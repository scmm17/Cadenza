@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/cadenza.ck"

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
        Assert.equalInt("testSong_init_isPaused", SongContext.isPaused, 1);

        // 5. resolveMidiChannelForSynth channel rules
        MockSong chanSong;
        MockPatch d0; "V3" => d0.uiName; 5 => d0.midiChannel;
        MockPatch d1; "SH-4d" => d1.uiName; 0 => d1.midiChannel;
        MockPatch d2; "SH-4d" => d2.uiName; 2 => d2.midiChannel;
        MockPatch d3; "Moog" => d3.uiName; 7 => d3.midiChannel;
        d0 @=> chanSong.devices[0];
        d1 @=> chanSong.devices[1];
        d2 @=> chanSong.devices[2];
        d3 @=> chanSong.devices[3];

        Assert.equalInt("testResolveChannel_Moog", chanSong.resolveMidiChannelForSynth(0, "Moog"), 0);
        Assert.equalInt("testResolveChannel_Hydrasynth", chanSong.resolveMidiChannelForSynth(0, "Hydrasynth"), 0);
        Assert.equalInt("testResolveChannel_S1", chanSong.resolveMidiChannelForSynth(0, "S-1"), 2);
        Assert.equalInt("testResolveChannel_SH4d_firstUnused", chanSong.resolveMidiChannelForSynth(3, "SH-4d"), 1);

        // Fill remaining SH-4d channels (0..3) and verify fallback to lowest channel (0) when exhausted
        MockPatch d4; "SH-4d" => d4.uiName; 1 => d4.midiChannel;
        MockPatch d5; "SH-4d" => d5.uiName; 3 => d5.midiChannel;
        d4 @=> chanSong.devices[4];
        d5 @=> chanSong.devices[5];
        Assert.equalInt("testResolveChannel_SH4d_allUsed", chanSong.resolveMidiChannelForSynth(3, "SH-4d"), 0);

        // Monotimbral virtual synth already in use falls back to its lowest/fixed channel (0)
        MockPatch acidDev; "Acid V" => acidDev.uiName; 0 => acidDev.midiChannel;
        acidDev @=> chanSong.devices[6];
        Assert.equalInt("testResolveChannel_AcidV_alreadyUsed", chanSong.resolveMidiChannelForSynth(3, "Acid V"), 0);

        // Test V3 picks first unused channel in 0..15
        MockSong v3Song;
        for (0 => int ch; ch < 15; ch++) {
            MockPatch vp;
            "V3" => vp.uiName;
            ch => vp.midiChannel;
            vp @=> v3Song.devices[ch];
        }
        MockPatch otherDev; "Moog" => otherDev.uiName; 0 => otherDev.midiChannel;
        otherDev @=> v3Song.devices[15];
        Assert.equalInt("testResolveChannel_V3_firstUnused15", v3Song.resolveMidiChannelForSynth(15, "V3"), 15);

        // If channel 3 is freed on V3, it picks 3 before 15
        "Hydrasynth" => v3Song.devices[3].uiName;
        Assert.equalInt("testResolveChannel_V3_firstUnusedGap", v3Song.resolveMidiChannelForSynth(15, "V3"), 3);

        // Fill all 16 channels 0..15 with V3 and verify fallback to lowest channel (0) when all 16 are used
        "V3" => v3Song.devices[3].uiName;
        MockPatch vp15; "V3" => vp15.uiName; 15 => vp15.midiChannel;
        vp15 @=> v3Song.devices[15];
        Assert.equalInt("testResolveChannel_V3_allUsed", v3Song.resolveMidiChannelForSynth(-1, "V3"), 0);

        // 6. MoogMessenger.formatPatchName omits "Program"
        Assert.equalString("testMoogFormatPatchName_0_0", MoogMessenger.formatPatchName(0, 0), "Messenger: 1");
        Assert.equalString("testMoogFormatPatchName_4_11", MoogMessenger.formatPatchName(4, 11), "Hard Lead: 12");
    }
}
