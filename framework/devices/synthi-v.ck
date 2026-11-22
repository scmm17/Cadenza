// SynthiV
// Purpose: Arturia Synthi V virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/synthi-v-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/synthi-v-presets.ck"

public class SynthiV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Synthi V",
            "Synthi V",
            0,
            "On The Run",
            CadenzaConstants.CC_VOLUME(),
            "SynthiV",
            "synthi"
        );
    }

    fun SynthiV()
    {
        initDefaults();
        resolvePreset("On The Run");
    }

    fun SynthiV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SynthiV(int channel, string presetName, int v)
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
            new SynthiVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}
