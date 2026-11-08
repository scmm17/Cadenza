@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/song.ck"
@import "../framework/chords.ck"

public class SongTempoTests {
    fun static void run() {
        <<< "--- Song Tempo & Reset Tests ---" >>>;

        // 1. Restart on empty/new Song does not crash (shreds null-safety)
        MockSong song;
        song.restart();
        Assert.isTrue("testRestart_nullShreds_noCrash", true);

        // 2. setBPM updates BPM and beat
        song.setBPM(150.0);
        Assert.equalFloat("testSetBPM_150_BPM", song.BPM, 150.0, 0.001);
        Assert.equalFloat("testSetBPM_150_beat_ms", (song.beat / 1::ms), (60000.0 / 150.0), 0.001);

        song.setBPM(85.0);
        Assert.equalFloat("testSetBPM_85_BPM", song.BPM, 85.0, 0.001);
        Assert.equalFloat("testSetBPM_85_beat_ms", (song.beat / 1::ms), (60000.0 / 85.0), 0.001);

        // 3. Part totalDuration reflects BPM dynamically
        MockPatch patch;
        Chord chords[1];
        NoteCollection nc;
        [60] @=> nc.notes;
        nc.notes @=> chords[0].notes;
        [0] @=> int prog[];
        ["1.0"] @=> string probStrings[];
        ChordProgression part(patch, chords, prog, true, 4, 2, probStrings);

        song.setBPM(120.0);
        // At 120 BPM: whole note = 2.0s, 2 measures of 4/4 = 4.0s
        Assert.equalFloat("testPartDuration_120BPM", (part.totalDuration(song) / 1::ms), 4000.0, 0.001);

        song.setBPM(60.0);
        // At 60 BPM: whole note = 4.0s, 2 measures of 4/4 = 8.0s
        Assert.equalFloat("testPartDuration_60BPM", (part.totalDuration(song) / 1::ms), 8000.0, 0.001);

        // 4. Paused state at init
        Assert.equalInt("testSong_init_isPaused", Song.isPaused, 1);
    }
}
