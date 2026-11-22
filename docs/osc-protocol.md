# Cadenza OSC & WebSocket Protocol

Reference for the real-time wire protocol between **ChucK**, the **Node.js Bridge Server** (`gui/server.js` + `gui/server/osc-bridge.js`), and the **Live Dashboard** (`gui/index.html` + `gui/js/*`).

## Transport Ports

| Direction | Transport | Endpoint |
|---|---|---|
| GUI Bridge → ChucK | OSC over UDP | `127.0.0.1:9449` (`CadenzaConstants.OSC_CONTROL_PORT()`) |
| ChucK → GUI Bridge | OSC over UDP | `localhost:9450` (`CadenzaConstants.OSC_GUI_PORT()`) |
| Browser ↔ GUI Bridge | WebSocket (JSON) | `ws://localhost:3000` |

---

## 1. OSC: GUI Bridge → ChucK (`:9449`)

Handled by `framework/control/osc-control.ck` (`OscControl`).

### Transport & Modes

| Address | Args | Description |
|---|---|---|
| `/cadenza/play` | `i` | Resume playback (`1`). |
| `/cadenza/pause` | `i` | Pause playback and send All-Notes-Off (`1`). |
| `/cadenza/restart` | `i` | Reset fragment cursor to `startFragment`, clear queued/looped fragments, pause, and stop active shreds (`1`). |
| `/cadenza/tempo` | `i` | Set tempo in BPM (`40`–`240`). |
| `/cadenza/golden` | `i` | Toggle deterministic ("golden") fragment transitions (`1`). |
| `/cadenza/allMode` | `i` | Toggle all-parts-active mode (`1`). |
| `/cadenza/save` | `i` | Persist current patch set YAML to disk (`1`). |
| `/cadenza/shutdown` | `i` | Send All-Notes-Off, clear LaunchControl LEDs, and exit ChucK (`1`). |

### Fragment Navigation

| Address | Args | Description |
|---|---|---|
| `/cadenza/nextFragment` | `s` | Queue fragment by name for next transition (or `""` to clear). |
| `/cadenza/loopFragment` | `s` | Toggle looping of fragment by name (or `""` to clear). |

### Device & Parameter Control

All `devIdx` arguments are **1-based** (`1`–`16`). All MIDI `channel` arguments are **1-based** (`1`–`16`).

| Address | Args | Description |
|---|---|---|
| `/cadenza/device` | `i` | Select active device (`devIdx`). |
| `/cadenza/muteDevice` | `i` | Toggle mute on device (`devIdx`). |
| `/cadenza/soloDevice` | `i` | Enable solo mode (if off) and toggle solo on device (`devIdx`). |
| `/cadenza/volume` | `ii` | Set volume (`devIdx`, `0`–`127`, CC 7). |
| `/cadenza/cutoff` | `ii` | Set filter cutoff (`devIdx`, `0`–`127`, CC 74 or CC 19 on Moog). |
| `/cadenza/resonance` | `ii` | Set filter resonance (`devIdx`, `0`–`127`, CC 71 or CC 21 on Moog). |
| `/cadenza/pan` | `ii` | Set stereo pan (`devIdx`, `-64`–`63`; stored as `0`–`127` with `64` center, CC 10 except on Moog). |
| `/cadenza/setSynth` | `is` | Replace device synth (`devIdx`, `uiName` e.g. `"V3"`, `"Hydrasynth"`, `"SH-4d"`, `"S-1"`, `"Moog"`, `"RD-6"`, `"Acid V"`, `"Augmented Mallets"`). |
| `/cadenza/setChannel` | `ii` | Change device MIDI channel (`devIdx`, `1`–`16`). |

### Presets & Patch Sets

| Address | Args | Description |
|---|---|---|
| `/cadenza/prevPreset` | `i` | Step active device to previous preset (`1`). |
| `/cadenza/nextPreset` | `i` | Step active device to next preset (`1`). |
| `/cadenza/prevPresetCat` | `i` | Step active device to previous preset category / Moog bank (`1`). |
| `/cadenza/nextPresetCat` | `i` | Step active device to next preset category / Moog bank (`1`). |
| `/cadenza/setPreset` | `is` | Select device and apply named preset (`devIdx`, `presetName`). |
| `/cadenza/loadPatchSet` | `s` | Load named YAML patch set for the current song. |
| `/cadenza/setPatchSetName` | `ss` | Update in-memory `(currentPatchSet, defaultPatchSet)` names. |
| `/cadenza/createPatchSet` | `ss` | Create and save current settings as `(newName, defaultPatchSet)`. |

