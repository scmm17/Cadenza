'use strict';

const express  = require('express');
const http     = require('http');
const path     = require('path');
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

oscServer.on('message', (msg) => {
  const address = msg[0];
  if (address === '/cadenza/state') {
    const jsonStr = msg[1];
    try {
      const state = JSON.parse(jsonStr);
      broadcast({ type: 'state', data: state });
    } catch (e) {
      console.error('OSC: Failed to parse state JSON:', e.message);
      console.error('Raw:', jsonStr);
    }
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

  ws.on('message', (raw) => {
    try {
      const cmd = JSON.parse(raw.toString());
      handleBrowserCommand(cmd);
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
function handleBrowserCommand(cmd) {
  switch (cmd.type) {
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