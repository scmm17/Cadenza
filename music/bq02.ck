@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================
// bq02.ck -- Baroque Prelude in C Major (Extended)
// In the manner of J.S. Bach's Well-Tempered Clavier, Book I
//
// Expanded from bq01.ck with additional sections and
// probabilistic fragment sequencing (after song04.ck).
//
// Sections:
//   Prelude        -- sparse opening, right hand solo (2 bars)
//   Exposition     -- I - vi - ii - V  (4 bars)
//   Development A  -- vi - ii - IV - V - I - V  (6 bars)
//   Sequence       -- descending chromatic sequence
//                     i - bVII - bVI - V  (borrowed minor, 4 bars)
//   Development B  -- ii - V - I - iii - IV - V  (6 bars)
//   Recapitulation -- I - IV - V - I  (4 bars)
//   Cadence        -- V7 - I  (2 bars, final authentic cadence)
//   Coda           -- I (2 bars, tonic flourish)
//
// Fragment graph (random sequencing):
//   Prelude        --> Exposition (100%)
//   Exposition     --> Development A (100%)
//   Development A  --> Sequence (60%) | Development B (40%)
//   Sequence       --> Development B (70%) | Recapitulation (30%)
//   Development B  --> Recapitulation (65%) | Dev A (20%) | Sequence (15%)
//   Recapitulation --> Cadence (80%) | Development B (20%)
//   Cadence        --> Coda (100%)
//   Coda           --> [end, 0%]
// ============================================================

// Global parameters
82 => float BPM;        // Stately baroque tempo (quarter = 72)
60 => int root;         // Middle C -- C major

// ============================================================
// V3 Piano Devices
// ============================================================
V3GrandPiano rightHand(1, "Grand Piano Vienna - softer", 90);
V3GrandPiano leftHand(2, "Grand Piano Vienna - softer", 75);

// ============================================================
// Note Collections -- semitone offsets from C (root = 60)
// ============================================================

// I chord:    C major    -- C E G C E  (open voiced)
[0, 4, 7, 12, 16] @=> int I_arr[];
NoteCollection I_nc(I_arr);

// vi chord:   A minor    -- A C E A
[9, 12, 16, 21] @=> int vi_arr[];
NoteCollection vi_nc(vi_arr);

// ii chord:   D minor    -- D F A D
[2, 5, 9, 14] @=> int ii_arr[];
NoteCollection ii_nc(ii_arr);

// V chord:    G major    -- G B D G
[7, 11, 14, 19] @=> int V_arr[];
NoteCollection V_nc(V_arr);

// IV chord:   F major    -- F A C F
[5, 9, 12, 17] @=> int IV_arr[];
NoteCollection IV_nc(IV_arr);

// V7 chord:   G dom 7th  -- G B D F
[7, 11, 14, 17] @=> int V7_arr[];
NoteCollection V7_nc(V7_arr);

// i chord:    C minor    -- C Eb G C  (borrowed from parallel minor)
[0, 3, 7, 12] @=> int i_arr[];
NoteCollection i_nc(i_arr);

// bVII chord: Bb major   -- Bb D F Bb  (descending sequence step 2)
[-2, 2, 5, 10] @=> int bVII_arr[];
NoteCollection bVII_nc(bVII_arr);

// bVI chord:  Ab major   -- Ab C Eb Ab  (descending sequence step 3)
[-4, 0, 3, 8] @=> int bVI_arr[];
NoteCollection bVI_nc(bVI_arr);

// iii chord:  E minor    -- E G B E  (mediant, Dev B colour)
[4, 7, 11, 16] @=> int iii_arr[];
NoteCollection iii_nc(iii_arr);

// ============================================================
// Chords -- Right hand (mid-high register, octave 0)
// ============================================================
Chord rh_I(I_nc, 0);
Chord rh_vi(vi_nc, 0);
Chord rh_ii(ii_nc, 0);
Chord rh_V(V_nc, 0);
Chord rh_IV(IV_nc, 0);
Chord rh_V7(V7_nc, 0);
Chord rh_i(i_nc, 0);
Chord rh_bVII(bVII_nc, 0);
Chord rh_bVI(bVI_nc, 0);
Chord rh_iii(iii_nc, 0);

