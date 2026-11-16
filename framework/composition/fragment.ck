// FragmentTransition, Fragment, and SongState
// Purpose: Song sections, weighted fragment transitions, and the fragment-aware SongState base class.
// Imports: framework/core/gui-link.ck, framework/composition/song-context.ck, framework/composition/part.ck
// Imported by: framework/song/*.ck, framework/control/*.ck

@import "../core/gui-link.ck"
@import "song-context.ck"
@import "part.ck"

public class FragmentTransition
{
    Fragment nextFragment;
    float probability;

    fun FragmentTransition(Fragment frag, float p)
    {
        frag @=> nextFragment;
        p => probability;
    }
}

public class Fragment
{
    int repeatCount;
    int currentRepeat;   // 1-based repeat iteration currently playing (for the GUI)
    FragmentTransition nextFragments[];
    Part @ parts[];
    string name;

    fun Fragment(string n, int r, Part p[])
    {
        n => name;
        r => repeatCount;
        p @=> parts;
    }

    fun void notifyTransition(Fragment next)
    {
        if (next == null) return;
        GuiLink.sendTransition(name, next.name);
    }

    fun Fragment getNextSongFragment()
    {
        if (nextFragments == null || nextFragments.cap() == 0) {
            return null;
        }

        Math.random2f(0.0, 1.0) => float r;
        if (SongContext.golden) {
            0.0 => r;
        }
        0 => float prob;

        for (FragmentTransition frag : nextFragments) {
            if (frag == null || frag.probability <= 0.0) continue;
            frag.probability + prob => prob;
            if (r <= prob) {
                notifyTransition(frag.nextFragment);
                return frag.nextFragment;
            }
        }
        notifyTransition(nextFragments[0].nextFragment);
        return nextFragments[0].nextFragment;
    }

    fun Fragment resolveNextFragment(SongState song)
    {
        if (song != null && song.queuedFragment != null) {
            song.queuedFragment @=> Fragment next;
            null @=> song.queuedFragment;
            notifyTransition(next);
            return next;
        }
        if (song != null && song.loopFragment != null) {
            notifyTransition(song.loopFragment);
            return song.loopFragment;
        }
        return getNextSongFragment();
    }

    fun Fragment play(SongState song)
    {
        for (0 => int i; i < repeatCount; i++) {
            i + 1 => currentRepeat;
            parts @=> song.currentParts;
            song.notifyStateChanged();
            song.playPartOnce();
            if (song.restartRequested) return null;
        }
        resolveNextFragment(song) @=> Fragment next;
        if (next != null) {
            <<< "Next Fragment:", next.name >>>;
        }
        return next;
    }

    fun static Fragment[] collectReachable(Fragment start)
    {
        Fragment @ queue[0];
        if (start == null) return queue;
        int seen[0];
        queue << start;
        1 => seen[start.name];
        0 => int qi;
        while (qi < queue.size()) {
            queue[qi] @=> Fragment f;
            qi++;
            if (f.nextFragments != null) {
                for (FragmentTransition t : f.nextFragments) {
                    if (t == null || t.nextFragment == null) { continue; }
                    if (!seen.isInMap(t.nextFragment.name)) {
                        1 => seen[t.nextFragment.name];
                        queue << t.nextFragment;
                    }
                }
            }
        }
        return queue;
    }
}

// SongState extends SongContext with Part[] and Fragment references so controllers
// and broadcasters can inspect active parts and fragments without depending on Song.
public class SongState extends SongContext
{
    Part @ parts[];
    Part @ currentParts[];

    Fragment @ startFragment;
    Fragment @ currentFragment;
    Fragment @ queuedFragment;
    Fragment @ loopFragment;
}
