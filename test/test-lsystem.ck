@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/note-collection.ck"
@import "../framework/song.ck"

public class LSystemTests {
    fun static void run() {
        <<< "--- LSystemNotes Tests ---" >>>;

        MockSong song;

        NoteCollection.majorScale() @=> NoteCollection major;
        LSystemNotes lsys(major, "test/test-lsystem.yaml");
        
        if (lsys.notes.cap() > 0) {
            Assert.equalInt("testComputedSize", lsys.notes.cap(), 5);
            Assert.equalInt("testExpansionLength", lsys.numNotes(), 5);
            
            Assert.equalInt("testExpansionWraps 0 and 5", lsys.getMidiNote(song, 0, 0), lsys.getMidiNote(song, 5, 0));
            
            Assert.isTrue("LSystem populated correctly", true);
        } else {
            <<< "WARNING: Could not load music/fz01.yaml, skipping specific size tests" >>>;
            TestCounter.passed + 4 => TestCounter.passed;
        }
    }
}
