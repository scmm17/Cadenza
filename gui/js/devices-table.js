import {
  state,
  REGISTERED_SYNTHS,
  esc,
  normalizeMoogDevicePatchName,
  send,
  syncModeButtons,
  syncPatchSetButton,
} from './state.js';
import { DEVICE_COLORS, clearDrumCache, isDrumDevice } from './piano-roll.js';

let activeDrag = null;
let activeInlineEdit = null;
let volSliderTimer = null;

const NOTE_SAFETY_TIMEOUT_MS = 15000;
const DRUM_HIGHLIGHT_MS = 60;
const CHORD_COALESCE_MS = 25;
const RETRIGGER_WINDOW_MS = 140;
// Map<devIdx, Map<midiNote, number[]>> — FIFO queues of safety timeout IDs per (dev, note)
// so overlapping notes (both polyphonic and same-pitch retriggers) stay lit until all end.
const activeDeviceNotes = new Map();
// Map<devIdx, number> — short auto-off timers for drum machine devices (independent of noteOff).
const activeDrumTimers = new Map();
// Timestamps and active WAAPI re-articulation animations for contiguous/overlapping note onsets.
const lastNoteOnTime = new Map();
const lastNoteOffTime = new Map();
const activeRetriggerAnims = new Map();

const modalCallbacks = {
  openPresetModal: () => {},
  openWarningModal: () => {},
};

export function registerDeviceModalCallbacks(cbs) {
  Object.assign(modalCallbacks, cbs);
}

function isDeviceNoteActive(devIdx) {
  if (activeDrumTimers.has(devIdx)) return true;
  const notes = activeDeviceNotes.get(devIdx);
  return Boolean(notes && notes.size > 0);
}

function cancelRetriggerAnim(devIdx) {
  const anim = activeRetriggerAnims.get(devIdx);
  if (anim) {
    anim.cancel();
    activeRetriggerAnims.delete(devIdx);
  }
}

function triggerBadgeRearticulate(devIdx, isDrum) {
  const badge = document.getElementById('dev-badge-' + devIdx);
  const bg = badge && badge.querySelector('.device-badge-bg');
  if (!bg || typeof bg.animate !== 'function') return;
  cancelRetriggerAnim(devIdx);
  const anim = bg.animate(
    [
      { opacity: 0.14 },
      { opacity: 0.14, offset: 0.25 },
      { opacity: 1 },
    ],
    {
      duration: isDrum ? 75 : 100,
      easing: 'ease-out',
    }
  );
  activeRetriggerAnims.set(devIdx, anim);
  anim.onfinish = () => {
    if (activeRetriggerAnims.get(devIdx) === anim) {
      activeRetriggerAnims.delete(devIdx);
    }
  };
}

function syncDeviceNoteHighlight(devIdx) {
  const badge = document.getElementById('dev-badge-' + devIdx);
  const isActive = isDeviceNoteActive(devIdx);
  if (!isActive) {
    cancelRetriggerAnim(devIdx);
    lastNoteOffTime.set(devIdx, performance.now());
  }
  if (badge) {
    badge.classList.toggle('is-drum', isDrumDevice(devIdx));
    badge.classList.toggle('note-active', isActive);
  }
}

