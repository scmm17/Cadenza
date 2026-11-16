// DrumMachine
// Purpose: Percussion pattern Part with static General MIDI drum note constants.
// Imports: framework/composition/melody.ck, framework/composition/note-collection.ck, framework/composition/song-context.ck, framework/devices/patch.ck
// Imported by: framework/cadenza.ck

@import "melody.ck"
@import "note-collection.ck"
@import "song-context.ck"
@import "../devices/patch.ck"

public class DrumMachine extends Melody
{
    fun DrumMachine(NoteCollection initScale, int npm, int numMeasures, float probabilities[], Patch drums)
    {
        initMelody(drums, initScale, npm, numMeasures);
        probabilities @=> rhythmProbabilities;
    }

    fun DrumMachine(NoteCollection initScale, int npm, int numMeasures, string probabilities[], Patch drums)
    {
        initMelody(drums, initScale, npm, numMeasures);
        setProbabilitiesFromStrings(probabilities);
    }

    fun int generateNote(SongContext song, int measure, int noteInMeasure)
    {
        measure * notesPerMeasure + noteInMeasure => int noteToPlay;
        scale.getMidiNote(song, noteToPlay, -song.rootNote) => int note;
        return note;
    }

    fun static int BassDrum()   { return 0x24; }
    fun static int SnareDrum()  { return 0x28; }
    fun static int LowTom()     { return 0x2D; }
    fun static int HiTom()      { return 0x32; }
    fun static int Clap()       { return 0x27; }
    fun static int Cymbal()     { return 0x33; }
    fun static int OpenHat()    { return 0x2E; }
    fun static int ClosedHat()  { return 0x2A; }
}
