@import "../framework/cadenza.ck"

// ============================================================
// Windham01.ck -- Meditative New Age piece in the Windham Hill style
//
// Style notes (George Winston / William Ackerman / Alex de Grassi):
//   - Open, ringing voicings: add9, sus2, 7sus4, maj7, min9, Lydian maj7#11
//   - Pedal tones in the bass, slow cyclical modal progressions
//   - Rolling arpeggios, sparse folk-like melodies, lots of space
//   - No drums
//
// Key: D major / modal (root = 50, D3). Each chord lasts 2 bars.
//
//   A: Meadow        Dadd9    | Gmaj7  | Dadd9    | A7sus4
//   B: Pedal Tone    Dsus2    | Cadd9  | Gmaj7    | Dsus2
//   C: Autumn        Bm9      | Gmaj7  | Dadd9    | A7sus4
//   D: Lydian Float  Gmaj7#11 | Dadd9  | Gmaj7#11 | Em9
//   E: Dorian Drift  Em9 | A7sus4 | Em9 | Gmaj7 | F#m7 | A7sus4
//   Ending:          Gmaj7 | A7sus4 | Dadd9 (held)
//   Silence:         4 bars of rest, then loop back to A
//
// Devices (never more than 4 playing at once):
//   1 Piano ostinato      5 Vibraphone melody
//   2 Nylon guitar        6 Fretless bass pedal
//   3 Harp                7 Hydrasynth pad
//   4 Flute lead          8 SH-4d soft bell
//
// Structure (like darius01.ck): 5 progressions x 5 sparse variants.
// Variant 3 of each progression is a double-time fragment.
// Transitions are randomised at start-up; section E can lead to
// the Ending -> Silence -> back to the start.
// ============================================================

72 => float BPM;
50 => int root;          // D3

// ------------------------------------------------------------
// Devices
// ------------------------------------------------------------
V3GrandPiano pianoDev(1, "Grand Piano Vienna - softer", 92);
V3GrandPiano guitarDev(2, "Guitar Nylon soft", 92);
V3GrandPiano harpDev(3, "Harp long", 84);
V3GrandPiano fluteDev(4, "Flute", 80);
V3GrandPiano vibeDev(5, "Vibraphone Tremolo soft", 80);
V3GrandPiano bassDev(6, "EBass Fretless", 88);
Hydrasynth padDev("Etherpad RJ", 82);
RolandSH4d bellDev(1, "Soft Bell", 78);

// ------------------------------------------------------------
// Chord qualities: [3rd, 5th, 7th/8ve, colour tone]
// ------------------------------------------------------------
0 => int Q_add9;
1 => int Q_maj7;
2 => int Q_sus2;
3 => int Q_sus4;
4 => int Q_min9;
5 => int Q_lyd;

fun int[] qualOf(int id)
{
    if (id == Q_add9) { [4, 7, 12, 14] @=> int q[]; return q; }
    if (id == Q_maj7) { [4, 7, 11, 14] @=> int q[]; return q; }
    if (id == Q_sus2) { [2, 7, 12, 14] @=> int q[]; return q; }
    if (id == Q_sus4) { [5, 7, 10, 14] @=> int q[]; return q; }
    if (id == Q_min9) { [3, 7, 10, 14] @=> int q[]; return q; }
    [4, 7, 11, 18] @=> int q[];   // Q_lyd
    return q;
}

// Repeat every entry k times (slow harmonic rhythm).
fun int[] stretch(int a[], int k)
{
    int out[a.cap() * k];
    for (0 => int i; i < a.cap(); i++)
    {
        for (0 => int j; j < k; j++)
        {
            a[i] => out[i * k + j];
        }
    }
    return out;
}

// padVoicing == false: 9-note pool (R 3 5 7 9 | R+12 3+12 5+12 7+12)
// padVoicing == true:  5-note open spread (R 5 9 | 3+12 7+12)
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
            r + q[3] => notes[2];
            r + 12 + q[0] => notes[3];
            r + 12 + q[2] => notes[4];
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
// Part registry
// ------------------------------------------------------------
Part @ allP[0];

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

