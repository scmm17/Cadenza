# The Cadenza Framework

This document describes the internal architecture of the Cadenza framework for contributors who want to extend it — adding new devices, new generative algorithms, or new features to the engine.

## Overview

Cadenza is a layered framework. From the bottom up:

```
Song / Fragment          ← Orchestration and timing
    Part                 ← Abstract musical unit
        ChordProgression ← Harmony
        Melody           ← Single-voice melodic generation
        DrumMachine      ← Percussion
    Patch                ← MIDI device abstraction
        NoteCollection   ← Note/scale/chord data
```

The `Song` class is the runtime engine. It drives timing, manages state, listens to hardware controls (via `LaunchControl`) and the GUI (via OSC), and coordinates all `Part` playback using ChucK's sporking model.

---

## File Map

| File | Contents |
|---|---|
| `framework/song.ck` | `Song`, `Part`, `Fragment`, `FragmentTransition`, `LaunchControl`, `ControlChange` |
| `framework/patch.ck` | `Patch` (base), all device subclasses, `V3Preset`, `V3PresetCollection` |
| `framework/chords.ck` | `Chord`, `ChordProgression` |
| `framework/melody.ck` | `Melody`, `AleatoricMelody`, `SequentialMelody`, `DrumMachine` |
| `framework/note-collection.ck` | `NoteCollection`, `LSystemNotes` |
| `framework/midi-events.ck` | `MidiMapper` (Hydrasynth keyboard event routing) |
| `framework/yaml.ck` | `YamlNode` YAML parser and writer |

---

## Class Reference

### `Patch` (`framework/patch.ck`)

The base class for all MIDI devices. It owns the `MidiOut` connection, handles note-on/note-off messaging, controller changes, volume, pan, filter, and mute state. It also transmits OSC note events to the GUI.

**Key fields:**

| Field | Type | Description |
|---|---|---|
| `deviceName` | `string` | System name of the MIDI device (must match OS MIDI device name) |
| `uiName` | `string` | Short display name shown in the GUI |
| `midiChannel` | `int` | 0-based MIDI channel |
| `patchName` | `string` | Patch/preset label (display only) |
| `volume` | `int` | 0–127 (sends CC 7 on init) |
| `filterCutoff` | `int` | 0–127 or -1 to disable (CC 74) |
| `filterResonance` | `int` | 0–127 or -1 to disable (CC 71) |
| `pan` | `int` | 0–127, 64=center (CC 10) |
| `muted` | `int` | Effective mute state (runtime, controlled by Song) |
| `userMuted` | `int` | User-explicit mute toggle |
| `devIndex` | `int` | 1-based index set by Song; used for OSC to GUI |

**Key methods:**

- `noteOn(int note, int velocity, dur duration)` — sends Note On, sporkes a delayed Note Off, and emits an OSC message to the GUI. Skips if `muted`.
- `noteOff(int note)` — sends Note Off and emits OSC.
- `sendControllerChange(int cc, int value)` — sends a raw MIDI CC.
- `sendAllNotesOff()` — sends CC 0x7B on the device's channel.
- `updateControllers()` — called on init; sends volume, pan, filter, and calls `setPreset()`.
- `setPreset()` — override in subclasses to send program change messages.
- `saveConfig(YamlNode config)` / `loadConfig(YamlNode config)` — override in subclasses for YAML persistence.

**OSC bridge**: All `noteOn` / `noteOff` messages are also sent via `OscSend` to `localhost:9450`. The path `/cadenza/noteOn` carries `devIndex, note, velocity`. This is how the GUI's piano roll is populated.

#### Adding a New Device

To add a new hardware synth, extend `Patch`:

```chuck
public class MyNewSynth extends Patch
{
    fun MyNewSynth(int channel, string preset, int v)
    {
        "My Synth MIDI Name" => deviceName;  // Must match OS name exactly
        "MySynth" => uiName;                 // Shown in the GUI
        channel - 1 => midiChannel;
        preset => patchName;
        Patch(v);                            // Must call parent constructor last
    }

    fun void setPreset()
    {
        // Send program change messages here
        programChangeHydra(program, bank);  // or write custom MIDI messages
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetString("preset", patchName);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        config.GetString("preset") => patchName;
        updateControllers();
    }
}
```

