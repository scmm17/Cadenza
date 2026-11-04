@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================
// darius01.ck -- Bluegrass breakdown with delayed drums
//
// Five bluegrass chord progressions in G major (root = 55):
//   A: Cabin Porch (I - IV - I - V7)            [Acoustic only]
//   B: Old Joe Modal (I - bVII - IV - I)        [Acoustic only]
//   C: Chorus Drive (IV - I - V7 - I)           [Drums enter]
//   D: Mountain Minor (vi - IV - I - V7 - ii - V7) [Full band + drums]
//   E: Salty Dog Turnaround (I - VI7 - II7 - V7 - I - V7) [Full band + drums -> Silence]
//
// Instrumentation:
//   - Guitar (flatpicking lead + boom-chuck rhythm)
//   - Mandolin (crosspicking lead + off-beat chop/tremolo)
//   - Fiddle (breakdown lead + long double-stop bow)
//   - Acoustic upright bass (alternating root-fifth + walking)
//   - Drums (SH-4d kit: kick/snare patterns, hats, and last-bar fills,
//            modelled after fanya01.ck; silent in sections A and B)
//
// Song structure:
//   - 5 progressions x 5 texture variants = 25 active fragments,
//     plus 1 Silence fragment (2 bars of 0.0 probability, like bq03.ck)
//     to mark the end of the song.
//   - Fragment transitions are randomised at start-up. Sections A and B
//     are purely acoustic and route forward into C, D, E where the drums
//     enter; section E routes to neighbours or to Silence to end the song.
// ============================================================

// Global parameters
132 => float BPM;
55 => int root;          // G3 -- G major

// ------------------------------------------------------------
// Devices -- Bluegrass band + SH-4d drum kit
// ------------------------------------------------------------
V3GrandPiano guitarLeadDev(1, "Guitar Steel", 105);
V3GrandPiano guitarRhythmDev(2, "Guitar Steel soft", 90);
V3GrandPiano mandolinLeadDev(3, "Mandoline Ensemble", 100);
V3GrandPiano mandolinChopDev(4, "Mandoline Ensemble Tremolo", 88);
V3GrandPiano fiddleLeadDev(5, "Celtic fiddle", 100);
V3GrandPiano fiddleBowDev(6, "Celtic fiddle (softer attack)", 85);
V3GrandPiano bassDev(7, "Upright Bass finger attack", 115);
RolandSH4d drumKit(10, "Drums", 43);

// ------------------------------------------------------------
// Bluegrass chord quality table: [3rd, 5th, 7th/6th/8ve, 9th/8ve]
// ------------------------------------------------------------
0 => int Q_maj;      // Major add9 (open-string ring)
1 => int Q_dom7;     // Dominant 7th / 9th (V7, bluesy I7, secondary doms)
2 => int Q_min7;     // Mountain minor 7th (vi, ii)
3 => int Q_sus4;     // Suspended 4th (embellishing I or V)
4 => int Q_maj6;     // Major 6th (IV6 / western swing colour)

fun int[] qualOf(int id)
{
    if (id == Q_maj)   { [4, 7, 12, 14] @=> int q[]; return q; }
    if (id == Q_dom7)  { [4, 7, 10, 14] @=> int q[]; return q; }
    if (id == Q_min7)  { [3, 7, 10, 14] @=> int q[]; return q; }
    if (id == Q_sus4)  { [5, 7, 12, 14] @=> int q[]; return q; }
    [4, 7, 9, 12] @=> int q[];   // Q_maj6
    return q;
}

