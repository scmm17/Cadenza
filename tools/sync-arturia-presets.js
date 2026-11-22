#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const CATALOG_PATH = path.join(ROOT, 'presets', 'catalog.json');
const ARTURIA_DB_PATH = '/Library/Arturia/Presets/db.db3';
const ARTURIA_LIB_ROOT = '/Library/Arturia';
const PLAYLIST_NAME = 'Cadenza';
const MAX_PROGRAMS_PER_BANK = 128;

const TARGET_SYNTHS = [
  {
    uiName: 'Acid V',
    className: 'AcidV',
    dbInstrumentName: 'Acid',
    appName: 'Acid V',
    folderName: 'Acid V',
    iacBusName: 'Acid V',
    deviceName: 'IAC Driver Acid V',
    fixedChannel: 0,
    maxChannels: 1,
    defaultPreset: 'Fast Travel',
  },
  {
    uiName: 'Augmented Mallets',
    className: 'AugmentedMallets',
    dbInstrumentName: 'Augmented MALLETS',
    appName: 'Augmented MALLETS',
    folderName: 'Augmented MALLETS',
    iacBusName: 'Augmented Mallets',
    deviceName: 'IAC Driver Augmented Mallets',
    fixedChannel: 1,
    maxChannels: 1,
    defaultPreset: 'A Royal Mallet',
  },
];

