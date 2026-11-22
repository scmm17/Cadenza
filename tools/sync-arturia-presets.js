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
  // Core 7 (hand-written device subclasses with synth-specific CC helpers)
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
    volumeCc: 85,
    defaultPreset: 'Fast Travel',
    useSubtypes: true,
  },
  {
    uiName: 'Augmented Mallets',
    className: 'AugmentedMallets',
    dbInstrumentName: 'Augmented MALLETS',
    appName: 'Augmented MALLETS',
    folderName: 'Augmented MALLETS',
    iacBusName: 'Augmented Mallets',
    deviceName: 'IAC Driver Augmented Mallets',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 17,
    defaultPreset: 'A Royal Mallet',
    splitTypes: ['Keys'],
  },
  {
    uiName: 'Augmented Brass',
    className: 'AugmentedBrass',
    dbInstrumentName: 'Augmented BRASS',
    appName: 'Augmented BRASS',
    folderName: 'Augmented BRASS',
    iacBusName: 'Augmented Brass',
    deviceName: 'IAC Driver Augmented Brass',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 17,
    defaultPreset: 'Wide and Proud',
    splitTypes: ['Brass & Winds'],
  },
  {
    uiName: 'Augmented Grand Piano',
    className: 'AugmentedGrandPiano',
    dbInstrumentName: 'Augmented GRAND PIANO',
    appName: 'Augmented GRAND PIANO',
    folderName: 'Augmented GRAND PIANO',
    iacBusName: 'Augmented Grand Piano',
    deviceName: 'IAC Driver Augmented Grand Piano',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 17,
    defaultPreset: 'Kairos',
    splitTypes: ['Piano'],
  },
  {
    uiName: 'Augmented Strings',
    className: 'AugmentedStrings',
    dbInstrumentName: 'Augmented STRINGS',
    appName: 'Augmented STRINGS',
    folderName: 'Augmented STRINGS',
    iacBusName: 'Augmented Strings',
    deviceName: 'IAC Driver Augmented Strings',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 17,
    defaultPreset: 'Baited Breath',
    splitTypes: ['Strings', 'Pad'],
  },
  {
    uiName: 'Synclavier V',
    className: 'SynclavierV',
    dbInstrumentName: 'Synclavier V',
    appName: 'Synclavier V',
    folderName: 'Synclavier V',
    iacBusName: 'Synclavier V',
    deviceName: 'IAC Driver Synclavier V',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 7,
    defaultPreset: 'Naked Planet',
    splitTypes: ['Pad'],
  },
  {
    uiName: 'Synthi V',
    className: 'SynthiV',
    dbInstrumentName: 'Synthi V',
    appName: 'Synthi V',
    folderName: 'Synthi V',
    iacBusName: 'Synthi V',
    deviceName: 'IAC Driver Synthi V',
    fixedChannel: 0,
    maxChannels: 1,
    volumeCc: 7,
    defaultPreset: 'On The Run',
    splitTypes: [],
  },
  // Remaining installed Arturia V Collection / Augmented instruments (auto-generated subclasses)
  // All use fixedChannel: 0 (MIDI ch 1) on their dedicated IAC bus to match Arturia's Default MIDI CC channel="0".
  { uiName: 'Analog Lab V',        className: 'AnalogLabV',         dbInstrumentName: 'Analog Lab V',        appName: 'Analog Lab V',        folderName: 'Analog Lab V',        iacBusName: 'Analog Lab V',        deviceName: 'IAC Driver Analog Lab V',        fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 0,     defaultPreset: 'Classic Jun Keys' },
  { uiName: 'ARP 2600 V3',         className: 'ARP2600V3',          dbInstrumentName: 'ARP 2600',            appName: 'ARP 2600 V3',         folderName: 'ARP 2600 V3',         iacBusName: 'ARP 2600 V3',         deviceName: 'IAC Driver ARP 2600 V3',         fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Sync Seq' },
  { uiName: 'Augmented Voices',    className: 'AugmentedVoices',    dbInstrumentName: 'Augmented VOICES',    appName: 'Augmented VOICES',    folderName: 'Augmented VOICES',    iacBusName: 'Augmented Voices',    deviceName: 'IAC Driver Augmented Voices',    fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: 'Voices Trailer' },
  { uiName: 'Augmented Woodwinds', className: 'AugmentedWoodwinds', dbInstrumentName: 'Augmented WOODWINDS', appName: 'Augmented WOODWINDS', folderName: 'Augmented WOODWINDS', iacBusName: 'Augmented Woodwinds', deviceName: 'IAC Driver Augmented Woodwinds', fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: "Andromeda's Voice" },
  { uiName: 'Augmented Yangtze',   className: 'AugmentedYangtze',   dbInstrumentName: 'Augmented YANGTZE',   appName: 'Augmented YANGTZE',   folderName: 'Augmented YANGTZE',   iacBusName: 'Augmented Yangtze',   deviceName: 'IAC Driver Augmented Yangtze',   fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: 'Windy Day' },
  { uiName: 'B-3 V2',              className: 'B3V2',               dbInstrumentName: 'B-3 V2',              appName: 'B-3 V2',              folderName: 'B-3 V2',              iacBusName: 'B-3 V2',              deviceName: 'IAC Driver B-3 V2',              fixedChannel: null, maxChannels: 3, volumeCc: 11, defaultPreset: 'Jazz Organ' },
  { uiName: 'Buchla Easel V',      className: 'BuchlaEaselV',       dbInstrumentName: 'Buchla Easel',        appName: 'Buchla Easel V',      folderName: 'Buchla Easel V',      iacBusName: 'Buchla Easel V',      deviceName: 'IAC Driver Buchla Easel V',      fixedChannel: 0, maxChannels: 1, volumeCc: 90, volumeParamId: 36,    defaultPreset: 'Volt-aged Piano' },
  { uiName: 'CMI V',               className: 'CMIV',               dbInstrumentName: 'CMI',                 appName: 'CMI V',               folderName: 'CMI V',               iacBusName: 'CMI V',               deviceName: 'IAC Driver CMI V',               fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Sararr' },
  { uiName: 'CP-70 V',             className: 'CP70V',              dbInstrumentName: 'CP-70 V',             appName: 'CP-70 V',             folderName: 'CP-70 V',             iacBusName: 'CP-70 V',             deviceName: 'IAC Driver CP-70 V',             fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: 'Definitive CP' },
  { uiName: 'CS-80 V4',            className: 'CS80V4',             dbInstrumentName: 'CS-80 V4',            appName: 'CS-80 V4',            folderName: 'CS-80 V4',            iacBusName: 'CS-80 V4',            deviceName: 'IAC Driver CS-80 V4',            fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Aftertouch Surprise' },
  { uiName: 'CZ V',                className: 'CZV',                dbInstrumentName: 'CZ V',                appName: 'CZ V',                folderName: 'CZ V',                iacBusName: 'CZ V',                deviceName: 'IAC Driver CZ V',                fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'The CZ Brass' },
  { uiName: 'Clavinet V',          className: 'ClavinetV',          dbInstrumentName: 'Clavinet V',          appName: 'Clavinet V',          folderName: 'Clavinet V',          iacBusName: 'Clavinet V',          deviceName: 'IAC Driver Clavinet V',          fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Love & Happiness' },
  { uiName: 'DX7 V',               className: 'DX7V',               dbInstrumentName: 'DX7 V',               appName: 'DX7 V',               folderName: 'DX7 V',               iacBusName: 'DX7 V',               deviceName: 'IAC Driver DX7 V',               fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 936,   defaultPreset: 'Rom1A 11-E.PIANO 1' },
  { uiName: 'Emulator II V',       className: 'EmulatorIIV',        dbInstrumentName: 'Emulator II V',       appName: 'Emulator II V',       folderName: 'Emulator II V',       iacBusName: 'Emulator II V',       deviceName: 'IAC Driver Emulator II V',       fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Voices' },
  { uiName: 'Farfisa V',           className: 'FarfisaV',           dbInstrumentName: 'Farfisa',             appName: 'Farfisa V',           folderName: 'Farfisa V',           iacBusName: 'Farfisa V',           deviceName: 'IAC Driver Farfisa V',           fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Dreamy Organ' },
  { uiName: 'Jun-6 V',             className: 'Jun6V',              dbInstrumentName: 'Jun-6 V',             appName: 'Jun-6 V',             folderName: 'Jun-6 V',             iacBusName: 'Jun-6 V',             deviceName: 'IAC Driver Jun-6 V',             fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Classic Road' },
  { uiName: 'Jup-8 V4',            className: 'Jup8V4',             dbInstrumentName: 'Jup-8 V4',            appName: 'Jup-8 V4',            folderName: 'Jup-8 V4',            iacBusName: 'Jup-8 V4',            deviceName: 'IAC Driver Jup-8 V4',            fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Different Waze' },
  { uiName: 'Jup-8000 V',          className: 'Jup8000V',           dbInstrumentName: 'Jup-8000 V',          appName: 'Jup-8000 V',          folderName: 'Jup-8000 V',          iacBusName: 'Jup-8000 V',          deviceName: 'IAC Driver Jup-8000 V',          fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 4,     defaultPreset: 'Vanilla Supasaw Pad' },
  { uiName: 'KORG MS-20 V',        className: 'KorgMS20V',          dbInstrumentName: 'KORG MS-20 V',        appName: 'KORG MS-20 V',        folderName: 'KORG MS-20 V',        iacBusName: 'KORG MS-20 V',        deviceName: 'IAC Driver KORG MS-20 V',        fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Mark One' },
  { uiName: 'Matrix-12 V2',        className: 'Matrix12V2',         dbInstrumentName: 'Matrix-12 V2',        appName: 'Matrix-12 V2',        folderName: 'Matrix-12 V2',        iacBusName: 'Matrix-12 V2',        deviceName: 'IAC Driver Matrix-12 V2',        fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Encounter Pad' },
  { uiName: 'Mellotron V',         className: 'MellotronV',         dbInstrumentName: 'Mellotron V',         appName: 'Mellotron V',         folderName: 'Mellotron V',         iacBusName: 'Mellotron V',         deviceName: 'IAC Driver Mellotron V',         fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Strawberry Flutes' },
  { uiName: 'Mini V4',             className: 'MiniV4',             dbInstrumentName: 'Mini V4',             appName: 'Mini V4',             folderName: 'Mini V4',             iacBusName: 'Mini V4',             deviceName: 'IAC Driver Mini V4',             fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: 'Base Bass' },
  { uiName: 'MiniBrute V',         className: 'MiniBruteV',         dbInstrumentName: 'MiniBrute V',         appName: 'MiniBrute V',         folderName: 'MiniBrute V',         iacBusName: 'MiniBrute V',         deviceName: 'IAC Driver MiniBrute V',         fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Dark Atmos' },
  { uiName: 'MiniFreak V',         className: 'MiniFreakV',         dbInstrumentName: 'MiniFreak V',         appName: 'MiniFreak V',         folderName: 'MiniFreak V',         iacBusName: 'MiniFreak V',         deviceName: 'IAC Driver MiniFreak V',         fixedChannel: 0, maxChannels: 1, volumeCc: 90, volumeParamId: 13316, defaultPreset: 'It Saw Key' },
  { uiName: 'Modular V3',          className: 'ModularV3',          dbInstrumentName: 'Modular',             appName: 'Modular V3',          folderName: 'Modular V3',          iacBusName: 'Modular V3',          deviceName: 'IAC Driver Modular V3',          fixedChannel: 0, maxChannels: 1, volumeCc: 7,  defaultPreset: 'Berliner' },
  { uiName: 'OP-Xa V',             className: 'OPXaV',              dbInstrumentName: 'OP-Xa V',             appName: 'OP-Xa V',             folderName: 'OP-Xa V',             iacBusName: 'OP-Xa V',             deviceName: 'IAC Driver OP-Xa V',             fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Jump' },
  { uiName: 'Piano V3',            className: 'PianoV3',            dbInstrumentName: 'Piano V3',            appName: 'Piano V3',            folderName: 'Piano V3',            iacBusName: 'Piano V3',            deviceName: 'IAC Driver Piano V3',            fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'American Home Clean' },
  { uiName: 'Prophet-5 V',         className: 'Prophet5V',          dbInstrumentName: 'Prophet-5 V',         appName: 'Prophet-5 V',         folderName: 'Prophet-5 V',         iacBusName: 'Prophet-5 V',         deviceName: 'IAC Driver Prophet-5 V',         fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Demacro' },
  { uiName: 'Prophet-VS V',        className: 'ProphetVSV',         dbInstrumentName: 'Prophet-VS V',        appName: 'Prophet-VS V',        folderName: 'Prophet-VS V',        iacBusName: 'Prophet-VS V',        deviceName: 'IAC Driver Prophet-VS V',        fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Artistic Facts' },
  { uiName: 'Pure LoFi',           className: 'PureLoFi',           dbInstrumentName: 'Pure LoFi',           appName: 'Pure LoFi',           folderName: 'Pure LoFi',           iacBusName: 'Pure LoFi',           deviceName: 'IAC Driver Pure LoFi',           fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 4,     defaultPreset: 'Little Pleasures' },
  { uiName: 'SEM V3',              className: 'SEMV3',              dbInstrumentName: 'SEM V3',              appName: 'SEM V3',              folderName: 'SEM V3',              iacBusName: 'SEM V3',              deviceName: 'IAC Driver SEM V3',              fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 51,    defaultPreset: 'Atom Sawyer' },
  { uiName: 'SQ80 V',              className: 'SQ80V',              dbInstrumentName: 'SQ80 V',              appName: 'SQ80 V',              folderName: 'SQ80 V',              iacBusName: 'SQ80 V',              deviceName: 'IAC Driver SQ80 V',              fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Fading Memory' },
  { uiName: 'Solina V2',           className: 'SolinaV2',           dbInstrumentName: 'Solina V2',           appName: 'Solina V2',           folderName: 'Solina V2',           iacBusName: 'Solina V2',           deviceName: 'IAC Driver Solina V2',           fixedChannel: null, maxChannels: 2, volumeCc: 7,  defaultPreset: 'Blue Strings' },
  { uiName: 'Stage-73 V2',         className: 'Stage73V2',          dbInstrumentName: 'Stage-73 V2',         appName: 'Stage-73 V2',         folderName: 'Stage-73 V2',         iacBusName: 'Stage-73 V2',         deviceName: 'IAC Driver Stage-73 V2',         fixedChannel: 0, maxChannels: 1, volumeCc: 85, defaultPreset: 'Clean Mark V' },
  { uiName: 'Synthx V',            className: 'SynthxV',            dbInstrumentName: 'Synthx V',            appName: 'Synthx V',            folderName: 'Synthx V',            iacBusName: 'Synthx V',            deviceName: 'IAC Driver Synthx V',            fixedChannel: 0, maxChannels: 1, volumeCc: 7,  volumeParamId: 130,   defaultPreset: 'Pulse Width Pad' },
  { uiName: 'VOX Continental V2',  className: 'VOXContinentalV2',   dbInstrumentName: 'VOX Continental V2',  appName: 'VOX Continental V2',  folderName: 'VOX Continental V2',  iacBusName: 'VOX Continental V2',  deviceName: 'IAC Driver VOX Continental V2',  fixedChannel: null, maxChannels: 3, volumeCc: 7,  defaultPreset: 'Alternative Vib' },
  { uiName: 'Vocoder V',           className: 'VocoderV',           dbInstrumentName: 'Vocoder V',           appName: 'Vocoder V',           folderName: 'Vocoder V',           iacBusName: 'Vocoder V',           deviceName: 'IAC Driver Vocoder V',           fixedChannel: 0, maxChannels: 1, volumeCc: 18, defaultPreset: 'Vocoder' },
  { uiName: 'Wurli V3',            className: 'WurliV3',            dbInstrumentName: 'Wurli V3',            appName: 'Wurli V3',            folderName: 'Wurli V3',            iacBusName: 'Wurli V3',            deviceName: 'IAC Driver Wurli V3',            fixedChannel: 0, maxChannels: 1, volumeCc: 17, defaultPreset: 'The Gig' },
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

function runSqliteJson(sql) {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const out = execFileSync('sqlite3', ['-cmd', '.timeout 15000', '-json', ARTURIA_DB_PATH, sql], {
        encoding: 'utf8',
      });
      if (out && out.trim()) return JSON.parse(out);
    } catch (err) {
      if (attempt === 2) throw err;
    }
  }
  return [];
}

function queryInstrumentAndPresets(synth) {
  const esc = sqlEscape(synth.dbInstrumentName);
  const baseName = synth.dbInstrumentName.replace(/\s+V\d*$/, '');
  const baseEsc = sqlEscape(baseName);
  const instSql = [
    'SELECT key_id, name, display_name FROM Instruments',
    `WHERE name = '${esc}' OR display_name = '${esc}' OR name = '${baseEsc}' OR display_name = '${baseEsc}'`,
    `ORDER BY CASE WHEN name = '${esc}' THEN 0 WHEN display_name = '${esc}' THEN 1 WHEN name = '${baseEsc}' THEN 2 ELSE 3 END LIMIT 1;`,
  ].join(' ');
  const instRows = runSqliteJson(instSql);
  if (!instRows.length) {
    throw new Error(`Instrument '${synth.dbInstrumentName}' not found in ${ARTURIA_DB_PATH}`);
  }
  const instrumentKey = instRows[0].key_id;
  const instrumentName = instRows[0].name;

  const presetsSql = [
    "SELECT p.key_id, p.name, p.file_path, COALESCE(t.name, 'Other') AS type_name, COALESCE(st.name, '') AS subtype_name",
    'FROM Preset_Id p',
    'LEFT JOIN Types_V2 t ON p.type_v2 = t.key_id',
    'LEFT JOIN Subtypes_V2 st ON p.subtype_v2 = st.key_id',
    `WHERE p.instrument_key = ${instrumentKey} AND p.hide_in_browser = 0`,
    'ORDER BY p.name ASC;',
  ].join(' ');

  const rawRows = runSqliteJson(presetsSql);

  // Determine which Types_V2 categories to expand into Subtypes_V2:
  // explicit splitTypes if provided, otherwise auto-split any type with > MAX_PROGRAMS_PER_BANK presets.
  const typeCounts = new Map();
  for (const r of rawRows) {
    typeCounts.set(r.type_name, (typeCounts.get(r.type_name) || 0) + 1);
  }
  const splitSet = Array.isArray(synth.splitTypes)
    ? new Set(synth.splitTypes)
    : new Set([...typeCounts.entries()].filter(([, c]) => c > MAX_PROGRAMS_PER_BANK).map(([t]) => t));

  const rows = rawRows.map((r) => {
    let category = r.type_name || 'Other';
    if (synth.useSubtypes) {
      category = r.subtype_name || r.type_name || 'Other';
    } else if (splitSet.has(r.type_name) && r.subtype_name) {
      category = r.subtype_name;
    }
    return { key_id: r.key_id, name: r.name, file_path: r.file_path, category };
  });
  rows.sort((a, b) => {
    if (a.category !== b.category) return a.category < b.category ? -1 : 1;
    if (a.name !== b.name) return a.name < b.name ? -1 : 1;
    return 0;
  });

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

  // MidiChList has 17 entries (0=All, 1..16=channels 1..16). Because each Arturia synth has its own
  // dedicated IAC bus, 0.000000 (All) ensures no synth (such as Vocoder V) ever drops notes due to a
  // channel filter mismatch while still isolating it from every other synth.
  const normChannel = '0.000000';
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
  // For synths whose factory Default MIDI config omits Master Volume, add an explicit CC binding.
  if (synth.volumeParamId != null && synth.volumeCc != null) {
    const prefMidiPath = path.join(ARTURIA_LIB_ROOT, synth.folderName, 'resources', 'plugin.prefmidi.xml');
    if (fs.existsSync(prefMidiPath)) {
      let midiXml = fs.readFileSync(prefMidiPath, 'utf8');
      const defBlockRe = /(<midiconfig\s+name="Default"[^>]*>)([\s\S]*?)(<\/midiconfig>)/;
      const m = midiXml.match(defBlockRe);
      if (m) {
        const ccRe = new RegExp(`controller="${synth.volumeCc}"`);
        if (!ccRe.test(m[2])) {
          const entry = `\t\t<assignment controller="${synth.volumeCc}" channel="0" paramid="${synth.volumeParamId}" min="0.000000" max="1.000000" isrelative="0"/>\n`;
          midiXml = midiXml.replace(defBlockRe, `$1\n${entry}$2$3`);
          fs.writeFileSync(prefMidiPath, midiXml, 'utf8');
        }
      }
    }
  }
}

function updateCatalog(syncedData) {
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
  catalog.synths = catalog.synths || {};
  catalog.presets = catalog.presets || {};

  for (const { synth, catalogEntries } of syncedData) {
    const hasDefault = catalogEntries.some((p) => p.name === synth.defaultPreset);
    const resolvedDefault = hasDefault
      ? synth.defaultPreset
      : (catalogEntries[0] ? catalogEntries[0].name : synth.defaultPreset);
    catalog.synths[synth.uiName] = {
      class: synth.className,
      deviceName: synth.deviceName,
      appName: synth.appName,
      fixedChannel: synth.fixedChannel,
      maxChannels: synth.maxChannels,
      volumeCc: synth.volumeCc != null ? synth.volumeCc : 7,
      defaultPreset: resolvedDefault,
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
    const chLabel = synth.fixedChannel != null ? `${synth.fixedChannel + 1}` : `1..${synth.maxChannels}`;
    console.log(
      `Synced ${synth.uiName} (instrument_key=${instrumentKey}): ${catalogEntries.length} presets across ${songs.length} bank(s), MIDI ch=${chLabel}`
    );
  }

  updateCatalog(syncedData);
  console.log(`Updated ${path.relative(ROOT, CATALOG_PATH)}`);

  execFileSync(process.execPath, [path.join(ROOT, 'tools', 'gen-presets.js')], {
    stdio: 'inherit',
  });
}

main();