// Builds one Chord per root/quality pair.
//  padVoicing == false: 9 notes ascending (R 3 5 7 9 | R+12 3+12 5+12 7+12)
//                       used as an index pool for melodies and bass lines
//  padVoicing == true:  5-note open double-stop / chord voicing
fun Chord[] voicings(int roots[], int quals[], int oct, int padVoicing)
{
    Chord @ out[roots.cap()];
    for (0 => int i; i < roots.cap(); i++)
    {
        roots[i] => int r;
        qualOf(quals[i]) @=> int q[];
        int notes[];
        if (padVoicing)
        {
            new int[5] @=> notes;
            r => notes[0];
            r + q[1] => notes[1];
            r + 12 => notes[2];
            r + 12 + q[0] => notes[3];
            r + 12 + q[1] => notes[4];
        }
        else
        {
            new int[9] @=> notes;
            r => notes[0];
            r + q[0] => notes[1];
            r + q[1] => notes[2];
            r + q[2] => notes[3];
            r + q[3] => notes[4];
            r + 12 => notes[5];
            r + q[0] + 12 => notes[6];
            r + q[1] + 12 => notes[7];
            r + q[2] + 12 => notes[8];
        }
        NoteCollection nc(notes);
        Chord c(nc, oct);
        c @=> out[i];
    }
    return out;
}

// ------------------------------------------------------------
// Part registry (everything must be listed for the Song)
// ------------------------------------------------------------
Part @ allP[0];

// Melody-style ChordProgression: `mel` holds indices into the chord's
// note pool; one index is consumed each time a note is played.
fun ChordProgression mkMel(Patch p, Chord ch[], int mel[], float probs[], float durs[], int vels[])
{
    int offs[ch.cap()];
    ChordProgression cp(p, ch, offs, true, 16, ch.cap(), probs);
    true => cp.useMelody;
    mel @=> cp.melody;
    vels @=> cp.velocities;
    durs @=> cp.durations;
    allP << cp;
    return cp;
}

// Long bowed double-stop / harmonic bed, one chord per bar.
fun ChordProgression mkBow(Patch p, Chord ch[])
{
    int offs[ch.cap()];
    [1.0] @=> float probs[];
    [76, 68, 62, 58, 54] @=> int vels[];
    ChordProgression cp(p, ch, offs, false, 1, ch.cap(), probs);
    vels @=> cp.velocities;
    allP << cp;
    return cp;
}

fun DrumMachine mkDrums(int notes[], float probs[], int vels[], int n)
{
    NoteCollection nc(notes);
    DrumMachine d(nc, 16, n, probs, drumKit);
    vels @=> d.velocities;
    allP << d;
    return d;
}

// Tom / clap / snare fill across the last bar of a section only (from fanya01.ck).
fun DrumMachine mkFill(int n)
{
    16 * n => int total;
    int notes[total];
    float probs[total];
    DrumMachine.HiTom() => int hi;
    DrumMachine.LowTom() => int lo;
    DrumMachine.Clap() => int cl;
    DrumMachine.SnareDrum() => int sn;
    [sn, cl, hi, hi, lo, hi, lo, lo] @=> int fillNotes[];
    [1.0, 0.5, 0.8, 0.7, 0.9, 0.6, 0.9, 1.0] @=> float fillProbs[];
    for (0 => int i; i < total; i++)
    {
        0 => notes[i];
        0.0 => probs[i];
    }
    (n - 1) * 16 => int start;
    for (0 => int i; i < 8; i++)
    {
        fillNotes[i] => notes[start + 8 + i];
        fillProbs[i] => probs[start + 8 + i];
    }
    // pick-up cymbal hit on beat 1 of the last bar
    DrumMachine.Cymbal() => notes[start];
    0.6 => probs[start];
    [100, 85, 95, 90, 100, 85, 95, 110] @=> int vels[];
    return mkDrums(notes, probs, vels, n);
}

// ------------------------------------------------------------
// Bluegrass rhythm / melody material
// ------------------------------------------------------------

// --- Guitar Lead: flatpicking 16th runs with Carter-style phrasing ---
[1.0, 0.6, 0.9, 0.5, 1.0, 0.0, 0.85, 0.6,
 1.0, 0.7, 0.9, 0.5, 0.95, 0.6, 0.8, 0.0] @=> float gtrLeadProbs[];
[0, 1, 2, 4, 5, 4, 2, 1, 2, 5, 6] @=> int gtrLeadMel[];
[0.95, 0.8, 0.9, 0.75] @=> float gtrLeadDurs[];
[112, 82, 96, 78, 105, 80] @=> int gtrLeadVel[];

