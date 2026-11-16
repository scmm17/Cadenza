import {
  state,
  REGISTERED_SYNTHS,
  esc,
  normalizeMoogDevicePatchName,
  send,
  syncModeButtons,
} from './state.js';
import { DEVICE_COLORS, clearDrumCache } from './piano-roll.js';

let activeDrag = null;
let activeInlineEdit = null;
let volSliderTimer = null;

const modalCallbacks = {
  openPresetModal: () => {},
  openWarningModal: () => {},
};

export function registerDeviceModalCallbacks(cbs) {
  Object.assign(modalCallbacks, cbs);
}

export function toggleDeviceSelect(idx) {
  if (state.selectedDevIdx === idx) {
    state.selectedDevIdx = null;
  } else {
    state.selectedDevIdx = idx;
    send('device', idx);
  }
  render();
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

    const isSelected = state.selectedDevIdx === dev.index;
    const selectedCls = isSelected ? ' active' : '';
    const devColor = DEVICE_COLORS[(dev.index - 1) % DEVICE_COLORS.length];
    const btnStyle = isSelected
      ? 'width:26px;height:26px;font-size:12px;background:' + devColor + ';border-color:' + devColor + ';color:#fff;box-shadow:0 0 10px ' + devColor + '88;'
      : 'width:26px;height:26px;font-size:12px;background:' + devColor + '22;border-color:' + devColor + '66;color:' + devColor + ';';

    const btnCell = '<td style="padding:4px 6px">'
      + '<button class="btn-device' + selectedCls + '" '
      + 'data-action="toggleDeviceSelect" data-dev="' + dev.index + '" '
      + 'title="Select ' + esc(dev.uiName) + ': ' + esc(dev.patchName) + '" '
      + 'style="' + btnStyle + '">'
      + dev.index
      + '</button></td>';

    const hasPresets = (dev.uiName === 'V3' || dev.uiName === 'Hydrasynth' || dev.uiName === 'SH-4d' || dev.uiName === 'Moog');
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

    return '<tr class="' + cls + '" data-dev="' + dev.index + '" style="cursor: pointer;">'
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
    + '<col style="width:105px">'
    + '<col style="width:70px">'
    + '<col style="width:250px">'
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
  const metaMap = state.presetCatalog && state.presetCatalog.synthMeta;
  const meta = metaMap && metaMap[synthName];
  if (meta) {
    if (meta.fixedChannel != null) {
      return { channel: meta.fixedChannel + 1, internalChannel: meta.fixedChannel, error: null };
    }
    if (meta.maxChannels > 1) {
      const found = findFirstUnusedChannelForSynth(devIdx, synthName, meta.maxChannels);
      if (found) return found;
      return {
        channel: null,
        internalChannel: null,
        error: `All MIDI channels for ${synthName} (channels 1–${meta.maxChannels}) are already in use.`,
      };
    }
  } else {
    const key = synthName ? synthName.toLowerCase() : '';
    if (key === 'moog' || key === 'hydrasynth') {
      return { channel: 1, internalChannel: 0, error: null };
    }
    if (key === 's-1') {
      return { channel: 3, internalChannel: 2, error: null };
    }
    if (key === 'sh-4d' || key === 'v3') {
      const max = key === 'sh-4d' ? 4 : 16;
      const label = key === 'sh-4d' ? 'SH-4d' : 'V3';
      const found = findFirstUnusedChannelForSynth(devIdx, label, max);
      if (found) return found;
      return {
        channel: null,
        internalChannel: null,
        error: `All MIDI channels for ${label} (channels 1–${max}) are already in use.`,
      };
    }
  }
  const devices = (state.chuckState && Array.isArray(state.chuckState.devices)) ? state.chuckState.devices : [];
  const dev = devices.find(d => d && d.index === devIdx);
  const currentChannel = (dev && dev.channel >= 1 && dev.channel <= 16) ? dev.channel : 1;
  return { channel: currentChannel, internalChannel: currentChannel - 1, error: null };
}

function onSynthChange(selectEl, devIdx) {
  const synthName = selectEl.value;
  selectEl.blur();
  if (!state.chuckState || !state.chuckState.devices) return;
  const dev = state.chuckState.devices.find(d => d.index === devIdx);
  if (!dev || dev.uiName === synthName) return;

  const res = resolveChannelForSynthChange(devIdx, synthName);
  if (res.error) {
    selectEl.value = dev.uiName;
    renderDevicesTable();
    modalCallbacks.openWarningModal(res.error);
    return;
  }

  dev.channel = res.channel;
  dev.uiName = synthName;
  if (synthName === 'V3') {
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
  }
  clearDrumCache();

  send('setSynth', { devIdx, synthName });
  send('setChannel', { devIdx, channel: res.channel });
  renderDevicesTable();
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
    send('setTempo', newBpm);
  });
}

function editParamInline(span, devIdx, param, min, max) {
  const currentVal = parseInt(span.textContent, 10) || 0;
  startInlineEdit(span, min, max, currentVal, (newVal) => {
    if (param === 'volume') {
      updateVolDisplay(devIdx, newVal);
      send('setParam', { devIdx, param: 'volume', value: newVal });
    } else {
      updateParamDisplay(devIdx, param, newVal);
      send('setParam', { devIdx, param, value: newVal });
    }
  });
}

export function initDevicesEvents() {
  const tempoSlider = document.getElementById('tempoSlider');
  if (tempoSlider) {
    tempoSlider.addEventListener('input', (e) => {
      const bpm = parseInt(e.target.value, 10);
      updateTempoDisplay(bpm);
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
          send('muteDevice', devIdx);
          return;
        }
        if (action === 'toggleDeviceSelect') {
          toggleDeviceSelect(devIdx);
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

      if (e.target.closest('input, button, select, .cell-select, .editable-num, .patch-title-clickable')) return;
      const row = e.target.closest('tr[data-dev]');
      if (row) {
        toggleDeviceSelect(parseInt(row.dataset.dev, 10));
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
    send('setParam', { devIdx: activeDrag.devIdx, param: activeDrag.param, value: newVal });
  });

  document.addEventListener('mouseup', () => {
    if (activeDrag) {
      activeDrag = null;
      setTimeout(() => { state.isDragging = false; }, 400);
    }
  });
}
