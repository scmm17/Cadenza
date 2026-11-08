@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/song.ck"

public class FragmentTransitionsTests {
    fun static void run() {
        <<< "--- Fragment Transitions Tests ---" >>>;

        MockSong song;

        Part emptyParts[0];
        Fragment f1("Frag1", 4, emptyParts);
        FragmentTransition emptyTrans1[0]; emptyTrans1 @=> f1.nextFragments;
        Fragment f2("Frag2", 4, emptyParts);
        Fragment f3("Frag3", 4, emptyParts);

        // testSingleTransition_alwaysPicked
        FragmentTransition t1(f2, 1.0);
        f1.nextFragments << t1;
        
        f1.getNextSongFragment() @=> Fragment next1;
        Assert.equalString("testSingleTransition_alwaysPicked", next1.name, "Frag2");

        // testGoldenMode_picksFirst
        1 => Song.golden;
        FragmentTransition t2(f3, 0.9); // even with high prob, golden should pick first
        
        Fragment f_golden("FragGolden", 4, emptyParts);
        FragmentTransition emptyTransG[0]; emptyTransG @=> f_golden.nextFragments;
        FragmentTransition t_g1(f2, 0.1);
        FragmentTransition t_g2(f3, 0.9);
        f_golden.nextFragments << t_g1;
        f_golden.nextFragments << t_g2;

        f_golden.getNextSongFragment() @=> Fragment next2;
        Assert.equalString("testGoldenMode_picksFirst", next2.name, "Frag2");
        0 => Song.golden; // reset

        // testTwoTransitions_sumToOne
        Fragment f_dist("FragDist", 4, emptyParts);
        FragmentTransition emptyTransD[0]; emptyTransD @=> f_dist.nextFragments;
        FragmentTransition t_d1(f2, 0.3);
        FragmentTransition t_d2(f3, 0.7);
        f_dist.nextFragments << t_d1;
        f_dist.nextFragments << t_d2;

        0 => int count2;
        0 => int count3;
        for (0 => int i; i < 1000; i++) {
            f_dist.getNextSongFragment() @=> Fragment n;
            if (n.name == "Frag2") count2++;
            else if (n.name == "Frag3") count3++;
        }

        // 0.3 * 1000 = 300. Allow +/- 10% tolerance = 300 +/- 100 (200 to 400)
        Assert.isTrue("testTwoTransitions_sumToOne Frag2 approx 30%", count2 > 200 && count2 < 400);

        // testQueuedFragment_overridesNormalTransitionsOnce
        f1 @=> song.startFragment;
        Fragment f4("Frag4", 1, emptyParts);
        FragmentTransition emptyTrans2[0]; emptyTrans2 @=> f2.nextFragments;
        FragmentTransition t_2to4(f4, 1.0);
        f2.nextFragments << t_2to4;

        song.queueFragmentByName("Frag4");
        Assert.isTrue("testQueuedFragment_setByName", song.queuedFragment == f4);

        f1.resolveNextFragment(song) @=> Fragment nextQueued;
        Assert.equalString("testQueuedFragment_pickedInsteadOfTransitions", nextQueued.name, "Frag4");
        Assert.isTrue("testQueuedFragment_clearedAfterUse", song.queuedFragment == null);

        f1.resolveNextFragment(song) @=> Fragment nextNormal;
        Assert.equalString("testQueuedFragment_resumesNormalTransitions", nextNormal.name, "Frag2");

        // testLoopFragment_repeatsUntilToggledOff
        song.loopFragmentByName("Frag4");
        Assert.isTrue("testLoopFragment_setByName", song.loopFragment == f4);

        f1.resolveNextFragment(song) @=> Fragment nextLoop1;
        Assert.equalString("testLoopFragment_firstIteration", nextLoop1.name, "Frag4");
        Assert.isTrue("testLoopFragment_persistsAfterUse", song.loopFragment == f4);

        f4.resolveNextFragment(song) @=> Fragment nextLoop2;
        Assert.equalString("testLoopFragment_secondIteration", nextLoop2.name, "Frag4");

        // Toggling the same fragment again clears loopFragment
        song.loopFragmentByName("Frag4");
        Assert.isTrue("testLoopFragment_toggledOff", song.loopFragment == null);

        f1.resolveNextFragment(song) @=> Fragment nextAfterLoop;
        Assert.equalString("testLoopFragment_resumesNormalAfterToggleOff", nextAfterLoop.name, "Frag2");

        // testZeroProbabilityTransitions_returnsNull
        Fragment f_terminal("FragTerminal", 4, emptyParts);
        FragmentTransition emptyTransT[0]; emptyTransT @=> f_terminal.nextFragments;
        FragmentTransition t_zero1(f2, 0.0);
        FragmentTransition t_zero2(f3, 0.0);
        f_terminal.nextFragments << t_zero1;
        f_terminal.nextFragments << t_zero2;
        f_terminal.getNextSongFragment() @=> Fragment nextZero;
        Assert.isTrue("testZeroProbabilityTransitions_returnsNull", nextZero == null);
    }
}
