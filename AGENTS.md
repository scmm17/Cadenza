# AGENTS.md

Guidance for coding agents working in the **Cadenza** repository.

## 1. Project Overview & Architecture

Cadenza is a real-time algorithmic music generation and MIDI control framework written in **ChucK** (`framework/`, `music/`, `test/`) paired with a **Node.js + vanilla HTML/CSS/ES-module Live Dashboard** (`gui/`), with synth preset/metadata tables generated from a single JSON source (`presets/catalog.json`).

### Runtime & Data Flow

```text
Browser UI (http://localhost:3000, gui/index.html + gui/css/dashboard.css + gui/js/*.js)
    ↕ WebSocket (JSON commands & state updates)
Node.js Bridge Server (gui/server.js + gui/server/*.js)
    ↕ OSC over UDP
    • localhost:9449  (GUI → ChucK: transport, tempo, mute/solo, synth/channel/preset/CC)
    • localhost:9450  (ChucK → GUI: device state, active notes for piano roll, fragment/song state)
ChucK Engine (framework/cadenza.ck → framework/song/song.ck, control/*, composition/*, devices/*)
    ↕ MIDI + LaunchControl XL
External Hardware Synths
```

### Repository Map

- `framework/`: Core ChucK libraries, imported by songs and tests via the single umbrella entry point `framework/cadenza.ck`:
  - `cadenza.ck`: Topologically ordered umbrella `@import` file for all framework layers.
  - `core/`:
    - `constants.ck`: `CadenzaConstants` static accessors for OSC ports, MIDI CC numbers, and LaunchControl XL note/color mappings.
    - `gui-link.ck`: `GuiLink` shared OSC transmitter to `localhost:9450` (supports `GuiLink.setEnabled(false)` for headless tests).
    - `yaml.ck`: `YamlNode`, `YamlParser` (custom in-ChucK YAML parser/writer).
  - `devices/`:
    - `patch.ck`: `Patch` base class, MIDI output/CC helpers, active-note tracking, and polymorphic preset hooks.
    - `hydrasynth.ck` (`Hydrasynth`), `moog-messenger.ck` (`MoogMessenger`), `roland-s1.ck` (`RolandS1`), `roland-sh4d.ck` (`RolandSH4d`), `behringer-rd6.ck` (`BehringerRD6`), `v3-grand-piano.ck` (`V3GrandPiano`).
    - `synth-registry.ck`: `SynthRegistry` central synth factory and MIDI channel auto-assignment rules.
    - `presets/`: `preset.ck` (`Preset`, `V3Preset`, `HydraPreset`, `SH4dPreset`), `preset-collection.ck` (`PresetCollection`), and `generated/` (`hydrasynth-presets.ck`, `sh4d-presets.ck`, `v3-presets.ck`, `moog-banks.ck`, `synth-table.ck`).
  - `composition/`:
    - `song-context.ck`: `SongContext` (shared timing/tempo fields, static state flags, virtual hooks) breaking ChucK `@import` cycles.
    - `part.ck`: `Part` base class.
    - `fragment.ck`: `Fragment`, `FragmentTransition`, and `SongState extends SongContext`.
    - `note-collection.ck` (`NoteCollection`), `lsystem-notes.ck` (`LSystemNotes`), `chords.ck` (`Chord`), `chord-progression.ck` (`ChordProgression`), `melody.ck` (`Melody`, `AleatoricMelody`, `SequentialMelody`), `drum-machine.ck` (`DrumMachine`).
  - `control/`:
    - `midi-mapper.ck` (`MidiMapper`), `terminal-display.ck` (`TerminalDisplay`), `state-broadcaster.ck` (`StateBroadcaster`), `launch-control.ck` (`LaunchControl`, `ControlChange`), `keyboard-control.ck` (`KeyboardControl`), `osc-control.ck` (`OscControl`).
  - `song/`:
    - `mixer.ck` (`Mixer`), `patch-set-store.ck` (`PatchSetStore`), `song.ck` (`Song extends SongState`).
