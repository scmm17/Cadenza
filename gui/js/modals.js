import {
  state,
  esc,
  send,
  doSave,
  syncSongInfo,
  syncPatchSetButton,
  computeYamlDiffs,
  resetYamlBaseline,
  beginPatchSetLoad,
} from './state.js';
import { render } from './devices-table.js';
import { updateGraph } from './fragment-graph.js';
import { DEVICE_COLORS } from './piano-roll.js';

let pendingDiffAction = null;

// ─── Shutdown Modal ───────────────────────────────────────────────────────────
export function openShutdown() {
  const m = document.getElementById('shutdownModal');
  if (m) m.classList.add('open');
}
export function closeShutdown() {
  const m = document.getElementById('shutdownModal');
  if (m) m.classList.remove('open');
}
export function confirmShutdown() {
  closeShutdown();
  send('shutdown');
}

// ─── Warning Modal ────────────────────────────────────────────────────────────
export function openWarningModal(message) {
  const msgEl = document.getElementById('warningModalMessage');
  if (msgEl) msgEl.textContent = message || '';
  const modal = document.getElementById('warningModal');
  if (modal) modal.classList.add('open');
  const okBtn = document.getElementById('btnWarningOk');
  if (okBtn) setTimeout(() => okBtn.focus(), 20);
}
export function closeWarningModal() {
  const modal = document.getElementById('warningModal');
  if (modal) modal.classList.remove('open');
  document.body.focus();
}

// ─── Open Song Modal ──────────────────────────────────────────────────────────
export function openSongModal() {
  if (state.ws && state.ws.readyState === 1) {
    state.ws.send(JSON.stringify({ type: 'getSongs' }));
  }
  const modal = document.getElementById('openModal');
  if (modal) modal.classList.add('open');
  const searchInput = document.getElementById('songSearchInput');
  if (searchInput) {
    searchInput.value = '';
    setTimeout(() => searchInput.focus(), 50);
  }
  state.selectedSongIdx = -1;
  renderSongList();
}
export function closeSongModal() {
  const modal = document.getElementById('openModal');
  if (modal) modal.classList.remove('open');
  const searchInput = document.getElementById('songSearchInput');
  if (searchInput) searchInput.blur();
  document.body.focus();
}
function executeOpenSong(songToLoad) {
  state.isSongReset = true;
  state.lastTransition = null;
  state.pendingBaselineReset = true;
  send('loadSong', songToLoad);
  updateGraph(false);
  syncSongInfo();
}

export function confirmOpenSong(explicitSong = null) {
  let songToLoad = explicitSong;
  if (!songToLoad) {
    const searchInput = document.getElementById('songSearchInput');
    const query = searchInput ? searchInput.value.toLowerCase() : '';
    const filteredSongs = state.songs.filter(song => song.toLowerCase().includes(query));
    if (state.selectedSongIdx >= 0 && state.selectedSongIdx < filteredSongs.length) {
      songToLoad = filteredSongs[state.selectedSongIdx];
    }
  }
  if (!songToLoad) return;
  closeSongModal();
  if (computeYamlDiffs().length > 0) {
    openDiffModal(() => executeOpenSong(songToLoad));
  } else {
    executeOpenSong(songToLoad);
  }
}
export function renderSongList() {
  const container = document.getElementById('songListContainer');
  if (!container) return;
  const searchInput = document.getElementById('songSearchInput');
  const query = searchInput ? searchInput.value.toLowerCase() : '';

  container.innerHTML = '';
  const filteredSongs = state.songs.filter(song => song.toLowerCase().includes(query));

  if (state.selectedSongIdx < 0 || state.selectedSongIdx >= filteredSongs.length) {
    state.selectedSongIdx = filteredSongs.length > 0 ? 0 : -1;
  }

  filteredSongs.forEach((song, idx) => {
    const div = document.createElement('div');
    div.className = 'song-item' + (idx === state.selectedSongIdx ? ' selected' : '');
    div.textContent = song;
    div.addEventListener('click', () => {
      state.selectedSongIdx = idx;
      Array.from(container.children).forEach(el => el.classList.remove('selected'));
      div.classList.add('selected');
    });
    div.addEventListener('dblclick', () => {
      state.selectedSongIdx = idx;
      confirmOpenSong(song);
    });
    container.appendChild(div);
  });
  if (state.selectedSongIdx >= 0) {
    const selectedEl = container.children[state.selectedSongIdx];
    if (selectedEl) selectedEl.scrollIntoView({ block: 'nearest' });
  }
}

