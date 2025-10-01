// Chords

@import "note-collection.ck"
@import "song.ck"
@import "patch.ck"

// Melody is a class that represents a melody in the framework.
// It extends Part and adds a scale, rhythm probabilities, notes per measure, and number of measures.
//
// This class is used to create melodies for musical parts.
public class Melody extends Part
{
    NoteCollection scale;

    fun Melody(Patch initPatch, NoteCollection initSale, int npm, int numMeasures, float probabilities[])
    {
        initPatch @=> patch;
        initSale @=> scale;
        probabilities @=> rhythmProbabilities;

        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
    }

    fun dur totalDuration(Song song)
     {
         return song.whole() * numberOfMeasures;
     }
 
    fun play(Song song)
    {
        playMelody(song);
    }

    fun void playMelody(Song song)
    {   
        playProbabilityRhythm(song);
    }

}

// AleatoricMelody is a class that represents an aleatoric melody in the framework.
// It extends Melody and adds a use note from chord probability.
//
// This class is used to create aleatoric melodies for musical parts.
public class AleatoricMelody extends Melody
{
    float useNoteFromChordProbability;
    fun AleatoricMelody(Patch initPatch, NoteCollection initSale, int npm, int numMeasures, float probabilities[])
    {
        initPatch @=> patch;
        initSale @=> scale;
        probabilities @=> rhythmProbabilities;

        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        0.0 => useNoteFromChordProbability;
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        Math.random2(0, scale.numNotes()-1) => int noteToPlay;
        scale.getMidiNote(song, noteToPlay, 0) => int note;
        return note;
    }
}

// SequentialMelody is a class that represents a sequential melody in the framework.
// It extends Melody and adds a use note from chord probability.
//
// This class is used to create sequential melodies for musical parts.
public class SequentialMelody extends Melody
{
    float useNoteFromChordProbability;
    int useAllNotes;
    int currentNote;

    fun SequentialMelody(Patch initPatch, NoteCollection initSale, int npm, int numMeasures, float probabilities[])
    {
        initPatch @=> patch;
        initSale @=> scale;
        probabilities @=> rhythmProbabilities;

        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        0.0 => useNoteFromChordProbability;
        false => useAllNotes;
        0 => currentNote;
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        int noteToPlay;
        if (useAllNotes) {
            currentNote => noteToPlay;
            currentNote++;
            if (currentNote >= scale.numNotes()) {
                0 => currentNote;
            }
        } else {
            measure * notesPerMeasure + noteInMeasure => noteToPlay;
        }
        scale.getMidiNote(song, noteToPlay, 0) => int note;
        return note;
    }
}

// DrumMachine is a class that represents a drum machine in the framework.
// It extends Melody and adds a use note from chord probability.
//
// This class is used to create drum machines for musical parts.
public class DrumMachine extends Melody
{
    float useNoteFromChordProbability;
    fun DrumMachine(NoteCollection initSale, int npm, int numMeasures, float probabilities[], Patch drums)
    {
        drums @=> patch;
        initSale @=> scale;
        probabilities @=> rhythmProbabilities;

        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
        0.0 => useNoteFromChordProbability;
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        measure * notesPerMeasure + noteInMeasure => int noteToPlay;
        scale.getMidiNote(song, noteToPlay, -song.rootNote) => int note;
        return note;
    }

    fun static int BassDrum()
    {
        return 0x24;
    }

    fun static int SnareDrum()
    {
        return 0x28;
    }

    fun static int LowTom()
    {
        return 0x2D;
    }

    fun static int HiTom()
    {
        return 0x32;
    }

    fun static int Clap()
    {
        return 0x27;
    }

    fun static int Cymbal()
    {
        return 0x33;
    }

    fun static int OpenHat()
    {
        return 0x2E;
    }

    fun static int ClosedHat()
    {
        return 0x2A;
    }

}
