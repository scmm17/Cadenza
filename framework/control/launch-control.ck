// ControlChange & LaunchControl
// Purpose: Launch Control XL hardware MIDI surface input (knobs, buttons) and LED feedback.
// Imports: framework/core/constants.ck, framework/composition/fragment.ck, framework/devices/patch.ck
// Imported by: framework/song/song.ck

@import "../core/constants.ck"
@import "../composition/fragment.ck"
@import "../devices/patch.ck"

public class ControlChange
{
    string name;
    int minController;
    int maxController;
    int mapToController;

    fun ControlChange(string n, int min, int max, int outController)
    {
        min => minController;
        max => maxController;
        outController => mapToController;
        n => name;
    }
}

public class LaunchControl
{
    string inputDeviceName;
    string outputDeviceName;
    int outputChannel;

    MidiIn min;
    MidiOut mout;
    MidiMsg msg;
    SongState @ song;

    [
      new ControlChange("Volume",    77, 84, CadenzaConstants.CC_VOLUME()),
      new ControlChange("Mod Wheel", 13, 20, CadenzaConstants.CC_CUTOFF()),
      new ControlChange("Resonance", 29, 36, CadenzaConstants.CC_RESONANCE()),
      new ControlChange("Pan",       49, 56, CadenzaConstants.CC_PAN()),
    ]
    @=> static ControlChange ccHandlers[];

    fun LaunchControl(SongState @ s)
    {
        "Launch Control XL" => inputDeviceName;
        s @=> song;
    }

    fun void startEventLoop()
    {
        midi_events();
    }

    fun void midi_events()
    {
        min.open(inputDeviceName) => int status;
        if (!status) {
            <<< "Failed to open Launch Control input", inputDeviceName >>>;
            me.exit();
        }
        mout.open(inputDeviceName) => status;
        if (!status) {
            <<< "Failed to open Launch Control output", inputDeviceName >>>;
            me.exit();
        }

        CadenzaConstants.LC_SELECT_BASE() => int selBase;
        CadenzaConstants.LC_MUTE_BASE() => int muteBase;
        CadenzaConstants.LC_LED_GREEN() => int green;

        setActiveSelectionLED(0, selBase, selBase, green);
        setActiveSoloLED(0, muteBase, 0, green);
        setLED(0, CadenzaConstants.LC_MUTE_MODE(), green, song.muteMode);
        setLED(0, CadenzaConstants.LC_SOLO_MODE(), green, song.soloMode);

        while (true) {
            min => now;
            while (min.recv(msg)) {
                <<< "In d1:", msg.data1, "d2:", msg.data2, "d3:", msg.data3 >>>;
                msg.data1 & 0x0F => int channel;
                msg.data1 & 0xFFF0 => int cc;
                <<< "CC:", cc, "channel:", channel >>>;
                false => int handled;
                if (cc == 0xB0) {
                    handleControlChange(msg.data2, msg.data3) => handled;
                }
                if (handled) {
                    continue;
                }
                if (cc == 0x90) {
                    handleButtonDown(channel, msg.data2, msg.data3) => handled;
                } else if (cc == 0x80) {
                    handleButtonUp(channel, msg.data2, msg.data3) => handled;
                }
                if (handled) {
                    continue;
                }
            }
        }
    }

    fun int handleControlChange(int baseControlNumber, int value)
    {
        for (ControlChange cc : ccHandlers) {
            if (baseControlNumber >= cc.minController &&
                baseControlNumber <= cc.maxController) {
                baseControlNumber - cc.minController => int channel;
                song.devices[channel] @=> Patch patch;
                if (patch != null) {
                    if (cc.mapToController == CadenzaConstants.CC_VOLUME()) {
                        patch.setVolume(value);
                    } else if (cc.mapToController == CadenzaConstants.CC_CUTOFF()) {
                        patch.setCutoff(value);
                    } else if (cc.mapToController == CadenzaConstants.CC_RESONANCE()) {
                        patch.setResonance(value);
                    } else if (cc.mapToController == CadenzaConstants.CC_PAN()) {
                        patch.setPan(value);
                    } else {
                        patch.sendControllerChange(cc.mapToController, value);
                    }
                    spork ~ song.notifyStateChanged();
                    return true;
                }
                return false;
            }
        }
        return false;
    }

