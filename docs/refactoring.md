# Architecture Refactoring Overview

This note summarizes the restructuring of Cadenza's ChucK framework and Live Dashboard. For detailed API references, see [The Framework](framework.md) and the [OSC & WebSocket Protocol](osc-protocol.md); for the original migration breakdown, see [refactoring-plan.md](../specs/refactoring-plan.md).

## Why We Refactored

Previously, almost all framework and dashboard code lived in four monolithic files:

| File | Before | After |
|---|---:|---:|
| `Patch` & synths | 3,782 lines (`framework/patch.ck`) | 332 lines (`framework/devices/patch.ck`) + per-synth files |
| `Song` & engine | 2,759 lines (`framework/song.ck`) | 583 lines (`framework/song/song.ck`) + focused modules |
| Dashboard UI | 3,147 lines (`gui/index.html`) | 200 lines (`gui/index.html`) + CSS/ES modules |
| Node bridge | 700 lines (`gui/server.js`) | 80 lines (`gui/server.js`) + `gui/server/*` |

Beyond file size, preset tables were duplicated across ChucK, a generated `gui/presets.js` file, and regex scraping in `gui/server.js`; `uiName == "..."` checks were scattered across ~12 places; and `Song` and `LaunchControl` mixed transport, persistence, hardware MIDI, terminal printing, and OSC state broadcasting.

---

## Key Changes

### 1. Single Import Entry Point (`framework/cadenza.ck`)
Every song in `music/` and test in `test/` now imports a single file:

```chuck
@import "../framework/cadenza.ck"
```

Internally, `framework/` is split into five acyclic layers (`core/`, `devices/`, `composition/`, `control/`, `song/`).

### 2. Acyclic Layering via `SongContext` & `SongState`
ChucK's `@import` forbids circular dependencies, which previously kept `Song`, `Part`, `Fragment`, and `LaunchControl` trapped in one file. To break the cycles:
- `framework/composition/song-context.ck` defines `SongContext` with shared timing/device state and virtual hook methods.
- `framework/composition/fragment.ck` defines `SongState extends SongContext` alongside `Fragment`.
- `Song extends SongState` in `framework/song/song.ck` provides the concrete overrides.

*(Note: in ChucK, method overrides must match the base parameter type `SongContext` / `SongState`, and `static` fields on `SongContext` must be qualified with `SongContext.<field>`.)*

### 3. Polymorphic `Patch` Hooks & `SynthRegistry`
- `framework/devices/patch.ck` defines base hooks (`presets()`, `syncPresetCursor()`, `applyPresetObject()`, `stepPreset()`, `stepPresetCategory()`, `selectPresetByName()`, `stateBank()`, `stateProgram()`).
- Each hardware synth lives in its own file under `framework/devices/` (`hydrasynth.ck`, `moog-messenger.ck`, `roland-s1.ck`, `roland-sh4d.ck`, `behringer-rd6.ck`, `v3-grand-piano.ck`), eliminating per-synth `if/else` chains in `Song`.
- `framework/devices/synth-registry.ck` (`SynthRegistry`) centralizes synth instantiation and channel auto-assignment rules.
- `Preset` and `PresetCollection` (`framework/devices/presets/`) replace three nearly identical per-synth collection classes.

### 4. Single JSON Source for Presets & Synth Metadata
- `presets/catalog.json` is the single source of truth for all V3, Hydrasynth, and SH-4d presets, the 16 Moog bank names, and synth channel metadata.
- `gui/server/preset-catalog.js` reads `presets/catalog.json` directly (no more regex-scraping ChucK source).
- `node tools/gen-presets.js` generates the ChucK data tables in `framework/devices/presets/generated/` and the browser's `gui/js/catalog-data.js` module.

### 5. Decomposed `Song`, `LaunchControl`, and Shared `GuiLink`
- **Transport & State:** `Song` delegates mute/solo state to `Mixer` (`framework/song/mixer.ck`) and YAML patch-set persistence to `PatchSetStore` (`framework/song/patch-set-store.ck`).
- **Controllers:** `OscControl` (`framework/control/osc-control.ck`, using a unified dispatch loop), `KeyboardControl`, `LaunchControl` (`framework/control/launch-control.ck`), and `MidiMapper` (`framework/control/midi-mapper.ck`) each handle one input surface.
- **Display & Broadcast:** `TerminalDisplay` (`dashboard.md` + ANSI console) and `StateBroadcaster` (JSON state + fragment graph) are separated from `LaunchControl` and triggered via `song.notifyStateChanged()`.
- **OSC:** `GuiLink` (`framework/core/gui-link.ck`) provides a single shared `OscSend` to port `9450`, and `CadenzaConstants` (`framework/core/constants.ck`) replaces scattered port/CC/LED magic numbers.

### 6. Modular GUI (`gui/`) Without a Build Step
- **Server:** `gui/server.js` wires Express and WebSockets to `gui/server/preset-catalog.js`, `gui/server/patch-sets.js`, and `gui/server/osc-bridge.js`.
- **Frontend:** `gui/index.html` contains only markup and loads `gui/css/dashboard.css` plus native ES modules in `gui/js/` (`state.js`, `devices-table.js`, `modals.js`, `keyboard.js`, `piano-roll.js`, `fragment-graph.js`, `catalog-data.js`, `main.js`), using delegated `data-action` handlers instead of inline `on*` attributes.

---

## Verification

Run the automated check script from the repository root after framework or GUI edits:

```bash
./scripts/check.sh
```

It runs the ChucK unit test suite (`chuck -s test/run-all.ck`), YAML round-trip tests (`test/test-yaml.ck`), `chuck --syntax` across `music/*.ck`, `node --check` on all JS files, and `node tools/gen-presets.js --check` to ensure generated preset files match `presets/catalog.json`.
