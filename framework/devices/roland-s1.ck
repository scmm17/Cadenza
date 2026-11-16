// RolandS1
// Purpose: Roland AIRA Compact S-1 MIDI patch implementation.
// Imports: framework/devices/patch.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"

public class RolandS1 extends Patch
{
    fun RolandS1()
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        2 => midiChannel;
        1 => program;
        1 => bank;
        "Bank: 1 Program: 1" => patchName;
    }

    fun RolandS1(int b, int p, int v)
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        2 => midiChannel;
        p => program;
        b => bank;
        "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        Patch(-1);
    }

    fun RolandS1(int channel, int b, int p, int v)
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        Patch(v);
    }

    fun void setPreset()
    {
        (bank - 1) * 16 + program - 1 => int preset;
        MidiMsg msg;
        0xC0 | 15 => msg.data1;
        preset => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        } else {
            1 => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        } else {
            1 => bank;
        }
        if (program < 1) { 1 => program; }
        if (bank < 1) { 1 => bank; }
        if (patchName == "") {
            "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        }
        updateControllers();
    }
}
