@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
60 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Midi devices
//Hydrasynth hydrasynth("A026", 127);
// Hydrasynth hydrasynth("A026", 127);
RolandS1 s1(2, 10, 64);
RolandSH4d sh4d_1(1, 3, 1, 94);
RolandSH4d sh4d_2(2, "Channel 2", 85);
RolandSH4d sh4d_3(3, "Channel 3", 120);
RolandSH4d sh4d_4(4, "Channel 4", 100);
RolandSH4d drumKit(10, "Drums", 43);

// Chords
Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);
Chord I_High(NoteCollection.I_notes(), 0);
Chord IV_High(NoteCollection.IV_notes(), 0);
Chord bVII_High(NoteCollection.bVII_notes(), 0);
Chord majorChord(NoteCollection.majorChordNotes(), -1);

// Mixolydian Chord
Chord mixolydianChord(NoteCollection.mixolydian_notes(), 2);
Chord mixolydianChord_Low(NoteCollection.mixolydian_notes(), 0);

[0] @=> int mixolydian[];
[mixolydianChord] @=> Chord mixolydianChords[];
[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 
 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 
 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0,
 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0] 
@=> float probabilitiesMixol[];
[127] @=> int velocitiesMixol[];
ChordProgression mixol(sh4d_4, mixolydianChords, mixolydian, true, 16, 4, probabilitiesMixol);
velocitiesMixol @=> mixol.velocities;
true => mixol.useMelody;
[7, 14, 7, 14, 13, 12, 11, 10, 11, 12, 13, 14] @=> mixol.melody;
[ 0.5, 0.0, 0.0, 0.0,  0.0, 0.0, 0.5, 0.0, 
  0.5, 0.0, 0.0, 0.0,  0.0, 0.0, 0.5, 0.0, 
  0.5, 0.0, 0.0, 0.5, -1.0, 0.0, 0.5, 0.0,
 -1.0, 0.0, 0.5, 0.0,  0.5, 0.0, 0.5, 0.0] 
@=> mixol.durations;
// 0.4 => mixol.mutateProbabilityRange;

// Chord progression, arpeggiated
[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chordsL[];
[I_High, IV_High, bVII_High, IV_High] @=> Chord chordsH[];
[1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.5] @=> float probabilities1[];
[124, 70] @=> int velocities1[];
ChordProgression prog(sh4d_1, chordsH, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;

ChordProgression prog4(s1, chordsH, progression, true, 16, 4, probabilities1);
velocities1 @=> prog4.velocities;

// Chord Progression
[1.0] @=> float probabilities2[];
[100] @=> int velocities2[];
ChordProgression prog2(sh4d_2, chordsL, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;

// Chord Progression
// [1.0, .2, 1.0, .7] @=> float probabilities3[];
// [100] @=> int velocities3[];
// ChordProgression prog3(hydrasynth, chordsL, progression, true, 16, 4, probabilities3);
// velocities3 @=> prog3.velocities;

// Melody
[1.0 , 0.3 /*, 1.0, 0.35*/] @=> float probabilities[];
[120, 90, 90, 90] @=> int velocities5[];
LSystemNotes lSystemNotes(NoteCollection.mixolydian_octave_notes(), "l-system01.yaml");
SequentialMelody melody(sh4d_3, lSystemNotes, 32, 4, probabilities);
velocities5 @=> melody.velocities;
// 0.4 => melody.mutateProbabilityRange;
true => melody.useAllNotes;

[1.0, 1.0, 0.0, 0.25] @=> float probabilities5[];
[40, 40, 60, 70] @=> int velocities6[];
AleatoricMelody melody2(sh4d_4, majorChord, 16, 4, probabilities5);
velocities6 @=> melody2.velocities;


// Drums
[1.0, 0, 1, 0, 1, 0, 1, 1] @=> float probabilities4[];
[120] @=>  int velocities4[];
[
 DrumMachine.BassDrum(),
 0, 
 DrumMachine.Clap(),
 0,
 DrumMachine.BassDrum(),
 0,
 DrumMachine.Clap(),
 DrumMachine.Clap(),
] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 16, 1, probabilities4, drumKit);
velocities4 @=> drums.velocities;

[prog, prog2, prog4, melody, melody2, drums, mixol] @=> Part allParts[];

[prog] @=> Part parts1[];
[prog, prog4] @=> Part parts2[];
[prog, prog4, drums] @=> Part parts3[];
[prog, prog4, prog2, drums] @=> Part parts4[];
[prog, prog2, prog4, melody, melody2, drums] @=> Part parts5[];
[prog, prog2, prog4, melody, melody2, mixol, drums] @=> Part parts6[];
[prog4, prog, melody2, drums] @=> Part parts7[];

Fragment frag1("frag1", 1, parts1);
Fragment frag2("frag2", 1, parts2);
Fragment frag3("frag3", 1, parts3);
Fragment frag4("frag4", 1, parts4);
Fragment frag5("frag5", 1, parts5);
Fragment frag6("frag6", 3, parts6);
Fragment frag7("frag7", 1, parts7);

FragmentTransition ft1(frag2, 1.0);
FragmentTransition ft2(frag3, 1.0);
FragmentTransition ft3(frag4, 1.0);
FragmentTransition ft4(frag5, 1.0);
FragmentTransition ft5(frag6, 1.0);
FragmentTransition ft6(frag7, 1.0);
FragmentTransition ft7(frag1, 1.0);

[ft1] @=> frag1.nextFragments;
[ft2] @=> frag2.nextFragments;
[ft3] @=> frag3.nextFragments;
[ft4] @=> frag4.nextFragments;
[ft5] @=> frag5.nextFragments;
[ft6] @=> frag6.nextFragments;
[ft7] @=> frag7.nextFragments;

Song song("bomp01", BPM, root, frag1, allParts);

song.play();
