'use strict';

const express  = require('express');
const http     = require('http');
const path     = require('path');
const fs       = require('fs');
const { spawn, exec } = require('child_process');
const { WebSocketServer } = require('ws');
const { Client, Server: OscServer } = require('node-osc');

// ─── Configuration ────────────────────────────────────────────────────────────
const HTTP_PORT     = 3000;
const CHUCK_HOST    = '127.0.0.1';
const CHUCK_OSC_IN  = 9449;   // We send TO ChucK on this port
const GUI_OSC_IN    = 9450;   // ChucK sends TO us on this port

// ─── HTTP + WebSocket Server ──────────────────────────────────────────────────
const app    = express();
const server = http.createServer(app);
const wss    = new WebSocketServer({ server });

// Serve everything in gui/ as static files (index.html lives here)
app.use(express.static(path.join(__dirname)));
app.use('/vendor', express.static(path.join(__dirname, 'node_modules', 'cytoscape', 'dist')));

// ─── OSC Client (→ ChucK) ─────────────────────────────────────────────────────
const chuckClient = new Client(CHUCK_HOST, CHUCK_OSC_IN);

// ─── OSC Server (← ChucK) ─────────────────────────────────────────────────────
const oscServer = new OscServer(GUI_OSC_IN, '0.0.0.0', () => {
  console.log(`OSC listening on port ${GUI_OSC_IN} (← ChucK)`);
});

// Last known state — replayed to new clients on connect.
let lastState = null;
let lastGraph = null;   // fragment graph, replayed to new clients
let graphBuf  = [];     // graph being reassembled from /cadenza/graphNode messages
let currentChuckProc = null;
let lastLoadedSong = null;
let lastBroadcastSong = null;

// ─── Patch Sets Disk Management ───────────────────────────────────────────────
function normalizeSongName(songName) {
  if (!songName) return '';
  return String(songName).replace(/\.ck$/i, '').trim();
}

function getActiveSongName(explicitSong) {
  return normalizeSongName(
    explicitSong ||
    (lastState && lastState.songName) ||
    lastLoadedSong ||
    ''
  );
}

function ensurePatchSetsDir(rawSongName) {
  const songName = normalizeSongName(rawSongName);
  if (!songName) {
    return { songName: '', patchSets: [], defaultPatchSet: 'Default' };
  }
  const musicDir = path.join(__dirname, '..', 'music');
  const patchSetsDir = path.join(musicDir, `${songName}.patch-sets`);
  const legacyYaml = path.join(musicDir, `${songName}.yaml`);
  const defaultMetaPath = path.join(patchSetsDir, '.default');

  try {
    if (!fs.existsSync(patchSetsDir)) {
      fs.mkdirSync(patchSetsDir, { recursive: true });
    }
    if (fs.existsSync(legacyYaml)) {
      const destYaml = path.join(patchSetsDir, 'Default.yaml');
      if (!fs.existsSync(destYaml)) {
        fs.renameSync(legacyYaml, destYaml);
        console.log(`Migrated legacy YAML ${legacyYaml} -> ${destYaml}`);
      } else {
        fs.unlinkSync(legacyYaml);
      }
    }

    let sets = fs.readdirSync(patchSetsDir)
      .filter(f => f.endsWith('.yaml'))
      .map(f => f.slice(0, -5))
      .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    let defaultPatchSet = '';
    if (fs.existsSync(defaultMetaPath)) {
      defaultPatchSet = fs.readFileSync(defaultMetaPath, 'utf8').trim();
    }
    if (sets.length > 0) {
      if (!defaultPatchSet || !sets.includes(defaultPatchSet)) {
        defaultPatchSet = sets[0];
        fs.writeFileSync(defaultMetaPath, defaultPatchSet + '\n', 'utf8');
      }
    } else {
      defaultPatchSet = defaultPatchSet || 'Default';
      if (!fs.existsSync(defaultMetaPath)) {
        fs.writeFileSync(defaultMetaPath, defaultPatchSet + '\n', 'utf8');
      }
    }

    return { songName, patchSets: sets, defaultPatchSet };
  } catch (err) {
    console.error(`Failed to manage patch sets for ${songName}:`, err.message);
    return { songName, patchSets: [], defaultPatchSet: 'Default' };
  }
}