---

## 2. OSC: ChucK → GUI Bridge (`:9450`)

Sent via `framework/core/gui-link.ck` (`GuiLink`).

| Address | Args | Description |
|---|---|---|
| `/cadenza/state` | `s` | Full dashboard state as JSON string (see schema below). |
| `/cadenza/graphNode` | `iis` | Fragment graph node batch: `(index, total, nodeJson)`. `(0, 0, "")` indicates no fragments. |
| `/cadenza/transition` | `ss` | Fragment transition edge taken: `(fromFragmentName, toFragmentName)`. |
| `/cadenza/noteOn` | `iii` | Note-on event for piano roll: `(devIndex, midiNote, velocity)`. |
| `/cadenza/noteOff` | `ii` | Note-off event for piano roll: `(devIndex, midiNote)`. |
| `/cadenza/allNotesOff` | `i` | All-notes-off for device: `(devIndex)`. |
| `/cadenza/activateSynth` | `s` | Request Node.js bridge to ensure the macOS standalone app for `uiName` is running (`"Acid V"`, `"Augmented Mallets"`, etc.). |

### `/cadenza/state` JSON Payload

```json
{
  "songName": "darius01",
  "patchSetName": "Default",
  "defaultPatchSetName": "Default",
  "fragmentName": "Verse 1",
  "nextFragmentName": "",
  "loopFragmentName": "",
  "bpm": 120.0,
  "muteMode": 0,
  "soloMode": 1,
  "golden": 0,
  "allMode": 0,
  "isPaused": 1,
  "currentDeviceIndex": 0,
  "devices": [
    {
      "index": 1,
      "uiName": "Hydrasynth",
      "channel": 1,
      "patchName": "Sawpressive GD",
      "bank": 0,
      "program": 0,
      "volume": 100,
      "filterCutoff": -1,
      "filterResonance": -1,
      "pan": 0,
      "muted": 0,
      "soloed": 0,
      "active": 1,
      "playing": 0
    }
  ],
  "repeatIndex": 1,
  "repeatCount": 2
}
```

### `/cadenza/graphNode` JSON Payload

```json
{
  "name": "Verse 1",
  "repeat": 2,
  "edges": [
    { "to": "Chorus 1", "p": 0.7 },
    { "to": "Bridge", "p": 0.3 }
  ]
}
```

---

## 3. WebSocket: Browser ↔ GUI Bridge (`ws://localhost:3000`)

### Server → Browser (`{ type, ... }`)

| `type` | Payload | Description |
|---|---|---|
| `presets` | `data: { V3, Hydrasynth, 'SH-4d', Moog, 'Acid V', 'Augmented Mallets', synths, synthMeta, moogBanks }` | Full catalog from `presets/catalog.json` (sent on connect and `getPresets`). |
| `state` | `data: <state>` | Parsed `/cadenza/state` payload. |
| `graph` | `fragments: <node[]>` | Reassembled fragment graph from `/cadenza/graphNode`. |
| `patchSets` | `data: { songName, patchSets, defaultPatchSet }` | Patch-set list and default metadata from disk. |
| `songList` | `songs: string[]` | `.ck` scripts discovered under `music/`. |
| `transition` | `from, to` | Fragment transition edge notification. |
| `noteOn` | `dev, note, vel` | Piano-roll note-on. |
| `noteOff` | `dev, note` | Piano-roll note-off. |
| `allNotesOff` | `dev` | Piano-roll all-notes-off. |

### Browser → Server (`{ type, value }`)

- **Simple OSC pass-throughs:** `device`, `golden`, `allMode`, `save`, `shutdown`, `play`, `pause`, `restart`, `nextFragment`, `loopFragment`, `muteDevice`, `soloDevice`, `prevPresetCat`, `prevPreset`, `nextPreset`, `nextPresetCat`, `setTempo`.
- **Parameterized OSC commands:** `setParam` (`{ devIdx, param, value }`), `setPreset` (`{ devIdx, presetName }`), `setSynth` (`{ devIdx, synthName }`), `setChannel` (`{ devIdx, channel }`).
- **Disk / Process commands:** `getSongs`, `loadSong` (`value: relPath`), `editSong`, `openSynthApp` (`{ uiName }`), `getPresets`, `getPatchSets`, `selectPatchSet`, `createPatchSet`, `renamePatchSet`, `setDefaultPatchSet`, `deletePatchSet`.
