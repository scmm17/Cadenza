// ChordProgression
// Purpose: Plays chord sequences as block chords or arpeggiated probability rhythms.
// Imports: framework/composition/chords.ck, framework/composition/part.ck, framework/composition/song-context.ck, framework/devices/patch.ck
// Imported by: framework/cadenza.ck

@import "chords.ck"
@import "part.ck"
@import "song-context.ck"
@import "../devices/patch.ck"

public class ChordProgression extends Part
{
    Chord chords[];
    int offsets[];
    int melody[];

    int arpeggiated;
    int random;
    int useMelody;
    dur noteDuration;

    int curMelodyPosition;

    fun ChordProgression(
      Patch initPatch,
      Chord progression[],
      int progOffsets[],
      int isArpeggiated,
      int npm,
      int numMeasures,
      float probabilities[])
    {
        initPart(initPatch);
        progression @=> chords;
        progOffsets @=> offsets;
        isArpeggiated => arpeggiated;
        probabilities @=> rhythmProbabilities;
        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        false => random;
        false => useMelody;
        0 => curMelodyPosition;
    }

    fun ChordProgression(
      Patch initPatch,
      Chord progression[],
      int progOffsets[],
      int isArpeggiated,
      int npm,
      int numMeasures,
      string probabilities[])
    {
        initPart(initPatch);
        progression @=> chords;
        progOffsets @=> offsets;
        isArpeggiated => arpeggiated;
        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        false => random;
        false => useMelody;
        0 => curMelodyPosition;

        setProbabilitiesFromStrings(probabilities);
    }

    fun dur totalDuration(SongContext song)
    {
        return song.whole() * numberOfMeasures;
    }

    fun void play(SongContext song)
    {
        song.whole() / notesPerMeasure => noteDuration;
        playProgression(song);
    }

    fun void playProgression(SongContext song)
    {
        if (arpeggiated) {
            playArpeggio(song);
        } else {
            0 => int chordIndex;
            for (Chord chord : chords) {
                for (0 => int i; i < chord.numNotes(); i++) {
                    chord.getMidiNote(song, i, offsets[chordIndex] + chord.octave * 12) => int note;
                    patch.noteOn(note, velocities[i % velocities.cap()], noteDuration);
                }
                song.advance(noteDuration);
                chordIndex++;
            }
        }
    }

    fun void playArpeggio(SongContext song)
    {
        playProbabilityRhythm(song);
    }

    fun int generateNote(SongContext song, int measure, int noteInMeasure)
    {
        chords[measure % chords.cap()] @=> Chord chord;
        if (random) {
            Math.random2(0, chord.notes.cap() - 1) => int index;
            chord.getMidiNote(song, index, offsets[measure % offsets.cap()] + chord.octave * 12) => int note;
            return note;
        } else if (useMelody) {
            melody[curMelodyPosition] => int noteIndex;
            ++curMelodyPosition % melody.cap() => curMelodyPosition;
            chord.getMidiNote(song, noteIndex, offsets[measure % offsets.cap()] + chord.octave * 12) => int note;
            return note;
        } else {
            chord.getMidiNote(song, noteInMeasure, offsets[measure % offsets.cap()] + chord.octave * 12) => int note;
            return note;
        }
    }
}
