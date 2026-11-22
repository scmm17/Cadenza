'use strict';

const fs = require('fs');
const path = require('path');

const MUSIC_DIR = path.join(__dirname, '..', '..', 'music');
const CATALOG_PATH = path.join(__dirname, '..', '..', 'presets', 'catalog.json');

function loadSynthMetaMap() {
  try {
    const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
    return catalog.synths || {};
  } catch (_) {
    return {
      V3: { deviceName: 'U2MIDI Pro' },
      Hydrasynth: { deviceName: 'HYDRASYNTH EXPLORER' },
      'SH-4d': { deviceName: 'SH-4d' },
      'S-1': { deviceName: 'S-1 MIDI IN' },
      Moog: { deviceName: 'Moog Messenger' },
      'RD-6': { deviceName: 'RHYTHM DESIGNER RD-6' },
    };
  }
}

function normalizeSongName(songName) {
  if (!songName) return '';
  return String(songName).replace(/\.ck$/i, '').trim();
}

function getActiveSongName(explicitSong, lastState, lastLoadedSong) {
  return normalizeSongName(
    explicitSong ||
    (lastState && lastState.songName) ||
    lastLoadedSong ||
    ''
  );
}

function ensurePatchSetsDir(rawSongName) {
  const songName = normalizeSongName(rawSongName);
  if (!songName) {
    return { songName: '', patchSets: [], defaultPatchSet: 'Default' };
  }
  const patchSetsDir = path.join(MUSIC_DIR, `${songName}.patch-sets`);
  const legacyYaml = path.join(MUSIC_DIR, `${songName}.yaml`);
  const defaultMetaPath = path.join(patchSetsDir, '.default');

  try {
    if (!fs.existsSync(patchSetsDir)) {
      fs.mkdirSync(patchSetsDir, { recursive: true });
    }
    if (fs.existsSync(legacyYaml)) {
      const destYaml = path.join(patchSetsDir, 'Default.yaml');
      if (!fs.existsSync(destYaml)) {
        fs.renameSync(legacyYaml, destYaml);
        console.log(`Migrated legacy YAML ${legacyYaml} -> ${destYaml}`);
      } else {
        fs.unlinkSync(legacyYaml);
      }
    }

    const sets = fs.readdirSync(patchSetsDir)
      .filter(f => f.endsWith('.yaml'))
      .map(f => f.slice(0, -5))
      .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    let defaultPatchSet = '';
    if (fs.existsSync(defaultMetaPath)) {
      defaultPatchSet = fs.readFileSync(defaultMetaPath, 'utf8').trim();
    }
    if (sets.length > 0) {
      if (!defaultPatchSet || !sets.includes(defaultPatchSet)) {
        defaultPatchSet = sets[0];
        fs.writeFileSync(defaultMetaPath, defaultPatchSet + '\n', 'utf8');
      }
    } else {
      defaultPatchSet = defaultPatchSet || 'Default';
      if (!fs.existsSync(defaultMetaPath)) {
        fs.writeFileSync(defaultMetaPath, defaultPatchSet + '\n', 'utf8');
      }
    }

    return { songName, patchSets: sets, defaultPatchSet };
  } catch (err) {
    console.error(`Failed to manage patch sets for ${songName}:`, err.message);
    return { songName, patchSets: [], defaultPatchSet: 'Default' };
  }
}