// Serialize the live state broadcast by ChucK into patch-set YAML. Used to seed
// a newly created patch set so it reflects in-memory settings immediately.
function buildYamlFromState(state) {
  const q = (s) => '"' + String(s == null ? '' : s).replace(/"/g, "'") + '"';
  const lines = ['song:', '  devices:'];
  const used = new Set();
  const deviceNames = {
    'V3': 'U2MIDI Pro', 'Hydrasynth': 'HYDRASYNTH EXPLORER', 'SH-4d': 'SH-4d',
    'S-1': 'S-1 MIDI IN', 'Moog': 'Moog Messenger', 'RD-6': 'RHYTHM DESIGNER RD-6',
  };
  const devices = (state && Array.isArray(state.devices)) ? state.devices : [];
  for (const d of devices) {
    const midiChannel = Math.max(0, Math.min(15, (parseInt(d.channel, 10) || 1) - 1));
    let key = `${d.uiName}-${midiChannel}`;
    if (used.has(key)) key += `-dev${d.index}`;
    used.add(key);
    lines.push(`    ${key}:`);
    lines.push(`      deviceName: ${q(deviceNames[d.uiName] || d.uiName)}`);
    lines.push(`      midiChannel: ${midiChannel}`);
    lines.push(`      patchName: ${q(d.patchName)}`);
    lines.push(`      uiName: ${q(d.uiName)}`);
    lines.push(`      muted: ${d.muted ? 1 : 0}`);
    lines.push(`      volume: ${d.volume}`);
    lines.push(`      filterCutoff: ${d.filterCutoff}`);
    lines.push(`      filterResonance: ${d.filterResonance}`);
    lines.push(`      pan: ${(parseInt(d.pan, 10) || 0) + 64}`);
    if (d.uiName === 'V3' || d.uiName === 'S-1' || d.uiName === 'Moog') {
      lines.push(`      program: ${d.program}`);
      lines.push(`      bank: ${d.bank}`);
      if (d.uiName === 'V3') lines.push('      programChange: 1');
    } else if (d.uiName === 'SH-4d' && d.bank >= 0 && d.program >= 0) {
      lines.push('      presetType: "tone"');
      lines.push(`      toneProgram: ${d.program}`);
      lines.push(`      toneBank: ${d.bank}`);
    }
  }
  const bpm = state && state.bpm ? Number(state.bpm) : 120;
  lines.push(`  bpm: ${bpm.toFixed(6)}`);
  return lines.join('\n') + '\n';
}

oscServer.on('message', (msg) => {
  const address = msg[0];
  if (address === '/cadenza/state') {
    const jsonStr = msg[1];
    try {
      const state = JSON.parse(jsonStr);
      lastState = state;
      if (state.songName) {
        const info = ensurePatchSetsDir(state.songName);
        if (!state.patchSetName) {
          state.patchSetName = info.defaultPatchSet;
        }
        if (!state.defaultPatchSetName) {
          state.defaultPatchSetName = info.defaultPatchSet;
        }
        if (lastBroadcastSong !== state.songName) {
          lastBroadcastSong = state.songName;
          broadcast({ type: 'patchSets', data: info });
        }
      }
      broadcast({ type: 'state', data: state });
    } catch (e) {
      console.error('OSC: Failed to parse state JSON:', e.message);
      console.error('Raw:', jsonStr);
    }
  } else if (address === '/cadenza/noteOn') {
    broadcast({ type: 'noteOn', dev: msg[1], note: msg[2], vel: msg[3] });
  } else if (address === '/cadenza/noteOff') {
    broadcast({ type: 'noteOff', dev: msg[1], note: msg[2] });
  } else if (address === '/cadenza/allNotesOff') {
    broadcast({ type: 'allNotesOff', dev: msg[1] });
  } else if (address === '/cadenza/transition') {
    broadcast({ type: 'transition', from: msg[1], to: msg[2] });
  } else if (address === '/cadenza/graphNode') {
    // One message per fragment: (index, total, json). Reassemble, then broadcast.
    const [ , idx, total, json ] = msg;
    if (idx === 0) graphBuf = [];
    if (total === 0) {
      lastGraph = [];
      graphBuf = [];
      broadcast({ type: 'graph', fragments: lastGraph });
    } else if (idx >= 0 && idx < total && json) {
      try {
        graphBuf[idx] = JSON.parse(json);
      } catch (e) {
        console.error('OSC: bad graphNode JSON:', e.message);
      }
      if (idx === total - 1) {
        let complete = graphBuf.length === total;
        for (let i = 0; complete && i < total; i++) {
          if (!graphBuf[i]) complete = false;
        }
        if (complete) {
          lastGraph = graphBuf;
          graphBuf = [];
          broadcast({ type: 'graph', fragments: lastGraph });
        } else {
          console.warn('OSC: ignoring incomplete graphNode batch');
          graphBuf = [];
        }
      }
    }
  }
});

// ─── Preset Catalog (parsed from framework/patch.ck) ─────────────────────────
function loadPresetCatalog() {
  const patchPath = path.join(__dirname, '..', 'framework', 'patch.ck');
  const v3 = [];
  const hydrasynth = [];
  const sh4d = [];
  try {
    const content = fs.readFileSync(patchPath, 'utf8');
    const v3Regex = /new\s+V3Preset\(\s*(\d+)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)/g;
    let m;
    while ((m = v3Regex.exec(content)) !== null) {
      v3.push({
        program: parseInt(m[1], 10),
        bank: parseInt(m[2], 10),
        name: m[3].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
        category: m[4].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
      });
    }
    const hydraRegex = /new\s+HydraPreset\(\s*(\d+)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)/g;
    while ((m = hydraRegex.exec(content)) !== null) {
      hydrasynth.push({
        program: parseInt(m[1], 10),
        bank: parseInt(m[2], 10),
        code: m[3],
        name: m[4].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
        category: m[5].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
      });
    }
    const sh4dRegex = /new\s+SH4dPreset\(\s*(\d+)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)/g;
    while ((m = sh4dRegex.exec(content)) !== null) {
      sh4d.push({
        program: parseInt(m[1], 10),
        bank: parseInt(m[2], 10),
        name: m[3].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
        category: m[4].replace(/\\"/g, '"').replace(/\\\\/g, '\\'),
      });
    }
  } catch (err) {
    console.error('Failed to parse preset catalog from patch.ck:', err.message);
  }
  return {
    V3: v3,
    Hydrasynth: hydrasynth,
    'SH-4d': sh4d,
    synths: ['V3', 'Hydrasynth', 'SH-4d', 'S-1', 'Moog', 'RD-6'],
  };
}

// ─── WebSocket ────────────────────────────────────────────────────────────────
const clients = new Set();

function broadcast(data) {
  const payload = JSON.stringify(data);
  for (const ws of clients) {
    if (ws.readyState === 1) ws.send(payload);
  }
}

wss.on('connection', (ws, req) => {
  clients.add(ws);
  console.log(`Browser connected (${clients.size} total)`);

  // Send preset catalog and cached state immediately so the page renders without waiting.
  ws.send(JSON.stringify({ type: 'presets', data: loadPresetCatalog() }));
  if (lastGraph) {
    ws.send(JSON.stringify({ type: 'graph', fragments: lastGraph }));
  }
  if (lastState) {
    ws.send(JSON.stringify({ type: 'state', data: lastState }));
    if (lastState.songName) {
      ws.send(JSON.stringify({ type: 'patchSets', data: ensurePatchSetsDir(lastState.songName) }));
    }
  }

  ws.on('message', (raw) => {
    try {
      const cmd = JSON.parse(raw.toString());
      handleBrowserCommand(cmd, ws);
    } catch (e) {
      console.error('WS: Invalid JSON:', e.message);
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    console.log(`Browser disconnected (${clients.size} remaining)`);
  });
});

// ─── Command Router ───────────────────────────────────────────────────────────
function handleBrowserCommand(cmd, ws) {
  switch (cmd.type) {
    case 'getSongs': {
      const musicDir = path.join(__dirname, '..', 'music');
      const songs = [];
      try {
        const scanDir = (dir) => {
          const files = fs.readdirSync(dir);
          for (const file of files) {
            const fullPath = path.join(dir, file);
            if (fs.statSync(fullPath).isDirectory()) {
              scanDir(fullPath);
            } else if (file.endsWith('.ck')) {
              songs.push(path.relative(musicDir, fullPath));
            }
          }
        };
        scanDir(musicDir);
        songs.sort();
        ws.send(JSON.stringify({ type: 'songList', songs }));
      } catch (err) {
        console.error('Failed to scan songs:', err);
        ws.send(JSON.stringify({ type: 'songList', songs: [] }));
      }
      break;
    }
    case 'editSong': {
      if (lastLoadedSong) {
        const songPath = path.join(__dirname, '..', 'music', lastLoadedSong);
        console.log(`→ OS: open ${songPath}`);
        exec(`open "${songPath}"`);
      } else {
        console.log(`→ OS: open failed, no song loaded`);
      }
      break;
    }
    case 'loadSong': {
      console.log(`→ ChucK: shutdown & load ${cmd.value}`);
      lastLoadedSong = cmd.value;
      const info = ensurePatchSetsDir(cmd.value);
      broadcast({ type: 'patchSets', data: info });
      
      const startNewProcess = () => {
        const songPath = path.join('music', cmd.value);
        console.log(`Spawning: chuck --dac:6 --in:0 ${songPath}`);
        const proc = spawn('chuck', ['--dac:6', '--in:0', songPath], { cwd: path.join(__dirname, '..') });
        currentChuckProc = proc;
        
        proc.stdout.on('data', data => process.stdout.write(`[ChucK] ${data}`));
        proc.stderr.on('data', data => process.stderr.write(`[ChucK ERR] ${data}`));
        proc.on('close', code => {
          console.log(`ChucK process exited with code ${code}`);
          if (currentChuckProc === proc) {
            currentChuckProc = null;
          }
        });
      };

      if (currentChuckProc) {
        // Send shutdown via OSC, but also forcefully kill if it takes too long
        chuckClient.send('/cadenza/shutdown', 1);
        
        const forceKillTimeout = setTimeout(() => {
          if (currentChuckProc) {
            console.log('ChucK did not exit after shutdown command. Force killing...');
            currentChuckProc.kill('SIGKILL');
          }
        }, 500);

        // Wait for the existing process to exit before starting the new one
        currentChuckProc.once('close', () => {
          clearTimeout(forceKillTimeout);
          startNewProcess();
        });
      } else {
        // A headless/orphaned process (e.g. from before this server restarted)
        // may still hold UDP 9449. Ask it to shut down, then make sure it's gone
        // before spawning so the new process can bind the OSC port.
        chuckClient.send('/cadenza/shutdown', 1);
        setTimeout(() => {
          exec('pkill -f "chuck .*music/"', () => setTimeout(startNewProcess, 200));
        }, 150);
      }
      break;
    }
    case 'device':
      console.log(`→ ChucK: /cadenza/device ${cmd.value}`);
      chuckClient.send('/cadenza/device', parseInt(cmd.value, 10));
      break;
    case 'golden':
      console.log('→ ChucK: /cadenza/golden');
      chuckClient.send('/cadenza/golden', 1);
      break;
    case 'allMode':
      console.log('→ ChucK: /cadenza/allMode');
      chuckClient.send('/cadenza/allMode', 1);
      break;
    case 'save':
      console.log('→ ChucK: /cadenza/save');
      chuckClient.send('/cadenza/save', 1);
      break;
    case 'shutdown':
      console.log('→ ChucK: /cadenza/shutdown');
      chuckClient.send('/cadenza/shutdown', 1);
      break;
    case 'play':
      console.log('→ ChucK: /cadenza/play');
      chuckClient.send('/cadenza/play', 1);
      break;
    case 'pause':
      console.log('→ ChucK: /cadenza/pause');
      chuckClient.send('/cadenza/pause', 1);
      break;
    case 'restart':
      console.log('→ ChucK: /cadenza/restart');
      chuckClient.send('/cadenza/restart', 1);
      break;
    case 'nextFragment':
      console.log(`→ ChucK: /cadenza/nextFragment "${cmd.value || ''}"`);
      chuckClient.send('/cadenza/nextFragment', String(cmd.value || ''));
      break;
    case 'loopFragment':
      console.log(`→ ChucK: /cadenza/loopFragment "${cmd.value || ''}"`);
      chuckClient.send('/cadenza/loopFragment', String(cmd.value || ''));
      break;
    case 'muteDevice':
      console.log(`→ ChucK: /cadenza/muteDevice ${cmd.value}`);
      chuckClient.send('/cadenza/muteDevice', parseInt(cmd.value, 10));
      break;
    case 'soloDevice':
      console.log(`→ ChucK: /cadenza/soloDevice ${cmd.value}`);
      chuckClient.send('/cadenza/soloDevice', parseInt(cmd.value, 10));
      break;
    case 'prevPresetCat':
      console.log('→ ChucK: /cadenza/prevPresetCat');
      chuckClient.send('/cadenza/prevPresetCat', 1);
      break;
    case 'prevPreset':
      console.log('→ ChucK: /cadenza/prevPreset');
      chuckClient.send('/cadenza/prevPreset', 1);
      break;
    case 'nextPreset':
      console.log('→ ChucK: /cadenza/nextPreset');
      chuckClient.send('/cadenza/nextPreset', 1);
      break;
    case 'nextPresetCat':
      console.log('→ ChucK: /cadenza/nextPresetCat');
      chuckClient.send('/cadenza/nextPresetCat', 1);
      break;
    case 'getPresets':
      ws.send(JSON.stringify({ type: 'presets', data: loadPresetCatalog() }));
      break;
    case 'setPreset': {
      const { devIdx, presetName } = cmd.value || {};
      if (devIdx != null && presetName) {
        console.log(`→ ChucK: /cadenza/setPreset dev=${devIdx} preset="${presetName}"`);
        chuckClient.send('/cadenza/setPreset', parseInt(devIdx, 10), String(presetName));
      }
      break;
    }
    case 'setSynth': {
      const { devIdx, synthName } = cmd.value || cmd || {};
      if (devIdx != null && synthName) {
        console.log(`→ ChucK: /cadenza/setSynth dev=${devIdx} synth="${synthName}"`);
        chuckClient.send('/cadenza/setSynth', parseInt(devIdx, 10), String(synthName));
      }
      break;
    }
    case 'setChannel': {
      const { devIdx, channel } = cmd.value || cmd || {};
      if (devIdx != null && channel != null) {
        console.log(`→ ChucK: /cadenza/setChannel dev=${devIdx} channel=${channel}`);
        chuckClient.send('/cadenza/setChannel', parseInt(devIdx, 10), parseInt(channel, 10));
      }
      break;
    }
    case 'getPatchSets': {
      const songName = getActiveSongName(cmd.value && cmd.value.songName);
      const info = ensurePatchSetsDir(songName);
      ws.send(JSON.stringify({ type: 'patchSets', data: info }));
      break;
    }
    case 'selectPatchSet': {
      const { name } = cmd.value || cmd || {};
      const songName = getActiveSongName();
      if (name && songName) {
        console.log(`→ ChucK: /cadenza/loadPatchSet "${name}"`);
        chuckClient.send('/cadenza/loadPatchSet', String(name));
        if (lastState) {
          lastState.patchSetName = String(name);
          broadcast({ type: 'state', data: lastState });
        }
        broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
      }
      break;
    }
    case 'createPatchSet': {
      const songName = getActiveSongName();
      if (!songName) break;
      const info = ensurePatchSetsDir(songName);
      const patchSetsDir = path.join(__dirname, '..', 'music', `${songName}.patch-sets`);
      const existingLower = new Set(info.patchSets.map(s => s.toLowerCase()));
      let idx = 1;
      let newName = `Patch Set ${idx}`;
      while (existingLower.has(newName.toLowerCase())) {
        idx++;
        newName = `Patch Set ${idx}`;
      }
      const destPath = path.join(patchSetsDir, `${newName}.yaml`);
      try {
        // Seed the new file from the live in-memory state (never copy the
        // previous patch set's on-disk YAML). ChucK overwrites it right away
        // with its full serialization via /cadenza/createPatchSet.
        fs.writeFileSync(destPath, buildYamlFromState(lastState), 'utf8');
      } catch (err) {
        console.error('Failed to create patch set file:', err.message);
      }
      console.log(`→ ChucK: /cadenza/createPatchSet "${newName}"`);
      chuckClient.send('/cadenza/createPatchSet', newName, String(info.defaultPatchSet || ''));
      if (lastState) {
        lastState.patchSetName = newName;
        broadcast({ type: 'state', data: lastState });
      }
      broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
      break;
    }
    case 'renamePatchSet': {
      const { oldName, newName: rawNewName } = cmd.value || cmd || {};
      const songName = getActiveSongName();
      if (!songName || !oldName || !rawNewName) break;
      const newName = String(rawNewName).trim().replace(/[\/\\:*?"<>|]/g, '');
      const info = ensurePatchSetsDir(songName);
      if (!newName || newName === oldName) {
        broadcast({ type: 'patchSets', data: info });
        break;
      }
      const patchSetsDir = path.join(__dirname, '..', 'music', `${songName}.patch-sets`);
      const oldPath = path.join(patchSetsDir, `${oldName}.yaml`);
      const newPath = path.join(patchSetsDir, `${newName}.yaml`);
      if (fs.existsSync(newPath) && oldName.toLowerCase() !== newName.toLowerCase()) {
        console.warn(`Cannot rename patch set to existing name "${newName}"`);
        broadcast({ type: 'patchSets', data: info });
        break;
      }
      try {
        if (fs.existsSync(oldPath)) {
          fs.renameSync(oldPath, newPath);
        }
        let defName = info.defaultPatchSet;
        if (defName === oldName) {
          defName = newName;
          fs.writeFileSync(path.join(patchSetsDir, '.default'), defName + '\n', 'utf8');
        }
        const curName = (lastState && lastState.patchSetName === oldName)
          ? newName
          : ((lastState && lastState.patchSetName) || newName);
        chuckClient.send('/cadenza/setPatchSetName', String(curName), String(defName));
        if (lastState) {
          lastState.patchSetName = curName;
          lastState.defaultPatchSetName = defName;
          broadcast({ type: 'state', data: lastState });
        }
      } catch (err) {
        console.error('Failed to rename patch set:', err.message);
      }
      broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
      break;
    }
    case 'setDefaultPatchSet': {
      const { name } = cmd.value || cmd || {};
      const songName = getActiveSongName();
      if (!songName || !name) break;
      const patchSetsDir = path.join(__dirname, '..', 'music', `${songName}.patch-sets`);
      try {
        fs.mkdirSync(patchSetsDir, { recursive: true });
        fs.writeFileSync(path.join(patchSetsDir, '.default'), String(name) + '\n', 'utf8');
        const curName = (lastState && lastState.patchSetName) || String(name);
        chuckClient.send('/cadenza/setPatchSetName', String(curName), String(name));
        if (lastState) {
          lastState.defaultPatchSetName = String(name);
          broadcast({ type: 'state', data: lastState });
        }
      } catch (err) {
        console.error('Failed to set default patch set:', err.message);
      }
      broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
      break;
    }
    case 'deletePatchSet': {
      const { name } = cmd.value || cmd || {};
      const songName = getActiveSongName();
      if (!songName || !name) break;
      const info = ensurePatchSetsDir(songName);
      const patchSetsDir = path.join(__dirname, '..', 'music', `${songName}.patch-sets`);
      const targetPath = path.join(patchSetsDir, `${name}.yaml`);
      try {
        if (fs.existsSync(targetPath)) {
          fs.unlinkSync(targetPath);
        }
        const remaining = fs.readdirSync(patchSetsDir)
          .filter(f => f.endsWith('.yaml'))
          .map(f => f.slice(0, -5))
          .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

        if (remaining.length === 0) {
          const fallback = 'Default';
          fs.writeFileSync(path.join(patchSetsDir, '.default'), fallback + '\n', 'utf8');
          chuckClient.send('/cadenza/setPatchSetName', fallback, fallback);
          chuckClient.send('/cadenza/save', 1);
          if (lastState) {
            lastState.patchSetName = fallback;
            lastState.defaultPatchSetName = fallback;
            broadcast({ type: 'state', data: lastState });
          }
        } else {
          let newDefault = info.defaultPatchSet;
          if (info.defaultPatchSet === name || !remaining.includes(newDefault)) {
            newDefault = remaining[0];
            fs.writeFileSync(path.join(patchSetsDir, '.default'), newDefault + '\n', 'utf8');
          }
          let newCurrent = (lastState && lastState.patchSetName) || newDefault;
          if (newCurrent === name || !remaining.includes(newCurrent)) {
            newCurrent = newDefault;
            chuckClient.send('/cadenza/setPatchSetName', newCurrent, newDefault);
            chuckClient.send('/cadenza/loadPatchSet', newCurrent);
          } else {
            chuckClient.send('/cadenza/setPatchSetName', newCurrent, newDefault);
          }
          if (lastState) {
            lastState.patchSetName = newCurrent;
            lastState.defaultPatchSetName = newDefault;
            broadcast({ type: 'state', data: lastState });
          }
        }
      } catch (err) {
        console.error('Failed to delete patch set:', err.message);
      }
      broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
      break;
    }
    case 'setTempo':
      console.log(`→ ChucK: /cadenza/tempo ${cmd.value}`);
      chuckClient.send('/cadenza/tempo', parseInt(cmd.value, 10));
      break;
    case 'setParam': {
      const { devIdx, param, value } = cmd.value;  // browser wraps extra data in cmd.value
      const paramToAddr = {
        volume:    '/cadenza/volume',
        cutoff:    '/cadenza/cutoff',
        resonance: '/cadenza/resonance',
        pan:       '/cadenza/pan',
      };
      const addr = paramToAddr[param];
      if (addr) {
        console.log(`→ ChucK: ${addr} dev=${devIdx} val=${value}`);
        chuckClient.send(addr, parseInt(devIdx, 10), parseInt(value, 10));
      } else {
        console.warn('setParam: unknown param', param);
      }
      break;
    }
    default:
      console.warn('WS: Unknown command type:', cmd.type);
  }
}

// ─── Start ────────────────────────────────────────────────────────────────────
server.listen(HTTP_PORT, () => {
  console.log('');
  console.log('  ╔══════════════════════════════════╗');
  console.log('  ║   Cadenza GUI — Bridge Server    ║');
  console.log('  ╠══════════════════════════════════╣');
  console.log(`  ║  Dashboard: http://localhost:${HTTP_PORT}  ║`);
  console.log(`  ║  OSC ← ChucK on UDP :${GUI_OSC_IN}       ║`);
  console.log(`  ║  OSC → ChucK on UDP :${CHUCK_OSC_IN}       ║`);
  console.log('  ╚══════════════════════════════════╝');
  console.log('');
});