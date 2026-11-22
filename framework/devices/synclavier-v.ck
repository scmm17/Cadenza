// SynclavierV
// Purpose: Arturia Synclavier V virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/arturia-synth.ck, framework/devices/presets/generated/synclavier-v-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "arturia-synth.ck"
@import "presets/generated/synclavier-v-presets.ck"

public class SynclavierV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia(
            "IAC Driver Synclavier V",
            "Synclavier V",
            0,
            "Naked Planet",
            CadenzaConstants.CC_VOLUME(),
            "SynclavierV",
            "synclavier"
        );
    }

    fun SynclavierV()
    {
        initDefaults();
        resolvePreset("Naked Planet");
    }

    fun SynclavierV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SynclavierV(int channel, string presetName, int v)
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
            new SynclavierVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}
