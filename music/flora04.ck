@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
45 => float BPM;          // Beats per minute
65 => int root;

// Midi devices
//Hydrasynth hydrasynth("F006");
Hydrasynth hydrasynth("B016", 24);
RolandS1 s1(1, 1, 64);
RolandSH4d sh4d_1(1, 3, 11, 127);
RolandSH4d sh4d_2(2, "Channel 2", 30);
RolandSH4d sh4d_3(3, "Channel 3", 49);
RolandSH4d sh4d_4(4, "Channel 4", 64);
// V3GrandPiano marimba(1, "Harp");
V3GrandPiano marimba(1, "G. Steel Slide (velo. 116-127 Slide)", 75);
V3GrandPiano marimba2(2, "G. Steel Slide (velo. 116-127 Slide)", 75);
V3GrandPiano bass(3, "Upright Jazz Bass Random", 64);
// RolandSH4d sh4d_3(3, "Channel 3");

// Chords
Chord I_Low(NoteCollection.circle_I_notes(), -1);
Chord IV_Low(NoteCollection.circle_IV_notes(), -1);
Chord viio_Low(NoteCollection.circle_viio_notes(), -1);
Chord iii_Low(NoteCollection.circle_iii_notes(), -1);
Chord vi_Low(NoteCollection.circle_vi_notes(), -1);
Chord ii_Low(NoteCollection.circle_ii_notes(), -1);
Chord V_Low(NoteCollection.circle_V_notes(), -1);
Chord I2_Low(NoteCollection.circle_I2_notes(), -1);

Chord I_High(NoteCollection.circle_I_notes(), 0);
Chord IV_High(NoteCollection.circle_IV_notes(), 0);
Chord viio_High(NoteCollection.circle_viio_notes(), 0);
Chord iii_High(NoteCollection.circle_iii_notes(), 0);
Chord vi_High(NoteCollection.circle_vi_notes(), 0);
Chord ii_High(NoteCollection.circle_ii_notes(), 0);
Chord V_High(NoteCollection.circle_V_notes(), 0);
Chord I2_High(NoteCollection.circle_I2_notes(), 0);

Chord I_LowLow(NoteCollection.circle_I_notes(), -2);
Chord IV_LowLow(NoteCollection.circle_IV_notes(), -2);
Chord viio_LowLow(NoteCollection.circle_viio_notes(), -2);
Chord iii_LowLow(NoteCollection.circle_iii_notes(), -2);
Chord vi_LowLow(NoteCollection.circle_vi_notes(), -2);
Chord ii_LowLow(NoteCollection.circle_ii_notes(), -2);
Chord V_LowLow(NoteCollection.circle_V_notes(), -2);
Chord I2_LowLow(NoteCollection.circle_I2_notes(), -2);




// Chord progression, arpeggiated
[0, 0, 0, 0] @=> int progression[];
[I_Low, IV_Low, viio_Low, iii_Low, vi_Low, ii_Low, V_Low, I2_Low] @=> Chord chordsL[];
[I_LowLow, IV_LowLow, viio_LowLow, iii_LowLow, vi_LowLow, ii_LowLow, V_LowLow, I2_LowLow] @=> Chord chordsLL[];
[I_High, IV_High, viio_High, iii_High, vi_High, ii_High, V_High, I2_High] @=> Chord chordsH[];

[1.0] @=> float probabilities1[];
[124] @=> int velocities1[];
ChordProgression prog1(hydrasynth, chordsH, progression, false, 1, 4, probabilities1);
// 0.4 => prog1.mutateProbabilityRange;
// true => prog1.legato;
velocities1 @=> prog1.velocities;


[1.0, 0.5] @=> float probabilities2[];
[124, 115] @=> int velocities2[];
ChordProgression prog2(sh4d_1, chordsLL, progression, true, 2, 4, probabilities2);
true => prog2.random;
velocities2 @=> prog2.velocities;
0.3 => prog2.mutateProbabilityRange;

// Chord Progression
[1.0, 0.5, .75, .25] @=> float probabilities3[];
[127, 100, 100, 100] @=> int velocities3[];
ChordProgression prog3(sh4d_2, chordsL, progression, true, 4, 4, probabilities3);
// 0.4 => prog3.mutateProbabilityRange;
velocities3 @=> prog3.velocities;
true => prog3.random;
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

[1.0, 1.0, 1.0, 1.0, 1.0, 1, 0.0, 1.0] @=> float probabilities5[];
ChordProgression melody3(marimba, chordsL, progression, true, 32, 4, probabilities5);
0.4 => melody3.mutateProbabilityRange;
true => melody3.random;
// true => melody.legato;
velocities4 @=> melody3.velocities;

[1.0, 1.0, 1.0, 1.0, 1.0, 1, 0.0, 1.0] @=> float probabilities7[];
ChordProgression melody4(marimba, chordsH, progression, true, 32, 4, probabilities7);
0.4 => melody4.mutateProbabilityRange;
true => melody4.random;
// true => melody.legato;
velocities4 @=> melody4.velocities;

[1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0] @=> float probabilities8[];
ChordProgression melody5(marimba, chordsL, progression, true, 32, 4, probabilities8);
0.4 => melody5.mutateProbabilityRange;
true => melody5.random;
// true => melody.legato;
velocities4 @=> melody5.velocities;

[0.0, .45, 1.0, 0.0] @=> float probabilities6[];
[125, 90, 110, 90] @=> int velocities5[];
AleatoricMelody melody2(sh4d_3, IV_High, 16, 4, probabilities6);
0.4 => melody2.mutateProbabilityRange;
true => melody2.legato;
velocities5 @=> melody2.velocities;

[prog1, prog2, prog3, melody1, melody2, melody3, melody4, melody5] @=> Part parts1[];
// Fragment frag1(1, song1);
Fragment frag1("frag1", 1, parts1);

FragmentTransition ft1(frag1, 1.0);

[ft1] @=> frag1.nextFragments;

Song song("flora04", BPM, root, frag1, parts1);


song.play();