// Build a 32-step (2-bar) array of zeros with values at given steps.
fun float[] steps32(int idx[], float vals[])
{
    float out[32];
    for (0 => int i; i < 32; i++) { 0.0 => out[i]; }
    for (0 => int i; i < idx.cap(); i++) { vals[i] => out[idx[i]]; }
    return out;
}

// ------------------------------------------------------------
// Rhythm / melody material (16 steps per bar, many 2-bar cycles)
// ------------------------------------------------------------

// Pad: rolled open chord at the start of every 2 bars, sustained.
steps32([0, 1, 2, 3, 4], [1.0, 1.0, 1.0, 1.0, 1.0]) @=> float padProbs[];
steps32([0, 1, 2, 3, 4], [31.5, 30.5, 29.5, 28.5, 27.5]) @=> float padDurs[];
[0, 1, 2, 3, 4] @=> int padMel[];
[58, 50, 48, 46, 44] @=> int padVel[];

// Bass: pedal tone, one long note every 2 bars, occasional fifth.
steps32([0, 24], [1.0, 0.25]) @=> float bassProbs[];
steps32([0, 24], [31.0, 7.5]) @=> float bassDurs[];
[0, 2, 0, 0, 2, 0] @=> int bassMel[];
[70, 52] @=> int bassVel[];

// Piano: gentle rolling left-hand 8ths (Winston style), soft.
[1.0, 0.0, 0.55, 0.0, 0.8, 0.0, 0.5, 0.0,
 0.9, 0.0, 0.5, 0.0, 0.7, 0.0, 0.35, 0.0] @=> float pianoProbs[];
[0, 2, 4, 5, 4, 2] @=> int pianoMel[];
[3.5, 3.0, 3.0, 2.5] @=> float pianoDurs[];
[66, 50, 56, 48, 60, 46] @=> int pianoVel[];

// Piano double-time: continuous rolling 16ths.
[1.0, 0.75, 0.9, 0.7, 0.95, 0.7, 0.85, 0.65,
 1.0, 0.75, 0.9, 0.7, 0.95, 0.7, 0.8, 0.55] @=> float pianoDTProbs[];
[0, 2, 4, 5, 6, 5, 4, 2] @=> int pianoDTMel[];
[2.5, 1.8, 2.0, 1.6] @=> float pianoDTDurs[];
[70, 48, 58, 46, 64, 46, 56, 44] @=> int pianoDTVel[];

// Guitar: sparse fingerpicked arpeggio (Ackerman style).
[0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.0,
 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0, 0.0] @=> float guitarProbs[];
[0, 4, 2, 6, 5, 2] @=> int guitarMel[];
[6.0, 5.0, 6.0] @=> float guitarDurs[];
[64, 52, 58] @=> int guitarVel[];

// Guitar double-time: Travis-style 16th pattern.
[1.0, 0.6, 0.85, 0.6, 0.9, 0.6, 0.85, 0.5,
 1.0, 0.6, 0.85, 0.6, 0.9, 0.6, 0.8, 0.45] @=> float guitarDTProbs[];
[0, 5, 2, 6, 0, 4, 2, 7] @=> int guitarDTMel[];
[2.0, 1.5, 1.8, 1.5] @=> float guitarDTDurs[];
[68, 50, 58, 48, 64, 50, 56, 46] @=> int guitarDTVel[];

// Harp: rare high sprinkles (2-bar cycle).
steps32([6, 7, 8, 22], [0.45, 0.35, 0.3, 0.35]) @=> float harpProbs[];
[8, 7, 5, 4, 6, 5] @=> int harpMel[];
[10.0] @=> float harpDurs[];
[54, 46, 42, 50] @=> int harpVel[];

// Harp double-time: descending/ascending 16th cascades on beats 3-4.
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
 0.9, 0.8, 0.8, 0.75, 0.8, 0.75, 0.7, 0.6] @=> float harpDTProbs[];
[8, 7, 6, 5, 4, 3, 2, 1, 2, 4, 5, 7] @=> int harpDTMel[];
[3.0] @=> float harpDTDurs[];
[60, 50, 48, 46, 50, 44, 42, 40] @=> int harpDTVel[];

