// AugmentedMallets
// Purpose: Arturia Augmented MALLETS virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/augmented-mallets-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/augmented-mallets-presets.ck"

public class AugmentedMallets extends Patch
{
    fun void initDefaults()
    {
        "IAC Driver Augmented Mallets" => deviceName;
        "Augmented Mallets" => uiName;
        1 => midiChannel;
        0 => bank;
        0 => program;
        "A Royal Mallet" => patchName;
    }

    fun AugmentedMallets()
    {
        initDefaults();
        resolvePreset("A Royal Mallet");
    }

    fun AugmentedMallets(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedMallets(int channel, string presetName, int v)
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
            new AugmentedMalletsPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }

    fun void resolvePreset(string name)
    {
        if (name == "" || name == "default") {
            "A Royal Mallet" => name;
        }
        presets() @=> PresetCollection @ col;
        if (col.hasPreset(name)) {
            col.getPreset(name) @=> Preset @ preset;
            preset.program => program;
            preset.bank => bank;
            preset.name => patchName;
        } else {
            0 => program;
            0 => bank;
            name => patchName;
        }
    }

    fun void sendProgramChange(int bankMsb, int bankLsb, int prog)
    {
        if (bankMsb >= 0) {
            sendControllerChange(CadenzaConstants.CC_BANK_MSB(), bankMsb);
        }
        if (bankLsb >= 0) {
            sendControllerChange(CadenzaConstants.CC_BANK_LSB(), bankLsb);
        }
        MidiMsg msg;
        0xC0 | midiChannel => msg.data1;
        prog => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }

    fun void setPreset()
    {
        if (bank >= 0 && program >= 0) {
            // CC 0 = 0 (Cadenza Playlist), CC 32 = bank (Category Song), PC = program
            sendProgramChange(0, bank, program);
        }
    }

    fun void setVolume(int val)
    {
        val => volume;
        if (volume != -1) {
            // Augmented MALLETS Default MIDI Config maps CC 17 to MasterVolume; also emit standard CC 7.
            sendControllerChange(CadenzaConstants.CC_AUG_MALLETS_VOLUME(), volume);
            sendControllerChange(CadenzaConstants.CC_VOLUME(), volume);
        }
    }

    fun void setPan(int val)
    {
        val => pan;
    }

    // Augmented MALLETS macro CC helpers (Default MIDI Config)
    fun void setColor(int val)  { sendControllerChange(74, val); }
    fun void setMorph(int val)  { sendControllerChange(71, val); }
    fun void setTime(int val)   { sendControllerChange(76, val); }
    fun void setMotion(int val) { sendControllerChange(77, val); }
    fun void setFxA(int val)    { sendControllerChange(93, val); }
    fun void setFxB(int val)    { sendControllerChange(18, val); }
    fun void setDelay(int val)  { sendControllerChange(19, val); }
    fun void setReverb(int val) { sendControllerChange(16, val); }

    fun string declaration()
    {
        return "AugmentedMallets mallets(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\", " + Std.itoa(volume) + ");";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
        if (preset == null) return;
        sendProgramChange(0, preset.bank, preset.program);
        if (vol != -1) {
            setVolume(vol);
        }
        preset.name => patchName;
        preset.program => program;
        preset.bank => bank;
        <<< declaration(), "" >>>;
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
        if (deviceName == "" || deviceName == "IAC Driver Bus 1") {
            "IAC Driver Augmented Mallets" => deviceName;
        }
        "Augmented Mallets" => uiName;
        GuiLink.sendActivateSynth(uiName);
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        if (patchName != "") {
            presets() @=> PresetCollection @ col;
            if (col.hasPreset(patchName)) {
                resolvePreset(patchName);
            }
        } else {
            resolvePreset("A Royal Mallet");
        }
        updateControllers();
    }
}
