// Chord
// Purpose: Represents a chord as a NoteCollection with an octave offset.
// Imports: framework/composition/note-collection.ck
// Imported by: framework/composition/chord-progression.ck, framework/cadenza.ck

@import "note-collection.ck"

public class Chord extends NoteCollection
{
    int octave;

    fun Chord(NoteCollection chordNotes, int initOctave)
    {
        chordNotes.notes @=> notes;
        initOctave => octave;
    }
}