- `presets/catalog.json` & `tools/gen-presets.js`: Single source of truth for V3/Hydrasynth/SH-4d presets, Moog bank names, and synth metadata; `node tools/gen-presets.js` regenerates `framework/devices/presets/generated/*.ck` and `gui/js/catalog-data.js`.
- `music/`: Runnable song scripts (`*.ck` importing `../framework/cadenza.ck`), L-system grammar files, and per-song patch sets (`<song>.patch-sets/*.yaml` + `.default`).
- `gui/`: Live Dashboard and Node bridge:
  - `server.js`: Express + `ws` entrypoint wiring `gui/server/preset-catalog.js`, `gui/server/patch-sets.js`, and `gui/server/osc-bridge.js`.
  - `index.html` & `css/dashboard.css`: Semantic HTML + stylesheet loading native ES modules without a build step.
  - `js/`: Native ES modules (`state.js`, `devices-table.js`, `modals.js`, `keyboard.js`, `piano-roll.js`, `fragment-graph.js`, `catalog-data.js`, `main.js`).
- `test/`: Headless ChucK unit test suite (`run-all.ck`, `test-*.ck`, `test-helpers.ck`, `mock-patch.ck`, `test-yaml.ck`).
- `scripts/check.sh`: Automated verification script running ChucK tests, YAML tests, `music/*.ck` syntax checks, JS syntax checks, and generated-preset freshness checks.
- `docs/` & `specs/`: Contributor and architecture docs (`docs/framework.md`, `docs/creating-music.md`, `docs/osc-protocol.md`, `docs/refactoring.md`, `docs/README.md`) and specs (`specs/refactoring-plan.md`, etc.).
- `./ck`: macOS helper script (`exec chuck --dac:6 --in:0 "$@"`) for live playback without webcam ADC sample-rate errors.
- `dashboard.md`: Auto-updated status table written by `TerminalDisplay` during live sessions.

---

## 2. ChucK Language Quirks & Common Pitfalls

ChucK syntax and runtime semantics trip up standard C/Java/JS assumptions. Watch out for these patterns:

### Value vs. Reference Assignment (`=>` vs. `@=>`)
- Assignment flows **left-to-right**: `value => target;`
- Primitives (`int`, `float`, `dur`, `time`) and `string` values use `=>`.
- **Object references and arrays MUST use `@=>`**:
  ```chuck
  newPatch @=> devices[idx];
  null @=> queuedFragment;
  devices[i] $ RolandSH4d @=> RolandSH4d @ sh; // Downcasting uses `$` + `@=>`
  ```
  Using `=>` on object or array references causes compilation errors.

### Arrays
- Empty/reset an array field by reference-assigning a zero-length typed array or calling `.clear()`:
  ```chuck
  FragmentTransition empty[0];
  empty @=> frag.nextFragments;
  mutedPatches.clear();
  ```
- Append elements with `<<` (`arr << item;`).
- Check array length with `.cap()` or `.size()`.

### `@import` Semantics & Acyclic Dependencies
- **No circular `@import`s**: ChucK requires an acyclic module graph (`core` → `devices` → `composition` → `control` → `song`). Keep shared engine state/hooks on `SongContext` (`framework/composition/song-context.ck`) and `SongState` (`framework/composition/fragment.ck`) so `Part`, `Fragment`, and controllers do not import `Song`.
- **Top-level and class-body statements do NOT execute on `@import`**:
  - `@import "file.ck"` imports class definitions into scope without executing top-level statements or non-declaration class-body statements (e.g., `9449 => static int PORT;` silently stays `0`).
  - Use `static` accessor methods (like `CadenzaConstants.OSC_CONTROL_PORT()`) or zero-initialized `static int` flags (like `GuiLink.disabled`) instead of class-body initializers, and put test/script entrypoints inside methods and call them explicitly.

### Static Field Inheritance & Constructor Name Shadowing (ChucK 1.5.5.5)
- **Always qualify base-class `static` fields with the declaring class name**: Accessing `SongContext` static fields via `Song.golden`, `song.golden`, or unqualified `golden` inside `Song` triggers a ChucK VM assertion crash (`chuck_instr.cpp`, line 7796). Always write `SongContext.golden`, `SongContext.isPaused`, `SongContext.shuttingDown`, and `SongContext.debug`.
- **Constructor name shadowing inside a class**: Inside `class Song`, writing `Song.shreds` fails to compile because `Song` resolves to `[fun]Song.Song(...)`; reference `Song`'s own static fields unqualified (`shreds`, `oldShreds`) inside `Song`.

### Virtual Override Parameter Types
- ChucK matches method overrides strictly by parameter type. `Part` subclasses (`ChordProgression`, `Melody`, `DrumMachine`) must declare `play(SongContext)`, `totalDuration(SongContext)`, and `generateNote(SongContext, int, int)` using `SongContext` (not `Song`), otherwise ChucK treats them as overloads and dispatches to the empty `Part` base methods.