> Always call `Patch(v)` **last** in your constructor — it opens the MIDI port and initializes controllers.

---

### `NoteCollection` (`framework/note-collection.ck`)

Stores an array of semitone offsets from the song's root note. The fundamental unit of musical content.

**Key method:**

```chuck
fun int getMidiNote(Song song, int noteIndex, int offset)
```

Returns `song.rootNote + offset + notes[noteIndex % numNotes()]`. The `noteIndex` wraps around, so you can pass any integer and it cycles the collection.

**Adding new scale/chord factories**: Add a `static` method to `NoteCollection` following the existing pattern:

```chuck
fun static NoteCollection myCustomChord()
{
    [0, 3, 6, 9] => int notes[];  // Diminished 7th
    NoteCollection chord(notes);
    return chord;
}
```

#### `LSystemNotes`

Extends `NoteCollection`. Reads a YAML file defining an L-system grammar and pre-computes a large array of note offsets by recursively expanding the grammar to `maxDepth`. This array is then used as the note collection, making L-system sequences usable as drop-in replacements for any `NoteCollection`.

The expansion is done once at construction time, so there is no runtime overhead during playback.

---

### `Part` (`framework/song.ck`)

Abstract base class. All musical generators (progressions, melodies, drums) extend it.

**Key fields:**

| Field | Type | Description |
|---|---|---|
| `patch` | `Patch` | The device this part plays on |
| `notesPerMeasure` | `int` | Subdivisions per measure |
| `numberOfMeasures` | `int` | How many measures this part lasts |
| `rhythmProbabilities` | `float[]` | Per-beat play probability (loops) |
| `velocities` | `int[]` | Per-beat velocity (loops) |
| `legato` | `int` | If true, notes extend into the next beat |
| `mutateProbabilityRange` | `float` | Amount of random drift added to probabilities each cycle |

**Methods to implement in subclasses:**

```chuck
fun void play(Song song)           // Entry point — called by Song.playParts()
fun dur totalDuration(Song song)   // Must return the part's total runtime
fun int generateNote(Song song, int measure, int noteInMeasure)  // Return MIDI note number
```

**`playProbabilityRhythm(Song song)`** — the heart of the engine. Called by `play()` in most subclasses. For each note slot it:
1. Rolls a random number against `rhythmProbabilities`.
2. Calls `generateNote()` to get the MIDI pitch.
3. Calls `patch.noteOn()` with the appropriate duration.
4. Calls `song.advance()` to consume time.

If `legato` is true, notes are extended to fill the full duration slot.

#### Adding a New Part Type

```chuck
public class MyWalkingBass extends Part
{
    NoteCollection scale;
    int currentNote;

    fun MyWalkingBass(Patch device, NoteCollection theScale, int npm, int numMeasures, float probs[])
    {
        initPart(device);
        theScale @=> scale;
        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        probs => rhythmProbabilities;
        0 => currentNote;
    }

    fun dur totalDuration(Song song) { return song.whole() * numberOfMeasures; }

    fun void play(Song song) { playProbabilityRhythm(song); }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        scale.getMidiNote(song, currentNote++, 0) => int note;
        if (currentNote >= scale.numNotes()) 0 => currentNote;
        return note;
    }
}
```

---

### `Fragment` and `FragmentTransition` (`framework/song.ck`)

`Fragment` groups a set of `Part` objects for one section of a song. It plays the parts together for `repeatCount` cycles. After playing, it probabilistically selects the next Fragment from its `nextFragments` array.

`FragmentTransition` pairs a target `Fragment` with a `float` probability weight. The `Fragment.getNextSongFragment()` method iterates over `nextFragments`, accumulating probabilities until a random draw is satisfied. This creates a Markov-chain style arrangement system.

---

### `Song` (`framework/song.ck`)

The runtime engine. Created once per performance. Key responsibilities:

**Timing:** `song.whole()`, `song.half()`, `song.quarter()`, etc. return `dur` values derived from BPM. `song.advance(dur d)` advances ChucK's clock while correctly handling pause/resume.

**Device management:** `initDevicesFromParts()` scans all Parts and registers their Patches into the `devices[16]` array (indexed by insertion order). The `devIndex` (1-based) is set here and is used by Patch to route OSC to the GUI.