// Left hand -- two octaves down
Chord lh_I(I_nc, -2);
Chord lh_vi(vi_nc, -2);
Chord lh_ii(ii_nc, -2);
Chord lh_V(V_nc, -2);
Chord lh_IV(IV_nc, -2);
Chord lh_V7(V7_nc, -2);
Chord lh_i(i_nc, -2);
Chord lh_bVII(bVII_nc, -2);
Chord lh_bVI(bVI_nc, -2);
Chord lh_iii(iii_nc, -2);

// ============================================================
// Shared probability templates
// ============================================================

// Dense baroque semiquaver perpetual motion
[
 "1.0:0.7:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "1.0:0.6:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "1.0:0.65:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "1.0:0.6:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.88:0.5:1.0:0.0"
] @=> string rh_dense_probs[];

// Looser development figuration
[
 "1.0:0.7:1.0:0.0",
 "0.8:0.4:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.75:0.3:1.0:0.0",
 "1.0:0.65:1.0:0.0",
 "0.85:0.45:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.8:0.4:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.85:0.5:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.78:0.35:1.0:0.0",
 "1.0:0.6:1.0:0.0",
 "0.85:0.45:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.82:0.42:1.0:0.0"
] @=> string rh_dev_probs[];

// Fuller recapitulation figuration
[
 "1.0:0.75:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "1.0:0.72:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.95:0.6:1.0:0.0"
] @=> string rh_recap_probs[];

// Prelude: sparse -- just a few notes
[
 "1.0:0.6:1.0:0.0",
 "0.0",
 "0.0",
 "0.5:0.2:0.8:0.0",
 "0.0",
 "0.0",
 "0.6:0.3:0.9:0.0",
 "0.0",
 "1.0:0.65:1.0:0.0",
 "0.0",
 "0.0",
 "0.5:0.2:0.8:0.0",
 "0.0",
 "0.0",
 "0.5:0.3:0.8:0.0",
 "0.0"
] @=> string rh_prelude_probs[];

// Left hand: struck on beat 1 only (basso continuo)
["1.0:0.5:1.0:0.0", "0.0", "0.0", "0.0"] @=> string lh_bass_probs[];

// Shared velocity arrays
[85, 70, 75, 72] @=> int rh_vel[];
[68, 60, 63, 65] @=> int lh_vel[];

// ============================================================
// PRELUDE: I  (2 bars, sparse opening)
// ============================================================
[rh_I, rh_I] @=> Chord prelude_rh_chords[];
[0, 0] @=> int prelude_offsets[];

ChordProgression prelude_rh(rightHand, prelude_rh_chords, prelude_offsets, true, 16, 2, rh_prelude_probs);
true => prelude_rh.random;
0.15 => prelude_rh.mutateProbabilityRange;
rh_vel @=> prelude_rh.velocities;

[lh_I, lh_I] @=> Chord prelude_lh_chords[];
["1.0:0.4:1.0:0.0", "0.0", "1.0", "0.0"] @=> string lh_prelude_probs[];
[55, 60] @=> int lh_prelude_vel[];
ChordProgression prelude_lh(leftHand, prelude_lh_chords, prelude_offsets, true, 4, 2, lh_prelude_probs);
false => prelude_lh.random;
0.0 => prelude_lh.mutateProbabilityRange;
lh_prelude_vel @=> prelude_lh.velocities;

// ============================================================
// EXPOSITION: I - vi - ii - V  (4 bars)
// ============================================================
[rh_I, rh_vi, rh_ii, rh_V] @=> Chord expo_rh_chords[];
[0, 0, 0, 0] @=> int expo_offsets[];

