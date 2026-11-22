// Patch
// Purpose: Base MIDI instrument patch abstraction with controller helpers, note/MIDI output, and polymorphic preset hooks.
// Imports: framework/core/constants.ck, framework/core/gui-link.ck, framework/core/yaml.ck, framework/devices/presets/preset.ck, framework/devices/presets/preset-collection.ck
// Imported by: framework/devices/*.ck, framework/devices/synth-registry.ck, framework/composition/part.ck

@import "../core/constants.ck"
@import "../core/gui-link.ck"
@import "../core/yaml.ck"
@import "presets/preset.ck"
@import "presets/preset-collection.ck"

public class Patch
{
    string deviceName;
    int midiChannel;      // 0-based (0..15)
    string patchName;
    int volume;           // 0-127, -1 for unused
    int filterCutoff;     // 0-127, -1 for unused
    int filterResonance;  // 0-127, -1 for unused
    int pan;              // 0=left, 64=center, 127=right, -1 for unused
    string uiName;
    int muted;            // Effective runtime muted state (used by noteOn)
    int userMuted;        // User-toggled explicit mute state
    int program;
    int bank;
    int devIndex;         // 1-based device index (1-16)
    int activeNotes[128];

    MidiOut gma;
    string openedDeviceName;
    PresetCollection @ presetCollection;

    fun Patch()
    {
        127 => volume;
        -1 => filterCutoff;
        -1 => filterResonance;
        64 => pan;
        false => muted;
        false => userMuted;
        "" => openedDeviceName;
    }

    fun void openDevice()
    {
        if (deviceName != "" && deviceName != openedDeviceName) {
            gma.open(deviceName) => int status;
            deviceName => openedDeviceName;
            if (!status) {
                <<< "Failed to open", gma.name() >>>;
            }
        }
    }

    fun Patch(int v)
    {
        openDevice();
        v => volume;
        if (volume == -1) {
            127 => volume;
        }
        -1 => filterCutoff;
        -1 => filterResonance;
        64 => pan;
        false => muted;
        false => userMuted;
        updateControllers();
    }

    fun void setPreset()
    {
    }

    fun void saveConfig(YamlNode @config)
    {
        <<< "saveConfig not implemented for:", deviceName >>>;
    }

    fun void loadConfig(YamlNode @config)
    {
        <<< "loadConfig not implemented for:", deviceName >>>;
    }

    fun void loadCommonConfig(YamlNode @config)
    {
        if (config.findChild("deviceName") >= 0) {
            config.GetString("deviceName") => deviceName;
        }
        if (config.findChild("midiChannel") >= 0) {
            config.GetInt("midiChannel") => midiChannel;
        }
        if (midiChannel < 0) { 0 => midiChannel; }
        if (midiChannel > 15) { 15 => midiChannel; }
        if (config.findChild("patchName") >= 0) {
            config.GetString("patchName") => patchName;
        }
        if (config.findChild("uiName") >= 0) {
            config.GetString("uiName") => uiName;
        }
        if (config.findChild("muted") >= 0) {
            config.GetInt("muted") => userMuted;
            userMuted => muted;
        }
        if (config.findChild("volume") >= 0) {
            config.GetInt("volume") => volume;
        }
        if (config.findChild("filterCutoff") >= 0) {
            config.GetInt("filterCutoff") => filterCutoff;
        }
        if (config.findChild("filterResonance") >= 0) {
            config.GetInt("filterResonance") => filterResonance;
        }
        if (config.findChild("pan") >= 0) {
            config.GetInt("pan") => pan;
        }
        openDevice();
    }

    fun void saveCommonConfig(YamlNode @config)
    {
        config.SetString("deviceName", deviceName);
        config.SetInt("midiChannel", midiChannel);
        config.SetString("patchName", patchName);
        config.SetString("uiName", uiName);
        config.SetInt("muted", userMuted);
        config.SetInt("volume", volume);
        config.SetInt("filterCutoff", filterCutoff);
        config.SetInt("filterResonance", filterResonance);
        config.SetInt("pan", pan);
    }

    fun void setCutoff(int val)
    {
        val => filterCutoff;
        if (filterCutoff != -1) {
            sendControllerChange(CadenzaConstants.CC_CUTOFF(), filterCutoff);
        }
    }

