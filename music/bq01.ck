@import "../framework/song.ck"
@import "../framework/chords.ck"
@import "../framework/melody.ck"

// bq01.ck -- Baroque Prelude in C Major
// In the manner of J.S. Bach Well-Tempered Clavier Book I

82 => float BPM;
60 => int root;

V3GrandPiano rightHand(1, "Grand Piano Vienna - softer", 90);
V3GrandPiano leftHand(2, "Grand Piano Vienna - softer", 75);

[0, 4, 7, 12, 16] @=> int I_arr[];
NoteCollection I_nc(I_arr);
[9, 12, 16, 21] @=> int vi_arr[];
NoteCollection vi_nc(vi_arr);
[2, 5, 9, 14] @=> int ii_arr[];
NoteCollection ii_nc(ii_arr);
[7, 11, 14, 19] @=> int V_arr[];
NoteCollection V_nc(V_arr);
[5, 9, 12, 17] @=> int IV_arr[];
NoteCollection IV_nc(IV_arr);
[7, 11, 14, 17] @=> int V7_arr[];
NoteCollection V7_nc(V7_arr);

Chord rh_I(I_nc, 0);
Chord rh_vi(vi_nc, 0);
Chord rh_ii(ii_nc, 0);
Chord rh_V(V_nc, 0);
Chord rh_IV(IV_nc, 0);
Chord rh_V7(V7_nc, 0);
Chord lh_I(I_nc, -2);
Chord lh_vi(vi_nc, -2);
Chord lh_ii(ii_nc, -2);
Chord lh_V(V_nc, -2);
Chord lh_IV(IV_nc, -2);
Chord lh_V7(V7_nc, -2);

[rh_I, rh_vi, rh_ii, rh_V] @=> Chord expo_rh[];
[0, 0, 0, 0] @=> int expo_offsets[];
["1.0:0.7:1.0:0.0", "0.9:0.5:1.0:0.0", "0.85:0.4:1.0:0.0", "0.9:0.5:1.0:0.0", "1.0:0.6:1.0:0.0", "0.9:0.5:1.0:0.0", "0.85:0.4:1.0:0.0", "0.9:0.5:1.0:0.0", "1.0:0.65:1.0:0.0", "0.9:0.5:1.0:0.0", "0.85:0.4:1.0:0.0", "0.9:0.5:1.0:0.0", "1.0:0.6:1.0:0.0", "0.9:0.5:1.0:0.0", "0.85:0.4:1.0:0.0", "0.88:0.5:1.0:0.0"] @=> string rh_baroque_probs[];
[85, 70, 75, 72] @=> int rh_velocities[];
ChordProgression expo_rh_part(rightHand, expo_rh, expo_offsets, true, 16, 4, rh_baroque_probs);
true => expo_rh_part.random;
0.1 => expo_rh_part.mutateProbabilityRange;
rh_velocities @=> expo_rh_part.velocities;

["1.0:0.5:1.0:0.0", "0.0", "0.0", "0.0"] @=> string lh_sustained_probs[];
[lh_I, lh_vi, lh_ii, lh_V] @=> Chord expo_lh[];
[68, 60, 63, 65] @=> int lh_velocities[];
ChordProgression expo_lh_part(leftHand, expo_lh, expo_offsets, true, 4, 4, lh_sustained_probs);
false => expo_lh_part.random;
0.0 => expo_lh_part.mutateProbabilityRange;
lh_velocities @=> expo_lh_part.velocities;

[rh_vi, rh_ii, rh_IV, rh_V, rh_I, rh_V] @=> Chord dev_rh[];
[0, 0, 0, 0, 0, 0] @=> int dev_offsets[];
["1.0:0.7:1.0:0.0", "0.8:0.4:1.0:0.0", "0.9:0.5:1.0:0.0", "0.75:0.3:1.0:0.0", "1.0:0.65:1.0:0.0", "0.85:0.45:1.0:0.0", "0.9:0.5:1.0:0.0", "0.8:0.4:1.0:0.0", "1.0:0.7:1.0:0.0", "0.85:0.5:1.0:0.0", "0.9:0.5:1.0:0.0", "0.78:0.35:1.0:0.0", "1.0:0.6:1.0:0.0", "0.85:0.45:1.0:0.0", "0.88:0.5:1.0:0.0", "0.82:0.42:1.0:0.0"] @=> string rh_dev_probs[];
ChordProgression dev_rh_part(rightHand, dev_rh, dev_offsets, true, 16, 6, rh_dev_probs);
true => dev_rh_part.random;
0.12 => dev_rh_part.mutateProbabilityRange;
rh_velocities @=> dev_rh_part.velocities;