// --- Guitar Rhythm: boom-chuck alternating bass + brush strum --------
[1.0, 0.0, 0.4, 0.0, 0.95, 0.0, 0.8, 0.0,
 1.0, 0.0, 0.4, 0.0, 0.95, 0.0, 0.85, 0.3] @=> float gtrRhythmProbs[];
[0, 4, 1, 2, 2, 5, 1, 4] @=> int gtrRhythmMel[];
[1.8, 0.9, 1.2, 0.9] @=> float gtrRhythmDurs[];
[105, 78, 92, 74] @=> int gtrRhythmVel[];

// --- Mandolin Lead: nimble crosspicking & syncopated rolls -----------
[1.0, 0.75, 0.9, 0.65, 0.95, 0.7, 0.0, 0.85,
 1.0, 0.7, 0.85, 0.6, 0.9, 0.0, 0.8, 0.65] @=> float mandoLeadProbs[];
[2, 5, 6, 7, 5, 4, 2, 6, 8, 7, 5, 2, 4] @=> int mandoLeadMel[];
[0.85, 0.7, 0.9, 0.65] @=> float mandoLeadDurs[];
[110, 80, 95, 75, 102, 78] @=> int mandoLeadVel[];

// --- Mandolin Chop: classic bluegrass backbeat chop on "&" / 2 & 4 ---
[0.0, 0.0, 0.6, 0.0, 1.0, 0.0, 0.7, 0.0,
 0.0, 0.0, 0.6, 0.0, 1.0, 0.0, 0.75, 0.3] @=> float mandoChopProbs[];
[6, 7, 5, 8, 6, 4, 7] @=> int mandoChopMel[];
[0.6, 0.5, 0.7] @=> float mandoChopDurs[];
[108, 84, 104, 80] @=> int mandoChopVel[];

// --- Fiddle Lead 1: driving hoe-down reel melody ---------------------
[1.0, 0.8, 0.95, 0.7, 1.0, 0.75, 0.9, 0.6,
 1.0, 0.8, 0.9, 0.0, 1.0, 0.7, 0.85, 0.65] @=> float fidReelProbs[];
[5, 6, 7, 8, 7, 5, 4, 2, 4, 5, 7] @=> int fidReelMel[];
[1.1, 0.9, 1.0, 0.85] @=> float fidReelDurs[];
[108, 86, 98, 82, 104] @=> int fidReelVel[];

// --- Fiddle Lead 2: high-lonesome call & response phrases ------------
[1.0, 0.0, 0.9, 0.8, 0.0, 1.0, 0.0, 0.85,
 0.9, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0] @=> float fidCallProbs[];
[7, 8, 6, 5, 7, 4, 5, 2, 0] @=> int fidCallMel[];
[2.2, 1.2, 1.8, 3.0] @=> float fidCallDurs[];
[105, 88, 96, 84] @=> int fidCallVel[];

// --- Acoustic Bass 1: classic bluegrass root-fifth on beats 1 and 3 --
[1.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0,
 1.0, 0.0, 0.0, 0.0, 0.3, 0.0, 0.4, 0.0] @=> float bass1Probs[];
[0, 2, 0, 2, 0, 2, 0, 1] @=> int bass1Mel[];
[3.2, 2.8, 3.2, 1.8] @=> float bass1Durs[];
[122, 108, 116, 98] @=> int bass1Vel[];

// --- Acoustic Bass 2: walking upright bass ---------------------------
[1.0, 0.0, 0.3, 0.0, 1.0, 0.0, 0.4, 0.0,
 1.0, 0.0, 0.3, 0.0, 1.0, 0.0, 0.7, 0.0] @=> float bass2Probs[];
[0, 1, 2, 4, 5, 4, 2, 1] @=> int bass2Mel[];
[2.0, 1.6, 2.0, 1.4] @=> float bass2Durs[];
[118, 100, 112, 96] @=> int bass2Vel[];

