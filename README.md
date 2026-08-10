<img width="3840" height="2160" alt="Screenshot 2026-08-09 at 7 01 00 PM" src="https://github.com/user-attachments/assets/2f1411c5-18f5-48a1-94b1-78927f249f79" />
# Cadenza

Cadenza is a modular framework for real-time algorithmic music generation and MIDI control, built entirely with the ChucK programming language. It is designed for composers, performers, and researchers working with generative music, live coding, and external MIDI synthesis.

## Core Framework

Cadenza provides a rich, extensible architecture to structure generative music:

- **Songs and Fragments**: Organize performances into discrete "Songs" containing multiple "Fragments" (sections), allowing for dynamic arrangements and seamless transitions.
- **Parts and Instruments**: Assign distinct musical parts (Melodies, Progressions, Drum Machines) to specific hardware or virtual MIDI devices.
- **Algorithmic Composition**: Leverage built-in systems for chord progressions, arpeggios, probabilistic rhythm generation, and scale-based melody generation.
- **Hardware Integration**: Centralize MIDI device management with robust support for hardware synths (e.g., Hydrasynth Explorer, Roland S-1, Roland SH-4d) including configuration caching via YAML.

## Live Dashboard (GUI)

Cadenza features a powerful, web-based Live Dashboard that syncs directly with the ChucK runtime. The GUI bridges ChucK OSC messages through a Node.js WebSocket server to provide real-time visualization and control.

Features include:
- **Scrolling Piano Roll**: A visual stream of all active notes separated by instrument.
- **Device Management**: Live control over volumes, panning, and synthesizer presets across all configured MIDI channels.
- **Playback Controls**: Global tempo (BPM) adjustments, mute/solo modes, and playback transport controls.

## Installation & Setup

1. **Install ChucK**: Download from the [official ChucK website](https://chuck.cs.princeton.edu/).
2. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/Cadenza.git
   cd Cadenza
   ```
3. **Start the GUI Server**:
   ```bash
   cd gui
   npm install
   npm start
   ```
4. **Open the Dashboard**: Navigate to `http://localhost:3000` in your web browser.
5. **Run a Song**: Use the built-in file picker by pressing `o` or clicking the folder button in the toolbar, in the Live Dashboard to select and play any performance script from the `music/` directory. You do not need to run `chuck` manually from the command line.

## Project Structure

- `framework/`: The core ChucK libraries (Songs, Patches, Melodies, Chords, MIDI handling, YAML parser).
- `music/`: The composition library containing runnable performance scripts and tracks.
- `gui/`: The Node.js WebSocket bridge and front-end Dashboard interface.

## Extending Cadenza

Cadenza is designed to be easily extensible. You can define new MIDI instrument configurations by extending the `Patch` class, add custom scales and chords to the `NoteCollection`, or script entirely new algorithmic generation logic for your performances.

## License

MIT
