// Song
// Purpose: Top-level composition orchestrator wiring transport, Mixer, PatchSetStore, and hardware/GUI controllers.
// Imports: core/*, devices/*, composition/*, song/*, control/*
// Imported by: framework/cadenza.ck

@import "../core/constants.ck"
@import "../core/gui-link.ck"
@import "../core/yaml.ck"
@import "../devices/synth-registry.ck"
@import "../composition/song-context.ck"
@import "../composition/part.ck"
@import "../composition/fragment.ck"
@import "mixer.ck"
@import "patch-set-store.ck"
@import "../control/midi-mapper.ck"
@import "../control/terminal-display.ck"
@import "../control/state-broadcaster.ck"
@import "../control/launch-control.ck"
@import "../control/keyboard-control.ck"
@import "../control/osc-control.ck"

public class Song extends SongState
{
    Event pauseEvent;
    Event resumeEvent;

    // Active playback shreds (always access qualified as Song.shreds / Song.oldShreds)
    static Shred shreds[];
    static Shred oldShreds[];

    Mixer mixer;
    PatchSetStore @ patchSetStore;
    MidiMapper @ midiThru;
    LaunchControl @ launchControl;
    TerminalDisplay terminalDisplay;
    StateBroadcaster stateBroadcaster;
    KeyboardControl keyboardControl;
    OscControl @ oscControl;
    int liveUiEnabled;

    fun Song(string songName, float bpm, int root, Fragment startFrag, Part allParts[])
    {
        songName => name;
        "Default" => currentPatchSet;
        "Default" => defaultPatchSet;
        setBPM(bpm);
        root => rootNote;
        allParts @=> parts;
        startFrag @=> startFragment;
        startFrag @=> currentFragment;
        null @=> queuedFragment;
        null @=> loopFragment;
        false => SongContext.debug;
        false => SongContext.shuttingDown;
        false => SongContext.golden;
        false => muteMode;
        true => soloMode;
        false => allMode;
        1 => SongContext.isPaused;
        0 => restartRequested;
        1 => liveUiEnabled;

        Shred emptyShreds[0];
        emptyShreds @=> shreds;
        Shred emptyOldShreds[0];
        emptyOldShreds @=> oldShreds;

        initDevicesFromParts();
        startFrag.parts @=> currentParts;

        new PatchSetStore(this) @=> patchSetStore;
        new MidiMapper("HYDRASYNTH EXPLORER", "U2MIDI Pro", 1) @=> midiThru;
        new LaunchControl(this) @=> launchControl;
        new OscControl(this) @=> oscControl;

        patchSetStore.loadConfig();

        spork ~ midiThru.startEventLoop();
        spork ~ launchControl.startEventLoop();
        spork ~ keyboardControl.keyboardLoop(this);
        spork ~ oscControl.oscControlLoop();

        notifyStateChanged();
    }

    fun void initDevicesFromParts()
    {
        parts[0].patch @=> currentDevice;
        for (Part part : parts) {
            part.patch @=> Patch patch;
            for (0 => int j; j < devices.cap(); j++) {
                if (devices[j] == null) {
                    patch @=> devices[j];
                    (j + 1) => patch.devIndex;
                    break;
                }
                if (patch.deviceName == devices[j].deviceName &&
                    patch.midiChannel == devices[j].midiChannel) {
                    devices[j] @=> part.patch;
                    (j + 1) => patch.devIndex;
                    break;
                }
            }
        }
        for (0 => int i; i < devices.cap(); i++) {
            if (devices[i] != null) {
                (i + 1) => devices[i].devIndex;
                devices[i].syncPresetCursor();
            }
        }
    }

    fun void notifyStateChanged()
    {
        if (!liveUiEnabled) return;
        terminalDisplay.printDevices(this);
        terminalDisplay.writeDashboardMarkdown(this);
        stateBroadcaster.broadcastState(this);
    }

