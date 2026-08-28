# Creating Music with Cadenza

This guide walks you through the structure of a Cadenza composition file, from declaring instruments to building a full song with fragments and transitions. All compositions live in the `music/` directory as `.ck` files.

## The Anatomy of a Song File

Every composition follows the same pattern:

1. Import the framework
2. Declare global parameters (BPM, root note)
3. Create MIDI device (Patch) instances
4. Define musical content (NoteCollections, Chords, Parts)
5. Organize Parts into Fragments
6. Create the Song and call `play()`

### Imports

Always import the modules you use. The most common set is:

```chuck
@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
```

`melody.ck` and `chords.ck` both transitively import `song.ck`, `patch.ck`, and `note-collection.ck`, so you rarely need to import those directly.

### Global Parameters

```chuck
90  => float BPM;    // Beats per minute
60  => int root;     // MIDI note number for the root (60 = middle C)
```

`root` is the tonal center of the composition. All chord and scale offsets are calculated relative to it.

---

## Instruments (Patches)

A `Patch` represents a physical or virtual MIDI device. Each class maps to a specific hardware synth. All constructors end with a volume argument (0–127).

### Available Patch Types

| Class | Hardware | Key Constructor Arguments |
|---|---|---|
| `Hydrasynth` | ASM Hydrasynth Explorer | `(string preset, int volume)` |
| `RolandS1` | Roland S-1 | `(int bank, int program, int volume)` |
| `RolandSH4d` | Roland SH-4d | `(int channel, int bank, int program, int volume)` or `(int channel, string patchName, int volume)` |
| `MoogMessenger` | Moog Messenger | `(int channel, int bank, int program, int volume)` |
| `BehringerRD6` | Behringer RD-6 | `(int volume)` |
| `V3GrandPiano` | V3 Grand Piano (XXL) | `(int channel, string presetName, int volume)` |

**Examples:**

```chuck
// Hydrasynth — load preset "D008" at volume 100
Hydrasynth hydra("D008", 100);

// Roland S-1 — bank 2, program 1, volume 64
RolandS1 s1(2, 1, 64);

// Roland SH-4d — channel 1, bank 3, program 7, volume 80
RolandSH4d sh4d(1, 3, 7, 80);

// Roland SH-4d used as a named drum kit on channel 10
RolandSH4d drumKit(10, "Drums", 70);

// Behringer RD-6 analog drum machine
BehringerRD6 rd6(94);
```

> **MIDI Channels**: MIDI channels in Cadenza are **1-based** when passed to constructors, but are stored as 0-based internally. Channel 10 is the standard General MIDI drum channel.

---

## Note Collections

A `NoteCollection` is an array of semitone offsets from the current root note. They are the building blocks for chords, scales, and arpeggios.

### Using Static Factories

`NoteCollection` provides a rich set of built-in collections:

```chuck
// Common chord voicings (I, IV, V, bVII)
NoteCollection.I_notes()
NoteCollection.IV_notes()
NoteCollection.V_notes()
NoteCollection.bVII_notes()

// Standard scales
NoteCollection.majorScale()
NoteCollection.minorScale()
NoteCollection.mixolydian_notes()

// Seventh chords
NoteCollection.I7_notes()
NoteCollection.IV7_notes()
NoteCollection.V7_notes()
```

### Creating Custom Note Collections

Pass any array of semitone offsets:

```chuck
[0, 4, 7, 12] => int major[];
NoteCollection majorNotes(major);
```

### Chords

A `Chord` wraps a `NoteCollection` and adds an octave offset, shifting its register up or down:

```chuck
Chord I_Low(NoteCollection.I_notes(), -1);   // I chord, one octave down
Chord IV_High(NoteCollection.IV_notes(), 0); // IV chord, normal register
```

### L-System Notes

`LSystemNotes` extends `NoteCollection` to generate algorithmic sequences from a YAML-defined L-system grammar (Lindenmayer system). This is an advanced technique for generating complex, self-similar melodic or rhythmic sequences.

```chuck
NoteCollection basis(NoteCollection.majorScale());
LSystemNotes lsys(basis, "my-lsystem.yaml");
```

The YAML file defines the start symbol, rewrite rules, offsets, and recursion depth. See `fz01.ck` for a real-world example.

---

## Rhythm and Probability

Parts use a `rhythmProbabilities` float array to decide which notes to actually play on each beat. A value of `1.0` means the note always plays; `0.0` means it always rests; values in between are probabilistic.

The array loops — if you have 8 beats but only 4 probabilities, the pattern repeats.

```chuck
// Play on beat 1 and 3, never on 2 and 4
[1.0, 0.0, 1.0, 0.0] => float probs[];
```

Velocities work the same way — they loop over the duration of the part:

```chuck
[120, 80, 100, 80] => int vels[];
```

Assign velocities to a part after constructing it:

```chuck
vels => myPart.velocities;
```

### Probability Mutation

Set `mutateProbabilityRange` on a Part to add subtle randomness to your probabilities each cycle, preventing mechanical repetition:

```chuck
0.4 => prog.mutateProbabilityRange;
```

---

## Musical Parts

Parts are the core performers. Each Part is attached to one Patch and plays for a specified number of measures at a given subdivision (notes-per-measure).

