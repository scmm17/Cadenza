// StateBroadcaster
// Purpose: Serializes SongState and Fragment graph to JSON and sends it via GuiLink to the Node.js GUI bridge.
// Imports: framework/core/gui-link.ck, framework/composition/fragment.ck, framework/devices/patch.ck
// Imported by: framework/song/song.ck

@import "../core/gui-link.ck"
@import "../composition/fragment.ck"
@import "../devices/patch.ck"

public class StateBroadcaster
{
    fun int isPlaying(SongState @ song, Patch @ p)
    {
        if (song.currentParts == null) return false;
        for (Part currentPart : song.currentParts) {
            if (currentPart != null && currentPart.patch == p) {
                return true;
            }
        }
        return false;
    }

    fun string buildStateJson(SongState @ song)
    {
        0 => int curIdx;
        for (0 => int i; i < song.devices.cap(); i++) {
            if (song.devices[i] != null && song.devices[i] == song.currentDevice) {
                i => curIdx;
            }
        }

        "" => string fragName;
        0 => int repeatIndex;
        0 => int repeatCount;
        if (song.currentFragment != null) {
            song.currentFragment.name => fragName;
            song.currentFragment.currentRepeat => repeatIndex;
            song.currentFragment.repeatCount => repeatCount;
        }
        "" => string nextFragName;
        if (song.queuedFragment != null) {
            song.queuedFragment.name => nextFragName;
        }
        "" => string loopFragName;
        if (song.loopFragment != null) {
            song.loopFragment.name => loopFragName;
        }

        "{" => string j;
        j + "\"songName\":\""            + escJson(song.name)              + "\"," => j;
        j + "\"patchSetName\":\""        + escJson(song.currentPatchSet)   + "\"," => j;
        j + "\"defaultPatchSetName\":\"" + escJson(song.defaultPatchSet)   + "\"," => j;
        j + "\"fragmentName\":\""        + escJson(fragName)               + "\"," => j;
        j + "\"nextFragmentName\":\""    + escJson(nextFragName)           + "\"," => j;
        j + "\"loopFragmentName\":\""    + escJson(loopFragName)           + "\"," => j;
        j + "\"bpm\":"                   + song.BPM                        + ","   => j;
        j + "\"muteMode\":"              + song.muteMode                   + ","   => j;
        j + "\"soloMode\":"              + song.soloMode                   + ","   => j;
        j + "\"golden\":"                + SongContext.golden              + ","   => j;
        j + "\"allMode\":"               + song.allMode                    + ","   => j;
        j + "\"isPaused\":"              + SongContext.isPaused            + ","   => j;
        j + "\"currentDeviceIndex\":"    + curIdx                          + ","   => j;
        j + "\"devices\":["                                                        => j;

        0 => int first;
        0 => int dNum;
        for (Patch p : song.devices) {
            if (p != null) {
                if (first) { j + "," => j; }
                p.stateBank() => int outBank;
                p.stateProgram() => int outProgram;
                j + "{" => j;
                j + "\"index\":"           + (dNum + 1)                               + "," => j;
                j + "\"uiName\":\""        + escJson(p.uiName)                        + "\"," => j;
                j + "\"channel\":"         + (p.midiChannel + 1)                      + "," => j;
                j + "\"patchName\":\""     + escJson(p.patchName)                     + "\"," => j;
                j + "\"bank\":"            + outBank                                  + "," => j;
                j + "\"program\":"         + outProgram                               + "," => j;
                j + "\"volume\":"          + p.volume                                 + "," => j;
                j + "\"filterCutoff\":"    + p.filterCutoff                           + "," => j;
                j + "\"filterResonance\":" + p.filterResonance                        + "," => j;
                j + "\"pan\":"             + (p.pan - 64)                             + "," => j;
                j + "\"muted\":"           + p.userMuted                              + "," => j;
                j + "\"soloed\":"          + (song.isPatchSoloed(p) ? 1 : 0)          + "," => j;
                j + "\"active\":"          + (p == song.currentDevice ? 1 : 0)        + "," => j;
                j + "\"playing\":"         + isPlaying(song, p)                       + "}" => j;
                1 => first;
            }
            dNum++;
        }
        j + "]," => j;

        j + "\"repeatIndex\":" + repeatIndex + "," => j;
        j + "\"repeatCount\":" + repeatCount => j;
        j + "}" => j;
        return j;
    }

    fun void broadcastState(SongState @ song)
    {
        if (GuiLink.disabled) return;
        buildStateJson(song) => string j;
        GuiLink.sendState(j);
        broadcastGraph(song);
    }

    fun int fragmentUsesPatch(Fragment @ fr, Patch @ p)
    {
        if (fr == null || fr.parts == null || p == null) return false;
        for (Part part : fr.parts) {
            if (part != null && (part.patch == p || (part.patch != null && p.devIndex > 0 && part.patch.devIndex == p.devIndex))) {
                return true;
            }
        }
        return false;
    }

    fun string buildGraphNodeJson(SongState @ song, Fragment @ fr)
    {
        "{\"name\":\"" + escJson(fr.name) + "\",\"repeat\":" + fr.repeatCount + ",\"devices\":[" => string g;
        0 => int firstDev;
        if (song != null && song.devices != null) {
            for (0 => int d; d < song.devices.cap(); d++) {
                if (song.devices[d] != null && fragmentUsesPatch(fr, song.devices[d])) {
                    if (firstDev) { g + "," => g; }
                    1 => firstDev;
                    g + (d + 1) => g;
                }
            }
        }
        g + "],\"edges\":[" => g;
        0 => int firstEdge;
        if (fr.nextFragments != null) {
            for (FragmentTransition t : fr.nextFragments) {
                if (t == null || t.nextFragment == null) { continue; }
                if (firstEdge) { g + "," => g; }
                1 => firstEdge;
                g + "{\"to\":\"" + escJson(t.nextFragment.name) + "\",\"p\":" + t.probability + "}" => g;
            }
        }
        g + "]}" => g;
        return g;
    }

    // Fragment graph, sent as one small OSC message per fragment.
    // Breadth-first from the start fragment; cycle-safe.
    fun void broadcastGraph(SongState @ song)
    {
        if (GuiLink.disabled) return;
        if (song.startFragment == null) {
            GuiLink.sendGraphNode(0, 0, "");
            return;
        }

        Fragment.collectReachable(song.startFragment) @=> Fragment @ queue[];

        for (0 => int i; i < queue.size(); i++) {
            queue[i] @=> Fragment fr;
            GuiLink.sendGraphNode(i, queue.size(), buildGraphNodeJson(song, fr));
        }
    }

    fun string escJson(string s)
    {
        "" => string r;
        for (0 => int i; i < s.length(); i++) {
            s.charAt(i) => int c;
            if (c == 34) {
                r + "\\\"" => r;
            } else if (c == 92) {
                r + "\\\\" => r;
            } else {
                r + s.substring(i, 1) => r;
            }
        }
        return r;
    }
}
