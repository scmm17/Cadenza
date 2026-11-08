@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/song.ck"

public class DummyPart extends Part {
    fun DummyPart() {
        MockPatch patch;
        initPart(patch);
    }
}

public class PartRhythmTests {
    fun static void run() {
        <<< "--- Part Rhythm & Probability Tests ---" >>>;

        DummyPart p;

        // getNextNotePosition tests
        int notes1[3];
        0 => notes1[0]; 60 => notes1[1]; 0 => notes1[2];
        Assert.equalInt("testNextNote_nextSlot", p.getNextNotePosition(notes1, 0), 1);

        int notes2[4];
        0 => notes2[0]; 0 => notes2[1]; 60 => notes2[2]; 0 => notes2[3];
        Assert.equalInt("testNextNote_skipRests", p.getNextNotePosition(notes2, 0), 2);

        int notes3[3];
        60 => notes3[0]; 0 => notes3[1]; 0 => notes3[2];
        Assert.equalInt("testNextNote_atEnd", p.getNextNotePosition(notes3, 0), 3);

        int notes4[3];
        0 => notes4[0]; 0 => notes4[1]; 60 => notes4[2];
        Assert.equalInt("testNextNote_lastNote", p.getNextNotePosition(notes4, 2), 3);

        // parseProbabilityString tests
        string str1[1]; "0.75" => str1[0];
        p.setProbabilitiesFromStrings(str1);
        Assert.equalFloat("testSingleProbability prob", p.rhythmProbabilities[0], 0.75, 1e-6);
        Assert.equalFloat("testSingleProbability min", p.rhythmProbabilityMins[0], -1.0, 1e-6);
        Assert.equalFloat("testSingleProbability max", p.rhythmProbabilityMaxs[0], -1.0, 1e-6);
        Assert.equalFloat("testSingleProbability range", p.rhythmProbabilityRanges[0], -1.0, 1e-6);

        string str2[1]; "0.8:0.2:1.0" => str2[0];
        p.setProbabilitiesFromStrings(str2);
        Assert.equalFloat("testThreePartString prob", p.rhythmProbabilities[0], 0.8, 1e-6);
        Assert.equalFloat("testThreePartString min", p.rhythmProbabilityMins[0], 0.2, 1e-6);
        Assert.equalFloat("testThreePartString max", p.rhythmProbabilityMaxs[0], 1.0, 1e-6);
        Assert.equalFloat("testThreePartString range", p.rhythmProbabilityRanges[0], -1.0, 1e-6);

        string str3[1]; "0.8:0.2:1.0:0.3" => str3[0];
        p.setProbabilitiesFromStrings(str3);
        Assert.equalFloat("testFourPartString prob", p.rhythmProbabilities[0], 0.8, 1e-6);
        Assert.equalFloat("testFourPartString min", p.rhythmProbabilityMins[0], 0.2, 1e-6);
        Assert.equalFloat("testFourPartString max", p.rhythmProbabilityMaxs[0], 1.0, 1e-6);
        Assert.equalFloat("testFourPartString range", p.rhythmProbabilityRanges[0], 0.3, 1e-6);

        string str4[2]; "0.1" => str4[0]; "0.5:0:1:0.2" => str4[1];
        p.setProbabilitiesFromStrings(str4);
        Assert.equalFloat("testMixedArray 0 prob", p.rhythmProbabilities[0], 0.1, 1e-6);
        Assert.equalFloat("testMixedArray 1 min", p.rhythmProbabilityMins[1], 0.0, 1e-6);
        
        string str5[1]; "0.0" => str5[0];
        p.setProbabilitiesFromStrings(str5);
        Assert.equalFloat("testZeroProbability", p.rhythmProbabilities[0], 0.0, 1e-6);

        string str6[1]; "1.0" => str6[0];
        p.setProbabilitiesFromStrings(str6);
        Assert.equalFloat("testFullProbability", p.rhythmProbabilities[0], 1.0, 1e-6);

        string str7[1]; "0.5:0.2" => str7[0];
        p.setProbabilitiesFromStrings(str7);
        Assert.equalFloat("testInvalidFormat defaults to 1.0", p.rhythmProbabilities[0], 1.0, 1e-6);

        // mutateProbabilities tests
        // testMutate_noRange
        string mut1[1]; "0.5" => mut1[0];
        p.setProbabilitiesFromStrings(mut1);
        0.0 => p.mutateProbabilityRange;
        p.mutateProbabilities();
        Assert.equalFloat("testMutate_noRange", p.rhythmProbabilities[0], 0.5, 1e-6);

        // testMutate_staysInBounds
        string mut2[1]; "0.5:0.0:1.0:0.5" => mut2[0];
        p.setProbabilitiesFromStrings(mut2);
        0.5 => p.mutateProbabilityRange;
        1 => int inBounds;
        for (0 => int i; i < 100; i++) {
            p.mutateProbabilities();
            if (p.rhythmProbabilities[0] < 0.0 || p.rhythmProbabilities[0] > 1.0) {
                0 => inBounds;
            }
        }
        Assert.isTrue("testMutate_staysInBounds", inBounds);

        // testMutate_customBounds
        string mut3[1]; "0.5:0.3:0.7:0.5" => mut3[0];
        p.setProbabilitiesFromStrings(mut3);
        1 => inBounds;
        for (0 => int i; i < 100; i++) {
            p.mutateProbabilities();
            if (p.rhythmProbabilities[0] < 0.3 || p.rhythmProbabilities[0] > 0.7) {
                0 => inBounds;
            }
        }
        Assert.isTrue("testMutate_customBounds", inBounds);

        // testMutate_zeroRange_perSlot
        string mut4[2]; "0.5:0.0:1.0:0.0" => mut4[0]; "0.5:0.0:1.0:0.5" => mut4[1];
        p.setProbabilitiesFromStrings(mut4);
        for (0 => int i; i < 10; i++) {
            p.mutateProbabilities();
        }
        Assert.equalFloat("testMutate_zeroRange_perSlot", p.rhythmProbabilities[0], 0.5, 1e-6);

        // testPlayProbabilityRhythm_clampsDurationToRemainingInPart
        MockSong mSong;
        DummyPart pClamp;
        MockPatch mPatch;
        mPatch @=> pClamp.patch;
        1 => pClamp.numberOfMeasures;
        16 => pClamp.notesPerMeasure;
        float probsToPlay[16];
        float dursToPlay[16];
        int velsToPlay[1];
        100 => velsToPlay[0];
        velsToPlay @=> pClamp.velocities;
        for (0 => int i; i < 16; i++) {
            0.0 => probsToPlay[i];
            0.0 => dursToPlay[i];
        }
        1.0 => probsToPlay[12];
        10.0 => dursToPlay[12]; // Exceeds remaining 4 steps
        probsToPlay @=> pClamp.rhythmProbabilities;
        dursToPlay @=> pClamp.durations;

        pClamp.playProbabilityRhythm(mSong);
        mSong.whole() / 16 * 4 => dur expectedMaxDur;
        Assert.equalFloat("testPlayProbabilityRhythm_clampsDuration", mPatch.lastDurationPlayed / 1::ms, expectedMaxDur / 1::ms, 0.001);

        // testPatch_activeNotesTrackedAndCleared
        Patch testPatch;
        testPatch.noteOn(60, 100, 100::ms);
        testPatch.noteOn(64, 100, 100::ms);
        Assert.equalInt("testPatch_activeNotesTracked 60", testPatch.activeNotes[60], 1);
        Assert.equalInt("testPatch_activeNotesTracked 64", testPatch.activeNotes[64], 1);
        testPatch.sendAllNotesOff();
        Assert.equalInt("testPatch_activeNotesCleared 60", testPatch.activeNotes[60], 0);
        Assert.equalInt("testPatch_activeNotesCleared 64", testPatch.activeNotes[64], 0);
    }
}
