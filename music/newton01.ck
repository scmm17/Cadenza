@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
85 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Midi devices
// Hydrasynth hydrasynth("F005");
Hydrasynth hydrasynth("F006", 91);
RolandS1 s1(2, 7, 64);

// Chords
Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);
Chord I_High(NoteCollection.I_notes(), 0);
Chord IV_High(NoteCollection.IV_notes(), 0);
Chord bVII_High(NoteCollection.bVII_notes(), 0);

// Chord progression, arpeggiated
[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chordsL[];
[I_High, IV_High, bVII_High, IV_High] @=> Chord chordsH[];
// [1.0, 1.0, 0.0, 0.0, .65, .25,] @=> float probabilities1[];
[1.0] @=> float probabilities1[];
[124, 100, 100] @=> int velocities1[];
ChordProgression prog(s1, chordsL, progression, true, 12, 4, probabilities1);
velocities1 @=> prog.velocities;
// true => prog.legato;

// Chord Progression
[1.0] @=> float probabilities2[];
[100] @=> int velocities2[];
ChordProgression prog2(hydrasynth, chordsL, progression, false, 1, 4, probabilities2);
velocities2 @=> prog2.velocities;
// true => prog2.legato;

// Chord Progression
[1.0, .2, 1.0, .7] @=> float probabilities3[];
[70] @=> int velocities3[];
ChordProgression prog3(hydrasynth, chordsL, progression, true, 16, 4, probabilities3);
velocities3 @=> prog3.velocities;
// true => prog2.legato;

// Drums
[1.0] @=> float probabilities4[];
[120] @=> int velocities4[];
[
 DrumMachine.BassDrum(),
 DrumMachine.Clap(),
 DrumMachine.Clap(),
] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 6, 1, probabilities4);
velocities4 @=> drums.velocities;

[prog, prog2, prog3, drums] @=> Part parts1[];
Fragment frag1("frag1", 1, parts1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;
Song song(BPM, root, frag1, parts1);
song @=> frag1.owningSong;
song.play();
