@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================
// bq03.ck -- Baroque Prelude in C Major (Extended)
// In the manner of J.S. Bach's Well-Tempered Clavier, Book I
//
// Expanded from bq01.ck with additional sections and
// probabilistic fragment sequencing (after song04.ck).
//
// Three-voice texture:
//   rightHand  -- Grand Piano, semiquaver arpeggios (melody / figuration)
//   leftHand   -- Grand Piano, eighth-note broken-chord bass (baroque continuo)
//   organ      -- Organ 776555678, basso continuo beat-1 strikes (pedal layer,
//                 used in all sections except the sparse Prelude)
//
// Sections:
//   Prelude        -- sparse opening, right hand solo (6 bars)
//   Exposition     -- I - vi - ii - V  (4 bars)
//   Development A  -- vi - ii - IV - V - I - V  (6 bars)
//   Sequence       -- descending chromatic sequence
//                     i - bVII - bVI - V  (borrowed minor, 4 bars)
//   Development B  -- ii - V - I - iii - IV - V  (6 bars)
//   Recapitulation -- I - IV - V - I  (4 bars)
//   Cadence        -- V7 - I  (2 bars, final authentic cadence)
//   Coda           -- I (2 bars, tonic flourish)
//   Cadence Repeat -- V7 - I  (2 bars, repeated authentic cadence)
//   Silence        -- 2 bars of silence (0.0 probability)
//
// Fragment graph (random sequencing):
//   Prelude        --> Exposition (100%)
//   Exposition     --> Development A (100%)
//   Development A  --> Sequence (60%) | Development B (40%)
//   Sequence       --> Development B (70%) | Recapitulation (30%)
//   Development B  --> Recapitulation (65%) | Dev A (20%) | Sequence (15%)
//   Recapitulation --> Cadence (80%) | Development B (20%)
//   Cadence        --> Coda (100%)
//   Coda           --> Cadence Repeat (100%)
//   Cadence Repeat --> Silence (100%)
//   Silence        --> [end, 0%]
// ============================================================

// Global parameters
82 => float BPM;        // Stately baroque tempo (quarter = 72)
60 => int root;         // Middle C -- C major

// ============================================================
// V3 Devices
// ============================================================
V3GrandPiano rightHand(1, "Grand Piano Vienna - softer", 90);
V3GrandPiano leftHand(2, "Grand Piano Vienna - softer", 75);
// Basso continuo organ -- channel 3, beat-1 pedal strikes
V3GrandPiano organ(3, "Organ 776555678 slow 4", 60);

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

// Organ basso continuo -- three octaves down (pedal register)
Chord bc_I(I_nc, -3);
Chord bc_vi(vi_nc, -3);
Chord bc_ii(ii_nc, -3);
Chord bc_V(V_nc, -3);
Chord bc_IV(IV_nc, -3);
Chord bc_V7(V7_nc, -3);
Chord bc_i(i_nc, -3);
Chord bc_bVII(bVII_nc, -3);
Chord bc_bVI(bVI_nc, -3);
Chord bc_iii(iii_nc, -3);

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

// ============================================================
// Left Hand Probability Templates
// ------------------------------------------------------------
// Baroque arpeggiated bass: 8 eighth-notes per measure.
// Beat 1 always strikes (root, forte), beats 2-4 cycle up
// through chord tones (3rd, 5th, octave) at lighter dynamics.
// This creates the flowing "broken chord" continuo texture
// characteristic of Bach's keyboard preludes.
// ============================================================

// Prelude LH: gentle, sparse arpeggios -- open up the texture
[
 "1.0:0.45:1.0:0.0",   // beat 1.0  -- root, struck firmly
 "0.7:0.25:0.8:0.0",   // beat 1.5  -- upper tone, soft
 "0.8:0.3:0.9:0.0",    // beat 2.0  -- mid tone
 "0.6:0.2:0.75:0.0",   // beat 2.5  -- light fill
 "0.9:0.4:1.0:0.0",    // beat 3.0  -- re-articulate
 "0.65:0.22:0.8:0.0",  // beat 3.5
 "0.75:0.28:0.85:0.0", // beat 4.0
 "0.55:0.18:0.7:0.0"   // beat 4.5  -- tail off
] @=> string lh_prelude_probs[];