// ─── Preset Category Modal ────────────────────────────────────────────────────
export function openPresetModal(devIdx) {
  if (!state.chuckState || !state.chuckState.devices) return;
  const dev = state.chuckState.devices.find(d => d.index === devIdx);
  if (!dev) return;

  const list = (state.presetCatalog && state.presetCatalog[dev.uiName] && state.presetCatalog[dev.uiName].length > 0)
    ? state.presetCatalog[dev.uiName]
    : [];
  if (list.length === 0) return;

  if (state.selectedDevIdx !== devIdx) {
    state.selectedDevIdx = devIdx;
    send('device', devIdx);
    render();
  }

  const normPatchName = dev.patchName ? String(dev.patchName).replace(/"/g, "'") : '';
  const hasValidBankProg = (dev.bank != null && dev.program != null && dev.bank >= 0 && dev.program >= 0);
  let currentPreset = null;
  if (hasValidBankProg) {
    currentPreset = list.find(p => (p.name === dev.patchName || p.name === normPatchName || p.code === dev.patchName) && p.bank === dev.bank && p.program === dev.program);
  }
  if (!currentPreset) {
    currentPreset = list.find(p => p.name === dev.patchName || p.name === normPatchName || (p.code && p.code === dev.patchName));
  }
  if (!currentPreset && hasValidBankProg) {
    currentPreset = list.find(p => p.bank === dev.bank && p.program === dev.program);
  }

  const category = currentPreset ? currentPreset.category : list[0].category;
  const categories = [...new Set(list.map(p => p.category))];
  const categoryPresets = list.filter(p => p.category === category);
  const currentIdxInCat = currentPreset ? Math.max(0, categoryPresets.indexOf(currentPreset)) : 0;

  state.presetModalState = {
    devIdx,
    uiName: dev.uiName,
    category,
    categories,
    presets: categoryPresets,
    initialPreset: currentPreset,
    initialPatchName: dev.patchName,
    initialBank: dev.bank,
    initialProgram: dev.program,
    currentPreset,
    selectedIdx: currentIdxInCat,
  };

  const titleEl = document.getElementById('presetModalTitle');
  if (titleEl) titleEl.textContent = '🎹 ' + dev.uiName + ' Presets';
  const catSelect = document.getElementById('presetCategorySelect');
  if (catSelect) {
    catSelect.innerHTML = categories.map(cat => {
      const label = dev.uiName === 'Hydrasynth' ? ('Bank ' + cat) : cat;
      return '<option value="' + esc(cat) + '"' + (cat === category ? ' selected' : '') + '>' + esc(label) + '</option>';
    }).join('');
    catSelect.value = category;
  }

  const searchInput = document.getElementById('presetSearchInput');
  if (searchInput) {
    searchInput.value = '';
    setTimeout(() => searchInput.focus(), 50);
  }

  const modal = document.getElementById('presetModal');
  if (modal) modal.classList.add('open');
  renderPresetList(true);
}

export function onPresetCategoryChange(newCategory) {
  if (!state.presetModalState) return;
  const list = state.presetCatalog[state.presetModalState.uiName] || [];
  state.presetModalState.category = newCategory;
  state.presetModalState.presets = list.filter(p => p.category === newCategory);

  const searchInput = document.getElementById('presetSearchInput');
  if (searchInput) searchInput.value = '';

  const curIdx = state.presetModalState.presets.indexOf(state.presetModalState.currentPreset);
  state.presetModalState.selectedIdx = curIdx >= 0 ? curIdx : 0;
  renderPresetList(false);
}

export function closePresetModal() {
  const modal = document.getElementById('presetModal');
  if (modal) modal.classList.remove('open');
  const searchInput = document.getElementById('presetSearchInput');
  if (searchInput) searchInput.blur();
  state.presetModalState = null;
  document.body.focus();
}

export function cancelPresetModal() {
  if (state.presetModalState) {
    if (state.presetModalState.initialPreset) {
      applyPresetSelection(state.presetModalState.initialPreset);
    } else if (state.presetModalState.currentPreset !== null && state.presetModalState.initialPatchName != null) {
      const { devIdx, initialPatchName, initialBank, initialProgram } = state.presetModalState;
      send('setPreset', { devIdx, presetName: initialPatchName });
      if (state.chuckState && state.chuckState.devices) {
        const dev = state.chuckState.devices.find(d => d.index === devIdx);
        if (dev) {
          dev.patchName = initialPatchName;
          dev.bank = initialBank;
          dev.program = initialProgram;
          render();
        }
      }
    }
  }
  closePresetModal();
}

function getFilteredCategoryPresets() {
  if (!state.presetModalState) return [];
  const searchInput = document.getElementById('presetSearchInput');
  const query = searchInput ? searchInput.value.trim().toLowerCase() : '';
  if (!query) return state.presetModalState.presets;
  return state.presetModalState.presets.filter(p =>
    p.name.toLowerCase().includes(query) || (p.code && p.code.toLowerCase().includes(query))
  );
}

export function renderPresetList(initialOpen = false) {
  const container = document.getElementById('presetListContainer');
  if (!container || !state.presetModalState) return;

  const filtered = getFilteredCategoryPresets();
  container.innerHTML = '';

  if (initialOpen && state.presetModalState.currentPreset) {
    const idx = filtered.indexOf(state.presetModalState.currentPreset);
    state.presetModalState.selectedIdx = idx >= 0 ? idx : 0;
  } else if (state.presetModalState.selectedIdx < 0 || state.presetModalState.selectedIdx >= filtered.length) {
    state.presetModalState.selectedIdx = filtered.length > 0 ? 0 : -1;
  }

  filtered.forEach((preset, idx) => {
    const div = document.createElement('div');
    const isCurrent = preset === state.presetModalState.currentPreset;
    div.className = 'song-item' + (idx === state.presetModalState.selectedIdx ? ' selected' : '');
    const activeDotHtml = isCurrent ? ' <span class="preset-active-dot" style="color:var(--cyan);font-size:11px;float:right">●</span>' : '';
    if (preset.code) {
      div.innerHTML = '<span class="preset-item-code">' + esc(preset.code) + '</span>' + esc(preset.name) + activeDotHtml;
    } else {
      div.innerHTML = esc(preset.name) + activeDotHtml;
    }
    div.addEventListener('click', () => {
      state.presetModalState.selectedIdx = idx;
      applyPresetSelection(preset);
      Array.from(container.children).forEach((el, i) => {
        el.classList.toggle('selected', i === idx);
        const dot = el.querySelector('.preset-active-dot');
        if (dot) dot.remove();
        if (filtered[i] === state.presetModalState.currentPreset) {
          const span = document.createElement('span');
          span.className = 'preset-active-dot';
          span.style.cssText = 'color:var(--cyan);font-size:11px;float:right';
          span.textContent = '●';
          el.appendChild(span);
        }
      });
    });
    div.addEventListener('dblclick', () => {
      state.presetModalState.selectedIdx = idx;
      confirmPresetModal(preset);
    });
    container.appendChild(div);
  });

  if (state.presetModalState.selectedIdx >= 0) {
    const selectedEl = container.children[state.presetModalState.selectedIdx];
    if (selectedEl) selectedEl.scrollIntoView({ block: 'nearest' });
  }
}

function applyPresetSelection(targetPreset) {
  if (!state.presetModalState || !targetPreset) return;
  const { devIdx, uiName, currentPreset } = state.presetModalState;
  if (currentPreset === targetPreset) return;

  const wirePresetName = (uiName === 'Moog')
    ? (targetPreset.category + ' Program: ' + (targetPreset.program + 1))
    : targetPreset.name;
  send('setPreset', { devIdx, presetName: wirePresetName });

  state.presetModalState.currentPreset = targetPreset;
  if (state.chuckState && state.chuckState.devices) {
    const dev = state.chuckState.devices.find(d => d.index === devIdx);
    if (dev) {
      dev.patchName = targetPreset.name;
      dev.bank = targetPreset.bank;
      dev.program = targetPreset.program;
      render();
    }
  }
}

export function movePresetSelection(delta) {
  if (!state.presetModalState) return;
  const filtered = getFilteredCategoryPresets();
  if (filtered.length === 0) return;
  const nextIdx = Math.max(0, Math.min(filtered.length - 1, state.presetModalState.selectedIdx + delta));
  state.presetModalState.selectedIdx = nextIdx;
  applyPresetSelection(filtered[nextIdx]);
  renderPresetList();
}

export function confirmPresetModal(explicitPreset = null) {
  if (!state.presetModalState) return;
  let targetPreset = explicitPreset;
  if (!targetPreset) {
    const filtered = getFilteredCategoryPresets();
    if (state.presetModalState.selectedIdx >= 0 && state.presetModalState.selectedIdx < filtered.length) {
      targetPreset = filtered[state.presetModalState.selectedIdx];
    }
  }
  if (targetPreset) {
    applyPresetSelection(targetPreset);
  }
  closePresetModal();
}

// ─── Patch Sets Modal ─────────────────────────────────────────────────────────
export function openPatchSetModal() {
  send('getPatchSets', { songName: state.chuckState ? state.chuckState.songName : '' });
  const modal = document.getElementById('patchSetModal');
  if (modal) modal.classList.add('open');
  renderPatchSetList(true);
}

export function closePatchSetModal() {
  commitRenamePatchSet();
  const modal = document.getElementById('patchSetModal');
  if (modal) modal.classList.remove('open');
  const input = document.getElementById('patchSetNameInput');
  if (input) input.blur();
  document.body.focus();
}

export function renderPatchSetList(syncInput = false) {
  const container = document.getElementById('patchSetListContainer');
  if (!container) return;

  const list = (state.patchSetsState.patchSets && state.patchSetsState.patchSets.length > 0)
    ? state.patchSetsState.patchSets.slice().sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
    : [state.activePatchSetName || 'Default'];
  const defaultName = state.patchSetsState.defaultPatchSet || list[0] || 'Default';
  const currentName = state.activePatchSetName || defaultName;

  const input = document.getElementById('patchSetNameInput');
  if (input && (syncInput || document.activeElement !== input)) {
    input.value = currentName;
  }

  container.innerHTML = '';
  const isDirty = computeYamlDiffs().length > 0;
  list.forEach((setName) => {
    const isSelected = setName === currentName;
    const isDefault = setName === defaultName;

    const row = document.createElement('div');
    row.className = 'song-item patchset-item'
      + (isSelected ? ' selected' : '')
      + (isSelected && isDirty ? ' is-dirty' : '');

    const nameSpan = document.createElement('span');
    nameSpan.className = 'patchset-item-name';
    nameSpan.textContent = setName;

    const actions = document.createElement('div');
    actions.className = 'patchset-item-actions';

    const checkBtn = document.createElement('button');
    checkBtn.type = 'button';
    checkBtn.className = 'patchset-action-btn patchset-check-btn' + (isDefault ? ' is-default' : '');
    checkBtn.title = isDefault ? 'Default patch set' : 'Set as default patch set';
    checkBtn.textContent = '✓';
    checkBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      setDefaultPatchSet(setName);
    });

    const delBtn = document.createElement('button');
    delBtn.type = 'button';
    delBtn.className = 'patchset-action-btn patchset-delete-btn';
    delBtn.title = 'Delete patch set';
    delBtn.textContent = '✕';
    delBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      promptDeletePatchSet(setName);
    });

    actions.appendChild(checkBtn);
    actions.appendChild(delBtn);
    row.appendChild(nameSpan);
    row.appendChild(actions);

    row.addEventListener('click', () => selectPatchSet(setName, false));
    row.addEventListener('dblclick', () => selectPatchSet(setName, true));

    container.appendChild(row);
  });
}

