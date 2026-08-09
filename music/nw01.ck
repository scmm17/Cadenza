@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// ============================================================================
// NEW POP SONG - nw01
// Key: D Major | BPM: 100 | Progression: I-vi-IV-V (D-Bm-G-A)
// Structure: Verse - Pre-Chorus - Chorus - Verse - Pre-Chorus - Chorus - Bridge - Chorus - Outro
// ============================================================================

// Global parameters
120 => float BPM;
62 => int root;  // D4

// ============================================================================
// MIDI Devices - V3 Grand Piano (Bank 3 - Tuned Percussion)
// ============================================================================
V3GrandPiano xylophone(1, "Xylophon", 75);           // program 14, bank 3
V3GrandPiano marimba(2, "Marimba", 70);              // program 11, bank 3
V3GrandPiano vibraphone(3, "Vibraphone", 65);        // program 6, bank 3

// Drum Kit - SH-4d on channel 10 (standard drum channel)
RolandSH4d drumKit(10, "Drums", 37);

// ============================================================================
// Note Collections for I-vi-IV-V in D Major
// ============================================================================

// I chord (D major): D-F#-A
fun NoteCollection I_D_notes() {
    [0, 4, 7, 12, 16, 19, 24] @=> int notes[];
    NoteCollection chord(notes);
    return chord;
}

// vi chord (B minor): B-D-F#
fun NoteCollection vi_Bm_notes() {
    [-3, 0, 4, 9, 12, 16, 21] @=> int notes[];
    NoteCollection chord(notes);
    return chord;
}

// IV chord (G major): G-B-D
fun NoteCollection IV_G_notes() {
    [5, 9, 12, 17, 21, 24] @=> int notes[];
    NoteCollection chord(notes);
    return chord;
}

// V chord (A major): A-C#-E
fun NoteCollection V_A_notes() {
    [7, 11, 14, 19, 23, 26] @=> int notes[];
    NoteCollection chord(notes);
    return chord;
}

// D Major Scale for L-system melody
fun NoteCollection D_major_scale() {
    [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24] @=> int notes[];
    NoteCollection scale(notes);
    return scale;
}

// ============================================================================
// Chords at different octaves
// ============================================================================

// Standard octave chords
Chord I_std(I_D_notes(), 0);
Chord vi_std(vi_Bm_notes(), 0);
Chord IV_std(IV_G_notes(), 0);
Chord V_std(V_A_notes(), 0);

// Low octave chords
Chord I_low(I_D_notes(), -1);
Chord vi_low(vi_Bm_notes(), -1);
Chord IV_low(IV_G_notes(), -1);
Chord V_low(V_A_notes(), -1);

// High octave chords
Chord I_high(I_D_notes(), 1);
Chord vi_high(vi_Bm_notes(), 1);
Chord IV_high(IV_G_notes(), 1);
Chord V_high(V_A_notes(), 1);

// ============================================================================
// Chord Progressions: I-vi-IV-V
// ============================================================================
[0, 0, 0, 0] @=> int progression[];

[I_std, vi_std, IV_std, V_std] @=> Chord chordsStd[];
[I_low, vi_low, IV_low, V_low] @=> Chord chordsLow[];
[I_high, vi_high, IV_high, V_high] @=> Chord chordsHigh[];

// ============================================================================
// L-System Melody
// ============================================================================
LSystemNotes lSystemMelody(D_major_scale(), me.dir() + "nw01-lsystem.yaml");

// ============================================================================
// VERSE - Sparse, gentle introduction
// ============================================================================

// Marimba arpeggios - sparse probability
[   "0.9:0.6:1.0",
    "0.3:0.1:0.5",
    "0.5:0.2:0.7",
    "0.2:0.0:0.4",
    "0.7:0.4:0.9",
    "0.2:0.0:0.4",
    "0.4:0.1:0.6",
    "0.3:0.0:0.5"
] @=> string verseArpProbs[];
[100, 85, 90, 80, 95, 80, 85, 80] @=> int verseVelocities[];

