@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
40 => float BPM;          // Beats per minute
56 => int root;

// Midi devices
//Hydrasynth hydrasynth("F006");
Hydrasynth hydrasynth("B016", 14);
RolandS1 s1(1, 1, 127);
RolandSH4d sh4d_1(1, 3, 11, 127);
RolandSH4d sh4d_2(2, "Channel 2", 30);
RolandSH4d sh4d_3(3, "Channel 3", 49);
RolandSH4d sh4d_4(4, "Channel 4", 64);
// V3GrandPiano marimba(1, "Harp");
V3GrandPiano marimba(1, "OB & Noise", 60);
// RolandSH4d sh4d_3(3, "Channel 3");

// Chords
Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);
Chord I_LowLow(NoteCollection.I_notes(), -3);
Chord IV_LowLow(NoteCollection.IV_notes(), -3);
Chord bVII_LowLow(NoteCollection.bVII_notes(), -3);
Chord I_High(NoteCollection.I_notes(), 0);
Chord IV_High(NoteCollection.IV_notes(), 0);
Chord bVII_High(NoteCollection.bVII_notes(), 0);


// Chord progression, arpeggiated
[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chordsL[];
[I_LowLow, IV_LowLow, bVII_LowLow, IV_LowLow] @=> Chord chordsLL[];
[I_High, IV_High, bVII_High, IV_High] @=> Chord chordsH[];

[1.0] @=> float probabilities1[];
[124] @=> int velocities1[];
ChordProgression prog1(hydrasynth, chordsH, progression, false, 1, 4, probabilities1);
// 0.4 => prog1.mutateProbabilityRange;
// true => prog1.legato;
velocities1 @=> prog1.velocities;


[0.25] @=> float probabilities2[];
[124, 115] @=> int velocities2[];
ChordProgression prog2(sh4d_1, chordsLL, progression, true, 2, 4, probabilities2);
true => prog2.random;
velocities2 @=> prog2.velocities;
// 0.3 => prog2.mutateProbabilityRange;

// Chord Progression
[1.0, 0.5, .25, .25] @=> float probabilities3[];
[127, 100, 100, 100] @=> int velocities3[];
ChordProgression prog3(sh4d_2, chordsH, progression, true, 4, 4, probabilities3);
0.4 => prog3.mutateProbabilityRange;
velocities3 @=> prog3.velocities;
true => prog2.random;
// true => prog2.legato;

// Melody
[1.0, 1.0, 0.0, 0.0, 1.0, 1, 1.0, 0.0] @=> float probabilities4[];
[120, 90, 90, 90] @=> int velocities4[];
// AleatoricMelody melody1(marimba, IV_Low, 16, 4, probabilities4);
ChordProgression melody1(marimba, chordsL, progression, true, 16, 4, probabilities4);
0.4 => melody1.mutateProbabilityRange;
true => melody1.random;
// true => melody.legato;
velocities4 @=> melody1.velocities;

[0.0, .45, 1.0, 0.0] @=> float probabilities5[];
[125, 90, 110, 90] @=> int velocities5[];
//AleatoricMelody melody2(sh4d_3, IV_High, 16, 4, probabilities5);
ChordProgression melody2(sh4d_3, chordsL, progression, true, 16, 4, probabilities5);
0.4 => melody2.mutateProbabilityRange;
true => melody2.legato;
true => melody2.random;
velocities5 @=> melody2.velocities;

[prog1, prog2, prog3, melody1, melody2] @=> Part parts1[];
// Fragment frag1(1, song1);
Fragment frag1("frag1", 1, parts1);

FragmentTransition ft1(frag1, 1.0);

[ft1] @=> frag1.nextFragments;

Song song("flora01", BPM, root, frag1, parts1);


song.play();