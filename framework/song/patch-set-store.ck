// PatchSetStore
// Purpose: Loads and saves song/device YAML patch-set configs and .default metadata.
// Imports: framework/core/yaml.ck, framework/devices/patch.ck, framework/devices/synth-registry.ck, framework/composition/fragment.ck
// Imported by: framework/song/song.ck

@import "../core/yaml.ck"
@import "../devices/patch.ck"
@import "../devices/synth-registry.ck"
@import "../composition/fragment.ck"

public class PatchSetStore
{
    SongState @ song;
    YamlNode @ config;

    fun PatchSetStore(SongState @ s)
    {
        s @=> song;
    }

    fun string getPatchSetDir()
    {
        return "music/" + song.name + ".patch-sets";
    }

    fun string getPatchSetFile(string setName)
    {
        return getPatchSetDir() + "/" + setName + ".yaml";
    }

    fun void readDefaultPatchSetMeta()
    {
        getPatchSetDir() + "/.default" => string defaultMetaFile;
        FileIO df;
        df.open(defaultMetaFile, FileIO.READ);
        if (df.good()) {
            while (df.more()) {
                YamlNode.trimLeft(YamlNode.trimRight(df.readLine())) => string line;
                if (line != "") {
                    line => song.defaultPatchSet;
                    break;
                }
            }
            df.close();
        } else {
            df.close();
            if (song.defaultPatchSet == "") {
                "Default" => song.defaultPatchSet;
            }
        }
    }

    fun void loadConfig()
    {
        readDefaultPatchSetMeta();
        song.defaultPatchSet => song.currentPatchSet;
        getPatchSetFile(song.currentPatchSet) => string patchSetFile;
        "music/" + song.name + ".yaml" => string legacyFile;

        FileIO f;
        f.open(patchSetFile, FileIO.READ);
        if (f.good()) {
            f.close();
            <<< "configFile:", patchSetFile >>>;
            YamlNode.ParseFile(patchSetFile) @=> config;
            loadSongConfig();
            loadDeviceConfigs();
            return;
        }
        f.close();

        f.open(legacyFile, FileIO.READ);
        if (f.good()) {
            f.close();
            <<< "configFile (legacy):", legacyFile >>>;
            YamlNode.ParseFile(legacyFile) @=> config;
            loadSongConfig();
            loadDeviceConfigs();
            saveConfig();
            return;
        }
        f.close();

        new YamlNode("song") @=> config;
        YamlNode emptyRoot[0];
        config.SetMap(emptyRoot);
        saveSongConfig();
        saveDeviceConfigs();
        saveConfig();
    }

    fun void saveConfig()
    {
        if (song.currentPatchSet == "") { "Default" => song.currentPatchSet; }
        getPatchSetFile(song.currentPatchSet) => string patchSetFile;
        new YamlNode("song") @=> config;
        YamlNode emptyRoot[0];
        config.SetMap(emptyRoot);
        saveDeviceConfigs();
        saveSongConfig();
        FileIO testWrite;
        testWrite.open(patchSetFile, FileIO.WRITE);
        if (testWrite.good()) {
            testWrite.close();
            config.WriteFile(patchSetFile);
        } else {
            testWrite.close();
            "music/" + song.name + ".yaml" => string legacyFile;
            config.WriteFile(legacyFile);
        }
    }

    fun void createAndSavePatchSet(string newName, string defName)
    {
        if (newName != "") { newName => song.currentPatchSet; }
        if (defName != "") { defName => song.defaultPatchSet; }
        saveConfig();
        song.notifyStateChanged();
    }

    fun void loadPatchSet(string setName)
    {
        if (setName == "") return;
        readDefaultPatchSetMeta();
        getPatchSetFile(setName) => string patchSetFile;
        FileIO f;
        f.open(patchSetFile, FileIO.READ);
        if (!f.good()) {
            f.close();
            <<< "Patch set file not found:", patchSetFile >>>;
            return;
        }
        f.close();
        for (0 => int i; i < song.devices.cap(); i++) {
            if (song.devices[i] != null) {
                song.devices[i].sendAllNotesOff();
            }
        }
        setName => song.currentPatchSet;
        YamlNode.ParseFile(patchSetFile) @=> config;
        loadSongConfig();
        loadDeviceConfigs();
        song.updateEffectiveMuteStates();
        song.notifyStateChanged();
    }

