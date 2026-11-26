import {
  registerUiCallbacks,
  connect,
  send,
  togglePlayPause,
  doRestart,
  doSave,
} from './state.js';
import {
  clearNotes,
  clearDrumCache,
  onNoteOn,
  onNoteOff,
  onAllNotesOff,
  initScrollCanvas,
} from './piano-roll.js';
import {
  setGraphVisible,
  toggleGraphWindow,
  updateGraph,
  flashTransition,
  initFragmentGraph,
} from './fragment-graph.js';
import {
  render,
  syncTempoSlider,
  editTempoInline,
  registerDeviceModalCallbacks,
  initDevicesEvents,
  onDeviceNoteOn,
  onDeviceNoteOff,
  onDeviceAllNotesOff,
  clearDeviceNotes,
} from './devices-table.js';
import {
  openShutdown,
  closeShutdown,
  confirmShutdown,
  openWarningModal,
  closeWarningModal,
  openSongModal,
  closeSongModal,
  confirmOpenSong,
  renderSongList,
  openPresetModal,
  cancelPresetModal,
  confirmPresetModal,
  openPatchSetModal,
  closePatchSetModal,
  renderPatchSetList,
  createNewPatchSet,
  closeDeletePatchSetModal,
  confirmDeletePatchSet,
  openDiffModal,
  closeDiffModal,
  saveDiffModal,
  renderDiffModal,
  initModals,
} from './modals.js';
import { initKeyboard } from './keyboard.js';
import {
  initSynthUi,
  onSynthUiStatus,
  toggleSynthUiAudio,
  popoutSynthUi,
  closeSynthUi,
} from './synth-ui.js';

registerUiCallbacks({
  render,
  updateGraph,
  clearNotes: () => {
    clearNotes();
    clearDeviceNotes();
  },
  clearDrumCache,
  onNoteOn: (dev, note, vel) => {
    onNoteOn(dev, note, vel);
    onDeviceNoteOn(dev, note);
  },
  onNoteOff: (dev, note) => {
    onNoteOff(dev, note);
    onDeviceNoteOff(dev, note);
  },
  onAllNotesOff: (dev) => {
    onAllNotesOff(dev);
    onDeviceAllNotesOff(dev);
  },
  flashTransition,
  renderSongList,
  renderPatchSetList,
  renderDiffModal,
  syncTempoSlider,
  onSynthUiStatus,
});

registerDeviceModalCallbacks({
  openPresetModal,
  openWarningModal,
});

const ACTIONS = {
  openSongModal: () => openSongModal(),
  closeSongModal: () => closeSongModal(),
  confirmOpenSong: () => confirmOpenSong(),
  send: (el) => send(el.dataset.cmd),
  toggleGraphWindow: () => toggleGraphWindow(),
  doSave: () => doSave(),
  doRestart: () => doRestart(),
  togglePlayPause: () => togglePlayPause(),
  editTempoInline: (el) => editTempoInline(el),
  openPatchSetModal: () => openPatchSetModal(),
  closePatchSetModal: () => closePatchSetModal(),
  createNewPatchSet: () => createNewPatchSet(),
  openShutdown: () => openShutdown(),
  closeShutdown: () => closeShutdown(),
  confirmShutdown: () => confirmShutdown(),
  cancelPresetModal: () => cancelPresetModal(),
  confirmPresetModal: () => confirmPresetModal(),
  closeDeletePatchSetModal: () => closeDeletePatchSetModal(),
  confirmDeletePatchSet: () => confirmDeletePatchSet(),
  closeWarningModal: () => closeWarningModal(),
  openDiffModal: () => openDiffModal(),
  closeDiffModal: () => closeDiffModal(),
  saveDiffModal: () => saveDiffModal(),
  toggleSynthUiAudio: () => toggleSynthUiAudio(),
  popoutSynthUi: () => popoutSynthUi(),
  closeSynthUi: () => closeSynthUi(),
};

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-action]');
  if (!el || el.closest('#devicesWrap')) return;
  const handler = ACTIONS[el.dataset.action];
  if (handler) handler(el, e);
});

initDevicesEvents();
initModals();
initKeyboard();
initScrollCanvas();
initFragmentGraph();
initSynthUi();
connect();
setGraphVisible(true);
