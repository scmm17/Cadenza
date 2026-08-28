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
    }
}