### ChordProgression

Plays a sequence of chords on a device, either simultaneously or arpeggiated.

```chuck
ChordProgression(
    Patch device,
    Chord chords[],
    int offsets[],      // semitone offset per chord
    int arpeggiated,    // true = arpeggio, false = block chord
    int notesPerMeasure,
    int numMeasures,
    float probabilities[]
)
```

**Example — block chords:**
```chuck
[0, 0, 0, 0] => int offsets[];
[I_Low, IV_Low, bVII_Low, IV_Low] => Chord chords[];
[1.0] => float probs[];
ChordProgression prog(sh4d, chords, offsets, false, 1, 4, probs);
```

**Example — arpeggiated:**
```chuck
ChordProgression arp(s1, chords, offsets, true, 16, 4, probs);
```

Set `true => prog.random` to randomize note selection within each chord instead of cycling through them in order.

### Melody

Plays individual notes from a `NoteCollection` sequentially.

```chuck
Melody(Patch device, NoteCollection scale, int npm, int numMeasures, float probs[])
```

### AleatoricMelody

Like `Melody`, but picks notes at random from the scale each time:

```chuck
AleatoricMelody melody(hydra, NoteCollection.majorScale(), 16, 4, probs);
```

### SequentialMelody

Steps through the scale in order, note by note. Set `true => mel.useAllNotes` to step continuously across multiple measures rather than resetting each measure:

```chuck
SequentialMelody bassLine(moog, NoteCollection.majorScale(), 8, 4, probs);
true => bassLine.useAllNotes;
```

### DrumMachine

Plays a fixed sequence of General MIDI drum notes. Unlike melodic parts, the `NoteCollection` is an array of explicit MIDI note numbers, not scale offsets.

```chuck
// Build the pattern using static constants
[
    DrumMachine.BassDrum(),
    0,
    DrumMachine.SnareDrum(),
    0,
    DrumMachine.BassDrum(),
    DrumMachine.ClosedHat(),
    DrumMachine.Clap(),
    0
] => int drumNotes[];

NoteCollection pattern(drumNotes);
RolandSH4d drumKit(10, "Drums", 70);
DrumMachine drums(pattern, 8, 1, probs, drumKit);
```

**Available drum constants:**

| Method | Drum Part |
|---|---|
| `DrumMachine.BassDrum()` | Kick / Bass Drum |
| `DrumMachine.SnareDrum()` | Snare |
| `DrumMachine.Clap()` | Clap |
| `DrumMachine.ClosedHat()` | Closed Hi-Hat |
| `DrumMachine.OpenHat()` | Open Hi-Hat |
| `DrumMachine.LowTom()` | Low Tom |
| `DrumMachine.HiTom()` | High Tom |
| `DrumMachine.Cymbal()` | Crash Cymbal |

Use `0` as a rest in the pattern array.

---

## Fragments and Song Structure

### Simple Songs (Single Fragment)

For a straightforward looping composition, create one Fragment and pass it to the Song:

```chuck
[prog, melody, drums] => Part parts[];
Fragment frag("main", 1, parts);
Song song("my-song", BPM, root, frag, parts);
song.play();
```

The `Fragment` constructor takes a name string, a repeat count, and the Parts array.

### Structured Songs (Multiple Fragments)

For an arrangement that builds over time — a song that starts sparse, adds instruments, then reaches a climax — use multiple Fragments connected by transitions:

```chuck
[drums]                    => Part parts1[];
[prog, drums]              => Part parts2[];
[prog, melody, drums]      => Part parts3[];

Fragment frag1("intro",   1, parts1);
Fragment frag2("verse",   2, parts2);
Fragment frag3("chorus",  4, parts3);

// Chain transitions
FragmentTransition ft1(frag2, 1.0);
FragmentTransition ft2(frag3, 1.0);
FragmentTransition ft3(frag1, 1.0);  // Loop back to start

[ft1] => frag1.nextFragments;
[ft2] => frag2.nextFragments;
[ft3] => frag3.nextFragments;

// Pass all parts ever used as the final argument
[prog, melody, drums] => Part allParts[];
Song song("my-song", BPM, root, frag1, allParts);
song.play();
```

`FragmentTransition(Fragment target, float probability)` — the probability field allows you to define weighted random transitions. Multiple transitions can be added to `nextFragments`, and the system picks one at runtime based on the weights.

> **Golden Mode**: When Golden mode is active (press `g` in the terminal or click the button in the GUI), the Song always takes the first listed transition, making the arrangement deterministic and repeatable.

---

## Configuration and State (YAML)

When a song is first loaded, if no `.yaml` file exists for it in the `music/` directory, one is automatically created saving the initial state (BPM, device volumes, mute states, presets). On subsequent loads, this state is restored.

You can manually save the current state from the Live Dashboard or by pressing `w` in the terminal. This makes Cadenza's "studio" settings persistent across sessions without modifying your `.ck` source file.

---

## Full Example

See [`music/plink01.ck`](../music/plink01.ck) for a concise, complete song combining an arpeggiated chord progression, aleatoric melody, and a full drum machine pattern across three separate physical devices.

For a structured arrangement with Fragments, see [`music/song01.ck`](../music/song01.ck).
