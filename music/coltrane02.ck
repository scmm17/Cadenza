@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters
120 => float BPM;          // Beats per minute
55 => int root;           // G below Middle C as the root note

// Midi devices
V3GrandPiano bass(1, "Marimba & Xylophon", 116);
V3GrandPiano piano(2, "MOSC (Notch filter 12)", 116);
V3GrandPiano ooh(3, "Theatre Organ Mighty Tower 4", 116);

// Chords
Chord coltrane1(NoteCollection.coltrane1_notes(), 0);
Chord coltrane2(NoteCollection.coltrane2_notes(), 0);
Chord coltrane3(NoteCollection.coltrane3_notes(), 0);
Chord coltrane4(NoteCollection.coltrane4_notes(), 0);
Chord coltrane5(NoteCollection.coltrane5_notes(), 0);
Chord coltrane6(NoteCollection.coltrane6_notes(), 0);
Chord coltrane7(NoteCollection.coltrane7_notes(), 0);

Chord coltrane1_high(NoteCollection.coltrane1_notes(), 1);
Chord coltrane2_high(NoteCollection.coltrane2_notes(), 1);
Chord coltrane3_high(NoteCollection.coltrane3_notes(), 1);
Chord coltrane4_high(NoteCollection.coltrane4_notes(), 1);
Chord coltrane5_high(NoteCollection.coltrane5_notes(), 1);
Chord coltrane6_high(NoteCollection.coltrane6_notes(), 1);
Chord coltrane7_high(NoteCollection.coltrane7_notes(), 1);

Chord coltrane1_bass(NoteCollection.coltrane1_notes(), -1);
Chord coltrane2_bass(NoteCollection.coltrane2_notes(), -1);
Chord coltrane3_bass(NoteCollection.coltrane3_notes(), -1);
Chord coltrane4_bass(NoteCollection.coltrane4_notes(), -1);
Chord coltrane5_bass(NoteCollection.coltrane5_notes(), -1);
Chord coltrane6_bass(NoteCollection.coltrane6_notes(), -1);
Chord coltrane7_bass(NoteCollection.coltrane7_notes(), -1);


// Chord progression, arpeggiated
[coltrane1, coltrane2, coltrane3, coltrane4, coltrane5, coltrane6, coltrane7] @=> Chord coltraneChords[];
[0, 0, 0, 0, 0, 0, 0] @=> int coltraneOffsets[];
true => int coltraneArpeggiated;
[1.0, 0.0, 0.75, 0.75] @=> float coltraneProbabilities[];
[120, 70, 94, 90] @=> int coltraneVelocities[];
ChordProgression coltraneProgression1(piano, coltraneChords, coltraneOffsets, coltraneArpeggiated, 8, 7, coltraneProbabilities);
// true => coltraneProgression1.random;
coltraneVelocities @=> coltraneProgression1.velocities;

[coltrane1_high, coltrane2_high, coltrane3_high, coltrane4_high, coltrane5_high, coltrane6_high, coltrane7_high] @=> Chord coltraneChords3[];
[0, 0, 0, 0, 0, 0, 0] @=> int coltraneOffsets3[];
true => int coltraneArpeggiated3;
[1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0] @=> float coltraneProbabilities3[];
[120, 70, 90, 90] @=> int coltraneVelocities3[];
ChordProgression coltraneProgression3(bass, coltraneChords3, coltraneOffsets3, coltraneArpeggiated3, 16, 7, coltraneProbabilities3);
true => coltraneProgression3.random;
coltraneVelocities3 @=> coltraneProgression3.velocities;

[coltrane1_bass, coltrane2_bass, coltrane3_bass, coltrane4_bass, coltrane5_bass, coltrane6_bass, coltrane7_bass] @=> Chord coltraneChords2[];
[0, 0, 0, 0, 0, 0, 0] @=> int coltraneOffsets2[];
false => int coltraneArpeggiated2;
[1.0] @=> float coltraneProbabilities2[];
[100, 100, 100, 100, 100, 100, 100] @=> int coltraneVelocities2[];
ChordProgression coltraneProgression2(ooh, coltraneChords2, coltraneOffsets2, coltraneArpeggiated2, 1, 7, coltraneProbabilities2);
coltraneVelocities2 @=> coltraneProgression2.velocities;

// Drums
[1.0] @=> float probabilities3[];
[127, 120, 134, 120, 94, 120, 120, 120] @=> int velocities3[];
[
 DrumMachine.BassDrum(),
 0,
 0,
 0,
 DrumMachine.SnareDrum(),
 0,
 0,
 0,
 DrumMachine.BassDrum(),
 0,
 0,
 0,
 DrumMachine.SnareDrum(),
 0,
 DrumMachine.SnareDrum(),
 0,
  ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
RolandSH4d drumKit(10, "Drums", 70);
DrumMachine drums(drumNotesCollection, 16, 1, probabilities3, drumKit);
velocities3 @=> drums.velocities;

[coltraneProgression1, coltraneProgression2, coltraneProgression3, drums] @=> Part parts1[];
// Fragment frag1(1, song1);
Fragment frag1("frag1", 1, parts1);

FragmentTransition ft1(frag1, 1.0);

[ft1] @=> frag1.nextFragments;

Song song("coltrane02", BPM, root, frag1, parts1);


song.play();