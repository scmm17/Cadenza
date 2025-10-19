## Cadenza

Cadenza is a modular framework for real-time algorithmic music generation and MIDI control, built with the ChucK programming language. It targets composers, performers, and researchers working with generative music, live coding, and MIDI-based synthesis.

### Highlights
- **Real-time generation**: Live composition with deterministic timing
- **Flexible structure**: Songs, fragments, parts, progressions, melodies, rhythms
- **MIDI device management**: Route to multiple hardware/virtual synths
- **Patch and preset management**: Centralized instrument configuration
- **Extensible**: Add instruments, scales, progressions, and logic
- **Example library**: A variety of example songs and styles

## Installation
1. Install ChucK: see `https://chuck.cs.princeton.edu/`
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/Cadenza.git
   cd Cadenza
   ```
3. Connect MIDI devices as needed (optional)

## Quick Start (music)
Minimal example to play a simple song with chords and drums:

```chuck
@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

60 => float BPM;
60 => int root;

RolandSH4d synth(1, "Channel 1", 64);

Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);

[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chords[];
[1.0, 0.0, 1.0, 0.5] @=> float probabilities[];
[100] @=> int velocities[];

ChordProgression prog(synth, chords, progression, true, 8, 4, probabilities);
velocities @=> prog.velocities;

// Updated drum kit display name: "Drums"
RolandSH4d drumKit(10, "Drums", 70);
[1.0] @=> float drumProbs[];
[120] @=> int drumVels[];
[
  DrumMachine.BassDrum(),
  DrumMachine.Clap(),
  DrumMachine.ClosedHat()
] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 8, 1, drumProbs, drumKit);
drumVels @=> drums.velocities;

[prog, drums] @=> Part parts1[];
Fragment frag1("frag1", 1, parts1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;

// Updated: Song now expects a name as first parameter
Song song("example", BPM, root, frag1, parts1);
song @=> frag1.owningSong;
song.play();
```

Run with:
```bash
chuck example.ck
```

## YAML Utilities (framework/yaml.ck)
Cadenza includes a small YAML reader/writer used by tests and tools.

### Supported features
- **Scalars**: string, int, float
- **Arrays (sequences)**
  - Block style: `- item`, `- key: value` (arrays of maps)
  - Flow style: `[1, 2, 3]`
- **Maps (objects)**, including nested structures
- **Multiple top-level keys**: parsed into an anonymous top-level map
- **Writer fixes**
  - Top-level keys start at column 0
  - Arrays of maps render with the first property inline on the dash line (e.g., `- name: "test"`), with remaining properties on subsequent indented lines

### API summary (YamlNode)
- Static type constants: `TYPE_STRING()`, `TYPE_FLOAT()`, `TYPE_INT()`, `TYPE_ARRAY()`, `TYPE_MAP()`
- Removed: `TYPE_REF()` and all ref-node handling
- Node accessors: `GetType()`, `GetName()`, `GetString()`, `GetInt()`, `GetFloat()`, `GetArray()`, `GetMap()`
- Mutators for map properties:
  - `SetString(string key, string value)`
  - `SetInt(string key, int value)`
  - `SetFloat(string key, float value)`
  - `SetMap(string key) @=> YamlNode` (creates/overwrites an empty map and returns it)
- File I/O: `YamlNode.ParseFile(path)`, `node.WriteFile(path)`

### Minimal usage
```chuck
// Read
YamlNode root; YamlNode.ParseFile("test/test-yaml-nesting.yaml") @=> root;

// Inspect
if (root.GetType() == TYPE_MAP()) {
    // ...
}

// Modify map properties
root.SetString("title", "My Song");
root.SetInt("count", 3);
root.SetFloat("ratio", 0.75);

// Write
root.WriteFile("out.yaml");
```

## Running Tests
All YAML tests are in `test/test-yaml.ck`.

```bash
chuck test/test-yaml.ck
```

The suite covers:
- Parsing/writing scalars, arrays, and maps
- Round-trip tests for nested files and object arrays
- Inline flow arrays `[1, 2, 3]`
- Arrays of maps, including inline `- key: value` items

## Project Structure
```
framework/
  song.ck             # Song management, playback, and scheduling
  patch.ck            # MIDI patch/device and preset management
  chords.ck           # Chord progressions and arpeggios
  melody.ck           # Melody and rhythm generation
  midi-events.ck      # MIDI event handling and mapping
  note-collection.ck  # Scales, chords, and note sets
  yaml.ck             # Minimal YAML reader/writer and YamlNode class
music/
  *.ck                # Example songs and performance scripts
test/
  *.yaml, *.ck        # YAML fixtures and test runner
```

## Supported Devices
- HYDRASYNTH EXPLORER
- Roland S-1
- Roland SH-4d
- V3 Grand Piano (XXL)
- Any General MIDI-compatible device

## Recent Changes
- YAML: inline flow arrays parsing (`[1, 2, 3]`)
- YAML: arrays of maps parsing and writer inlining (`- name: "x"`)
- YAML: multiple top-level keys supported; top-level writer at column 0
- YAML: static type constants; removed `TYPE_REF()`
- YAML: map setters (`SetString`, `SetInt`, `SetFloat`, `SetMap`)
- Music: drum kit constructor display name changed to `"Drums"`
- Music: all `Song` constructors accept a leading `name` parameter

## Extending Cadenza
- Add new instruments by extending `Patch`
- Add scales/chords in `note-collection.ck`
- Create new performance logic via parts/fragments
- Customize MIDI mapping in `midi-events.ck`

## Contributing
Issues and PRs are welcome.

## License
MIT