### String Operations & Conversions
- **`string.substring(start, length)` takes `(start, length)`, NOT `(start, endIndex)`!**
  For example, extracting from `start` up to index `i` requires `str.substring(start, i - start)`.
- Use `Std.itoa(int)`, `Std.ftoa(float, precision)`, `Std.atoi(string)`, `Std.atof(string)` for numeric/string conversions, and `YamlNode.trimLeft(...)` / `YamlNode.trimRight(...)` for whitespace trimming.

### `Patch` Subclass Constructors
- **Always assign fields (`deviceName`, `uiName`, `midiChannel`, `patchName`, `bank`, `program`, etc.) BEFORE calling `Patch(v)` last.**
  `Patch(int v)` immediately calls `openDevice()` and `updateControllers()` (which calls `setPreset()`). Setting metadata after `Patch(v)` will miss initialization.
- The **no-arg constructor `Patch()`** leaves `openedDeviceName` empty and avoids opening live MIDI hardware when `deviceName == ""` (used by `MockPatch` in unit tests).
- Device-specific quirk: `MoogMessenger.setPan()` intentionally stores `pan` in state **without** sending MIDI CC 10, because CC 10 maps to OSC Tune on the Moog Messenger.

### 0-Based vs. 1-Based Channels and Indices
Be explicit about which coordinate system you are touching:
- **MIDI Channels**:
  - `0..15` internally in `Patch.midiChannel`, YAML patch-set files (`midiChannel`), OSC/WebSocket payloads (`dev.channel`), and `SynthRegistry.resolveMidiChannelForSynth()`.
  - `1..16` in user-facing UI controls, warning dialogs, and `Patch` subclass constructors (`channel - 1 => midiChannel`).
- **Device Indices**:
  - `1..16` in `Patch.devIndex`, OSC messages, and GUI `dev.index`.
  - `0..15` (`devIdx - 1`) when indexing `Song.devices[]`.

### Synth Catalog, Channels & Preset Naming Conventions
- **`presets/catalog.json` is the single source of truth** for synth channel limits/defaults, Moog bank names, and V3/Hydrasynth/SH-4d preset lists.
- Never hand-edit files in `framework/devices/presets/generated/` or `gui/js/catalog-data.js`. After editing `presets/catalog.json`, run:
  ```bash
  node tools/gen-presets.js
  ```
- Keep synth assignment and preset parsing rules aligned across `presets/catalog.json`, `framework/devices/synth-registry.ck`, `framework/devices/*.ck`, `gui/js/devices-table.js`, `gui/js/modals.js`, and `gui/server/preset-catalog.js`:
  - **`Moog`** (`Moog Messenger`) & **`Hydrasynth`**: Auto-assign to channel **1** (`0` internal).
    - Moog preset format is `<Category>: <1-16>` (e.g., `"Messenger: 1"`, `"Hard Lead: 12"`), formatted by `MoogMessenger.formatPatchName(b, p)` without the word `"Program"`.
    - `MoogMessenger.selectPresetByName` preserves backwards-compatible parsing for legacy `"<Category> Program: <N>"` and `"Bank: <B> Program: <P>"` strings as well as `"<Category>: <N>"`.
  - **`S-1`**: Auto-assigns to channel **3** (`2` internal).
  - **`SH-4d`**: Synth channels span **1–4** (`0..3` internal; drums typically live on channel 10 / `9` internal). Auto-assignment picks the first unused channel in `0..3` among `SH-4d` devices, or aborts (and pops up `#warningModal` in the UI) if all 4 are taken.
  - **`V3`**: Supports channels **1–16** (`0..15` internal). Auto-assignment picks the first unused channel in `0..15` among `V3` devices, or aborts (and pops up `#warningModal` in the UI) if all 16 are taken.

---

## 3. Testing Guide & Known Testing Issues

### Unified Verification Script (`./scripts/check.sh`)
Run the full verification suite from the repository root after framework, preset, or GUI changes:

```bash
./scripts/check.sh
```

This runs five checks in sequence:
1. ChucK unit tests (`chuck -s test/run-all.ck`)
2. Standalone YAML tests (`cd test && chuck -s test-yaml.ck`)
3. ChucK syntax checks (`chuck --syntax`) across `music/*.ck`
4. Node/JS syntax checks (`node --check`) across `gui/server.js`, `gui/server/*.js`, and `gui/js/*.js`
5. Generated preset freshness check (`node tools/gen-presets.js --check`)