    // ── Patch-set persistence delegates ──────────────────────────────────────
    fun void loadConfig() { if (patchSetStore != null) patchSetStore.loadConfig(); }
    fun void saveConfig() { if (patchSetStore != null) patchSetStore.saveConfig(); }
    fun void createAndSavePatchSet(string newName, string defName) { if (patchSetStore != null) patchSetStore.createAndSavePatchSet(newName, defName); }
    fun void loadPatchSet(string setName) { if (patchSetStore != null) patchSetStore.loadPatchSet(setName); }
    fun void setPatchSetMetadata(string curName, string defName) { if (patchSetStore != null) patchSetStore.setPatchSetMetadata(curName, defName); }

    // ── Device registry & switching ──────────────────────────────────────────
    fun Patch createEmptyPatchForSynth(string synthUiName) { return SynthRegistry.createEmpty(synthUiName); }
    fun Patch createDefaultPatchForSynth(string synthUiName, int midiChan, int vol) { return SynthRegistry.createDefault(synthUiName, midiChan, vol); }
    fun int findFirstUnusedMidiChannel(int excludeIdx, string synthUiName, int maxChannels) { return SynthRegistry.findFirstUnusedChannel(devices, excludeIdx, synthUiName, maxChannels); }
    fun int resolveMidiChannelForSynth(int idx, string synthUiName) { return SynthRegistry.resolveMidiChannel(devices, idx, synthUiName); }

    fun void setMidiThruChannel(int ch)
    {
        if (midiThru != null) {
            ch => midiThru.outputChannel;
        }
    }

    fun int selectDevice(int idx)
    {
        if (idx < 0 || idx >= devices.cap() || devices[idx] == null) {
            return 0;
        }
        devices[idx] @=> currentDevice;
        setMidiThruChannel(currentDevice.midiChannel);
        currentDevice.syncPresetCursor();
        return 1;
    }

    fun void replacePatchInParts(Part @ list[], Patch @ oldPatch, Patch @ newPatch, int devIdx1Based)
    {
        if (list == null) return;
        for (Part part : list) {
            if (part != null && (part.patch == oldPatch || (part.patch != null && part.patch.devIndex == devIdx1Based))) {
                newPatch @=> part.patch;
            }
        }
    }

    fun void replaceDevice(int idx, Patch @ newPatch)
    {
        if (idx < 0 || idx >= devices.cap() || newPatch == null) return;
        devices[idx] @=> Patch @ oldPatch;
        (idx + 1) => newPatch.devIndex;
        newPatch @=> devices[idx];

        if (currentDevice == oldPatch) {
            newPatch @=> currentDevice;
            setMidiThruChannel(newPatch.midiChannel);
        }

        mixer.replacePatchReference(oldPatch, newPatch);
        replacePatchInParts(parts, oldPatch, newPatch, idx + 1);
        replacePatchInParts(currentParts, oldPatch, newPatch, idx + 1);

        Fragment.collectReachable(startFragment) @=> Fragment @ reachable[];
        for (Fragment f : reachable) {
            replacePatchInParts(f.parts, oldPatch, newPatch, idx + 1);
        }
    }

    fun void setDeviceSynth(int devIdx, string synthUiName)
    {
        devIdx - 1 => int idx;
        if (idx < 0 || idx >= devices.cap() || devices[idx] == null) return;
        devices[idx] @=> Patch @ oldPatch;
        if (oldPatch.uiName == synthUiName) {
            selectDevice(idx);
            notifyStateChanged();
            return;
        }
        resolveMidiChannelForSynth(idx, synthUiName) => int targetMidiChannel;
        if (targetMidiChannel < 0) {
            0 => targetMidiChannel;
        }
        null @=> Patch @ sharedPatch;
        for (0 => int i; i < devices.cap(); i++) {
            if (i != idx && devices[i] != null && devices[i].uiName == synthUiName && devices[i].midiChannel == targetMidiChannel) {
                devices[i] @=> sharedPatch;
                break;
            }
        }
        oldPatch.sendAllNotesOff();
        createDefaultPatchForSynth(synthUiName, targetMidiChannel, oldPatch.volume) @=> Patch @ newPatch;
        if (newPatch == null) return;
        targetMidiChannel => newPatch.midiChannel;
        oldPatch.volume => newPatch.volume;
        oldPatch.filterCutoff => newPatch.filterCutoff;
        oldPatch.filterResonance => newPatch.filterResonance;
        oldPatch.pan => newPatch.pan;
        oldPatch.userMuted => newPatch.userMuted;
        oldPatch.muted => newPatch.muted;
        if (sharedPatch != null && sharedPatch.patchName != "") {
            newPatch.selectPresetByName(sharedPatch.patchName, newPatch.volume);
        }
        replaceDevice(idx, newPatch);
        selectDevice(idx);
        newPatch.updateControllers();
        notifyStateChanged();
    }

