// Chords

@import "note-collection.ck"
@import "song.ck"
@import "patch.ck"

public class Chord extends NoteCollection
{
    // Octave offset
    int octave;
    
    fun Chord(NoteCollection chordNotes, int initOctave)
    { 
        chordNotes.notes @=> notes;
        initOctave => octave;
    }
}

public class ChordProgression extends Part
{
    Chord chords[];
    int offsets[];
    int melody[];

    // If true, play the chord in sequence, otherwise play as a chord.
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
        initPatch @=> patch;
        progression @=> chords;
        progOffsets @=> offsets;
        isArpeggiated => arpeggiated;
        probabilities @=> rhythmProbabilities;
        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        false => random;
        0.0 => mutateProbabilityRange;
        false => useMelody;
        0 => curMelodyPosition;
    }

    fun dur totalDuration(Song song)
     {
         return song.whole() * numberOfMeasures;
     }
     
     fun play(Song song)
     {
        if (arpeggiated) 
        {
            song.whole()/notesPerMeasure => noteDuration;
        } else {
            song.whole()/notesPerMeasure => noteDuration;
        }
        playProgression(song);
    }

    fun void playProgression(Song song)
    {
        if (arpeggiated) 
        {
            playArpeggio(song);
        } 
        else 
        {
            0 => int chordIndex;
            for(Chord chord : chords) 
            {
                for(0 => int i; i < chord.numNotes(); i++)
                {
                    chord.getMidiNote(song, i, offsets[chordIndex] + chord.octave * 12) => int note;
                    patch.noteOn(note, velocities[i % velocities.cap()], song.whole());
                }
                noteDuration => now;
                chordIndex++;
            }
        }
        
    }

    fun void playArpeggio(Song song)
    {
        playProbabilityRhythm(song);
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        chords[measure % chords.cap()] @=> Chord chord;
        if (random)
        {
            Math.random2(0, chord.notes.cap()-1) => int index;
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