// Exposition / Recapitulation LH: steady eighth-note arpeggios
[
 "1.0:0.5:1.0:0.0",    // beat 1.0  -- bass root, clear attack
 "0.85:0.35:0.9:0.0",  // beat 1.5
 "0.9:0.4:1.0:0.0",    // beat 2.0
 "0.8:0.3:0.85:0.0",   // beat 2.5
 "1.0:0.48:1.0:0.0",   // beat 3.0  -- re-articulate bass
 "0.82:0.32:0.88:0.0", // beat 3.5
 "0.88:0.38:0.95:0.0", // beat 4.0
 "0.78:0.28:0.82:0.0"  // beat 4.5
] @=> string lh_expo_probs[];

// Development LH: more animated -- occasional rests for tension
[
 "1.0:0.52:1.0:0.0",   // beat 1.0
 "0.78:0.3:0.88:0.0",  // beat 1.5
 "0.88:0.4:0.95:0.0",  // beat 2.0
 "0.7:0.25:0.82:0.0",  // beat 2.5  -- slight gap
 "0.95:0.45:1.0:0.0",  // beat 3.0
 "0.72:0.28:0.84:0.0", // beat 3.5
 "0.82:0.35:0.9:0.0",  // beat 4.0
 "0.65:0.22:0.78:0.0"  // beat 4.5
] @=> string lh_dev_probs[];

// Sequence LH: lament-bass feel -- steady, unrelenting eighth-notes
[
 "1.0:0.55:1.0:0.0",   // beat 1.0  -- bass root, weighty
 "0.9:0.38:0.95:0.0",  // beat 1.5
 "0.92:0.42:1.0:0.0",  // beat 2.0
 "0.85:0.35:0.9:0.0",  // beat 2.5
 "1.0:0.52:1.0:0.0",   // beat 3.0
 "0.88:0.36:0.92:0.0", // beat 3.5
 "0.9:0.4:0.95:0.0",   // beat 4.0
 "0.82:0.32:0.88:0.0"  // beat 4.5
] @=> string lh_seq_probs[];

// Cadence LH: deliberate -- quarter-note feel with rests on off-beats
[
 "1.0:0.6:1.0:0.0",    // beat 1.0
 "0.5:0.2:0.7:0.0",    // beat 1.5
 "0.6:0.25:0.8:0.0",   // beat 2.0
 "0.0",                 // beat 2.5  -- rest
 "1.0:0.55:1.0:0.0",   // beat 3.0
 "0.45:0.18:0.65:0.0", // beat 3.5
 "0.55:0.22:0.72:0.0", // beat 4.0
 "0.0"                  // beat 4.5  -- rest
] @=> string lh_cad_probs[];

// Coda LH: triumphant arpeggios -- full and bright
[
 "1.0:0.58:1.0:0.0",   // beat 1.0
 "0.92:0.42:1.0:0.0",  // beat 1.5
 "0.95:0.46:1.0:0.0",  // beat 2.0
 "0.88:0.38:0.95:0.0", // beat 2.5
 "1.0:0.55:1.0:0.0",   // beat 3.0
 "0.9:0.4:1.0:0.0",    // beat 3.5
 "0.92:0.44:1.0:0.0",  // beat 4.0
 "0.85:0.36:0.92:0.0"  // beat 4.5
] @=> string lh_coda_probs[];

// Shared velocity arrays
[85, 70, 75, 72] @=> int rh_vel[];
// 8 entries, one per eighth-note slot -- root louder, inner tones softer
[65, 52, 56, 50, 62, 50, 54, 48] @=> int lh_vel[];

// Organ basso continuo: quarter-note strikes -- beat 1 always, others silent.
// Classic basso continuo pedal -- provides harmonic foundation and sustain.
["1.0:0.5:1.0:0.0", "0.0", "0.0", "0.0"] @=> string org_bass_probs[];
// Single velocity entry -- organ sustains naturally, so a steady forte works
[62] @=> int org_vel[];

