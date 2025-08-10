@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
55 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Midi devices
//Hydrasynth hydrasynth("F006");
Hydrasynth hydrasynth("A011", 91);
RolandS1 s1(2, 1, 64);
RolandSH4d sh4d_1(1, 3, 4, 99);
RolandSH4d sh4d_2(2, "Channel 2", 64);
RolandSH4d sh4d_3(3, "Channel 3", 64);

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
[1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.5] @=> float probabilities1[];
[124, 70] @=> int velocities1[];
ChordProgression prog(sh4d_1, chordsH, progression, true, 16, 4, probabilities1);
velocities1 @=> prog.velocities;

ChordProgression prog4(s1, chordsH, progression, true, 16, 4, probabilities1);
velocities1 @=> prog4.velocities;

// Chord Progression
[1.0] @=> float probabilities2[];
[100] @=> int velocities2[];
ChordProgression prog2(sh4d_2, chordsL, progression, false, 1, 8, probabilities2);
velocities2 @=> prog2.velocities;
true => prog2.random;
// true => prog2.legato;

// Melody
[1.0, 0.65, 1.0, 0.35] @=> float probabilities[];
[120, 90, 90, 90] @=> int velocities5[];
AleatoricMelody melody(sh4d_3, IV_Low, 32, 4, probabilities);
// true => melody.legato;
velocities5 @=> melody.velocities;

[1.0, .25, 1.0, 0.0] @=> float probabilities5[];
[125, 90, 110, 90] @=> int velocities6[];
AleatoricMelody melody2(hydrasynth, IV_Low, 32, 4, probabilities5);
// true => melody.legato;
velocities6 @=> melody2.velocities;

// Drums
[1.0, 0, 1, 1, 1, 0, 1, 0] @=> float probabilities4[];
[127,0,120,120,127,0,120,0] @=>  int velocities4[];
[
 DrumMachine.BassDrum(),
 0, 
 DrumMachine.HiTom(),
 DrumMachine.HiTom(),
 DrumMachine.BassDrum(),
 0,
 DrumMachine.Clap(),
 0,
 ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
RolandSH4d drumKit(10, "Drums", 70);
DrumMachine drums(drumNotesCollection, 32, 1, probabilities4, drumKit);
velocities4 @=> drums.velocities;

[prog, prog2, prog4, melody, melody2, drums] @=> Part parts1[];
Fragment frag1("frag1", 1, parts1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;
Song song("newton06", BPM, root, frag1, parts1);
song @=> frag1.owningSong;
song.play();
