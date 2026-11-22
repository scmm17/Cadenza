// AcidV
// Purpose: Arturia Acid V virtual synth MIDI patch implementation via IAC Driver and Cadenza Playlist PC.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/acid-v-presets.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/acid-v-presets.ck"

public class AcidV extends Patch
{
    fun void initDefaults()
    {
        "IAC Driver Acid V" => deviceName;
        "Acid V" => uiName;
        0 => midiChannel;
        0 => bank;
        0 => program;
        "Fast Travel" => patchName;
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

    fun void resolvePreset(string name)
    {
        if (name == "" || name == "default") {
            "Fast Travel" => name;
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
            // Acid V Default MIDI Config maps CC 85 to MasterVolume; also emit standard CC 7.
            sendControllerChange(CadenzaConstants.CC_ACID_V_VOLUME(), volume);
            sendControllerChange(CadenzaConstants.CC_VOLUME(), volume);
        }
    }

    fun void setPan(int val)
    {
        // Monophonic 303: keep pan in state without emitting unmapped CC 10.
        val => pan;
    }

    // Acid V 303-specific CC helpers (Default MIDI Config)
    fun void setEnvMod(int val)          { sendControllerChange(19, val); }
    fun void setDecay(int val)           { sendControllerChange(16, val); }
    fun void setAccent(int val)          { sendControllerChange(17, val); }
    fun void setDistortionDrive(int val) { sendControllerChange(81, val); }
    fun void setDistortionMix(int val)   { sendControllerChange(82, val); }
    fun void setForceSlide(int on)       { sendControllerChange(83, on ? 127 : 0); }

    fun string declaration()
    {
        return "AcidV acid(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\", " + Std.itoa(volume) + ");";
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
            "IAC Driver Acid V" => deviceName;
        }
        "Acid V" => uiName;
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
            resolvePreset("Fast Travel");
        }
        updateControllers();
    }
}
