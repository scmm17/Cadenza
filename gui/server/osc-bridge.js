'use strict';

const fs = require('fs');
const path = require('path');
const { spawn, exec } = require('child_process');
const { Client, Server: OscServer } = require('node-osc');
const patchSets = require('./patch-sets');

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
  };

  oscServer.on('message', (msg) => {
    const address = msg[0];
    if (address === '/cadenza/state') {
      const jsonStr = msg[1];
      try {
        const state = JSON.parse(jsonStr);
        shared.lastState = state;
        if (state.songName) {
          const info = patchSets.ensurePatchSetsDir(state.songName);
          if (!state.patchSetName) state.patchSetName = info.defaultPatchSet;
          if (!state.defaultPatchSetName) state.defaultPatchSetName = info.defaultPatchSet;
          if (shared.lastBroadcastSong !== state.songName) {
            shared.lastBroadcastSong = state.songName;
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
          if (shared.lastState) {
            shared.lastState.patchSetName = String(name);
            broadcast({ type: 'state', data: shared.lastState });
          }
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