// Flute: contemplative, mostly long tones with space (2-bar phrases).
steps32([0, 10, 20], [0.85, 0.4, 0.6]) @=> float fluteProbs[];
steps32([0, 10, 20], [9.5, 9.5, 11.5]) @=> float fluteDurs[];
[4, 2, 1, 0, 2, 4, 5, 4, 2] @=> int fluteMel[];
[62, 52, 56] @=> int fluteVel[];

// Vibraphone: sparse bell melody, pentatonic-leaning chord tones.
steps32([4, 14, 24], [0.7, 0.45, 0.6]) @=> float vibeProbs[];
steps32([4, 14, 24], [9.0, 9.0, 7.5]) @=> float vibeDurs[];
[5, 7, 6, 4, 8, 5, 2] @=> int vibeMel[];
[60, 48, 54] @=> int vibeVel[];

// Bell: very rare high sparkles.
steps32([8, 22, 28], [0.35, 0.3, 0.2]) @=> float bellProbs[];
[8.0] @=> float bellDurs[];
[7, 8, 6, 5, 8] @=> int bellMel[];
[52, 44, 40] @=> int bellVel[];

// ------------------------------------------------------------
// Fragments -- 5 progressions x 5 sparse textures
// ------------------------------------------------------------
5 => int NUM_GROUPS;
5 => int NUM_VARIANTS;
Fragment @ frags[NUM_GROUPS * NUM_VARIANTS];

fun void buildSection(int g, string gname, int baseRoots[], int baseQuals[])
{
    stretch(baseRoots, 2) @=> int roots[];
    stretch(baseQuals, 2) @=> int quals[];

    voicings(roots, quals, 1, false) @=> Chord hi[];
    voicings(roots, quals, 0, false) @=> Chord mid[];
    voicings(roots, quals, -1, false) @=> Chord lo[];
    voicings(roots, quals, 0, true) @=> Chord padCh[];

    mkMel(padDev,    padCh, padMel,    padProbs,    padDurs,    padVel)    @=> ChordProgression pad;
    mkMel(bassDev,   lo,    bassMel,   bassProbs,   bassDurs,   bassVel)   @=> ChordProgression bass;
    mkMel(pianoDev,  lo,    pianoMel,  pianoProbs,  pianoDurs,  pianoVel)  @=> ChordProgression piano;
    mkMel(guitarDev, mid,   guitarMel, guitarProbs, guitarDurs, guitarVel) @=> ChordProgression guitar;
    mkMel(harpDev,   hi,    harpMel,   harpProbs,   harpDurs,   harpVel)   @=> ChordProgression harp;
    mkMel(fluteDev,  hi,    fluteMel,  fluteProbs,  fluteDurs,  fluteVel)  @=> ChordProgression flute;
    mkMel(vibeDev,   hi,    vibeMel,   vibeProbs,   vibeDurs,   vibeVel)   @=> ChordProgression vibe;
    mkMel(bellDev,   hi,    bellMel,   bellProbs,   bellDurs,   bellVel)   @=> ChordProgression bell;

    g * NUM_VARIANTS => int base;

    // 0: stillness -- pad, pedal bass, vibraphone melody
    [pad, bass, vibe] @=> Part p0[];
    Fragment f0(gname + " stillness", 1, p0);
    f0 @=> frags[base + 0];

    // 1: fingerstyle -- nylon guitar, pedal bass, flute
    [guitar, bass, flute] @=> Part p1[];
    Fragment f1(gname + " fingerstyle", 1, p1);
    f1 @=> frags[base + 1];

    // 2: solo piano -- rolling piano with rare bell sparkles
    [piano, bell] @=> Part p2[];
    Fragment f2(gname + " piano", 1, p2);
    f2 @=> frags[base + 2];

    // 3: double-time -- alternating piano / guitar + harp cascades
    if (g % 2 == 0)
    {
        mkMel(pianoDev, lo, pianoDTMel, pianoDTProbs, pianoDTDurs, pianoDTVel) @=> ChordProgression pianoDT;
        [pianoDT, bass, vibe] @=> Part p3[];
        Fragment f3(gname + " double-time", 1, p3);
        f3 @=> frags[base + 3];
    }
    else
    {
        mkMel(guitarDev, mid, guitarDTMel, guitarDTProbs, guitarDTDurs, guitarDTVel) @=> ChordProgression guitarDT;
        mkMel(harpDev, hi, harpDTMel, harpDTProbs, harpDTDurs, harpDTVel) @=> ChordProgression harpDT;
        [guitarDT, harpDT, pad] @=> Part p3[];
        Fragment f3(gname + " double-time", 1, p3);
        f3 @=> frags[base + 3];
    }

    // 4: ether -- pad, harp sprinkles, bell sparkles
    [pad, harp, bell] @=> Part p4[];
    Fragment f4(gname + " ether", 1, p4);
    f4 @=> frags[base + 4];
}

