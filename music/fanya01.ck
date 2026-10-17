@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================
// fanya01.ck -- Extended-harmony groove with melody fragments
//
// Five chord progressions in D (minor / dorian / lydian colours,
// chromatic mediants, descending chromatic bass, rising lydian),
// built from extended chords (m9, maj9, maj7#11, 7b9, 7#9, m11,
// m7b5, sus9) rather than the plain triads of the bq songs.
//
// Each progression ("section") is realised as 5 fragments that
// use different mixes of:
//   - 6 lead melodies, each a ChordProgression with useMelody=true
//     (a short index pattern run through the current chord, with its
//      own rhythm / duration pattern). Pattern lengths are mutually
//     prime-ish so the melodies phase against the harmony.
//   - an arpeggiator, 2 basses, a pad
//   - kick/snare, hats and fill drum parts
//
// Fragment transitions are randomised at start-up: every fragment
// can move to its siblings (same chords, other texture) or to any
// fragment of a neighbouring progression, with random weights.
// ============================================================

// Global parameters
100 => float BPM;
50 => int root;          // D

// ------------------------------------------------------------
// Devices -- V3 "Synthesizer" category presets
// ------------------------------------------------------------
V3GrandPiano lead1Dev(1, "OBLead", 100);
V3GrandPiano lead2Dev(2, "FMPluk", 95);
V3GrandPiano lead3Dev(3, "Bellz", 90);
V3GrandPiano lead4Dev(4, "SquareLead", 85);
V3GrandPiano lead5Dev(5, "Hook", 95);
V3GrandPiano lead6Dev(6, "Xypho", 90);
V3GrandPiano arpDev(7, "Polysynth Classic", 90);
V3GrandPiano bass1Dev(8, "Classic Synth Bass", 110);
V3GrandPiano bass2Dev(9, "JBass 1", 105);
V3GrandPiano padDev(11, "Soft Pad", 85);
RolandSH4d drumKit(10, "Drums", 43);

// ------------------------------------------------------------
// Chord quality table: [3rd, 5th, 7th, 9th/11th] in semitones
// ------------------------------------------------------------
0 => int Q_m9;
1 => int Q_maj9;
2 => int Q_maj7s11;
3 => int Q_dom9;
4 => int Q_7b9;
5 => int Q_7s9;
6 => int Q_m11;
7 => int Q_m7b5;
8 => int Q_sus9;

fun int[] qualOf(int id)
{
    if (id == Q_m9)       { [3, 7, 10, 14] @=> int q[]; return q; }
    if (id == Q_maj9)     { [4, 7, 11, 14] @=> int q[]; return q; }
    if (id == Q_maj7s11)  { [4, 7, 11, 18] @=> int q[]; return q; }
    if (id == Q_dom9)     { [4, 7, 10, 14] @=> int q[]; return q; }
    if (id == Q_7b9)      { [4, 7, 10, 13] @=> int q[]; return q; }
    if (id == Q_7s9)      { [4, 7, 10, 15] @=> int q[]; return q; }
    if (id == Q_m11)      { [3, 7, 10, 17] @=> int q[]; return q; }
    if (id == Q_m7b5)     { [3, 6, 10, 14] @=> int q[]; return q; }
    [5, 7, 10, 14] @=> int q[];   // sus9
    return q;
}

// Builds one Chord per root/quality pair.
//  padVoicing == false: 9 notes, ascending, used as an index pool for
//                       melodies:  R 3 5 7 9 | R+12 3+12 5+12 7+12
//  padVoicing == true:  5-note open voicing for block chords
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
            r + q[2] => notes[1];
            r + 12 + q[0] => notes[2];
            r + 12 + q[1] => notes[3];
            r + 12 + q[3] => notes[4];
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

// Block-chord pad, one chord per bar.
fun ChordProgression mkPad(Patch p, Chord ch[])
{
    int offs[ch.cap()];
    [1.0] @=> float probs[];
    [72, 58, 60, 56, 54] @=> int vels[];
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

// Tom / clap fill across the last bar of a section only.
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
    // a pick-up hit before the bar line on the last bar
    DrumMachine.Cymbal() => notes[start];
    0.6 => probs[start];
    [100, 85, 95, 90, 100, 85, 95, 110] @=> int vels[];
    return mkDrums(notes, probs, vels, n);
}

