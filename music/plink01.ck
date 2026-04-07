@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
90 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Midi devices
RolandS1 s1(2, 1, 64);
Hydrasynth hydrasynth("default", 64);
BehringerRD6 rd6(94);

// Chords
[0,4,7,12] @=> int major[];
NoteCollection majorNotes(major);
Chord majorChord(majorNotes, -1);
[0,3,7,12] @=> int minor[];
NoteCollection minorNotes(minor);
Chord minorChord(minorNotes, -1);

// Scales
[0, 2, 4, 5, 7, 9, 11, 12] @=> int majorScaleNotes[];
NoteCollection majorScale(majorScaleNotes);

// Chord progression, arpeggiated
[0, -3, 5, 7] @=> int progression[];
[majorChord, minorChord, majorChord, majorChord] @=> Chord chords[];
[0.65] @=> float probabilities1[];
[44, 40, 40, 40] @=> int velocities1[];
ChordProgression prog(s1, chords, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;

// Chord Progression
[1.0] @=> float probabilities2[];
[50] @=> int velocities2[];
ChordProgression prog2(hydrasynth, chords, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;


// Melody
[1.0, 0.25, 1.0, 0.35] @=> float probabilities[];
[64, 30, 40, 40] @=> int velocities[];
AleatoricMelody melody(hydrasynth, majorChord, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;

// Drums
[1.0] @=> float probabilities3[];
[94, 0, 34, 0, 94, 20, 20, 20] @=> int velocities3[];
[DrumMachine.BassDrum(), 
 0, 
 DrumMachine.SnareDrum(),
 0,
 DrumMachine.BassDrum(),
 0, 
 DrumMachine.Clap(),
 DrumMachine.Clap(),
 DrumMachine.BassDrum(), 
 0, 
 DrumMachine.SnareDrum(),
 0,
 DrumMachine.BassDrum(),
 DrumMachine.ClosedHat(), 
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat(),

 ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 16, 1, probabilities3, rd6);
velocities3 @=> drums.velocities;

[prog, prog2, melody, drums] @=> Part parts[];
// [melody] @=> Part parts[];
// [drums] @=> Part parts[];

Fragment frag("main", 1, parts);
Song song("plink01", BPM, root, frag, parts);
song.play();
