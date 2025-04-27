@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
40 => float BPM;          // Beats per minute
57 => int root;           // A below Middle C as the root note

// Midi devices
Hydrasynth hydrasynth("F002");
RolandS1 s1(2, 5);

// Chords
Chord majorChord(NoteCollection.majorChordNotes(), -1);
Chord minorChord(NoteCollection.minorChordNotes(), -1);
Chord majorChordH(NoteCollection.majorChordNotes(), 0);
Chord minorChordH(NoteCollection.minorChordNotes(), 0);

// Chord progression, arpeggiated
[5, 7, 0, -3] @=> int progression[];
[majorChordH, majorChordH, majorChordH, minorChordH] @=> Chord chordsH[];
[majorChord, majorChord, majorChord, minorChord] @=> Chord chordsL[];
[0.65, 0, .65, 0, .65, 0, .65, 0, 
 0.65, 0, .30, 0, .65, .35, 1.0, 1.0] @=> float probabilities1[];
[124, 100, 120, 100] @=> int velocities1[];
ChordProgression prog(s1, chordsH, progression, true, 64, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.legato;

// Chord Progression
[1.0, .2, 1.0, .7] @=> float probabilities2[];
[70] @=> int velocities2[];
ChordProgression prog2(hydrasynth, chordsL, progression, true, 32, 4, probabilities2);
velocities2 @=> prog2.velocities;
true => prog2.legato;

// Melody
[1.0, 0.25, 1.0, 0.35] @=> float probabilities[];
[24, 20, 30, 20] @=> int velocities[];
AleatoricMelody melody(hydrasynth, majorChord, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;

// Drums
[1.0] @=> float probabilities3[];
[120, 0, 34, 0, 120, 20, 20, 20] @=> int velocities3[];
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
 DrumMachine.ClosedHat(),
 0,
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat(),
 DrumMachine.Cymbal(), /* DrumMachine.ClosedHat() */

 ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 64, 1, probabilities3);
velocities3 @=> drums.velocities;

[prog,  prog2,  /* melody, */ drums] @=> Part parts[];
// [prog, prog2, melody, drums] @=> Part parts[];

Song song(BPM, root, parts);
song.play();
