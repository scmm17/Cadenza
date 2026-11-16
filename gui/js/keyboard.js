import {
  state,
  send,
  togglePlayPause,
  doRestart,
  doSave,
} from './state.js';
import {
  closeWarningModal,
  confirmDeletePatchSet,
  closeDeletePatchSetModal,
  closePatchSetModal,
  confirmShutdown,
  closeShutdown,
  confirmPresetModal,
  cancelPresetModal,
  movePresetSelection,
  confirmOpenSong,
  closeSongModal,
  renderSongList,
  openShutdown,
  openSongModal,
} from './modals.js';
import { toggleGraphWindow } from './fragment-graph.js';

export function initKeyboard() {
  document.addEventListener('keydown', e => {
    const isInput = e.target.matches('input,textarea,select');
    const k = e.key;

    const isWarningModalOpen = document.getElementById('warningModal').classList.contains('open');
    const isShutdownOpen = document.getElementById('shutdownModal').classList.contains('open');
    const isOpenModalOpen = document.getElementById('openModal').classList.contains('open');
    const isPresetModalOpen = document.getElementById('presetModal').classList.contains('open');
    const isPatchSetModalOpen = document.getElementById('patchSetModal').classList.contains('open');
    const isDeletePatchSetModalOpen = document.getElementById('deletePatchSetModal').classList.contains('open');

    if (isWarningModalOpen) {
      if (k === 'Enter' || k === 'Escape' || k === ' ') {
        e.preventDefault();
        closeWarningModal();
      }
      return;
    }

    if (isDeletePatchSetModalOpen) {
      if (k === 'Enter') { e.preventDefault(); confirmDeletePatchSet(); return; }
      if (k === 'Escape') { e.preventDefault(); closeDeletePatchSetModal(); return; }
      return;
    }

    if (isPatchSetModalOpen) {
      if (isInput) return;
      if (k === 'Escape') { e.preventDefault(); closePatchSetModal(); return; }
      return;
    }

    if (isShutdownOpen) {
      if (k === 'Enter') { e.preventDefault(); confirmShutdown(); return; }
      if (k === 'Escape') { e.preventDefault(); closeShutdown(); return; }
      if (isInput) return;
      return;
    }

    if (isPresetModalOpen) {
      if (k === 'Enter') { e.preventDefault(); confirmPresetModal(); return; }
      if (k === 'Escape') { e.preventDefault(); cancelPresetModal(); return; }
      if (k === 'ArrowDown') {
        e.preventDefault();
        movePresetSelection(1);
        return;
      }
      if (k === 'ArrowUp') {
        e.preventDefault();
        movePresetSelection(-1);
        return;
      }
      if (isInput) return;
      return;
    }

    if (isOpenModalOpen) {
      if (k === 'Enter') { e.preventDefault(); confirmOpenSong(); return; }
      if (k === 'Escape') { e.preventDefault(); closeSongModal(); return; }
      if (k === 'ArrowDown') {
        e.preventDefault();
        const filteredLength = document.getElementById('songListContainer').children.length;
        state.selectedSongIdx = Math.min(filteredLength - 1, state.selectedSongIdx + 1);
        renderSongList();
        return;
      }
      if (k === 'ArrowUp') {
        e.preventDefault();
        state.selectedSongIdx = Math.max(0, state.selectedSongIdx - 1);
        renderSongList();
        return;
      }
      if (isInput) return;
      return;
    }

    if (isInput) return;
    if (e.ctrlKey || e.altKey || e.metaKey) return;

    if (k === ' ' || k === 'p') {
      e.preventDefault();
      if (document.activeElement && document.activeElement.tagName === 'BUTTON') {
        document.activeElement.blur();
      }
      togglePlayPause();
      return;
    }

    if (k >= '1' && k <= '8') {
      send('device', parseInt(k, 10));
      return;
    }

    switch (k) {
      case 'r': doRestart(); break;
      case 'g': send('golden'); break;
      case 'a': send('allMode'); break;
      case 'w': doSave(); break;
      case 'q': openShutdown(); break;
      case 'o': openSongModal(); break;
      case 'e': send('editSong'); break;
      case 'f': toggleGraphWindow(); break;
    }
  });
}