// ============================================================
// PRELUDE: I  (6 bars, sparse opening)
// ============================================================
[rh_I, rh_I, rh_I, rh_I, rh_I, rh_I] @=> Chord prelude_rh_chords[];
[0, 0, 0, 0, 0, 0] @=> int prelude_offsets[];
[60, 46, 50, 48] @=> int prelude_rh_vel[];

ChordProgression prelude_rh(rightHand, prelude_rh_chords, prelude_offsets, true, 16, 6, rh_prelude_probs);
true => prelude_rh.random;
0.15 => prelude_rh.mutateProbabilityRange;
prelude_rh_vel @=> prelude_rh.velocities;

[lh_I, lh_I, lh_I, lh_I, lh_I, lh_I] @=> Chord prelude_lh_chords[];
[46, 36, 38, 32, 42, 34, 36, 30] @=> int prelude_lh_vel[];
ChordProgression prelude_lh(leftHand, prelude_lh_chords, prelude_offsets, true, 8, 6, lh_prelude_probs);
false => prelude_lh.random;
0.08 => prelude_lh.mutateProbabilityRange;
prelude_lh_vel @=> prelude_lh.velocities;

// ============================================================
// EXPOSITION: I - vi - ii - V  (4 bars)
// Dynamics: louder than prelude, softer than main body
// ============================================================
[rh_I, rh_vi, rh_ii, rh_V] @=> Chord expo_rh_chords[];
[0, 0, 0, 0] @=> int expo_offsets[];
[73, 58, 62, 60] @=> int expo_rh_vel[];

ChordProgression expo_rh(rightHand, expo_rh_chords, expo_offsets, true, 16, 4, rh_dense_probs);
true => expo_rh.random;
0.1 => expo_rh.mutateProbabilityRange;
expo_rh_vel @=> expo_rh.velocities;

[lh_I, lh_vi, lh_ii, lh_V] @=> Chord expo_lh_chords[];
[56, 44, 47, 40, 52, 42, 45, 38] @=> int expo_lh_vel[];
ChordProgression expo_lh(leftHand, expo_lh_chords, expo_offsets, true, 8, 4, lh_expo_probs);
false => expo_lh.random;
0.05 => expo_lh.mutateProbabilityRange;
expo_lh_vel @=> expo_lh.velocities;

// Organ: basso continuo, beat-1 only
[bc_I, bc_vi, bc_ii, bc_V] @=> Chord expo_bc_chords[];
[50] @=> int expo_org_vel[];
ChordProgression expo_bc(organ, expo_bc_chords, expo_offsets, true, 4, 4, org_bass_probs);
false => expo_bc.random;
0.0 => expo_bc.mutateProbabilityRange;
expo_org_vel @=> expo_bc.velocities;

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
ChordProgression devA_lh(leftHand, devA_lh_chords, devA_offsets, true, 8, 6, lh_dev_probs);
false => devA_lh.random;
0.07 => devA_lh.mutateProbabilityRange;
lh_vel @=> devA_lh.velocities;

// Organ: basso continuo, beat-1 only
[bc_vi, bc_ii, bc_IV, bc_V, bc_I, bc_V] @=> Chord devA_bc_chords[];
ChordProgression devA_bc(organ, devA_bc_chords, devA_offsets, true, 4, 6, org_bass_probs);
false => devA_bc.random;
0.0 => devA_bc.mutateProbabilityRange;
org_vel @=> devA_bc.velocities;

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

ChordProgression seq_rh(rightHand, seq_rh_chords, seq_offsets, true, 16, 4, rh_seq_probs);
true => seq_rh.random;
0.12 => seq_rh.mutateProbabilityRange;
prelude_rh_vel @=> seq_rh.velocities;

[lh_i, lh_bVII, lh_bVI, lh_V] @=> Chord seq_lh_chords[];
ChordProgression seq_lh(leftHand, seq_lh_chords, seq_offsets, true, 8, 4, lh_seq_probs);
false => seq_lh.random;
0.06 => seq_lh.mutateProbabilityRange;
prelude_lh_vel @=> seq_lh.velocities;