**Mute/Solo:** The Song manages two parallel mute concepts:
- `userMuted` — what the user has toggled via GUI or LaunchControl.
- `muted` — the *effective* mute state, which may be overridden by Solo mode.

`updateEffectiveMuteStates()` reconciles these whenever mute/solo state changes.

**Playback:** `song.play()` drives a fragment chain loop. For each Fragment, it calls `playPartOnce()`, which sporkes each Part into its own shred. All parts run concurrently; the song waits for the longest one to complete before advancing to the next Fragment.

**Keyboard Controls (terminal):**

| Key | Action |
|---|---|
| `1`–`9` | Select device by index |
| `g` | Toggle Golden Mode (deterministic transitions) |
| `a` | Toggle All Mode (play all parts, ignoring Fragment membership) |
| `w` | Save current config to YAML |
| `Q` | Shutdown gracefully |

**OSC Control Loop:** Runs on port `9449`. Each GUI action is translated to an OSC message and dispatched to a dedicated handler shred. Adding a new GUI control requires:
1. Adding a new `recv.event(...)` declaration in `oscControlLoop()`.
2. Adding a handler method `fun handleOscMyAction(OscEvent e)`.
3. Sporking the handler.
4. Implementing the corresponding GUI logic in `gui/index.html`.

---

### `LaunchControl` (`framework/song.ck`)

Integrates a **Novation Launch Control XL** hardware control surface. On init it opens the device by name and listens for MIDI CC messages. The `ControlChange` objects define the mapping from physical knob ranges to MIDI CC output channels:

| Knobs (CC input) | Function | Output CC |
|---|---|---|
| 77–84 | Volume, channels 1–8 | CC 7 |
| 13–20 | Filter Cutoff, channels 1–8 | CC 74 |
| 29–36 | Resonance, channels 1–8 | CC 71 |
| 49–56 | Pan, channels 1–8 | CC 10 |

The pad buttons (notes 41, 57, 73, 89) select the active device. Buttons 109 and 110 toggle mute and solo mode. The LEDs provide visual feedback about the current state.

---

### `YamlNode` (`framework/yaml.ck`)

A minimal YAML parser and writer built in ChucK. Supports scalars (string, int, float), arrays (block and flow style), and nested maps.

**Reading:**
```chuck
YamlNode.ParseFile("config.yaml") @=> YamlNode root;
root.GetString("name") => string name;
root.GetInt("count") => int count;
root.GetFloat("ratio") => float ratio;
root.GetMap("devices") @=> YamlNode devices;
root.GetArray() @=> YamlNode items[];
```

**Writing:**
```chuck
root.SetString("name", "MySong");
root.SetInt("count", 4);
root.SetFloat("ratio", 0.75);
root.SetMap("section") @=> YamlNode section;
root.WriteFile("output.yaml");
```

Songs use `loadConfig()` / `saveConfig()` in `Song` to persist BPM and per-device state to `music/<name>.yaml`.

---

## Data Flow

```
ChucK Script (.ck)
    → Constructs Patches, Parts, Fragments, Song
    → song.play() begins

Song
    → sporkes oscControlLoop() (listens OSC port 9449)
    → sporkes keyboardLoop()
    → sporkes launchControl.startEventLoop()
    → Iterates Fragment chain
        → For each Fragment, sporkes each Part into its own shred

Part (per shred)
    → Calls generateNote() for each beat
    → Calls patch.noteOn(note, velocity, duration)

Patch.noteOn()
    → Sends MIDI Note On via MidiOut
    → Sends OSC /cadenza/noteOn to localhost:9450 (→ GUI)
    → Sporkes delayed noteOff

GUI (Node.js server, localhost:3000)
    → Receives OSC from ChucK on port 9450
    → Forwards to browser via WebSocket
    → Browser renders piano roll

GUI user action
    → Browser sends JSON command over WebSocket
    → Node.js server converts to OSC
    → Sends to ChucK on port 9449
    → Song's oscControlLoop() handles it
```

---

## Testing

YAML round-trip tests live in `test/test-yaml.ck`. Run them after any changes to `yaml.ck`:

```bash
chuck test/test-yaml.ck
```

There is no automated integration test runner for the framework beyond manually loading songs. When adding new Part or Patch subclasses, verify by writing a minimal composition in `music/` that exercises the new code and running it through the GUI.