// ------------------------------------------------------------
// Rhythm / melody material
// ------------------------------------------------------------

// --- Lead 1: tresillo (3+3+2+3+3+2), long notes -------------
[1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0,
 1.0, 0.0, 0.0, 0.9, 0.0, 0.0, 0.8, 0.0] @=> float l1Probs[];
[4, 6, 5, 8, 6, 4, 5, 3, 2] @=> int l1Mel[];
[-1.0] @=> float l1Durs[];
[110, 90, 100, 85, 95] @=> int l1Vel[];

// --- Lead 2: busy plucked 16ths, accents at odd places -------
[1.0, 0.6, 0.8, 0.5, 0.9, 0.0, 0.7, 0.6,
 1.0, 0.5, 0.0, 0.8, 0.6, 0.7, 0.0, 0.5] @=> float l2Probs[];
[0, 2, 4, 2, 5, 4, 7, 5, 6, 8, 4] @=> int l2Mel[];
[0.9, 0.7, 0.8, 0.6] @=> float l2Durs[];
[105, 70, 80, 65, 95, 70] @=> int l2Vel[];

// --- Lead 3: sparse bells on off-beat points, long ring -----
[0.0, 0.0, 0.9, 0.0, 0.0, 0.0, 0.0, 0.8,
 0.0, 0.0, 0.9, 0.0, 0.0, 0.7, 0.0, 0.0] @=> float l3Probs[];
[8, 6, 7, 4, 5, 3] @=> int l3Mel[];
[4.0, 3.0, 5.0] @=> float l3Durs[];
[95, 80, 88] @=> int l3Vel[];

// --- Lead 4: 3+3+3+3+4 syncopation ---------------------------
[1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0,
 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.7] @=> float l4Probs[];
[2, 4, 3, 5, 4, 6, 5, 7, 6] @=> int l4Mel[];
[2.5, 2.5, 2.0] @=> float l4Durs[];
[100, 80, 90, 75] @=> int l4Vel[];

// --- Lead 5: call (first half) and silence (response) -------
[1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0,
 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] @=> float l5Probs[];
[5, 7, 8, 7, 5, 4, 5, 2] @=> int l5Mel[];
[1.5, 0.5, 1.0, -1.0] @=> float l5Durs[];
[105, 85, 95, 80] @=> int l5Vel[];

// --- Lead 6: groups-of-5 pulse -------------------------------
[1.0, 0.0, 0.8, 1.0, 0.0, 0.8, 1.0, 0.0,
 0.8, 1.0, 0.0, 0.8, 1.0, 0.0, 0.8, 0.0] @=> float l6Probs[];
[0, 4, 2, 6, 4, 8, 6, 3, 1, 5] @=> int l6Mel[];
[1.0, 1.0, 1.5] @=> float l6Durs[];
[100, 75, 85, 70, 90] @=> int l6Vel[];

// --- Arpeggiator: 8th notes up and down ----------------------
[1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0,
 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.9, 0.5] @=> float arpProbs[];
[0, 2, 4, 2, 0, 3, 5, 3] @=> int arpMel[];
[1.6] @=> float arpDurs[];
[90, 65, 75, 62] @=> int arpVel[];

// --- Bass 1: syncopated root / octave / fifth ----------------
[1.0, 0.0, 0.0, 0.8, 0.0, 0.0, 1.0, 0.0,
 0.0, 0.6, 1.0, 0.0, 0.0, 0.0, 0.7, 0.0] @=> float b1Probs[];
[0, 0, 5, 0, 2, 0, 5, 3] @=> int b1Mel[];
[2.0, 1.5, 3.0, 1.0] @=> float b1Durs[];
[120, 95, 105, 90] @=> int b1Vel[];

// --- Bass 2: bouncing octaves --------------------------------
[1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.8, 1.0,
 1.0, 0.0, 1.0, 0.0, 0.8, 0.0, 1.0, 0.0] @=> float b2Probs[];