ChordProgression expo_rh(rightHand, expo_rh_chords, expo_offsets, true, 16, 4, rh_dense_probs);
true => expo_rh.random;
0.1 => expo_rh.mutateProbabilityRange;
rh_vel @=> expo_rh.velocities;

[lh_I, lh_vi, lh_ii, lh_V] @=> Chord expo_lh_chords[];
ChordProgression expo_lh(leftHand, expo_lh_chords, expo_offsets, true, 4, 4, lh_bass_probs);
false => expo_lh.random;
0.0 => expo_lh.mutateProbabilityRange;
lh_vel @=> expo_lh.velocities;

// ============================================================
// DEVELOPMENT A: vi - ii - IV - V - I - V  (6 bars)
// ============================================================
[rh_vi, rh_ii, rh_IV, rh_V, rh_I, rh_V] @=> Chord devA_rh_chords[];
[0, 0, 0, 0, 0, 0] @=> int devA_offsets[];

ChordProgression devA_rh(rightHand, devA_rh_chords, devA_offsets, true, 16, 6, rh_dev_probs);
true => devA_rh.random;
0.12 => devA_rh.mutateProbabilityRange;
rh_vel @=> devA_rh.velocities;

[lh_vi, lh_ii, lh_IV, lh_V, lh_I, lh_V] @=> Chord devA_lh_chords[];
ChordProgression devA_lh(leftHand, devA_lh_chords, devA_offsets, true, 4, 6, lh_bass_probs);
false => devA_lh.random;
0.0 => devA_lh.mutateProbabilityRange;
lh_vel @=> devA_lh.velocities;

// ============================================================
// SEQUENCE: i - bVII - bVI - V  (4 bars)
// Descending chromatic sequence -- dramatic modal digression.
// Borrowed from C natural minor (parallel minor key).
// Classic baroque lament / descending tetrachord.
// ============================================================
[rh_i, rh_bVII, rh_bVI, rh_V] @=> Chord seq_rh_chords[];
[0, 0, 0, 0] @=> int seq_offsets[];

[
 "1.0:0.65:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.7:0.3:1.0:0.0",
 "1.0:0.6:1.0:0.0",
 "0.88:0.45:1.0:0.0",
 "0.85:0.4:1.0:0.0",
 "0.78:0.35:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.82:0.4:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.72:0.3:1.0:0.0",
 "1.0:0.65:1.0:0.0",
 "0.85:0.45:1.0:0.0",
 "0.82:0.4:1.0:0.0",
 "0.88:0.5:1.0:0.0"
] @=> string rh_seq_probs[];

[80, 68, 72, 70] @=> int seq_rh_vel[];
ChordProgression seq_rh(rightHand, seq_rh_chords, seq_offsets, true, 16, 4, rh_seq_probs);
true => seq_rh.random;
0.12 => seq_rh.mutateProbabilityRange;
seq_rh_vel @=> seq_rh.velocities;

[lh_i, lh_bVII, lh_bVI, lh_V] @=> Chord seq_lh_chords[];
[62, 55, 58, 60] @=> int seq_lh_vel[];
ChordProgression seq_lh(leftHand, seq_lh_chords, seq_offsets, true, 4, 4, lh_bass_probs);
false => seq_lh.random;
0.0 => seq_lh.mutateProbabilityRange;
seq_lh_vel @=> seq_lh.velocities;

// ============================================================
// DEVELOPMENT B: ii - V - I - iii - IV - V  (6 bars)
// Dominant build -- intensifying drive toward recapitulation.
// Uses mediant (iii) for baroque colour.
// ============================================================
[rh_ii, rh_V, rh_I, rh_iii, rh_IV, rh_V] @=> Chord devB_rh_chords[];
[0, 0, 0, 0, 0, 0] @=> int devB_offsets[];

[
 "1.0:0.75:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.85:0.45:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.85:0.45:1.0:0.0",
 "1.0:0.72:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.82:0.42:1.0:0.0",
 "1.0:0.7:1.0:0.0",
 "0.9:0.5:1.0:0.0",
 "0.88:0.5:1.0:0.0",
 "0.92:0.55:1.0:0.0"
] @=> string rh_devB_probs[];

