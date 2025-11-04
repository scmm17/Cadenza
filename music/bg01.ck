@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// Global parameters
80 => float BPM;         // Beats per minute
53 => int root;           // F4 as the root note for F major

// V3 MIDI devices - Bluegrass instrumentation
V3GrandPiano fantasia(1, "Fantasia", 125);
V3GrandPiano strings(2, "Disco Strings Slide velo. 116-127 Slide", 69);
V3GrandPiano cello(3, "Cello", 90);
V3GrandPiano bass(4, "Upright Jazz Bass Random", 125);

// Chords - F major I, IV, V progression using new F major chord collections
Chord F_I_Low(NoteCollection.F_I_chord_Low(), 0);
Chord F_I_High(NoteCollection.F_I_chord_High(), 0);
Chord F_IV_Low(NoteCollection.F_IV_chord_Low(), 0);
Chord F_IV_High(NoteCollection.F_IV_chord_High(), 0);
Chord F_V_Low(NoteCollection.F_V_chord_Low(), 0);
Chord F_V_High(NoteCollection.F_V_chord_High(), 0);

// Chord progression pattern: I-I-IV-IV-I-I-V-V
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
["1.0:0.2:1.0:0.3", "0.3:0.1:0.5:0.2", "0.6:0.3:0.8:0.2", "0.2:0.0:0.4:0.2",
 "0.5:0.3:0.7:0.2", "0.4:0.2:0.6:0.2", "0.6:0.3:0.8:0.2", "0.3:0.1:0.5:0.2"] @=> string stringsProbStringsVerse[];
[125, 95, 127, 90] @=> int stringsVelocities[];
ChordProgression stringsChordsVerse(strings, chordsHigh, progression, true, 16, numBars, stringsProbStringsVerse);
true => stringsChordsVerse.random;
0.3 => stringsChordsVerse.mutateProbabilityRange;
stringsVelocities @=> stringsChordsVerse.velocities;

// Steel guitar - Chorus (full energy)
["1.0:0.6:1.0:0.3", "0.8:0.4:1.0:0.3", "1.0:0.6:1.0:0.3", "0.7:0.3:1.0:0.3",
 "1.0:0.6:1.0:0.3", "0.8:0.4:1.0:0.3", "1.0:0.6:1.0:0.3", "0.9:0.5:1.0:0.3"] @=> string stringsProbStringsChorus[];
ChordProgression stringsChordsChorus(strings, chordsHigh, progression, true, 16, numBars, stringsProbStringsChorus);
true => stringsChordsChorus.random;
0.3 => stringsChordsChorus.mutateProbabilityRange;
stringsVelocities @=> stringsChordsChorus.velocities;

// Steel guitar - Bridge (syncopated, off-beat emphasis)
["0.4:0.2:0.6:0.3", "0.9:0.6:1.0:0.3", "0.3:0.1:0.5:0.3", "0.8:0.5:1.0:0.3",
 "0.4:0.2:0.6:0.3", "1.0:0.7:1.0:0.3", "0.3:0.1:0.5:0.3", "0.9:0.6:1.0:0.3"] @=> string stringsProbStringsBridge[];
ChordProgression stringsChordsBridge(strings, chordsHigh, progression, true, 16, numBars, stringsProbStringsBridge);
true => stringsChordsBridge.random;
0.3 => stringsChordsBridge.mutateProbabilityRange;
stringsVelocities @=> stringsChordsBridge.velocities;

// Violin - Verse (sparse, sustained)
["1.0:0.2:0.8:0.2", "0.2:0.0:0.4:0.2", "0.4:0.0:0.5:0.2", "0.35:0.1:0.5:0.2"] @=> string celloProbStringsVerse[];
[90, 85, 88, 82] @=> int celloVelocities[];
ChordProgression celloPartVerse(cello, chordsHigh, progression, true, 8, numBars, celloProbStringsVerse);
true => celloPartVerse.random;
0.3 => celloPartVerse.mutateProbabilityRange;
celloVelocities @=> celloPartVerse.velocities;

// Violin - Chorus (full)
["1.0", "0.5:0.2:0.8:0.2", "1.0", "0.6:0.3:0.9:0.2"] @=> string celloProbStringsChorus[];
ChordProgression celloPartChorus(cello, chordsHigh, progression, true, 8, numBars, celloProbStringsChorus);
true => celloPartChorus.random;
0.3 => celloPartChorus.mutateProbabilityRange;
celloVelocities @=> celloPartChorus.velocities;

// Violin - Bridge (syncopated)
["0.3:0.1:0.5:0.3", "0.9:0.6:1.0:0.3", "0.4:0.2:0.6:0.3", "0.8:0.5:1.0:0.3"] @=> string celloProbStringsBridge[];
ChordProgression celloPartBridge(cello, chordsHigh, progression, true, 8, numBars, celloProbStringsBridge);
true => celloPartBridge.random;
0.3 => celloPartBridge.mutateProbabilityRange;
celloVelocities @=> celloPartBridge.velocities;