// Organ: lament bass -- soft, as prelude dynamics
[bc_i, bc_bVII, bc_bVI, bc_V] @=> Chord seq_bc_chords[];
[42] @=> int seq_org_vel[];
ChordProgression seq_bc(organ, seq_bc_chords, seq_offsets, true, 4, 4, org_bass_probs);
false => seq_bc.random;
0.0 => seq_bc.mutateProbabilityRange;
seq_org_vel @=> seq_bc.velocities;

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
ChordProgression devB_lh(leftHand, devB_lh_chords, devB_offsets, true, 8, 6, lh_dev_probs);
false => devB_lh.random;
0.07 => devB_lh.mutateProbabilityRange;
lh_vel @=> devB_lh.velocities;

// Organ: basso continuo, beat-1 only
[bc_ii, bc_V, bc_I, bc_iii, bc_IV, bc_V] @=> Chord devB_bc_chords[];
ChordProgression devB_bc(organ, devB_bc_chords, devB_offsets, true, 4, 6, org_bass_probs);
false => devB_bc.random;
0.0 => devB_bc.mutateProbabilityRange;
org_vel @=> devB_bc.velocities;

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
ChordProgression recap_lh(leftHand, recap_lh_chords, recap_offsets, true, 8, 4, lh_expo_probs);
false => recap_lh.random;
0.05 => recap_lh.mutateProbabilityRange;
lh_vel @=> recap_lh.velocities;

// Organ: basso continuo, beat-1 only
[bc_I, bc_IV, bc_V, bc_I] @=> Chord recap_bc_chords[];
ChordProgression recap_bc(organ, recap_bc_chords, recap_offsets, true, 4, 4, org_bass_probs);
false => recap_bc.random;
0.0 => recap_bc.mutateProbabilityRange;
org_vel @=> recap_bc.velocities;

// ============================================================
// CADENCE: V7 - I  (2 bars, authentic perfect cadence)
// ============================================================
[rh_V7, rh_I] @=> Chord cad_rh_chords[];
[0, 0] @=> int cad_offsets[];

["1.0:0.8:1.0:0.0", "0.0", "0.8:0.5:1.0:0.0", "0.0",
 "1.0:0.75:1.0:0.0", "0.0", "0.85:0.55:1.0:0.0", "0.0"] @=> string rh_cad_probs[];
[80, 68] @=> int cad_rh_vel[];

ChordProgression cad_rh(rightHand, cad_rh_chords, cad_offsets, true, 8, 2, rh_cad_probs);
false => cad_rh.random;
0.0 => cad_rh.mutateProbabilityRange;
cad_rh_vel @=> cad_rh.velocities;

[lh_V7, lh_I] @=> Chord cad_lh_chords[];
[62, 50, 54, 0, 58, 47, 52, 0] @=> int cad_lh_vel[];
ChordProgression cad_lh(leftHand, cad_lh_chords, cad_offsets, true, 8, 2, lh_cad_probs);
false => cad_lh.random;
0.0 => cad_lh.mutateProbabilityRange;
cad_lh_vel @=> cad_lh.velocities;

// Organ: basso continuo, beat-1 only -- weighty, solemn perfect cadence
[bc_V7, bc_I] @=> Chord cad_bc_chords[];
[54] @=> int cad_bc_vel[];
ChordProgression cad_bc(organ, cad_bc_chords, cad_offsets, true, 4, 2, org_bass_probs);
false => cad_bc.random;
0.0 => cad_bc.mutateProbabilityRange;
cad_bc_vel @=> cad_bc.velocities;

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

[72, 60] @=> int coda_rh_vel[];
ChordProgression coda_rh(rightHand, coda_rh_chords, coda_offsets, true, 16, 2, rh_coda_probs);
true => coda_rh.random;
0.05 => coda_rh.mutateProbabilityRange;
coda_rh_vel @=> coda_rh.velocities;

[lh_I, lh_I] @=> Chord coda_lh_chords[];
[54, 44, 48, 40, 52, 42, 46, 38] @=> int coda_lh_vel[];
ChordProgression coda_lh(leftHand, coda_lh_chords, coda_offsets, true, 8, 2, lh_coda_probs);
false => coda_lh.random;
0.05 => coda_lh.mutateProbabilityRange;
coda_lh_vel @=> coda_lh.velocities;

