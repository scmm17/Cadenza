// ArturiaSynth
// Purpose: Shared base class for Arturia virtual instruments over dedicated CoreMIDI IAC buses and Cadenza Playlist PC.
// Imports: framework/devices/patch.ck
// Imported by: framework/devices/acid-v.ck, framework/devices/augmented-*.ck, framework/devices/synclavier-v.ck, framework/devices/synthi-v.ck, framework/cadenza.ck

@import "patch.ck"

public class ArturiaSynth extends Patch
{
    string defaultDeviceName;
    string defaultUiName;
    string defaultPatchName;
    string classDeclName;
    string varDeclName;
    int volumeCc;
    1 => int maxChannels;

    fun void initArturia(
        string devName,
        string ui,
        int defaultChan0,
        string defPatch,
        int volCc,
        string clsName,
        string varName
    )
    {
        devName => defaultDeviceName;
        ui => defaultUiName;
        defPatch => defaultPatchName;
        volCc => volumeCc;
        clsName => classDeclName;
        varName => varDeclName;

        devName => deviceName;
        ui => uiName;
        defaultChan0 => midiChannel;
        0 => bank;
        0 => program;
        defPatch => patchName;
    }

    fun void resolvePreset(string name)
    {
        if (name == "" || name == "default") {
            defaultPatchName => name;
        }
        presets() @=> PresetCollection @ col;
        if (col != null && col.hasPreset(name)) {
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
            CadenzaConstants.CC_VOLUME() => int cc;
            if (volumeCc >= 0) {
                volumeCc => cc;
            }
            // Arturia Default MIDI configs bind MasterVolume on channel 0 (MIDI ch 1).
            MidiMsg msg;
            0xB0 => msg.data1;
            cc => msg.data2;
            volume => msg.data3;
            gma.send(msg);
            if (midiChannel != 0) {
                sendControllerChange(cc, volume);
            }
        }
    }

    fun void setPan(int val)
    {
        val => pan;
    }

    fun string declaration()
    {
        return classDeclName + " " + varDeclName + "(" + Std.itoa(midiChannel + 1) + ", \"" + patchName + "\", " + Std.itoa(volume) + ");";
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
            defaultDeviceName => deviceName;
        }
        defaultUiName => uiName;
        // Every Arturia synth has its own dedicated IAC bus and factory Default MIDI CCs are bound on ch 1 (0).
        // Monotimbral synths normalize legacy saved channels to 0; multi-manual synths (e.g. B-3 V2, Solina V2)
        // preserve channels within 0..maxChannels-1.
        if (maxChannels <= 1 || midiChannel < 0 || midiChannel >= maxChannels) {
            0 => midiChannel;
        }
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
            if (col != null && col.hasPreset(patchName)) {
                resolvePreset(patchName);
            }
        } else {
            resolvePreset(defaultPatchName);
        }
        updateControllers();
    }
}