ChordProgression verseArp(marimba, chordsLow, progression, true, 8, 4, verseArpProbs);
true => verseArp.random;
verseVelocities @=> verseArp.velocities;
1.5 => verseArp.mutateProbabilityRange;

// Xylophone melody - light touches
[   "0.8:0.4:1.0",
    "0.2:0.0:0.5",
    "0.6:0.2:0.8",
    "0.1:0.0:0.3",
    "0.7:0.3:0.9",
    "0.1:0.0:0.3",
    "0.5:0.1:0.7",
    "0.2:0.0:0.4"
] @=> string verseMelodyProbs[];
[90, 75, 85, 70, 88, 72, 80, 70] @=> int verseMelodyVel[];

SequentialMelody verseMelody(xylophone, lSystemMelody, 8, 4, verseMelodyProbs);
verseMelodyVel @=> verseMelody.velocities;
1.0 => verseMelody.mutateProbabilityRange;
true => verseMelody.useAllNotes;

[verseArp, verseMelody] @=> Part verseParts[];

// ============================================================================
// DRUMS - Starts at chorus, continues through song
// ============================================================================

// Pop drum pattern - kick on 1 and 3, snare on 2 and 4
[   "1.0",           // kick
    "0.0",
    "0.5:0.2:0.7",   // ghost hi-hat
    "0.0",
    "1.0",           // snare
    "0.0",
    "0.6:0.3:0.8",   // hi-hat
    "0.0",
    "1.0",           // kick
    "0.0",
    "0.5:0.2:0.7",   // ghost hi-hat
    "0.0",
    "1.0",           // snare
    "0.0",
    "0.7:0.4:0.9",   // hi-hat
    "0.3:0.0:0.5"    // occasional hi-hat
] @=> string drumProbs[];

[127, 0, 100, 0, 120, 0, 105, 0, 127, 0, 105, 0, 120, 0, 100, 100] @=> int drumVelocities[];

[
    DrumMachine.BassDrum(),   // 1
    0,
    DrumMachine.ClosedHat(),  // &
    0,
    DrumMachine.SnareDrum(),  // 2
    0,
    DrumMachine.ClosedHat(),  // &
    0,
    DrumMachine.BassDrum(),   // 3
    0,
    DrumMachine.ClosedHat(),  // &
    0,
    DrumMachine.SnareDrum(),  // 4
    0,
    DrumMachine.ClosedHat(),  // &
    DrumMachine.ClosedHat()   // a
] @=> int drumNotes[];

NoteCollection drumNotesCollection(drumNotes);
DrumMachine drums(drumNotesCollection, 16, 4, drumProbs, drumKit);
drumVelocities @=> drums.velocities;
0.3 => drums.mutateProbabilityRange;

// ============================================================================
// PRE-CHORUS - Building intensity
// ============================================================================

// Marimba arpeggios - denser
[   "1.0:0.7:1.0",
    "0.5:0.2:0.7",
    "0.7:0.4:0.9",
    "0.4:0.1:0.6",
    "0.9:0.6:1.0",
    "0.4:0.1:0.6",
    "0.6:0.3:0.8",
    "0.5:0.2:0.7"
] @=> string preChorusArpProbs[];
[110, 95, 100, 90, 105, 90, 95, 90] @=> int preChorusVel[];

ChordProgression preChorusArp(marimba, chordsStd, progression, true, 8, 4, preChorusArpProbs);
true => preChorusArp.random;
preChorusVel @=> preChorusArp.velocities;
1.2 => preChorusArp.mutateProbabilityRange;

// Vibraphone pads - sustained feel
[   "1.0:0.8:1.0",
    "0.3:0.0:0.5",
    "0.6:0.2:0.8",
    "0.2:0.0:0.4"
] @=> string preChorusPadProbs[];
[95, 85, 90, 82] @=> int preChorusPadVel[];

ChordProgression preChorusPad(vibraphone, chordsStd, progression, true, 4, 4, preChorusPadProbs);
preChorusPadVel @=> preChorusPad.velocities;
0.8 => preChorusPad.mutateProbabilityRange;

