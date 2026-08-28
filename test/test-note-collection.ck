@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/note-collection.ck"
@import "../framework/chords.ck"
@import "../framework/song.ck"

public class NoteCollectionTests {
    fun static void run() {
        <<< "--- NoteCollection & Chord Tests ---" >>>;

        MockSong song;

        // testMajorScale
        NoteCollection.majorScale() @=> NoteCollection major;
        Assert.equalInt("testMajorScale count", major.numNotes(), 8);
        int expectedMajor[8];
        [0, 2, 4, 5, 7, 9, 11, 12] @=> expectedMajor;
        for (0 => int i; i < 8; i++) {
            Assert.equalInt("testMajorScale note " + i, major.notes[i], expectedMajor[i]);
        }

        // testMinorScale
        NoteCollection.minorScale() @=> NoteCollection minor;
        int expectedMinor[8];
        [0, 2, 3, 5, 7, 9, 11, 12] @=> expectedMinor;
        for (0 => int i; i < 8; i++) {
            Assert.equalInt("testMinorScale note " + i, minor.notes[i], expectedMinor[i]);
        }

        // testMajorChordNotes
        NoteCollection.majorChordNotes() @=> NoteCollection majChord;
        int expectedMajChord[4];
        [0, 4, 7, 12] @=> expectedMajChord;
        for (0 => int i; i < 4; i++) {
            Assert.equalInt("testMajorChordNotes note " + i, majChord.notes[i], expectedMajChord[i]);
        }

        // testMinorChordNotes
        NoteCollection.minorChordNotes() @=> NoteCollection minChord;
        int expectedMinChord[4];
        [0, 3, 7, 12] @=> expectedMinChord;
        for (0 => int i; i < 4; i++) {
            Assert.equalInt("testMinorChordNotes note " + i, minChord.notes[i], expectedMinChord[i]);
        }

        // testI_IV_V_notes
        NoteCollection.I_notes() @=> NoteCollection chordI;
        Assert.equalInt("testI_IV_V_notes I first", chordI.notes[0], 0);
        NoteCollection.IV_notes() @=> NoteCollection chordIV;
        Assert.equalInt("testI_IV_V_notes IV first", chordIV.notes[0], 0);
        NoteCollection.V_notes() @=> NoteCollection chordV;
        Assert.equalInt("testI_IV_V_notes V first", chordV.notes[0], -5);
        NoteCollection.bVII_notes() @=> NoteCollection chordbVII;
        Assert.equalInt("testI_IV_V_notes bVII first", chordbVII.notes[0], -2);

        // testCustomNotes
        NoteCollection custom;
        [1, 3, 5, 7] @=> custom.notes;
        Assert.equalInt("testCustomNotes count", custom.numNotes(), 4);
        Assert.equalInt("testCustomNotes note", custom.notes[2], 5);

        // testGetMidiNote_basic
        Assert.equalInt("testGetMidiNote_basic", major.getMidiNote(song, 0, 0), song.rootNote + 0);
        Assert.equalInt("testGetMidiNote_basic 2", major.getMidiNote(song, 2, 0), song.rootNote + 4);

        // testGetMidiNote_wraps (does not add octaves in default NoteCollection)
        Assert.equalInt("testGetMidiNote_wraps", major.getMidiNote(song, 8, 0), song.rootNote + 0);
        Assert.equalInt("testGetMidiNote_wraps 2", major.getMidiNote(song, 10, 0), song.rootNote + 4);

        // testGetMidiNote_offset
        Assert.equalInt("testGetMidiNote_offset", major.getMidiNote(song, 0, 2), song.rootNote + 0 + 2);

        // testGetMidiNote_negOffset
        Assert.equalInt("testGetMidiNote_negOffset", major.getMidiNote(song, 0, -2), song.rootNote + 0 - 2);

        // testChordOctaveOffset (octave field is applied by ChordProgression, not getMidiNote)
        Chord c1;
        NoteCollection.majorChordNotes().notes @=> c1.notes;
        -1 => c1.octave;
        Assert.equalInt("testChordOctaveOffset", c1.getMidiNote(song, 0, 0), song.rootNote + 0);

        // testChordOctaveZero
        Chord c2;
        NoteCollection.majorChordNotes().notes @=> c2.notes;
        0 => c2.octave;
        Assert.equalInt("testChordOctaveZero", c2.getMidiNote(song, 0, 0), song.rootNote + 0);
    }
}