    fun void setDeviceChannel(int devIdx, int channel)
    {
        devIdx - 1 => int idx;
        if (idx < 0 || idx >= devices.cap() || devices[idx] == null) return;
        if (channel < 1) { 1 => channel; }
        if (channel > 16) { 16 => channel; }
        channel - 1 => int newMidiChannel;
        devices[idx] @=> Patch @ p;
        if (p.midiChannel == newMidiChannel) {
            selectDevice(idx);
            notifyStateChanged();
            return;
        }
        p.sendAllNotesOff();
        newMidiChannel => p.midiChannel;
        p.onChannelChanged(channel);
        selectDevice(idx);
        p.updateControllers();
        notifyStateChanged();
    }

    // ── Transport & fragment scheduling ──────────────────────────────────────
    fun void pause()
    {
        1 => SongContext.isPaused;
        for (0 => int i; i < devices.cap(); i++) {
            if (devices[i] != null) {
                devices[i].sendAllNotesOff();
            }
        }
        pauseEvent.broadcast();
        notifyStateChanged();
    }

    fun void resume()
    {
        0 => SongContext.isPaused;
        resumeEvent.broadcast();
        notifyStateChanged();
    }

    fun void advance(dur d)
    {
        now + d => time target;
        while (now < target) {
            if (restartRequested) break;

            target - now => dur remain;

            if (SongContext.isPaused) {
                resumeEvent => now;
                if (restartRequested) break;
                now + remain => target;
                target - now => remain;
            }

            if (remain <= 0::samp) break;

            if (remain > 20::ms) {
                20::ms => now;
            } else {
                remain => now;
            }
        }
    }

    fun void restart()
    {
        1 => restartRequested;
        null @=> queuedFragment;
        null @=> loopFragment;
        if (startFragment != null) {
            startFragment @=> currentFragment;
            1 => startFragment.currentRepeat;
        }
        pause();
        if (shreds != null) {
            for (0 => int i; i < shreds.cap(); i++) {
                if (shreds[i] != null) shreds[i].exit();
            }
        }
        if (oldShreds != null) {
            for (0 => int i; i < oldShreds.cap(); i++) {
                if (oldShreds[i] != null) oldShreds[i].exit();
            }
        }
        resumeEvent.broadcast();
    }

    fun Fragment findFragmentByName(string fragName)
    {
        if (startFragment == null || fragName == "") return null;
        Fragment.collectReachable(startFragment) @=> Fragment @ queue[];
        for (Fragment f : queue) {
            if (f.name == fragName) {
                return f;
            }
        }
        return null;
    }

    fun void queueFragmentByName(string fragName)
    {
        if (fragName == "") {
            null @=> queuedFragment;
            return;
        }
        findFragmentByName(fragName) @=> Fragment f;
        if (f != null) {
            f @=> queuedFragment;
        }
    }

    fun void loopFragmentByName(string fragName)
    {
        if (fragName == "") {
            null @=> loopFragment;
            return;
        }
        findFragmentByName(fragName) @=> Fragment f;
        if (f == null) return;
        if (loopFragment == f) {
            null @=> loopFragment;
        } else {
            f @=> loopFragment;
            null @=> queuedFragment;
        }
    }

