@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
80 => float BPM;         // Beats per minute
53 => int root;           // F4 as the root note for F major

// V3 MIDI devices - Bluegrass instrumentation
V3GrandPiano mandolin(1, "Banjo", 120);
V3GrandPiano steelGuitar(2, "G. Steel Slide (velo. 116-127 Slide)", 100);
V3GrandPiano violin(3, "Violin", 95);
V3GrandPiano bass(4, "Upright Jazz Bass Random", 110);

// Chords - F major I, IV, V progression using new F major chord collections
Chord F_I_Low(NoteCollection.F_I_chord_Low(), 0);
Chord F_I_High(NoteCollection.F_I_chord_High(), 0);
Chord F_IV_Low(NoteCollection.F_IV_chord_Low(), 0);
Chord F_IV_High(NoteCollection.F_IV_chord_High(), 0);
Chord F_V_Low(NoteCollection.F_V_chord_Low(), 0);
Chord F_V_High(NoteCollection.F_V_chord_High(), 0);

// Chord progression pattern: I-I-IV-IV-I-I-V-V
//[0, 0, 1, 1, 0, 0, 2, 2] @=> int progression[];
[0, 0, 0, 0, 0, 0, 0, 0] @=> int progression[];
[F_I_Low, F_IV_Low, F_V_Low] @=> Chord chordsLow[];
[F_I_High, F_IV_High, F_V_High] @=> Chord chordsHigh[];

4 => int numBars;

// Bass line - Upright bass with steady rhythm
["1.0", ".4:0.1:0.4", "1.0", ".4:0.1:0.4", "1.0", ".4:0.1:0.6", "1.0", "0.2:0.1:0.4"] @=> string bassProbStrings[];
[110, 100, 105, 100] @=> int bassVelocities[];
ChordProgression bassLine(bass, chordsLow, progression, true, 8, numBars, bassProbStrings);
// true => bassLine.random;
0.3 => bassLine.mutateProbabilityRange;
bassVelocities @=> bassLine.velocities;

// Steel guitar - Verse (sparse)
["0.5:0.3:0.7:0.2", "0.3:0.1:0.5:0.2", "0.6:0.3:0.8:0.2", "0.2:0.0:0.4:0.2",
 "0.5:0.3:0.7:0.2", "0.4:0.2:0.6:0.2", "0.6:0.3:0.8:0.2", "0.3:0.1:0.5:0.2"] @=> string steelProbStringsVerse[];
[125, 95, 127, 90] @=> int steelVelocities[];
ChordProgression steelChordsVerse(steelGuitar, chordsHigh, progression, true, 16, numBars, steelProbStringsVerse);
true => steelChordsVerse.random;
0.3 => steelChordsVerse.mutateProbabilityRange;
steelVelocities @=> steelChordsVerse.velocities;

// Steel guitar - Chorus (full energy)
["1.0:0.6:1.0:0.3", "0.8:0.4:1.0:0.3", "1.0:0.6:1.0:0.3", "0.7:0.3:1.0:0.3",
 "1.0:0.6:1.0:0.3", "0.8:0.4:1.0:0.3", "1.0:0.6:1.0:0.3", "0.9:0.5:1.0:0.3"] @=> string steelProbStringsChorus[];
ChordProgression steelChordsChorus(steelGuitar, chordsHigh, progression, true, 16, numBars, steelProbStringsChorus);
true => steelChordsChorus.random;
0.3 => steelChordsChorus.mutateProbabilityRange;
steelVelocities @=> steelChordsChorus.velocities;

// Steel guitar - Bridge (syncopated, off-beat emphasis)
["0.4:0.2:0.6:0.3", "0.9:0.6:1.0:0.3", "0.3:0.1:0.5:0.3", "0.8:0.5:1.0:0.3",
 "0.4:0.2:0.6:0.3", "1.0:0.7:1.0:0.3", "0.3:0.1:0.5:0.3", "0.9:0.6:1.0:0.3"] @=> string steelProbStringsBridge[];
