'use strict';

const fs = require('fs');
const path = require('path');
const { spawn, exec, execFile } = require('child_process');
const { Client, Server: OscServer } = require('node-osc');
const patchSets = require('./patch-sets');

const ARTURIA_APPS_DIR = '/Applications/Arturia';
const ARTURIA_LIB_ROOT = '/Library/Arturia';
const LAUNCH_COOLDOWN_MS = 10000;
const STOP_CHECK_COOLDOWN_MS = 10000;
const COLD_LAUNCH_SYNC_DELAY_MS = 3000;
const COLD_LAUNCH_SETTLE_DELAY_MS = 6500;
const COLD_LAUNCH_FINAL_DELAY_MS = 10000;

const SIMPLE_OSC_COMMANDS = {
  device:        { addr: '/cadenza/device',        type: 'int' },
  golden:        { addr: '/cadenza/golden',        constVal: 1 },
  allMode:       { addr: '/cadenza/allMode',       constVal: 1 },
  save:          { addr: '/cadenza/save',          constVal: 1 },
  shutdown:      { addr: '/cadenza/shutdown',      constVal: 1 },
  play:          { addr: '/cadenza/play',          constVal: 1 },
  pause:         { addr: '/cadenza/pause',         constVal: 1 },
  restart:       { addr: '/cadenza/restart',       constVal: 1 },
  nextFragment:  { addr: '/cadenza/nextFragment',  type: 'str' },
  loopFragment:  { addr: '/cadenza/loopFragment',  type: 'str' },
  muteDevice:    { addr: '/cadenza/muteDevice',    type: 'int' },
  soloDevice:    { addr: '/cadenza/soloDevice',    type: 'int' },
  prevPresetCat: { addr: '/cadenza/prevPresetCat', constVal: 1 },
  prevPreset:    { addr: '/cadenza/prevPreset',    constVal: 1 },
  nextPreset:    { addr: '/cadenza/nextPreset',    constVal: 1 },
  nextPresetCat: { addr: '/cadenza/nextPresetCat', constVal: 1 },
  setTempo:      { addr: '/cadenza/tempo',         type: 'int' },
};

const PARAM_ADDRS = {
  volume:    '/cadenza/volume',
  cutoff:    '/cadenza/cutoff',
  resonance: '/cadenza/resonance',
  pan:       '/cadenza/pan',
};