export function onDeviceNoteOn(devIdx, note) {
  if (devIdx == null || note == null) return;
  const now = performance.now();
  const wasActive = isDeviceNoteActive(devIdx);
  const prevOn = lastNoteOnTime.get(devIdx) ?? -Infinity;
  const prevOff = lastNoteOffTime.get(devIdx) ?? -Infinity;
  const isChordPeer = (now - prevOn) <= CHORD_COALESCE_MS;
  const shouldRearticulate = !isChordPeer && (wasActive || (now - prevOff) <= RETRIGGER_WINDOW_MS);
  lastNoteOnTime.set(devIdx, now);

  if (isDrumDevice(devIdx)) {
    const prevTimer = activeDrumTimers.get(devIdx);
    if (prevTimer != null) clearTimeout(prevTimer);
    const timerId = setTimeout(() => {
      if (activeDrumTimers.get(devIdx) === timerId) {
        activeDrumTimers.delete(devIdx);
        syncDeviceNoteHighlight(devIdx);
      }
    }, DRUM_HIGHLIGHT_MS);
    activeDrumTimers.set(devIdx, timerId);
    syncDeviceNoteHighlight(devIdx);
    if (shouldRearticulate) triggerBadgeRearticulate(devIdx, true);
    return;
  }
  let notes = activeDeviceNotes.get(devIdx);
  if (!notes) {
    notes = new Map();
    activeDeviceNotes.set(devIdx, notes);
  }
  let queue = notes.get(note);
  if (!queue) {
    queue = [];
    notes.set(note, queue);
  }
  const timerId = setTimeout(() => {
    const idx = queue.indexOf(timerId);
    if (idx !== -1) queue.splice(idx, 1);
    if (queue.length === 0) {
      notes.delete(note);
      if (notes.size === 0) {
        activeDeviceNotes.delete(devIdx);
      }
    }
    syncDeviceNoteHighlight(devIdx);
  }, NOTE_SAFETY_TIMEOUT_MS);
  queue.push(timerId);
  syncDeviceNoteHighlight(devIdx);
  if (shouldRearticulate) triggerBadgeRearticulate(devIdx, false);
}

export function onDeviceNoteOff(devIdx, note) {
  if (devIdx == null || note == null) return;
  const notes = activeDeviceNotes.get(devIdx);
  if (!notes) return;
  const queue = notes.get(note);
  if (!queue || queue.length === 0) return;
  const timerId = queue.shift();
  clearTimeout(timerId);
  if (queue.length === 0) {
    notes.delete(note);
    if (notes.size === 0) {
      activeDeviceNotes.delete(devIdx);
    }
  }
  syncDeviceNoteHighlight(devIdx);
}

export function onDeviceAllNotesOff(devIdx) {
  if (!devIdx) {
    clearDeviceNotes();
    return;
  }
  cancelRetriggerAnim(devIdx);
  const drumTimer = activeDrumTimers.get(devIdx);
  if (drumTimer != null) {
    clearTimeout(drumTimer);
    activeDrumTimers.delete(devIdx);
  }
  const notes = activeDeviceNotes.get(devIdx);
  if (notes) {
    for (const queue of notes.values()) {
      for (const timerId of queue) clearTimeout(timerId);
    }
    activeDeviceNotes.delete(devIdx);
  }
  syncDeviceNoteHighlight(devIdx);
}

export function clearDeviceNotes() {
  for (const anim of activeRetriggerAnims.values()) {
    anim.cancel();
  }
  activeRetriggerAnims.clear();
  lastNoteOnTime.clear();
  lastNoteOffTime.clear();
  for (const timerId of activeDrumTimers.values()) {
    clearTimeout(timerId);
  }
  activeDrumTimers.clear();
  for (const notes of activeDeviceNotes.values()) {
    for (const queue of notes.values()) {
      for (const timerId of queue) clearTimeout(timerId);
    }
  }
  activeDeviceNotes.clear();
  for (const el of document.querySelectorAll('.device-badge.note-active')) {
    el.classList.remove('note-active');
  }
}

export function render() {
  if (!state.chuckState) return;
  const activeSelect = document.activeElement && document.activeElement.classList && document.activeElement.classList.contains('cell-select');
  if (!state.isDragging && !activeSelect) renderDevicesTable();
  syncModeButtons();
}

function valToAngle(param, val) {
  if (param === 'pan') return (val / 64) * 135;
  return -135 + (Math.max(0, val) / 127) * 270;
}

