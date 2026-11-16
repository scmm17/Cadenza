// TerminalDisplay
// Purpose: Renders the ANSI console device table and writes dashboard.md during live sessions.
// Imports: framework/composition/fragment.ck, framework/devices/patch.ck
// Imported by: framework/song/song.ck

@import "../composition/fragment.ck"
@import "../devices/patch.ck"

public class TerminalDisplay
{
    fun string padString(int len)
    {
        "" => string s;
        for (0 => int i; i < len; i++) {
            s + " " => s;
        }
        return s;
    }

    fun int isActiveDevice(SongState @ song, Patch @ p)
    {
        return p == song.currentDevice;
    }

    fun int isPlaying(SongState @ song, Patch @ p)
    {
        if (song.currentParts == null) return false;
        for (Part currentPart : song.currentParts) {
            if (currentPart != null && currentPart.patch == p) {
                return true;
            }
        }
        return false;
    }

    fun void printDevices(SongState @ song)
    {
        <<< "\033c", "" >>>;
        0 => int maxLength;
        for (Patch patch : song.devices) {
            if (patch != null) {
                if (patch.patchName.length() + patch.uiName.length() > maxLength) {
                    patch.patchName.length() + patch.uiName.length() => maxLength;
                }
            }
        }
        0 => int deviceNum;
        for (Patch patch : song.devices) {
            if (patch != null) {
                " " => string pad;
                " " => string prefix;
                if (isActiveDevice(song, patch)) {
                    "*" => prefix;
                }
                if (isPlaying(song, patch)) {
                    "X" => pad;
                }
                patch.patchName => string name;
                "| " + patch.uiName + ":" => string n;
                <<< prefix, pad, "Device:", deviceNum + 1, n, name, padString(maxLength - (name.length() + patch.uiName.length())), "| Volume:", patch.volume >>>;
            }
            deviceNum++;
        }

        "" => string fragName;
        if (song.currentFragment != null) {
            song.currentFragment.name => fragName;
        }
        <<< "Fragment: " + fragName + ", Mute Mode: " + song.muteMode + ", Solo Mode: " + song.soloMode + ", Muted Patches: " + song.mutedPatchCount() + ", Golden: " + SongContext.golden + ", All Mode: " + song.allMode, "" >>>;
    }

    fun void writeDashboardMarkdown(SongState @ song)
    {
        "dashboard.md" => string filename;
        FileIO fout;
        fout.open(filename, FileIO.WRITE);
        if (!fout.good()) {
            fout.close();
            return;
        }
        fout.write("| Status | Device | Synth | Channel | Patch | Vol | Cutoff | Res | Pan |\n");
        fout.write("| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |\n");

        0 => int deviceNum;
        for (Patch patch : song.devices) {
            if (patch != null) {
                " " => string pad;
                " " => string prefix;
                " " => string muteString;
                if (isActiveDevice(song, patch)) {
                    " 👁️" => prefix;
                }
                if (isPlaying(song, patch)) {
                    " ☑️" => pad;
                }
                if (patch.muted) {
                    " ❌" => muteString;
                }
                patch.patchName => string name;
                patch.uiName => string ui;
                "| " + prefix + pad + muteString + " | " + Std.itoa(deviceNum + 1) + " | " + ui + " | " + Std.itoa(patch.midiChannel + 1) + " | " + name + " | " + patch.volume + " | " + patch.filterCutoff + " | " + patch.filterResonance + " | " + (patch.pan - 64) + " |\n" => string line;
                fout.write(line);
            }
            deviceNum++;
        }
        "" => string fragName;
        if (song.currentFragment != null) {
            song.currentFragment.name => fragName;
        }
        fout.write("\n");
        fout.write("| Song | Fragment | Mute Mode | Solo Mode | Golden | All |\n");
        fout.write("| :---: | :---: | :---: | :---: | :---: | :---: |\n");
        "| " + song.name + " | " + fragName + " | " + (song.muteMode ? "☑️" : "❌") + " | " + (song.soloMode ? "☑️" : "❌") + " | " + (SongContext.golden ? "☑️" : "❌") + " | " + (song.allMode ? "☑️" : "❌") + " |\n" => string statusLine;
        fout.write(statusLine);
        fout.close();
    }
}
