@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
90 => float BPM;          // Beats per minute
4 => int beatsPerMeasure; // Beats in a measure
60 => int root;           // Middle C as the root note

// Chords
[0,4,7,12] @=> int major[];
Chord majorChord(major, -1);
[0,3,7,12] @=> int minor[];
Chord minorChord(minor, -1);

// Scales
[0, 2, 4, 5, 7, 9, 11, 12] @=> int majorScaleNotes[];
NoteCollection majorScale(majorScaleNotes);

// Chord progression, arpeggiated
[0, -3, 5, 7] @=> int progression[];
[majorChord, minorChord, majorChord, majorChord] @=> Chord chords[];
[0.65] @=> float probabilities1[];
[44, 40, 40, 40] @=> int velocities1[];
ChordProgression prog(chords, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;
// "HYDRASYNTH EXPLORER" => prog.midiDevice;
// 0 => prog.midiChannel;
"S-1 MIDI IN" => prog.midiDevice;
2 => prog.midiChannel;

// Chord Progression
[1.0] @=> float probabilities2[];
[50] @=> int velocities2[];
ChordProgression prog2(chords, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;
"HYDRASYNTH EXPLORER" => prog2.midiDevice;
0 => prog2.midiChannel;
// "S-1 MIDI IN" => prog2.midiDevice;
// 2 => prog2.midiChannel;


// Melody
[1.0, 0.25, 1.0, 0.35] @=> float probabilities[];
[64, 30, 40, 40] @=> int velocities[];
AleatoricMelody melody(majorChord, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;
// "S-1 MIDI IN" => melody.midiDevice;
// 2 => melody.midiChannel;
"HYDRASYNTH EXPLORER" => melody.midiDevice;
0 => melody.midiChannel;

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
DrumMachine drums(drumNotesCollection, 16, 1, probabilities3);
0 => drums.midiChannel;
velocities3 @=> drums.velocities;
"RHYTHM DESIGNER RD-6" => drums.midiDevice;

// [prog, prog2, melody, drums] @=> Part parts[];
// [melody] @=> Part parts[];
// [drums] @=> Part parts[];

Song song(BPM, root, beatsPerMeasure, parts);
song.play();