[0, 5, 0, 5, 0, 2, 0, 3] @=> int b2Mel[];
[1.5] @=> float b2Durs[];
[115, 90, 100, 88] @=> int b2Vel[];

// --- Drums ---------------------------------------------------
DrumMachine.BassDrum() => int K;
DrumMachine.SnareDrum() => int S;
DrumMachine.Clap() => int C;
DrumMachine.ClosedHat() => int H;
DrumMachine.OpenHat() => int O;

// Kick/snare 1: driving, snare on 2 and 4
[K, 0, 0, 0, S, 0, 0, K, 0, 0, K, 0, S, 0, 0, 0] @=> int ks1Notes[];
[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.9, 0.0, 1.0, 0.0, 0.0, 0.3] @=> float ks1Probs[];
// Kick/snare 2: broken, snare ghost notes + clap layer
[K, 0, 0, K, 0, 0, S, 0, 0, K, 0, 0, S, 0, K, C] @=> int ks2Notes[];
[1.0, 0.0, 0.0, 0.7, 0.0, 0.0, 1.0, 0.0, 0.0, 0.8, 0.0, 0.0, 1.0, 0.0, 0.6, 0.4] @=> float ks2Probs[];
// Kick/snare 3: half-time
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
// Fragments -- 5 progressions x 5 textures
// ------------------------------------------------------------
5 => int NUM_GROUPS;
5 => int NUM_VARIANTS;
Fragment @ frags[NUM_GROUPS * NUM_VARIANTS];

fun void buildSection(int g, string gname, int roots[], int quals[])
{
    roots.cap() => int n;

    voicings(roots, quals, 1, false) @=> Chord hi[];
    voicings(roots, quals, 0, false) @=> Chord mid[];
    voicings(roots, quals, -1, false) @=> Chord lo[];
    voicings(roots, quals, 0, true) @=> Chord padChords[];

    mkMel(lead1Dev, hi,  l1Mel, l1Probs, l1Durs, l1Vel) @=> ChordProgression l1;
    mkMel(lead2Dev, mid, l2Mel, l2Probs, l2Durs, l2Vel) @=> ChordProgression l2;
    mkMel(lead3Dev, hi,  l3Mel, l3Probs, l3Durs, l3Vel) @=> ChordProgression l3;
    mkMel(lead4Dev, mid, l4Mel, l4Probs, l4Durs, l4Vel) @=> ChordProgression l4;
    mkMel(lead5Dev, hi,  l5Mel, l5Probs, l5Durs, l5Vel) @=> ChordProgression l5;
    mkMel(lead6Dev, mid, l6Mel, l6Probs, l6Durs, l6Vel) @=> ChordProgression l6;
    mkMel(arpDev,   mid, arpMel, arpProbs, arpDurs, arpVel) @=> ChordProgression arp;
    mkMel(bass1Dev, lo,  b1Mel, b1Probs, b1Durs, b1Vel) @=> ChordProgression bass1;
    mkMel(bass2Dev, lo,  b2Mel, b2Probs, b2Durs, b2Vel) @=> ChordProgression bass2;
    mkPad(padDev, padChords) @=> ChordProgression pad;

    mkDrums(ks1Notes, ks1Probs, ksVel, n) @=> DrumMachine ks1;
    mkDrums(ks2Notes, ks2Probs, ksVel, n) @=> DrumMachine ks2;
    mkDrums(ks3Notes, ks3Probs, ksVel, n) @=> DrumMachine ks3;
    mkDrums(h1Notes, h1Probs, hVel, n) @=> DrumMachine h1;
    mkDrums(h2Notes, h2Probs, hVel, n) @=> DrumMachine h2;
    mkFill(n) @=> DrumMachine fill;

    g * NUM_VARIANTS => int base;

    // 0: groove -- bass 1, pad, tresillo lead, straight drums
    [bass1, pad, l1, ks1, h1] @=> Part p0[];
    Fragment f0(gname + " groove", 1, p0);
    f0 @=> frags[base + 0];

    // 1: pluck -- bouncing bass, arp, two syncopated leads
    [bass2, arp, l2, l4, ks2, h2] @=> Part p1[];
    Fragment f1(gname + " pluck", 1, p1);
    f1 @=> frags[base + 1];

    // 2: breakdown -- pad, bells, call-and-response, hats only
    [pad, l3, l5, h1] @=> Part p2[];
    Fragment f2(gname + " breakdown", 1, p2);
    f2 @=> frags[base + 2];

    // 3: full -- everything but the kitchen sink, twice through
    [bass1, pad, arp, l1, l6, ks1, h2, fill] @=> Part p3[];
    Fragment f3(gname + " full", 2, p3);
    f3 @=> frags[base + 3];

    // 4: half-time bells -- bass 2, bells, square lead
    [bass2, l3, l4, ks3, h1, fill] @=> Part p4[];
    Fragment f4(gname + " halftime", 1, p4);
    f4 @=> frags[base + 4];
}

