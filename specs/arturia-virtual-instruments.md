# Spec: Connecting Arturia Virtual Instruments to Cadenza

> Status: **Partially Implemented** (**Acid V** and **Augmented Mallets** integrated and verified; additional Arturia instruments can be added via `tools/sync-arturia-presets.js`)
> Target Platform: macOS (CoreMIDI / CoreAudio) + Cadenza ChucK Engine + Node.js GUI Bridge

---

## 1. Executive Summary & Architecture

Arturia virtual instruments (including **Acid V** and the rest of the installed V Collection / Analog Lab V suite) do not expose their own hardware-style CoreMIDI destination ports when idle, and they do not natively respond to MIDI Program Change messages unless a Playlist is populated in Arturia's preset database.

Connecting them cleanly to Cadenza requires a **hybrid control model** that keeps real-time musical performance in ChucK while delegating application lifecycle and preset synchronization to the Node.js layer:

```text
┌───────────────────────────────────────────────────────────────────────────┐
│ Browser Live Dashboard (http://localhost:3000)                            │
│  • Select Arturia synth ("Acid V", etc.) & MIDI channel (1..16)           │
│  • Browse/select presets from catalog.json (populated from db.db3)        │
│  • Optional "Open Synth UI" action to bring standalone window forward      │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │ WebSocket (JSON)
┌───────────────────────────────▼───────────────────────────────────────────┐
│ Node.js Bridge Server (gui/server.js + gui/server/osc-bridge.js)          │
│  • Serves Arturia preset catalog from presets/catalog.json                │
│  • Watches /cadenza/state & /cadenza/activateSynth over OSC (:9450)       │
│  • Auto-launches /Applications/Arturia/<App>.app when referenced          │
│  • Offline sync script (tools/sync-arturia-presets.js) syncs db.db3       │
└──────────────┬──────────────────────────────────┬─────────────────────────┘
               │ OSC (:9449 / :9450)              │ macOS `open -g -a ...`
┌──────────────▼──────────────────┐               │
│ ChucK Engine (framework/)       │               │
│  • AcidV extends Patch          │               │
│  • MidiOut → "IAC Driver Bus 1" │               │
│  • NoteOn/Off, Legato, CC, PC   │               │
└──────────────┬──────────────────┘               │
               │ CoreMIDI Virtual Loopback        │
               ▼                                  ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ macOS CoreMIDI IAC Driver ("IAC Driver Bus 1")                            │
│  → Standalone Arturia Apps (/Applications/Arturia/Acid V.app, etc.)       │
│  → Or Analog Lab V / AU/VST3 Plugin Host                                  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Why This Split?

1. **Real-Time MIDI Stays Direct (ChucK → IAC Driver → Arturia):** Note On/Off timing, legato note overlaps (303 slides), velocity accents, `LaunchControl` knob sweeps, and Bank/Program Changes stay inside ChucK's sample-accurate clock (`Patch` + `MidiOut`), avoiding Node.js event-loop or UDP jitter.
2. **Lifecycle & Preset Discovery Live in Node.js:** Node.js already owns process orchestration in Cadenza (`gui/server/osc-bridge.js` spawns `chuck`), filesystem/JSON management, and WebSocket communication with the browser. Extending it to activate Arturia standalone apps on demand and sync Arturia's SQLite database (`db.db3`) into `presets/catalog.json` fits Cadenza's existing architecture with zero external native ChucK extensions.

---

## 2. Local System Audit (Verified on This Mac)

Inspection of the local macOS environment confirms the following installed software, databases, and CoreMIDI state:

### 2.1 Installed Arturia Standalone Apps & Plugins

All instruments are installed in three formats:
- **Standalone Apps:** `/Applications/Arturia/*.app`
- **VST3 Plugins:** `/Library/Audio/Plug-Ins/VST3/*.vst3`
- **Audio Unit (AU) Components:** `/Library/Audio/Plug-Ins/Components/*.component`

Installed standalone applications under `/Applications/Arturia/` include:
- **Acid V.app** *(specifically requested)*
- **Analog Lab V.app** *(can also host presets from all V Collection engines internally)*
- **Synthesizers & Keyboards:** `ARP 2600 V3.app`, `B-3 V2.app`, `Buchla Easel V.app`, `CMI V.app`, `CP-70 V.app`, `CS-80 V4.app`, `CZ V.app`, `Clavinet V.app`, `DX7 V.app`, `Emulator II V.app`, `Farfisa V.app`, `Jun-6 V.app`, `Jup-8 V4.app`, `Jup-8000 V.app`, `KORG MS-20 V.app`, `Matrix-12 V2.app`, `Mellotron V.app`, `Mini V4.app`, `MiniBrute V.app`, `MiniFreak V.app`, `Modular V3.app`, `OP-Xa V.app`, `Piano V3.app`, `Prophet-5 V.app`, `Prophet-VS V.app`, `Pure LoFi.app`, `SEM V3.app`, `Solina V2.app`, `SQ80 V.app`, `Stage-73 V2.app`, `Synclavier V.app`, `Synthi V.app`
- **Augmented Series:** `Augmented BRASS.app`, `Augmented GRAND PIANO.app`, `Augmented MALLETS.app`, `Augmented STRINGS.app`

*(Note: `/Library/Arturia/Presets/db.db3` also indexes presets for additional engines such as `Pigments`, `Wurli V3`, `Vocoder`, `Augmented VOICES/WOODWINDS/YANGTZE/PERSIA`, `Memory V`, `Pure SUB`, and `Synthx`.)*

### 2.2 Arturia Preset Database (`/Library/Arturia/Presets/db.db3`)

Arturia stores all factory/user presets and MIDI Program Change playlists in a single SQLite 3 database at `/Library/Arturia/Presets/db.db3`.

Relevant tables:
- `Instruments` (`key_id`, `name`, `display_name`, `version`)
- `Preset_Id` (`key_id`, `name`, `type_v2`, `subtype_v2`, `instrument_key`, `pack`, `file_path`, ...)
- `Types_V2` (`key_id`, `name`) — primary preset category (e.g., `Bass`, `Sequence`, `Lead`, `Pad`)
- `Subtypes_V2` (`key_id`, `name`, `type_key`)
- `Playlists_V2` (`key_id`, `name`, `instrument_key`, `idx`, `last_change`)
- `Playlist_Songs` (`key_id`, `playlist_key`, `name`, `idx`)
- `Playlist_Presets` (`preset_key`, `playlist_key`, `song_key`, `idx`, `uuid`)

For **Acid V** (`Instruments.key_id = 87`, `name = 'Acid'`, `display_name = 'Acid'`):
- **156 total presets** currently installed across **6 `Types_V2` categories**:
  - `Sequence`: 97
  - `Bass`: 53
  - `Drums`: 3
  - `Pad`: 1
  - `Sound Effects`: 1
  - `Template`: 1
- `Playlists_V2`, `Playlist_Songs`, and `Playlist_Presets` are currently **empty** (`0` rows).

### 2.3 Current CoreMIDI Configuration

Querying macOS CoreMIDI destinations shows 6 active hardware destinations:
- `[0]` `U2MIDI Pro` (`V3`)
- `[1]` `S-1 MIDI IN` (`S-1`)
- `[2]` `SH-4d` (`SH-4d`)
- `[3]` `SH-4d CTRL`
- `[4]` `HYDRASYNTH EXPLORER` (`Hydrasynth`)
- `[5]` `Moog Messenger` (`Moog`)

In `/Users/scm/Library/Preferences/ByHost/com.apple.MIDI.*.plist`, Apple's virtual loopback driver (`com.apple.AppleMIDIIACDriver`, device `"IAC Driver"`, entity `"Bus 1"`) is present but currently set to `"offline" => 1`. Because it is offline, neither ChucK (`MidiOut.open(...)`) nor Arturia standalone apps can see a virtual MIDI loopback port yet.

---

## 3. MIDI & Audio Routing Topologies on macOS

### 3.1 Why a macOS IAC Driver Virtual MIDI Bus Is Required

Inspection of `/Applications/Arturia/Acid V.app/Contents/MacOS/Acid V` (`Arturia::Standalone::StandaloneVST3Application` / `HostIOManager`) shows that Arturia standalone apps do **not** publish their own virtual CoreMIDI destination endpoint; instead, they open existing system CoreMIDI input sources configured in **Audio MIDI Settings** (`standalone.pref`). Conversely, ChucK's `Patch.openDevice()` calls `gma.open(deviceName)` on a CoreMIDI destination endpoint.

Enabling Apple's built-in **IAC (Inter-Application Communication) Driver** bridges ChucK `MidiOut` directly to Arturia MIDI In:

1. Open `/System/Applications/Utilities/Audio MIDI Setup.app`.
2. Choose **Window → Show MIDI Studio** (`⌘2`).
3. Double-click **IAC Driver**.
4. Check **Device is online**.
5. Ensure at least one port exists (default port name: `Bus 1`, which exposes CoreMIDI endpoint `"IAC Driver Bus 1"`).
6. *(Optional)* Add extra buses in the IAC Driver Ports list (e.g., `Bus 1` or per-instrument buses like `Arturia Ch1`, `Acid V`, etc.) if you prefer isolating synths by port rather than by MIDI channel.

> **Important Note for Live Sessions:** ChucK snapshots CoreMIDI device lists when opening ports. Restarting the ChucK process (or reloading the song) is required after bringing the IAC Driver online for `MidiOut.open("IAC Driver Bus 1")` to resolve it.

### 3.2 Hosting Topologies Compared

| Topology | Description | Multi-Synth Support | Audio Mixing | Setup Complexity | Recommendation |
|---|---|---|---|---|---|
| **A. Standalone Apps + Shared IAC Bus** | Launch `Acid V.app` (and any other `.app` under `/Applications/Arturia/`) directly, listening on `"IAC Driver Bus 1"` | Multi-channel (`1..16`), one app per channel (or per IAC bus) | macOS CoreAudio automatically mixes all running apps + ChucK | **Low** (no DAW or host required) | **Recommended primary approach** |
| **B. `Analog Lab V.app` Multi Host** | Single `Analog Lab V.app` process hosting up to 2 instrument parts (`Slot1`, `Slot2`) | 2 parts per instance (`MidiChannel` per slot) | Built-in master FX, volume, pan | Low (only 2 concurrent parts) | Useful for 1–2 layered Arturia voices |
| **C. AU/VST3 Host (Hosting AU / Element / MainStage)** | Lightweight host loads `.component` / `.vst3` plugins on channels 1–16 of `"IAC Driver Bus 1"` | Up to 16+ simultaneous Arturia instruments in one process | Single mixer, AU FX chains, one saved session file | Medium (requires host project) | Best when running 4+ Arturia plugins at once |

### 3.3 The Omni-Channel Pitfall in Standalone Apps

By default, Arturia standalone apps ship with `MIDI Channel = All` (Omni) in the right-hand Side Panel (**Gear icon → Settings tab → Global Settings → Midi Channel**), and reset `GlobalInputMidiChannel` / `MIDI Channel` back to `All` when loading presets via `lastpresetc.pref`.

- If two standalone apps (e.g., `Acid V.app` and `Augmented MALLETS.app`) both listen to `"IAC Driver Bus 1"` while in Omni mode, both instruments will trigger on every MIDI note regardless of Cadenza's `midiChannel`.
- **Implemented Isolation Solution:** Provision a **dedicated CoreMIDI IAC Driver bus per Arturia instrument** (e.g., `"IAC Driver Acid V"`, `"IAC Driver Augmented Mallets"`) via `tools/sync-arturia-presets.js`, bind each app's `standalone.pref` **exclusively** to its dedicated IAC bus (removing `"IAC Driver Bus 1"` and direct hardware controllers), send `CC 120` All Sound Off + `CC 123` All Notes Off before replacing/pausing a `Patch`, and automatically stop unused standalone apps in `gui/server/osc-bridge.js` when no device slot references them.

---

## 4. Preset Selection: How Arturia Bank Select & Program Change Work

Disassembly and string inspection of `/Library/Arturia/Acid V/Acid V.vst3/Contents/MacOS/Acid V` (`Arturia::JuceArturiaLib::IPlaylistController` and `MidiConfigManager`) confirms the exact MIDI preset-selection protocol used across modern Arturia VC8/VC9/VC10 instruments:

### 4.1 Three-Level Hierarchy (Playlists → Songs → Presets)

Arturia maps standard MIDI Bank Select + Program Change to **Playlists** stored in `/Library/Arturia/Presets/db.db3`:

| MIDI Message | ChucK `Patch` Parameter | Arturia Target | SQLite Table & Column | Range |
|---|---|---|---|---|
| **CC 0** (Bank Select MSB) | `bankMsb` | Selects **Playlist** | `Playlists_V2.idx` (filtered by `instrument_key`) | `0..127` |
| **CC 32** (Bank Select LSB) | `bankLsb` | Selects **Song** inside Playlist | `Playlist_Songs.idx` | `0..127` |
| **Program Change** (`0xC0 \| ch`) | `prog` | Selects **Preset** inside Song | `Playlist_Presets.idx` | `0..127` |

*(Confirmed from binary diagnostic strings: `"Midi message catch to select a playlist "`, `"Midi message catch to select a song "`, `"Program Change message catch to select a preset chan "`.)*

### 4.2 Why Program Change Does Nothing Out of the Box

On a clean installation, `Playlists_V2` has **0 rows** for `Acid V` (and all other instruments). Sending `CC 0` / `CC 32` / `Program Change` without an existing Playlist in `db.db3` fails silently because there is no playlist index `0` or song index `0` to resolve.

### 4.3 Automated Sync via `tools/sync-arturia-presets.js`

Instead of manually dragging 156+ presets into playlists inside every Arturia GUI, Cadenza should provide a deterministic sync tool: `tools/sync-arturia-presets.js` (using macOS's built-in `sqlite3` CLI or a Node SQLite helper, invoked **while Arturia apps are closed** or before launching them so SQLite WAL/locks don't conflict).

#### Sync Algorithm for Each Enabled Arturia Instrument (starting with `Acid V`)

1. **Query Installed Presets from `/Library/Arturia/Presets/db.db3`:**
   ```sql
   SELECT p.key_id, p.name, COALESCE(t.name, 'Uncategorized') AS category
   FROM Preset_Id p
   JOIN Instruments i ON p.instrument_key = i.key_id
   LEFT JOIN Types_V2 t ON p.type_v2 = t.key_id
   WHERE i.name = 'Acid'
     AND p.hide_in_browser = 0
   ORDER BY category ASC, p.name ASC;
   ```
2. **Provision the `"Cadenza"` Playlist in `db.db3`:**
   - Ensure a playlist named `"Cadenza"` exists in `Playlists_V2` for `instrument_key = 87` at `idx = 0` (shifting any existing user playlists to `idx >= 1` if they occupied `idx = 0`, or keeping `Cadenza` at `idx = 0` so `CC 0 = 0` always selects it).
   - Clear and repopulate `Playlist_Songs` and `Playlist_Presets` for the `"Cadenza"` playlist, packing presets into **Songs** (each Song = 1 Bank LSB `0..127`, max 128 presets per Song):
     - **Song `idx = 0`** (`CC 32 = 0`, `"Bass"`): 53 presets (`program = 0..52`)
     - **Song `idx = 1`** (`CC 32 = 1`, `"Sequence"`): 97 presets (`program = 0..96`)
     - **Song `idx = 2`** (`CC 32 = 2`, `"Other"` — `Drums`, `Pad`, `Sound Effects`, `Template`): 6 presets (`program = 0..5`)
   - *(For larger Arturia synths like `MiniFreak V` [626 presets] or `Pigments` [1,176 presets], any category exceeding 128 presets is chunked into `Category 1`, `Category 2`, etc., so every `(bankLsb, program)` pair stays within `0..127`.)*
3. **Update `presets/catalog.json`:**
   - Write `"Acid V"` into `catalog.presets["Acid V"]` with the exact `{ program, bank, name, category }` entries matching the `"Cadenza"` playlist indices in `db.db3`.
   - Note: `category` in `catalog.json` keeps the true musical category (`"Bass"`, `"Sequence"`, `"Drums"`, `"Pad"`, `"Sound Effects"`, `"Template"`) for GUI browsing/filtering, while `bank` (`0`, `1`, `2`) holds the `Playlist_Songs.idx` sent as `CC 32`.
4. **Regenerate Static Artifacts:**
   - Run `node tools/gen-presets.js` to regenerate `framework/devices/presets/generated/*.ck` and `gui/js/catalog-data.js`.

Result: Calling `sendProgramChange(0, bank, program)` from ChucK (`CC 0 = 0`, `CC 32 = bank`, `PC = program`) selects the exact matching preset inside `Acid V` with 1:1 fidelity to Cadenza's Live Dashboard.

---

## 5. `Acid V` MIDI Mapping & 303 Performance Semantics

Inspection of `/Library/Arturia/Acid V/resources/plugin.prefmidi.xml` (`<midiconfig name="Default">`) and `/Library/Arturia/Acid V/resources/Reference_ParamNames.xml` reveals the exact factory CC mapping and a critical volume CC mismatch:

### 5.1 Default MIDI CC Table (`Acid V`)

| MIDI CC | `Acid V` `paramid` | Internal Parameter Name | Display Name | Cadenza Compatibility |
|---:|---:|---|---|---|
| **74** | `4` | `FilterEnv303_Cutoff` | Cutoff | Matches `CadenzaConstants.CC_CUTOFF()` (`74`) |
| **71** | `5` | `Filter303_Resonance` | Resonance | Matches `CadenzaConstants.CC_RESONANCE()` (`71`) |
| **85** | `0` | `MasterVolume` | Master Volume (`-70..0 dB`) | **Mismatch:** Cadenza uses CC `7` (`CC_VOLUME()`) |
| **16** | `7` | `FilterEnv303_Decay` | Decay | Available for AcidV-specific helper |
| **17** | `8` | `VCAEnv303_AccentAmt` | Accent | Available for AcidV-specific helper |
| **18** | `308` | *(Macro / Sub)* | *(Mapped Macro)* | Available |
| **19** | `6` | `FilterEnv303_EnvMod` | Envelope Mod | Available for AcidV-specific helper |
| **72** | `13` | `Sequencer_Vibrato_RateUnSynced` | Vibrato Speed | Available |
| **73** | `9` | `Osc303_SubOsc_Octave` | Sub Osc Octave | Available |
| **75** | `10` | `Osc303_SubOsc_Waveform` | Sub Osc Waveform | Available |
| **76** | `47` | `Function1_RateUnSynced` | Function1 Rate | Available |
| **77** | `46` | `Function1_RateType` | Function1 Rate Type | Available |
| **79** | `11` | `Osc303_SubOsc_Volume` | Sub Osc Volume | Available |
| **80** | `12` | `Sequencer_Vibrato_Amp` | Vibrato Amount | Available |
| **81** | `14` | `Distortion_Disto_Drive` | Distortion Drive | Available |
| **82** | `16` | `Distortion_DryWet` | Distortion Dry/Wet | Available |
| **83** | `21` | `Sequencer_ForceSlide` | Slide | Available |
| **93** | `175` | `FX1_Dry_Wet` | FX1 Dry/Wet | Available |

*(Note: Arturia CC 120–127 are reserved internally for VST3 Program Changes and standard channel-mode messages such as CC 123 All Notes Off.)*

### 5.2 Handling `MasterVolume` (CC 7 vs. CC 85)

In Cadenza today:
- `Patch.updateControllers()` sends `CadenzaConstants.CC_VOLUME()` (`7`).
- `OscControl.dispatch()` (`"volume"`) and `LaunchControl.handleControlChange()` update `p.volume` and call `p.sendControllerChange(CadenzaConstants.CC_VOLUME(), val)` directly rather than calling a virtual `setVolume(int)` method on `Patch`.

**Recommended Solution (Zero manual Arturia MIDI config needed):**
1. Add `fun void setVolume(int val)` to `Patch` (`val => volume; if (volume != -1) sendControllerChange(CadenzaConstants.CC_VOLUME(), volume);`), and update `OscControl.dispatch`, `LaunchControl.handleControlChange`, and `Patch.updateControllers` to call `p.setVolume(val)`.
2. Override `setVolume(int val)` in `AcidV` to send **CC `85`** (and optionally CC `7` for compatibility with custom user MIDI maps).
3. Also override `setPan(int val)` in `AcidV` to store `pan` in state without sending CC `10` (or route CC `10` only if mapped), since Acid V is a monophonic 303 synth with no default CC `10` pan binding.

*(Note: This pattern also applies to other Arturia V Collection instruments such as `Mini V4`, whose `plugin.prefmidi.xml` similarly maps `Master Volume` to CC `85` or `16..19` rather than CC `7`.)*

### 5.3 TB-303 Playing Semantics in Cadenza

- **Legato / Slide:** Overlapping MIDI Note On before the previous Note Off automatically triggers Acid V's TB-303 slide/glide. In Cadenza `Part`s (`Melody`, `ChordProgression`), set `1 => part.legato;` (or overlap note durations) to produce acid slides, or toggle `CC 83` (`Sequencer_ForceSlide`).
- **Accent:** High-velocity MIDI notes (typically `velocity >= 100` in `part.velocities`) trigger Acid V's 303 accent circuit (louder VCA + sharper filter envelope punch).
- **`Bass` vs. `Sequence` Presets:**
  - **`Bass` presets** keep Acid V's internal sequencer disabled, letting Cadenza's generative `Melody`, `LSystemNotes`, or `Part` rhythms play every note directly.
  - **`Sequence` presets** enable Acid V's internal 64-step pattern sequencer (`Sequencer_OnOff`), so incoming MIDI notes trigger and transpose the internal pattern. To audition `Sequence` presets purely as synth tones under Cadenza's own sequencer, turn off Acid V's sequencer in the UI and click the **Lock Sequencer** icon (`Sequencer_Lock`) so subsequent preset changes preserve the sequencer-off state.

---

## 6. Cadenza Implementation Specification

This section specifies the exact changes across `presets/`, `tools/`, `framework/`, `gui/server/`, and `gui/js/` when implementing Arturia support.

### 6.1 `presets/catalog.json` Schema Extension

Extend `synths` entries with an optional `appName` field (for standalone macOS process activation) and add `"Acid V"`:

```jsonc
{
  "synths": {
    "V3": { "class": "V3GrandPiano", "deviceName": "U2MIDI Pro", "fixedChannel": null, "maxChannels": 16, "defaultPreset": "Grand Piano Vienna" },
    "Hydrasynth": { "class": "Hydrasynth", "deviceName": "HYDRASYNTH EXPLORER", "fixedChannel": 0, "maxChannels": 1, "defaultPreset": "A001" },
    "SH-4d": { "class": "RolandSH4d", "deviceName": "SH-4d", "fixedChannel": null, "maxChannels": 4, "defaultPreset": null },
    "S-1": { "class": "RolandS1", "deviceName": "S-1 MIDI IN", "fixedChannel": 2, "maxChannels": 1, "defaultPreset": "Bank: 1 Program: 1" },
    "Moog": { "class": "MoogMessenger", "deviceName": "Moog Messenger", "fixedChannel": 0, "maxChannels": 1, "defaultPreset": "Messenger: 1" },
    "RD-6": { "class": "BehringerRD6", "deviceName": "RHYTHM DESIGNER RD-6", "fixedChannel": null, "maxChannels": 1, "defaultPreset": "RHYTHM DESIGNER RD-6" },
    "Acid V": {
      "class": "AcidV",
      "deviceName": "IAC Driver Bus 1",
      "appName": "Acid V",
      "fixedChannel": null,
      "maxChannels": 16,
      "defaultPreset": "Fast Travel"
    }
  },
  "presets": {
    "Acid V": [
      { "program": 0, "bank": 0, "name": "A Legend Is Reborn", "category": "Bass" }
      // ... populated by tools/sync-arturia-presets.js
    ]
  }
}
```

### 6.2 `tools/gen-presets.js` & `gui/server/preset-catalog.js`

1. **`tools/gen-presets.js`:**
   - Add `genArturiaPresetFile(uiName, classPrefix, entries)` (or generalize a shared generator helper) to emit `framework/devices/presets/generated/acid-v-presets.ck` containing `AcidVPresetsData` (`Preset[]` using `new AcidVPreset(program, bank, name, category)`) and `AcidVPresetCollection extends PresetCollection` (`1 => preferCurrentCategory; 0 => matchCode;`).
   - Add `APP_NAMES[]` alongside `UI_NAMES[]`, `FIXED_CHANNELS[]`, `MAX_CHANNELS[]`, and `DEFAULT_PRESETS[]` in `SynthTableData` (`generated/synth-table.ck`) if ChucK needs to emit app-activation metadata, or let Node resolve `appName` directly from `presets/catalog.json`.
   - Include `"Acid V": catalog.presets["Acid V"]` (and dynamically forward all keys in `catalog.presets`) in `genGuiCatalogModule()`.
2. **`gui/server/preset-catalog.js`:**
   - Forward all `catalog.presets` keys dynamically (`Object.assign({}, catalog.presets, { Moog: moog })`) instead of hardcoding only `V3`, `Hydrasynth`, `SH-4d`, and `Moog`.

### 6.3 ChucK Device Class (`framework/devices/acid-v.ck`)

Reference design following all `AGENTS.md` §2 ChucK conventions (fields before `Patch(v)` last, explicit `@=>`, 0-based `midiChannel`):

```chuck
// AcidV
// Purpose: Arturia Acid V virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/acid-v-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/acid-v-presets.ck"

public class AcidV extends Patch
{
    fun void initDefaults()
    {
        "IAC Driver Bus 1" => deviceName;
        "Acid V" => uiName;
        0 => midiChannel;
        0 => bank;
        0 => program;
        "Fast Travel" => patchName;
    }

    fun AcidV()
    {
        initDefaults();
    }

    fun AcidV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        Patch(v); // Must be called last
    }

    fun AcidV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        Patch(v); // Must be called last
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AcidVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    fun void resolvePreset(string name)
    {
        if (name == "" || name == "default") {
            "Fast Travel" => name;
        }
        presets() @=> PresetCollection @ col;
        col.getPreset(name) @=> Preset @ preset;
        if (preset != null) {
            preset.program => program;
            preset.bank => bank;
            preset.name => patchName;
        } else {
            0 => program;
            0 => bank;
            name => patchName;
        }
    }

    fun void setPreset()
    {
        if (bank >= 0 && program >= 0) {
            // CC 0 = 0 (Cadenza Playlist), CC 32 = bank (Category Song), PC = program
            sendProgramChange(0, bank, program);
        }
    }

    fun void setVolume(int val)
    {
        val => volume;
        if (volume != -1) {
            // Acid V Default MIDI Config maps CC 85 to MasterVolume
            sendControllerChange(CadenzaConstants.CC_ARTURIA_VOLUME(), volume);
        }
    }

    fun void setPan(int val)
    {
        // Monophonic 303: keep pan in state without emitting unmapped CC 10
        val => pan;
    }

    // Acid V 303-specific CC helpers (Default MIDI Config)
    fun void setEnvMod(int val)         { sendControllerChange(19, val); }
    fun void setDecay(int val)          { sendControllerChange(16, val); }
    fun void setAccent(int val)         { sendControllerChange(17, val); }
    fun void setDistortionDrive(int val){ sendControllerChange(81, val); }
    fun void setDistortionMix(int val)  { sendControllerChange(82, val); }
    fun void setForceSlide(int on)      { sendControllerChange(83, on ? 127 : 0); }

    fun string declaration()
    {
        return "AcidV acid(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\", " + Std.itoa(volume) + ");";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
        if (preset == null) return;
        sendProgramChange(0, preset.bank, preset.program);
        if (vol != -1) {
            setVolume(vol);
        }
        preset.name => patchName;
        preset.program => program;
        preset.bank => bank;
        <<< declaration(), "" >>>;
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "IAC Driver Bus 1" => deviceName;
        "Acid V" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        if (patchName != "") {
            resolvePreset(patchName);
        }
        updateControllers();
    }
}
```

### 6.4 Constants, `Preset`, `SynthRegistry`, and `cadenza.ck`

1. **`framework/core/constants.ck`:**
   - Add `fun static int CC_ARTURIA_VOLUME() { return 85; }`.
2. **`framework/devices/presets/preset.ck`:**
   - Add `public class AcidVPreset extends Preset` (or generic `ArturiaPreset extends Preset`).
3. **`framework/devices/synth-registry.ck`:**
   - `@import "acid-v.ck"`
   - Add `else if (synthUiName == "Acid V")` branches in `createEmpty()` and `createDefault()`.
4. **`framework/cadenza.ck`:**
   - Add `@import "devices/presets/generated/acid-v-presets.ck"` and `@import "devices/acid-v.ck"` before `synth-registry.ck`.

### 6.5 Node.js Bridge Activation & OSC Messaging (`gui/server/osc-bridge.js`)

To support the user's idea of **activating virtual synths from Cadenza via messaging**, the Node.js bridge server handles process lifecycle cleanly without blocking ChucK's audio thread:

#### Activation Triggers

1. **Automatic Activation on `/cadenza/state`:**
   - Whenever ChucK broadcasts `/cadenza/state` (`StateBroadcaster`), `osc-bridge.js` inspects `state.devices[]`.
   - For each device whose `uiName` resolves in `catalog.synths[uiName].appName` (e.g., `"Acid V"`):
     - Call `ensureSynthAppRunning(appName)` (debounced with a per-app cooldown, e.g., 10 seconds, so rapid state broadcasts never spawn duplicate `open` calls).
2. **Explicit OSC Trigger (`ChucK → Node :9450`):**
   - Add `GuiLink.sendActivateSynth(string uiName)` emitting `/cadenza/activateSynth` (`s` = `uiName`) when `Song.setDeviceSynth` swaps a slot to a software instrument or on `Song` startup before initial `updateControllers()` sends Program Change.
3. **Manual Window Focus from GUI (`Browser → Node`):**
   - Add WebSocket command `{ type: 'focusSynthApp', value: { uiName } }` (e.g., clicking a small launch/focus icon next to software synths in the device table) running `open -a "/Applications/Arturia/<appName>.app"` without `-g` so the synth window comes to the foreground for sound editing.

#### Server Activation Helper (`gui/server/synth-launcher.js`)

```javascript
// Conceptual flow for gui/server/synth-launcher.js
const { execFile } = require('child_process');
const path = require('path');

const LAUNCH_COOLDOWN_MS = 10000;
const lastLaunchAttempt = new Map();

function ensureSynthAppRunning(appName, { foreground = false } = {}) {
  if (!appName) return;
  const appPath = path.join('/Applications/Arturia', `${appName}.app`);
  const now = Date.now();
  if (!foreground && now - (lastLaunchAttempt.get(appName) || 0) < LAUNCH_COOLDOWN_MS) {
    return;
  }
  lastLaunchAttempt.set(appName, now);

  execFile('pgrep', ['-x', appName], (err) => {
    if (!err && !foreground) return; // Already running
    const args = foreground ? ['-a', appPath] : ['-g', '-a', appPath];
    execFile('open', args, (openErr) => {
      if (openErr) {
        console.error(`Failed to launch ${appPath}:`, openErr.message);
      } else {
        console.log(`→ OS: launched ${appName} (${foreground ? 'foreground' : 'background'})`);
      }
    });
  });
}
```

#### Startup Timing Caveat

When `Acid V.app` cold-starts (~2–4 seconds), ChucK's initial `Patch(v)` constructor may have already transmitted `sendProgramChange` and initial CCs before `Acid V.app` opens `"IAC Driver Bus 1"`. To make cold launches reliable:
- **Wait & Re-sync:** When `ensureSynthAppRunning` launches a previously stopped app, the Node server sets a short timer (or polls until `pgrep` + readiness) and then sends `/cadenza/setPreset` (`devIdx`, `patchName`) + `/cadenza/volume` back to ChucK on `:9449`, re-applying the initial preset and controller values once the app is listening.
- Update `docs/osc-protocol.md` to document `/cadenza/activateSynth` and `focusSynthApp`.

### 6.6 GUI Dashboard (`gui/js/devices-table.js`)

Replace the hardcoded synth checks in `gui/js/devices-table.js` so any Arturia synth added to `presets/catalog.json` automatically gets preset modals and default patch selection:

- **Line 118 (`hasPresets`):**
  ```javascript
  const hasPresets = Boolean(
    state.presetCatalog &&
    Array.isArray(state.presetCatalog[dev.uiName]) &&
    state.presetCatalog[dev.uiName].length > 0
  );
  ```
- **Lines 252–274 (`onSynthChange`):**
  Read `meta = state.presetCatalog?.synthMeta?.[synthName]` and `presets = state.presetCatalog?.[synthName]` to look up `meta.defaultPreset` (and its `bank`/`program`) dynamically rather than an `if/else` chain per synth.

---

## 7. Scaling Beyond `Acid V` to Other Installed Arturia Instruments

Because `/Library/Arturia/Presets/db.db3`, `plugin.prefmidi.xml`, and the Playlist Bank/Program Change engine are shared across Arturia's V Collection framework, adding more installed instruments (e.g., `Mini V4`, `Jup-8 V4`, `CS-80 V4`, `DX7 V`, `Prophet-5 V`, `Jun-6 V`, `Pigments`, `Analog Lab V`) follows a uniform pattern:

1. **Shared Generic `ArturiaPatch` Base Class (Optional Phase 2):**
   - Instead of duplicating `AcidV` for 30 instruments, extract a shared `ArturiaSynth extends Patch` base class (or configure `ArturiaSynth` with `uiName`, `deviceName`, `appName`, and its `PresetCollection`), or generate thin subclasses alongside `presets/generated/*.ck`.
2. **Channel Allocation (`1..16`):**
   - Up to 16 Arturia standalone instances (or 16 AU/VST3 channels in a host) can share `"IAC Driver Bus 1"` on channels `1..16` (`maxChannels: 16`, `fixedChannel: null` in `catalog.json`), provided each standalone app's **Settings → MIDI Channel** is set to its assigned channel (or each synth uses its own IAC bus).
3. **Sync Any Subset of Instruments:**
   - Configure `tools/sync-arturia-presets.js` with an allowlist of Arturia instruments to expose in Cadenza (keeping `catalog.json` and the GUI dropdown focused on the synths you actively compose with).

#### Implemented Phase 1 Instruments (`Acid V` & `Augmented Mallets`)

- **`Acid V`** (`framework/devices/acid-v.ck`, `class AcidV`, `uiName = "Acid V"`, CoreMIDI port `"IAC Driver Acid V"`, `fixedChannel = 0` / MIDI Channel 1, `defaultPreset = "Fast Travel"`, Master Volume CC `85` via `CadenzaConstants.CC_ACID_V_VOLUME()`, 156 presets across 6 banks in `db.db3`).
- **`Augmented Mallets`** (`framework/devices/augmented-mallets.ck`, `class AugmentedMallets`, `uiName = "Augmented Mallets"`, CoreMIDI port `"IAC Driver Augmented Mallets"`, `fixedChannel = 1` / MIDI Channel 2, `defaultPreset = "A Royal Mallet"`, Master Volume CC `17` via `CadenzaConstants.CC_AUG_MALLETS_VOLUME()`, 201 presets across 7 banks in `db.db3`, with `Keys` chunked into `Keys (1)` and `Keys (2)` to stay within 128 programs per bank).
- **`Patch.sendAllNotesOff()` & `CadenzaConstants.CC_ALL_SOUND_OFF()`:** Sends MIDI CC `120` (All Sound Off / Arturia Panic) before CC `123` (All Notes Off) so sustaining voices and internal sequencers cut cleanly when switching synths or pausing.
- **`tools/sync-arturia-presets.js`:** Brings `IAC Driver` online, creates dedicated CoreMIDI IAC buses (`"IAC Driver Acid V"`, `"IAC Driver Augmented Mallets"`), populates `"Cadenza"` playlists in `/Library/Arturia/Presets/db.db3`, binds each app's `standalone.pref` exclusively to its dedicated IAC bus, updates `presets/catalog.json`, and invokes `tools/gen-presets.js`.
- **Node.js Bridge (`gui/server/osc-bridge.js`):** Handles `/cadenza/activateSynth`, re-sanitizes `standalone.pref` before cold-launching `Acid V.app` / `Augmented MALLETS.app`, re-syncs preset & volume after cold launch, stops unused Arturia standalone apps via `syncVirtualSynths()` when switched away on `/cadenza/state` or `setSynth`, and handles `openSynthApp`.

---

## 8. User Setup Checklist (One-Time Manual Steps)

Once the Cadenza changes in §6 are implemented, the user setup is four quick steps:

1. **Bring IAC Driver Online (One Time):**
   - Open **Audio MIDI Setup.app** → **Window → Show MIDI Studio** → double-click **IAC Driver** → check **Device is online** → verify **Bus 1** is listed under Ports → **Apply**.
2. **Generate Playlists & Sync Catalog (With Arturia Apps Closed):**
   - Run `node tools/sync-arturia-presets.js` to populate the `"Cadenza"` playlist in `/Library/Arturia/Presets/db.db3` and update `presets/catalog.json` + generated ChucK/GUI files.
3. **Configure MIDI Input & Channel in `Acid V.app` (One Time per Standalone App):**
   - Launch `/Applications/Arturia/Acid V.app`.
   - Open **Audio & MIDI Settings** (top-left hamburger menu) → under **MIDI Input**, check **IAC Driver Bus 1**.
   - Open the right-hand **Settings (gear) → Settings tab → Midi Channel** → set it to the MIDI channel you will use in Cadenza (e.g., `1`, or a dedicated channel `1..16` if running multiple Arturia apps on `Bus 1`).
4. **Play from Cadenza:**
   - Instantiate `AcidV acid(1, "Fast Travel", 100);` in a `music/*.ck` script, or switch any track in the Live Dashboard (`http://localhost:3000`) to **Acid V** — the Node.js server ensures `Acid V.app` is running and ChucK streams notes, CCs, and preset changes over `"IAC Driver Bus 1"`.
