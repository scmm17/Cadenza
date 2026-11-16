# Cadenza Documentation

Welcome to the Cadenza contributor documentation.

## Sections

- **[Creating Music](creating-music.md)** — For composers and performers who want to write new songs using the Cadenza framework. Covers instruments, note collections, parts, rhythm, and song structure.

- **[The Framework](framework.md)** — For developers who want to extend the framework itself. Covers the internal architecture, class reference, OSC data flow, and how to add new device types or musical algorithms.

- **[Architecture Refactoring Overview](refactoring.md)** — High-level summary of how `framework/` and `gui/` are organized after splitting up the monolithic files, and how to run the automated checks.

- **[OSC & WebSocket Protocol](osc-protocol.md)** — Wire-protocol reference for all `/cadenza/*` OSC messages (ports `9449` and `9450`) and WebSocket commands between ChucK, the Node.js bridge, and the browser dashboard.