// Serialize the live state broadcast by ChucK into patch-set YAML. Used to seed
// a newly created patch set so it reflects in-memory settings immediately.
function buildYamlFromState(state) {
  const q = (s) => '"' + String(s == null ? '' : s).replace(/"/g, "'") + '"';
  const lines = ['song:', '  devices:'];
  const used = new Set();
  const synthMeta = loadSynthMetaMap();
  const devices = (state && Array.isArray(state.devices)) ? state.devices : [];
  for (const d of devices) {
    const meta = synthMeta[d.uiName];
    const midiChannel = Math.max(0, Math.min(15, (parseInt(d.channel, 10) || 1) - 1));
    let key = `${d.uiName}-${midiChannel}`;
    if (used.has(key)) key += `-dev${d.index}`;
    used.add(key);
    lines.push(`    ${key}:`);
    lines.push(`      deviceName: ${q((meta && meta.deviceName) || d.uiName)}`);
    lines.push(`      midiChannel: ${midiChannel}`);
    lines.push(`      patchName: ${q(d.patchName)}`);
    lines.push(`      uiName: ${q(d.uiName)}`);
    lines.push(`      muted: ${d.muted ? 1 : 0}`);
    lines.push(`      volume: ${d.volume}`);
    lines.push(`      filterCutoff: ${d.filterCutoff}`);
    lines.push(`      filterResonance: ${d.filterResonance}`);
    lines.push(`      pan: ${(parseInt(d.pan, 10) || 0) + 64}`);
    if (
      d.uiName === 'V3' ||
      d.uiName === 'S-1' ||
      d.uiName === 'Moog' ||
      Boolean(meta && meta.appName)
    ) {
      lines.push(`      program: ${d.program}`);
      lines.push(`      bank: ${d.bank}`);
      if (d.uiName === 'V3') lines.push('      programChange: 1');
    } else if (d.uiName === 'SH-4d' && d.bank >= 0 && d.program >= 0) {
      lines.push('      presetType: "tone"');
      lines.push(`      toneProgram: ${d.program}`);
      lines.push(`      toneBank: ${d.bank}`);
    }
  }
  const bpm = state && state.bpm ? Number(state.bpm) : 120;
  lines.push(`  bpm: ${bpm.toFixed(6)}`);
  return lines.join('\n') + '\n';
}

function createPatchSet(songName, lastState, chuckClient, broadcast) {
  const info = ensurePatchSetsDir(songName);
  const patchSetsDir = path.join(MUSIC_DIR, `${songName}.patch-sets`);
  const existingLower = new Set(info.patchSets.map(s => s.toLowerCase()));
  let idx = 1;
  let newName = `Patch Set ${idx}`;
  while (existingLower.has(newName.toLowerCase())) {
    idx++;
    newName = `Patch Set ${idx}`;
  }
  const destPath = path.join(patchSetsDir, `${newName}.yaml`);
  try {
    fs.writeFileSync(destPath, buildYamlFromState(lastState), 'utf8');
  } catch (err) {
    console.error('Failed to create patch set file:', err.message);
  }
  console.log(`→ ChucK: /cadenza/createPatchSet "${newName}"`);
  chuckClient.send('/cadenza/createPatchSet', newName, String(info.defaultPatchSet || ''));
  if (lastState) {
    lastState.patchSetName = newName;
    broadcast({ type: 'state', data: lastState });
  }
  broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
}

function renamePatchSet(songName, oldName, rawNewName, lastState, chuckClient, broadcast) {
  const newName = String(rawNewName).trim().replace(/[\/\\:*?"<>|]/g, '');
  const info = ensurePatchSetsDir(songName);
  if (!newName || newName === oldName) {
    broadcast({ type: 'patchSets', data: info });
    return;
  }
  const patchSetsDir = path.join(MUSIC_DIR, `${songName}.patch-sets`);
  const oldPath = path.join(patchSetsDir, `${oldName}.yaml`);
  const newPath = path.join(patchSetsDir, `${newName}.yaml`);
  if (fs.existsSync(newPath) && oldName.toLowerCase() !== newName.toLowerCase()) {
    console.warn(`Cannot rename patch set to existing name "${newName}"`);
    broadcast({ type: 'patchSets', data: info });
    return;
  }
  try {
    if (fs.existsSync(oldPath)) {
      fs.renameSync(oldPath, newPath);
    }
    let defName = info.defaultPatchSet;
    if (defName === oldName) {
      defName = newName;
      fs.writeFileSync(path.join(patchSetsDir, '.default'), defName + '\n', 'utf8');
    }
    const curName = (lastState && lastState.patchSetName === oldName)
      ? newName
      : ((lastState && lastState.patchSetName) || newName);
    chuckClient.send('/cadenza/setPatchSetName', String(curName), String(defName));
    if (lastState) {
      lastState.patchSetName = curName;
      lastState.defaultPatchSetName = defName;
      broadcast({ type: 'state', data: lastState });
    }
  } catch (err) {
    console.error('Failed to rename patch set:', err.message);
  }
  broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
}

function setDefaultPatchSet(songName, name, lastState, chuckClient, broadcast) {
  const patchSetsDir = path.join(MUSIC_DIR, `${songName}.patch-sets`);
  try {
    fs.mkdirSync(patchSetsDir, { recursive: true });
    fs.writeFileSync(path.join(patchSetsDir, '.default'), String(name) + '\n', 'utf8');
    const curName = (lastState && lastState.patchSetName) || String(name);
    chuckClient.send('/cadenza/setPatchSetName', String(curName), String(name));
    if (lastState) {
      lastState.defaultPatchSetName = String(name);
      broadcast({ type: 'state', data: lastState });
    }
  } catch (err) {
    console.error('Failed to set default patch set:', err.message);
  }
  broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
}

function deletePatchSet(songName, name, lastState, chuckClient, broadcast) {
  const info = ensurePatchSetsDir(songName);
  const patchSetsDir = path.join(MUSIC_DIR, `${songName}.patch-sets`);
  const targetPath = path.join(patchSetsDir, `${name}.yaml`);
  try {
    if (fs.existsSync(targetPath)) {
      fs.unlinkSync(targetPath);
    }
    const remaining = fs.readdirSync(patchSetsDir)
      .filter(f => f.endsWith('.yaml'))
      .map(f => f.slice(0, -5))
      .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    if (remaining.length === 0) {
      const fallback = 'Default';
      fs.writeFileSync(path.join(patchSetsDir, '.default'), fallback + '\n', 'utf8');
      chuckClient.send('/cadenza/setPatchSetName', fallback, fallback);
      chuckClient.send('/cadenza/save', 1);
      if (lastState) {
        lastState.patchSetName = fallback;
        lastState.defaultPatchSetName = fallback;
        broadcast({ type: 'state', data: lastState });
      }
    } else {
      let newDefault = info.defaultPatchSet;
      if (info.defaultPatchSet === name || !remaining.includes(newDefault)) {
        newDefault = remaining[0];
        fs.writeFileSync(path.join(patchSetsDir, '.default'), newDefault + '\n', 'utf8');
      }
      let newCurrent = (lastState && lastState.patchSetName) || newDefault;
      if (newCurrent === name || !remaining.includes(newCurrent)) {
        newCurrent = newDefault;
        chuckClient.send('/cadenza/setPatchSetName', newCurrent, newDefault);
        chuckClient.send('/cadenza/loadPatchSet', newCurrent);
      } else {
        chuckClient.send('/cadenza/setPatchSetName', newCurrent, newDefault);
        if (lastState) {
          lastState.patchSetName = newCurrent;
          lastState.defaultPatchSetName = newDefault;
          broadcast({ type: 'state', data: lastState });
        }
      }
    }
  } catch (err) {
    console.error('Failed to delete patch set:', err.message);
  }
  broadcast({ type: 'patchSets', data: ensurePatchSetsDir(songName) });
}

module.exports = {
  normalizeSongName,
  getActiveSongName,
  ensurePatchSetsDir,
  buildYamlFromState,
  createPatchSet,
  renamePatchSet,
  setDefaultPatchSet,
  deletePatchSet,
};