// Organ: full triumphant pedal for the coda
[bc_I, bc_I] @=> Chord coda_bc_chords[];
[48] @=> int coda_bc_vel[];
ChordProgression coda_bc(organ, coda_bc_chords, coda_offsets, true, 4, 2, org_bass_probs);
false => coda_bc.random;
0.0 => coda_bc.mutateProbabilityRange;
coda_bc_vel @=> coda_bc.velocities;

// ============================================================
// CADENCE REPEAT: V7 - I  (2 bars, final authentic cadence)
// CADENCE REPEAT: I - I  (2 bars, final tonic statement)
// CADENCE REPEAT: I - I  (2 bars, final tonic statement)
// RH plays freely (no extended hold) -- figures continue into the silence fragment.
// LH holds its notes through the 2-bar silence via extended durations.
// ============================================================
[rh_I, rh_I] @=> Chord cadRepeat_rh_chords[];
[0, 0] @=> int cadRepeat_offsets[];
// RH: slightly soft but audible
[50, 36, 40, 38] @=> int cadRepeat_rh_vel[];
ChordProgression cadRepeat_rh(rightHand, cadRepeat_rh_chords, cadRepeat_offsets, true, 16, 2, rh_coda_probs);
false => cadRepeat_rh.random;
0.0 => cadRepeat_rh.mutateProbabilityRange;
cadRepeat_rh_vel @=> cadRepeat_rh.velocities;
// No .durations assigned -- RH plays with natural note lengths

[lh_I, lh_I] @=> Chord cadRepeat_lh_chords[];
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
 24.0, 23.0, 22.0, 21.0, 20.0, 19.0, 18.0, 17.0] @=> float cadRepeat_lh_durs[];
ChordProgression cadRepeat_lh(leftHand, cadRepeat_lh_chords, cadRepeat_offsets, true, 8, 2, lh_coda_probs);
false => cadRepeat_lh.random;
0.0 => cadRepeat_lh.mutateProbabilityRange;
prelude_lh_vel @=> cadRepeat_lh.velocities;
cadRepeat_lh_durs @=> cadRepeat_lh.durations;

[bc_I, bc_I] @=> Chord cadRepeat_bc_chords[];
[0.0, 0.0, 0.0, 0.0, 12.0, 11.0, 10.0, 9.0] @=> float cadRepeat_bc_durs[];
[42] @=> int cadRepeat_org_vel[];
ChordProgression cadRepeat_bc(organ, cadRepeat_bc_chords, cadRepeat_offsets, true, 4, 2, org_bass_probs);
false => cadRepeat_bc.random;
0.0 => cadRepeat_bc.mutateProbabilityRange;
cadRepeat_org_vel @=> cadRepeat_bc.velocities;
cadRepeat_bc_durs @=> cadRepeat_bc.durations;

// ============================================================
// SILENCE: 2 bars -- RH keeps playing I arpeggios; LH/BC silent
// (LH sustain is already held from cadRepeat's extended durations)
// ============================================================
["0.0"] @=> string silence_probs[];
[rh_I, rh_I] @=> Chord silence_rh_chords[];
[0, 0] @=> int silence_offsets[];
[0] @=> int silence_vel[];

// RH: same coda figures, same soft volume as cadRepeat
ChordProgression silence_rh(rightHand, silence_rh_chords, silence_offsets, true, 16, 2, rh_coda_probs);
false => silence_rh.random;
0.0 => silence_rh.mutateProbabilityRange;
cadRepeat_rh_vel @=> silence_rh.velocities;

// LH: silent -- it is already sounding from cadRepeat's held notes
ChordProgression silence_lh(leftHand, silence_rh_chords, silence_offsets, true, 4, 2, silence_probs);
false => silence_lh.random;
0.0 => silence_lh.mutateProbabilityRange;
silence_vel @=> silence_lh.velocities;

// BC: silent
ChordProgression silence_bc(organ, silence_rh_chords, silence_offsets, true, 4, 2, silence_probs);
false => silence_bc.random;
0.0 => silence_bc.mutateProbabilityRange;
silence_vel @=> silence_bc.velocities;

