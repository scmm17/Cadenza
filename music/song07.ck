@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"
@import "../framework/midi-events.ck"

// Global parameters — E (root 64), mixolydian I–IV–bVII–IV loop
78 => float BPM;
64 => int root;

// Midi devices — all V3GrandPiano
V3GrandPiano piano(1, "Crystal", 116);
V3GrandPiano bass(2, "Upright Jazz Bass Random", 116);
V3GrandPiano ooh(3, "Disco Strings Slide velo. 116-127 Slide", 116);

// Chords (flora-style Roman numerals)
Chord I_Low(NoteCollection.I_notes(), -1);
Chord IV_Low(NoteCollection.IV_notes(), -1);
Chord bVII_Low(NoteCollection.bVII_notes(), -1);

Chord I_High(NoteCollection.I_notes(), 0);
Chord IV_High(NoteCollection.IV_notes(), 0);
Chord bVII_High(NoteCollection.bVII_notes(), 0);

[I_Low, IV_Low, bVII_Low, IV_Low] @=> Chord chords1[];
[I_High, IV_High, bVII_High, IV_High] @=> Chord chords2[];

// One chord per bar, diatonic to root
[0, 0, 0, 0] @=> int progression[];

// Rhythm probabilities: "p:min:max:range" — bounds 0..1 and per-step mutation range
// so values can drift toward 0 (mute) over time. Rests use 0 range so they stay silent.
[
 "0.7:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.6:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.7:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.55:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.65:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.35:0.0:1.0:0.14",
 "0.0:0.0:0.0:0.0",
 "0.7:0.0:1.0:0.14",
 "0.4:0.0:1.0:0.14",
 "1.0:0.0:1.0:0.10",
 "1.0:0.0:1.0:0.10"
] @=> string probabilitiesArp[];
[105, 85, 98, 75] @=> int velocities1[];
ChordProgression prog(bass, chords1, progression, true, 16, 4, probabilitiesArp);
velocities1 @=> prog.velocities;

ChordProgression prog3(bass, chords2, progression, true, 32, 4, probabilitiesArp);
velocities1 @=> prog3.velocities;
true => prog3.random;

// Pad: block chords
["1.0:0.0:1.0:0.06"] @=> string probabilitiesPad[];
[58] @=> int velocities2[];
ChordProgression prog2(ooh, chords1, progression, false, 1, 4, probabilitiesPad);
velocities2 @=> prog2.velocities;

[62] @=> int velocities4[];
ChordProgression prog5(piano, chords1, progression, true, 16, 4, probabilitiesPad);
velocities4 @=> prog5.velocities;

// Melody (stronger drift, matches former prog4 mutateProbabilityRange ~0.35)
[
 "1.0:0.0:1.0:0.35",
 "0.2:0.0:1.0:0.35",
 "0.55:0.0:1.0:0.35",
 "0.4:0.0:1.0:0.35"
] @=> string probabilitiesMelody[];
[108, 78, 82, 105] @=> int velocities[];
AleatoricMelody melody(piano, I_High, 16, 4, probabilitiesMelody);
velocities @=> melody.velocities;

ChordProgression prog4(piano, chords2, progression, true, 32, 4, probabilitiesMelody);
velocities @=> prog4.velocities;
true => prog4.random;

// Drums — Voice Kit on V3 channel 4
[1.0] @=> float probabilities3[];
[120, 118, 128, 118, 90, 118, 118, 118] @=> int velocities3[];
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
V3GrandPiano drumKit(4, "Voice Kit (page 43)", 79);
DrumMachine drums(drumNotesCollection, 32, 1, probabilities3, drumKit);
velocities3 @=> drums.velocities;

[prog2] @=> Part parts1[];
[prog2, prog5, drums] @=> Part parts2[];
[prog2, prog3, drums] @=> Part parts3[];
[prog2, prog3, prog4, prog, drums] @=> Part parts4[];
[prog4, prog5, melody, drums] @=> Part parts5[];
[prog, prog2, prog3, prog4, prog5, melody, drums] @=> Part parts6[];

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

Song song("song07", BPM, root, frag1, parts6);

song.play();
