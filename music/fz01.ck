@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================================
// FZ01 - "Quintuplet Cadenza"  (a Frank-Zappa-flavoured study)
// Key:  C major / A minor (white-key collection)
// Time: 5/4   (true 5/4 - see BPM note below)
// Progression (one chord per bar):
//   Em - F - Am - C - Dm - G - Bdim
//   (the seven white-key triads, from the literal E-F-A-C-D-G-B root cycle)
// Form: Verse - PreChorus - Chorus - Verse - PreChorus - Chorus - Bridge
//       - Chorus - Outro   (linear, FragmentTransition probability 1.0)
//
// 5/4 NOTE: the framework hard-codes whole = beat * 4, so to get a perceived
// 5/4 at musical-quarter = 110 BPM we set the framework BPM to 110 * 4/5 = 88.
// One framework "whole" (4 framework-beats at 88) then spans exactly 5 actual
// 5/4 quarter-notes at 110 - and a notesPerMeasure = 5 grid lines up with the
// 5 quarter pulses of one 5/4 bar.
// ============================================================================

172 => float BPM;           // perceived 110 in 5/4 (88 = 110 * 4/5)
60 => int root;            // C4

// ----------------------------------------------------------------------------
// V3 Grand Piano (bank 3 - "B3" percussion / stringed presets)
// ----------------------------------------------------------------------------
V3GrandPiano marimba(1, "Marimba", 110);                    // lead
V3GrandPiano vibraphone(2, "Vibraphone", 80);               // sustained pad
V3GrandPiano bass(3, "Upright Jazz Bass Random", 115);      // 5/4 walking bass
V3GrandPiano xylo(4, "Xylophon", 95);                       // counter-melody
V3GrandPiano bells(5, "Tubular Bell", 70);                  // chorus colour

// Drums on the SH-4d (channel 10)
RolandSH4d drumKit(10, "Drums", 75);

// ============================================================================
// Note Collections - white-key triads, two-octave voicings for arpeggiation
// All offsets are semitones from the song root (C4).
// ============================================================================

// Em : E G B
fun NoteCollection Em_notes() {
    [4, 7, 11, 16, 19, 23] @=> int n[];
    NoteCollection c(n); return c;
}

// F  : F A C
fun NoteCollection F_notes() {
    [5, 9, 12, 17, 21, 24] @=> int n[];
    NoteCollection c(n); return c;
}

// Am : A C E   (A below C, two-octave spread)
fun NoteCollection Am_notes() {
    [-3, 0, 4, 9, 12, 16] @=> int n[];
    NoteCollection c(n); return c;
}

// C  : C E G
fun NoteCollection C_notes() {
    [0, 4, 7, 12, 16, 19] @=> int n[];
    NoteCollection c(n); return c;
}

// Dm : D F A
fun NoteCollection Dm_notes() {
    [2, 5, 9, 14, 17, 21] @=> int n[];
    NoteCollection c(n); return c;
}

// G  : G B D   (G below middle C)
fun NoteCollection G_notes() {
    [-5, -1, 2, 7, 11, 14] @=> int n[];
    NoteCollection c(n); return c;
}

// Bdim : B D F (diminished triad, B below middle C)
fun NoteCollection Bdim_notes() {
    [-1, 2, 5, 11, 14, 17] @=> int n[];
    NoteCollection c(n); return c;
}

// Full C major scale spanning two octaves - basis for the L-system melody.
fun NoteCollection C_major_scale() {
    [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23] @=> int n[];
    NoteCollection s(n); return s;
}

// ============================================================================
// Three octave-shifts for each of the seven chords (low / std / high)
// ============================================================================
Chord Em_low(Em_notes(),   -1);  Chord Em_std(Em_notes(),   0);  Chord Em_high(Em_notes(),   1);
Chord F_low(F_notes(),     -1);  Chord F_std(F_notes(),     0);  Chord F_high(F_notes(),     1);
Chord Am_low(Am_notes(),   -1);  Chord Am_std(Am_notes(),   0);  Chord Am_high(Am_notes(),   1);
Chord C_low(C_notes(),     -1);  Chord C_std(C_notes(),     0);  Chord C_high(C_notes(),     1);
Chord Dm_low(Dm_notes(),   -1);  Chord Dm_std(Dm_notes(),   0);  Chord Dm_high(Dm_notes(),   1);
Chord G_low(G_notes(),     -1);  Chord G_std(G_notes(),     0);  Chord G_high(G_notes(),     1);
Chord Bdim_low(Bdim_notes(), -1); Chord Bdim_std(Bdim_notes(), 0); Chord Bdim_high(Bdim_notes(), 1);