// --- Drums (fanya01.ck method) ---------------------------------------
DrumMachine.BassDrum() => int K;
DrumMachine.SnareDrum() => int S;
DrumMachine.Clap() => int C;
DrumMachine.ClosedHat() => int H;
DrumMachine.OpenHat() => int O;

// Kick/snare 1: driving backbeat on 2 and 4
[K, 0, 0, 0, S, 0, 0, K, 0, 0, K, 0, S, 0, 0, 0] @=> int ks1Notes[];
[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.9, 0.0, 1.0, 0.0, 0.0, 0.3] @=> float ks1Probs[];
// Kick/snare 2: train-beat / syncopated snare ghost notes + clap layer
[K, 0, 0, K, 0, 0, S, 0, 0, K, 0, 0, S, 0, K, C] @=> int ks2Notes[];
[1.0, 0.0, 0.0, 0.7, 0.0, 0.0, 1.0, 0.0, 0.0, 0.8, 0.0, 0.0, 1.0, 0.0, 0.6, 0.4] @=> float ks2Probs[];
// Kick/snare 3: half-time / breakdown stomp
[K, 0, 0, 0, 0, 0, 0, K, 0, 0, K, 0, S, 0, 0, 0] @=> int ks3Notes[];
[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.0, 0.0, 0.8, 0.0, 1.0, 0.0, 0.0, 0.4] @=> float ks3Probs[];
[125, 90, 90, 100, 120, 80, 85, 100, 90, 95, 110, 85, 120, 80, 85, 90] @=> int ksVel[];

// Hats 1: steady 8ths with occasional open hat
[H, 0, H, 0, H, 0, H, 0, H, 0, H, 0, H, 0, O, 0] @=> int h1Notes[];
[1.0, 0.0, 0.9, 0.0, 1.0, 0.0, 0.9, 0.0, 1.0, 0.0, 0.9, 0.0, 1.0, 0.0, 0.5, 0.0] @=> float h1Probs[];
// Hats 2: 16ths, ghosted
[H, H, H, H, H, H, H, H, H, H, H, H, H, H, H, O] @=> int h2Notes[];
[1.0, 0.4, 0.8, 0.5, 1.0, 0.4, 0.8, 0.6, 1.0, 0.4, 0.8, 0.5, 1.0, 0.5, 0.7, 0.35] @=> float h2Probs[];
[90, 45, 65, 45, 85, 45, 65, 50, 90, 45, 65, 45, 85, 50, 70, 80] @=> int hVel[];

// ------------------------------------------------------------
// Fragments -- 5 progressions x 5 textures + 1 Silence fragment
// ------------------------------------------------------------
5 => int NUM_GROUPS;
5 => int NUM_VARIANTS;
Fragment @ frags[NUM_GROUPS * NUM_VARIANTS];

