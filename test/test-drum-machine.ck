@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/song.ck"
@import "../framework/melody.ck"

public class DummyDrumMachine extends DrumMachine {
    fun DummyDrumMachine() {
        MockPatch patch;
        patch @=> this.patch;
    }
}

public class DrumMachineTests {
    fun static void run() {
        <<< "--- DrumMachine Tests ---" >>>;

        MockSong song;
        DummyDrumMachine dm;

        Assert.equalInt("testBassDrum_midiNote", DrumMachine.BassDrum(), 36);
        Assert.equalInt("testSnareDrum_midiNote", DrumMachine.SnareDrum(), 40);
        Assert.equalInt("testClosedHat_midiNote", DrumMachine.ClosedHat(), 42);
        Assert.equalInt("testOpenHat_midiNote", DrumMachine.OpenHat(), 46);
        Assert.equalInt("testClap_midiNote", DrumMachine.Clap(), 39);
        Assert.equalInt("testLowTom_midiNote", DrumMachine.LowTom(), 45);
        Assert.equalInt("testHiTom_midiNote", DrumMachine.HiTom(), 50);
        Assert.equalInt("testCymbal_midiNote", DrumMachine.Cymbal(), 51);

        int drumNotes[2];
        DrumMachine.BassDrum() => drumNotes[0];
        0 => drumNotes[1];
        NoteCollection coll;
        drumNotes @=> coll.notes;
        coll @=> dm.scale;
        
        dm.generateNote(song, 0, 0) => int gen1;
        Assert.equalInt("testGenerateNote_returnsCorrectNote", gen1, 36);
        
        dm.generateNote(song, 0, 1) => int gen2;
        Assert.equalInt("testPattern_zeros_are_rests", gen2, 0);
    }
}