function makeMuteSoloCell(dev) {
  const soloed = dev.soloed === 1;
  const muted = dev.muted === 1;
  return '<div style="display:flex;flex-direction:row;gap:4px;align-items:center;justify-content:center">'
    + '<button class="btn-ms btn-solo' + (soloed ? ' on' : '') + '"'
    + ' data-action="soloDevice" data-dev="' + dev.index + '" title="Solo">Solo</button>'
    + '<button class="btn-ms btn-mute' + (muted ? ' on' : '') + '"'
    + ' data-action="muteDevice" data-dev="' + dev.index + '" title="Mute">Mute</button>'
    + '</div>';
}

function makeVolCell(devIdx, vol) {
  const pct = Math.round((vol / 127) * 100);
  return '<div style="display:flex;align-items:center;gap:7px;width:100%">'
    + '<span class="cell-mono editable-num" id="val-' + devIdx + '-volume"'
    + ' style="width:28px;display:inline-block;flex-shrink:0;text-align:right"'
    + ' title="Click to edit volume"'
    + ' data-action="editParamInline" data-dev="' + devIdx + '" data-param="volume" data-min="0" data-max="127">' + vol + '</span>'
    + '<input type="range" class="vol-slider" id="slider-' + devIdx + '-volume" min="0" max="127" value="' + vol + '"'
    + ' data-dev="' + devIdx + '" style="flex:1; --pct:' + pct + '%">'
    + '</div>';
}

function makeKnobCell(devIdx, param, val, min, max) {
  const effVal = val === -1 ? 64 : val;
  const angle = valToAngle(param, effVal).toFixed(1);
  return '<div style="display:flex;align-items:center;gap:4px">'
    + '<span class="cell-mono editable-num" id="val-' + devIdx + '-' + param + '"'
    + ' style="width:28px;display:inline-block;flex-shrink:0;text-align:right"'
    + ' title="Click to edit ' + param + '"'
    + ' data-action="editParamInline" data-dev="' + devIdx + '" data-param="' + param + '" data-min="' + min + '" data-max="' + max + '">' + effVal + '</span>'
    + '<svg id="knob-' + devIdx + '-' + param + '" width="22" height="22" viewBox="-15 -15 30 30"'
    + ' class="knob-svg" style="cursor:ew-resize;flex-shrink:0"'
    + ' data-dev="' + devIdx + '" data-param="' + param + '" data-min="' + min + '" data-max="' + max + '" data-val="' + effVal + '">'
    + '<path d="M -7.78 7.78 A 11 11 0 1 1 7.78 7.78" class="knob-track"/>'
    + '<circle r="10" class="knob-bg"/>'
    + '<line x1="0" y1="-4" x2="0" y2="-8" class="knob-indicator" transform="rotate(' + angle + ')"/>'
    + '</svg>'
    + '</div>';
}