ChordProgression steelChordsBridge(steelGuitar, chordsHigh, progression, true, 16, numBars, steelProbStringsBridge);
true => steelChordsBridge.random;
0.3 => steelChordsBridge.mutateProbabilityRange;
steelVelocities @=> steelChordsBridge.velocities;

// Violin - Verse (sparse, sustained)
["0.6:0.3:0.8:0.2", "0.2:0.0:0.4:0.2", "0.5:0.2:0.7:0.2", "0.3:0.1:0.5:0.2"] @=> string violinProbStringsVerse[];
[90, 85, 88, 82] @=> int violinVelocities[];
ChordProgression violinPartVerse(violin, chordsHigh, progression, true, 8, numBars, violinProbStringsVerse);
true => violinPartVerse.random;
0.3 => violinPartVerse.mutateProbabilityRange;
violinVelocities @=> violinPartVerse.velocities;

// Violin - Chorus (full)
["1.0", "0.5:0.2:0.8:0.2", "1.0", "0.6:0.3:0.9:0.2"] @=> string violinProbStringsChorus[];
ChordProgression violinPartChorus(violin, chordsHigh, progression, true, 8, numBars, violinProbStringsChorus);
true => violinPartChorus.random;
0.3 => violinPartChorus.mutateProbabilityRange;
violinVelocities @=> violinPartChorus.velocities;

// Violin - Bridge (syncopated)
["0.3:0.1:0.5:0.3", "0.9:0.6:1.0:0.3", "0.4:0.2:0.6:0.3", "0.8:0.5:1.0:0.3"] @=> string violinProbStringsBridge[];
ChordProgression violinPartBridge(violin, chordsHigh, progression, true, 8, numBars, violinProbStringsBridge);
true => violinPartBridge.random;
0.3 => violinPartBridge.mutateProbabilityRange;
violinVelocities @=> violinPartBridge.velocities;

// Mandolin - Verse (sparse melody)
["0.6:0.4:0.8:0.3", "0.3:0.1:0.5:0.3", "0.5:0.3:0.7:0.3", "0.2:0.0:0.4:0.3",
 "0.6:0.4:0.8:0.3", "0.4:0.2:0.6:0.3", "0.5:0.3:0.7:0.3", "0.3:0.1:0.5:0.3"] @=> string mandolinProbStringsVerse[];
[120, 84, 115, 95] @=> int mandolinVelocities[];
ChordProgression mandolinMelodyVerse(mandolin, chordsHigh, progression, true, 16, numBars, mandolinProbStringsVerse);
0.3 => mandolinMelodyVerse.mutateProbabilityRange;
true => mandolinMelodyVerse.random;
mandolinVelocities @=> mandolinMelodyVerse.velocities;

// Mandolin - Chorus (full energy)
["1.0:0.7:1.0:0.4", "0.8:0.5:1.0:0.4", "0.9:0.6:1.0:0.4", "0.75:0.4:1.0:0.4",
 "1.0:0.7:1.0:0.4", "0.85:0.5:1.0:0.4", "0.9:0.6:1.0:0.4", "0.8:0.5:1.0:0.4"] @=> string mandolinProbStringsChorus[];
ChordProgression mandolinMelodyChorus(mandolin, chordsHigh, progression, true, 16, numBars, mandolinProbStringsChorus);
0.3 => mandolinMelodyChorus.mutateProbabilityRange;
true => mandolinMelodyChorus.random;
mandolinVelocities @=> mandolinMelodyChorus.velocities;

// Mandolin - Bridge (syncopated)
["0.3:0.1:0.5:0.4", "0.9:0.6:1.0:0.4", "0.4:0.2:0.6:0.4", "0.8:0.5:1.0:0.4",
 "0.3:0.1:0.5:0.4", "1.0:0.7:1.0:0.4", "0.4:0.2:0.6:0.4", "0.9:0.6:1.0:0.4"] @=> string mandolinProbStringsBridge[];
