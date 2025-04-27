// MidiIn min;
// MidiMsg msg;

// // open midi receiver, exit on fail
// if ( !min.open("HYDRASYNTH EXPLORER") ) me.exit(); 

// <<< "Opened!" >>>;

// while( true )
// {
//     // wait on midi event
//     min => now;

//     // receive midimsg(s)
//     while( min.recv( msg ) )
//     {
//         // print content
//     	<<< msg.data1, msg.data2, msg.data3 >>>;
//     }
// }

@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters
50 => float BPM;          // Beats per minute
4 => int beatsPerMeasure; // Beats in a measure
57 => int root;           // A below Middle C as the root note

// Midi devices
// Hydrasynth hydrasynth("D010");
Hydrasynth hydrasynth("D035");
RolandS1 s1(1, 13);
RolandSH4d sh4d_1(1, 3, 10);
RolandSH4d sh4d_2(2);

// Chords
Chord majorChord(NoteCollection.majorChordNotes(), -1);
Chord minorChord(NoteCollection.minorChordNotes(), -1);

Chord majorChordH(NoteCollection.majorChordNotes(), 0);
Chord minorChordH(NoteCollection.minorChordNotes(), 0);

// Chord progression, arpeggiated
[0, -3, 5, 7] @=> int progression[];
[majorChord, minorChord, majorChord, majorChord] @=> Chord chords1[];
[0.65, 0, .65, 0, .65, 0, .65, 0, 
 0.65, 0, .30, 0, .65, .35, 1.0, 1.0] @=> float probabilities1[];
[124, 100, 120, 100] @=> int velocities1[];
ChordProgression prog(s1, chords1, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.random;

[majorChordH, minorChordH, majorChordH, majorChordH] @=> Chord chords2[];
ChordProgression prog3(s1, chords2, progression, true, 32, 4, probabilities1);
velocities1 @=> prog3.velocities;
true => prog3.random;

// Chord Progression
[1.0] @=> float probabilities2[];
[75] @=> int velocities2[];
ChordProgression prog2(hydrasynth, chords1, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;

[127] @=> int velocities4[];
ChordProgression prog5(sh4d_2, chords1, progression, true, 16, 4, probabilities2);
velocities4 @=> prog5.velocities;

// Melody
[1.0, 0.15, 0.25, 0.15] @=> float probabilities[];
[124, 120, 130, 120] @=> int velocities[];
AleatoricMelody melody(sh4d_1, majorChordH, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;

ChordProgression prog4(sh4d_1, chords2, progression, true, 32, 4, probabilities);
velocities @=> prog4.velocities;
true => prog4.random;


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
 DrumMachine.Clap(),
 0,
 DrumMachine.Clap(),
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
 DrumMachine.ClosedHat(),
 0,
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat(),
 DrumMachine.ClosedHat()

 ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
RolandSH4d drumKit(10);
DrumMachine drums(drumNotesCollection, 32, 1, probabilities3, drumKit);
velocities3 @=> drums.velocities;

[prog, prog2, prog3, prog4, /* melody, */ drums] @=> Part parts[];

[prog2] @=> Part parts1[];
Song song1(BPM, root, beatsPerMeasure, parts1);

[prog2, prog5, drums] @=> Part parts2[];
Song song2(BPM, root, beatsPerMeasure, parts2);

[prog2, prog3, drums] @=> Part parts3[];
Song song3(BPM, root, beatsPerMeasure, parts3);

[prog2, prog3, prog4, prog, drums] @=> Part parts4[];
Song song4(BPM, root, beatsPerMeasure, parts4);

[prog4, prog5, melody, drums] @=> Part parts5[];
Song song5(BPM, root, beatsPerMeasure, parts5);

[prog, prog2, prog3, prog4, prog5, melody, drums] @=> Part parts6[];
Song song6(BPM, root, beatsPerMeasure, parts6);

// Fragment frag1(1, song1);
Fragment frag1(1, song1);
Fragment frag2(1, song2);
Fragment frag3(1, song3);
Fragment frag4(1, song4);
Fragment frag5(1, song5);
Fragment frag6(3, song6);
Fragment frag7(1, song4);

FragmentTransition ft1(frag1, 1.0);
FragmentTransition ft2(frag2, 1.0);

FragmentTransition ft3_1(frag3, 0.75);
FragmentTransition ft3_2(frag2, 0.15);
FragmentTransition ft3_3(frag4, 0.10);

FragmentTransition ft4_1(frag4, 0.6);
FragmentTransition ft4_2(frag3, 0.3);
FragmentTransition ft4_3(frag5, 0.1);

FragmentTransition ft5_1(frag5, 0.6);
FragmentTransition ft5_2(frag4, 0.2);
FragmentTransition ft5_3(frag6, 0.2);

FragmentTransition ft6_1(frag6, 0.55);
FragmentTransition ft6_2(frag5, 0.20);
FragmentTransition ft6_3(frag4, 0.30);

FragmentTransition ft7_1(frag7, 0.75);
FragmentTransition ft7_2(frag2, 0.25);

[ft2] @=> frag1.nextFragments;
[ft3_1, ft3_2, ft3_3] @=> frag2.nextFragments;
[ft4_1, ft4_2, ft4_3] @=> frag3.nextFragments;
[ft5_1, ft5_2, ft5_3] @=> frag4.nextFragments;
[ft6_1, ft6_2, ft6_3] @=> frag5.nextFragments;
[ft7_1, ft7_2] @=> frag6.nextFragments;
[ft1] @=> frag7.nextFragments;


// Song song(BPM, root, beatsPerMeasure, parts);
// true => song.forever;
// song.play();


Song song(BPM, root, beatsPerMeasure, frag1);
song.play();