// withDrums == 0 for early sections (A, B) so drums do not enter until later;
// withDrums == 1 for later sections (C, D, E).
fun void buildSection(int g, string gname, int roots[], int quals[], int withDrums)
{
    roots.cap() => int n;

    voicings(roots, quals, 1, false) @=> Chord hi[];
    voicings(roots, quals, 0, false) @=> Chord mid[];
    voicings(roots, quals, -1, false) @=> Chord lo[];
    voicings(roots, quals, 0, true) @=> Chord bowChords[];

    mkMel(guitarLeadDev,   mid, gtrLeadMel,   gtrLeadProbs,   gtrLeadDurs,   gtrLeadVel)   @=> ChordProgression gtrLead;
    mkMel(guitarRhythmDev, mid, gtrRhythmMel, gtrRhythmProbs, gtrRhythmDurs, gtrRhythmVel) @=> ChordProgression gtrRhythm;
    mkMel(mandolinLeadDev, hi,  mandoLeadMel, mandoLeadProbs, mandoLeadDurs, mandoLeadVel) @=> ChordProgression mandoLead;
    mkMel(mandolinChopDev, hi,  mandoChopMel, mandoChopProbs, mandoChopDurs, mandoChopVel) @=> ChordProgression mandoChop;
    mkMel(fiddleLeadDev,   hi,  fidReelMel,   fidReelProbs,   fidReelDurs,   fidReelVel)   @=> ChordProgression fidReel;
    mkMel(fiddleLeadDev,   hi,  fidCallMel,   fidCallProbs,   fidCallDurs,   fidCallVel)   @=> ChordProgression fidCall;
    mkBow(fiddleBowDev,    bowChords)                                                      @=> ChordProgression fidBow;
    mkMel(bassDev,         lo,  bass1Mel,     bass1Probs,     bass1Durs,     bass1Vel)     @=> ChordProgression bass1;
    mkMel(bassDev,         lo,  bass2Mel,     bass2Probs,     bass2Durs,     bass2Vel)     @=> ChordProgression bass2;

    g * NUM_VARIANTS => int base;

    if (!withDrums)
    {
        // Acoustic-only variants (Sections A and B -- before drums enter)
        // 0: porch picking -- bass, rhythm guitar, flatpicking guitar lead
        [bass1, gtrRhythm, gtrLead] @=> Part p0[];
        Fragment f0(gname + " porch", 1, p0);
        f0 @=> frags[base + 0];

        // 1: mandolin feature -- bass, rhythm guitar, mandolin chop & lead
        [bass1, gtrRhythm, mandoChop, mandoLead] @=> Part p1[];
        Fragment f1(gname + " mandolin", 1, p1);
        f1 @=> frags[base + 1];

        // 2: high lonesome -- bass, fiddle double-stops, fiddle call & mandolin chop
        [bass1, fidBow, fidCall, mandoChop] @=> Part p2[];
        Fragment f2(gname + " lonesome", 1, p2);
        f2 @=> frags[base + 2];

        // 3: acoustic breakdown -- full acoustic stringband trading runs
        [bass2, gtrRhythm, mandoChop, gtrLead, fidReel] @=> Part p3[];
        Fragment f3(gname + " stringband", 2, p3);
        f3 @=> frags[base + 3];

        // 4: twin leads -- walking bass, mandolin lead & fiddle reel
        [bass2, mandoLead, fidReel, fidBow] @=> Part p4[];
        Fragment f4(gname + " twin", 1, p4);
        f4 @=> frags[base + 4];
    }
    else
    {
        // Full band with drums (Sections C, D, E -- drums enter and drive the tune)
        mkDrums(ks1Notes, ks1Probs, ksVel, n) @=> DrumMachine ks1;
        mkDrums(ks2Notes, ks2Probs, ksVel, n) @=> DrumMachine ks2;
        mkDrums(ks3Notes, ks3Probs, ksVel, n) @=> DrumMachine ks3;
        mkDrums(h1Notes, h1Probs, hVel, n) @=> DrumMachine h1;
        mkDrums(h2Notes, h2Probs, hVel, n) @=> DrumMachine h2;
        mkFill(n) @=> DrumMachine fill;

        // 0: groove -- root-fifth bass, guitar lead, mandolin chop, straight drums
        [bass1, gtrRhythm, gtrLead, mandoChop, ks1, h1] @=> Part p0[];
        Fragment f0(gname + " groove", 1, p0);
        f0 @=> frags[base + 0];

        // 1: pluck -- walking bass, mandolin lead, fiddle call, broken train-beat drums
        [bass2, gtrRhythm, mandoLead, fidCall, ks2, h2] @=> Part p1[];
        Fragment f1(gname + " pluck", 1, p1);
        f1 @=> frags[base + 1];

        // 2: breakdown -- fiddle bow, fiddle reel, mandolin chop, hats only
        [bass1, fidBow, fidReel, mandoChop, h1] @=> Part p2[];
        Fragment f2(gname + " breakdown", 1, p2);
        f2 @=> frags[base + 2];

        // 3: full -- all instruments blazing, twice through with tom/clap fill
        [bass2, gtrRhythm, gtrLead, mandoChop, mandoLead, fidBow, fidReel, ks1, h2, fill] @=> Part p3[];
        Fragment f3(gname + " full", 2, p3);
        f3 @=> frags[base + 3];

        // 4: halftime -- walking bass, fiddle call, guitar lead, half-time stomp + fill
        [bass2, fidBow, fidCall, gtrLead, ks3, h1, fill] @=> Part p4[];
        Fragment f4(gname + " halftime", 1, p4);
        f4 @=> frags[base + 4];
    }
}