    fun void setResonance(int val)
    {
        val => filterResonance;
        if (filterResonance != -1) {
            sendControllerChange(CadenzaConstants.CC_RESONANCE(), filterResonance);
        }
    }

    fun void setVolume(int val)
    {
        val => volume;
        if (volume != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), volume);
        }
    }

    fun void setPan(int val)
    {
        val => pan;
        if (pan != -1) {
            sendControllerChange(CadenzaConstants.CC_PAN(), pan);
        }
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
        }
    }

    fun void sendControllerChange(int controller, int value)
    {
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        controller => msg.data2;
        value => msg.data3;
        gma.send(msg);
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
        0 => msg.data2;
        prog => msg.data3;
        gma.send(msg);
    }

    fun void sendAllNotesOff()
    {
        for (0 => int n; n < 128; n++) {
            while (activeNotes[n] > 0) {
                noteOff(n);
            }
        }
        GuiLink.sendAllNotesOff(devIndex);
        sendControllerChange(CadenzaConstants.CC_ALL_SOUND_OFF(), 0);
        sendControllerChange(CadenzaConstants.CC_ALL_NOTES_OFF(), 0);
    }

    fun void noteOn(int note, int velocity, dur duration)
    {
        if (muted) {
            return;
        }
        if (note >= 0 && note < 128) {
            activeNotes[note]++;
        }
        GuiLink.sendNoteOn(devIndex, note, velocity);
        MidiMsg msg;
        0x90 | midiChannel => msg.data1;
        note => msg.data2;
        velocity => msg.data3;
        gma.send(msg);
        if (duration > 0::ms) {
            spork ~ noteOffFun(note, duration - 1::ms);
        }
    }

    fun void noteOff(int note)
    {
        if (note >= 0 && note < 128) {
            if (activeNotes[note] > 0) {
                activeNotes[note]--;
            }
        }
        GuiLink.sendNoteOff(devIndex, note);
        MidiMsg msg;
        0x80 | midiChannel => msg.data1;
        note => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }

    fun noteOffFun(int note, dur duration)
    {
        duration => now;
        noteOff(note);
    }

    // ── Polymorphic preset & state hooks ──────────────────────────────────────
    fun PresetCollection presets()
    {
        return presetCollection;
    }

    fun PresetCollection ensurePresets()
    {
        if (presetCollection == null) {
            presets() @=> presetCollection;
            if (presetCollection != null) {
                syncPresetCursor();
            }
        }
        return presetCollection;
    }

    fun void syncPresetCursor()
    {
        presets() @=> PresetCollection @ col;
        if (col != null) {
            col.setPresetState(patchName);
        }
    }

    fun string declaration()
    {
        return "";
    }

    fun void applyPresetObject(Preset preset, int vol)
    {
    }

    fun void stepPreset(int delta, int vol)
    {
        ensurePresets() @=> PresetCollection @ col;
        if (col == null) return;
        Preset @ preset;
        if (delta >= 0) {
            col.getNextPreset() @=> preset;
        } else {
            col.getPreviousPreset() @=> preset;
        }
        if (preset != null) {
            applyPresetObject(preset, vol);
        }
    }

    fun void stepPresetCategory(int delta, int vol)
    {
        ensurePresets() @=> PresetCollection @ col;
        if (col == null) return;
        Preset @ preset;
        if (delta >= 0) {
            col.getNextCategory() @=> preset;
        } else {
            col.getPreviousCategory() @=> preset;
        }
        if (preset != null) {
            <<< "Category:", preset.category >>>;
            applyPresetObject(preset, vol);
        }
    }

    fun int selectPresetByName(string name, int vol)
    {
        ensurePresets() @=> PresetCollection @ col;
        if (col == null) return 0;
        col.setPresetState(name);
        col.getPreset(name) @=> Preset @ preset;
        if (preset != null) {
            applyPresetObject(preset, vol);
            return 1;
        }
        return 0;
    }

    fun int stateBank() { return bank; }
    fun int stateProgram() { return program; }
    fun void onChannelChanged(int channel1Based) {}
    fun void reapplyLoadedPreset() {}
    fun void refreshSiblingPresets(Patch @ devices[]) {}
}
