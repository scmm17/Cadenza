// SynthRegistry
// Purpose: Central synth factory and MIDI channel auto-assignment rules (backed by generated/synth-table.ck).
// Imports: framework/devices/*.ck, framework/devices/presets/generated/synth-table.ck
// Imported by: framework/song/song.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/synth-table.ck"
@import "hydrasynth.ck"
@import "moog-messenger.ck"
@import "roland-s1.ck"
@import "roland-sh4d.ck"
@import "behringer-rd6.ck"
@import "v3-grand-piano.ck"

public class SynthRegistry
{
    fun static int findSynthIndex(string synthUiName)
    {
        for (0 => int i; i < SynthTableData.UI_NAMES.cap(); i++) {
            if (SynthTableData.UI_NAMES[i] == synthUiName) {
                return i;
            }
        }
        return -1;
    }

    fun static Patch createEmpty(string synthUiName)
    {
        if (synthUiName == "V3") {
            return new V3GrandPiano();
        } else if (synthUiName == "Hydrasynth") {
            return new Hydrasynth();
        } else if (synthUiName == "SH-4d") {
            return new RolandSH4d();
        } else if (synthUiName == "S-1") {
            return new RolandS1();
        } else if (synthUiName == "Moog") {
            return new MoogMessenger();
        } else if (synthUiName == "RD-6") {
            return new BehringerRD6();
        }
        return null;
    }

    fun static Patch createDefault(string synthUiName, int midiChan, int vol)
    {
        midiChan + 1 => int ch1Based;
        if (ch1Based < 1) { 1 => ch1Based; }
        if (ch1Based > 16) { 16 => ch1Based; }
        if (synthUiName == "V3") {
            return new V3GrandPiano(ch1Based, "Grand Piano Vienna", vol);
        } else if (synthUiName == "Hydrasynth") {
            return new Hydrasynth(ch1Based, "A001", vol);
        } else if (synthUiName == "SH-4d") {
            return new RolandSH4d(ch1Based, vol);
        } else if (synthUiName == "S-1") {
            return new RolandS1(ch1Based, 1, 1, vol);
        } else if (synthUiName == "Moog") {
            return new MoogMessenger(ch1Based, 1, 1, vol);
        } else if (synthUiName == "RD-6") {
            return new BehringerRD6(ch1Based, vol);
        }
        return null;
    }

    fun static int findFirstUnusedChannel(Patch devices[], int excludeIdx, string synthUiName, int maxChannels)
    {
        for (0 => int ch; ch < maxChannels; ch++) {
            false => int used;
            for (0 => int i; i < devices.cap(); i++) {
                if (i != excludeIdx && devices[i] != null && devices[i].uiName == synthUiName && devices[i].midiChannel == ch) {
                    true => used;
                    break;
                }
            }
            if (!used) return ch;
        }
        return -1;
    }

    fun static int resolveMidiChannel(Patch devices[], int idx, string synthUiName)
    {
        findSynthIndex(synthUiName) => int entryIdx;
        if (entryIdx >= 0) {
            SynthTableData.FIXED_CHANNELS[entryIdx] => int fixedCh;
            if (fixedCh >= 0) {
                return fixedCh;
            }
            SynthTableData.MAX_CHANNELS[entryIdx] => int maxCh;
            if (maxCh > 1) {
                return findFirstUnusedChannel(devices, idx, synthUiName, maxCh);
            }
        }
        if (idx >= 0 && idx < devices.cap() && devices[idx] != null) {
            return devices[idx].midiChannel;
        }
        return 0;
    }
}
