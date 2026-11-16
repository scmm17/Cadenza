// Mixer
// Purpose: Manages explicit mute list, solo patch, and effective device mute state calculation.
// Imports: framework/devices/patch.ck
// Imported by: framework/song/song.ck

@import "../devices/patch.ck"

public class Mixer
{
    Patch @ soloPatch;
    Patch @ mutedPatches[];

    fun Mixer()
    {
        Patch empty[0];
        empty @=> mutedPatches;
        null @=> soloPatch;
    }

    fun void updateEffectiveMuteStates(Patch @ devices[])
    {
        if (devices == null) return;
        for (Patch p : devices) {
            if (p != null) {
                p.muted => int wasMuted;
                if (soloPatch != null) {
                    if (p == soloPatch) {
                        false => p.muted;
                    } else {
                        true => p.muted;
                    }
                } else {
                    p.userMuted => p.muted;
                }
                if (!wasMuted && p.muted) {
                    p.sendAllNotesOff();
                }
            }
        }
    }

    fun void mutePatch(Patch @ patch, Patch @ devices[])
    {
        true => patch.userMuted;
        mutedPatches << patch;
        updateEffectiveMuteStates(devices);
    }

    fun void unMutePatch(Patch @ patch, Patch @ devices[])
    {
        false => patch.userMuted;
        for (0 => int i; i < mutedPatches.cap(); i++) {
            if (mutedPatches[i] == patch) {
                mutedPatches.erase(i);
                break;
            }
        }
        updateEffectiveMuteStates(devices);
    }

    fun void toggleMute(Patch @ patch, Patch @ devices[])
    {
        if (patch.userMuted) {
            unMutePatch(patch, devices);
        } else {
            mutePatch(patch, devices);
        }
    }

    fun void clearAllMutes(Patch @ devices[])
    {
        for (Patch p : mutedPatches) {
            false => p.userMuted;
        }
        mutedPatches.clear();
        updateEffectiveMuteStates(devices);
    }

    fun void setSoloPatch(Patch @ patch, Patch @ devices[])
    {
        <<< "Setting solo patch:", patch.deviceName >>>;
        patch @=> soloPatch;
        updateEffectiveMuteStates(devices);
    }

    fun void unsetSoloPatch(Patch @ devices[])
    {
        if (soloPatch != null) {
            <<< "Unsetting solo patch:", soloPatch.deviceName >>>;
            null @=> soloPatch;
        }
        updateEffectiveMuteStates(devices);
    }

    fun void toggleSoloPatch(Patch @ patch, Patch @ devices[])
    {
        <<< "Toggling solo patch:", patch.deviceName >>>;
        soloPatch @=> Patch originalSoloPatch;
        if (soloPatch != null) {
            unsetSoloPatch(devices);
        }
        if (originalSoloPatch != patch) {
            setSoloPatch(patch, devices);
        }
    }

    fun void replacePatchReference(Patch @ oldPatch, Patch @ newPatch)
    {
        if (soloPatch == oldPatch) {
            newPatch @=> soloPatch;
        }
        for (0 => int m; m < mutedPatches.cap(); m++) {
            if (mutedPatches[m] == oldPatch) {
                newPatch @=> mutedPatches[m];
            }
        }
    }
}
