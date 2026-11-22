// AugmentedBrass
// Purpose: Arturia Augmented BRASS virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/augmented-brass-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/augmented-brass-presets.ck"

public class AugmentedBrass extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Augmented Brass",
            "Augmented Brass",
            0,
            "Wide and Proud",
            CadenzaConstants.CC_AUGMENTED_VOLUME(),
            "AugmentedBrass",
            "brass"
        );
    }

    fun AugmentedBrass()
    {
        initDefaults();
        resolvePreset("Wide and Proud");
    }

    fun AugmentedBrass(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedBrass(int channel, string presetName, int v)
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
            new AugmentedBrassPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    // Augmented BRASS macro CC helpers (Default MIDI Config)
    fun void setColor(int val)  { sendControllerChange(74, val); }
    fun void setMorph(int val)  { sendControllerChange(71, val); }
    fun void setTime(int val)   { sendControllerChange(76, val); }
    fun void setMotion(int val) { sendControllerChange(77, val); }
    fun void setFxA(int val)    { sendControllerChange(93, val); }
    fun void setFxB(int val)    { sendControllerChange(18, val); }
    fun void setDelay(int val)  { sendControllerChange(19, val); }
    fun void setReverb(int val) { sendControllerChange(16, val); }
}
