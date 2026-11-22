// AcidV
// Purpose: Arturia Acid V virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/acid-v-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/acid-v-presets.ck"

public class AcidV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Acid V",
            "Acid V",
            0,
            "Fast Travel",
            CadenzaConstants.CC_ACID_V_VOLUME(),
            "AcidV",
            "acid"
        );
    }

    fun AcidV()
    {
        initDefaults();
        resolvePreset("Fast Travel");
    }

    fun AcidV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AcidV(int channel, string presetName, int v)
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
            new AcidVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    // Acid V 303-specific CC helpers (Default MIDI Config)
    fun void setEnvMod(int val)          { sendControllerChange(19, val); }
    fun void setDecay(int val)           { sendControllerChange(16, val); }
    fun void setAccent(int val)          { sendControllerChange(17, val); }
    fun void setDistortionDrive(int val) { sendControllerChange(81, val); }
    fun void setDistortionMix(int val)   { sendControllerChange(82, val); }
    fun void setForceSlide(int on)       { sendControllerChange(83, on ? 127 : 0); }
}
