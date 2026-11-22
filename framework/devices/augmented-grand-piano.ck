// AugmentedGrandPiano
// Purpose: Arturia Augmented GRAND PIANO virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/augmented-grand-piano-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/augmented-grand-piano-presets.ck"

public class AugmentedGrandPiano extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Augmented Grand Piano",
            "Augmented Grand Piano",
            0,
            "Kairos",
            CadenzaConstants.CC_AUGMENTED_VOLUME(),
            "AugmentedGrandPiano",
            "augPiano"
        );
    }

    fun AugmentedGrandPiano()
    {
        initDefaults();
        resolvePreset("Kairos");
    }

    fun AugmentedGrandPiano(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedGrandPiano(int channel, string presetName, int v)
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
            new AugmentedGrandPianoPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    // Augmented GRAND PIANO macro CC helpers (Default MIDI Config)
    fun void setColor(int val)  { sendControllerChange(74, val); }
    fun void setMorph(int val)  { sendControllerChange(71, val); }
    fun void setTime(int val)   { sendControllerChange(76, val); }
    fun void setMotion(int val) { sendControllerChange(77, val); }
    fun void setFxA(int val)    { sendControllerChange(93, val); }
    fun void setFxB(int val)    { sendControllerChange(18, val); }
    fun void setDelay(int val)  { sendControllerChange(19, val); }
    fun void setReverb(int val) { sendControllerChange(16, val); }
}
