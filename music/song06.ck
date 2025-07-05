@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters
60 => float BPM;          // Beats per minute
57 => int root;           // A below Middle C as the root note

// Midi devices
V3GrandPiano piano(1, "Marimba", 116);
V3GrandPiano bass(2, "Vibraphone", 116);
V3GrandPiano ooh(3, "Classic Choir Aah Filter", 116);

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
[100, 80, 100, 70] @=> int velocities1[];
ChordProgression prog(bass, chords1, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.random;

[majorChordH, minorChordH, majorChordH, majorChordH] @=> Chord chords2[];
ChordProgression prog3(bass, chords2, progression, true, 32, 4, probabilities1);
velocities1 @=> prog3.velocities;
true => prog3.random;

// Chord Progression
[1.0] @=> float probabilities2[];
[55] @=> int velocities2[];
ChordProgression prog2(ooh, chords1, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;

[60] @=> int velocities4[];
ChordProgression prog5(piano, chords1, progression, true, 16, 4, probabilities2);
velocities4 @=> prog5.velocities;

// Melody
[1.0, 0.15, 0.65, 0.35] @=> float probabilities[];
[110, 75, 75, 100] @=> int velocities[];
AleatoricMelody melody(piano, majorChordH, 16, 4, probabilities);
// true => melody.legato;
velocities @=> melody.velocities;

ChordProgression prog4(piano, chords2, progression, true, 32, 4, probabilities);
velocities @=> prog4.velocities;
true => prog4.random;
0.3 => prog4.mutateProbabilityRange;


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
RolandSH4d drumKit(10, "SH-4d SDrums", 38);
DrumMachine drums(drumNotesCollection, 32, 1, probabilities3, drumKit);
velocities3 @=> drums.velocities;

[prog2] @=> Part parts1[];
[prog2, prog5, drums] @=> Part parts2[];
[prog2, prog3, drums] @=> Part parts3[];
[prog2, prog3, prog4, prog, drums] @=> Part parts4[];
[prog4, prog5, melody, drums] @=> Part parts5[];
[prog, prog2, prog3, prog4, prog5, melody, drums] @=> Part parts6[];

// Fragment frag1(1, song1);
Fragment frag1("frag1", 1, parts1);
Fragment frag2("frag2", 1, parts2);
Fragment frag3("frag3", 1, parts3);
Fragment frag4("frag4", 1, parts4);
Fragment frag5("frag5", 1, parts5);
Fragment frag6("frag6", 3, parts6);
Fragment frag7("frag7", 1, parts4);

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

Song song(BPM, root, frag1, parts6);
song @=> frag1.owningSong;
song @=> frag2.owningSong;
song @=> frag3.owningSong;
song @=> frag4.owningSong;
song @=> frag5.owningSong;
song @=> frag6.owningSong;
song @=> frag7.owningSong;

song.play();