// ============================================================================
// Progression: Em - F - Am - C - Dm - G - Bdim   (7 measures of 5/4)
// ============================================================================
[0, 0, 0, 0, 0, 0, 0] @=> int progression[];

[Em_low,  F_low,  Am_low,  C_low,  Dm_low,  G_low,  Bdim_low ] @=> Chord chordsLow[];
[Em_std,  F_std,  Am_std,  C_std,  Dm_std,  G_std,  Bdim_std ] @=> Chord chordsStd[];
[Em_high, F_high, Am_high, C_high, Dm_high, G_high, Bdim_high] @=> Chord chordsHigh[];

7 => int numBars;        // one chord per bar of 5/4 -> 7-bar cycle

// ============================================================================
// L-system melody  (see music/fz01-lsystem.yaml)
// 4 symbols x 4-deep expansion = 256 notes of angular C-major lines
// ============================================================================
LSystemNotes fzMelody(C_major_scale(), "fz01-lsystem.yaml");

// ============================================================================
// VERSE - sparse, lurching marimba over a thumping 5/4 bass
// notesPerMeasure = 5 means one note per beat in 5/4
// ============================================================================

// Bass: strong on 1, syncopated on 3 and 5  (kick-style 5/4 backbone)
[   "1.0",
    "0.4:0.1:0.6",
    "0.85:0.5:1.0",
    "0.3:0.0:0.5",
    "0.7:0.4:0.9"
] @=> string verseBassProbs[];
[120, 95, 110, 90, 105] @=> int verseBassVel[];

ChordProgression verseBass(bass, chordsLow, progression, true, 5, numBars, verseBassProbs);
true => verseBass.random;
verseBassVel @=> verseBass.velocities;
0.4 => verseBass.mutateProbabilityRange;

// Marimba lead: 10 quintuplet positions, accent 1, "and-of-2", 4
[   "1.0:0.7:1.0:0.4",
    "0.3:0.0:0.5",
    "0.8:0.5:1.0",
    "0.4:0.1:0.6",
    "0.6:0.3:0.8",
    "0.5:0.2:0.7",
    "0.9:0.6:1.0",
    "0.3:0.0:0.5",
    "0.7:0.4:0.9",
    "0.5:0.2:0.7"
] @=> string verseMarimbaProbs[];
[115, 90, 108, 92, 100, 95, 112, 88, 105, 95] @=> int verseMarimbaVel[];

SequentialMelody verseMarimba(marimba, fzMelody, 10, numBars, verseMarimbaProbs);
verseMarimbaVel @=> verseMarimba.velocities;
1.0 => verseMarimba.mutateProbabilityRange;
true => verseMarimba.useAllNotes;

[verseBass, verseMarimba] @=> Part verseParts[];

// ============================================================================
// PRE-CHORUS - vibraphone enters, marimba doubles up, hint of drums
// ============================================================================

// Vibraphone: arpeggiated stabs on beats 1 and 3 of each 5/4 bar.
// (Arpeggiated + random=true picks a fresh chord-tone per hit so successive
//  bars feel chordal even though only one note sounds per slot.)
[   "0.95:0.7:1.0",   // beat 1 - strong
    "0.0",            // beat 2
    "0.65:0.3:0.85",  // beat 3 - mid
    "0.0",            // beat 4
    "0.45:0.1:0.65"   // beat 5 - light
] @=> string preChorusVibeProbs[];
[105, 0, 95, 0, 88] @=> int preChorusVibeVel[];

ChordProgression preChorusVibe(vibraphone, chordsStd, progression, true, 5, numBars, preChorusVibeProbs);
true => preChorusVibe.random;
preChorusVibeVel @=> preChorusVibe.velocities;
0.4 => preChorusVibe.mutateProbabilityRange;

// Bass thickens
[   "1.0",
    "0.6:0.3:0.8",
    "0.9:0.6:1.0",
    "0.5:0.2:0.7",
    "0.85:0.5:1.0"
] @=> string preChorusBassProbs[];
ChordProgression preChorusBass(bass, chordsLow, progression, true, 5, numBars, preChorusBassProbs);
true => preChorusBass.random;
verseBassVel @=> preChorusBass.velocities;
0.4 => preChorusBass.mutateProbabilityRange;

