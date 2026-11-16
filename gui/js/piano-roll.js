import { state } from './state.js';

export const DEVICE_COLORS = [
  '#06b6d4', // Dev 1: Luminous Cyan
  '#a855f7', // Dev 2: Neon Purple / Violet
  '#f59e0b', // Dev 3: Vivid Amber
  '#10b981', // Dev 4: Emerald Green
  '#f43f5e', // Dev 5: Electric Rose
  '#3b82f6', // Dev 6: Royal Blue
  '#ff6b4a', // Dev 7: Bright Coral
  '#eab308', // Dev 8: Gold
];

const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];

const DRUM_NAMES = {
  36: 'Bass Drum',
  40: 'Snare Drum',
  45: 'Low Tom',
  50: 'Hi Tom',
  39: 'Clap',
  51: 'Cymbal',
  46: 'Open Hat',
  42: 'Closed Hat',
};

function getNoteLabel(midiNote) {
  if (midiNote < 0) {
    const note = midiNote + 2000;
    return DRUM_NAMES[note] || `Drum ${note}`;
  }
  const name = NOTE_NAMES[midiNote % 12];
  const oct = Math.floor(midiNote / 12) - 1;
  return name + oct;
}

const drumDeviceCache = new Map();

export function clearDrumCache() {
  drumDeviceCache.clear();
}

export function isDrumDevice(devIdx) {
  if (drumDeviceCache.has(devIdx)) return drumDeviceCache.get(devIdx);
  if (!state.chuckState || !state.chuckState.devices) return false;
  const dev = state.chuckState.devices.find(d => d.index === devIdx);
  let result = false;
  if (dev) {
    const isV3 = Boolean(dev.uiName && dev.uiName.toLowerCase() === 'v3');
    const isSteelDrums = [dev.uiName, dev.patchName]
      .some(n => n && n.toLowerCase().includes('steel drum'));
    if (isSteelDrums) result = false;
    else if (dev.channel === 10) result = true;
    else if (dev.uiName && (dev.uiName.toLowerCase().includes('drum') || dev.uiName.toLowerCase().includes('kit') || dev.uiName.toLowerCase().includes(' kick'))) result = true;
    else if (isV3 && dev.patchName && (dev.patchName.toLowerCase().includes('drum') || dev.patchName.toLowerCase().includes('kit') || dev.patchName.toLowerCase().includes(' kick'))) result = true;
  }
  drumDeviceCache.set(devIdx, result);
  return result;
}

const activePitchRows = [];
const activePitchRowSet = new Set();
let activePitchRowsDirty = false;
const noteBlocks = [];
let noteBlocksReadIdx = 0;
const activeNotesMap = new Map();
const pitchDevices = new Map();

export function clearNotes() {
  activePitchRows.length = 0;
  activePitchRowSet.clear();
  activePitchRowsDirty = true;
  noteBlocks.length = 0;
  noteBlocksReadIdx = 0;
  activeNotesMap.clear();
  pitchDevices.clear();
}

function addPitchRow(pitchKey) {
  if (!activePitchRowSet.has(pitchKey)) {
    activePitchRowSet.add(pitchKey);
    activePitchRows.push(pitchKey);
    activePitchRowsDirty = true;
  }
}

function getOrAssignDevIdx(pitchKey, dev) {
  let devMap = pitchDevices.get(pitchKey);
  if (!devMap) { devMap = new Map(); pitchDevices.set(pitchKey, devMap); }
  if (!devMap.has(dev)) { devMap.set(dev, devMap.size); }
  return devMap.get(dev);
}

export function onNoteOn(dev, note) {
  const now = performance.now();
  const isDrum = isDrumDevice(dev);
  const pitchKey = isDrum ? -2000 + note : note;
  addPitchRow(pitchKey);

  const key = `${dev}-${pitchKey}`;
  const existing = activeNotesMap.get(key);
  if (existing) {
    existing.endT = Math.max(existing.startT + 1, now - 2);
    activeNotesMap.delete(key);
  }

  const endT = isDrum ? (now + 60) : null;
  const color = DEVICE_COLORS[(dev - 1) % DEVICE_COLORS.length];
  const devIdx = getOrAssignDevIdx(pitchKey, dev);
  const block = { dev, pitchKey, isDrum, startT: now, endT, color, devIdx };
  noteBlocks.push(block);

  if (noteBlocks.length - noteBlocksReadIdx > 3000) {
    noteBlocksReadIdx = noteBlocks.length - 3000;
  }
  if (noteBlocksReadIdx > 1000) {
    noteBlocks.splice(0, noteBlocksReadIdx);
    noteBlocksReadIdx = 0;
  }

  if (!isDrum) {
    activeNotesMap.set(key, block);
  }
}

