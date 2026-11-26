# Cadenza

Cadenza is a modular framework for real-time algorithmic music generation and MIDI control written in **ChucK**, paired with a web-based **Live Dashboard** (`gui/`) bridged over OSC and WebSockets, and backed by a single-source synth preset catalog (`presets/catalog.json`). It is designed for composers, performers, and researchers working with generative music, live coding, hardware synthesizers, and virtual instruments.

<img width="3840" height="2160" alt="Screenshot 2026-08-09 at 7 01 00 PM" src="https://github.com/user-attachments/assets/2f1411c5-18f5-48a1-94b1-78927f249f79" />

## Core Framework

Cadenza's ChucK runtime is organized into acyclic layers imported through a single umbrella entry point (`framework/cadenza.ck`):

- **Songs & Fragments**: Structure performances into named **Fragments** (sections) connected by weighted probabilistic transitions (`FragmentTransition`), with support for deterministic ("golden") playback, queuing the next fragment, and looping any fragment on the fly.
- **Parts & Algorithmic Composition**: Build arrangements from modular `Part` subclasses including `Chord` / `ChordProgression`, `Melody` (`AleatoricMelody`, `SequentialMelody`), `DrumMachine`, scale/chord `NoteCollection`s, probabilistic rhythms with mutation, and L-system note generation (`LSystemNotes`).
- **51 Hardware & Virtual Synthesizers**:
  - **Hardware**: ASM Hydrasynth Explorer, Moog Messenger (with 16 named bank categories), Roland S-1, Roland SH-4d, Behringer RD-6, and V3 Grand Piano.
  - **Virtual Instruments (macOS)**: 45 Arturia V Collection and Augmented standalone instruments via dedicated CoreMIDI IAC buses (`ArturiaSynth`), with automatic background app lifecycle management, per-synth MIDI CC volume mapping, and preset playlist syncing.
- **Controller & MIDI Integration**: Novation LaunchControl XL mapping (`LaunchControl`), MIDI Thru routing (`MidiMapper`), and terminal/markdown status output (`TerminalDisplay` → `dashboard.md`).
- **Per-Song Patch Sets**: Save and switch named YAML patch sets (`music/<song>.patch-sets/*.yaml` + `.default`) using Cadenza's built-in ChucK YAML parser/writer (`YamlParser`).

## Live Dashboard (GUI)

The Live Dashboard (`http://localhost:3000`) connects to ChucK through a Node.js OSC↔WebSocket bridge (`:9449` GUI → ChucK, `:9450` ChucK → GUI) with zero frontend build step:

- **Devices Table**: Live synth and MIDI channel switching (with automatic channel assignment), a searchable category-based **Preset Picker**, volume sliders, rotary cutoff/resonance/pan knobs, inline numeric editing, per-device mute/solo toggles, and real-time note-activity indicators.
- **Interactive Fragment Graph**: Docked, resizable Cytoscape.js view of the song's transition graph highlighting the active, queued, and looping fragments plus the last transition taken. Single-click a node to queue it next, double-click to loop it, or **hover over a node for 1 second** to inspect the devices (device number, synth, and patch) used in that fragment — clicking a device in the popover solos that device and loops the fragment for quick patch auditioning.
- **Song Scroll**: Real-time scrolling piano roll displaying active notes color-coded by device, with automatic drum-lane labeling.
- **Patch Sets & Unsaved Changes Diff**: Create, switch, rename, delete, and set default patch sets per song, with an unsaved-changes indicator and a **Diff** modal showing modified tempo and device parameters against the saved YAML.
- **Transport & Shortcuts**: Global tempo (BPM), Play/Pause, Reset, Golden mode (`g`), All-devices mode (`a`), Fragment Graph toggle (`f`), Save (`w`), Open Song picker (`o`), and Edit Song (`e`).

## Installation & Setup