// Marimba: denser version of verse line
[   "1.0:0.8:1.0:0.4",
    "0.5:0.2:0.7",
    "0.9:0.6:1.0",
    "0.6:0.3:0.8",
    "0.8:0.5:1.0",
    "0.6:0.3:0.8",
    "0.95:0.7:1.0",
    "0.5:0.2:0.7",
    "0.85:0.6:1.0",
    "0.6:0.3:0.8"
] @=> string preChorusMarimbaProbs[];
[120, 100, 115, 100, 110, 100, 118, 95, 112, 100] @=> int preChorusMarimbaVel[];
SequentialMelody preChorusMarimba(marimba, fzMelody, 10, numBars, preChorusMarimbaProbs);
preChorusMarimbaVel @=> preChorusMarimba.velocities;
1.2 => preChorusMarimba.mutateProbabilityRange;
true => preChorusMarimba.useAllNotes;

// ============================================================================
// 5/4 DRUM PATTERN (notesPerMeasure = 10 - eighth-note quintuplets)
// Beats:         1   .   2   .   3   .   4   .   5   .
// Slot index:    0   1   2   3   4   5   6   7   8   9
//   kick on 1, snare on 3, kick on 4, hat threading throughout
// ============================================================================
[   "1.0",            // 1   kick
    "0.6:0.3:0.8",    //  &  hat
    "0.7:0.4:0.9",    // 2   hat (sometimes ghost snare via mutation)
    "0.5:0.2:0.7",    //  &  hat
    "1.0",            // 3   snare
    "0.5:0.2:0.7",    //  &  hat
    "0.9:0.6:1.0",    // 4   kick
    "0.6:0.3:0.8",    //  &  hat
    "0.8:0.5:1.0",    // 5   snare
    "0.4:0.1:0.6"     //  &  hat (occasional)
] @=> string drumProbs[];
[127,  95, 100,  90, 120,  92, 122,  95, 110,  85] @=> int drumVel[];

[
    DrumMachine.BassDrum(),    // 1
    DrumMachine.ClosedHat(),   // &
    DrumMachine.ClosedHat(),   // 2
    DrumMachine.ClosedHat(),   // &
    DrumMachine.SnareDrum(),   // 3
    DrumMachine.ClosedHat(),   // &
    DrumMachine.BassDrum(),    // 4
    DrumMachine.ClosedHat(),   // &
    DrumMachine.SnareDrum(),   // 5
    DrumMachine.ClosedHat()    // &
] @=> int drumNotes[];

NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 10, numBars, drumProbs, drumKit);
drumVel @=> drums.velocities;
0.3 => drums.mutateProbabilityRange;

[preChorusBass, preChorusVibe, preChorusMarimba, drums] @=> Part preChorusParts[];

// ============================================================================
// CHORUS - everyone in, marimba pushed up, tubular bells punctuate
// ============================================================================

// Marimba: dense quintuplet runs, mostly above 0.6
[   "1.0:0.8:1.0:0.4",
    "0.7:0.4:0.9",
    "0.95:0.7:1.0",
    "0.6:0.3:0.8",
    "0.9:0.6:1.0",
    "0.7:0.4:0.9",
    "1.0:0.8:1.0",
    "0.65:0.4:0.85",
    "0.9:0.6:1.0",
    "0.75:0.4:0.95"
] @=> string chorusMarimbaProbs[];
[125, 110, 122, 100, 120, 105, 127, 100, 118, 108] @=> int chorusMarimbaVel[];
SequentialMelody chorusMarimba(marimba, fzMelody, 10, numBars, chorusMarimbaProbs);
chorusMarimbaVel @=> chorusMarimba.velocities;
1.0 => chorusMarimba.mutateProbabilityRange;
true => chorusMarimba.useAllNotes;

// Vibraphone: rhythmic comping (arpeggiated)
[   "1.0",
    "0.7:0.4:0.9",
    "0.9:0.6:1.0",
    "0.6:0.3:0.8",
    "0.85:0.5:1.0"
] @=> string chorusVibeProbs[];
[110, 95, 105, 92, 100] @=> int chorusVibeVel[];
ChordProgression chorusVibe(vibraphone, chordsStd, progression, true, 5, numBars, chorusVibeProbs);
true => chorusVibe.random;
chorusVibeVel @=> chorusVibe.velocities;
0.6 => chorusVibe.mutateProbabilityRange;

