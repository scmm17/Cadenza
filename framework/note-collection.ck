@import "song.ck"

public class NoteCollection
{
    int notes[];

    fun static NoteCollection majorScale()
    {
        [0, 2, 4, 5, 7, 9, 11, 12] @=> int majorScaleNotes[];
        NoteCollection major(majorScaleNotes);
        return major;
    }

    fun static NoteCollection minorScale()
    {
        [0, 2, 3, 5, 7, 9, 11, 12] @=> int minorScaleNotes[];
        NoteCollection minor(minorScaleNotes);
        return minor;
    }

    fun static NoteCollection majorChordNotes()
    {
        [0,4,7,12] @=> int major[];
        NoteCollection majorChordNotes(major);
        return majorChordNotes;
    }

    fun static NoteCollection minorChordNotes()
    {
        [0,3,7,12] @=> int minor[];
        NoteCollection minorChordNotes(minor);
        return minorChordNotes;
    }

    fun static NoteCollection I_notes()
    {
        [0,7,12,16,19,24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection IV_notes()
    {
        [0,5,12,17,21,24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection bVII_notes()
    {
        [-2,5,10,14,17,22] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun NoteCollection(int theNotes[])
    {
        theNotes @=> notes;
    }

    fun int numNotes()
    {
        return notes.cap();
    }

    fun int getMidiNote(Song song, int noteIndex, int offset)
    {
        // get the note, adding or subtracting octaves, as needed
        return song.rootNote + offset + notes[noteIndex % numNotes()] /* + 12 * (noteIndex / numNotes()) */;
    }
}
