@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters
60 => float BPM;          // Beats per minute
57 => int root;           // A below Middle C as the root note

// Midi devices
// Hydrasynth hydrasynth("D010");
V3GrandPiano instrument(1, "Voice Kit (page 43)"); 

// Drums
[0.0] @=> float probabilities3[];
[0] @=> int velocities3[];
[
 0,
 ] @=> int drumNotes[];

NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 32, 1, probabilities3, instrument);
velocities3 @=> drums.velocities;

[drums] @=> Part parts1[];
Song song1(BPM, root, parts1);

// Fragment frag1(1, song1);
Fragment frag1(1, song1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;

Song song(BPM, root, frag1);

song.play();