// ------------------------------------------------------------
// The five progressions (roots are semitones from D)
// ------------------------------------------------------------

// A: modal / dorian lift       Dm9 | Bbmaj7#11 | Fmaj9 | C7sus9
buildSection(0, "A",
    [0, -4, 3, -2],
    [Q_m9, Q_maj7s11, Q_maj9, Q_sus9]);

// B: subdominant colours       Gm9 | Ebmaj9 | Bbmaj7#11 | A7b9
buildSection(1, "B",
    [5, 1, -4, -5],
    [Q_m9, Q_maj9, Q_maj7s11, Q_7b9]);

// C: Picardy brightness        Dmaj9 | F#m11 | Bm9 | E9
buildSection(2, "C",
    [0, 4, -3, 2],
    [Q_maj9, Q_m11, Q_m9, Q_dom9]);

// D: descending chromatic bass Dm9 | C#m7b5 | Cmaj7#11 | Bbmaj9 | Gm11 | A7b9
buildSection(3, "D",
    [0, -1, -2, -4, -7, -5],
    [Q_m9, Q_m7b5, Q_maj7s11, Q_maj9, Q_m11, Q_7b9]);

// E: rising lydian              Dm9 | Emaj7#11 | Fmaj7#11 | Gm9 | Abmaj7#11 | A7#9
buildSection(4, "E",
    [0, 2, 3, 5, 6, -5],
    [Q_m9, Q_maj7s11, Q_maj7s11, Q_m9, Q_maj7s11, Q_7s9]);

// ------------------------------------------------------------
// Random transition graph
//
// Each fragment may continue to:
//   - any sibling texture of the same progression (higher weight)
//   - any texture of the neighbouring progressions (lower weight)
// Weights are randomised at start-up, then normalised.
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

// Neighbouring progressions for each group
[[1, 2, 3], [0, 2, 4], [1, 3, 0], [0, 4, 1], [2, 3, 0]] @=> int neighbours[][];

for (0 => int g; g < NUM_GROUPS; g++)
{
    for (0 => int v; v < NUM_VARIANTS; v++)
    {
        g * NUM_VARIANTS + v => int idx;
        Fragment @ tos[(NUM_VARIANTS - 1) + 3 * NUM_VARIANTS];
        float w[(NUM_VARIANTS - 1) + 3 * NUM_VARIANTS];
        0 => int k;
        // siblings
        for (0 => int sv; sv < NUM_VARIANTS; sv++)
        {
            if (sv == v) continue;
            frags[g * NUM_VARIANTS + sv] @=> tos[k];
            Math.random2f(1.5, 4.0) => w[k];
            k++;
        }
        // neighbouring progressions
        for (0 => int ni; ni < 3; ni++)
        {
            neighbours[g][ni] => int ng;
            for (0 => int nv; nv < NUM_VARIANTS; nv++)
            {
                frags[ng * NUM_VARIANTS + nv] @=> tos[k];
                Math.random2f(0.2, 1.5) => w[k];
                k++;
            }
        }
        link(frags[idx], tos, w);
    }
}

Song song("fanya01", BPM, root, frags[0], allP);

song.play();