// Mandolin - Verse (sparse melody)
["0.6:0.4:0.8:0.3", "0.3:0.1:0.5:0.3", "0.5:0.3:0.7:0.3", "0.2:0.0:0.4:0.3",
 "0.6:0.4:0.8:0.3", "0.4:0.2:0.6:0.3", "0.5:0.3:0.7:0.3", "0.3:0.1:0.5:0.3"] @=> string fantasiaProbStringsVerse[];
[120, 84, 115, 95] @=> int fantasiaVelocities[];
ChordProgression fantasiaMelodyVerse(fantasia, chordsHigh, progression, true, 16, numBars, fantasiaProbStringsVerse);
0.3 => fantasiaMelodyVerse.mutateProbabilityRange;
true => fantasiaMelodyVerse.random;
fantasiaVelocities @=> fantasiaMelodyVerse.velocities;

// Mandolin - Chorus (full energy)
["1.0:0.7:1.0:0.4", "0.8:0.5:1.0:0.4", "0.9:0.6:1.0:0.4", "0.75:0.4:1.0:0.4",
 "1.0:0.7:1.0:0.4", "0.85:0.5:1.0:0.4", "0.9:0.6:1.0:0.4", "0.8:0.5:1.0:0.4"] @=> string fantasiaProbStringsChorus[];
ChordProgression fantasiaMelodyChorus(fantasia, chordsHigh, progression, true, 16, numBars, fantasiaProbStringsChorus);
0.3 => fantasiaMelodyChorus.mutateProbabilityRange;
true => fantasiaMelodyChorus.random;
fantasiaVelocities @=> fantasiaMelodyChorus.velocities;

// Mandolin - Bridge (syncopated)
["0.5:0.1:0.5:0.4", "0.9:0.6:1.0:0.4", "0.4:0.2:0.6:0.4", "0.8:0.5:1.0:0.4",
 "0.3:0.1:0.5:0.4", "1.0:0.7:1.0:0.4", "0.4:0.2:0.6:0.4", "0.9:0.6:1.0:0.4"] @=> string fantasiaProbStringsBridge[];
 [85, 95, 90, 95] @=> int fantasiaBridgeVelocities[];
 ChordProgression fantasiaMelodyBridge(fantasia, chordsHigh, progression, true, 16, numBars, fantasiaProbStringsBridge);
0.3 => fantasiaMelodyBridge.mutateProbabilityRange;
true => fantasiaMelodyBridge.random;
fantasiaBridgeVelocities @=> fantasiaMelodyBridge.velocities;

// All parts array for the Song
[bassLine, 
 stringsChordsVerse, stringsChordsChorus, stringsChordsBridge,
 celloPartVerse, celloPartChorus, celloPartBridge,
 fantasiaMelodyVerse, fantasiaMelodyChorus, fantasiaMelodyBridge] @=> Part allParts[];

// Song structure fragments
// Verse 1 - Sparse (bass only)
[bassLine] @=> Part verse1Parts[];
Fragment verse1("Verse 1", 1, verse1Parts);

// Pre-Chorus 1 - Add strings guitar (verse style)
[bassLine, stringsChordsVerse] @=> Part preChorus1Parts[];
Fragment preChorus1("Pre-Chorus 1", 1, preChorus1Parts);

// Chorus 1 - Full arrangement (chorus style)
[bassLine, stringsChordsChorus, celloPartChorus, fantasiaMelodyChorus] @=> Part chorus1Parts[];
Fragment chorus1("Chorus 1", 2, chorus1Parts);

// Verse 2 - Bass and cello (verse style)
[bassLine, celloPartVerse] @=> Part verse2Parts[];
Fragment verse2("Verse 2", 2, verse2Parts);

// Pre-Chorus 2 - Build up with bass, strings, cello (chorus style)
[bassLine, stringsChordsChorus, celloPartChorus] @=> Part preChorus2Parts[];
Fragment preChorus2("Pre-Chorus 2", 1, preChorus2Parts);

// Chorus 2 - Full arrangement (chorus style)
[bassLine, stringsChordsChorus, stringsChordsVerse, celloPartChorus, fantasiaMelodyChorus] @=> Part chorus2Parts[];
Fragment chorus2("Chorus 2", 2, chorus2Parts);

// Bridge - Mandolin and bass duet (bridge style - syncopated)
[bassLine, fantasiaMelodyBridge] @=> Part bridgeParts[];
Fragment bridge("Bridge", 2, bridgeParts);

// Chorus 3 - Final full chorus (chorus style)
[bassLine, stringsChordsChorus, celloPartChorus, fantasiaMelodyChorus] @=> Part chorus3Parts[];
Fragment chorus3("Chorus 3", 2, chorus3Parts);

// Outro - Fade with strings and bass (verse style - sparse)
[bassLine, stringsChordsVerse] @=> Part outroParts[];
Fragment outro("Outro", 2, outroParts);

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

