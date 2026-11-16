// Cadenza Framework Umbrella
// Purpose: Single-import entry point for all Cadenza ChucK modules in topological order.
// Imports: all framework core, device, composition, song, and control modules.
// Imported by: music/*.ck, test/*.ck

// 1. Core utilities & constants
@import "core/constants.ck"
@import "core/gui-link.ck"
@import "core/yaml.ck"

// 2. MIDI devices & presets
@import "devices/presets/preset.ck"
@import "devices/presets/preset-collection.ck"
@import "devices/presets/generated/hydrasynth-presets.ck"
@import "devices/presets/generated/sh4d-presets.ck"
@import "devices/presets/generated/v3-presets.ck"
@import "devices/presets/generated/moog-banks.ck"
@import "devices/presets/generated/synth-table.ck"
@import "devices/patch.ck"
@import "devices/hydrasynth.ck"
@import "devices/moog-messenger.ck"
@import "devices/roland-s1.ck"
@import "devices/roland-sh4d.ck"
@import "devices/behringer-rd6.ck"
@import "devices/v3-grand-piano.ck"
@import "devices/synth-registry.ck"

// 3. Composition primitives
@import "composition/song-context.ck"
@import "composition/part.ck"
@import "composition/fragment.ck"
@import "composition/note-collection.ck"
@import "composition/lsystem-notes.ck"
@import "composition/chords.ck"
@import "composition/chord-progression.ck"
@import "composition/melody.ck"
@import "composition/drum-machine.ck"

// 4. Control & display
@import "control/midi-mapper.ck"
@import "control/terminal-display.ck"
@import "control/state-broadcaster.ck"
@import "control/launch-control.ck"
@import "control/keyboard-control.ck"
@import "control/osc-control.ck"

// 5. Song orchestrator
@import "song/mixer.ck"
@import "song/patch-set-store.ck"
@import "song/song.ck"
