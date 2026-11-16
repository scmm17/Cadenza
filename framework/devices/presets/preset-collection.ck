// PresetCollection
// Purpose: Shared cursor navigation and preset lookup across synth preset catalogs.
// Imports: framework/devices/presets/preset.ck
// Imported by: framework/devices/presets/generated/*.ck, framework/devices/patch.ck

@import "preset.ck"

public class PresetCollection
{
    Preset @ items[];
    int curPresetIndex;
    string curPresetCategory;
    int preferCurrentCategory;
    int matchCode;

    fun PresetCollection()
    {
        0 => curPresetIndex;
        "" @=> curPresetCategory;
        0 => preferCurrentCategory;
        0 => matchCode;
    }

    fun void initItems(Preset @ list[])
    {
        list @=> items;
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun Preset getNextPreset()
    {
        if (items == null || items.cap() == 0) return null;
        (curPresetIndex + 1) % items.cap() => curPresetIndex;
        items[curPresetIndex] @=> Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun Preset getPreviousPreset()
    {
        if (items == null || items.cap() == 0) return null;
        ((curPresetIndex - 1) + items.cap()) % items.cap() => curPresetIndex;
        items[curPresetIndex] @=> Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun Preset getNextCategory()
    {
        if (items == null || items.cap() == 0) return null;
        for (curPresetIndex + 1 => int i; i < items.cap(); i++) {
            if (items[i].category != curPresetCategory) {
                i => curPresetIndex;
                items[curPresetIndex] @=> Preset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        0 => curPresetIndex;
        items[0] @=> Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun Preset getPreviousCategory()
    {
        if (items == null || items.cap() == 0) return null;
        for (curPresetIndex => int i; i >= 0; i--) {
            if (items[i].category != curPresetCategory) {
                i => curPresetIndex;
                items[curPresetIndex] @=> Preset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        items.cap() - 1 => curPresetIndex;
        items[curPresetIndex] @=> Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun string normalizePresetName(string s)
    {
        s => string copy;
        copy.replace("\"", "'");
        return copy;
    }

    fun int matchesEntry(Preset preset, string presetName, string norm)
    {
        if (preset.name == presetName || preset.name == norm) {
            return true;
        }
        if (matchCode && preset.code == presetName) {
            return true;
        }
        return false;
    }

    fun int hasPreset(string presetName)
    {
        if (presetName == "" || items == null) return false;
        normalizePresetName(presetName) => string norm;
        for (Preset preset : items) {
            if (matchesEntry(preset, presetName, norm)) {
                return true;
            }
        }
        return false;
    }

    fun int matchesPreset(string presetName, int b, int p)
    {
        if (presetName == "" || b < 0 || p < 0 || items == null) return false;
        normalizePresetName(presetName) => string norm;
        for (Preset preset : items) {
            if (matchesEntry(preset, presetName, norm) && preset.bank == b && preset.program == p) {
                return true;
            }
        }
        return false;
    }

    fun Preset getPreset(string presetName)
    {
        if (items == null || items.cap() == 0) return null;
        normalizePresetName(presetName) => string norm;
        if (preferCurrentCategory && curPresetCategory != "") {
            for (Preset preset : items) {
                if (preset.category == curPresetCategory && matchesEntry(preset, presetName, norm)) {
                    return preset;
                }
            }
        }
        for (Preset preset : items) {
            if (matchesEntry(preset, presetName, norm)) {
                return preset;
            }
        }
        <<< "Can't find preset: ", presetName >>>;
        return items[0];
    }

    fun Preset getPreset(int b, int p)
    {
        if (items == null) return null;
        for (Preset preset : items) {
            if (preset.bank == b && preset.program == p) {
                return preset;
            }
        }
        return null;
    }

    fun void setPresetState(string presetName)
    {
        if (items == null || items.cap() == 0) {
            0 => curPresetIndex;
            "" @=> curPresetCategory;
            return;
        }
        normalizePresetName(presetName) => string norm;
        if (preferCurrentCategory && curPresetCategory != "") {
            for (0 => int i; i < items.cap(); i++) {
                if (items[i].category == curPresetCategory && matchesEntry(items[i], presetName, norm)) {
                    i => curPresetIndex;
                    items[curPresetIndex].category @=> curPresetCategory;
                    return;
                }
            }
        }
        for (0 => int i; i < items.cap(); i++) {
            if (matchesEntry(items[i], presetName, norm)) {
                i => curPresetIndex;
                items[curPresetIndex].category @=> curPresetCategory;
                return;
            }
        }
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun void setPresetState(string presetName, int b, int p)
    {
        if (b >= 0 && p >= 0 && items != null) {
            for (0 => int i; i < items.cap(); i++) {
                if (items[i].bank == b && items[i].program == p) {
                    i => curPresetIndex;
                    items[curPresetIndex].category @=> curPresetCategory;
                    return;
                }
            }
        }
        setPresetState(presetName);
    }
}
