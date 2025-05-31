# MuseGen

MuseGen is a powerful music generation and performance framework built with ChucK, designed for creating dynamic, real-time musical compositions and MIDI control.

## Features

- Real-time music generation and performance
- MIDI device control and routing
- Rich library of instruments and patches including:
  - Virtual instruments (V3 Grand Piano, Roland S-1, Roland SH-4d, Hydrasynth)
  - Synthesizer controls
  - Drum machines
  - Various MIDI-controlled instruments
- Dynamic song structure management
- Chord progression and melody generation
- Support for multiple parts and layers
- Launch Control XL integration

## Prerequisites

- [ChucK](https://chuck.cs.princeton.edu/) programming language
- MIDI-compatible devices (optional but recommended)
- Supported hardware:
  - HYDRASYNTH EXPLORER
  - Roland S-1
  - Roland SH-4d
  - Behringer RD-6
  - Launch Control XL (for control surface)

## Project Structure

```
framework/
├── song.ck          # Core song management and playback
├── patch.ck         # MIDI patch and device management
├── chords.ck        # Chord progression handling
├── melody.ck        # Melody generation
├── midi-events.ck   # MIDI event handling
├── note-collection.ck # Note and scale management
```

## Getting Started

1. Install ChucK from the [official website](https://chuck.cs.princeton.edu/)
2. Clone this repository
3. Connect your MIDI devices (if using hardware instruments)
4. Run the main program:
   ```bash
   chuck song.ck
   ```

## Usage

The framework provides several classes for music generation and control:

### Song Management
```chuck
Song song(120.0, 60, parts); // Create a new song at 120 BPM, root note C
song.play();                 // Start playback
```

### Chord Progressions
```chuck
ChordProgression progression(patch, chords, offsets, false, 4, 4, probs);
```

### Melody Generation
```chuck
Melody melody(patch, scale, notesPerMeasure, numMeasures, probabilities);
```

### MIDI Device Control
```chuck
Patch device("DEVICE_NAME", channel);
device.noteOn(60, 100, duration); // Play middle C
```

## Supported Instruments

The framework includes extensive support for various instruments and presets:

- V3 Grand Piano (127+ presets)
- Synthesizer sounds
- Orchestral instruments
- Electronic instruments
- Drum kits and percussion
- String ensembles
- Wind instruments
- Brass sections

## Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [ChucK](https://chuck.cs.princeton.edu/)
- Special thanks to the ChucK development team
- Inspired by various MIDI and synthesis frameworks
