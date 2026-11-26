import { state, send } from './state.js';
import { DEVICE_COLORS } from './piano-roll.js';

const AU_HOST_BASE = 'http://127.0.0.1:3099';
const SYNTH_UI_WIDTH_KEY = 'cadenza.synthUiWidth';

let selectedDevIdx = null;
let activeViewWidth = 0;
let activeViewHeight = 0;
let midiAudioEnabled = true;
let nativePoppedOut = false;
let isDraggingMouse = false;
let lastMoveSentAt = 0;
let lastSyncedDevicesSig = '';

function bottomRow() { return document.getElementById('bottomRow'); }
function synthUiCard() { return document.getElementById('synthUiCard'); }
function streamImg() { return document.getElementById('synthUiStream'); }
function loadingEl() { return document.getElementById('synthUiLoading'); }
function statusTextEl() { return document.getElementById('synthUiStatusText'); }

export function synthUiVisible() {
  const row = bottomRow();
  return row ? !row.classList.contains('synth-ui-hidden') : false;
}

export function getSelectedSynthUiDevIdx() {
  return selectedDevIdx;
}

function setSynthUiVisible(on) {
  const row = bottomRow();
  if (row) row.classList.toggle('synth-ui-hidden', !on);
  if (!on) {
    const img = streamImg();
    if (img) img.removeAttribute('src');
  }
}

function setStatusMessage(msg, isError = false) {
  const loading = loadingEl();
  const txt = statusTextEl();
  const viewport = document.getElementById('synthUiViewport');
  if (loading) loading.style.display = 'flex';
  if (viewport) viewport.style.display = 'none';
  if (txt) {
    txt.textContent = msg;
    txt.style.color = isError ? '#f87171' : '';
  }
}

function showStream() {
  const loading = loadingEl();
  const viewport = document.getElementById('synthUiViewport');
  if (loading) loading.style.display = 'none';
  if (viewport) viewport.style.display = 'flex';
}

function updateHeaderForDevice(dev) {
  const badge = document.getElementById('synthUiBadge');
  const title = document.getElementById('synthUiTitle');
  const preset = document.getElementById('synthUiPreset');
  if (badge && dev) {
    const devColor = DEVICE_COLORS[(dev.index - 1) % DEVICE_COLORS.length];
    badge.textContent = String(dev.index);
    badge.style.setProperty('--dev-color', devColor);
    badge.style.setProperty('--dev-bg', devColor + '22');
    badge.style.setProperty('--dev-border', devColor + '66');
  }
  if (title) title.textContent = dev ? dev.uiName : 'Synth UI';
  if (preset) preset.textContent = dev && dev.patchName ? dev.patchName : '';
}

function updateControlButtons() {
  const audioBtn = document.getElementById('btnSynthUiAudio');
  if (audioBtn) {
    audioBtn.textContent = midiAudioEnabled ? '🔊 AU Audio: On' : '🔇 AU Audio: Off';
    audioBtn.classList.toggle('active', midiAudioEnabled);
  }
  const popBtn = document.getElementById('btnSynthUiPopout');
  if (popBtn) {
    popBtn.classList.toggle('active', nativePoppedOut);
  }
}

function clampSynthUiWidth(w) {
  const row = bottomRow();
  const maxW = row ? Math.max(260, row.clientWidth - 260) : 900;
  return Math.min(Math.max(w, 280), maxW);
}

function setSynthUiWidth(w, persist) {
  const row = bottomRow();
  if (!row) return;
  const clamped = clampSynthUiWidth(w);
  row.style.setProperty('--synth-ui-w', clamped + 'px');
  if (persist) localStorage.setItem(SYNTH_UI_WIDTH_KEY, String(Math.round(clamped)));
}