    fun void shutdown()
    {
        <<< "Shutting Down" >>>;
        CadenzaConstants.LC_SELECT_BASE() => int selBase;
        CadenzaConstants.LC_MUTE_BASE() => int muteBase;
        CadenzaConstants.LC_LED_GREEN() => int green;
        CadenzaConstants.LC_LED_RED() => int red;

        if (launchControl != null) {
            launchControl.setActiveSelectionLED(0, selBase, 0, green);
        }
        if (soloMode) {
            toggleSoloMode(CadenzaConstants.LC_SOLO_MODE());
        }
        if (muteMode) {
            toggleMuteMode(CadenzaConstants.LC_MUTE_MODE());
        }
        if (launchControl != null) {
            launchControl.setActiveMutedLED(0, muteBase, red);
            launchControl.setLED(0, CadenzaConstants.LC_MUTE_MODE(), green, false);
            launchControl.setLED(0, CadenzaConstants.LC_SOLO_MODE(), green, false);
        }
        for (Patch device : devices) {
            if (device != null) {
                device.sendAllNotesOff();
            }
        }

        if (SongContext.debug) {
            <<< "Stopping shreds" >>>;
        }
        if (shreds != null) {
            for (Shred shred : shreds) {
                if (shred != null) shred.exit();
            }
        }
        if (oldShreds != null) {
            for (Shred shred : oldShreds) {
                if (shred != null) shred.exit();
            }
        }
        true => SongContext.shuttingDown;
        me.exit();
    }

    // ── Preset delegates ─────────────────────────────────────────────────────
    fun void syncSharedPatchMetadata(Patch @ source)
    {
        if (source == null) return;
        for (0 => int i; i < devices.cap(); i++) {
            devices[i] @=> Patch @ other;
            if (other != null && other != source
                && other.uiName == source.uiName
                && other.midiChannel == source.midiChannel) {
                other.copyPresetMetadataFrom(source);
            }
        }
    }

    fun void applyMoogPreset(int b, int p, int volume)
    {
        if (currentDevice == null || currentDevice.uiName != "Moog") return;
        currentDevice $ MoogMessenger @=> MoogMessenger @ moog;
        moog.applyBankProgram(b, p, volume);
        syncSharedPatchMetadata(currentDevice);
    }

    fun setNextPreset(int volume)
    {
        if (currentDevice != null) {
            currentDevice.stepPreset(1, volume);
            syncSharedPatchMetadata(currentDevice);
        }
    }

    fun setNextPresetCategory(int volume)
    {
        if (currentDevice != null) {
            currentDevice.stepPresetCategory(1, volume);
            syncSharedPatchMetadata(currentDevice);
        }
    }

    fun setPreviousPreset(int volume)
    {
        if (currentDevice != null) {
            currentDevice.stepPreset(-1, volume);
            syncSharedPatchMetadata(currentDevice);
        }
    }

    fun setPreviousPresetCategory(int volume)
    {
        if (currentDevice != null) {
            currentDevice.stepPresetCategory(-1, volume);
            syncSharedPatchMetadata(currentDevice);
        }
    }

    fun void setPresetByName(string presetName, int volume)
    {
        if (currentDevice == null) return;
        if (!currentDevice.selectPresetByName(presetName, volume)) {
            currentDevice.refreshSiblingPresets(devices);
        }
        syncSharedPatchMetadata(currentDevice);
    }

    // ── Mixer delegates ──────────────────────────────────────────────────────
    fun void updateEffectiveMuteStates() { mixer.updateEffectiveMuteStates(devices); }
    fun void startMuteMode() { true => muteMode; }
    fun void endMuteMode() { false => muteMode; mixer.clearAllMutes(devices); }
    fun void mutePatch(Patch patch) { mixer.mutePatch(patch, devices); }
    fun void unMutePatch(Patch patch) { mixer.unMutePatch(patch, devices); }
    fun void startSoloMode() { true => soloMode; }
    fun void endSoloMode() { false => soloMode; mixer.unsetSoloPatch(devices); }
    fun void setSoloPatch(Patch patch) { mixer.setSoloPatch(patch, devices); }
    fun void unsetSoloPatch() { mixer.unsetSoloPatch(devices); }
    fun void toggleMute(Patch patch) { mixer.toggleMute(patch, devices); }
    fun void toggleSoloPatch(Patch patch) { mixer.toggleSoloPatch(patch, devices); }
    fun int isPatchSoloed(Patch p) { return mixer.soloPatch == p; }
    fun int mutedPatchCount() { return mixer.mutedPatches.cap(); }

