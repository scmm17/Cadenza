// BehringerRD6
// Purpose: Behringer RD-6 Rhythm Designer MIDI patch implementation.
// Imports: framework/devices/patch.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"

public class BehringerRD6 extends Patch
{
    string presetName;

    fun BehringerRD6()
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        0 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;
    }

    fun BehringerRD6(int v)
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        0 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;

        Patch(v);
    }

    fun BehringerRD6(int channel, int v)
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        channel - 1 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;

        Patch(v);
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetString("presetName", presetName);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        openDevice();
        if (config.findChild("presetName") >= 0) {
            config.GetString("presetName") => presetName;
        } else {
            "RHYTHM DESIGNER RD-6" => presetName;
        }
        if (patchName == "") {
            "RHYTHM DESIGNER RD-6" => patchName;
        }
        updateControllers();
    }
}