### Always Run ChucK Tests in Silent Mode (`-s` / `--silent`)
Run the main unit test suite directly with:

```bash
chuck -s test/run-all.ck
```

**Important testing issues to know:**
1. **`-s` is mandatory for headless/automated runs**: Without `-s`, ChucK tries to initialize real-time audio hardware (DAC/ADC), which can fail with webcam/input sample-rate errors (why `./ck` uses `--dac:6 --in:0`), conflict with an active live session, or make tests hang.
2. **Real-time clock blocking & OSC suppression**: Even in `-s` mode, `dur => now` advances ChucK's virtual sample clock (fast, not wall-clock, in `--silent` mode), whereas real `Song` constructors open MIDI devices, bind OSC UDP port `9449`, and start `LaunchControl` / `keyboardLoop` shreds. **Always use `MockSong` and `MockPatch` from `test/mock-patch.ck`** in unit tests instead of instantiating `Song` directly or opening hardware `Patch` constructors; both call `GuiLink.setEnabled(false)` to suppress OSC broadcasts to port `9450`.
3. **OSC / MIDI side effects**: `MockPatch` clears `deviceName` (`""`) and overrides `noteOn`/`noteOff` so hardware MIDI ports are never opened.
4. **Top-level code in `@import` files does not run**: Adding a new `test/test-foo.ck` file requires **both**:
   - `@import "test-foo.ck"` in `test/run-all.ck`
   - Calling `FooTests.run();` inside `test/run-all.ck`
5. **Failure exit codes**: `test/run-all.ck` checks `if (TestCounter.failed > 0) Machine.crash();`. Use the helpers in `test/test-helpers.ck` (`Assert.equalInt`, `Assert.equalFloat`, `Assert.equalString`, `Assert.arraysEqualInt`, `Assert.arraysEqualFloat`, `Assert.isTrue`, `Assert.isFalse`) so failures increment `TestCounter.failed` and fail the command cleanly.

### Standalone YAML Tests (`test/test-yaml.ck`)
`test/test-yaml.ck` is run by `./scripts/check.sh`, **not** by `test/run-all.ck`:
- It uses its own local `assert*` helpers that print `PASS` / `ASSERT FAIL` to stdout and does **not** call `Machine.crash()` on failure, so inspect output for `ASSERT FAIL`.
- Run it from inside `test/` so relative fixture/output YAML files resolve cleanly without polluting the repo root:
  ```bash
  (cd test && chuck -s test-yaml.ck)
  ```
  Check `git status` afterward in case output test fixtures (`test/*-out.yaml`) were rewritten.

### Validating GUI Changes (`gui/`)
There is no JS build step (`gui/index.html` is served statically and loads native ES modules directly):
- Validate Node/browser syntax via `./scripts/check.sh` or directly with `node --check`:
  ```bash
  node --check gui/server.js gui/server/*.js gui/js/*.js
  ```

---

## 4. Working Alongside a Live Session

- **Do not kill or restart running `chuck` or `node server.js` processes** unless explicitly asked — the user often keeps a live performance or editing session running while requesting code changes.
- Keep wire-protocol backwards compatibility in mind when the user's running `chuck` process may predate a GUI edit (or vice versa).
- **Watch for live-session workspace mutations**: Running Cadenza instances update `dashboard.md` and `music/<song>.patch-sets/*.yaml` (and `.default`, or migrate legacy `music/<song>.yaml` files). Always inspect `git status` and `git diff` carefully before staging or committing.

---

## 5. Code Style & Documentation Conventions

- **ChucK (`framework/`, `music/`, `test/`)**: 4-space indentation, `PascalCase` for classes, `camelCase` for variables and methods. Preserve existing comments unless changing that code.
- **JavaScript/HTML/CSS (`gui/`)**: Vanilla ES6+ without build tooling or external frameworks; keep UI logic in `gui/js/*.js` using delegated `data-action` handlers rather than inline `on*` HTML attributes, styling in `gui/css/dashboard.css`, and OSC/file-system bridging in `gui/server.js` + `gui/server/*.js`.
- Keep changes to synth preset catalogs, OSC messages, and YAML keys aligned across `presets/catalog.json` (regenerated via `node tools/gen-presets.js`), `framework/`, and `gui/`, and update `docs/` (`docs/framework.md`, `docs/osc-protocol.md`, `docs/creating-music.md`) when public APIs or protocols change.
