# AGENTS.md

Guidance for coding agents working in the **Cadenza** repository.

## 1. Project Overview & Architecture

Cadenza is a real-time algorithmic music generation and MIDI control framework written in **ChucK** (`framework/`, `music/`, `test/`) paired with a **Node.js + vanilla HTML/CSS/JS Live Dashboard** (`gui/`).

### Runtime & Data Flow

```text
Browser UI (http://localhost:3000, gui/index.html)
    ↕ WebSocket (JSON commands & state updates)
Node.js Bridge Server (gui/server.js)
    ↕ OSC over UDP
    • localhost:9449  (GUI → ChucK: transport, tempo, mute/solo, synth/channel/preset/CC)
    • localhost:9450  (ChucK → GUI: device state, active notes for piano roll, fragment/song state)
ChucK Engine (framework/song.ck, framework/patch.ck, ...)
    ↕ MIDI + LaunchControl XL
External Hardware Synths
```

### Repository Map

- `framework/`: Core ChucK libraries:
  - `song.ck`: `Song`, `Part`, `Fragment`, `FragmentTransition`, `LaunchControl`, `ControlChange` (osc/keyboard loops, device registry, patch-set YAML load/save).
  - `patch.ck`: `Patch` base class and synth subclasses (`Hydrasynth`, `MoogMessenger`, `RolandS1`, `RolandSH4d`, `BehringerRD6`, `V3GrandPiano`) plus preset collections (`HydraPresetCollection`, `SH4dPresetCollection`, `V3PresetCollection`).
  - `chords.ck`: `Chord`, `ChordProgression`.
  - `melody.ck`: `Melody`, `AleatoricMelody`, `SequentialMelody`, `DrumMachine`.
  - `note-collection.ck`: `NoteCollection`, `LSystemNotes`.
  - `midi-events.ck`: `MidiMapper`.
  - `yaml.ck`: `YamlNode`, `YamlParser` (custom in-ChucK YAML parser/writer).
- `music/`: Runnable song scripts (`*.ck`), L-system grammar files, and per-song patch sets (`<song>.patch-sets/*.yaml` + `.default`).
- `gui/`: Live Dashboard and bridge:
  - `server.js`: Express + `ws` + `node-osc` bridge and patch-set YAML file manager.
  - `index.html`: Single-file vanilla HTML/CSS/JS frontend (uses `cytoscape` for fragment graphs).
  - `presets.js`: Synth preset catalog data for the UI.
- `test/`: Headless ChucK unit test suite (`run-all.ck`, `test-*.ck`, `test-helpers.ck`, `mock-patch.ck`, `test-yaml.ck`).
- `docs/` & `specs/`: Architecture/contributor docs (`docs/framework.md`, `docs/creating-music.md`) and feature specifications (`specs/`).
- `./ck`: macOS helper script (`exec chuck --dac:6 --in:0 "$@"`) for live playback without webcam ADC sample-rate errors.
- `dashboard.md`: Auto-updated status table written during live sessions.

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

### `@import` Semantics
- `@import "file.ck"` imports class definitions into scope, **but does NOT execute top-level statements** in the imported file.
- Avoid putting executable side effects at the top level of framework or library test modules; put entrypoints inside `class`/`static` methods and invoke them explicitly.

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
  - `0..15` internally in `Patch.midiChannel`, YAML patch-set files (`midiChannel`), OSC/WebSocket payloads (`dev.channel`), and `Song.resolveMidiChannelForSynth()`.
  - `1..16` in user-facing UI controls, warning dialogs, and `Patch` subclass constructors (`channel - 1 => midiChannel`).
- **Device Indices**:
  - `1..16` in `Patch.devIndex`, OSC messages, and GUI `dev.index`.
  - `0..15` (`devIdx - 1`) when indexing `Song.devices[]`.

### Synth Channel & Preset Naming Conventions
When modifying synth assignment or preset parsing (`framework/song.ck`, `framework/patch.ck`, `gui/index.html`, `gui/server.js`), keep these rules synchronized:
- **`Moog`** (`Moog Messenger`) & **`Hydrasynth`**: Auto-assign to channel **1** (`0` internal).
  - Moog preset format is `<Category>: <1-16>` (e.g., `"Messenger: 1"`, `"Hard Lead: 12"`), formatted by `MoogMessenger.formatPatchName(b, p)` without the word `"Program"`.
  - `Song.setPresetByName` keeps backwards-compatible parsing for legacy `"<Category> Program: <N>"` and `"Bank: <B> Program: <P>"` strings as well as `"<Category>: <N>"`.
