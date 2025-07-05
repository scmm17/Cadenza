@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
120 => float BPM;          // Beats per minute
60 => int root;           // Middle C as the root note

// Midi devices
// Hydrasynth hydrasynth("F005");
//Hydrasynth hydrasynth("F006");
// Hydrasynth hydrasynth("A003");
//RolandS1 s1(2, 8);
RolandS1 s1(2, 10, 64);
//RolandS1 s1(2, 9);
RolandSH4d sh4d_1(1, 3, 5, 99);
V3GrandPiano piano(1, "Grand Piano Vienna - Rock", 116);
RolandSH4d sh4d_2(2, "SH4d channel 2", 64);
RolandSH4d sh4d_3(3, "SH4d channel 3", 64);

// Chords
Chord I7_Low(NoteCollection.I7_notes(), -1);
Chord IV7_Low(NoteCollection.IV7_notes(), -1);
Chord V7_Low(NoteCollection.V7_notes(), -1);

Chord I7_High(NoteCollection.I7_notes(), 0);
Chord IV7_High(NoteCollection.IV7_notes(), 0);
Chord V7_High(NoteCollection.V7_notes(), 0);

Chord I7_Higher(NoteCollection.I7_notes(), 1);
Chord IV7_Higher(NoteCollection.IV7_notes(), 1);
Chord V7_Higher(NoteCollection.V7_notes(), 1);


// Chord notes
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] @=> int progression[];
[I7_Low, I7_Low, I7_Low, I7_Low, 
 IV7_Low, IV7_Low, I7_Low, I7_Low, 
 V7_Low, IV7_Low, I7_Low, I7_Low] @=> Chord chordsL[];

// Chords
[I7_High, I7_High, I7_High, I7_High, 
 IV7_High, IV7_High, I7_High, I7_High, 
 V7_High, IV7_High, I7_High, I7_High] @=> Chord chordsH[];

[I7_High, I7_High, I7_High, I7_High, 
 IV7_High, IV7_High, I7_Higher, I7_High, 
 V7_High, IV7_High, I7_Higher, I7_Higher] @=> Chord chordsMelody[];

Chord I7_bass_Low(NoteCollection.I7_bass_notes(), -1);
Chord IV7_bass_Low(NoteCollection.IV7_bass_notes(), -1);
Chord V7_bass_Low(NoteCollection.V7_bass_notes(), -1);

Chord I7_bass_High(NoteCollection.I7_bass_notes(), 0);
Chord IV7_bass_High(NoteCollection.IV7_bass_notes(), 0);
Chord V7_bass_High(NoteCollection.V7_bass_notes(), 0);

// Bass Line
[I7_bass_Low, I7_bass_Low, I7_bass_Low, I7_bass_Low, 
 IV7_bass_Low, IV7_bass_Low, I7_bass_Low, I7_bass_Low, 
 V7_bass_Low, IV7_bass_Low, I7_bass_Low, I7_bass_Low] @=> Chord chordsBassL[];

[I7_bass_High, I7_bass_High, I7_bass_High, I7_bass_High, 
 IV7_bass_High, IV7_bass_High, I7_bass_High, I7_bass_High, 
 V7_bass_High, IV7_bass_High, I7_bass_High, I7_bass_High] @=> Chord chordsBassH[];

[1.0, 0.5] @=> float probabilities1[];
[124, 80, 80, 80] @=> int velocities1[];
ChordProgression prog(sh4d_1, chordsBassH, progression, true, 8, 12, probabilities1);
velocities1 @=> prog.velocities;
ChordProgression prog6(s1, chordsBassH, progression, true, 16, 12, probabilities1);
velocities1 @=> prog6.velocities;
0.4 => prog6.mutateProbabilityRange;

[1.0, 0.0, .45, .5] @=> float probabilities3[];
ChordProgression prog4(piano, chordsMelody, progression, true, 16, 12, probabilities3);
[120, 100] @=> int velocities2[];
true => prog4.random;
true => prog4.legato;
velocities2 @=> prog4.velocities;
.3 => prog4.mutateProbabilityRange;

[1.0, 0.25, .45, .5] @=> float probabilities9[];
ChordProgression prog5(piano, chordsMelody, progression, true, 16, 12, probabilities9);
velocities2 @=> prog5.velocities;
true => prog5.random;
true => prog5.legato;
.3 => prog5.mutateProbabilityRange;
// Chord Progression
[1.0, 0.0, 1.0, .5] @=> float probabilities2[];
ChordProgression prog2(piano, chordsL, progression, false, 2, 12, probabilities2);
velocities2 @=> prog2.velocities;
// true => prog2.legato;

// Drums
[1.0] @=> float probabilities4[];
[127] @=>  int velocities4[];
[
    DrumMachine.BassDrum(),
    0,
    DrumMachine.ClosedHat(),
    DrumMachine.ClosedHat(),
    DrumMachine.BassDrum(),
    0,
    DrumMachine.ClosedHat(),
    0
  ] @=> int drumNotes[];
NoteCollection drumNotesCollection(drumNotes);
RolandSH4d drumKit(10, "SH-4d SDrums", 60);
DrumMachine drums(drumNotesCollection, 16, 12, probabilities4, drumKit);
velocities4 @=> drums.velocities;

//[prog, prog2, prog4, melody, melody2, drums] @=> Part parts[];
[prog2, prog, prog4, prog5, prog6, drums] @=> Part parts1[];
Fragment frag1("frag1", 1, parts1);
FragmentTransition ft1(frag1, 1.0);
[ft1] @=> frag1.nextFragments;
Song song(BPM, root, frag1, parts1);
song @=> frag1.owningSong;
song.play();