// ------------------------------------------------------------
// The five progressions (roots are semitones from D)
// ------------------------------------------------------------
buildSection(0, "A Meadow",       [0, 5, 0, -5],          [Q_add9, Q_maj7, Q_add9, Q_sus4]);
buildSection(1, "B Pedal",        [0, -2, 5, 0],          [Q_sus2, Q_add9, Q_maj7, Q_sus2]);
buildSection(2, "C Autumn",       [-3, 5, 0, -5],         [Q_min9, Q_maj7, Q_add9, Q_sus4]);
buildSection(3, "D Lydian",       [5, 0, 5, 2],           [Q_lyd, Q_add9, Q_lyd, Q_min9]);
buildSection(4, "E Dorian",       [2, -5, 2, 5, 4, -5],   [Q_min9, Q_sus4, Q_min9, Q_maj7, Q_min9, Q_sus4]);

// ------------------------------------------------------------
// ENDING: Gmaj7 (2 bars) | A7sus4 (2 bars) | Dadd9 held (4 bars)
// ------------------------------------------------------------
[5, 5, -5, -5, 0, 0, 0, 0] @=> int endRoots[];
[Q_maj7, Q_maj7, Q_sus4, Q_sus4, Q_add9, Q_add9, Q_add9, Q_add9] @=> int endQuals[];
voicings(endRoots, endQuals, 1, false) @=> Chord endHi[];
voicings(endRoots, endQuals, -1, false) @=> Chord endLo[];
voicings(endRoots, endQuals, 0, true) @=> Chord endPadCh[];

// 128 steps (8 bars)
float endPadProbs[128];
float endPadDurs[128];
float endBassProbs[128];
float endBassDurs[128];
float endVibeProbs[128];
float endVibeDurs[128];
for (0 => int i; i < 128; i++)
{
    0.0 => endPadProbs[i];  0.0 => endPadDurs[i];
    0.0 => endBassProbs[i]; 0.0 => endBassDurs[i];
    0.0 => endVibeProbs[i]; 0.0 => endVibeDurs[i];
}
// Pad: rolled chords at bars 1, 3, and a final 4-bar hold at bar 5
for (0 => int k; k < 5; k++)
{
    1.0 => endPadProbs[0 + k];  (31.5 - k) => endPadDurs[0 + k];
    1.0 => endPadProbs[32 + k]; (31.5 - k) => endPadDurs[32 + k];
    1.0 => endPadProbs[64 + k]; (63.5 - k) => endPadDurs[64 + k];
}
// Bass: one pedal note per chord, final note held 4 bars
1.0 => endBassProbs[0];  31.0 => endBassDurs[0];
1.0 => endBassProbs[32]; 31.0 => endBassDurs[32];
1.0 => endBassProbs[64]; 63.0 => endBassDurs[64];
// Vibraphone: three last soft bell tones
1.0 => endVibeProbs[8];  20.0 => endVibeDurs[8];
1.0 => endVibeProbs[40]; 20.0 => endVibeDurs[40];
1.0 => endVibeProbs[72]; 48.0 => endVibeDurs[72];

