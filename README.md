# MuseGen

MuseGen is an advanced, modular framework for real-time algorithmic music generation and MIDI control, built with the [ChucK](https://chuck.cs.princeton.edu/) programming language. It is designed for composers, performers, and researchers interested in generative music, live coding, and MIDI-based synthesis.

---

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [Example: Creating a Song](#example-creating-a-song)
- [Supported Devices](#supported-devices)
- [LaunchControl Interface](#launchcontrol-interface)
- [Extending MuseGen](#extending-musegen)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- **Real-time music generation**: Compose and perform algorithmic music live.
- **Flexible song structure**: Supports multi-part songs, chord progressions, melodies, and rhythm patterns.
- **MIDI device management**: Control and route MIDI to multiple hardware and virtual instruments.
- **Patch and preset management**: Easily switch and manage instrument sounds.
- **Extensible**: Add new instruments, scales, progressions, and performance logic.
- **Example library**: Includes a variety of example songs and styles.

---

## Architecture
MuseGen is organized into modular ChucK classes:
- **Song**: Central class for song structure, playback, and part management.
- **Part**: Abstract base for musical parts (melody, chords, drums, etc.).
- **ChordProgression**: Handles chord sequences and arpeggiation.
- **Melody**: Generates melodies based on scales, probabilities, and song context.
- **Patch**: Manages MIDI device, channel, and preset selection.
- **NoteCollection**: Encapsulates scales, chords, and note sets.
- **MIDI Events**: Handles low-level MIDI input/output and mapping.
- **LaunchControl**: Provides integration with the Novation Launch Control XL MIDI controller for live performance and parameter control.

---

## Installation
1. **Install [ChucK](https://chuck.cs.princeton.edu/)** (required)
2. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/MuseGen.git
   cd MuseGen
   ```
3. **Connect your MIDI devices** (optional, for hardware synths)

---

## Project Structure
```
framework/
  song.ck             # Song management, playback, and scheduling
  patch.ck            # MIDI patch/device and preset management
  chords.ck           # Chord progressions and arpeggios
  melody.ck           # Melody and rhythm generation
  midi-events.ck      # MIDI event handling and mapping
  note-collection.ck  # Scales, chords, and note sets
  launch-control.ck   # Launch Control XL integration
music/
  song01.ck, ...      # Example songs and performance scripts
```

---

## Usage
### Running the Main Engine
```bash
chuck framework/song.ck
```

### Running an Example Song
```bash
chuck music/song01.ck
```

### Creating Your Own Song
1. Create a new `.ck` file in the `music/` directory.
2. Import the framework modules you need:
   ```chuck
   @import "../framework/song.ck";
   @import "../framework/chords.ck";
   @import "../framework/melody.ck";
   // ...
   ```
3. Define your parts, patches, and song structure.
4. Start playback with `song.play();`

---

## Example: Creating a Song
```chuck
// Import framework
@import "../framework/song.ck";
@import "../framework/chords.ck";
@import "../framework/melody.ck";

// Define a patch (e.g., for a hardware synth)
RolandS1 synth(1, 5) @=> Patch myPatch;

// Define a chord progression
ChordProgression prog(myPatch, chords, offsets, false, 4, 4, probs);

// Define a melody
Melody melody(myPatch, scale, 4, 4, probabilities);

// Combine into parts
Part parts[2];
prog @=> parts[0];
melody @=> parts[1];

// Create and play the song
Song song(120.0, 60, parts);
song.play();
```

---

## Supported Devices
- HYDRASYNTH EXPLORER
- Roland S-1
- Roland SH-4d
- Behringer RD-6
- V3 Grand Piano (XXL)
- Novation Launch Control XL
- Any General MIDI-compatible device

---

## LaunchControl Interface
MuseGen includes integration with the **Novation Launch Control XL** MIDI controller, allowing for hands-on, real-time control of song parameters, device selection, and live performance features. The LaunchControl interface enables:
- Mapping of faders, knobs, and buttons to song and patch parameters
- Live muting/unmuting of parts
- Real-time tempo and effect adjustments
- Flexible MIDI event handling for custom mappings

To use the LaunchControl interface, ensure your Launch Control XL is connected and recognized by your system. The `framework/launch-control.ck` script provides the main integration logic. You can further customize mappings by editing this file or extending its class.

---

## Extending MuseGen
- **Add new instruments**: Extend the `Patch` class for new hardware or software synths.
- **Custom scales/chords**: Add to `note-collection.ck`.
- **New song forms**: Subclass `Part` or create new performance logic.
- **MIDI mapping**: Modify or extend `midi-events.ck` or `launch-control.ck` for custom control.

---

## Contributing
Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request.

---

## License
MIT