export function renderDevicesTable() {
  const s = state.chuckState;
  const wrap = document.getElementById('devicesWrap');
  if (!wrap || !s || !s.devices || s.devices.length === 0) return;

  const rows = s.devices.map(dev => {
    normalizeMoogDevicePatchName(dev);
    const icons = dev.playing === 1 ? '&#x2611;&#xFE0F;' : '';

    const cls = [
      dev.active === 1 ? 'row-active' : '',
      dev.playing === 1 ? 'row-playing' : '',
      dev.muted === 1 ? 'row-muted' : '',
    ].filter(Boolean).join(' ');

    const devColor = DEVICE_COLORS[(dev.index - 1) % DEVICE_COLORS.length];
    const badgeCls = [
      'device-badge',
      isDrumDevice(dev.index) ? 'is-drum' : '',
      isDeviceNoteActive(dev.index) ? 'note-active' : '',
    ].filter(Boolean).join(' ');

    const btnCell = '<td style="padding:4px 6px">'
      + '<span class="' + badgeCls + '" '
      + 'id="dev-badge-' + dev.index + '" '
      + 'title="' + esc(dev.uiName) + ': ' + esc(dev.patchName) + '" '
      + 'style="--dev-color:' + devColor + ';--dev-bg:' + devColor + '22;--dev-border:' + devColor + '66;--dev-glow:' + devColor + '88">'
      + '<span class="device-badge-bg" aria-hidden="true"></span>'
      + '<span class="device-badge-num">' + dev.index + '</span>'
      + '</span></td>';

    const hasPresets = Boolean(
      (state.presetCatalog && Array.isArray(state.presetCatalog[dev.uiName]) && state.presetCatalog[dev.uiName].length > 0) ||
      dev.uiName === 'V3' || dev.uiName === 'Hydrasynth' || dev.uiName === 'SH-4d' || dev.uiName === 'Moog'
    );
    const patchTitleHtml = hasPresets
      ? '<div class="patch-title patch-title-clickable" data-action="openPresetModal" data-dev="' + dev.index + '" title="Click to choose preset (' + esc(dev.patchName) + ')">' + esc(dev.patchName) + '</div>'
      : '<div class="patch-title" title="' + esc(dev.patchName) + '">' + esc(dev.patchName) + '</div>';

    const synthList = (state.presetCatalog && Array.isArray(state.presetCatalog.synths) && state.presetCatalog.synths.length > 0)
      ? state.presetCatalog.synths.slice()
      : REGISTERED_SYNTHS.slice();
    if (dev.uiName && !synthList.includes(dev.uiName)) {
      synthList.unshift(dev.uiName);
    }
    const synthSelectHtml = '<select class="cell-select cell-synth-select" data-dev="' + dev.index + '" title="Click to switch synth">'
      + synthList.map(syn => '<option value="' + esc(syn) + '"' + (syn === dev.uiName ? ' selected' : '') + '>' + esc(syn) + '</option>').join('')
      + '</select>';

    let chanOptionsHtml = '';
    for (let ch = 1; ch <= 16; ch++) {
      chanOptionsHtml += '<option value="' + ch + '"' + (ch === dev.channel ? ' selected' : '') + '>' + ch + '</option>';
    }
    const channelSelectHtml = '<select class="cell-select cell-channel-select" data-dev="' + dev.index + '" title="Click to change MIDI channel (1–16)">'
      + chanOptionsHtml
      + '</select>';

    return '<tr class="' + cls + '" data-dev="' + dev.index + '">'
      + btnCell
      + '<td style="text-align:center"><span class="status-icons">' + (icons || '&nbsp;') + '</span></td>'
      + '<td class="cell-synth">' + synthSelectHtml + '</td>'
      + '<td class="cell-mono">' + channelSelectHtml + '</td>'
      + '<td class="cell-patch">' + patchTitleHtml + '</td>'
      + '<td style="white-space:nowrap">' + makeVolCell(dev.index, dev.volume) + '</td>'
      + '<td style="white-space:nowrap">' + makeKnobCell(dev.index, 'cutoff', dev.filterCutoff, 0, 127) + '</td>'
      + '<td style="white-space:nowrap">' + makeKnobCell(dev.index, 'resonance', dev.filterResonance, 0, 127) + '</td>'
      + '<td style="white-space:nowrap">' + makeKnobCell(dev.index, 'pan', dev.pan, -64, 63) + '</td>'
      + '<td>' + makeMuteSoloCell(dev) + '</td>'
      + '</tr>';
  }).join('');

  wrap.innerHTML =
    '<table class="devices-table">'
    + '<colgroup>'
    + '<col style="width:50px">'
    + '<col style="width:65px">'
    + '<col style="width:155px">'
    + '<col style="width:70px">'
    + '<col style="width:210px">'
    + '<col style="width:175px">'
    + '<col style="width:70px">'
    + '<col style="width:70px">'
    + '<col style="width:70px">'
    + '<col style="width:115px">'
    + '</colgroup>'
    + '<thead><tr>'
    + '<th></th><th style="text-align:center">Playing</th><th>Synth</th><th>Channel</th>'
    + '<th>Patch</th><th>Vol</th><th>Cutoff</th><th>Res</th><th>Pan</th><th></th>'
    + '</tr></thead>'
    + '<tbody>' + rows + '</tbody>'
    + '</table>';
}

