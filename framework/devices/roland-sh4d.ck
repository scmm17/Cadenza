// RolandSH4d
// Purpose: Roland SH-4d MIDI patch implementation (pattern banks, channels, and per-channel tone presets).
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/sh4d-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/sh4d-presets.ck"

public class RolandSH4d extends Patch
{
    int programChange;
    string presetType; // "bank", "channel", or "tone"
    int toneProgram;
    int toneBank;

    fun RolandSH4d()
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        0 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        "channel" => presetType;
        "Channel 1" => patchName;
    }

    fun RolandSH4d(int channel, int b, int p, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        if (b >= 64) {
            0 => program;
            0 => bank;
            false => programChange;
            b => toneBank;
            p => toneProgram;
            "tone" => presetType;
            presets().getPreset(b, p) @=> Preset @ preset;
            if (preset != null) {
                preset.name => patchName;
            } else {
                "Tone Bank: " + Std.itoa(b) + " Program: " + Std.itoa(p + 1) => patchName;
            }
        } else {
            p => program;
            b => bank;
            true => programChange;
            -1 => toneProgram;
            -1 => toneBank;
            "bank" => presetType;
            "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        }
        Patch(v);
    }

    fun RolandSH4d(int channel, string pName, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        resolvePreset(pName);
        Patch(v);
    }

    fun RolandSH4d(int channel, int b, int p, string pName, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        resolvePreset(pName);
        Patch(v);
    }

    fun RolandSH4d(int channel, int b, int p, int tb, int tp, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        tb => toneBank;
        tp => toneProgram;
        "tone" => presetType;
        presets().getPreset(tb, tp) @=> Preset @ preset;
        if (preset != null) {
            preset.name => patchName;
        } else {
            "Tone Bank: " + Std.itoa(tb) + " Program: " + Std.itoa(tp + 1) => patchName;
        }
        Patch(v);
    }

    fun RolandSH4d(int channel, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        "channel" => presetType;
        "Channel " + Std.itoa(channel) => patchName;
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new SH4dPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    fun void syncPresetCursor()
    {
        presets().setPresetState(patchName, toneBank, toneProgram);
    }

    fun int stateBank()
    {
        if (presetType == "tone") return toneBank;
        return -1;
    }

    fun int stateProgram()
    {
        if (presetType == "tone") return toneProgram;
        return -1;
    }

    fun void onChannelChanged(int channel1Based)
    {
        if (presetType == "channel" && patchName.find("Channel ") == 0) {
            "Channel " + Std.itoa(channel1Based) => patchName;
        }
    }

    fun void reapplyLoadedPreset()
    {
        if (presetType == "tone" && toneBank >= 0 && toneProgram >= 0) {
            programChangeSH4dChannel(toneProgram, toneBank);
        }
    }

    fun void copyPresetMetadataFrom(Patch @ source)
    {
        if (source == null) return;
        source.patchName => patchName;
        source.stateBank() => toneBank;
        source.stateProgram() => toneProgram;
        source.stateBank() => bank;
        source.stateProgram() => program;
        if (toneBank >= 0 && toneProgram >= 0) {
            "tone" => presetType;
        }
        syncPresetCursor();
    }

    fun void refreshSiblingPresets(Patch @ devices[])
    {
        if (devices == null) return;
        for (Patch p : devices) {
            if (p != null && p.uiName == "SH-4d") {
                p $ RolandSH4d @=> RolandSH4d @ otherSh;
                if (otherSh.programChange) {
                    otherSh.setPreset();
                }
            }
        }
    }

    fun void programChangeSH4d(int prog)
    {
        MidiMsg msg;
        0xC0 | 15 => msg.data1;
        86 => msg.data2;
        prog => msg.data3;
        gma.send(msg);
    }

    fun void programChangeSH4dChannel(int prog, int bnk)
    {
        sendProgramChange(88, bnk, prog);
    }

    fun void resolvePreset(string pName)
    {
        presets() @=> PresetCollection @ collection;
        if (collection.hasPreset(pName)) {
            collection.getPreset(pName) @=> Preset @ p;
            p.program => toneProgram;
            p.bank => toneBank;
            p.name => patchName;
            "tone" => presetType;
        } else {
            -1 => toneProgram;
            -1 => toneBank;
            pName => patchName;
            if (programChange) {
                "bank" => presetType;
            } else {
                "channel" => presetType;
            }
        }
    }

    fun void setChannelPreset(string presetName)
    {
        resolvePreset(presetName);
        if (presetType == "tone" && toneBank >= 0 && toneProgram >= 0) {
            programChangeSH4dChannel(toneProgram, toneBank);
        }
    }

    fun void setChannelPreset(int tb, int tp)
    {
        tb => toneBank;
        tp => toneProgram;
        "tone" => presetType;
        presets().getPreset(tb, tp) @=> Preset @ p;
        if (p != null) {
            p.name => patchName;
        } else {
            "Tone Bank: " + Std.itoa(tb) + " Program: " + Std.itoa(tp + 1) => patchName;
        }
        programChangeSH4dChannel(toneProgram, toneBank);
    }

    fun string declaration()
    {
        return "RolandSH4d sh4d(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\", " + Std.itoa(volume) + ");";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
        if (preset == null) return;
        programChangeSH4dChannel(preset.program, preset.bank);
        if (vol != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), vol);
        }
        preset.name => patchName;
        preset.program => toneProgram;
        preset.bank => toneBank;
        "tone" => presetType;
        <<< declaration(), "" >>>;
    }

    fun int selectPresetByName(string presetName, int vol)
    {
        ensurePresets() @=> PresetCollection @ col;
        if (col != null && col.hasPreset(presetName)) {
            col.setPresetState(presetName);
            applyPresetObject(col.getPreset(presetName), vol);
            return 1;
        }
        resolvePreset(presetName);
        return 0;
    }

    fun void setPreset()
    {
        if (programChange) {
            (bank - 1) * 16 + program - 1 => int preset;
            programChangeSH4d(preset);
            0.1::second => now;
        }
        if (presetType == "tone" && toneBank >= 0 && toneProgram >= 0) {
            programChangeSH4dChannel(toneProgram, toneBank);
            0.1::second => now;
        }
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
        config.SetInt("programChange", programChange);
        config.SetString("presetType", presetType);
        if (presetType == "tone") {
            config.SetInt("toneProgram", toneProgram);
            config.SetInt("toneBank", toneBank);
        }
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        if (config.findChild("programChange") >= 0) {
            config.GetInt("programChange") => programChange;
        }
        if (config.findChild("presetType") >= 0) {
            config.GetString("presetType") => presetType;
        } else {
            if (programChange) {
                "bank" => presetType;
            } else {
                "channel" => presetType;
            }
        }
        if (config.findChild("toneProgram") >= 0) {
            config.GetInt("toneProgram") => toneProgram;
        } else {
            -1 => toneProgram;
        }
        if (config.findChild("toneBank") >= 0) {
            config.GetInt("toneBank") => toneBank;
        } else {
            -1 => toneBank;
        }
        presets() @=> PresetCollection @ collection;
        if (presetType == "tone" || collection.hasPreset(patchName)) {
            "tone" => presetType;
            if (!collection.matchesPreset(patchName, toneBank, toneProgram)) {
                if (collection.hasPreset(patchName)) {
                    collection.getPreset(patchName) @=> Preset @ p;
                    p.program => toneProgram;
                    p.bank => toneBank;
                    p.name => patchName;
                } else if (toneBank >= 0 && toneProgram >= 0) {
                    collection.getPreset(toneBank, toneProgram) @=> Preset @ p;
                    if (p != null) {
                        p.name => patchName;
                    }
                }
            } else {
                collection.getPreset(toneBank, toneProgram) @=> Preset @ p;
                if (p != null) {
                    p.name => patchName;
                }
            }
        }
        if (patchName == "") {
            "Channel " + Std.itoa(midiChannel + 1) => patchName;
        }
        updateControllers();
    }
}