export function onNoteOff(dev, note) {
  const now = performance.now();
  if (isDrumDevice(dev)) return;

  const key = `${dev}-${note}`;
  const block = activeNotesMap.get(key);
  if (block) {
    block.endT = Math.max(block.startT + 1, now);
    activeNotesMap.delete(key);
  }
}

export function onAllNotesOff(dev) {
  const now = performance.now();
  for (const [key, block] of activeNotesMap.entries()) {
    if (!dev || block.dev === dev) {
      block.endT = Math.max(block.startT + 1, now);
      activeNotesMap.delete(key);
    }
  }
}

let scrollAnimationId = null;

export function initScrollCanvas() {
  const canvas = document.getElementById('scrollCanvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d', { alpha: false });
  const bgCanvas = document.createElement('canvas');
  const bgCtx = bgCanvas.getContext('2d', { alpha: false });
  let bgDirty = true;
  let lastRowCount = -1;

  const gutterW = 96;
  const playheadX = gutterW;
  const pxPerMs = 0.12;

  let cachedDpr = window.devicePixelRatio || 1;
  let cachedW = 0;
  let cachedH = 0;

  const ro = new ResizeObserver(entries => {
    for (const entry of entries) {
      const dpr = window.devicePixelRatio || 1;
      const w = entry.contentRect.width;
      const h = entry.contentRect.height;
      const targetW = Math.floor(w * dpr);
      const targetH = Math.floor(h * dpr);
      if (canvas.width !== targetW || canvas.height !== targetH) {
        canvas.width = targetW;
        canvas.height = targetH;
      }
      if (cachedDpr !== dpr || cachedW !== w || cachedH !== h) {
        bgDirty = true;
      }
      cachedDpr = dpr;
      cachedW = w;
      cachedH = h;
    }
  });
  ro.observe(canvas);

  function renderStaticBg(w, h, dpr) {
    const targetW = Math.floor(w * dpr);
    const targetH = Math.floor(h * dpr);
    if (bgCanvas.width !== targetW || bgCanvas.height !== targetH) {
      bgCanvas.width = targetW;
      bgCanvas.height = targetH;
    }

    bgCtx.save();
    bgCtx.scale(dpr, dpr);
    bgCtx.fillStyle = '#080512';
    bgCtx.fillRect(0, 0, w, h);

    const rowCount = Math.max(1, activePitchRows.length);
    const rowH = h / rowCount;

    bgCtx.strokeStyle = 'rgba(110, 70, 240, 0.22)';
    bgCtx.lineWidth = 1;
    bgCtx.beginPath();
    for (let i = 0; i < activePitchRows.length; i++) {
      const y = i * rowH;
      bgCtx.moveTo(gutterW, y + rowH);
      bgCtx.lineTo(w, y + rowH);
    }
    bgCtx.stroke();

    bgCtx.fillStyle = '#0a0718';
    bgCtx.fillRect(0, 0, gutterW, h);
    bgCtx.strokeStyle = 'rgba(110, 70, 240, 0.3)';
    bgCtx.lineWidth = 1;
    bgCtx.beginPath();
    bgCtx.moveTo(gutterW, 0);
    bgCtx.lineTo(gutterW, h);
    bgCtx.stroke();

    bgCtx.textAlign = 'right';
    bgCtx.textBaseline = 'middle';
    bgCtx.font = '600 11px "JetBrains Mono", monospace';
    for (let i = 0; i < activePitchRows.length; i++) {
      const pKey = activePitchRows[i];
      const y = i * rowH;
      bgCtx.fillStyle = (pKey < 0) ? '#fbbf24' : '#a78bfa';
      bgCtx.fillText(getNoteLabel(pKey), gutterW - 10, y + rowH / 2);
    }

    bgCtx.restore();
    lastRowCount = activePitchRows.length;
    bgDirty = false;
  }

  const pitchRowIndex = new Map();

  function renderFrame(now) {
    scrollAnimationId = requestAnimationFrame(renderFrame);

    const dpr = cachedDpr;
    const w = cachedW;
    const h = cachedH;
    if (w === 0 || h === 0) return;

    if (activePitchRowsDirty) {
      activePitchRows.sort((a, b) => b - a);
      pitchRowIndex.clear();
      for (let i = 0; i < activePitchRows.length; i++) pitchRowIndex.set(activePitchRows[i], i);
      activePitchRowsDirty = false;
      bgDirty = true;
    }
    if (activePitchRows.length !== lastRowCount) {
      bgDirty = true;
    }

    if (bgDirty) {
      renderStaticBg(w, h, dpr);
    }
    if (bgCanvas.width > 0 && bgCanvas.height > 0) {
      ctx.drawImage(bgCanvas, 0, 0);
    }

    ctx.save();
    ctx.scale(dpr, dpr);

    for (const [key, block] of activeNotesMap.entries()) {
      if (block.endT === null && (now - block.startT) > 15000) {
        block.endT = block.startT + 15000;
        activeNotesMap.delete(key);
      }
    }

    while (
      noteBlocksReadIdx < noteBlocks.length &&
      noteBlocks[noteBlocksReadIdx].endT !== null &&
      (playheadX + (now - noteBlocks[noteBlocksReadIdx].endT) * pxPerMs) > w
    ) {
      noteBlocksReadIdx++;
    }
    if (noteBlocksReadIdx > 500) {
      noteBlocks.splice(0, noteBlocksReadIdx);
      noteBlocksReadIdx = 0;
    }

    const rowCount = Math.max(1, activePitchRows.length);
    const rowH = h / rowCount;

    const pathByColor = new Map();
    const flashes = [];
    let deadCount = 0;

    for (let i = noteBlocksReadIdx; i < noteBlocks.length; i++) {
      const block = noteBlocks[i];

      const leadX = playheadX + (now - block.startT) * pxPerMs;
      const trailX = (block.endT === null) ? playheadX : (playheadX + (now - block.endT) * pxPerMs);
      let blockW = leadX - trailX;
      if (blockW < 2) blockW = 2;

      if (trailX > w) {
        deadCount++;
        continue;
      }

      const drawX = Math.max(playheadX, trailX);
      const drawW = Math.min(w - drawX, blockW - (drawX - trailX));
      if (drawW <= 0) continue;

      const rowI = pitchRowIndex.get(block.pitchKey);
      if (rowI === undefined) continue;
      const rowY = rowI * rowH;

      const devMap = pitchDevices.get(block.pitchKey);
      const devCount = devMap ? devMap.size : 1;
      const subH = Math.max(3, (rowH - 2) / devCount);
      const y = rowY + 1 + block.devIdx * subH;

      let path = pathByColor.get(block.color);
      if (!path) { path = new Path2D(); pathByColor.set(block.color, path); }

      const r = Math.min(3, subH / 2, drawW / 2);
      if (r >= 1.5 && path.roundRect) {
        path.roundRect(drawX, y, drawW, subH - 1, r);
      } else {
        path.rect(drawX, y, drawW, subH - 1);
      }

      const age = now - block.startT;
      if (age < 400) {
        const alpha = 1 - (age / 400);
        const expand = 4 * Math.sin(alpha * Math.PI / 2);
        flashes.push({ x: drawX, y: y - expand, w: drawW, h: subH - 1 + expand * 2, r, alpha });
      }
    }

    if (deadCount > 250) {
      let writeIdx = 0;
      for (let i = noteBlocksReadIdx; i < noteBlocks.length; i++) {
        const block = noteBlocks[i];
        if (block.endT === null || (playheadX + (now - block.endT) * pxPerMs) <= w) {
          noteBlocks[writeIdx++] = block;
        }
      }
      noteBlocks.length = writeIdx;
      noteBlocksReadIdx = 0;
    }

    ctx.lineJoin = 'round';
    for (const [color, path] of pathByColor.entries()) {
      ctx.globalAlpha = 0.22;
      ctx.lineWidth = 4;
      ctx.strokeStyle = color;
      ctx.stroke(path);
      ctx.globalAlpha = 1;
      ctx.fillStyle = color;
      ctx.fill(path);
    }

    for (const f of flashes) {
      const brightAlpha = Math.pow(f.alpha, 0.6);
      ctx.fillStyle = `rgba(255, 255, 255, ${brightAlpha * 0.22})`;
      ctx.fillRect(f.x - 3, f.y - 3, f.w + 6, f.h + 6);
      ctx.fillStyle = `rgba(255, 255, 255, ${brightAlpha})`;
      if (f.r >= 1.5 && ctx.roundRect) {
        ctx.beginPath();
        ctx.roundRect(f.x, f.y, f.w, f.h, f.r);
        ctx.fill();
      } else {
        ctx.fillRect(f.x, f.y, f.w, f.h);
      }
    }

    ctx.restore();
  }

  if (scrollAnimationId) cancelAnimationFrame(scrollAnimationId);
  scrollAnimationId = requestAnimationFrame(renderFrame);
}