// ------------------------------------------------------------
// The five bluegrass progressions (roots are semitones from G)
// ------------------------------------------------------------

// A: Cabin Porch (Acoustic, no drums)          G | C | G | D7
buildSection(0, "A",
    [0, 5, 0, -5],
    [Q_maj, Q_maj6, Q_maj, Q_dom7],
    0);

// B: Old Joe Modal (Acoustic, no drums)        G | F | C | G
buildSection(1, "B",
    [0, -2, 5, 0],
    [Q_maj, Q_maj, Q_maj6, Q_maj],
    0);

// C: Chorus Drive (Drums enter!)               C | G | D7 | G
buildSection(2, "C",
    [5, 0, -5, 0],
    [Q_maj6, Q_maj, Q_dom7, Q_maj],
    1);

// D: Mountain Minor (Full band + drums)        Em7 | C | G | D7 | Am7 | D7
buildSection(3, "D",
    [-3, 5, 0, -5, 2, -5],
    [Q_min7, Q_maj, Q_maj, Q_dom7, Q_min7, Q_dom7],
    1);

// E: Salty Dog Turnaround (Full band + drums)  G | E7 | A7 | D7 | Gsus4 | D7
buildSection(4, "E",
    [0, -3, 2, -5, 0, -5],
    [Q_maj, Q_dom7, Q_dom7, Q_dom7, Q_sus4, Q_dom7],
    1);

// ------------------------------------------------------------
// SILENCE: 2 bars of silence (0.0 probability) to mark the end
// of the song, like in bq03.ck
// ------------------------------------------------------------
["0.0"] @=> string silenceProbs[];
voicings([0, 0], [Q_maj, Q_maj], 0, false) @=> Chord silenceChords[];
[0, 0] @=> int silenceOffsets[];
[0] @=> int silenceVel[];

fun ChordProgression mkSilentPart(Patch p)
{
    ChordProgression cp(p, silenceChords, silenceOffsets, true, 4, 2, silenceProbs);
    false => cp.random;
    0.0 => cp.mutateProbabilityRange;
    silenceVel @=> cp.velocities;
    allP << cp;
    return cp;
}

mkSilentPart(guitarLeadDev)   @=> ChordProgression silGtrLead;
mkSilentPart(guitarRhythmDev) @=> ChordProgression silGtrRhythm;
mkSilentPart(mandolinLeadDev) @=> ChordProgression silMandoLead;
mkSilentPart(mandolinChopDev) @=> ChordProgression silMandoChop;
mkSilentPart(fiddleLeadDev)   @=> ChordProgression silFidLead;
mkSilentPart(fiddleBowDev)    @=> ChordProgression silFidBow;
mkSilentPart(bassDev)         @=> ChordProgression silBass;

[0, 0, 0, 0, 0, 0, 0, 0] @=> int silDrumNotes[];
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] @=> float silDrumProbs[];
mkDrums(silDrumNotes, silDrumProbs, silenceVel, 2) @=> DrumMachine silDrums;

[silGtrLead, silGtrRhythm, silMandoLead, silMandoChop,
 silFidLead, silFidBow, silBass, silDrums] @=> Part silenceParts[];
Fragment fSilence("Silence", 1, silenceParts);

