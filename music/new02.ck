@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================
// new02.ck — ii–V–I in D Major, Tonal Jazz, AABA 32-bar form
// ============================================================

// Global parameters
120 => float BPM;
62  => int root;        // D4 (MIDI 62)

// ============================================================
// Devices
// ============================================================
V3GrandPiano piano(1, "E-Piano MK1 Dyno - velocity splits 9 2", 105);  // Piano comping, ch 1
V3GrandPiano sax(2, "Max Jazz Tenor velo. split 64 Random Key & breath noise", 100); // Tenor sax, ch 2
MoogMessenger bass(1, 1, 1, 70);                     // Moog Messenger bass, ch 3
V3GrandPiano drumKit(4, "Jazz Drum Kit (page 43)", 90); // Jazz drums, ch 4

// ============================================================
// NoteCollections — D major ii–V–I (semitone offsets from D)
// ============================================================
// ii chord: Em7  — root=E(+2), min3rd(+5), P5th(+9), min7th(+12)
[2, 5, 9, 12] @=> int ii_notes[];
NoteCollection ii_nc(ii_notes);

// V chord: A7   — root=A(+7), maj3rd(+11), P5th(+14), min7th(+17)
[7, 11, 14, 17] @=> int V_notes[];
NoteCollection V_nc(V_notes);

// I chord: Dmaj7 — root=D(0), maj3rd(+4), P5th(+7), maj7th(+11)
[0, 4, 7, 11] @=> int I_notes[];
NoteCollection I_nc(I_notes);

// D major scale for sax improvisation
[0, 2, 4, 5, 7, 9, 11, 12] @=> int dMajorNotes[];
NoteCollection dMajorScale(dMajorNotes);

// ============================================================
// Chords — A section (ii–V–I–I), low and high registers
// ============================================================
Chord ii_bass(ii_nc, -2);       // Bass register
Chord V_bass(V_nc, -2);
Chord I_bass(I_nc, -2);

Chord ii_piano(ii_nc, -1);      // Piano comping register
Chord V_piano(V_nc, -1);
Chord I_piano(I_nc, -1);

// A section: ii – V – I – I  (each chord lasts 2 bars)
[ii_bass, V_bass, I_bass, I_bass]     @=> Chord bassA[];
[ii_piano, V_piano, I_piano, I_piano] @=> Chord pianoA[];

// Offsets: all chords voiced relative to root (no additional transposition)
[0, 0, 0, 0] @=> int progOffsets[];

// ============================================================
// Chords — B section (I–IV–V–I), bridge contrast
// ============================================================
Chord I_b_bass(NoteCollection.I_notes(), -2);
Chord IV_b_bass(NoteCollection.IV_notes(), -2);
Chord V_b_bass(NoteCollection.V_notes(), -2);

Chord I_b_piano(NoteCollection.I_notes(), -1);
Chord IV_b_piano(NoteCollection.IV_notes(), -1);
Chord V_b_piano(NoteCollection.V_notes(), -1);

[I_b_bass, IV_b_bass, V_b_bass, I_b_bass]     @=> Chord bassB[];
[I_b_piano, IV_b_piano, V_b_piano, I_b_piano] @=> Chord pianoB[];

// ============================================================
// Bass — MoogMessenger, arpeggiated walking feel
// ============================================================
[
    "1.0:0.5:1.0:0.08",   // beat 1
    "0.2:0.3:1.0:0.1",
    "0.55:0.0:1.0:0.12",  // & of 1
    "0.2:0.4:1.0:0.3",
    "0.85:0.5:1.0:0.08",  // beat 2
    "0.0:0.0:0.0:0.0",
    "0.45:0.0:1.0:0.12",  // & of 2
    "0.3:0.6:1.0:0.3"
] @=> string bassProbs[];
[100, 80] @=> int bassVelocities[];

ChordProgression bassPartA(bass, bassA, progOffsets, true, 8, 8, bassProbs);
bassVelocities @=> bassPartA.velocities;

ChordProgression bassPartB(bass, bassB, progOffsets, true, 8, 8, bassProbs);
bassVelocities @=> bassPartB.velocities;

// ============================================================
// Piano comping — V3GrandPiano, jazz syncopated rhythm
// ============================================================
[
    "0.0:0.0:0.0:0.0",      // beat 1 (rest)
    "0.65:0.0:1.0:0.15",    // & of 1
    "0.80:0.3:1.0:0.10",    // beat 2
    "0.0:0.0:0.0:0.0",
    "0.0:0.0:0.0:0.0",      // beat 3 (rest)
    "0.70:0.0:1.0:0.15",    // & of 3
    "0.60:0.0:1.0:0.10",    // beat 4
    "0.50:0.0:1.0:0.15",    // & of 4
    "0.0:0.0:0.0:0.0",
    "0.75:0.0:1.0:0.15",
    "0.55:0.0:1.0:0.10",
    "0.0:0.0:0.0:0.0",
    "0.85:0.3:1.0:0.10",
    "0.0:0.0:0.0:0.0",
    "0.65:0.0:1.0:0.15",
    "0.40:0.0:1.0:0.15"
] @=> string pianoProbs[];
[90, 72, 80, 65] @=> int pianoVelocities[];