// ============================================================
// All Parts (required by Song constructor)
// ============================================================
[prelude_rh, prelude_lh,
 expo_rh,    expo_lh,    expo_bc,
 devA_rh,   devA_lh,   devA_bc,
 seq_rh,    seq_lh,    seq_bc,
 devB_rh,   devB_lh,   devB_bc,
 recap_rh,  recap_lh,  recap_bc,
 cad_rh,    cad_lh,    cad_bc,
 coda_rh,   coda_lh,   coda_bc,
 cadRepeat_rh, cadRepeat_lh, cadRepeat_bc,
 silence_rh, silence_lh, silence_bc] @=> Part allParts[];

// ============================================================
// Fragments
// ============================================================
[prelude_rh, prelude_lh] @=> Part preludeParts[];
Fragment fPrelude("Prelude", 1, preludeParts);

[expo_rh, expo_lh, expo_bc] @=> Part expoParts[];
Fragment fExposition("Exposition", 1, expoParts);

[devA_rh, devA_lh, devA_bc] @=> Part devAParts[];
Fragment fDevA("Development A", 1, devAParts);

[seq_rh, seq_lh, seq_bc] @=> Part seqParts[];
Fragment fSequence("Sequence", 1, seqParts);

[devB_rh, devB_lh, devB_bc] @=> Part devBParts[];
Fragment fDevB("Development B", 1, devBParts);

[recap_rh, recap_lh, recap_bc] @=> Part recapParts[];
Fragment fRecap("Recapitulation", 1, recapParts);

[cad_rh, cad_lh, cad_bc] @=> Part cadParts[];
Fragment fCadence("Cadence", 1, cadParts);

[coda_rh, coda_lh, coda_bc] @=> Part codaParts[];
Fragment fCoda("Coda", 1, codaParts);

[cadRepeat_rh, cadRepeat_lh, cadRepeat_bc] @=> Part cadRepeatParts[];
Fragment fCadenceRepeat("Cadence Repeat", 1, cadRepeatParts);

[silence_rh, silence_lh, silence_bc] @=> Part silenceParts[];
Fragment fSilence("Silence", 1, silenceParts);

// True silence: all three voices at 0.0 probability
// Reuses silence_lh and silence_bc (already 0.0); adds a matching RH
ChordProgression true_silence_rh(rightHand, silence_rh_chords, silence_offsets, true, 4, 2, silence_probs);
false => true_silence_rh.random;
0.0 => true_silence_rh.mutateProbabilityRange;
silence_vel @=> true_silence_rh.velocities;

[true_silence_rh, silence_lh, silence_bc] @=> Part trueSilenceParts[];
Fragment fTrueSilence("True Silence", 1, trueSilenceParts);

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

// Coda -> Cadence Repeat
FragmentTransition ft_coda_cadRepeat(fCadenceRepeat, 1.0);

// Cadence Repeat -> Silence (RH plays)
FragmentTransition ft_cadRepeat_silence(fSilence, 1.0);

// Silence (RH plays) -> True Silence (all silent)
FragmentTransition ft_silence_trueSilence(fTrueSilence, 1.0);

// True Silence -> end
FragmentTransition ft_end(fPrelude, 0.0);

// Wire the graph
[ft_toExpo]                              @=> fPrelude.nextFragments;
[ft_toDevA]                              @=> fExposition.nextFragments;
[ft_devA_seq,  ft_devA_devB]             @=> fDevA.nextFragments;
[ft_seq_devB,  ft_seq_recap]             @=> fSequence.nextFragments;
[ft_devB_recap, ft_devB_devA, ft_devB_seq] @=> fDevB.nextFragments;
[ft_recap_cad, ft_recap_devB]            @=> fRecap.nextFragments;
[ft_toCoda]                              @=> fCadence.nextFragments;
[ft_coda_cadRepeat]                      @=> fCoda.nextFragments;
[ft_cadRepeat_silence]                   @=> fCadenceRepeat.nextFragments;
[ft_silence_trueSilence]                 @=> fSilence.nextFragments;
[ft_end]                                 @=> fTrueSilence.nextFragments;

// ============================================================
// Create and play the song
// ============================================================
Song song("bq03", BPM, root, fPrelude, allParts);

song.play();
