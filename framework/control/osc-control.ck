// OscControl
// Purpose: Receives OSC control commands on port 9449 and dispatches them to SongState.
// Imports: framework/core/constants.ck, framework/composition/fragment.ck
// Imported by: framework/song/song.ck

@import "../core/constants.ck"
@import "../composition/fragment.ck"

public class OscControl
{
    SongState @ song;

    fun OscControl(SongState @ s)
    {
        s @=> song;
    }

    fun Patch getDevice(int devIdx1Based)
    {
        devIdx1Based - 1 => int idx;
        if (idx < 0 || idx >= song.devices.cap()) {
            return null;
        }
        return song.devices[idx];
    }

    fun void listen(OscEvent e, string cmd)
    {
        while (true) {
            e => now;
            while (e.nextMsg()) {
                dispatch(cmd, e);
            }
        }
    }

    fun void dispatch(string cmd, OscEvent e)
    {
        if (cmd == "device") {
            e.getInt() => int i;
            if (song.selectDevice(i - 1)) {
                song.notifyStateChanged();
            }
        } else if (cmd == "play") {
            e.getInt();
            song.resume();
        } else if (cmd == "pause") {
            e.getInt();
            song.pause();
        } else if (cmd == "restart") {
            e.getInt();
            song.restart();
        } else if (cmd == "nextFragment") {
            e.getString() => string fragName;
            song.queueFragmentByName(fragName);
            song.notifyStateChanged();
        } else if (cmd == "loopFragment") {
            e.getString() => string fragName;
            song.loopFragmentByName(fragName);
            song.notifyStateChanged();
        } else if (cmd == "golden") {
            e.getInt();
            !SongContext.golden => SongContext.golden;
            song.notifyStateChanged();
        } else if (cmd == "allMode") {
            e.getInt();
            !song.allMode => song.allMode;
            song.notifyStateChanged();
        } else if (cmd == "save") {
            e.getInt();
            song.saveConfig();
            <<< "Saved config", "" >>>;
        } else if (cmd == "shutdown") {
            e.getInt();
            song.shutdown();
        } else if (cmd == "volume") {
            e.getInt() => int devIdx;
            e.getInt() => int val;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                p.setVolume(val);
                song.notifyStateChanged();
            }
        } else if (cmd == "cutoff") {
            e.getInt() => int devIdx;
            e.getInt() => int val;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                p.setCutoff(val);
                song.notifyStateChanged();
            }
        } else if (cmd == "resonance") {
            e.getInt() => int devIdx;
            e.getInt() => int val;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                p.setResonance(val);
                song.notifyStateChanged();
            }
        } else if (cmd == "pan") {
            // Pan arrives as -64..63 from the GUI; convert to MIDI 0-127 (64 = center).
            e.getInt() => int devIdx;
            e.getInt() => int val;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                val + 64 => int midiPan;
                p.setPan(midiPan);
                song.notifyStateChanged();
            }
        } else if (cmd == "tempo") {
            e.getInt() => int bpm;
            if (bpm >= 40 && bpm <= 240) {
                song.setBPM(bpm * 1.0);
                song.notifyStateChanged();
            }
        } else if (cmd == "muteDevice") {
            e.getInt() => int devIdx;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                song.toggleMute(p);
                song.notifyStateChanged();
            }
        } else if (cmd == "soloDevice") {
            e.getInt() => int devIdx;
            getDevice(devIdx) @=> Patch @ p;
            if (p != null) {
                if (!song.soloMode) { song.startSoloMode(); }
                song.toggleSoloPatch(p);
                song.notifyStateChanged();
            }
        } else if (cmd == "prevPresetCat") {
            e.getInt();
            if (song.currentDevice != null) {
                song.setPreviousPresetCategory(song.currentDevice.volume);
                song.notifyStateChanged();
            }
        } else if (cmd == "prevPreset") {
            e.getInt();
            if (song.currentDevice != null) {
                song.setPreviousPreset(song.currentDevice.volume);
                song.notifyStateChanged();
            }
        } else if (cmd == "nextPreset") {
            e.getInt();
            if (song.currentDevice != null) {
                song.setNextPreset(song.currentDevice.volume);
                song.notifyStateChanged();
            }
        } else if (cmd == "nextPresetCat") {
            e.getInt();
            if (song.currentDevice != null) {
                song.setNextPresetCategory(song.currentDevice.volume);
                song.notifyStateChanged();
            }
        } else if (cmd == "setPreset") {
            e.getInt() => int devIdx;
            e.getString() => string presetName;
            if (song.selectDevice(devIdx - 1)) {
                song.setPresetByName(presetName, song.currentDevice.volume);
                song.notifyStateChanged();
            }
        } else if (cmd == "setSynth") {
            e.getInt() => int devIdx;
            e.getString() => string synthName;
            song.setDeviceSynth(devIdx, synthName);
        } else if (cmd == "setChannel") {
            e.getInt() => int devIdx;
            e.getInt() => int ch;
            song.setDeviceChannel(devIdx, ch);
        } else if (cmd == "loadPatchSet") {
            e.getString() => string setName;
            song.loadPatchSet(setName);
        } else if (cmd == "setPatchSetName") {
            e.getString() => string curName;
            e.getString() => string defName;
            song.setPatchSetMetadata(curName, defName);
        } else if (cmd == "createPatchSet") {
            e.getString() => string newName;
            e.getString() => string defName;
            song.createAndSavePatchSet(newName, defName);
        }
    }

    fun void oscControlLoop()
    {
        OscRecv recv;
        CadenzaConstants.OSC_CONTROL_PORT() => recv.port;
        recv.listen();

        spork ~ listen(recv.event("/cadenza/device, i"),          "device");
        spork ~ listen(recv.event("/cadenza/golden, i"),          "golden");
        spork ~ listen(recv.event("/cadenza/allMode, i"),         "allMode");
        spork ~ listen(recv.event("/cadenza/save, i"),            "save");
        spork ~ listen(recv.event("/cadenza/shutdown, i"),        "shutdown");
        spork ~ listen(recv.event("/cadenza/volume, ii"),         "volume");
        spork ~ listen(recv.event("/cadenza/cutoff, ii"),         "cutoff");
        spork ~ listen(recv.event("/cadenza/resonance, ii"),      "resonance");
        spork ~ listen(recv.event("/cadenza/pan, ii"),            "pan");
        spork ~ listen(recv.event("/cadenza/tempo, i"),           "tempo");
        spork ~ listen(recv.event("/cadenza/muteDevice, i"),      "muteDevice");
        spork ~ listen(recv.event("/cadenza/soloDevice, i"),      "soloDevice");
        spork ~ listen(recv.event("/cadenza/prevPreset, i"),      "prevPreset");
        spork ~ listen(recv.event("/cadenza/nextPreset, i"),      "nextPreset");
        spork ~ listen(recv.event("/cadenza/prevPresetCat, i"),   "prevPresetCat");
        spork ~ listen(recv.event("/cadenza/nextPresetCat, i"),   "nextPresetCat");
        spork ~ listen(recv.event("/cadenza/setPreset, is"),      "setPreset");
        spork ~ listen(recv.event("/cadenza/setSynth, is"),       "setSynth");
        spork ~ listen(recv.event("/cadenza/setChannel, ii"),     "setChannel");
        spork ~ listen(recv.event("/cadenza/loadPatchSet, s"),    "loadPatchSet");
        spork ~ listen(recv.event("/cadenza/setPatchSetName, ss"),"setPatchSetName");
        spork ~ listen(recv.event("/cadenza/createPatchSet, ss"), "createPatchSet");
        spork ~ listen(recv.event("/cadenza/play, i"),            "play");
        spork ~ listen(recv.event("/cadenza/pause, i"),           "pause");
        spork ~ listen(recv.event("/cadenza/restart, i"),         "restart");
        spork ~ listen(recv.event("/cadenza/nextFragment, s"),    "nextFragment");
        spork ~ listen(recv.event("/cadenza/loopFragment, s"),    "loopFragment");

        while (true) { 1::second => now; }
    }
}