// Bass: full energy, all five quarter-pulses active
[   "1.0",
    "0.85:0.5:1.0",
    "1.0",
    "0.7:0.4:0.9",
    "0.95:0.6:1.0"
] @=> string chorusBassProbs[];
[125, 105, 122, 100, 120] @=> int chorusBassVel[];
ChordProgression chorusBass(bass, chordsLow, progression, true, 5, numBars, chorusBassProbs);
true => chorusBass.random;
chorusBassVel @=> chorusBass.velocities;
0.4 => chorusBass.mutateProbabilityRange;

// Tubular bells: a single ringing accent on beat 1 of each 5/4 bar
// (arpeggiated + random=true so each bar picks a different chord tone).
[   "0.85:0.4:1.0",
    "0.0",
    "0.0",
    "0.0",
    "0.0"
] @=> string chorusBellsProbs[];
[110, 0, 0, 0, 0] @=> int chorusBellsVel[];
ChordProgression chorusBells(bells, chordsHigh, progression, true, 5, numBars, chorusBellsProbs);
true => chorusBells.random;
chorusBellsVel @=> chorusBells.velocities;
0.3 => chorusBells.mutateProbabilityRange;

[chorusBass, chorusVibe, chorusMarimba, chorusBells, drums] @=> Part chorusParts[];

// ============================================================================
// BRIDGE - sparse, exposed.  Marimba alone with xylophon counter-line.
// Probability mutation ranges widened so the rhythms drift Zappa-style.
// ============================================================================

// Marimba: very sparse base, wide mutation range -> the line evolves
[   "0.6:0.2:0.9:1.5",
    "0.2:0.0:0.5:1.5",
    "0.5:0.1:0.8:1.5",
    "0.3:0.0:0.6:1.5",
    "0.7:0.3:1.0:1.5",
    "0.2:0.0:0.5:1.5",
    "0.5:0.1:0.8:1.5",
    "0.3:0.0:0.6:1.5",
    "0.6:0.2:0.9:1.5",
    "0.4:0.1:0.7:1.5"
] @=> string bridgeMarimbaProbs[];
[100, 75, 95, 80, 110, 75, 92, 80, 100, 85] @=> int bridgeMarimbaVel[];
SequentialMelody bridgeMarimba(marimba, fzMelody, 10, numBars, bridgeMarimbaProbs);
bridgeMarimbaVel @=> bridgeMarimba.velocities;
1.5 => bridgeMarimba.mutateProbabilityRange;
true => bridgeMarimba.useAllNotes;

// Xylophon counter-melody: off-beats only, threading between marimba notes
[   "0.0",
    "0.7:0.3:0.9:1.0",
    "0.2:0.0:0.4",
    "0.6:0.2:0.8:1.0",
    "0.0",
    "0.6:0.2:0.8:1.0",
    "0.3:0.0:0.5",
    "0.7:0.3:0.9:1.0",
    "0.0",
    "0.55:0.2:0.8:1.0"
] @=> string bridgeXyloProbs[];
[0, 100, 80, 95, 0, 95, 82, 100, 0, 92] @=> int bridgeXyloVel[];
SequentialMelody bridgeXylo(xylo, fzMelody, 10, numBars, bridgeXyloProbs);
bridgeXyloVel @=> bridgeXylo.velocities;
1.2 => bridgeXylo.mutateProbabilityRange;
true => bridgeXylo.useAllNotes;

// Vibraphone: a single sustained tone on beat 1 of each bar
// (arpeggiated + random=true keeps the bridge airy and chord-changing).
[   "0.9:0.5:1.0",
    "0.0",
    "0.0",
    "0.0",
    "0.0"
] @=> string bridgeVibeProbs[];
[95, 0, 0, 0, 0] @=> int bridgeVibeVel[];
ChordProgression bridgeVibe(vibraphone, chordsStd, progression, true, 5, numBars, bridgeVibeProbs);
true => bridgeVibe.random;
bridgeVibeVel @=> bridgeVibe.velocities;
0.3 => bridgeVibe.mutateProbabilityRange;

[bridgeVibe, bridgeMarimba, bridgeXylo] @=> Part bridgeParts[];

// ============================================================================
// OUTRO - thinning out, marimba and bass fade with sparse hits
// ============================================================================