[lh_vi, lh_ii, lh_IV, lh_V, lh_I, lh_V] @=> Chord dev_lh[];
ChordProgression dev_lh_part(leftHand, dev_lh, dev_offsets, true, 4, 6, lh_sustained_probs);
false => dev_lh_part.random;
0.0 => dev_lh_part.mutateProbabilityRange;
lh_velocities @=> dev_lh_part.velocities;

[rh_I, rh_IV, rh_V, rh_I] @=> Chord recap_rh[];
[0, 0, 0, 0] @=> int recap_offsets[];
["1.0:0.75:1.0:0.0", "0.92:0.55:1.0:0.0", "0.88:0.5:1.0:0.0", "0.92:0.55:1.0:0.0", "1.0:0.7:1.0:0.0", "0.92:0.55:1.0:0.0", "0.88:0.5:1.0:0.0", "0.92:0.55:1.0:0.0", "1.0:0.72:1.0:0.0", "0.92:0.55:1.0:0.0", "0.88:0.5:1.0:0.0", "0.92:0.55:1.0:0.0", "1.0:0.7:1.0:0.0", "0.92:0.55:1.0:0.0", "0.88:0.5:1.0:0.0", "0.95:0.6:1.0:0.0"] @=> string rh_recap_probs[];
ChordProgression recap_rh_part(rightHand, recap_rh, recap_offsets, true, 16, 4, rh_recap_probs);
true => recap_rh_part.random;
0.08 => recap_rh_part.mutateProbabilityRange;
rh_velocities @=> recap_rh_part.velocities;

[lh_I, lh_IV, lh_V, lh_I] @=> Chord recap_lh[];
ChordProgression recap_lh_part(leftHand, recap_lh, recap_offsets, true, 4, 4, lh_sustained_probs);
false => recap_lh_part.random;
0.0 => recap_lh_part.mutateProbabilityRange;
lh_velocities @=> recap_lh_part.velocities;

[rh_V7, rh_I] @=> Chord cad_rh[];
[0, 0] @=> int cad_offsets[];
["1.0:0.8:1.0:0.0", "0.0", "0.8:0.5:1.0:0.0", "0.0", "1.0:0.75:1.0:0.0", "0.0", "0.85:0.55:1.0:0.0", "0.0"] @=> string rh_cad_probs[];
[90, 78] @=> int cad_rh_velocities[];
ChordProgression cad_rh_part(rightHand, cad_rh, cad_offsets, true, 8, 2, rh_cad_probs);
false => cad_rh_part.random;
0.0 => cad_rh_part.mutateProbabilityRange;
cad_rh_velocities @=> cad_rh_part.velocities;

[lh_V7, lh_I] @=> Chord cad_lh[];
["1.0:0.6:1.0:0.0", "0.0", "0.0", "0.0"] @=> string lh_cad_probs[];
[72, 65] @=> int cad_lh_velocities[];
ChordProgression cad_lh_part(leftHand, cad_lh, cad_offsets, true, 4, 2, lh_cad_probs);
false => cad_lh_part.random;
0.0 => cad_lh_part.mutateProbabilityRange;
cad_lh_velocities @=> cad_lh_part.velocities;

[expo_rh_part, expo_lh_part, dev_rh_part, dev_lh_part, recap_rh_part, recap_lh_part, cad_rh_part, cad_lh_part] @=> Part allParts[];

[expo_rh_part, expo_lh_part] @=> Part expositionParts[];
Fragment exposition("Exposition", 1, expositionParts);

[dev_rh_part, dev_lh_part] @=> Part developmentParts[];
Fragment development("Development", 1, developmentParts);

[recap_rh_part, recap_lh_part] @=> Part recapitulationParts[];
Fragment recapitulation("Recapitulation", 1, recapitulationParts);

[cad_rh_part, cad_lh_part] @=> Part cadenceParts[];
Fragment cadence("Cadence", 1, cadenceParts);

FragmentTransition toDevelopment(development, 1.0);
FragmentTransition toRecapitulation(recapitulation, 1.0);
FragmentTransition toCadence(cadence, 1.0);
FragmentTransition end(exposition, 0.0);

[toDevelopment]    @=> exposition.nextFragments;
[toRecapitulation] @=> development.nextFragments;
[toCadence]        @=> recapitulation.nextFragments;
[end]              @=> cadence.nextFragments;

Song song("bq01", BPM, root, exposition, allParts);
song.play();