ChordProgression mandolinMelodyBridge(mandolin, chordsHigh, progression, true, 16, numBars, mandolinProbStringsBridge);
0.3 => mandolinMelodyBridge.mutateProbabilityRange;
true => mandolinMelodyBridge.random;
mandolinVelocities @=> mandolinMelodyBridge.velocities;

// All parts array for the Song
[bassLine, 
 steelChordsVerse, steelChordsChorus, steelChordsBridge,
 violinPartVerse, violinPartChorus, violinPartBridge,
 mandolinMelodyVerse, mandolinMelodyChorus, mandolinMelodyBridge] @=> Part allParts[];

// Song structure fragments
// Verse 1 - Sparse (bass only)
[bassLine] @=> Part verse1Parts[];
Fragment verse1("Verse 1", 1, verse1Parts);

// Pre-Chorus 1 - Add steel guitar (verse style)
[bassLine, steelChordsVerse] @=> Part preChorus1Parts[];
Fragment preChorus1("Pre-Chorus 1", 1, preChorus1Parts);

// Chorus 1 - Full arrangement (chorus style)
[bassLine, steelChordsChorus, violinPartChorus, mandolinMelodyChorus] @=> Part chorus1Parts[];
Fragment chorus1("Chorus 1", 2, chorus1Parts);

// Verse 2 - Bass and violin (verse style)
[bassLine, violinPartVerse] @=> Part verse2Parts[];
Fragment verse2("Verse 2", 2, verse2Parts);

// Pre-Chorus 2 - Build up with bass, steel, violin (chorus style)
[bassLine, steelChordsChorus, violinPartChorus] @=> Part preChorus2Parts[];
Fragment preChorus2("Pre-Chorus 2", 1, preChorus2Parts);

// Chorus 2 - Full arrangement (chorus style)
[bassLine, steelChordsChorus, violinPartChorus, mandolinMelodyChorus] @=> Part chorus2Parts[];
Fragment chorus2("Chorus 2", 2, chorus2Parts);

// Bridge - Mandolin and bass duet (bridge style - syncopated)
[bassLine, mandolinMelodyBridge] @=> Part bridgeParts[];
Fragment bridge("Bridge", 2, bridgeParts);

// Chorus 3 - Final full chorus (chorus style)
[bassLine, steelChordsChorus, violinPartChorus, mandolinMelodyChorus] @=> Part chorus3Parts[];
Fragment chorus3("Chorus 3", 2, chorus3Parts);

// Outro - Fade with steel and bass (verse style - sparse)
[bassLine, steelChordsVerse] @=> Part outroParts[];
Fragment outro("Outro", 1, outroParts);

// Fragment transitions (100% probability for linear structure)
FragmentTransition toPreChorus1(preChorus1, 1.0);
FragmentTransition toChorus1(chorus1, 1.0);
FragmentTransition toVerse2(verse2, 1.0);
FragmentTransition toPreChorus2(preChorus2, 1.0);
FragmentTransition toChorus2(chorus2, 1.0);
FragmentTransition toBridge(bridge, 1.0);
FragmentTransition toChorus3(chorus3, 1.0);
FragmentTransition toOutro(outro, 1.0);
FragmentTransition end(verse1, 0.0);  // End after outro

// Connect fragments
[toPreChorus1] @=> verse1.nextFragments;
[toChorus1] @=> preChorus1.nextFragments;
[toVerse2] @=> chorus1.nextFragments;
[toPreChorus2] @=> verse2.nextFragments;
[toChorus2] @=> preChorus2.nextFragments;
[toBridge] @=> chorus2.nextFragments;
[toChorus3] @=> bridge.nextFragments;
[toOutro] @=> chorus3.nextFragments;
[end] @=> outro.nextFragments;

// Create and play the song
Song song("bg01", BPM, root, verse1, allParts);

song.play();

