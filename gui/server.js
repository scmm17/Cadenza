'use strict';

const express = require('express');
const http = require('http');
const path = require('path');
const { WebSocketServer } = require('ws');
const { loadPresetCatalog } = require('./server/preset-catalog');
const { ensurePatchSetsDir } = require('./server/patch-sets');
const { createOscBridge } = require('./server/osc-bridge');

const HTTP_PORT = 3000;
const CHUCK_HOST = '127.0.0.1';
const CHUCK_OSC_IN = 9449;
const GUI_OSC_IN = 9450;

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.static(path.join(__dirname)));
app.use('/vendor', express.static(path.join(__dirname, 'node_modules', 'cytoscape', 'dist')));

const clients = new Set();

function broadcast(data) {
  const payload = JSON.stringify(data);
  for (const ws of clients) {
    if (ws.readyState === 1) ws.send(payload);
  }
}

const { shared, handleBrowserCommand } = createOscBridge({
  chuckHost: CHUCK_HOST,
  chuckOscIn: CHUCK_OSC_IN,
  guiOscIn: GUI_OSC_IN,
  broadcast,
  loadPresetCatalog,
});

wss.on('connection', (ws) => {
  clients.add(ws);
  console.log(`Browser connected (${clients.size} total)`);

  ws.send(JSON.stringify({ type: 'presets', data: loadPresetCatalog() }));
  if (shared.lastGraph) {
    ws.send(JSON.stringify({ type: 'graph', fragments: shared.lastGraph }));
  }
  if (shared.lastState) {
    ws.send(JSON.stringify({ type: 'state', data: shared.lastState }));
    if (shared.lastState.songName) {
      ws.send(JSON.stringify({ type: 'patchSets', data: ensurePatchSetsDir(shared.lastState.songName) }));
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