// Xylophone melody continues
SequentialMelody preChorusMelody(xylophone, lSystemMelody, 8, 4, verseMelodyProbs);
verseMelodyVel @=> preChorusMelody.velocities;
1.2 => preChorusMelody.mutateProbabilityRange;
true => preChorusMelody.useAllNotes;

[preChorusArp, preChorusPad, preChorusMelody, drums] @=> Part preChorusParts[];

// ============================================================================
// CHORUS - Full energy, all instruments
// ============================================================================

// Marimba - dense arpeggios
[   "1.0:0.8:1.0",
    "0.7:0.4:0.9",
    "0.9:0.6:1.0",
    "0.6:0.3:0.8",
    "1.0:0.8:1.0",
    "0.6:0.3:0.8",
    "0.8:0.5:1.0",
    "0.7:0.4:0.9"
] @=> string chorusArpProbs[];
[120, 105, 115, 100, 118, 102, 110, 105] @=> int chorusVel[];

ChordProgression chorusArp(marimba, chordsStd, progression, true, 16, 4, chorusArpProbs);
true => chorusArp.random;
chorusVel @=> chorusArp.velocities;
1.0 => chorusArp.mutateProbabilityRange;

// Vibraphone - rhythmic support
[   "1.0:0.9:1.0",
    "0.5:0.2:0.7",
    "0.8:0.5:1.0",
    "0.4:0.1:0.6",
    "0.9:0.6:1.0",
    "0.4:0.1:0.6",
    "0.7:0.4:0.9",
    "0.5:0.2:0.7"
] @=> string chorusPadProbs[];
[110, 95, 105, 90, 108, 92, 100, 95] @=> int chorusPadVel[];

ChordProgression chorusPad(vibraphone, chordsHigh, progression, true, 8, 4, chorusPadProbs);
true => chorusPad.random;
chorusPadVel @=> chorusPad.velocities;
0.8 => chorusPad.mutateProbabilityRange;

// Xylophone - prominent melody
[   "1.0:0.7:1.0",
    "0.6:0.3:0.8",
    "0.9:0.6:1.0",
    "0.5:0.2:0.7",
    "1.0:0.7:1.0",
    "0.5:0.2:0.7",
    "0.8:0.5:1.0",
    "0.6:0.3:0.8"
] @=> string chorusMelodyProbs[];
[115, 100, 110, 95, 112, 98, 105, 100] @=> int chorusMelodyVel[];

SequentialMelody chorusMelody(xylophone, lSystemMelody, 16, 4, chorusMelodyProbs);
chorusMelodyVel @=> chorusMelody.velocities;
1.5 => chorusMelody.mutateProbabilityRange;
true => chorusMelody.useAllNotes;

[chorusArp, chorusPad, chorusMelody, drums] @=> Part chorusParts[];

// ============================================================================
// BRIDGE - Stripped back, melodic focus
// ============================================================================

// Vibraphone only - atmospheric
[   "0.9:0.6:1.0",
    "0.4:0.1:0.6",
    "0.7:0.3:0.9",
    "0.3:0.0:0.5"
] @=> string bridgePadProbs[];
[100, 88, 95, 85] @=> int bridgePadVel[];

ChordProgression bridgePad(vibraphone, chordsLow, progression, true, 4, 4, bridgePadProbs);
bridgePadVel @=> bridgePad.velocities;
1.0 => bridgePad.mutateProbabilityRange;

// Xylophone - sparse melody
[   "0.7:0.3:0.9",
    "0.2:0.0:0.4",
    "0.5:0.1:0.7",
    "0.1:0.0:0.3",
    "0.6:0.2:0.8",
    "0.1:0.0:0.3",
    "0.4:0.0:0.6",
    "0.2:0.0:0.4"
] @=> string bridgeMelodyProbs[];
[95, 80, 90, 75, 92, 78, 85, 80] @=> int bridgeMelodyVel[];