function executeSelectPatchSet(name, closeModalAfter = false) {
  state.activePatchSetName = name;
  if (state.chuckState) state.chuckState.patchSetName = name;
  const input = document.getElementById('patchSetNameInput');
  if (input) input.value = name;
  beginPatchSetLoad();
  syncPatchSetButton();
  renderPatchSetList(true);
  send('selectPatchSet', { name });
  if (closeModalAfter) {
    closePatchSetModal();
  }
}

export function selectPatchSet(name, closeModalAfter = false) {
  if (!name) return;
  const diffModal = document.getElementById('diffModal');
  if (diffModal && diffModal.classList.contains('open') && pendingDiffAction && pendingDiffAction.patchSetName === name) {
    if (closeModalAfter) pendingDiffAction.closePatchSetAfter = true;
    return;
  }
  if (computeYamlDiffs().length > 0) {
    openDiffModal({
      patchSetName: name,
      closePatchSetAfter: closeModalAfter,
      run: (_didSave, action) => executeSelectPatchSet(name, Boolean(action && action.closePatchSetAfter)),
    });
    return;
  }
  executeSelectPatchSet(name, closeModalAfter);
}

export function createNewPatchSet() {
  commitRenamePatchSet();
  state.pendingFocusNewPatchSet = true;
  resetYamlBaseline(state.chuckState);
  send('createPatchSet', {});
}