function findFirstUnusedChannelForSynth(devIdx, targetName, maxChannels) {
  const devices = (state.chuckState && Array.isArray(state.chuckState.devices)) ? state.chuckState.devices : [];
  const targetKey = targetName.toLowerCase();
  const usedChannels = new Set(
    devices
      .filter(d => d && d.index !== devIdx && d.uiName && d.uiName.toLowerCase() === targetKey)
      .map(d => d.channel)
  );
  for (let ch = 1; ch <= maxChannels; ch++) {
    if (!usedChannels.has(ch)) {
      return { channel: ch, internalChannel: ch - 1, error: null };
    }
  }
  return null;
}

function resolveChannelForSynthChange(devIdx, synthName) {
  const devices = (state.chuckState && Array.isArray(state.chuckState.devices)) ? state.chuckState.devices : [];
  const targetKey = synthName ? synthName.toLowerCase() : '';
  const metaMap = state.presetCatalog && state.presetCatalog.synthMeta;
  const meta = metaMap && metaMap[synthName];

  if (meta) {
    if (meta.fixedChannel != null) {
      const ch = meta.fixedChannel + 1;
      const existing = devices.find(d => d && d.index !== devIdx && d.uiName && d.uiName.toLowerCase() === targetKey);
      const info = existing
        ? `${synthName} is already in use on Device ${existing.index}. Assigned to channel ${ch}, sharing the synth and patch.`
        : null;
      return { channel: ch, internalChannel: meta.fixedChannel, info };
    }
    if (meta.maxChannels > 1) {
      const found = findFirstUnusedChannelForSynth(devIdx, synthName, meta.maxChannels);
      if (found) return { channel: found.channel, internalChannel: found.internalChannel, info: null };
      return {
        channel: 1,
        internalChannel: 0,
        info: `All MIDI channels for ${synthName} (channels 1–${meta.maxChannels}) are already in use. Assigned to channel 1, sharing the synth and patch.`,
      };
    }
    if (meta.maxChannels === 1) {
      const existing = devices.find(d => d && d.index !== devIdx && d.uiName && d.uiName.toLowerCase() === targetKey);
      const info = existing
        ? `${synthName} is already in use on Device ${existing.index}. Assigned to channel 1, sharing the synth and patch.`
        : null;
      return { channel: 1, internalChannel: 0, info };
    }
  } else {
    if (targetKey === 'moog' || targetKey === 'hydrasynth') {
      const existing = devices.find(d => d && d.index !== devIdx && d.uiName && d.uiName.toLowerCase() === targetKey);
      const info = existing
        ? `${synthName} is already in use on Device ${existing.index}. Assigned to channel 1, sharing the synth and patch.`
        : null;
      return { channel: 1, internalChannel: 0, info };
    }
    if (targetKey === 's-1') {
      const existing = devices.find(d => d && d.index !== devIdx && d.uiName && d.uiName.toLowerCase() === targetKey);
      const info = existing
        ? `${synthName} is already in use on Device ${existing.index}. Assigned to channel 3, sharing the synth and patch.`
        : null;
      return { channel: 3, internalChannel: 2, info };
    }
    if (targetKey === 'sh-4d' || targetKey === 'v3') {
      const max = targetKey === 'sh-4d' ? 4 : 16;
      const label = targetKey === 'sh-4d' ? 'SH-4d' : 'V3';
      const found = findFirstUnusedChannelForSynth(devIdx, label, max);
      if (found) return { channel: found.channel, internalChannel: found.internalChannel, info: null };
      return {
        channel: 1,
        internalChannel: 0,
        info: `All MIDI channels for ${label} (channels 1–${max}) are already in use. Assigned to channel 1, sharing the synth and patch.`,
      };
    }
  }
  const dev = devices.find(d => d && d.index === devIdx);
  const currentChannel = (dev && dev.channel >= 1 && dev.channel <= 16) ? dev.channel : 1;
  return { channel: currentChannel, internalChannel: currentChannel - 1, info: null };
}