1. **Install Prerequisites**:
   - [ChucK](https://chuck.cs.princeton.edu/)
   - [Node.js](https://nodejs.org/)
2. **Clone the Repository**:
   ```bash
   git clone https://github.com/scmm17/Cadenza.git
   cd Cadenza
   ```
3. **Start the GUI Bridge Server**:
   ```bash
   cd gui
   npm install
   npm start
   ```
4. **Open the Dashboard**: Navigate to `http://localhost:3000` in your browser.
5. **Load & Play a Song**: Press `o` (or click the folder button in the toolbar) to pick any song from `music/`. The bridge spawns and manages the ChucK process automatically. (To run a song directly from the terminal on macOS, use `./ck music/<song>.ck`.)

### Preset Catalog & Arturia Sync

`presets/catalog.json` is the single source of truth for synth metadata, Moog bank names, and preset lists:

- Regenerate ChucK preset tables (`framework/devices/presets/generated/*.ck`) and GUI catalog data (`gui/js/catalog-data.js`) after editing `presets/catalog.json`:
  ```bash
  node tools/gen-presets.js
  ```
- Sync installed Arturia standalone presets, playlists, and CoreMIDI IAC buses on macOS:
  ```bash
  node tools/sync-arturia-presets.js
  ```

## Project Structure

- `framework/`: Modular ChucK libraries imported via `framework/cadenza.ck`:
  - `core/`: Constants, shared OSC `GuiLink`, and in-ChucK `YamlParser`.
  - `devices/`: `Patch` base class, hardware/Arturia synth implementations, `SynthRegistry`, and generated preset tables.
  - `composition/`: `SongContext`, `Part`, `Fragment`, `NoteCollection`, `LSystemNotes`, `Chord`, `ChordProgression`, `Melody`, `DrumMachine`.
  - `control/`: `OscControl`, `StateBroadcaster`, `LaunchControl`, `KeyboardControl`, `MidiMapper`, `TerminalDisplay`.
  - `song/`: `Song`, `Mixer`, and `PatchSetStore`.
- `music/`: Runnable song scripts (`*.ck`), L-system grammars, and per-song `.patch-sets/` YAML directories.
- `gui/`: Node.js OSC↔WebSocket bridge (`server.js`, `server/*.js`) and vanilla HTML/CSS/ES-module Live Dashboard (`index.html`, `css/dashboard.css`, `js/*.js`).
- `presets/` & `tools/`: `presets/catalog.json`, `tools/gen-presets.js`, and `tools/sync-arturia-presets.js`.
- `test/` & `scripts/`: Headless ChucK unit tests (`test/run-all.ck`, `test/test-yaml.ck`) and unified check script (`scripts/check.sh`).
- `docs/`: Contributor and architecture documentation.

## Testing & Verification

Run the full verification suite from the repository root:

```bash
./scripts/check.sh
```

This runs:
1. ChucK unit tests (`chuck -s test/run-all.ck`)
2. Standalone YAML parser/writer tests (`cd test && chuck -s test-yaml.ck`)
3. ChucK syntax checks across all `music/*.ck` scripts
4. Node/JS syntax checks across `gui/server.js`, `gui/server/*.js`, and `gui/js/*.js`
5. Generated-preset freshness check (`node tools/gen-presets.js --check`)

**Note**: When running ChucK tests directly, the `-s` (silent/non-realtime) flag is required so tests run headlessly without initializing audio hardware.

## Documentation

- [Documentation Index](docs/README.md)
- [Creating Music](docs/creating-music.md) — Guide to writing songs, parts, rhythms, and fragment graphs
- [The Framework](docs/framework.md) — Internal architecture, class reference, and extending Cadenza
- [OSC & WebSocket Protocol](docs/osc-protocol.md) — Wire-protocol reference for ChucK, the Node.js bridge, and the browser UI
- [Architecture Refactoring Overview](docs/refactoring.md) — Module layout and verification workflow

## License

MIT