async function postAuHost(path, body) {
  const res = await fetch(`${AU_HOST_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  });
  return res.json();
}

export function onSynthUiStatus(data) {
  if (!data) return;
  if (typeof data.midiEnabled === 'boolean') midiAudioEnabled = data.midiEnabled;
  if (typeof data.poppedOut === 'boolean') nativePoppedOut = data.poppedOut;
  if (data.width > 0 && data.height > 0) {
    activeViewWidth = data.width;
    activeViewHeight = data.height;
  }
  updateControlButtons();
}

export function closeSynthUi() {
  selectedDevIdx = null;
  setSynthUiVisible(false);
  document.querySelectorAll('#devicesWrap tr.row-selected').forEach((tr) => tr.classList.remove('row-selected'));
}

export function syncAuHostDevicesFromState() {
  const devices = (state.chuckState && Array.isArray(state.chuckState.devices)) ? state.chuckState.devices : [];
  const metaMap = state.presetCatalog && state.presetCatalog.synthMeta;
  if (!metaMap) return;

  const arturiaDevices = [];
  const seenApps = new Set();
  const sigParts = [];

  for (const dev of devices) {
    if (!dev || !dev.uiName) continue;
    const meta = metaMap[dev.uiName];
    if (!meta || !meta.appName || seenApps.has(meta.appName)) continue;
    seenApps.add(meta.appName);
    const bank = dev.bank != null ? dev.bank : -1;
    const program = dev.program != null ? dev.program : -1;
    sigParts.push(`${meta.appName}:${bank}:${program}`);
    arturiaDevices.push({
      uiName: dev.uiName,
      appName: meta.appName,
      deviceName: meta.deviceName || '',
      bank,
      program,
      volume: dev.volume != null ? dev.volume : -1,
      volumeCc: meta.volumeCc != null ? meta.volumeCc : 7,
      cutoff: dev.filterCutoff != null ? dev.filterCutoff : -1,
      resonance: dev.filterResonance != null ? dev.filterResonance : -1,
    });
  }

  const sig = sigParts.join('|');
  if (sig === lastSyncedDevicesSig) return;
  lastSyncedDevicesSig = sig;
  postAuHost('/sync', { devices: arturiaDevices }).catch(() => {});
}

export async function selectDeviceForSynthUi(devIdx, { toggleIfSame = false } = {}) {
  const devices = (state.chuckState && Array.isArray(state.chuckState.devices)) ? state.chuckState.devices : [];
  const dev = devices.find((d) => d && d.index === devIdx);
  if (!dev) return;

  if (toggleIfSame && selectedDevIdx === devIdx && synthUiVisible()) {
    closeSynthUi();
    return;
  }

  selectedDevIdx = devIdx;
  document.querySelectorAll('#devicesWrap tr[data-dev]').forEach((tr) => {
    tr.classList.toggle('row-selected', parseInt(tr.dataset.dev, 10) === devIdx);
  });

  const metaMap = state.presetCatalog && state.presetCatalog.synthMeta;
  const meta = metaMap && metaMap[dev.uiName];
  if (!meta || !meta.appName) {
    setSynthUiVisible(true);
    updateHeaderForDevice(dev);
    setStatusMessage(`${dev.uiName} is a hardware synth (no Arturia AU plugin).`);
    return;
  }

  setSynthUiVisible(true);
  updateHeaderForDevice(dev);
  setStatusMessage(`Loading ${dev.uiName} AudioUnit…`);

  const selectPayload = {
    uiName: dev.uiName,
    appName: meta.appName,
    deviceName: meta.deviceName || '',
    bank: dev.bank != null ? dev.bank : -1,
    program: dev.program != null ? dev.program : -1,
    volume: dev.volume != null ? dev.volume : -1,
    volumeCc: meta.volumeCc != null ? meta.volumeCc : 7,
    cutoff: dev.filterCutoff != null ? dev.filterCutoff : -1,
    resonance: dev.filterResonance != null ? dev.filterResonance : -1,
  };

  // Notify Node bridge if updated server.js is running; also hit local AU host directly for PoC
  send('selectSynthUi', selectPayload);

  try {
    const data = await postAuHost('/select', selectPayload);
    if (selectedDevIdx !== devIdx) return;
    if (!data || !data.ok) {
      setStatusMessage((data && data.error) || `Failed to load ${dev.uiName} AudioUnit`, true);
      return;
    }
    onSynthUiStatus(data);
    const img = streamImg();
    if (img) {
      img.onload = () => showStream();
      img.src = `${AU_HOST_BASE}/stream.mjpeg?t=${Date.now()}`;
    }
  } catch (err) {
    if (selectedDevIdx !== devIdx) return;
    setStatusMessage(`AU Host not running on ${AU_HOST_BASE} (${err.message}). Start tools/au-host.`, true);
  }
}

export async function toggleSynthUiAudio() {
  const next = !midiAudioEnabled;
  try {
    const data = await postAuHost('/midi', { enabled: next });
    onSynthUiStatus(data);
  } catch (_) {
    send('synthUiMidi', { enabled: next });
  }
}

export async function popoutSynthUi() {
  try {
    const data = await postAuHost('/popout', {});
    onSynthUiStatus(data);
  } catch (_) {
    send('synthUiPopout', {});
  }
}

function getNormalizedImagePoint(img, clientX, clientY) {
  const rect = img.getBoundingClientRect();
  if (rect.width <= 0 || rect.height <= 0) return null;

  const natW = img.naturalWidth || activeViewWidth || rect.width;
  const natH = img.naturalHeight || activeViewHeight || rect.height;
  const imgAspect = natW / natH;
  const boxAspect = rect.width / rect.height;

  let drawW = rect.width;
  let drawH = rect.height;
  let offsetX = 0;
  let offsetY = 0;

  if (boxAspect > imgAspect) {
    drawW = rect.height * imgAspect;
    offsetX = (rect.width - drawW) / 2;
  } else {
    drawH = rect.width / imgAspect;
    offsetY = (rect.height - drawH) / 2;
  }

  const x = (clientX - rect.left - offsetX) / drawW;
  const y = (clientY - rect.top - offsetY) / drawH;
  if (x < 0 || x > 1 || y < 0 || y > 1) return null;
  return { x, y };
}

function sendMouseEvent(type, pt, deltaY = 0) {
  if (!pt) return;
  postAuHost('/mouse', { type, x: pt.x, y: pt.y, deltaY }).catch(() => {});
}

export function initSynthUi() {
  const savedW = parseFloat(localStorage.getItem(SYNTH_UI_WIDTH_KEY));
  if (!isNaN(savedW) && savedW > 0) {
    setSynthUiWidth(savedW, false);
  }

  const divider = document.getElementById('synthUiDivider');
  const row = bottomRow();
  if (divider && row) {
    let dragging = false;
    divider.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      dragging = true;
      divider.classList.add('dragging');
      document.body.classList.add('graph-resizing');
      divider.setPointerCapture(e.pointerId);
    });
    divider.addEventListener('pointermove', (e) => {
      if (!dragging) return;
      const rowRect = row.getBoundingClientRect();
      setSynthUiWidth(rowRect.right - e.clientX, false);
    });
    const endDrag = (e) => {
      if (!dragging) return;
      dragging = false;
      divider.classList.remove('dragging');
      document.body.classList.remove('graph-resizing');
      if (divider.hasPointerCapture(e.pointerId)) {
        divider.releasePointerCapture(e.pointerId);
      }
      const card = synthUiCard();
      if (card) setSynthUiWidth(card.getBoundingClientRect().width, true);
    };
    divider.addEventListener('pointerup', endDrag);
    divider.addEventListener('pointercancel', endDrag);
  }

  const img = streamImg();
  if (img) {
    img.addEventListener('mousedown', (e) => {
      if (e.button !== 0) return;
      e.preventDefault();
      const pt = getNormalizedImagePoint(img, e.clientX, e.clientY);
      if (!pt) return;
      isDraggingMouse = true;
      sendMouseEvent('down', pt);
    });

    window.addEventListener('mousemove', (e) => {
      const pt = getNormalizedImagePoint(img, e.clientX, e.clientY);
      const now = performance.now();
      if (isDraggingMouse) {
        const clamped = pt || {
          x: Math.max(0, Math.min(1, (e.clientX - img.getBoundingClientRect().left) / Math.max(1, img.getBoundingClientRect().width))),
          y: Math.max(0, Math.min(1, (e.clientY - img.getBoundingClientRect().top) / Math.max(1, img.getBoundingClientRect().height))),
        };
        if (now - lastMoveSentAt >= 16) {
          lastMoveSentAt = now;
          sendMouseEvent('drag', clamped);
        }
      } else if (pt && synthUiVisible() && now - lastMoveSentAt >= 35) {
        lastMoveSentAt = now;
        sendMouseEvent('move', pt);
      }
    });

    window.addEventListener('mouseup', (e) => {
      if (!isDraggingMouse) return;
      isDraggingMouse = false;
      const rect = img.getBoundingClientRect();
      const pt = getNormalizedImagePoint(img, e.clientX, e.clientY) || {
        x: Math.max(0, Math.min(1, (e.clientX - rect.left) / Math.max(1, rect.width))),
        y: Math.max(0, Math.min(1, (e.clientY - rect.top) / Math.max(1, rect.height))),
      };
      sendMouseEvent('up', pt);
    });

    img.addEventListener('wheel', (e) => {
      const pt = getNormalizedImagePoint(img, e.clientX, e.clientY);
      if (!pt) return;
      e.preventDefault();
      sendMouseEvent('wheel', pt, e.deltaY);
    }, { passive: false });
  }
}