function onSynthChange(selectEl, devIdx) {
  const synthName = selectEl.value;
  selectEl.blur();
  if (!state.chuckState || !state.chuckState.devices) return;
  const dev = state.chuckState.devices.find(d => d.index === devIdx);
  if (!dev || dev.uiName === synthName) return;

  const res = resolveChannelForSynthChange(devIdx, synthName);
  const sharedDev = state.chuckState.devices.find(
    d => d && d.index !== devIdx && d.uiName === synthName && d.channel === res.channel
  );

  dev.channel = res.channel;
  dev.uiName = synthName;
  if (sharedDev) {
    dev.patchName = sharedDev.patchName;
    dev.bank = sharedDev.bank;
    dev.program = sharedDev.program;
  } else if (synthName === 'V3') {
    dev.patchName = 'Grand Piano Vienna';
    dev.bank = 0;
    dev.program = 0;
  } else if (synthName === 'Hydrasynth') {
    dev.patchName = 'Sawpressive GD';
    dev.bank = 0;
    dev.program = 0;
  } else if (synthName === 'SH-4d') {
    dev.patchName = 'Channel ' + dev.channel;
    dev.bank = -1;
    dev.program = -1;
  } else if (synthName === 'S-1') {
    dev.patchName = 'Bank: 1 Program: 1';
    dev.bank = 0;
    dev.program = 0;
  } else if (synthName === 'Moog') {
    dev.patchName = 'Messenger: 1';
    dev.bank = 0;
    dev.program = 0;
  } else if (synthName === 'RD-6') {
    dev.patchName = 'RHYTHM DESIGNER RD-6';
  } else {
    const meta = state.presetCatalog && state.presetCatalog.synthMeta && state.presetCatalog.synthMeta[synthName];
    const list = state.presetCatalog && Array.isArray(state.presetCatalog[synthName])
      ? state.presetCatalog[synthName]
      : [];
    const defaultName = (meta && meta.defaultPreset) || (list[0] && list[0].name) || synthName;
    const match = list.find(p => p && p.name === defaultName) || list[0];
    dev.patchName = match ? match.name : defaultName;
    dev.bank = match && match.bank != null ? match.bank : 0;
    dev.program = match && match.program != null ? match.program : 0;
  }
  clearDrumCache();

  send('setSynth', { devIdx, synthName });
  send('setChannel', { devIdx, channel: res.channel });
  renderDevicesTable();
  syncPatchSetButton();
  if (res.info) {
    modalCallbacks.openWarningModal(res.info, { title: 'ℹ️ Shared Channel', color: 'var(--cyan)' });
  }
}

function onChannelChange(selectEl, devIdx) {
  const channel = parseInt(selectEl.value, 10);
  selectEl.blur();
  if (isNaN(channel) || channel < 1 || channel > 16) return;
  if (state.chuckState && state.chuckState.devices) {
    const dev = state.chuckState.devices.find(d => d.index === devIdx);
    if (dev) {
      if (dev.uiName === 'SH-4d' && /^Channel \d+$/.test(dev.patchName || '')) {
        dev.patchName = 'Channel ' + channel;
      }
      dev.channel = channel;
    }
  }
  send('setChannel', { devIdx, channel });
  renderDevicesTable();
  syncPatchSetButton();
}

const PARAM_STATE_KEYS = {
  volume: 'volume',
  cutoff: 'filterCutoff',
  resonance: 'filterResonance',
  pan: 'pan',
};

function setDeviceStateParam(devIdx, param, val) {
  const key = PARAM_STATE_KEYS[param];
  if (!key || !state.chuckState || !Array.isArray(state.chuckState.devices)) return;
  const dev = state.chuckState.devices.find(d => d.index === devIdx);
  if (dev) {
    dev[key] = val;
    syncPatchSetButton();
  }
}