function createOscBridge({ chuckHost, chuckOscIn, guiOscIn, broadcast, loadPresetCatalog }) {
  const chuckClient = new Client(chuckHost, chuckOscIn);
  const oscServer = new OscServer(guiOscIn, '0.0.0.0', () => {
    console.log(`OSC listening on port ${guiOscIn} (← ChucK)`);
  });

  const shared = {
    lastState: null,
    lastGraph: null,
    graphBuf: [],
    currentChuckProc: null,
    lastLoadedSong: null,
    lastBroadcastSong: null,
    lastPatchSetInfo: null,
    lastSyncedSynthSig: '',
  };

  const lastLaunchAttempt = new Map();
  const lastStopCheck = new Map();
  const knownRunningApps = new Set();
  const desiredRunning = new Map();

  function ensureStandaloneMidiPref(meta) {
    if (!meta || !meta.appName || !meta.deviceName) return;
    const prefPath = path.join(ARTURIA_LIB_ROOT, meta.appName, 'tmp', 'standalone.pref');
    try {
      if (!fs.existsSync(prefPath)) return;
      const xml = fs.readFileSync(prefPath, 'utf8');
      const matches = [...xml.matchAll(/^[ \t]*<VALUE\s+name="MidiDevice_\d+"\s+val="([^"]*)"[^>]*\/>/gm)];
      if (matches.length === 1 && matches[0][1] === meta.deviceName) {
        return;
      }
      const desiredLine = `  <VALUE name="MidiDevice_1" val="${meta.deviceName}"/>`;
      const stripped = xml.replace(/^[ \t]*<VALUE\s+name="MidiDevice_\d+"\s+[^>]*\/>\r?\n?/gm, '');
      if (stripped.includes('</PROPERTIES>')) {
        const updated = stripped.replace('</PROPERTIES>', `${desiredLine}\n</PROPERTIES>`);
        fs.writeFileSync(prefPath, updated, 'utf8');
      }
    } catch (err) {
      console.warn(`→ OS: could not update ${prefPath}:`, err.message);
    }
  }

  function ensureStandalonePluginPref(meta) {
    if (!meta || !meta.appName) return;
    const prefPath = path.join(ARTURIA_LIB_ROOT, meta.appName, 'tmp', 'plugin.pref.xml');
    try {
      if (!fs.existsSync(prefPath)) return;
      const xml = fs.readFileSync(prefPath, 'utf8');
      let updated = xml;
      const multicoreRe = /(<param\s+name="Multi[- ]?Core\d*"\s+value=")([^"]*)("\s*\/>)/gi;
      if (multicoreRe.test(updated)) {
        updated = updated.replace(multicoreRe, '$10.000000$3');
      } else if (meta.appName.startsWith('Augmented ') && updated.includes('</rootnode>')) {
        updated = updated.replace('</rootnode>', '\t<param name="Multicore" value="0.000000"/>\n</rootnode>');
      }
      // Force Fader Mode = Jump (0.000000) instead of Scale (1.000000) / Pick-Up (0.500000)
      // so incoming volume/CC messages from Cadenza jump directly to the exact target value.
      const takeoverRe = /(<param\s+name="MIDITakeOverMode"\s+value=")([^"]*)("\s*\/>)/g;
      if (takeoverRe.test(updated)) {
        updated = updated.replace(takeoverRe, '$10.000000$3');
      } else if (updated.includes('</rootnode>')) {
        updated = updated.replace('</rootnode>', '\t<param name="MIDITakeOverMode" value="0.000000"/>\n</rootnode>');
      }
      if (updated !== xml) {
        fs.writeFileSync(prefPath, updated, 'utf8');
      }
    } catch (err) {
      console.warn(`→ OS: could not update ${prefPath}:`, err.message);
    }
  }

  function ensureVirtualSynthRunning(uiName, { foreground = false } = {}) {
    if (!uiName || process.platform !== 'darwin') return;
    const catalog = loadPresetCatalog();
    const meta = catalog && catalog.synthMeta && catalog.synthMeta[uiName];
    if (!meta || !meta.appName) return;

    const appName = meta.appName;
    const appPath = path.join(ARTURIA_APPS_DIR, `${appName}.app`);
    if (!fs.existsSync(appPath)) return;

    desiredRunning.set(appName, true);
    const now = Date.now();
    if (!foreground && now - (lastLaunchAttempt.get(appName) || 0) < LAUNCH_COOLDOWN_MS) {
      return;
    }
    lastLaunchAttempt.set(appName, now);

    execFile('pgrep', ['-x', appName], (err) => {
      if (!err) {
        knownRunningApps.add(appName);
        if (!foreground) return;
      }
      if (!foreground && desiredRunning.get(appName) !== true) {
        return;
      }
      if (err) {
        ensureStandaloneMidiPref(meta);
        ensureStandalonePluginPref(meta);
      }
      const args = foreground ? ['-a', appPath] : ['-g', '-a', appPath];
      execFile('open', args, (openErr) => {
        if (openErr) {
          console.error(`→ OS: failed to launch ${appPath}:`, openErr.message);
          return;
        }
        knownRunningApps.add(appName);
        lastStopCheck.delete(appName);
        console.log(`→ OS: launched ${appName} (${foreground ? 'foreground' : 'background'})`);
        if (err) {
          const syncLaunchedDevices = ({ allowPresetReload }) => {
            if (desiredRunning.get(appName) !== true) return;
            const devices = shared.lastState && Array.isArray(shared.lastState.devices)
              ? shared.lastState.devices
              : [];
            for (const dev of devices) {
              if (dev && dev.uiName === uiName) {
                if (allowPresetReload && dev.patchName) {
                  // setPreset in ChucK applies the preset, sends volume immediately,
                  // and schedules post-preset delayed volume re-syncs.
                  chuckClient.send('/cadenza/setPreset', parseInt(dev.index, 10), String(dev.patchName));
                } else if (dev.volume != null && dev.volume >= 0) {
                  chuckClient.send('/cadenza/volume', parseInt(dev.index, 10), parseInt(dev.volume, 10));
                }
              }
            }
          };
          setTimeout(() => syncLaunchedDevices({ allowPresetReload: true }), COLD_LAUNCH_SYNC_DELAY_MS);
          setTimeout(() => {
            const isPaused = Boolean(shared.lastState && shared.lastState.isPaused);
            syncLaunchedDevices({ allowPresetReload: isPaused });
          }, COLD_LAUNCH_SETTLE_DELAY_MS);
          setTimeout(() => {
            syncLaunchedDevices({ allowPresetReload: false });
          }, COLD_LAUNCH_FINAL_DELAY_MS);
        }
      });
    });
  }

  function stopVirtualSynthIfRunning(appName) {
    if (!appName || process.platform !== 'darwin') return;
    desiredRunning.set(appName, false);
    lastLaunchAttempt.delete(appName);

    const now = Date.now();
    if (!knownRunningApps.has(appName) && now - (lastStopCheck.get(appName) || 0) < STOP_CHECK_COOLDOWN_MS) {
      return;
    }
    lastStopCheck.set(appName, now);

    execFile('pgrep', ['-x', appName], (err) => {
      if (err) {
        knownRunningApps.delete(appName);
        return;
      }
      if (desiredRunning.get(appName) !== false) {
        return;
      }
      execFile('pkill', ['-x', appName], (killErr) => {
        knownRunningApps.delete(appName);
        if (!killErr) {
          console.log(`→ OS: stopped ${appName} (unused)`);
        }
      });
    });
  }

  function syncVirtualSynths(devices) {
    if (process.platform !== 'darwin' || !Array.isArray(devices)) return;
    const catalog = loadPresetCatalog();
    const synthMeta = (catalog && catalog.synthMeta) || {};
    const activeApps = new Map();

    for (const dev of devices) {
      if (!dev || !dev.uiName) continue;
      const meta = synthMeta[dev.uiName];
      if (meta && meta.appName && !activeApps.has(meta.appName)) {
        activeApps.set(meta.appName, dev.uiName);
      }
    }

    const handledApps = new Set();
    for (const meta of Object.values(synthMeta)) {
      if (!meta || !meta.appName || handledApps.has(meta.appName)) continue;
      handledApps.add(meta.appName);
      const activeUiName = activeApps.get(meta.appName);
      if (activeUiName) {
        desiredRunning.set(meta.appName, true);
        ensureVirtualSynthRunning(activeUiName);
      } else {
        stopVirtualSynthIfRunning(meta.appName);
      }
    }
  }

  oscServer.on('message', (msg) => {
    const address = msg[0];
    if (address === '/cadenza/state') {
      const jsonStr = msg[1];
      try {
        const state = JSON.parse(jsonStr);
        shared.lastState = state;
        const synthSig = Array.isArray(state.devices)
          ? state.devices.map(d => (d && d.uiName) || '').join('|')
          : '';
        if (synthSig !== shared.lastSyncedSynthSig) {
          shared.lastSyncedSynthSig = synthSig;
          syncVirtualSynths(state.devices);
        }
        if (state.songName) {
          if (shared.lastBroadcastSong !== state.songName) {
            shared.lastBroadcastSong = state.songName;
            shared.lastPatchSetInfo = patchSets.ensurePatchSetsDir(state.songName);
            broadcast({ type: 'patchSets', data: shared.lastPatchSetInfo });
          } else if ((!state.patchSetName || !state.defaultPatchSetName) && !shared.lastPatchSetInfo) {
            shared.lastPatchSetInfo = patchSets.ensurePatchSetsDir(state.songName);
          }
          if (shared.lastPatchSetInfo) {
            if (!state.patchSetName) state.patchSetName = shared.lastPatchSetInfo.defaultPatchSet;
            if (!state.defaultPatchSetName) state.defaultPatchSetName = shared.lastPatchSetInfo.defaultPatchSet;
          }
        }
        broadcast({ type: 'state', data: state });
      } catch (e) {
        console.error('OSC: Failed to parse state JSON:', e.message);
        console.error('Raw:', jsonStr);
      }
    } else if (address === '/cadenza/activateSynth') {
      if (msg[1]) ensureVirtualSynthRunning(String(msg[1]));
    } else if (address === '/cadenza/noteOn') {
      broadcast({ type: 'noteOn', dev: msg[1], note: msg[2], vel: msg[3] });
    } else if (address === '/cadenza/noteOff') {
      broadcast({ type: 'noteOff', dev: msg[1], note: msg[2] });
    } else if (address === '/cadenza/allNotesOff') {
      broadcast({ type: 'allNotesOff', dev: msg[1] });
    } else if (address === '/cadenza/transition') {
      broadcast({ type: 'transition', from: msg[1], to: msg[2] });
    } else if (address === '/cadenza/graphNode') {
      const [, idx, total, json] = msg;
      if (idx === 0) shared.graphBuf = [];
      if (total === 0) {
        shared.lastGraph = [];
        shared.graphBuf = [];
        broadcast({ type: 'graph', fragments: shared.lastGraph });
      } else if (idx >= 0 && idx < total && json) {
        try {
          shared.graphBuf[idx] = JSON.parse(json);
        } catch (e) {
          console.error('OSC: bad graphNode JSON:', e.message);
        }
        if (idx === total - 1) {
          let complete = shared.graphBuf.length === total;
          for (let i = 0; complete && i < total; i++) {
            if (!shared.graphBuf[i]) complete = false;
          }
          if (complete) {
            shared.lastGraph = shared.graphBuf;
            shared.graphBuf = [];
            broadcast({ type: 'graph', fragments: shared.lastGraph });
          } else {
            console.warn('OSC: ignoring incomplete graphNode batch');
            shared.graphBuf = [];
          }
        }
      }
    }
  });

  function handleBrowserCommand(cmd, ws) {
    const simple = SIMPLE_OSC_COMMANDS[cmd.type];
    if (simple) {
      let arg = simple.constVal;
      if (simple.type === 'int') arg = parseInt(cmd.value, 10);
      else if (simple.type === 'str') arg = String(cmd.value || '');
      console.log(`→ ChucK: ${simple.addr} ${arg}`);
      chuckClient.send(simple.addr, arg);
      return;
    }

    switch (cmd.type) {
      case 'getSongs': {
        const musicDir = path.join(__dirname, '..', '..', 'music');
        const songs = [];
        try {
          const scanDir = (dir) => {
            for (const file of fs.readdirSync(dir)) {
              const fullPath = path.join(dir, file);
              if (fs.statSync(fullPath).isDirectory()) scanDir(fullPath);
              else if (file.endsWith('.ck')) songs.push(path.relative(musicDir, fullPath));
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
        if (shared.lastLoadedSong) {
          const songPath = path.join(__dirname, '..', '..', 'music', shared.lastLoadedSong);
          console.log(`→ OS: open ${songPath}`);
          exec(`open "${songPath}"`);
        } else {
          console.log('→ OS: open failed, no song loaded');
        }
        break;
      }
      case 'loadSong': {
        console.log(`→ ChucK: shutdown & load ${cmd.value}`);
        shared.lastLoadedSong = cmd.value;
        const info = patchSets.ensurePatchSetsDir(cmd.value);
        broadcast({ type: 'patchSets', data: info });

        const startNewProcess = () => {
          shared.lastState = null;
          shared.lastSyncedSynthSig = '';
          broadcast({ type: 'songLoading', songName: patchSets.normalizeSongName(cmd.value) });
          const songPath = path.join('music', cmd.value);
          console.log(`Spawning: chuck --dac:6 --in:0 ${songPath}`);
          const proc = spawn('chuck', ['--dac:6', '--in:0', songPath], {
            cwd: path.join(__dirname, '..', '..'),
          });
          shared.currentChuckProc = proc;
          proc.stdout.on('data', data => process.stdout.write(`[ChucK] ${data}`));
          proc.stderr.on('data', data => process.stderr.write(`[ChucK ERR] ${data}`));
          proc.on('close', code => {
            console.log(`ChucK process exited with code ${code}`);
            if (shared.currentChuckProc === proc) shared.currentChuckProc = null;
          });
        };

        if (shared.currentChuckProc) {
          chuckClient.send('/cadenza/shutdown', 1);
          const forceKillTimeout = setTimeout(() => {
            if (shared.currentChuckProc) {
              console.log('ChucK did not exit after shutdown command. Force killing...');
              shared.currentChuckProc.kill('SIGKILL');
            }
          }, 500);
          shared.currentChuckProc.once('close', () => {
            clearTimeout(forceKillTimeout);
            startNewProcess();
          });
        } else {
          chuckClient.send('/cadenza/shutdown', 1);
          setTimeout(() => {
            exec('pkill -f "chuck .*music/"', () => setTimeout(startNewProcess, 200));
          }, 150);
        }
        break;
      }
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
          const targetIdx = parseInt(devIdx, 10);
          const nextUiName = String(synthName);
          console.log(`→ ChucK: /cadenza/setSynth dev=${targetIdx} synth="${nextUiName}"`);
          chuckClient.send('/cadenza/setSynth', targetIdx, nextUiName);
          if (shared.lastState && Array.isArray(shared.lastState.devices)) {
            const updatedDevices = shared.lastState.devices.map(d =>
              d && parseInt(d.index, 10) === targetIdx ? { ...d, uiName: nextUiName } : d
            );
            syncVirtualSynths(updatedDevices);
          } else {
            ensureVirtualSynthRunning(nextUiName);
          }
        }
        break;
      }
      case 'openSynthApp': {
        const { uiName } = cmd.value || cmd || {};
        if (uiName) {
          ensureVirtualSynthRunning(String(uiName), { foreground: true });
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
        const songName = patchSets.getActiveSongName(
          cmd.value && cmd.value.songName,
          shared.lastState,
          shared.lastLoadedSong
        );
        ws.send(JSON.stringify({ type: 'patchSets', data: patchSets.ensurePatchSetsDir(songName) }));
        break;
      }
      case 'selectPatchSet': {
        const { name } = cmd.value || cmd || {};
        const songName = patchSets.getActiveSongName(null, shared.lastState, shared.lastLoadedSong);
        if (name && songName) {
          console.log(`→ ChucK: /cadenza/loadPatchSet "${name}"`);
          chuckClient.send('/cadenza/loadPatchSet', String(name));
          broadcast({ type: 'patchSets', data: patchSets.ensurePatchSetsDir(songName) });
        }
        break;
      }
      case 'createPatchSet': {
        const songName = patchSets.getActiveSongName(null, shared.lastState, shared.lastLoadedSong);
        if (songName) patchSets.createPatchSet(songName, shared.lastState, chuckClient, broadcast);
        break;
      }
      case 'renamePatchSet': {
        const { oldName, newName } = cmd.value || cmd || {};
        const songName = patchSets.getActiveSongName(null, shared.lastState, shared.lastLoadedSong);
        if (songName && oldName && newName) {
          patchSets.renamePatchSet(songName, oldName, newName, shared.lastState, chuckClient, broadcast);
        }
        break;
      }
      case 'setDefaultPatchSet': {
        const { name } = cmd.value || cmd || {};
        const songName = patchSets.getActiveSongName(null, shared.lastState, shared.lastLoadedSong);
        if (songName && name) {
          patchSets.setDefaultPatchSet(songName, name, shared.lastState, chuckClient, broadcast);
        }
        break;
      }
      case 'deletePatchSet': {
        const { name } = cmd.value || cmd || {};
        const songName = patchSets.getActiveSongName(null, shared.lastState, shared.lastLoadedSong);
        if (songName && name) {
          patchSets.deletePatchSet(songName, name, shared.lastState, chuckClient, broadcast);
        }
        break;
      }
      case 'setParam': {
        const { devIdx, param, value } = cmd.value || {};
        const addr = PARAM_ADDRS[param];
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

  return { shared, handleBrowserCommand };
}

module.exports = { createOscBridge };
