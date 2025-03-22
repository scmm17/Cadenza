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

    // If true, play the chord in sequence, otherwise play as a chord.
    int arpeggiated;
    int random;
    dur noteDuration; 

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
            for(0 => int k; k < chords.cap(); k++) 
            {
                chords[k] @=> Chord chord;
                for(0 => int i; i < chord.numNotes(); i++)
                {
                    chord.getMidiNote(song, i, offsets[k] + chord.octave * 12) => int note;
                    patch.noteOn(note, velocities[i % velocities.cap()], song.whole());
                }
                noteDuration => now;
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
            chord.getMidiNote(song, index, offsets[measure] + chord.octave * 12) => int note;
            return note;
        } else {
            chord.getMidiNote(song, noteInMeasure, offsets[measure] + chord.octave * 12) => int note;
            return note;
        }
    }

}