- **`S-1`**: Auto-assigns to channel **3** (`2` internal).
- **`SH-4d`**: Synth channels span **1–4** (`0..3` internal; drums typically live on channel 10 / `9` internal). Auto-assignment picks the first unused channel in `0..3` among `SH-4d` devices, or aborts (and pops up `#warningModal` in the UI) if all 4 are taken.
- **`V3`**: Supports channels **1–16** (`0..15` internal). Auto-assignment picks the first unused channel in `0..15` among `V3` devices, or aborts (and pops up `#warningModal` in the UI) if all 16 are taken.

---

## 3. Testing Guide & Known Testing Issues

### Always Run Tests in Silent Mode (`-s` / `--silent`)
Run the main unit test suite from the repository root:

```bash
chuck -s test/run-all.ck
```

**Important testing issues to know:**
1. **`-s` is mandatory for headless/automated runs**: Without `-s`, ChucK tries to initialize real-time audio hardware (DAC/ADC), which can fail with webcam/input sample-rate errors (why `./ck` uses `--dac:6 --in:0`), conflict with an active live session, or make tests hang.
2. **Real-time clock blocking**: Even in `-s` mode, `dur => now` advances ChucK's virtual sample clock (fast, not wall-clock, in `--silent` mode), whereas real `Song` constructors open MIDI devices, bind OSC UDP port `9449`, and start `LaunchControl` / `keyboardLoop` shreds. **Always use `MockSong` and `MockPatch` from `test/mock-patch.ck`** in unit tests instead of instantiating `Song` directly or opening hardware `Patch` constructors.
3. **OSC / MIDI side effects**: `MockPatch` clears `deviceName` (`""`) and overrides `noteOn`/`noteOff` so hardware MIDI ports are never opened.
4. **Top-level code in `@import` files does not run**: Adding a new `test/test-foo.ck` file requires **both**:
   - `@import "test-foo.ck"` in `test/run-all.ck`
   - Calling `FooTests.run();` inside `test/run-all.ck`
5. **Failure exit codes**: `test/run-all.ck` checks `if (TestCounter.failed > 0) Machine.crash();`. Use the helpers in `test/test-helpers.ck` (`Assert.equalInt`, `Assert.equalFloat`, `Assert.equalString`, `Assert.arraysEqualInt`, `Assert.arraysEqualFloat`, `Assert.isTrue`, `Assert.isFalse`) so failures increment `TestCounter.failed` and fail the command cleanly.

### Standalone YAML Tests (`test/test-yaml.ck`)
`test/test-yaml.ck` is **not** included in `test/run-all.ck`:
- It uses its own local `assert*` helpers that print `PASS` / `ASSERT FAIL` to stdout and does **not** call `Machine.crash()` on failure, so inspect output for `ASSERT FAIL`.
- Run it from inside `test/` so relative fixture/output YAML files resolve cleanly without polluting the repo root:
  ```bash
  (cd test && chuck -s test-yaml.ck)
  ```
  Check `git status` afterward in case output test fixtures (`test/*-out.yaml`) were rewritten.

### Validating GUI Changes (`gui/`)
There is no JS test runner or build step (`gui/index.html` is served statically and edited directly):
- Validate Node server syntax after editing `gui/server.js`:
  ```bash
  node --check gui/server.js
  ```
- Validate inline `<script>` syntax and helper functions in `gui/index.html` by extracting script blocks and running them through Node's `vm.Script` / `vm.createContext` with lightweight DOM stubs.

---

## 4. Working Alongside a Live Session

- **Do not kill or restart running `chuck` or `node server.js` processes** unless explicitly asked — the user often keeps a live performance or editing session running while requesting code changes.
- Keep wire-protocol backwards compatibility in mind when the user's running `chuck` process may predate a GUI edit (or vice versa).
- **Watch for live-session workspace mutations**: Running Cadenza instances update `dashboard.md` and `music/<song>.patch-sets/*.yaml` (and `.default`, or migrate legacy `music/<song>.yaml` files). Always inspect `git status` and `git diff` carefully before staging or committing.

---

## 5. Code Style & Documentation Conventions

- **ChucK (`framework/`, `music/`, `test/`)**: 4-space indentation, `PascalCase` for classes, `camelCase` for variables and methods. Preserve existing comments unless changing that code.
- **JavaScript/HTML (`gui/`)**: Vanilla ES6 without build tooling or external frontend frameworks; keep UI logic self-contained in `gui/index.html` and OSC/file-system bridging in `gui/server.js`.
- Keep changes to synth preset catalogs, OSC messages, and YAML keys aligned across `framework/patch.ck`, `framework/song.ck`, `gui/server.js`, `gui/index.html`, and `gui/presets.js`.
