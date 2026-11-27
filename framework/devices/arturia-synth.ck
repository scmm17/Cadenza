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
    int volumeSyncGen;
    int pendingVolumeOnNote;
    YamlNode @ auParamsNode;
    YamlNode @ auStateNode;

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

    fun void sendVolumeMidi(int val)
    {
        if (val == -1) return;
        CadenzaConstants.CC_VOLUME() => int cc;
        if (volumeCc >= 0) {
            volumeCc => cc;
        }
        // Arturia Default MIDI configs bind MasterVolume on channel 0 (MIDI ch 1).
        MidiMsg msg;
        0xB0 => msg.data1;
        cc => msg.data2;
        val => msg.data3;
        gma.send(msg);
        if (midiChannel != 0) {
            sendControllerChange(cc, val);
        }
    }

    fun void forceVolumeMidi(int val)
    {
        if (val == -1) return;
        // Nudge by 1 step before the target value so Arturia's MIDI engine
        // cannot ignore a repeated identical CC value (same effect as moving the slider).
        (val > 0 ? val - 1 : val + 1) => int nudge;
        sendVolumeMidi(nudge);
        sendVolumeMidi(val);
    }

    fun void cancelPendingControllers()
    {
        volumeSyncGen++;
        0 => pendingVolumeOnNote;
    }

    fun void onFragmentStart()
    {
        if (volume != -1) {
            0 => pendingVolumeOnNote;
            forceVolumeMidi(volume);
        }
    }

    fun void beforeNoteOn()
    {
        if (pendingVolumeOnNote && volume != -1) {
            0 => pendingVolumeOnNote;
            forceVolumeMidi(volume);
        }
    }

    fun void delayedVolumeSync(int gen)
    {
        // Arturia standalone apps load presets asynchronously after a Program Change
        // (sample-based Augmented presets can take 1-2s+) and reset MasterVolume to
        // the preset's saved value when loading finishes. Re-send the current volume
        // across settle windows unless superseded by a newer change or teardown.
        250::ms => now;
        if (gen != volumeSyncGen) return;
        if (volume != -1) { forceVolumeMidi(volume); }

        500::ms => now; // 750ms total
        if (gen != volumeSyncGen) return;
        if (volume != -1) { forceVolumeMidi(volume); }

        750::ms => now; // 1500ms total
        if (gen != volumeSyncGen) return;
        if (volume != -1) { forceVolumeMidi(volume); }

        1500::ms => now; // 3000ms total
        if (gen != volumeSyncGen) return;
        if (volume != -1) { forceVolumeMidi(volume); }
    }

    fun void schedulePostPresetVolumeSync()
    {
        1 => pendingVolumeOnNote;
        if (GuiLink.disabled) return;
        volumeSyncGen++;
        spork ~ delayedVolumeSync(volumeSyncGen);
    }

    fun void setVolume(int val)
    {
        val => volume;
        volumeSyncGen++;
        0 => pendingVolumeOnNote;
        sendVolumeMidi(volume);
    }

    fun void updateControllers()
    {
        setPreset();

        if (filterCutoff != -1) {
            setCutoff(filterCutoff);
        }
        if (filterResonance != -1) {
            setResonance(filterResonance);
        }
        if (pan != -1) {
            setPan(pan);
        }
        if (volume != -1) {
            setVolume(volume);
            schedulePostPresetVolumeSync();
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
        null @=> auParamsNode;
        null @=> auStateNode;
        sendProgramChange(0, preset.bank, preset.program);
        preset.name => patchName;
        preset.program => program;
        preset.bank => bank;
        if (vol != -1) {
            setVolume(vol);
            schedulePostPresetVolumeSync();
        }
        <<< declaration(), "" >>>;
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
        if (auParamsNode != null && auParamsNode.GetType() == YamlNode.TYPE_MAP() && auParamsNode.arrayValue.cap() > 0) {
            "auParams" => auParamsNode.name;
            config.findChild("auParams") => int existingParamsIdx;
            if (existingParamsIdx >= 0) {
                auParamsNode @=> config.arrayValue[existingParamsIdx];
            } else {
                config.arrayValue << auParamsNode;
            }
        }
        if (auStateNode != null && auStateNode.GetType() == YamlNode.TYPE_ARRAY() && auStateNode.arrayValue.cap() > 0) {
            "auState" => auStateNode.name;
            config.findChild("auState") => int existingStateIdx;
            if (existingStateIdx >= 0) {
                auStateNode @=> config.arrayValue[existingStateIdx];
            } else {
                config.arrayValue << auStateNode;
            }
        }
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        if (config.findChild("auParams") >= 0) {
            config.GetValue("auParams") @=> auParamsNode;
        } else {
            null @=> auParamsNode;
        }
        if (config.findChild("auState") >= 0) {
            config.GetValue("auState") @=> auStateNode;
        } else {
            null @=> auStateNode;
        }
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