export function onPatchSetNameKeydown(e) {
  e.stopPropagation();
  if (e.key === 'Enter') {
    e.preventDefault();
    commitRenamePatchSet();
    e.target.blur();
  } else if (e.key === 'Escape') {
    e.preventDefault();
    e.target.value = state.activePatchSetName || 'Default';
    e.target.blur();
  }
}

export function commitRenamePatchSet() {
  const input = document.getElementById('patchSetNameInput');
  if (!input) return;
  const newName = input.value.trim().replace(/[\/\\:*?"<>|]/g, '');
  const oldName = state.activePatchSetName;
  if (!newName || !oldName || newName === oldName) {
    input.value = oldName || 'Default';
    return;
  }
  const existing = state.patchSetsState.patchSets || [];
  if (existing.some(s => s.toLowerCase() === newName.toLowerCase() && s !== oldName)) {
    input.value = oldName;
    return;
  }
  state.activePatchSetName = newName;
  if (state.chuckState) state.chuckState.patchSetName = newName;
  const idx = existing.indexOf(oldName);
  if (idx >= 0) existing[idx] = newName;
  if (state.patchSetsState.defaultPatchSet === oldName) {
    state.patchSetsState.defaultPatchSet = newName;
  }
  syncPatchSetButton();
  renderPatchSetList(true);
  send('renamePatchSet', { oldName, newName });
}

function setDefaultPatchSet(name) {
  if (!name) return;
  state.patchSetsState.defaultPatchSet = name;
  if (state.chuckState) state.chuckState.defaultPatchSetName = name;
  renderPatchSetList(false);
  send('setDefaultPatchSet', { name });
}

function promptDeletePatchSet(name) {
  if (!name) return;
  state.pendingDeletePatchSetName = name;
  const targetEl = document.getElementById('deletePatchSetTargetName');
  if (targetEl) targetEl.textContent = '"' + name + '"';
  const modal = document.getElementById('deletePatchSetModal');
  if (modal) modal.classList.add('open');
}

export function closeDeletePatchSetModal() {
  state.pendingDeletePatchSetName = null;
  const modal = document.getElementById('deletePatchSetModal');
  if (modal) modal.classList.remove('open');
}

export function confirmDeletePatchSet() {
  const name = state.pendingDeletePatchSetName;
  closeDeletePatchSetModal();
  if (!name) return;
  if (name === state.activePatchSetName) {
    beginPatchSetLoad();
  }
  send('deletePatchSet', { name });
}

// ─── Diff Modal ───────────────────────────────────────────────────────────────
export function openDiffModal(pending = null) {
  if (computeYamlDiffs().length === 0) return;
  pendingDiffAction = typeof pending === 'function' ? { run: pending } : pending;
  renderDiffModal();
  const modal = document.getElementById('diffModal');
  if (modal) modal.classList.add('open');
  const focusBtn = document.getElementById(pendingDiffAction ? 'btnDiffSave' : 'btnDiffClose');
  if (focusBtn) setTimeout(() => focusBtn.focus(), 20);
}

export function closeDiffModal() {
  const modal = document.getElementById('diffModal');
  if (modal) modal.classList.remove('open');
  const action = pendingDiffAction;
  pendingDiffAction = null;
  if (action && typeof action.run === 'function') {
    action.run(false, action);
  }
  document.body.focus();
}

export function saveDiffModal() {
  doSave();
  const modal = document.getElementById('diffModal');
  if (modal) modal.classList.remove('open');
  const action = pendingDiffAction;
  pendingDiffAction = null;
  if (action && typeof action.run === 'function') {
    setTimeout(() => action.run(true, action), 60);
  }
  document.body.focus();
}

export function renderDiffModal() {
  const tbody = document.getElementById('diffTableBody');
  if (!tbody) return;
  const diffs = computeYamlDiffs();
  if (diffs.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-dim);padding:18px;">No unsaved changes</td></tr>';
    return;
  }
  tbody.innerHTML = diffs.map(d => {
    let deviceHtml = '<span class="diff-dev-none">—</span>';
    if (d.devIndex != null) {
      const color = DEVICE_COLORS[(d.devIndex - 1) % DEVICE_COLORS.length];
      deviceHtml = '<span class="diff-dev-cell">'
        + '<span class="diff-dev-badge" style="background:' + color + '22;border-color:' + color + '66;color:' + color + '">'
        + esc(d.devIndex)
        + '</span>'
        + '<span>' + esc(d.synthName || '') + '</span>'
        + '</span>';
    }
    const channelHtml = d.channel != null
      ? '<td class="cell-mono">' + esc(d.channel) + '</td>'
      : '<td><span class="diff-dev-none">—</span></td>';
    return '<tr>'
      + '<td>' + deviceHtml + '</td>'
      + channelHtml
      + '<td>' + esc(d.field) + '</td>'
      + '<td class="diff-val-old">' + esc(d.oldValue) + '</td>'
      + '<td class="diff-val-new">' + esc(d.newValue) + '</td>'
      + '</tr>';
  }).join('');
}

export function initModals() {
  const songSearch = document.getElementById('songSearchInput');
  if (songSearch) songSearch.addEventListener('input', renderSongList);

  const presetModal = document.getElementById('presetModal');
  if (presetModal) {
    presetModal.addEventListener('click', (e) => {
      if (e.target === presetModal) cancelPresetModal();
    });
  }
  const catSelect = document.getElementById('presetCategorySelect');
  if (catSelect) {
    catSelect.addEventListener('change', (e) => onPresetCategoryChange(e.target.value));
  }
  const presetSearch = document.getElementById('presetSearchInput');
  if (presetSearch) {
    presetSearch.addEventListener('input', () => renderPresetList());
  }

  const patchSetModal = document.getElementById('patchSetModal');
  if (patchSetModal) {
    patchSetModal.addEventListener('mousedown', (e) => {
      if (e.target === patchSetModal) closePatchSetModal();
    });
  }
  const patchSetInput = document.getElementById('patchSetNameInput');
  if (patchSetInput) {
    patchSetInput.addEventListener('keydown', onPatchSetNameKeydown);
    patchSetInput.addEventListener('blur', commitRenamePatchSet);
  }

  const deleteModal = document.getElementById('deletePatchSetModal');
  if (deleteModal) {
    deleteModal.addEventListener('click', (e) => {
      if (e.target === deleteModal) closeDeletePatchSetModal();
    });
  }

  const warningModal = document.getElementById('warningModal');
  if (warningModal) {
    warningModal.addEventListener('click', (e) => {
      if (e.target === warningModal) closeWarningModal();
    });
  }

  const diffModal = document.getElementById('diffModal');
  if (diffModal) {
    diffModal.addEventListener('click', (e) => {
      if (e.target === diffModal) closeDiffModal();
    });
  }
}