[   "0.7:0.3:0.9:2.0",
    "0.2:0.0:0.4:2.0",
    "0.6:0.2:0.8:2.0",
    "0.2:0.0:0.4:2.0",
    "0.4:0.1:0.6:2.0"
] @=> string outroBassProbs[];
[100, 75, 92, 75, 85] @=> int outroBassVel[];
ChordProgression outroBass(bass, chordsLow, progression, true, 5, numBars, outroBassProbs);
true => outroBass.random;
outroBassVel @=> outroBass.velocities;
1.5 => outroBass.mutateProbabilityRange;

[   "0.7:0.3:0.9:1.5",
    "0.2:0.0:0.4:1.5",
    "0.5:0.1:0.7:1.5",
    "0.2:0.0:0.4:1.5",
    "0.6:0.2:0.8:1.5",
    "0.2:0.0:0.4:1.5",
    "0.5:0.1:0.7:1.5",
    "0.2:0.0:0.4:1.5",
    "0.4:0.0:0.6:1.5",
    "0.2:0.0:0.4:1.5"
] @=> string outroMarimbaProbs[];
[95, 75, 88, 75, 92, 75, 86, 75, 82, 70] @=> int outroMarimbaVel[];
SequentialMelody outroMarimba(marimba, fzMelody, 10, numBars, outroMarimbaProbs);
outroMarimbaVel @=> outroMarimba.velocities;
1.5 => outroMarimba.mutateProbabilityRange;
true => outroMarimba.useAllNotes;

[outroBass, outroMarimba] @=> Part outroParts[];

// ============================================================================
// All parts (declared once for Song.parts[] - device init walks this list)
// ============================================================================
[verseBass, verseMarimba,
 preChorusBass, preChorusVibe, preChorusMarimba,
 chorusBass, chorusVibe, chorusMarimba, chorusBells,
 bridgeVibe, bridgeMarimba, bridgeXylo,
 outroBass, outroMarimba,
 drums] @=> Part allParts[];

// ============================================================================
// Fragment graph (linear, deterministic - all transitions 1.0)
//   verse1 -> preChorus1 -> chorus1 -> verse2 -> preChorus2 ->
//   chorus2 -> bridge -> chorus3 -> outro -> verse1 (loop sentinel)
// ============================================================================
Fragment verse1("verse1",         1, verseParts);
Fragment preChorus1("preChorus1", 1, preChorusParts);
Fragment chorus1("chorus1",       2, chorusParts);
Fragment verse2("verse2",         1, verseParts);
Fragment preChorus2("preChorus2", 1, preChorusParts);
Fragment chorus2("chorus2",       2, chorusParts);
Fragment bridge("bridge",         1, bridgeParts);
Fragment chorus3("chorus3",       2, chorusParts);
Fragment outro("outro",           1, outroParts);

FragmentTransition ft_to_pc1(preChorus1, 1.0);
FragmentTransition ft_to_c1(chorus1,    1.0);
FragmentTransition ft_to_v2(verse2,     1.0);
FragmentTransition ft_to_pc2(preChorus2, 1.0);
FragmentTransition ft_to_c2(chorus2,    1.0);
FragmentTransition ft_to_bridge(bridge, 1.0);
FragmentTransition ft_to_c3(chorus3,    1.0);
FragmentTransition ft_to_outro(outro,   1.0);
FragmentTransition ft_loop(verse1,      1.0);

[ft_to_pc1]    @=> verse1.nextFragments;
[ft_to_c1]     @=> preChorus1.nextFragments;
[ft_to_v2]     @=> chorus1.nextFragments;
[ft_to_pc2]    @=> verse2.nextFragments;
[ft_to_c2]     @=> preChorus2.nextFragments;
[ft_to_bridge] @=> chorus2.nextFragments;
[ft_to_c3]     @=> bridge.nextFragments;
[ft_to_outro]  @=> chorus3.nextFragments;
[ft_loop]      @=> outro.nextFragments;

// ============================================================================
// Go!
// ============================================================================
Song song("fz01", BPM, root, verse1, allParts);

<<< "================================================================" >>>;
<<< "  fz01 - 'Quintuplet Cadenza'  (Frank Zappa-flavoured)" >>>;
<<< "  Key: C major / A minor (white-key cycle Em F Am C Dm G Bdim)" >>>;
<<< "  Time: 5/4   BPM:", BPM >>>;
<<< "  Lead:  Marimba   Pads: Vibraphone   Bass: Upright Jazz" >>>;
<<< "  Counter: Xylophon   Colour: Tubular Bell   Drums: SH-4d" >>>;
<<< "================================================================" >>>;

song.play();
