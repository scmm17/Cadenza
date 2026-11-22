// AugmentedStrings
// Purpose: Arturia Augmented STRINGS virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/augmented-strings-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/augmented-strings-presets.ck"

public class AugmentedStrings extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Augmented Strings",
            "Augmented Strings",
            0,
            "Baited Breath",
            CadenzaConstants.CC_AUGMENTED_VOLUME(),
            "AugmentedStrings",
            "augStrings"
        );
    }

    fun AugmentedStrings()
    {
        initDefaults();
        resolvePreset("Baited Breath");
    }

    fun AugmentedStrings(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedStrings(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AugmentedStringsPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    // Augmented STRINGS macro CC helpers (Default MIDI Config)
    fun void setColor(int val)  { sendControllerChange(74, val); }
    fun void setMorph(int val)  { sendControllerChange(71, val); }
    fun void setTime(int val)   { sendControllerChange(76, val); }
    fun void setMotion(int val) { sendControllerChange(77, val); }
    fun void setFxA(int val)    { sendControllerChange(93, val); }
    fun void setFxB(int val)    { sendControllerChange(18, val); }
    fun void setDelay(int val)  { sendControllerChange(19, val); }
    fun void setReverb(int val) { sendControllerChange(16, val); }
}