[88, 72, 78, 74] @=> int devB_vel[];
ChordProgression devB_rh(rightHand, devB_rh_chords, devB_offsets, true, 16, 6, rh_devB_probs);
true => devB_rh.random;
0.1 => devB_rh.mutateProbabilityRange;
devB_vel @=> devB_rh.velocities;

[lh_ii, lh_V, lh_I, lh_iii, lh_IV, lh_V] @=> Chord devB_lh_chords[];
ChordProgression devB_lh(leftHand, devB_lh_chords, devB_offsets, true, 4, 6, lh_bass_probs);
false => devB_lh.random;
0.0 => devB_lh.mutateProbabilityRange;
lh_vel @=> devB_lh.velocities;

// ============================================================
// RECAPITULATION: I - IV - V - I  (4 bars)
// ============================================================
[rh_I, rh_IV, rh_V, rh_I] @=> Chord recap_rh_chords[];
[0, 0, 0, 0] @=> int recap_offsets[];

ChordProgression recap_rh(rightHand, recap_rh_chords, recap_offsets, true, 16, 4, rh_recap_probs);
true => recap_rh.random;
0.08 => recap_rh.mutateProbabilityRange;
rh_vel @=> recap_rh.velocities;

[lh_I, lh_IV, lh_V, lh_I] @=> Chord recap_lh_chords[];
ChordProgression recap_lh(leftHand, recap_lh_chords, recap_offsets, true, 4, 4, lh_bass_probs);
false => recap_lh.random;
0.0 => recap_lh.mutateProbabilityRange;
lh_vel @=> recap_lh.velocities;

// ============================================================
// CADENCE: V7 - I  (2 bars, authentic perfect cadence)
// ============================================================
[rh_V7, rh_I] @=> Chord cad_rh_chords[];
[0, 0] @=> int cad_offsets[];

["1.0:0.8:1.0:0.0", "0.0", "0.8:0.5:1.0:0.0", "0.0",
 "1.0:0.75:1.0:0.0", "0.0", "0.85:0.55:1.0:0.0", "0.0"] @=> string rh_cad_probs[];
[90, 78] @=> int cad_rh_vel[];

ChordProgression cad_rh(rightHand, cad_rh_chords, cad_offsets, true, 8, 2, rh_cad_probs);
false => cad_rh.random;
0.0 => cad_rh.mutateProbabilityRange;
cad_rh_vel @=> cad_rh.velocities;

[lh_V7, lh_I] @=> Chord cad_lh_chords[];
["1.0:0.6:1.0:0.0", "0.0", "0.0", "0.0"] @=> string lh_cad_probs[];
[72, 65] @=> int cad_lh_vel[];

ChordProgression cad_lh(leftHand, cad_lh_chords, cad_offsets, true, 4, 2, lh_cad_probs);
false => cad_lh.random;
0.0 => cad_lh.mutateProbabilityRange;
cad_lh_vel @=> cad_lh.velocities;

// ============================================================
// CODA: I  (2 bars, tonic flourish -- triumphant close)
// ============================================================
[rh_I, rh_I] @=> Chord coda_rh_chords[];
[0, 0] @=> int coda_offsets[];

[
 "1.0:0.8:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "1.0:0.75:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "1.0:0.8:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "1.0:0.78:1.0:0.0",
 "0.95:0.6:1.0:0.0",
 "0.92:0.55:1.0:0.0",
 "1.0:0.8:1.0:0.0"
] @=> string rh_coda_probs[];

[92, 80] @=> int coda_rh_vel[];
ChordProgression coda_rh(rightHand, coda_rh_chords, coda_offsets, true, 16, 2, rh_coda_probs);
true => coda_rh.random;
0.05 => coda_rh.mutateProbabilityRange;
coda_rh_vel @=> coda_rh.velocities;