function updateParamDisplay(devIdx, param, val) {
  const label = document.getElementById('val-' + devIdx + '-' + param);
  if (label && !label.querySelector('input')) label.textContent = val;
  const knob = document.getElementById('knob-' + devIdx + '-' + param);
  if (knob) {
    const ind = knob.querySelector('.knob-indicator');
    if (ind) ind.setAttribute('transform', 'rotate(' + valToAngle(param, val).toFixed(1) + ')');
  }
}

function updateVolDisplay(devIdx, val) {
  const label = document.getElementById('val-' + devIdx + '-volume');
  if (label && !label.querySelector('input')) label.textContent = val;
  const slider = document.getElementById('slider-' + devIdx + '-volume');
  if (slider) {
    slider.value = val;
    slider.style.setProperty('--pct', Math.round((val / 127) * 100) + '%');
  }
}

function onVolSlider(e, devIdx) {
  const val = parseInt(e.target.value, 10);
  state.isDragging = true;
  e.target.style.setProperty('--pct', Math.round((val / 127) * 100) + '%');
  const label = document.getElementById('val-' + devIdx + '-volume');
  if (label && !label.querySelector('input')) label.textContent = val;
  setDeviceStateParam(devIdx, 'volume', val);
  send('setParam', { devIdx, param: 'volume', value: val });
  clearTimeout(volSliderTimer);
  volSliderTimer = setTimeout(() => { state.isDragging = false; }, 500);
}

function updateTempoDisplay(bpm) {
  const disp = document.getElementById('bpmDisplay');
  if (disp && !disp.querySelector('input')) disp.textContent = bpm;
  const slider = document.getElementById('tempoSlider');
  if (slider) {
    slider.value = bpm;
    const pct = Math.round(((bpm - 40) / 200) * 100);
    slider.style.setProperty('--pct', pct + '%');
  }
}

export function syncTempoSlider(bpm) {
  if (state.isDragging || bpm == null) return;
  updateTempoDisplay(Math.round(bpm));
}

function startInlineEdit(spanEl, min, max, currentVal, onCommit) {
  if (activeInlineEdit) activeInlineEdit.cancel();
  state.isDragging = true;

  const origText = spanEl.textContent;
  spanEl.innerHTML = '';

  const input = document.createElement('input');
  input.type = 'text';
  input.inputMode = 'numeric';
  input.value = currentVal;
  input.className = 'inline-edit-input';
  if (spanEl.id === 'bpmDisplay') {
    input.style.width = '44px';
    input.style.fontSize = '14px';
  }

  spanEl.appendChild(input);
  input.focus();
  input.select();

  let finished = false;
  function commit() {
    if (finished) return;
    finished = true;
    activeInlineEdit = null;
    let num = parseInt(input.value.trim(), 10);
    if (isNaN(num)) num = currentVal;
    else num = Math.max(min, Math.min(max, num));
    spanEl.textContent = num;
    onCommit(num);
    setTimeout(() => { state.isDragging = false; }, 200);
  }
  function cancel() {
    if (finished) return;
    finished = true;
    activeInlineEdit = null;
    spanEl.textContent = origText;
    setTimeout(() => { state.isDragging = false; }, 200);
  }

  activeInlineEdit = { commit, cancel };
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      e.stopPropagation();
      commit();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      e.stopPropagation();
      cancel();
    }
  });
  input.addEventListener('blur', commit);
  input.addEventListener('click', (e) => e.stopPropagation());
}

export function editTempoInline(span) {
  const slider = document.getElementById('tempoSlider');
  const currentBpm = (slider && parseInt(slider.value, 10)) || 120;
  startInlineEdit(span, 40, 240, currentBpm, (newBpm) => {
    updateTempoDisplay(newBpm);
    if (state.chuckState) state.chuckState.bpm = newBpm;
    syncPatchSetButton();
    send('setTempo', newBpm);
  });
}

