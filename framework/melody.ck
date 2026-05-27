// Melody

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

    fun void initMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures)
    {
        initPart(initPatch);
        initScale @=> scale;
        npm => notesPerMeasure;
        numMeasures => numberOfMeasures;
    }

    fun Melody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, float probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
    }

    // Overloaded constructor for string-based probabilities
    fun Melody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
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

// AleatoricMelody generates notes by randomly selecting from the scale.
// It extends Melody to produce non-deterministic melodic content.
//
// This class is used to create aleatoric melodies for musical parts.
public class AleatoricMelody extends Melody
{
    fun AleatoricMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, float probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
    }

    // Overloaded constructor for string-based probabilities
    fun AleatoricMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        Math.random2(0, scale.numNotes()-1) => int noteToPlay;
        scale.getMidiNote(song, noteToPlay, 0) => int note;
        return note;
    }
}

// SequentialMelody generates notes by stepping sequentially through the scale.
// It extends Melody and supports both per-measure cycling and continuous note stepping.
//
// This class is used to create sequential melodies for musical parts.
public class SequentialMelody extends Melody
{
    int useAllNotes;
    int currentNote;

    fun SequentialMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, float probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
        false => useAllNotes;
        0 => currentNote;
    }

    // Overloaded constructor for string-based probabilities
    fun SequentialMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
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

// DrumMachine generates drum patterns using MIDI note mappings for standard percussion.
// It extends Melody and provides static accessors for common General MIDI drum note numbers.
//
// This class is used to create drum machines for musical parts.
public class DrumMachine extends Melody
{
    fun DrumMachine(NoteCollection initScale, int npm, int numMeasures, float probabilities[], Patch drums)
    {
        initMelody(drums, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
    }

    // Overloaded constructor for string-based probabilities
    fun DrumMachine(NoteCollection initScale, int npm, int numMeasures, string probabilities[], Patch drums)
    {
        initMelody(drums, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
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