    fun void setPatchSetMetadata(string curName, string defName)
    {
        if (curName != "") { curName => song.currentPatchSet; }
        if (defName != "") { defName => song.defaultPatchSet; }
        song.notifyStateChanged();
    }

    fun void saveDeviceConfigs()
    {
        config.SetMap("devices") @=> YamlNode deviceSettings;
        YamlNode empty[0];
        deviceSettings.SetMap(empty);
        for (0 => int i; i < song.devices.cap(); i++) {
            song.devices[i] @=> Patch p;
            if (p != null) {
                p.uiName + "-" + Std.itoa(p.midiChannel) => string propName;
                if (deviceSettings.findChild(propName) >= 0) {
                    propName + "-dev" + Std.itoa(i + 1) => propName;
                }
                deviceSettings.SetMap(propName) @=> YamlNode patchConfig;
                YamlNode emptyPatch[0];
                patchConfig.SetMap(emptyPatch);
                p.saveConfig(patchConfig);
            }
        }
    }

    fun void loadDeviceConfigs()
    {
        config.GetMap("devices") @=> YamlNode deviceSettings;
        if (deviceSettings == null) return;

        0 => int numDevices;
        for (0 => int i; i < song.devices.cap(); i++) {
            if (song.devices[i] != null) {
                numDevices++;
            }
        }
        deviceSettings.arrayValue.cap() => int numSaved;
        int claimed[numSaved];
        for (0 => int k; k < numSaved; k++) { 0 => claimed[k]; }

        for (0 => int i; i < song.devices.cap(); i++) {
            song.devices[i] @=> Patch p;
            if (p != null) {
                null @=> YamlNode @ patchConfig;
                if (numSaved == numDevices && i < numSaved) {
                    deviceSettings.arrayValue[i] @=> patchConfig;
                    1 => claimed[i];
                } else {
                    p.uiName + "-" + Std.itoa(p.midiChannel) => string propName;
                    deviceSettings.findChild(propName) => int childIdx;
                    if (childIdx >= 0 && !claimed[childIdx]) {
                        deviceSettings.arrayValue[childIdx] @=> patchConfig;
                        1 => claimed[childIdx];
                    } else if (i < numSaved && !claimed[i]) {
                        deviceSettings.arrayValue[i] @=> patchConfig;
                        1 => claimed[i];
                    }
                }
                if (patchConfig != null) {
                    "" => string targetUiName;
                    if (patchConfig.findChild("uiName") >= 0) {
                        patchConfig.GetString("uiName") => targetUiName;
                    }
                    if (targetUiName != "" && targetUiName != p.uiName) {
                        SynthRegistry.createEmpty(targetUiName) @=> Patch @ newPatch;
                        if (newPatch != null) {
                            song.replaceDevice(i, newPatch);
                            newPatch @=> p;
                        }
                    }
                    p.loadConfig(patchConfig);
                    if (song.currentDevice == p) {
                        song.setMidiThruChannel(p.midiChannel);
                    }
                } else {
                    p.uiName + "-" + Std.itoa(p.midiChannel) => string propName;
                    <<< "Warning: Config for patch ", propName, " not found in YAML." >>>;
                }
                p.syncPresetCursor();
            }
        }
        for (Patch p : song.devices) {
            if (p != null) {
                p.reapplyLoadedPreset();
            }
        }
    }

    fun void saveSongConfig()
    {
        config.SetFloat("bpm", song.BPM);
    }

    fun void loadSongConfig()
    {
        config.GetFloat("bpm") => float savedBpm;
        if (savedBpm > 0.0) {
            song.setBPM(savedBpm);
        }
    }
}
