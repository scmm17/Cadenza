@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
65 => float BPM;          // Beats per minute
57 => int root;           // A below Middle C as the root note

// Midi devices
// Hydrasynth hydrasynth("F005");
Hydrasynth hydrasynth("A011");
RolandS1 s1(2, 6);

// Chords
Chord majorChordL(NoteCollection.majorChordNotes(), -1);
Chord minorChordL(NoteCollection.minorChordNotes(), -1);
Chord majorChordH(NoteCollection.majorChordNotes(), 0);
Chord minorChordH(NoteCollection.minorChordNotes(), 0);

// Chord progression, arpeggiated
[5, 7, 0, -3] @=> int progression[];
[majorChordH, majorChordH, majorChordH, minorChordH] @=> Chord chordsH[];
[majorChordL, majorChordL, majorChordL, minorChordL] @=> Chord chordsL[];
[0.65, 0, .65, 0, .65, 0, .65, 0, 
 0.65, 0, .30, 0, .65, .35, 1.0, 1.0] @=> float probabilities1[];
[124, 100, 120, 100] @=> int velocities1[];
ChordProgression prog(hydrasynth, chordsH, progression, true, 32, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.legato;

// Chord Progression
[1.0, .2, 1.0, .7] @=> float probabilities2[];
[110] @=> int velocities2[];
ChordProgression prog2(s1, chordsL, progression, true, 16, 4, probabilities2);
velocities2 @=> prog2.velocities;
// true => prog2.legato;

// Chord Progression
[1.0, .2, 1.0, .7] @=> float probabilities3[];
[70] @=> int velocities3[];
ChordProgression prog3(hydrasynth, chordsL, progression, true, 16, 4, probabilities3);
velocities3 @=> prog3.velocities;
// true => prog2.legato;

// Melody
[1.0, 0.25, 1.0, 0.35] @=> float probabilities[];
[24, 20, 30, 20] @=> int velocities[];
AleatoricMelody melody(hydrasynth, majorChordL, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;

// Drums
[1.0] @=> float probabilities4[];
[120, 0, 34, 0, 120, 20, 20, 20] @=> int velocities4[];
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
RolandSH4d drumKit(10, "SH-4d SDrums");
DrumMachine drums(drumNotesCollection, 32, 1, probabilities4, drumKit);
velocities4 @=> drums.velocities;

[prog, prog2,  prog3, /* melody, */ drums] @=> Part parts[];
// [prog, prog2, melody, drums] @=> Part parts[];

Song song(BPM, root, parts);
song.play();
