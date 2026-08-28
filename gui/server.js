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

// ─── OSC Client (→ ChucK) ─────────────────────────────────────────────────────
const chuckClient = new Client(CHUCK_HOST, CHUCK_OSC_IN);

// ─── OSC Server (← ChucK) ─────────────────────────────────────────────────────
const oscServer = new OscServer(GUI_OSC_IN, '0.0.0.0', () => {
  console.log(`OSC listening on port ${GUI_OSC_IN} (← ChucK)`);
});

// Last known state — replayed to new clients on connect.
let lastState = null;
let currentChuckProc = null;
let lastLoadedSong = null;

oscServer.on('message', (msg) => {
  const address = msg[0];
  if (address === '/cadenza/state') {
    const jsonStr = msg[1];
    try {
      const state = JSON.parse(jsonStr);
      lastState = state;
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
  }
});

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

  // Send cached state immediately so the page renders without waiting.
  if (lastState) {
    ws.send(JSON.stringify({ type: 'state', data: lastState }));
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
        // Just send shutdown in case a headless process is running
        chuckClient.send('/cadenza/shutdown', 1);
        setTimeout(startNewProcess, 100);
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