    fun void toggleMuteMode(int note)
    {
        if (soloMode) {
            endSoloMode();
        }
        if (muteMode) {
            endMuteMode();
        } else {
            startMuteMode();
        }
    }

    fun void toggleSoloMode(int note)
    {
        if (muteMode) {
            endMuteMode();
        }
        if (soloMode) {
            endSoloMode();
        } else {
            startSoloMode();
        }
    }

    // ── Playback loop ────────────────────────────────────────────────────────
    fun void play()
    {
        while (true) {
            while (SongContext.isPaused) {
                resumeEvent => now;
            }
            0 => restartRequested;
            if (startFragment != null) {
                for (startFragment @=> Fragment frag;
                     frag != null;
                     playFragment(frag) @=> frag) {
                    while (SongContext.isPaused) {
                        resumeEvent => now;
                        if (restartRequested) break;
                    }
                    if (restartRequested) break;
                    frag @=> currentFragment;
                }
            } else if (parts != null) {
                while (SongContext.isPaused) {
                    resumeEvent => now;
                    if (restartRequested) break;
                }
                if (!restartRequested) {
                    playParts();
                }
            }
            if (!restartRequested) break;
        }
        pause();
    }

    fun void playPartOnce()
    {
        if (currentParts != null) {
            playParts();
        }
    }

    fun Fragment playFragment(Fragment frag)
    {
        return frag.play(this);
    }

    fun int containsPart(Part part)
    {
        if (currentParts == null) {
            return true;
        }
        for (Part currentPart : currentParts) {
            if (currentPart == part) {
                return true;
            }
        }
        return false;
    }

    fun void playParts()
    {
        0::second => dur total;
        Shred myShreds[parts.cap()];
        myShreds @=> shreds;
        0 => int partIndex;
        0 => int maxBars;
        for (Part part : parts) {
            if (!allMode && !containsPart(part)) {
                continue;
            }
            if (part.numberOfMeasures > maxBars) {
                part.numberOfMeasures => maxBars;
            }
            if (part.totalDuration(this) > total) {
                part.totalDuration(this) => total;
            }
        }
        Patch @ syncedPatches[0];
        for (Part part : parts) {
            if (!allMode && !containsPart(part)) {
                partIndex++;
                continue;
            }
            if (part.patch != null) {
                false => int alreadySynced;
                for (0 => int s; s < syncedPatches.cap(); s++) {
                    if (syncedPatches[s] == part.patch) {
                        true => alreadySynced;
                        break;
                    }
                }
                if (!alreadySynced) {
                    syncedPatches << part.patch;
                    part.patch.onFragmentStart();
                }
            }
            spork ~ playPart(part, maxBars) @=> shreds[partIndex];
            partIndex++;
        }
        if (forever) {
            while (true) {
                advance(5::second);
                if (restartRequested) break;
            }
        } else {
            advance(total);
            if (SongContext.shuttingDown) {
                <<< "Exiting" >>>;
                me.exit();
            }
            for (Shred shred : oldShreds) {
                if (shred != null) {
                    shred.exit();
                }
            }
            shreds @=> oldShreds;
        }
    }

    fun void waitIfPaused()
    {
        while (SongContext.isPaused) {
            resumeEvent => now;
            if (restartRequested) return;
        }
    }

    fun void playPart(Part part, int maxBars)
    {
        waitIfPaused();
        if (restartRequested) return;
        for (0 => int i; i < maxBars / part.numberOfMeasures; i++) {
            part.play(this);
        }
    }
}
