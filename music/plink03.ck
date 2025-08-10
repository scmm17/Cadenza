@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
60 => float BPM;          // Beats per minute
57 => int root;           // A below Middle C as the root note

// Midi devices
Hydrasynth hydrasynth("D048");
RolandS1 s1(2, 1);

// Chords
Chord majorChord(NoteCollection.majorChordNotes(), -1);
Chord minorChord(NoteCollection.minorChordNotes(), -1);

// Chord progression, arpeggiated
[0, -3, 5, 7] @=> int progression[];
[majorChord, minorChord, majorChord, majorChord] @=> Chord chords[];
[0.65, 0, .65, 0, .65, 0, .65, 0, 
 0.65, 0, .30, 0, .65, .35, 1.0, 1.0] @=> float probabilities1[];
[124, 100, 120, 100] @=> int velocities1[];
ChordProgression prog(s1, chords, progression, true, 32, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.legato;

// Chord Progression
[1.0] @=> float probabilities2[];
[50] @=> int velocities2[];
ChordProgression prog2(hydrasynth, chords, progression, true, 4, 4, probabilities2);
velocities2 @=> prog2.velocities;

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
DrumMachine drums(drumNotesCollection, 32, 1, probabilities3);
velocities3 @=> drums.velocities;

[prog, prog2, melody, drums] @=> Part parts[];

Song song("plink03", BPM, root, parts);
song.play();