function sqlEscape(str) {
  return String(str).replace(/'/g, "''");
}

function deterministicUuid(instKey, presetKey) {
  const hash = crypto
    .createHash('sha1')
    .update(`cadenza:${instKey}:${presetKey}`)
    .digest('hex');
  return [
    hash.slice(0, 8),
    hash.slice(8, 12),
    `4${hash.slice(13, 16)}`,
    `8${hash.slice(17, 20)}`,
    hash.slice(20, 32),
  ].join('-');
}

function enableIacDriver() {
  if (process.platform !== 'darwin') {
    console.log('Skipping CoreMIDI IAC Driver setup (not macOS).');
    return;
  }
  const busLiterals = TARGET_SYNTHS.map(s => JSON.stringify(s.iacBusName)).join(', ');
  const swiftCode = `
import CoreMIDI
import Foundation

let requiredBuses = [${busLiterals}]
let n = MIDIGetNumberOfDevices()
var iacDev: MIDIDeviceRef = 0
for i in 0..<n {
    let dev = MIDIGetDevice(i)
    var name: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(dev, kMIDIPropertyName, &name)
    if (name?.takeRetainedValue() as String?) == "IAC Driver" {
        iacDev = dev
        break
    }
}
if iacDev == 0 {
    fputs("IAC Driver device not found in CoreMIDI.\\n", stderr)
    exit(1)
}

var needsRestart = false
var offline: Int32 = 0
MIDIObjectGetIntegerProperty(iacDev, kMIDIPropertyOffline, &offline)
if offline != 0 {
    let err = MIDIObjectSetIntegerProperty(iacDev, kMIDIPropertyOffline, 0)
    if err == noErr {
        print("IAC Driver brought online.")
        needsRestart = true
    } else {
        fputs("Failed to set IAC Driver online (OSStatus \\(err))\\n", stderr)
        exit(1)
    }
} else {
    print("IAC Driver is already online.")
}

var existingBuses = Set<String>()
let entityCount = MIDIDeviceGetNumberOfEntities(iacDev)
for i in 0..<entityCount {
    let ent = MIDIDeviceGetEntity(iacDev, i)
    var ename: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(ent, kMIDIPropertyName, &ename)
    if let s = ename?.takeRetainedValue() as String? {
        existingBuses.insert(s)
    }
}

for bus in requiredBuses {
    if !existingBuses.contains(bus) {
        var newEnt: MIDIEntityRef = 0
        let err = MIDIDeviceAddEntity(iacDev, bus as CFString, true, 1, 1, &newEnt)
        if err == noErr {
            print("Added IAC Driver bus: '\\(bus)'")
            needsRestart = true
        } else {
            fputs("Failed to add IAC bus '\\(bus)' (OSStatus \\(err))\\n", stderr)
            exit(1)
        }
    }
}

if needsRestart {
    let err = MIDIRestart()
    if err != noErr {
        fputs("MIDIRestart returned OSStatus \\(err)\\n", stderr)
    }
    Thread.sleep(forTimeInterval: 0.75)
}

let destCount = MIDIGetNumberOfDestinations()
var visibleDests = Set<String>()
for i in 0..<destCount {
    let ep = MIDIGetDestination(i)
    var dname: Unmanaged<CFString>?
    MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &dname)
    if let s = dname?.takeRetainedValue() as String? {
        visibleDests.insert(s)
    }
}
for bus in requiredBuses {
    let full = "IAC Driver \\(bus)"
    print("IAC destination '\\(full)' visible: \\(visibleDests.contains(full))")
}
`;
  try {
    const out = execFileSync('swift', ['-e', swiftCode], { encoding: 'utf8' }).trim();
    if (out) console.log(out);
  } catch (err) {
    console.warn('Warning: Could not automatically enable IAC Driver via CoreMIDI:', err.message);
    console.warn('Enable it manually in Audio MIDI Setup.app -> Window -> Show MIDI Studio -> IAC Driver.');
  }
}

function queryInstrumentAndPresets(synth) {
  const esc = sqlEscape(synth.dbInstrumentName);
  const instSql = `SELECT key_id, name, display_name FROM Instruments WHERE name = '${esc}' OR display_name = '${esc}' ORDER BY CASE WHEN name = '${esc}' THEN 0 ELSE 1 END LIMIT 1;`;
  const instRows = JSON.parse(
    execFileSync('sqlite3', ['-cmd', '.timeout 5000', '-json', ARTURIA_DB_PATH, instSql], {
      encoding: 'utf8',
    }) || '[]'
  );
  if (!instRows.length) {
    throw new Error(`Instrument '${synth.dbInstrumentName}' not found in ${ARTURIA_DB_PATH}`);
  }
  const instrumentKey = instRows[0].key_id;
  const instrumentName = instRows[0].name;

  // Match Arturia's in-app category browser: for Augmented Mallets, split Keys into its subtypes
  // (Classic Synth Keys, Lofi Keys, Evolving Keys, Percussive Keys, Bells, Mallets) while keeping
  // Bass, Pad, Sequence, Sound Effects, Template; for Acid V, use subtype (falling back to type).
  const categoryExpr = synth.uiName === 'Augmented Mallets'
    ? "CASE WHEN t.name = 'Keys' AND st.name IS NOT NULL AND st.name != '' THEN st.name ELSE COALESCE(t.name, 'Other') END"
    : "COALESCE(NULLIF(st.name, ''), t.name, 'Other')";

  const presetsSql = [
    `SELECT p.key_id, p.name, p.file_path, ${categoryExpr} AS category`,
    'FROM Preset_Id p',
    'LEFT JOIN Types_V2 t ON p.type_v2 = t.key_id',
    'LEFT JOIN Subtypes_V2 st ON p.subtype_v2 = st.key_id',
    `WHERE p.instrument_key = ${instrumentKey} AND p.hide_in_browser = 0`,
    'ORDER BY category ASC, p.name ASC;',
  ].join(' ');

  const rows = JSON.parse(
    execFileSync('sqlite3', ['-cmd', '.timeout 5000', '-json', ARTURIA_DB_PATH, presetsSql], {
      encoding: 'utf8',
    }) || '[]'
  );

  const songs = [];
  const catalogEntries = [];
  const byCategory = new Map();
  for (const r of rows) {
    const cat = r.category || 'Other';
    if (!byCategory.has(cat)) byCategory.set(cat, []);
    byCategory.get(cat).push(r);
  }

  let bankIdx = 0;
  for (const [category, list] of byCategory.entries()) {
    for (let offset = 0; offset < list.length; offset += MAX_PROGRAMS_PER_BANK) {
      const chunk = list.slice(offset, offset + MAX_PROGRAMS_PER_BANK);
      const chunkNum = Math.floor(offset / MAX_PROGRAMS_PER_BANK) + 1;
      const songName = list.length > MAX_PROGRAMS_PER_BANK ? `${category} (${chunkNum})` : category;
      songs.push({ bank: bankIdx, songName, presets: chunk });
      chunk.forEach((p, progIdx) => {
        catalogEntries.push({
          program: progIdx,
          bank: bankIdx,
          name: p.name,
          category,
        });
      });
      bankIdx++;
    }
  }

  return { instrumentKey, instrumentName, songs, catalogEntries };
}

function syncDbPlaylist(instrumentKey, instrumentName, songs, folderName) {
  // Arturia's PlaylistController reads /Library/Arturia/Presets/<folder>/Playlists/<name>/<name>.json
  // on startup and reconciles Playlists_V2 / Playlist_Songs / Playlist_Presets against it.
  const playlistDir = path.join(ARTURIA_LIB_ROOT, 'Presets', folderName, 'Playlists', PLAYLIST_NAME);
  fs.mkdirSync(playlistDir, { recursive: true });

  const presetsRootPrefix = path.join(ARTURIA_LIB_ROOT, 'Presets');
  const playlistJson = {
    version: 2,
    name: PLAYLIST_NAME,
    instrument: instrumentName,
    idx: 0,
    songs: songs.map((song) => ({
      name: song.songName,
      idx: song.bank,
      presets: song.presets.map((p, progIdx) => {
        const relPath = p.file_path.startsWith(presetsRootPrefix)
          ? p.file_path.slice(presetsRootPrefix.length)
          : p.file_path;
        return {
          name: p.name,
          path: relPath,
          uuid: deterministicUuid(instrumentKey, p.key_id),
          idx: progIdx,
        };
      }),
    })),
  };
  fs.writeFileSync(
    path.join(playlistDir, `${PLAYLIST_NAME}.json`),
    JSON.stringify(playlistJson),
    'utf8'
  );

  const epochStr = String(Math.floor(Date.now() / 1000));
  const plEsc = sqlEscape(PLAYLIST_NAME);
  const stmts = [
    'PRAGMA foreign_keys = ON;',
    'PRAGMA busy_timeout = 5000;',
    'BEGIN IMMEDIATE;',
    `DELETE FROM Playlist_Presets WHERE playlist_key IN (SELECT key_id FROM Playlists_V2 WHERE name = '${plEsc}' AND instrument_key = ${instrumentKey});`,
    `DELETE FROM Playlist_Songs WHERE playlist_key IN (SELECT key_id FROM Playlists_V2 WHERE name = '${plEsc}' AND instrument_key = ${instrumentKey});`,
    `DELETE FROM Playlists_V2 WHERE name = '${plEsc}' AND instrument_key = ${instrumentKey};`,
    `DELETE FROM Playlist_Presets WHERE preset_key IN (SELECT key_id FROM Preset_Id WHERE instrument_key = ${instrumentKey});`,
    `UPDATE Playlists_V2 SET idx = idx + 1 WHERE instrument_key = ${instrumentKey} AND EXISTS (SELECT 1 FROM Playlists_V2 WHERE instrument_key = ${instrumentKey} AND idx = 0);`,
    `INSERT INTO Playlists_V2 (name, instrument_key, idx, last_change) VALUES ('${plEsc}', ${instrumentKey}, 0, '${epochStr}');`,
  ];

  const plSubquery = `(SELECT key_id FROM Playlists_V2 WHERE name = '${plEsc}' AND instrument_key = ${instrumentKey})`;
  for (const song of songs) {
    const songEsc = sqlEscape(song.songName);
    stmts.push(
      `INSERT INTO Playlist_Songs (playlist_key, name, idx) VALUES (${plSubquery}, '${songEsc}', ${song.bank});`
    );
    const songSubquery = `(SELECT key_id FROM Playlist_Songs WHERE playlist_key = ${plSubquery} AND idx = ${song.bank})`;
    song.presets.forEach((p, progIdx) => {
      const uuid = deterministicUuid(instrumentKey, p.key_id);
      stmts.push(
        `INSERT INTO Playlist_Presets (preset_key, playlist_key, song_key, idx, uuid) VALUES (${p.key_id}, ${plSubquery}, ${songSubquery}, ${progIdx}, '${uuid}');`
      );
    });
  }
  stmts.push('COMMIT;');

  execFileSync('sqlite3', [ARTURIA_DB_PATH], {
    input: stmts.join('\n'),
    encoding: 'utf8',
  });
}

function seedStandalonePreferences(synth) {
  const tmpDir = path.join(ARTURIA_LIB_ROOT, synth.folderName, 'tmp');
  fs.mkdirSync(tmpDir, { recursive: true });

  const standalonePath = path.join(tmpDir, 'standalone.pref');
  if (!fs.existsSync(standalonePath)) {
    const content = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '',
      '<PROPERTIES>',
      '  <VALUE name="Tempo" val="120"/>',
      `  <VALUE name="MidiDevice_1" val="${synth.deviceName}"/>`,
      '</PROPERTIES>',
      '',
    ].join('\n');
    fs.writeFileSync(standalonePath, content, 'utf8');
  } else {
    let xml = fs.readFileSync(standalonePath, 'utf8');
    const desiredLine = `  <VALUE name="MidiDevice_1" val="${synth.deviceName}"/>`;
    const stripped = xml.replace(/^[ \t]*<VALUE\s+name="MidiDevice_\d+"\s+[^>]*\/>\r?\n?/gm, '');
    if (stripped.includes('</PROPERTIES>')) {
      const updated = stripped.replace('</PROPERTIES>', `${desiredLine}\n</PROPERTIES>`);
      if (updated !== xml) {
        fs.writeFileSync(standalonePath, updated, 'utf8');
      }
    }
  }

  // MidiChList has 17 entries (0=All, 1..16=channels 1..16); normalized value = (ch1Based / 16).
  const normChannel = ((synth.fixedChannel + 1) / 16).toFixed(6);
  const pluginPrefPath = path.join(tmpDir, 'plugin.pref.xml');
  if (!fs.existsSync(pluginPrefPath)) {
    const content = [
      '<?xml version="1.0" encoding="utf-8"?>',
      '<rootnode>',
      `\t<param name="MIDI Channel" value="${normChannel}"/>`,
      `\t<param name="GlobalInputMidiChannel" value="${normChannel}"/>`,
      '</rootnode>',
      '',
    ].join('\n');
    fs.writeFileSync(pluginPrefPath, content, 'utf8');
  } else {
    let xml = fs.readFileSync(pluginPrefPath, 'utf8');
    const setParam = (doc, paramName, val) => {
      const re = new RegExp(`(<param\\s+name="${paramName}"\\s+value=")[^"]*("\\s*/>)`);
      if (re.test(doc)) {
        return doc.replace(re, `$1${val}$2`);
      }
      if (doc.includes('</rootnode>')) {
        return doc.replace('</rootnode>', `\t<param name="${paramName}" value="${val}"/>\n</rootnode>`);
      }
      return doc;
    };
    xml = setParam(xml, 'MIDI Channel', normChannel);
    xml = setParam(xml, 'GlobalInputMidiChannel', normChannel);
    fs.writeFileSync(pluginPrefPath, xml, 'utf8');
  }
}

