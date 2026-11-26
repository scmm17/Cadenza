'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawn } = require('child_process');

const AU_HOST_PORT = parseInt(process.env.CADENZA_AU_HOST_PORT || '3099', 10);
const AU_HOST_BIN = path.join(__dirname, '..', '..', 'tools', 'au-host');

let auHostProc = null;
let startPromise = null;

function httpRequest(method, urlPath, bodyObj = null, timeoutMs = 1500) {
  return new Promise((resolve, reject) => {
    const payload = bodyObj ? JSON.stringify(bodyObj) : null;
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: AU_HOST_PORT,
        path: urlPath,
        method,
        timeout: timeoutMs,
        headers: payload
          ? {
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(payload),
            }
          : {},
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          try {
            resolve({ status: res.statusCode, data: JSON.parse(text) });
          } catch (_) {
            resolve({ status: res.statusCode, data: text });
          }
        });
      }
    );
    req.on('timeout', () => {
      req.destroy(new Error('AU host request timed out'));
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function isAuHostAlive() {
  try {
    const res = await httpRequest('GET', '/status', null, 500);
    return res.status === 200;
  } catch (_) {
    return false;
  }
}

async function ensureAuHostRunning() {
  if (process.platform !== 'darwin') return false;
  if (await isAuHostAlive()) return true;
  if (startPromise) return startPromise;

  startPromise = (async () => {
    if (!fs.existsSync(AU_HOST_BIN)) {
      console.warn(`→ AU Host binary not found at ${AU_HOST_BIN}`);
      return false;
    }
    if (!auHostProc) {
      console.log(`→ Starting AU Host (${AU_HOST_BIN}) on port ${AU_HOST_PORT}`);
      const proc = spawn(AU_HOST_BIN, [], {
        env: { ...process.env, CADENZA_AU_HOST_PORT: String(AU_HOST_PORT) },
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      auHostProc = proc;
      proc.stdout.on('data', (d) => process.stdout.write(`[AU-Host] ${d}`));
      proc.stderr.on('data', (d) => process.stderr.write(`[AU-Host ERR] ${d}`));
      proc.on('close', (code) => {
        console.log(`AU Host exited with code ${code}`);
        if (auHostProc === proc) auHostProc = null;
      });
    }

    for (let i = 0; i < 20; i++) {
      await new Promise((r) => setTimeout(r, 150));
      if (await isAuHostAlive()) return true;
    }
    return false;
  })();

  try {
    return await startPromise;
  } finally {
    startPromise = null;
  }
}

function stopAuHost() {
  if (auHostProc) {
    auHostProc.kill('SIGTERM');
    auHostProc = null;
  }
}

module.exports = {
  AU_HOST_PORT,
  ensureAuHostRunning,
  httpRequest,
  stopAuHost,
};