ChordProgression pianoPartA(piano, pianoA, progOffsets, true, 16, 8, pianoProbs);
pianoVelocities @=> pianoPartA.velocities;

ChordProgression pianoPartB(piano, pianoB, progOffsets, true, 16, 8, pianoProbs);
pianoVelocities @=> pianoPartB.velocities;

// ============================================================
// Sax melody — AleatoricMelody over D major scale
// ============================================================
[
    "1.0:0.0:1.0:0.30",   // phrase opener
    "0.0:0.0:0.0:0.0",
    "0.55:0.0:1.0:0.30",
    "0.25:0.0:0.9:0.30",
    "0.0:0.0:0.0:0.0",
    "0.70:0.0:1.0:0.30",
    "0.35:0.0:1.0:0.30",
    "0.0:0.0:0.0:0.0",
    "0.80:0.0:1.0:0.30",
    "0.0:0.0:0.0:0.0",
    "0.45:0.0:1.0:0.30",
    "0.60:0.0:1.0:0.30",
    "0.0:0.0:0.0:0.0",
    "0.30:0.0:1.0:0.30",
    "0.75:0.0:1.0:0.30",
    "0.0:0.0:0.0:0.0"
] @=> string saxProbs[];
[110, 85, 95, 80] @=> int saxVelocities[];

AleatoricMelody saxMelody(piano, dMajorScale, 16, 8, saxProbs);
saxVelocities @=> saxMelody.velocities;

// ============================================================
// Drums — Jazz ride pattern (16 sixteenth notes, loops x8)
// ============================================================
[
    DrumMachine.BassDrum(),   // beat 1
    0,
    DrumMachine.ClosedHat(),  // & of 1
    0,
    DrumMachine.Cymbal(),     // beat 2 (ride)
    0,
    DrumMachine.ClosedHat(),  // & of 2
    0,
    DrumMachine.BassDrum(),   // beat 3
    0,
    DrumMachine.ClosedHat(),  // & of 3
    0,
    DrumMachine.Cymbal(),       // beat 4
    0,
    DrumMachine.ClosedHat(),  // & of 4
    0
] @=> int drumNotes[];
NoteCollection drumNC(drumNotes);
[1.0] @=> float drumProbs[];
[75, 0, 120, 0] @=> int drumVelocities[];
DrumMachine drums(drumNC, 16, 1, drumProbs, drumKit);
drumVelocities @=> drums.velocities;

// ============================================================
// Part groupings per fragment
// ============================================================
[saxMelody]                          @=> Part partsIntro1[];  // Intro 1: piano only (device 2)
[pianoPartA, saxMelody, drums]               @=> Part partsIntro2[];  // Intro 2: piano + sax (devices 2 & 3)
[bassPartA, pianoPartA, saxMelody, drums] @=> Part partsA[];
[bassPartB, pianoPartB, saxMelody, drums] @=> Part partsB[];

// allParts required by Song constructor
[bassPartA, bassPartB, pianoPartA, pianoPartB, saxMelody, drums] @=> Part allParts[];

// ============================================================
// Fragments — Intro → AABA straight-through (all 1.0)
// ============================================================
Fragment fragIntro1("Intro1", 1, partsIntro1); // Intro 1: piano only   (8 bars)
Fragment fragIntro2("Intro2", 1, partsIntro2); // Intro 2: piano + sax  (8 bars)
Fragment fragA1("A1", 1, partsA);              // A section 1  (bars  1–8)
Fragment fragA2("A2", 1, partsA);              // A section 2  (bars  9–16)
Fragment fragB ("B",  1, partsB);              // B bridge     (bars 17–24)
Fragment fragA3("A3", 1, partsA);              // A section 3  (bars 25–32)

FragmentTransition ftI1(fragIntro2, 1.0);  // Intro1 → Intro2
FragmentTransition ftI2(fragA1,     1.0);  // Intro2 → A1
FragmentTransition ftA1(fragA2,     1.0);  // A1 → A2
FragmentTransition ftA2(fragB,      1.0);  // A2 → B
FragmentTransition ftB (fragA3,     1.0);  // B  → A3
FragmentTransition ftA3(fragA1,     1.0);  // A3 → A1

[ftI1] @=> fragIntro1.nextFragments;
[ftI2] @=> fragIntro2.nextFragments;
[ftA1] @=> fragA1.nextFragments;
[ftA2] @=> fragA2.nextFragments;
[ftB]  @=> fragB.nextFragments;
[ftA3] @=> fragA3.nextFragments;

// ============================================================
// Song
// ============================================================
Song song("new02", BPM, root, fragIntro1, allParts);

song.play();