function editParamInline(span, devIdx, param, min, max) {
  const currentVal = parseInt(span.textContent, 10) || 0;
  startInlineEdit(span, min, max, currentVal, (newVal) => {
    if (param === 'volume') {
      updateVolDisplay(devIdx, newVal);
    } else {
      updateParamDisplay(devIdx, param, newVal);
    }
    setDeviceStateParam(devIdx, param, newVal);
    send('setParam', { devIdx, param, value: newVal });
  });
}

export function initDevicesEvents() {
  const tempoSlider = document.getElementById('tempoSlider');
  if (tempoSlider) {
    tempoSlider.addEventListener('input', (e) => {
      const bpm = parseInt(e.target.value, 10);
      updateTempoDisplay(bpm);
      if (state.chuckState) state.chuckState.bpm = bpm;
      syncPatchSetButton();
      send('setTempo', bpm);
    });
  }

  const wrap = document.getElementById('devicesWrap');
  if (wrap) {
    wrap.addEventListener('click', (e) => {
      const actionEl = e.target.closest('[data-action]');
      if (actionEl && wrap.contains(actionEl)) {
        const action = actionEl.dataset.action;
        const devIdx = parseInt(actionEl.dataset.dev, 10);
        if (action === 'soloDevice') {
          send('soloDevice', devIdx);
          return;
        }
        if (action === 'muteDevice') {
          if (state.chuckState && Array.isArray(state.chuckState.devices)) {
            const dev = state.chuckState.devices.find(d => d.index === devIdx);
            if (dev) {
              dev.muted = dev.muted ? 0 : 1;
              render();
            }
          }
          send('muteDevice', devIdx);
          return;
        }
        if (action === 'openPresetModal') {
          e.stopPropagation();
          modalCallbacks.openPresetModal(devIdx);
          return;
        }
        if (action === 'editParamInline') {
          const param = actionEl.dataset.param;
          const min = parseInt(actionEl.dataset.min, 10);
          const max = parseInt(actionEl.dataset.max, 10);
          editParamInline(actionEl, devIdx, param, min, max);
          return;
        }
      }
    });

    wrap.addEventListener('change', (e) => {
      const target = e.target;
      if (target.classList.contains('cell-synth-select')) {
        onSynthChange(target, parseInt(target.dataset.dev, 10));
      } else if (target.classList.contains('cell-channel-select')) {
        onChannelChange(target, parseInt(target.dataset.dev, 10));
      }
    });

    wrap.addEventListener('input', (e) => {
      if (e.target.classList.contains('vol-slider')) {
        onVolSlider(e, parseInt(e.target.dataset.dev, 10));
      }
    });

    wrap.addEventListener('mousedown', (e) => {
      const knob = e.target.closest('.knob-svg');
      if (!knob) return;
      e.preventDefault();
      state.isDragging = true;
      activeDrag = {
        startX: e.clientX,
        startVal: parseInt(knob.dataset.val, 10),
        devIdx: parseInt(knob.dataset.dev, 10),
        param: knob.dataset.param,
        min: parseInt(knob.dataset.min, 10),
        max: parseInt(knob.dataset.max, 10),
      };
    });
  }

  document.addEventListener('mousemove', e => {
    if (!activeDrag) return;
    const range = activeDrag.max - activeDrag.min;
    const delta = Math.round((e.clientX - activeDrag.startX) * (range / 200));
    const newVal = Math.max(activeDrag.min, Math.min(activeDrag.max, activeDrag.startVal + delta));
    updateParamDisplay(activeDrag.devIdx, activeDrag.param, newVal);
    setDeviceStateParam(activeDrag.devIdx, activeDrag.param, newVal);
    send('setParam', { devIdx: activeDrag.devIdx, param: activeDrag.param, value: newVal });
  });

  document.addEventListener('mouseup', () => {
    if (activeDrag) {
      activeDrag = null;
      setTimeout(() => { state.isDragging = false; }, 400);
    }
  });
}
