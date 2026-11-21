import { PRESET_CATALOG } from './catalog-data.js';

export const MOOG_CATEGORIES = Array.isArray(PRESET_CATALOG.moogBanks)
  ? PRESET_CATALOG.moogBanks
  : [];

export const REGISTERED_SYNTHS = Array.isArray(PRESET_CATALOG.synths)
  ? PRESET_CATALOG.synths
  : ['V3', 'Hydrasynth', 'SH-4d', 'S-1', 'Moog', 'RD-6'];

export const state = {
  chuckState: null,
  ws: null,
  reconnect: null,
  songs: [],
  selectedSongIdx: -1,
  selectedDevIdx: null,
  presetCatalog: Object.assign({ V3: [], Hydrasynth: [], 'SH-4d': [], Moog: [] }, PRESET_CATALOG),
  presetModalState: null,
  patchSetsState: { songName: '', patchSets: ['Default'], defaultPatchSet: 'Default' },
  activePatchSetName: 'Default',
  pendingDeletePatchSetName: null,
  pendingFocusNewPatchSet: false,
  isSongReset: true,
  initialStateReceived: false,
  playFromResetTime: 0,
  currentSongName: null,
  isDragging: false,
  chuckGraph: [],
  lastTransition: null,
  baselineState: null,
  pendingBaselineReset: false,
  patchSetLoadStage: null,
  patchSetLoadTimer: null,
};

const ui = {
  render: () => {},
  updateGraph: () => {},
  clearNotes: () => {},
  clearDrumCache: () => {},
  onNoteOn: () => {},
  onNoteOff: () => {},
  onAllNotesOff: () => {},
  flashTransition: () => {},
  renderSongList: () => {},
  renderPatchSetList: () => {},
  renderDiffModal: () => {},
  syncTempoSlider: () => {},
};

export function registerUiCallbacks(cbs) {
  Object.assign(ui, cbs);
}

