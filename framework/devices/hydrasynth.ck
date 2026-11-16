// Hydrasynth
// Purpose: ASM Hydrasynth Explorer MIDI patch implementation and preset selection.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/hydrasynth-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/hydrasynth-presets.ck"

public class Hydrasynth extends Patch
{
    string presetName;

    fun Hydrasynth()
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        0 => midiChannel;
        "A001" => presetName;
        "Sawpressive GD" => patchName;
        0 => bank;
        0 => program;
    }

    fun Hydrasynth(string preset, int v)
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        0 => midiChannel;
        resolvePreset(preset);
        Patch(v);
    }

    fun Hydrasynth(int channel, string preset, int v)
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        channel - 1 => midiChannel;
        resolvePreset(preset);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new HydraPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    fun void resolvePreset(string preset)
    {
        if (preset == "" || preset == "default") {
            preset => presetName;
            preset => patchName;
            -1 => program;
            -1 => bank;
            return;
        }
        presets() @=> PresetCollection @ collection;
        if (collection.hasPreset(preset)) {
            collection.getPreset(preset) @=> Preset @ p;
            p.program => program;
            p.bank => bank;
            p.code => presetName;
            p.name => patchName;
        } else if (preset.length() >= 2) {
            preset => presetName;
            preset => patchName;
            preset.substring(0, 1) => string bankStr;
            preset.substring(1) => string programStr;
            bankStr.charAt(0) - "A".charAt(0) => bank;
            programStr.toInt() - 1 => program;
        } else {
            preset => presetName;
            preset => patchName;
            -1 => program;
            -1 => bank;
        }
    }

    fun void setPreset()
    {
        if (bank >= 0 && program >= 0) {
            sendProgramChange(bank, bank, program);
        }
    }

    fun string declaration()
    {
        return "Hydrasynth hydrasynth(\"" + patchName + "\", " + Std.itoa(volume) + ");";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
        if (preset == null) return;
        sendProgramChange(preset.bank, preset.bank, preset.program);
        if (vol != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), vol);
        }
        preset.name => patchName;
        preset.program => program;
        preset.bank => bank;
        preset.code => presetName;
        <<< declaration(), "" >>>;
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetString("presetName", presetName);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        openDevice();
        "" => string savedPreset;
        if (config.findChild("presetName") >= 0) {
            config.GetString("presetName") => savedPreset;
        }
        presets() @=> PresetCollection @ collection;
        if (patchName != "" && patchName != savedPreset && collection.hasPreset(patchName)) {
            resolvePreset(patchName);
        } else if (savedPreset != "" && collection.hasPreset(savedPreset)) {
            resolvePreset(savedPreset);
        } else if (patchName != "") {
            resolvePreset(patchName);
        } else if (savedPreset != "") {
            resolvePreset(savedPreset);
        } else {
            resolvePreset("A001");
        }
        updateControllers();
    }
}
