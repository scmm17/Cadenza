# MuseGen

MuseGen is a ChucK-based framework for real-time algorithmic music generation and MIDI control.

## Features
- Real-time music and MIDI performance
- Song, chord, and melody generation
- MIDI device and patch management
- Works with hardware synths and controllers

## Quick Start
1. Install [ChucK](https://chuck.cs.princeton.edu/)
2. Clone this repo
3. Run:
   ```bash
   chuck framework/song.ck
   ```

## Structure
- `framework/` — Core engine (song, patch, chords, melody, MIDI)
- `music/` — Example songs and scripts

## Example
```chuck
Song song(120.0, 60, parts);
song.play();
```

## License
MIT