export function esc(s) {
  if (s == null) return '';
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

export function normalizeMoogDevicePatchName(dev) {
  if (!dev || dev.uiName !== 'Moog') return;
  if (dev.bank != null && dev.program != null && dev.bank >= 0 && dev.bank < 16 && dev.program >= 0 && dev.program < 16) {
    dev.patchName = MOOG_CATEGORIES[dev.bank] + ': ' + (dev.program + 1);
  } else if (dev.patchName) {
    dev.patchName = String(dev.patchName).replace(/\s+Program:\s*/g, ': ');
  }
}

export function mergePresetCatalog(incoming) {
  if (!incoming || typeof incoming !== 'object') return;
  for (const [k, v] of Object.entries(incoming)) {
    if (Array.isArray(v)) {
      if (v.length > 0 || !Array.isArray(state.presetCatalog[k]) || state.presetCatalog[k].length === 0) {
        state.presetCatalog[k] = v;
      }
    } else if (v && typeof v === 'object') {
      state.presetCatalog[k] = Object.assign({}, state.presetCatalog[k] || {}, v);
    }
  }
  if (Array.isArray(state.presetCatalog.Moog)) {
    state.presetCatalog.Moog = state.presetCatalog.Moog.map(p => (
      p && p.name
        ? Object.assign({}, p, { name: String(p.name).replace(/\s+Program:\s*/g, ': ') })
        : p
    ));
  }
}

export function setConnected(ok) {
  const dot = document.getElementById('statusDot');
  const text = document.getElementById('statusText');
  if (dot) dot.className = 'status-dot ' + (ok ? 'connected' : 'disconnected');
  if (text) text.textContent = ok ? 'Connected' : 'Disconnected — retrying…';
}

export function send(type, value) {
  if (!state.ws || state.ws.readyState !== WebSocket.OPEN) return;
  state.ws.send(JSON.stringify({ type, value }));
}

export function syncSongInfo() {
  const s = state.chuckState;
  if (!s) return;
  const songEl = document.getElementById('songNameDisplay');
  if (songEl) {
    songEl.textContent = s.songName || '—';
    if (state.currentSongName !== s.songName) {
      if (state.currentSongName !== null) ui.clearNotes();
      state.currentSongName = s.songName;
    }
  }
  const fragEl = document.getElementById('fragmentNameDisplay');
  if (fragEl) {
    fragEl.textContent = state.isSongReset ? '—' : (s.fragmentName || '—');
  }
}

const YAML_DEVICE_FIELDS = [
  { key: 'uiName', label: 'Synth', format: v => String(v) },
  { key: 'channel', label: 'Channel', format: v => String(v) },
  { key: 'patchName', label: 'Patch', format: v => String(v) },
  { key: 'volume', label: 'Volume', format: v => String(v) },
  { key: 'filterCutoff', label: 'Cutoff', format: v => String(v) },
  { key: 'filterResonance', label: 'Resonance', format: v => String(v) },
  { key: 'pan', label: 'Pan', format: v => String(v) },
  { key: 'muted', label: 'Mute', format: v => (v ? 'On' : 'Off') },
];

export function createYamlSnapshot(s) {
  if (!s || !Array.isArray(s.devices)) return null;
  return {
    bpm: s.bpm != null ? Math.round(Number(s.bpm)) : 120,
    devices: s.devices.map(d => {
      const copy = {
        index: d.index,
        uiName: d.uiName || '',
        channel: d.channel != null ? Number(d.channel) : 1,
        patchName: d.patchName != null ? String(d.patchName) : '',
        bank: d.bank,
        program: d.program,
        volume: d.volume != null ? Number(d.volume) : 0,
        filterCutoff: (d.filterCutoff == null || d.filterCutoff === -1) ? 64 : Number(d.filterCutoff),
        filterResonance: (d.filterResonance == null || d.filterResonance === -1) ? 64 : Number(d.filterResonance),
        pan: d.pan != null ? Number(d.pan) : 0,
        muted: d.muted ? 1 : 0,
      };
      normalizeMoogDevicePatchName(copy);
      return {
        index: copy.index,
        uiName: copy.uiName,
        channel: copy.channel,
        patchName: copy.patchName,
        volume: copy.volume,
        filterCutoff: copy.filterCutoff,
        filterResonance: copy.filterResonance,
        pan: copy.pan,
        muted: copy.muted,
      };
    }),
  };
}

export function computeYamlDiffs() {
  if (!state.baselineState || !state.chuckState) return [];
  const base = state.baselineState;
  const curr = createYamlSnapshot(state.chuckState);
  if (!curr) return [];

  const diffs = [];
  if (base.bpm !== curr.bpm) {
    diffs.push({
      devIndex: null,
      synthName: null,
      channel: null,
      field: 'Tempo',
      oldValue: String(base.bpm),
      newValue: String(curr.bpm),
    });
  }

  const baseByIndex = new Map(base.devices.map(d => [d.index, d]));
  for (const dev of curr.devices) {
    const baseDev = baseByIndex.get(dev.index);
    if (!baseDev) continue;
    for (const { key, label, format } of YAML_DEVICE_FIELDS) {
      if (baseDev[key] !== dev[key]) {
        diffs.push({
          devIndex: dev.index,
          synthName: dev.uiName,
          channel: dev.channel,
          field: label,
          oldValue: format(baseDev[key]),
          newValue: format(dev[key]),
        });
      }
    }
  }
  return diffs;
}

export function resetYamlBaseline(s = state.chuckState) {
  state.baselineState = createYamlSnapshot(s);
  syncPatchSetButton();
}

export function beginPatchSetLoad() {
  clearTimeout(state.patchSetLoadTimer);
  state.patchSetLoadStage = 'waitingForPatchSets';
  state.baselineState = createYamlSnapshot(state.chuckState);
  state.patchSetLoadTimer = setTimeout(() => {
    state.patchSetLoadStage = null;
  }, 800);
}

export function syncPatchSetButton() {
  const btn = document.getElementById('btnPatchSet');
  if (!btn) return;
  const name = (state.chuckState && state.chuckState.patchSetName)
    || state.activePatchSetName
    || state.patchSetsState.defaultPatchSet
    || 'Default';
  state.activePatchSetName = name;
  btn.textContent = name;

  const diffs = computeYamlDiffs();
  const isDirty = diffs.length > 0;
  btn.classList.toggle('is-dirty', isDirty);

  const diffBtn = document.getElementById('btnDiff');
  if (diffBtn) {
    diffBtn.disabled = !isDirty;
  }

  const diffModal = document.getElementById('diffModal');
  if (diffModal && diffModal.classList.contains('open')) {
    ui.renderDiffModal();
  }
}

export function syncModeButtons() {
  const s = state.chuckState;
  if (!s) return;
  const btnGolden = document.getElementById('btnGolden');
  const btnAllMode = document.getElementById('btnAllMode');
  if (btnGolden) btnGolden.classList.toggle('active', !!s.golden);
  if (btnAllMode) btnAllMode.classList.toggle('active', !!s.allMode);
  ui.syncTempoSlider(s.bpm);
  syncSongInfo();
  syncPatchSetButton();

  const btn = document.getElementById('btnPlayPause');
  if (btn) {
    if (s.isPaused) {
      btn.innerHTML = '▶';
      btn.setAttribute('data-tooltip', 'Play');
    } else {
      btn.innerHTML = '⏸';
      btn.setAttribute('data-tooltip', 'Pause');
    }
  }
}

export function togglePlayPause() {
  if (!state.chuckState) return;
  if (state.chuckState.isPaused) {
    if (state.isSongReset) {
      state.isSongReset = false;
      state.lastTransition = null;
      state.playFromResetTime = performance.now();
      if (state.chuckGraph && state.chuckGraph.length > 0) {
        state.chuckState.fragmentName = state.chuckGraph[0].name;
        state.chuckState.repeatIndex = 1;
      }
    }
    send('play');
    state.chuckState.isPaused = 0;
    const btn = document.getElementById('btnPlayPause');
    if (btn) {
      btn.innerHTML = '⏸';
      btn.setAttribute('data-tooltip', 'Pause');
    }
    ui.updateGraph(false);
    syncSongInfo();
  } else {
    send('pause');
    state.chuckState.isPaused = 1;
    const btn = document.getElementById('btnPlayPause');
    if (btn) {
      btn.innerHTML = '▶';
      btn.setAttribute('data-tooltip', 'Play');
    }
  }
}

export function doRestart() {
  state.isSongReset = true;
  state.lastTransition = null;
  if (state.chuckState) {
    state.chuckState.isPaused = 1;
    state.chuckState.nextFragmentName = '';
  }
  send('restart');
  ui.clearNotes();
  const btn = document.getElementById('btnPlayPause');
  if (btn) {
    btn.innerHTML = '▶';
    btn.setAttribute('data-tooltip', 'Play');
  }
  ui.updateGraph(false);
  syncSongInfo();
}

export function doSave() {
  send('save');
  resetYamlBaseline(state.chuckState);
  const btn = document.getElementById('btnSave');
  if (!btn) return;
  btn.classList.remove('btn-flash-save');
  void btn.offsetWidth;
  btn.classList.add('btn-flash-save');
  btn.addEventListener('animationend', () => btn.classList.remove('btn-flash-save'), { once: true });
}

export function connect() {
  state.ws = new WebSocket('ws://localhost:3000');

  state.ws.addEventListener('open', () => {
    setConnected(true);
    clearTimeout(state.reconnect);
  });

  state.ws.addEventListener('message', ({ data }) => {
    try {
      const msg = JSON.parse(data);
      if (msg.type === 'state') {
        const songChanged = state.chuckState && msg.data && state.chuckState.songName !== msg.data.songName;
        state.chuckState = msg.data;
        if (state.chuckState && Array.isArray(state.chuckState.devices)) {
          state.chuckState.devices.forEach(normalizeMoogDevicePatchName);
        }
        if (!state.baselineState || songChanged || state.pendingBaselineReset) {
          state.baselineState = createYamlSnapshot(state.chuckState);
          state.pendingBaselineReset = false;
        } else if (state.patchSetLoadStage === 'waitingForPatchSets') {
          state.baselineState = createYamlSnapshot(state.chuckState);
        } else if (state.patchSetLoadStage === 'waitingForChuckState') {
          state.patchSetLoadStage = null;
          clearTimeout(state.patchSetLoadTimer);
          state.baselineState = createYamlSnapshot(state.chuckState);
        }
        if (!state.initialStateReceived) {
          state.initialStateReceived = true;
          if (!state.chuckState.isPaused) {
            state.isSongReset = false;
          }
        } else if (songChanged && state.chuckState.isPaused) {
          state.isSongReset = true;
          state.lastTransition = null;
        }
        if (!state.isSongReset && performance.now() - state.playFromResetTime < 150 && state.chuckGraph && state.chuckGraph.length > 0) {
          state.chuckState.fragmentName = state.chuckGraph[0].name;
        }
        if (state.chuckState.patchSetName) {
          state.activePatchSetName = state.chuckState.patchSetName;
        }
        if (state.chuckState.defaultPatchSetName) {
          state.patchSetsState.defaultPatchSet = state.chuckState.defaultPatchSetName;
        }
        if (songChanged) {
          send('getPatchSets', { songName: state.chuckState.songName });
        }
        ui.clearDrumCache();
        ui.render();
        ui.updateGraph(false);
        const patchSetModal = document.getElementById('patchSetModal');
        if (patchSetModal && patchSetModal.classList.contains('open')) {
          ui.renderPatchSetList();
        }
      } else if (msg.type === 'patchSets') {
        if (msg.data) {
          if (state.patchSetLoadStage === 'waitingForPatchSets') {
            state.patchSetLoadStage = 'waitingForChuckState';
          }
          state.patchSetsState = {
            songName: msg.data.songName || '',
            patchSets: Array.isArray(msg.data.patchSets) ? msg.data.patchSets : [],
            defaultPatchSet: msg.data.defaultPatchSet || 'Default',
          };
          if (!state.activePatchSetName || (state.patchSetsState.patchSets.length > 0 && !state.patchSetsState.patchSets.includes(state.activePatchSetName))) {
            state.activePatchSetName = (state.chuckState && state.chuckState.patchSetName && state.patchSetsState.patchSets.includes(state.chuckState.patchSetName))
              ? state.chuckState.patchSetName
              : (state.patchSetsState.defaultPatchSet || state.patchSetsState.patchSets[0] || 'Default');
          }
          syncPatchSetButton();
          const patchSetModal = document.getElementById('patchSetModal');
          if (patchSetModal && patchSetModal.classList.contains('open')) {
            const shouldFocusNew = state.pendingFocusNewPatchSet;
            state.pendingFocusNewPatchSet = false;
            ui.renderPatchSetList(shouldFocusNew);
            if (shouldFocusNew) {
              const input = document.getElementById('patchSetNameInput');
              if (input) {
                input.focus();
                input.select();
              }
            }
          } else {
            state.pendingFocusNewPatchSet = false;
          }
        }
      } else if (msg.type === 'graph') {
        state.chuckGraph = msg.fragments || [];
        ui.updateGraph(false);
      } else if (msg.type === 'transition') {
        if (!state.isSongReset && !(state.chuckState && state.chuckState.isPaused) && performance.now() - state.playFromResetTime >= 150) {
          ui.flashTransition(msg.from, msg.to);
        }
      } else if (msg.type === 'noteOn') {
        ui.onNoteOn(msg.dev, msg.note, msg.vel);
      } else if (msg.type === 'noteOff') {
        ui.onNoteOff(msg.dev, msg.note);
      } else if (msg.type === 'allNotesOff') {
        ui.onAllNotesOff(msg.dev);
      } else if (msg.type === 'songList') {
        state.songs = msg.songs.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
        ui.renderSongList();
      } else if (msg.type === 'presets') {
        if (msg.data) {
          mergePresetCatalog(msg.data);
        }
      }
    } catch (e) {
      console.error('Parse error:', e);
    }
  });

  state.ws.addEventListener('close', () => {
    setConnected(false);
    state.reconnect = setTimeout(connect, 2000);
  });
  state.ws.addEventListener('error', () => state.ws.close());
}
