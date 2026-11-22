// GENERATED from presets/catalog.json — do not edit manually.
// Purpose: Auto-generated ArturiaSynth subclasses and ArturiaExtraRegistry.
// Regenerate with: node tools/gen-presets.js

@import "../arturia-synth.ck"
@import "../presets/generated/arturia-extra-presets.ck"

public class AnalogLabV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Analog Lab V", "Analog Lab V", 0, "Classic Jun Keys", 7, "AnalogLabV", "analogLabV");
    }

    fun AnalogLabV()
    {
        initDefaults();
        resolvePreset("Classic Jun Keys");
    }

    fun AnalogLabV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AnalogLabV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AnalogLabVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class ARP2600V3 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver ARP 2600 V3", "ARP 2600 V3", 0, "Sync Seq", 7, "ARP2600V3", "aRP2600V3");
    }

    fun ARP2600V3()
    {
        initDefaults();
        resolvePreset("Sync Seq");
    }

    fun ARP2600V3(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun ARP2600V3(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new ARP2600V3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class AugmentedVoices extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Augmented Voices", "Augmented Voices", 0, "Voices Trailer", 17, "AugmentedVoices", "augmentedVoices");
    }

    fun AugmentedVoices()
    {
        initDefaults();
        resolvePreset("Voices Trailer");
    }

    fun AugmentedVoices(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedVoices(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AugmentedVoicesPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class AugmentedWoodwinds extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Augmented Woodwinds", "Augmented Woodwinds", 0, "Andromeda's Voice", 17, "AugmentedWoodwinds", "augmentedWoodwinds");
    }

    fun AugmentedWoodwinds()
    {
        initDefaults();
        resolvePreset("Andromeda's Voice");
    }

    fun AugmentedWoodwinds(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedWoodwinds(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AugmentedWoodwindsPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class AugmentedYangtze extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Augmented Yangtze", "Augmented Yangtze", 0, "Windy Day", 17, "AugmentedYangtze", "augmentedYangtze");
    }

    fun AugmentedYangtze()
    {
        initDefaults();
        resolvePreset("Windy Day");
    }

    fun AugmentedYangtze(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun AugmentedYangtze(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new AugmentedYangtzePresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class B3V2 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver B-3 V2", "B-3 V2", 0, "Jazz Organ", 11, "B3V2", "b3V2");
        3 => maxChannels;
    }

    fun B3V2()
    {
        initDefaults();
        resolvePreset("Jazz Organ");
    }

    fun B3V2(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun B3V2(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new B3V2PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class BuchlaEaselV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Buchla Easel V", "Buchla Easel V", 0, "Volt-aged Piano", 90, "BuchlaEaselV", "buchlaEaselV");
    }

    fun BuchlaEaselV()
    {
        initDefaults();
        resolvePreset("Volt-aged Piano");
    }

    fun BuchlaEaselV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun BuchlaEaselV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new BuchlaEaselVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class CMIV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver CMI V", "CMI V", 0, "Sararr", 7, "CMIV", "cMIV");
    }

    fun CMIV()
    {
        initDefaults();
        resolvePreset("Sararr");
    }

    fun CMIV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun CMIV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new CMIVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class CP70V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver CP-70 V", "CP-70 V", 0, "Definitive CP", 17, "CP70V", "cP70V");
    }

    fun CP70V()
    {
        initDefaults();
        resolvePreset("Definitive CP");
    }

    fun CP70V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun CP70V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new CP70VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class CS80V4 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver CS-80 V4", "CS-80 V4", 0, "Aftertouch Surprise", 85, "CS80V4", "cS80V4");
    }

    fun CS80V4()
    {
        initDefaults();
        resolvePreset("Aftertouch Surprise");
    }

    fun CS80V4(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun CS80V4(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new CS80V4PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class CZV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver CZ V", "CZ V", 0, "The CZ Brass", 7, "CZV", "cZV");
    }

    fun CZV()
    {
        initDefaults();
        resolvePreset("The CZ Brass");
    }

    fun CZV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun CZV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new CZVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class ClavinetV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Clavinet V", "Clavinet V", 0, "Love & Happiness", 7, "ClavinetV", "clavinetV");
    }

    fun ClavinetV()
    {
        initDefaults();
        resolvePreset("Love & Happiness");
    }

    fun ClavinetV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun ClavinetV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new ClavinetVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class DX7V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver DX7 V", "DX7 V", 0, "Rom1A 11-E.PIANO 1", 7, "DX7V", "dX7V");
    }

    fun DX7V()
    {
        initDefaults();
        resolvePreset("Rom1A 11-E.PIANO 1");
    }

    fun DX7V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun DX7V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new DX7VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class EmulatorIIV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Emulator II V", "Emulator II V", 0, "Voices", 85, "EmulatorIIV", "emulatorIIV");
    }

    fun EmulatorIIV()
    {
        initDefaults();
        resolvePreset("Voices");
    }

    fun EmulatorIIV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun EmulatorIIV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new EmulatorIIVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class FarfisaV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Farfisa V", "Farfisa V", 0, "Dreamy Organ", 7, "FarfisaV", "farfisaV");
    }

    fun FarfisaV()
    {
        initDefaults();
        resolvePreset("Dreamy Organ");
    }

    fun FarfisaV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun FarfisaV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new FarfisaVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Jun6V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Jun-6 V", "Jun-6 V", 0, "Classic Road", 85, "Jun6V", "jun6V");
    }

    fun Jun6V()
    {
        initDefaults();
        resolvePreset("Classic Road");
    }

    fun Jun6V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Jun6V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Jun6VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Jup8V4 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Jup-8 V4", "Jup-8 V4", 0, "Different Waze", 85, "Jup8V4", "jup8V4");
    }

    fun Jup8V4()
    {
        initDefaults();
        resolvePreset("Different Waze");
    }

    fun Jup8V4(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Jup8V4(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Jup8V4PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Jup8000V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Jup-8000 V", "Jup-8000 V", 0, "Vanilla Supasaw Pad", 7, "Jup8000V", "jup8000V");
    }

    fun Jup8000V()
    {
        initDefaults();
        resolvePreset("Vanilla Supasaw Pad");
    }

    fun Jup8000V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Jup8000V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Jup8000VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class KorgMS20V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver KORG MS-20 V", "KORG MS-20 V", 0, "Mark One", 85, "KorgMS20V", "korgMS20V");
    }

    fun KorgMS20V()
    {
        initDefaults();
        resolvePreset("Mark One");
    }

    fun KorgMS20V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun KorgMS20V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new KorgMS20VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Matrix12V2 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Matrix-12 V2", "Matrix-12 V2", 0, "Encounter Pad", 7, "Matrix12V2", "matrix12V2");
    }

    fun Matrix12V2()
    {
        initDefaults();
        resolvePreset("Encounter Pad");
    }

    fun Matrix12V2(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Matrix12V2(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Matrix12V2PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class MellotronV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Mellotron V", "Mellotron V", 0, "Strawberry Flutes", 85, "MellotronV", "mellotronV");
    }

    fun MellotronV()
    {
        initDefaults();
        resolvePreset("Strawberry Flutes");
    }

    fun MellotronV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun MellotronV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new MellotronVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class MiniV4 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Mini V4", "Mini V4", 0, "Base Bass", 17, "MiniV4", "miniV4");
    }

    fun MiniV4()
    {
        initDefaults();
        resolvePreset("Base Bass");
    }

    fun MiniV4(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun MiniV4(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new MiniV4PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class MiniBruteV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver MiniBrute V", "MiniBrute V", 0, "Dark Atmos", 85, "MiniBruteV", "miniBruteV");
    }

    fun MiniBruteV()
    {
        initDefaults();
        resolvePreset("Dark Atmos");
    }

    fun MiniBruteV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun MiniBruteV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new MiniBruteVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class MiniFreakV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver MiniFreak V", "MiniFreak V", 0, "It Saw Key", 90, "MiniFreakV", "miniFreakV");
    }

    fun MiniFreakV()
    {
        initDefaults();
        resolvePreset("It Saw Key");
    }

    fun MiniFreakV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun MiniFreakV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new MiniFreakVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class ModularV3 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Modular V3", "Modular V3", 0, "Berliner", 7, "ModularV3", "modularV3");
    }

    fun ModularV3()
    {
        initDefaults();
        resolvePreset("Berliner");
    }

    fun ModularV3(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun ModularV3(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new ModularV3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class OPXaV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver OP-Xa V", "OP-Xa V", 0, "Jump", 85, "OPXaV", "oPXaV");
    }

    fun OPXaV()
    {
        initDefaults();
        resolvePreset("Jump");
    }

    fun OPXaV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun OPXaV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new OPXaVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class PianoV3 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Piano V3", "Piano V3", 0, "American Home Clean", 85, "PianoV3", "pianoV3");
    }

    fun PianoV3()
    {
        initDefaults();
        resolvePreset("American Home Clean");
    }

    fun PianoV3(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PianoV3(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new PianoV3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Prophet5V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Prophet-5 V", "Prophet-5 V", 0, "Demacro", 85, "Prophet5V", "prophet5V");
    }

    fun Prophet5V()
    {
        initDefaults();
        resolvePreset("Demacro");
    }

    fun Prophet5V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Prophet5V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Prophet5VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class ProphetVSV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Prophet-VS V", "Prophet-VS V", 0, "Artistic Facts", 85, "ProphetVSV", "prophetVSV");
    }

    fun ProphetVSV()
    {
        initDefaults();
        resolvePreset("Artistic Facts");
    }

    fun ProphetVSV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun ProphetVSV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new ProphetVSVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class PureLoFi extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Pure LoFi", "Pure LoFi", 0, "Little Pleasures", 7, "PureLoFi", "pureLoFi");
    }

    fun PureLoFi()
    {
        initDefaults();
        resolvePreset("Little Pleasures");
    }

    fun PureLoFi(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PureLoFi(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new PureLoFiPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class SEMV3 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver SEM V3", "SEM V3", 0, "Atom Sawyer", 7, "SEMV3", "sEMV3");
    }

    fun SEMV3()
    {
        initDefaults();
        resolvePreset("Atom Sawyer");
    }

    fun SEMV3(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SEMV3(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new SEMV3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class SQ80V extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver SQ80 V", "SQ80 V", 0, "Fading Memory", 85, "SQ80V", "sQ80V");
    }

    fun SQ80V()
    {
        initDefaults();
        resolvePreset("Fading Memory");
    }

    fun SQ80V(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SQ80V(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new SQ80VPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class SolinaV2 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Solina V2", "Solina V2", 0, "Blue Strings", 7, "SolinaV2", "solinaV2");
        2 => maxChannels;
    }

    fun SolinaV2()
    {
        initDefaults();
        resolvePreset("Blue Strings");
    }

    fun SolinaV2(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SolinaV2(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new SolinaV2PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class Stage73V2 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Stage-73 V2", "Stage-73 V2", 0, "Clean Mark V", 85, "Stage73V2", "stage73V2");
    }

    fun Stage73V2()
    {
        initDefaults();
        resolvePreset("Clean Mark V");
    }

    fun Stage73V2(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun Stage73V2(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new Stage73V2PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class SynthxV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Synthx V", "Synthx V", 0, "Pulse Width Pad", 7, "SynthxV", "synthxV");
    }

    fun SynthxV()
    {
        initDefaults();
        resolvePreset("Pulse Width Pad");
    }

    fun SynthxV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun SynthxV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new SynthxVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class VOXContinentalV2 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver VOX Continental V2", "VOX Continental V2", 0, "Alternative Vib", 7, "VOXContinentalV2", "vOXContinentalV2");
        3 => maxChannels;
    }

    fun VOXContinentalV2()
    {
        initDefaults();
        resolvePreset("Alternative Vib");
    }

    fun VOXContinentalV2(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun VOXContinentalV2(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new VOXContinentalV2PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class VocoderV extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Vocoder V", "Vocoder V", 0, "Vocoder", 18, "VocoderV", "vocoderV");
    }

    fun VocoderV()
    {
        initDefaults();
        resolvePreset("Vocoder");
    }

    fun VocoderV(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun VocoderV(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new VocoderVPresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class WurliV3 extends ArturiaSynth
{
    fun void initDefaults()
    {
        initArturia("IAC Driver Wurli V3", "Wurli V3", 0, "The Gig", 17, "WurliV3", "wurliV3");
    }

    fun WurliV3()
    {
        initDefaults();
        resolvePreset("The Gig");
    }

    fun WurliV3(string presetName, int v)
    {
        initDefaults();
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun WurliV3(int channel, string presetName, int v)
    {
        initDefaults();
        channel - 1 => midiChannel;
        resolvePreset(presetName);
        GuiLink.sendActivateSynth(uiName);
        Patch(v);
    }

    fun PresetCollection presets()
    {
        if (presetCollection == null) {
            new WurliV3PresetCollection @=> presetCollection;
        }
        return presetCollection;
    }
}

public class ArturiaExtraRegistry
{
    fun static Patch createEmpty(string synthUiName)
    {
        if (synthUiName == "Analog Lab V") {
            return new AnalogLabV();
        } else if (synthUiName == "ARP 2600 V3") {
            return new ARP2600V3();
        } else if (synthUiName == "Augmented Voices") {
            return new AugmentedVoices();
        } else if (synthUiName == "Augmented Woodwinds") {
            return new AugmentedWoodwinds();
        } else if (synthUiName == "Augmented Yangtze") {
            return new AugmentedYangtze();
        } else if (synthUiName == "B-3 V2") {
            return new B3V2();
        } else if (synthUiName == "Buchla Easel V") {
            return new BuchlaEaselV();
        } else if (synthUiName == "CMI V") {
            return new CMIV();
        } else if (synthUiName == "CP-70 V") {
            return new CP70V();
        } else if (synthUiName == "CS-80 V4") {
            return new CS80V4();
        } else if (synthUiName == "CZ V") {
            return new CZV();
        } else if (synthUiName == "Clavinet V") {
            return new ClavinetV();
        } else if (synthUiName == "DX7 V") {
            return new DX7V();
        } else if (synthUiName == "Emulator II V") {
            return new EmulatorIIV();
        } else if (synthUiName == "Farfisa V") {
            return new FarfisaV();
        } else if (synthUiName == "Jun-6 V") {
            return new Jun6V();
        } else if (synthUiName == "Jup-8 V4") {
            return new Jup8V4();
        } else if (synthUiName == "Jup-8000 V") {
            return new Jup8000V();
        } else if (synthUiName == "KORG MS-20 V") {
            return new KorgMS20V();
        } else if (synthUiName == "Matrix-12 V2") {
            return new Matrix12V2();
        } else if (synthUiName == "Mellotron V") {
            return new MellotronV();
        } else if (synthUiName == "Mini V4") {
            return new MiniV4();
        } else if (synthUiName == "MiniBrute V") {
            return new MiniBruteV();
        } else if (synthUiName == "MiniFreak V") {
            return new MiniFreakV();
        } else if (synthUiName == "Modular V3") {
            return new ModularV3();
        } else if (synthUiName == "OP-Xa V") {
            return new OPXaV();
        } else if (synthUiName == "Piano V3") {
            return new PianoV3();
        } else if (synthUiName == "Prophet-5 V") {
            return new Prophet5V();
        } else if (synthUiName == "Prophet-VS V") {
            return new ProphetVSV();
        } else if (synthUiName == "Pure LoFi") {
            return new PureLoFi();
        } else if (synthUiName == "SEM V3") {
            return new SEMV3();
        } else if (synthUiName == "SQ80 V") {
            return new SQ80V();
        } else if (synthUiName == "Solina V2") {
            return new SolinaV2();
        } else if (synthUiName == "Stage-73 V2") {
            return new Stage73V2();
        } else if (synthUiName == "Synthx V") {
            return new SynthxV();
        } else if (synthUiName == "VOX Continental V2") {
            return new VOXContinentalV2();
        } else if (synthUiName == "Vocoder V") {
            return new VocoderV();
        } else if (synthUiName == "Wurli V3") {
            return new WurliV3();
        }
        return null;
    }

    fun static Patch createDefault(string synthUiName, int ch1Based, int vol)
    {
        if (synthUiName == "Analog Lab V") {
            return new AnalogLabV(ch1Based, "Classic Jun Keys", vol);
        } else if (synthUiName == "ARP 2600 V3") {
            return new ARP2600V3(ch1Based, "Sync Seq", vol);
        } else if (synthUiName == "Augmented Voices") {
            return new AugmentedVoices(ch1Based, "Voices Trailer", vol);
        } else if (synthUiName == "Augmented Woodwinds") {
            return new AugmentedWoodwinds(ch1Based, "Andromeda's Voice", vol);
        } else if (synthUiName == "Augmented Yangtze") {
            return new AugmentedYangtze(ch1Based, "Windy Day", vol);
        } else if (synthUiName == "B-3 V2") {
            return new B3V2(ch1Based, "Jazz Organ", vol);
        } else if (synthUiName == "Buchla Easel V") {
            return new BuchlaEaselV(ch1Based, "Volt-aged Piano", vol);
        } else if (synthUiName == "CMI V") {
            return new CMIV(ch1Based, "Sararr", vol);
        } else if (synthUiName == "CP-70 V") {
            return new CP70V(ch1Based, "Definitive CP", vol);
        } else if (synthUiName == "CS-80 V4") {
            return new CS80V4(ch1Based, "Aftertouch Surprise", vol);
        } else if (synthUiName == "CZ V") {
            return new CZV(ch1Based, "The CZ Brass", vol);
        } else if (synthUiName == "Clavinet V") {
            return new ClavinetV(ch1Based, "Love & Happiness", vol);
        } else if (synthUiName == "DX7 V") {
            return new DX7V(ch1Based, "Rom1A 11-E.PIANO 1", vol);
        } else if (synthUiName == "Emulator II V") {
            return new EmulatorIIV(ch1Based, "Voices", vol);
        } else if (synthUiName == "Farfisa V") {
            return new FarfisaV(ch1Based, "Dreamy Organ", vol);
        } else if (synthUiName == "Jun-6 V") {
            return new Jun6V(ch1Based, "Classic Road", vol);
        } else if (synthUiName == "Jup-8 V4") {
            return new Jup8V4(ch1Based, "Different Waze", vol);
        } else if (synthUiName == "Jup-8000 V") {
            return new Jup8000V(ch1Based, "Vanilla Supasaw Pad", vol);
        } else if (synthUiName == "KORG MS-20 V") {
            return new KorgMS20V(ch1Based, "Mark One", vol);
        } else if (synthUiName == "Matrix-12 V2") {
            return new Matrix12V2(ch1Based, "Encounter Pad", vol);
        } else if (synthUiName == "Mellotron V") {
            return new MellotronV(ch1Based, "Strawberry Flutes", vol);
        } else if (synthUiName == "Mini V4") {
            return new MiniV4(ch1Based, "Base Bass", vol);
        } else if (synthUiName == "MiniBrute V") {
            return new MiniBruteV(ch1Based, "Dark Atmos", vol);
        } else if (synthUiName == "MiniFreak V") {
            return new MiniFreakV(ch1Based, "It Saw Key", vol);
        } else if (synthUiName == "Modular V3") {
            return new ModularV3(ch1Based, "Berliner", vol);
        } else if (synthUiName == "OP-Xa V") {
            return new OPXaV(ch1Based, "Jump", vol);
        } else if (synthUiName == "Piano V3") {
            return new PianoV3(ch1Based, "American Home Clean", vol);
        } else if (synthUiName == "Prophet-5 V") {
            return new Prophet5V(ch1Based, "Demacro", vol);
        } else if (synthUiName == "Prophet-VS V") {
            return new ProphetVSV(ch1Based, "Artistic Facts", vol);
        } else if (synthUiName == "Pure LoFi") {
            return new PureLoFi(ch1Based, "Little Pleasures", vol);
        } else if (synthUiName == "SEM V3") {
            return new SEMV3(ch1Based, "Atom Sawyer", vol);
        } else if (synthUiName == "SQ80 V") {
            return new SQ80V(ch1Based, "Fading Memory", vol);
        } else if (synthUiName == "Solina V2") {
            return new SolinaV2(ch1Based, "Blue Strings", vol);
        } else if (synthUiName == "Stage-73 V2") {
            return new Stage73V2(ch1Based, "Clean Mark V", vol);
        } else if (synthUiName == "Synthx V") {
            return new SynthxV(ch1Based, "Pulse Width Pad", vol);
        } else if (synthUiName == "VOX Continental V2") {
            return new VOXContinentalV2(ch1Based, "Alternative Vib", vol);
        } else if (synthUiName == "Vocoder V") {
            return new VocoderV(ch1Based, "Vocoder", vol);
        } else if (synthUiName == "Wurli V3") {
            return new WurliV3(ch1Based, "The Gig", vol);
        }
        return null;
    }
}