[lh_I, lh_I] @=> Chord coda_lh_chords[];
[70, 68] @=> int coda_lh_vel[];
ChordProgression coda_lh(leftHand, coda_lh_chords, coda_offsets, true, 4, 2, lh_bass_probs);
false => coda_lh.random;
0.0 => coda_lh.mutateProbabilityRange;
coda_lh_vel @=> coda_lh.velocities;

// ============================================================
// All Parts (required by Song constructor)
// ============================================================
[prelude_rh, prelude_lh,
 expo_rh,    expo_lh,
 devA_rh,   devA_lh,
 seq_rh,    seq_lh,
 devB_rh,   devB_lh,
 recap_rh,  recap_lh,
 cad_rh,    cad_lh,
 coda_rh,   coda_lh] @=> Part allParts[];

// ============================================================
// Fragments
// ============================================================
[prelude_rh, prelude_lh] @=> Part preludeParts[];
Fragment fPrelude("Prelude", 1, preludeParts);

[expo_rh, expo_lh] @=> Part expoParts[];
Fragment fExposition("Exposition", 1, expoParts);

[devA_rh, devA_lh] @=> Part devAParts[];
Fragment fDevA("Development A", 1, devAParts);

[seq_rh, seq_lh] @=> Part seqParts[];
Fragment fSequence("Sequence", 1, seqParts);

[devB_rh, devB_lh] @=> Part devBParts[];
Fragment fDevB("Development B", 1, devBParts);

[recap_rh, recap_lh] @=> Part recapParts[];
Fragment fRecap("Recapitulation", 1, recapParts);

[cad_rh, cad_lh] @=> Part cadParts[];
Fragment fCadence("Cadence", 1, cadParts);

[coda_rh, coda_lh] @=> Part codaParts[];
Fragment fCoda("Coda", 1, codaParts);

// ============================================================
// Fragment Transitions (probabilistic routing)
// ============================================================

// Prelude -> Exposition
FragmentTransition ft_toExpo(fExposition, 1.0);

// Exposition -> Dev A
FragmentTransition ft_toDevA(fDevA, 1.0);

// Dev A -> Sequence (60%) | Dev B (40%)
FragmentTransition ft_devA_seq(fSequence, 0.6);
FragmentTransition ft_devA_devB(fDevB, 0.4);

// Sequence -> Dev B (70%) | Recap (30%)
FragmentTransition ft_seq_devB(fDevB, 0.7);
FragmentTransition ft_seq_recap(fRecap, 0.3);

// Dev B -> Recap (65%) | Dev A (20%) | Sequence (15%)
FragmentTransition ft_devB_recap(fRecap, 0.65);
FragmentTransition ft_devB_devA(fDevA, 0.20);
FragmentTransition ft_devB_seq(fSequence, 0.15);

// Recapitulation -> Cadence (80%) | Dev B (20%)
FragmentTransition ft_recap_cad(fCadence, 0.8);
FragmentTransition ft_recap_devB(fDevB, 0.2);

// Cadence -> Coda
FragmentTransition ft_toCoda(fCoda, 1.0);

// Coda -> end
FragmentTransition ft_end(fPrelude, 0.0);

// Wire the graph
[ft_toExpo]                              @=> fPrelude.nextFragments;
[ft_toDevA]                              @=> fExposition.nextFragments;
[ft_devA_seq,  ft_devA_devB]             @=> fDevA.nextFragments;
[ft_seq_devB,  ft_seq_recap]             @=> fSequence.nextFragments;
[ft_devB_recap, ft_devB_devA, ft_devB_seq] @=> fDevB.nextFragments;
[ft_recap_cad, ft_recap_devB]            @=> fRecap.nextFragments;
[ft_toCoda]                              @=> fCadence.nextFragments;
[ft_end]                                 @=> fCoda.nextFragments;

// ============================================================
// Create and play the song
// ============================================================
Song song("bq02", BPM, root, fPrelude, allParts);

song.play();
