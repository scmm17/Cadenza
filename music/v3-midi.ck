@import "../framework/midi-events.ck"
@import "../framework/patch.ck"

V3GrandPiano piano(1, 0, 0);

MidiMapper hydraEvents("HYDRASYNTH EXPLORER", "U2MIDI Pro", 1);
hydraEvents.startEventLoop();
