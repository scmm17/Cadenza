// V3GrandPiano
// Purpose: V3 Sound Grand Piano XXL MIDI patch implementation and preset selection.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/v3-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/v3-presets.ck"

public class V3GrandPiano extends Patch
{
    int programChange;

    fun V3GrandPiano()
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        0 => midiChannel;
        0 => program;
        0 => bank;
        true => programChange;
        "Grand Piano Vienna" => patchName;
    }

    fun V3GrandPiano(int channel, int b, int p, int v)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        Patch(v);
    }

    fun V3GrandPiano(int channel, int v)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        Patch(v);
    }

    fun V3GrandPiano(int channel, string presetName, int v)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        presets().getPreset(presetName) @=> Preset @ preset;
        preset.program => program;
        preset.bank => bank;
        true => programChange;
        preset.name => patchName;
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new V3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    fun void setPreset()
    {
        if (programChange) {
            sendProgramChange(bank, 0, program);
            0.1::second => now;
        }
    }

    fun string declaration()
    {
        return "V3GrandPiano instrument(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\");";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
        if (preset == null) return;
        sendProgramChange(preset.bank, 0, preset.program);
        if (vol != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), vol);
        }
        preset.name => patchName;
        preset.program => program;
        preset.bank => bank;
        true => programChange;
        <<< declaration(), "" >>>;
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
        config.SetInt("programChange", programChange);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        true => programChange;
        if (patchName == "") {
            "Grand Piano Vienna" => patchName;
        }
        updateControllers();
    }
}
