@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters
120 => float BPM;          // Beats per minute
55 => int root;           // G below Middle C as the root note

// Midi devices
RolandSH4d sh4d(1, 2, 8);
V3GrandPiano piano(1, "XBass 1");
V3GrandPiano bass(2, "Mute Guitar");
V3GrandPiano ooh(3, "Theatre Organ Mighty Tower 4");

// Chords
Chord trane1(NoteCollection.trane1_notes(), 0);
Chord trane2(NoteCollection.trane2_notes(), 0);
Chord trane3(NoteCollection.trane3_notes(), 0);
Chord trane4(NoteCollection.trane4_notes(), 0);
Chord trane5(NoteCollection.trane5_notes(), 0);

Chord trane1_high(NoteCollection.trane1_notes(), 1);
Chord trane2_high(NoteCollection.trane2_notes(), 1);
Chord trane3_high(NoteCollection.trane3_notes(), 1);
Chord trane4_high(NoteCollection.trane4_notes(), 1);
Chord trane5_high(NoteCollection.trane5_notes(), 1);

Chord trane1_bass(NoteCollection.trane1_notes(), -1);
Chord trane2_bass(NoteCollection.trane2_notes(), -1);
Chord trane3_bass(NoteCollection.trane3_notes(), -1);
Chord trane4_bass(NoteCollection.trane4_notes(), -1);
Chord trane5_bass(NoteCollection.trane5_notes(), -1);


// Chord progression, arpeggiated
[trane1, trane2, trane3, trane4, trane5] @=> Chord coltraneChords[];
[0, 0, 0, 0, 0] @=> int coltraneOffsets[];
true => int coltraneArpeggiated;
[1.0, 0.0, 0.75, 0.75] @=> float coltraneProbabilities[];
[120, 70, 94, 90] @=> int coltraneVelocities[];
ChordProgression coltraneProgression1(piano, coltraneChords, coltraneOffsets, coltraneArpeggiated, 8, 5, coltraneProbabilities);
// true => coltraneProgression1.random;
0.3 => coltraneProgression1.mutateProbabilityRange;
coltraneVelocities @=> coltraneProgression1.velocities;

[trane1_high, trane2_high, trane3_high, trane4_high, trane5_high] @=> Chord coltraneChords3[];
[0, 0, 0, 0, 0] @=> int coltraneOffsets3[];
true => int coltraneArpeggiated3;
[1.0, 0.0, 0.0, 0.0, 1.0, 0.75, 0.75, 1.0] @=> float coltraneProbabilities3[];
[120, 70, 90, 90] @=> int coltraneVelocities3[];
ChordProgression coltraneProgression3(bass, coltraneChords3, coltraneOffsets3, coltraneArpeggiated3, 16, 5, coltraneProbabilities3);
0.3 => coltraneProgression3.mutateProbabilityRange;
true => coltraneProgression3.random;
coltraneVelocities3 @=> coltraneProgression3.velocities;

[trane1_bass, trane2_bass, trane3_bass, trane4_bass, trane5_bass] @=> Chord coltraneChords2[];
[0, 0, 0, 0, 0] @=> int coltraneOffsets2[];
false => int coltraneArpeggiated2;
[1.0] @=> float coltraneProbabilities2[];
[100, 100, 100, 100, 100, 100, 100] @=> int coltraneVelocities2[];
ChordProgression coltraneProgression2(ooh, coltraneChords2, coltraneOffsets2, coltraneArpeggiated2, 1, 5, coltraneProbabilities2);
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
RolandSH4d drumKit(10, "SH-4d SDrums");
DrumMachine drums(drumNotesCollection, 16, 1, probabilities3, drumKit);
velocities3 @=> drums.velocities;

[coltraneProgression1, coltraneProgression2, coltraneProgression3, drums] @=> Part parts1[];
// Fragment frag1(1, song1);
Fragment frag1("frag1", 1, parts1);

FragmentTransition ft1(frag1, 1.0);

[ft1] @=> frag1.nextFragments;

Song song(BPM, root, frag1, parts1);
song @=> frag1.owningSong;

song.play();