function updateCatalog(syncedData) {
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
  catalog.synths = catalog.synths || {};
  catalog.presets = catalog.presets || {};

  for (const { synth, catalogEntries } of syncedData) {
    catalog.synths[synth.uiName] = {
      class: synth.className,
      deviceName: synth.deviceName,
      appName: synth.appName,
      fixedChannel: synth.fixedChannel,
      maxChannels: synth.maxChannels,
      defaultPreset: synth.defaultPreset,
    };
    catalog.presets[synth.uiName] = catalogEntries;
  }

  fs.writeFileSync(CATALOG_PATH, JSON.stringify(catalog, null, 2) + '\n', 'utf8');
}

function main() {
  if (!fs.existsSync(ARTURIA_DB_PATH)) {
    throw new Error(`Arturia preset database not found at ${ARTURIA_DB_PATH}`);
  }

  enableIacDriver();

  const syncedData = [];
  for (const synth of TARGET_SYNTHS) {
    const { instrumentKey, instrumentName, songs, catalogEntries } = queryInstrumentAndPresets(synth);
    syncDbPlaylist(instrumentKey, instrumentName, songs, synth.folderName);
    seedStandalonePreferences(synth);
    syncedData.push({ synth, catalogEntries });
    console.log(
      `Synced ${synth.uiName} (instrument_key=${instrumentKey}): ${catalogEntries.length} presets across ${songs.length} bank(s), MIDI ch=${synth.fixedChannel + 1}`
    );
  }

  updateCatalog(syncedData);
  console.log(`Updated ${path.relative(ROOT, CATALOG_PATH)}`);

  execFileSync(process.execPath, [path.join(ROOT, 'tools', 'gen-presets.js')], {
    stdio: 'inherit',
  });
}

main();