// ------------------------------------------------------------
// Random transition graph (fanya01.ck style, staged for delayed
// drums and ending on Silence)
//
// - Group 0 (A, acoustic): siblings in A or forward to B (also acoustic)
// - Group 1 (B, acoustic): siblings in B or forward into drum groups C, D
// - Groups 2 & 3 (C, D, with drums): siblings or neighbouring drum groups C, D, E
// - Group 4 (E, with drums): siblings, drum neighbours C & D, or Silence
// - Silence: end of song (0.0 probability transition, like bq03.ck)
// ------------------------------------------------------------
fun void link(Fragment from, Fragment tos[], float w[])
{
    0.0 => float sum;
    for (0 => int i; i < tos.cap(); i++)
    {
        w[i] +=> sum;
    }
    FragmentTransition @ fts[tos.cap()];
    for (0 => int i; i < tos.cap(); i++)
    {
        new FragmentTransition(tos[i], w[i] / sum) @=> fts[i];
    }
    fts @=> from.nextFragments;
}

// Neighbouring progressions for each group:
//   A (0) -> [1]       (stays acoustic in B first so drums wait until later)
//   B (1) -> [2, 3]    (crosses into drum-backed sections C and D)
//   C (2) -> [3, 4]    (stays in drum-backed sections)
//   D (3) -> [4, 2]    (stays in drum-backed sections)
//   E (4) -> [2, 3]    (plus Silence to end the song)
[[1], [2, 3], [3, 4], [4, 2], [2, 3]] @=> int neighbours[][];

for (0 => int g; g < NUM_GROUPS; g++)
{
    neighbours[g].cap() => int numNeigh;
    (g == 4 ? 1 : 0) => int hasSilence;
    for (0 => int v; v < NUM_VARIANTS; v++)
    {
        g * NUM_VARIANTS + v => int idx;
        (NUM_VARIANTS - 1) + numNeigh * NUM_VARIANTS + hasSilence => int totalEdges;
        Fragment @ tos[totalEdges];
        float w[totalEdges];
        0 => int k;

        // If golden mode is used (picks index 0), make index 0 step forward cleanly
        if (v < NUM_VARIANTS - 1)
        {
            frags[g * NUM_VARIANTS + v + 1] @=> tos[k];
            Math.random2f(1.5, 3.5) => w[k];
            k++;
        }
        else if (hasSilence)
        {
            fSilence @=> tos[k];
            Math.random2f(2.5, 4.5) => w[k];
            k++;
        }

        // Neighbouring progressions (put first when at the last variant of A..D
        // so golden mode steps cleanly A -> B -> C -> D -> E -> Silence)
        if (v == NUM_VARIANTS - 1 && !hasSilence)
        {
            for (0 => int ni; ni < numNeigh; ni++)
            {
                neighbours[g][ni] => int ng;
                for (0 => int nv; nv < NUM_VARIANTS; nv++)
                {
                    frags[ng * NUM_VARIANTS + nv] @=> tos[k];
                    Math.random2f(0.8, 2.2) => w[k];
                    k++;
                }
            }
        }

        // Remaining siblings in the same progression
        for (0 => int sv; sv < NUM_VARIANTS; sv++)
        {
            if (sv == v || sv == v + 1) continue;
            frags[g * NUM_VARIANTS + sv] @=> tos[k];
            Math.random2f(1.0, 2.8) => w[k];
            k++;
        }

        // Neighbouring progressions (for all other cases)
        if (v < NUM_VARIANTS - 1 || hasSilence)
        {
            for (0 => int ni; ni < numNeigh; ni++)
            {
                neighbours[g][ni] => int ng;
                for (0 => int nv; nv < NUM_VARIANTS; nv++)
                {
                    frags[ng * NUM_VARIANTS + nv] @=> tos[k];
                    Math.random2f(0.5, 2.0) => w[k];
                    k++;
                }
            }
        }

        // Group E non-last variants can also transition to Silence
        if (hasSilence && v < NUM_VARIANTS - 1)
        {
            fSilence @=> tos[k];
            Math.random2f(1.8, 3.5) => w[k];
            k++;
        }

        link(frags[idx], tos, w);
    }
}

// Silence -> end (0.0 probability, like bq03.ck)
FragmentTransition ft_end(frags[0], 0.0);
[ft_end] @=> fSilence.nextFragments;

Song song("darius01", BPM, root, frags[0], allP);

song.play();
