# MuseGen

MuseGen is an advanced, modular framework for real-time algorithmic music generation and MIDI control, built with the [ChucK](https://chuck.cs.princeton.edu/) programming language. It is designed for composers, performers, and researchers interested in generative music, live coding, and MIDI-based synthesis.

## Features
- **Real-time music generation**: Compose and perform algorithmic music live
- **Flexible song structure**: Supports multi-part songs, chord progressions, melodies, and rhythm patterns
- **MIDI device management**: Control and route MIDI to multiple hardware and virtual instruments
- **Patch and preset management**: Easily switch and manage instrument sounds
- **Extensible**: Add new instruments, scales, progressions, and performance logic
- **Example library**: Includes a variety of example songs and styles

## Installation
1. **Install [ChucK](https://chuck.cs.princeton.edu/)** (required)
2. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/MuseGen.git
   cd MuseGen
   ```
3. **Connect your MIDI devices** (optional, for hardware synths)

## Quick Start Example
Here's a complete, working example that creates a simple song with a chord progression and drums:

```chuck
@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
60 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Create a synth patch
RolandSH4d synth(1, "SH4d channel 1", 64);

// Define chords
Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);

// Create a chord progression
[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chords[];
[1.0, 0.0, 1.0, 0.5] @=> float probabilities[];
[100] @=> int velocities[];

ChordProgression prog(synth, chords, progression, true, 8, 4, probabilities);
velocities @=> prog.velocities;

// Create drums
[1.0] @=> float drumProbs[];
[120] @=> int drumVels[];
[
 DrumMachine.BassDrum(),
 DrumMachine.Clap(),
 DrumMachine.ClosedHat()
] @=> int drumNotes[];

NoteCollection drumNotesCollection(drumNotes);
RolandSH4d drumKit(10, "SH-4d SDrums", 70);
DrumMachine drums(drumNotesCollection, 8, 1, drumProbs, drumKit);
drumVels @=> drums.velocities;

// Create song structure
[prog, drums] @=> Part parts1[];
Fragment frag1("frag1", 1, parts1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;

// Create and play song
Song song(BPM, root, frag1, parts1);
song @=> frag1.owningSong;
song.play();
```

To run the example:
```bash
chuck example.ck
```

This will create a simple song with:
- A repeating chord progression using the Roland SH-4d
- A basic drum pattern using the SH-4d's drum sounds
- Automatic variation through probability-based note selection

## Project Structure
```
framework/
  song.ck             # Song management, playback, and scheduling
  patch.ck            # MIDI patch/device and preset management
  chords.ck           # Chord progressions and arpeggios
  melody.ck           # Melody and rhythm generation
  midi-events.ck      # MIDI event handling and mapping
  note-collection.ck  # Scales, chords, and note sets
music/
  song01.ck, ...      # Example songs and performance scripts
```

## Supported Devices
- HYDRASYNTH EXPLORER
- Roland S-1
- Roland SH-4d
- V3 Grand Piano (XXL)
- Any General MIDI-compatible device

## Extending MuseGen
- **Add new instruments**: Extend the `Patch` class for new hardware or software synths
- **Custom scales/chords**: Add to `note-collection.ck`
- **New song forms**: Subclass `Part` or create new performance logic
- **MIDI mapping**: Modify or extend `midi-events.ck` for custom control

## Contributing
Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request.

## License
MIT
