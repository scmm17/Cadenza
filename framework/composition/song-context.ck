// SongContext
// Purpose: Base context holding musical timing, device registry, mode flags, and virtual hooks for composition/control layers.
// Imports: framework/devices/patch.ck
// Imported by: framework/composition/part.ck, framework/composition/fragment.ck, framework/composition/note-collection.ck, framework/composition/melody.ck, framework/composition/chord-progression.ck, framework/composition/drum-machine.ck

@import "../devices/patch.ck"

public class SongContext
{
    string name;
    float BPM;
    dur beat;
    int rootNote;

    Patch @ devices[16];
    Patch @ currentDevice;

    int muteMode;
    int soloMode;
    int allMode;
    int forever;
    int restartRequested;

    string currentPatchSet;
    string defaultPatchSet;

    // Static flags — always access qualified as SongContext.<field>
    static int debug;
    static int golden;
    static int shuttingDown;
    static int isPaused;

    fun void setBPM(float bpm)
    {
        bpm => BPM;
        60::second / bpm => beat;
    }

    fun dur whole() { return beat * 4; }
    fun dur half() { return beat * 2; }
    fun dur quarter() { return beat; }
    fun dur eighth() { return beat / 2; }
    fun dur sixteenth() { return beat / 4; }
    fun dur dottedQuarter() { return quarter() + eighth(); }
    fun dur dottedHalf() { return half() + quarter(); }
    fun dur tripletEighth() { return quarter() / 3; }

    // ── Virtual hooks (overridden by Song) ───────────────────────────────────
    fun void advance(dur d) {}
    fun void waitIfPaused() {}
    fun void notifyStateChanged() {}
    fun void playPartOnce() {}
    fun int selectDevice(int idx) { return 0; }
    fun void setMidiThruChannel(int ch) {}
    fun void replaceDevice(int idx, Patch @ newPatch) {}
    fun void setDeviceSynth(int devIdx, string synthUiName) {}
    fun void setDeviceChannel(int devIdx, int channel) {}
    fun void setNextPreset(int volume) {}
    fun void setPreviousPreset(int volume) {}
    fun void setNextPresetCategory(int volume) {}
    fun void setPreviousPresetCategory(int volume) {}
    fun void setPresetByName(string presetName, int volume) {}
    fun void updateEffectiveMuteStates() {}
    fun void toggleMute(Patch patch) {}
    fun void toggleSoloPatch(Patch patch) {}
    fun void toggleMuteMode(int note) {}
    fun void toggleSoloMode(int note) {}
    fun void startSoloMode() {}
    fun int isPatchSoloed(Patch p) { return false; }
    fun int mutedPatchCount() { return 0; }
    fun void saveConfig() {}
    fun void loadPatchSet(string setName) {}
    fun void setPatchSetMetadata(string curName, string defName) {}
    fun void createAndSavePatchSet(string newName, string defName) {}
    fun void pause() {}
    fun void resume() {}
    fun void restart() {}
    fun void shutdown() {}
    fun void queueFragmentByName(string fragName) {}
    fun void loopFragmentByName(string fragName) {}
}
