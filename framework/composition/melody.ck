// Melody, AleatoricMelody, SequentialMelody
// Purpose: Melodic Part implementations over a NoteCollection scale.
// Imports: framework/composition/note-collection.ck, framework/composition/part.ck, framework/composition/song-context.ck, framework/devices/patch.ck
// Imported by: framework/composition/drum-machine.ck, framework/cadenza.ck

@import "note-collection.ck"
@import "part.ck"
@import "song-context.ck"
@import "../devices/patch.ck"

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

    fun Melody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
    }

    fun dur totalDuration(SongContext song)
    {
        return song.whole() * numberOfMeasures;
    }

    fun void play(SongContext song)
    {
        playMelody(song);
    }

    fun void playMelody(SongContext song)
    {
        playProbabilityRhythm(song);
    }
}

public class AleatoricMelody extends Melody
{
    fun AleatoricMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, float probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
    }

    fun AleatoricMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
    }

    fun int generateNote(SongContext song, int measure, int noteInMeasure)
    {
        Math.random2(0, scale.numNotes() - 1) => int noteToPlay;
        scale.getMidiNote(song, noteToPlay, 0) => int note;
        return note;
    }
}

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

    fun SequentialMelody(Patch initPatch, NoteCollection initScale, int npm, int numMeasures, string probabilities[])
    {
        initMelody(initPatch, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
        false => useAllNotes;
        0 => currentNote;
    }

    fun int generateNote(SongContext song, int measure, int noteInMeasure)
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