    fun void setLED(int channel, int note, int color, int on)
    {
        if (on) {
            0x90 => msg.data1;
        } else {
            0x80 => msg.data1;
        }
        note => msg.data2;
        color => msg.data3;
        mout.send(msg);
    }

    fun void setActiveSelectionLED(int channel, int baseNote, int note, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            setLED(channel, i, color, i == note);
        }
    }

    fun void setActiveMutedLED(int channel, int baseNote, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            i - baseNote => int j;
            if (song.muteMode && j >= 0 && j < song.devices.cap() && song.devices[j] != null) {
                setLED(channel, i, color, song.devices[j].userMuted);
            } else {
                setLED(channel, i, color, false);
            }
        }
    }

    fun void setActiveSoloLED(int channel, int baseNote, int note, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            i - baseNote => int j;
            if (song.soloMode && j >= 0 && j < song.devices.cap() && song.devices[j] != null) {
                song.devices[j] @=> Patch patch;
                setLED(channel, i, color, !patch.muted);
                if (patch.muted) {
                    patch.sendAllNotesOff();
                }
            } else {
                setLED(channel, i, color, false);
            }
        }
    }

    fun int handleButtonDown(int channel, int note, int velocity)
    {
        CadenzaConstants.LC_SELECT_BASE() => int selBase;
        CadenzaConstants.LC_MUTE_BASE() => int muteBase;
        CadenzaConstants.LC_LED_GREEN() => int green;
        CadenzaConstants.LC_LED_RED() => int red;

        if (note >= selBase && note <= selBase + 7) {
            note - selBase => int i;
            if (song.selectDevice(i)) {
                setActiveSelectionLED(channel, selBase, note, green);
                song.notifyStateChanged();
                return true;
            }
        }
        if (song.muteMode && note >= muteBase && note <= muteBase + 7) {
            note - muteBase => int i;
            if (i >= 0 && i < song.devices.cap() && song.devices[i] != null) {
                song.toggleMute(song.devices[i]);
                setActiveMutedLED(channel, muteBase, red);
                song.notifyStateChanged();
                return true;
            }
        }
        if (song.soloMode && note >= muteBase && note <= muteBase + 7) {
            note - muteBase => int i;
            if (i >= 0 && i < song.devices.cap() && song.devices[i] != null) {
                song.toggleSoloPatch(song.devices[i]);
                setActiveSoloLED(channel, muteBase, note, green);
                song.notifyStateChanged();
                return true;
            }
        }
        if (note == CadenzaConstants.LC_PREV_CAT()) {
            song.setPreviousPresetCategory(song.currentDevice.volume);
            song.notifyStateChanged();
            return true;
        }
        if (note == CadenzaConstants.LC_NEXT_CAT()) {
            song.setNextPresetCategory(song.currentDevice.volume);
            song.notifyStateChanged();
            return true;
        }
        if (note == CadenzaConstants.LC_PREV_PRESET()) {
            song.setPreviousPreset(song.currentDevice.volume);
            song.notifyStateChanged();
            return true;
        }
        if (note == CadenzaConstants.LC_NEXT_PRESET()) {
            song.setNextPreset(song.currentDevice.volume);
            song.notifyStateChanged();
            return true;
        }
        if (note == CadenzaConstants.LC_MUTE_MODE()) {
            song.toggleMuteMode(note);
            setLED(channel, CadenzaConstants.LC_MUTE_MODE(), green, song.muteMode);
            setLED(channel, CadenzaConstants.LC_SOLO_MODE(), green, song.soloMode);
            setActiveMutedLED(channel, muteBase, red);
            song.notifyStateChanged();
            return true;
        }
        if (note == CadenzaConstants.LC_SOLO_MODE()) {
            song.toggleSoloMode(note);
            setLED(channel, CadenzaConstants.LC_SOLO_MODE(), green, song.soloMode);
            setLED(channel, CadenzaConstants.LC_MUTE_MODE(), green, song.muteMode);
            setActiveSoloLED(channel, muteBase, 0, green);
            song.notifyStateChanged();
            return true;
        }
        return false;
    }

    fun int handleButtonUp(int channel, int note, int velocity)
    {
        return true;
    }
}