SequentialMelody bridgeMelody(xylophone, lSystemMelody, 8, 4, bridgeMelodyProbs);
bridgeMelodyVel @=> bridgeMelody.velocities;
1.5 => bridgeMelody.mutateProbabilityRange;
true => bridgeMelody.useAllNotes;

[bridgePad, bridgeMelody, drums] @=> Part bridgeParts[];

// ============================================================================
// OUTRO - Fading texture
// ============================================================================

// Marimba - very sparse
[   "0.6:0.2:0.8",
    "0.1:0.0:0.3",
    "0.3:0.0:0.5",
    "0.1:0.0:0.2"
] @=> string outroArpProbs[];
[80, 65, 70, 60] @=> int outroVel[];

ChordProgression outroArp(marimba, chordsLow, progression, true, 4, 4, outroArpProbs);
true => outroArp.random;
outroVel @=> outroArp.velocities;
2.0 => outroArp.mutateProbabilityRange;

// Vibraphone - gentle ending
[   "0.5:0.1:0.7",
    "0.2:0.0:0.4"
] @=> string outroPadProbs[];
[75, 60] @=> int outroPadVel[];

ChordProgression outroPad(vibraphone, chordsLow, progression, true, 2, 4, outroPadProbs);
outroPadVel @=> outroPad.velocities;
1.5 => outroPad.mutateProbabilityRange;

[outroArp, outroPad, drums] @=> Part outroParts[];

// ============================================================================
// All parts combined for Song initialization
// ============================================================================
[verseArp, verseMelody, preChorusArp, preChorusPad, preChorusMelody, 
 chorusArp, chorusPad, chorusMelody, bridgePad, bridgeMelody, 
 outroArp, outroPad, drums] @=> Part allParts[];

// ============================================================================
// FRAGMENT STRUCTURE
// Verse - Pre-Chorus - Chorus - Verse - Pre-Chorus - Chorus - Bridge - Chorus - Outro
// ============================================================================

// Create Fragments for each section
Fragment verse1("verse1", 2, verseParts);
Fragment preChorus1("preChorus1", 1, preChorusParts);
Fragment chorus1("chorus1", 2, chorusParts);
Fragment verse2("verse2", 2, verseParts);
Fragment preChorus2("preChorus2", 1, preChorusParts);
Fragment chorus2("chorus2", 4, allParts);
Fragment bridge("bridge", 2, bridgeParts);
Fragment chorus3("chorus3", 2, chorusParts);
Fragment outro("outro", 2, outroParts);

// Fragment Transitions - 100% probability for linear playback
FragmentTransition ft_to_pc1(preChorus1, 1.0);
FragmentTransition ft_to_c1(chorus1, 1.0);
FragmentTransition ft_to_v2(verse2, 1.0);
FragmentTransition ft_to_pc2(preChorus2, 1.0);
FragmentTransition ft_to_c2(chorus2, 1.0);
FragmentTransition ft_to_bridge(bridge, 1.0);
FragmentTransition ft_to_c3(chorus3, 1.0);
FragmentTransition ft_to_outro(outro, 1.0);
FragmentTransition ft_end(verse1, 1.0);  // Loop outro to end

// Wire up the transitions
[ft_to_pc1] @=> verse1.nextFragments;
[ft_to_c1] @=> preChorus1.nextFragments;
[ft_to_v2] @=> chorus1.nextFragments;
[ft_to_pc2] @=> verse2.nextFragments;
[ft_to_c2] @=> preChorus2.nextFragments;
[ft_to_bridge] @=> chorus2.nextFragments;
[ft_to_c3] @=> bridge.nextFragments;
[ft_to_outro] @=> chorus3.nextFragments;
[ft_end] @=> outro.nextFragments;

// ============================================================================
// CREATE AND PLAY SONG
// ============================================================================
Song song("nw01", BPM, root, verse1, allParts);

<<< "============================================" >>>;
<<< "Playing: New Pop Song (nw01)" >>>;
<<< "Key: D Major | BPM:", BPM >>>;
<<< "Progression: I-vi-IV-V (D-Bm-G-A)" >>>;
<<< "============================================" >>>;

song.play();