[0, 1, 2, 3, 4] @=> int endPadMel[];
[48, 42, 40, 38, 36] @=> int endPadVel[];
[0] @=> int endBassMel[];
[58] @=> int endBassVel[];
[4, 3, 5] @=> int endVibeMel[];
[50, 46, 42] @=> int endVibeVel[];

mkMel(padDev,  endPadCh, endPadMel,  endPadProbs,  endPadDurs,  endPadVel)  @=> ChordProgression endPad;
mkMel(bassDev, endLo,    endBassMel, endBassProbs, endBassDurs, endBassVel) @=> ChordProgression endBass;
mkMel(vibeDev, endHi,    endVibeMel, endVibeProbs, endVibeDurs, endVibeVel) @=> ChordProgression endVibe;

[endPad, endBass, endVibe] @=> Part endingParts[];
Fragment fEnding("Ending", 1, endingParts);

// ------------------------------------------------------------
// SILENCE: 4 bars of rest before looping
// ------------------------------------------------------------
["0.0"] @=> string silenceProbs[];
voicings([0, 0, 0, 0], [Q_add9, Q_add9, Q_add9, Q_add9], 0, false) @=> Chord silenceChords[];
[0, 0, 0, 0] @=> int silenceOffsets[];
[0] @=> int silenceVel[];

fun ChordProgression mkSilentPart(Patch p)
{
    ChordProgression cp(p, silenceChords, silenceOffsets, true, 4, 4, silenceProbs);
    false => cp.random;
    0.0 => cp.mutateProbabilityRange;
    silenceVel @=> cp.velocities;
    allP << cp;
    return cp;
}

mkSilentPart(padDev)  @=> ChordProgression silPad;
mkSilentPart(bassDev) @=> ChordProgression silBass;
[silPad, silBass] @=> Part silenceParts[];
Fragment fSilence("Silence", 1, silenceParts);

// ------------------------------------------------------------
// Random transition graph (darius01.ck style)
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

//   A (0) -> [1, 2]   B (1) -> [2, 3]   C (2) -> [3, 0]
//   D (3) -> [4, 1]   E (4) -> [0, 2]   (+ Ending from E)
[[1, 2], [2, 3], [3, 0], [4, 1], [0, 2]] @=> int neighbours[][];

for (0 => int g; g < NUM_GROUPS; g++)
{
    neighbours[g].cap() => int numNeigh;
    (g == 4 ? 1 : 0) => int hasEnding;
    for (0 => int v; v < NUM_VARIANTS; v++)
    {
        g * NUM_VARIANTS + v => int idx;
        (NUM_VARIANTS - 1) + numNeigh * NUM_VARIANTS + hasEnding => int totalEdges;
        Fragment @ tos[totalEdges];
        float w[totalEdges];
        0 => int k;

        // Golden mode (index 0) steps forward cleanly
        if (v < NUM_VARIANTS - 1)
        {
            frags[g * NUM_VARIANTS + v + 1] @=> tos[k];
            Math.random2f(1.5, 3.5) => w[k];
            k++;
        }
        else if (hasEnding)
        {
            fEnding @=> tos[k];
            Math.random2f(2.5, 4.5) => w[k];
            k++;
        }

        if (v == NUM_VARIANTS - 1 && !hasEnding)
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

        for (0 => int sv; sv < NUM_VARIANTS; sv++)
        {
            if (sv == v || sv == v + 1) continue;
            frags[g * NUM_VARIANTS + sv] @=> tos[k];
            Math.random2f(1.0, 2.8) => w[k];
            k++;
        }

        if (v < NUM_VARIANTS - 1 || hasEnding)
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

        if (hasEnding && v < NUM_VARIANTS - 1)
        {
            fEnding @=> tos[k];
            Math.random2f(0.8, 1.6) => w[k];
            k++;
        }

        link(frags[idx], tos, w);
    }
}

FragmentTransition ft_toSilence(fSilence, 1.0);
[ft_toSilence] @=> fEnding.nextFragments;

FragmentTransition ft_loop(frags[0], 1.0);
[ft_loop] @=> fSilence.nextFragments;

Song song("Windham01", BPM, root, frags[0], allP);

song.play();
