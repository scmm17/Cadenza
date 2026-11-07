@import "../framework/yaml.ck"

// Patch is a class that represents a MIDI device in the framework.
// It contains the device name, MIDI channel, patch name, volume, filter cutoff, filter resonance, pan, UI name, muted state, program, and bank.
//
// This class is used to create patches for MIDI devices.
public class Patch 
{
    // Name of the MIDI device to connect to
    string deviceName;
    // MIDI channel to use (0-based)
    int midiChannel;
    // Name of the patch (preset) for display and reference
    string patchName;
    // Volume level (0-127, -1 for default)
    int volume;
    // Filter cutoff value (0-127, -1 for unused)
    int filterCutoff;
    // Filter resonance value (0-127, -1 for unused)
    int filterResonance;
    // Stereo pan position (0=left, 64=center, 127=right, -1 for unused)
    int pan;
    // Name to display in the UI
    string uiName;
    // Muted state (0 = not muted, 1 = muted, or use as boolean)
    int muted;     // Effective runtime muted state (used by noteOn)
    int userMuted; // User-toggled explicit mute state

    // Program and bank for program change, used by some devices
    int program;
    int bank;

    MidiOut gma;
    string openedDeviceName;

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
        if (deviceName != "" && deviceName != openedDeviceName)
        {
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

    fun void updateControllers()
    {
        setPreset();

        if (filterCutoff != -1) {
            sendControllerChange(74, filterCutoff);
        }
        if (filterResonance != -1) {
            sendControllerChange(71, filterResonance);
        }
        if (pan != -1) {
            sendControllerChange(10, pan);
        }
        if (volume != -1) {
            sendControllerChange(7, volume);
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

    fun void sendAllNotesOff() 
    {
        if (noteXmit == null) { initNoteXmit(); }
        if (devIndex > 0) {
            noteXmit.startMsg("/cadenza/allNotesOff", "i");
            devIndex => noteXmit.addInt;
        }
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        0x7B => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }

    fun void programChangeHydra(int program, int bank)
    {
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        0 => msg.data2;
        bank => msg.data3;
        gma.send(msg);

        0xB0 | midiChannel => msg.data1;
        32 => msg.data2;
        bank => msg.data3;
        gma.send(msg);

        0xC0 | midiChannel => msg.data1;
        0 => msg.data2;
        program => msg.data3;
        gma.send(msg);
    }

    fun void programChangeS1(int program)
    {
        MidiMsg msg;

        0xC0 | 15 => msg.data1;
        program => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }

    fun void programChangeSH4d(int program)
    {
        MidiMsg msg;

        0xC0 | 15 => msg.data1;
        86 => msg.data2;
        program => msg.data3;
        gma.send(msg);
    }

    fun void programChangeSH4dChannel(int program, int bank)
    {
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        0 => msg.data2;
        88 => msg.data3;
        gma.send(msg);

        0xB0 | midiChannel => msg.data1;
        32 => msg.data2;
        bank => msg.data3;
        gma.send(msg);

        0xC0 | midiChannel => msg.data1;
        0 => msg.data2;
        program => msg.data3;
        gma.send(msg);
    }

    fun void programChangeSH4d(int program, int bank)
    {
        programChangeSH4dChannel(program, bank);
    }

    fun void programChangeV3GrandPiano(int program, int bank)
    {
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        0 => msg.data2;
        bank => msg.data3;
        gma.send(msg);

        0xB0 | midiChannel => msg.data1;
        32 => msg.data2;
        0 => msg.data3;
        gma.send(msg);

        0xC0 | midiChannel => msg.data1;
        0 => msg.data2;
        program => msg.data3;
        gma.send(msg);
    }

    int devIndex; // 1-based device index (1-8)

    static OscSend @ noteXmit;

    fun static void initNoteXmit() {
        if (noteXmit == null) {
            new OscSend @=> noteXmit;
            noteXmit.setHost("localhost", 9450);
        }
    }

    fun void noteOn(int note, int velocity, dur duration)
    {
        if (muted) {
            return;
        }
        if (noteXmit == null) { initNoteXmit(); }
        if (devIndex > 0) {
            noteXmit.startMsg("/cadenza/noteOn", "i i i");
            devIndex => noteXmit.addInt;
            note => noteXmit.addInt;
            velocity => noteXmit.addInt;
        }
        MidiMsg msg;
        0x90 | midiChannel => msg.data1;
        note => msg.data2;
        velocity => msg.data3;
        gma.send(msg);
        if (duration  > 0::ms) {
            spork ~ noteOffFun(note, duration - 1::ms);
        }
    }
        
    fun void noteOff(int note)
    {
        if (noteXmit == null) { initNoteXmit(); }
        if (devIndex > 0) {
            noteXmit.startMsg("/cadenza/noteOff", "i i");
            devIndex => noteXmit.addInt;
            note => noteXmit.addInt;
        }
        MidiMsg msg;
        0x80 | midiChannel => msg.data1;
        note => msg.data2;
        gma.send(msg);
    }

    fun noteOffFun(int note, dur duration)
    {
        duration => now;
        noteOff(note);
    }
}

// HydraPreset is a class that represents a Hydrasynth preset in the framework.
// It contains the program, bank, code, name, and category.
//
// This class is used to create Hydrasynth presets for MIDI devices.
public class HydraPreset
{
    int program;
    int bank;
    string code;
    string name;
    string category;
    fun HydraPreset(int p, int b, string c, string n, string cat) {
        p => program;
        b => bank;
        c => code;
        n => name;
        cat => category;
    }
}

// HydraPresetCollection is a class that represents a collection of Hydrasynth presets in the framework.
// It contains the current preset index, current preset category, and a list of Hydrasynth presets.
//
// This class is used to create Hydrasynth preset collections for MIDI devices.
public class HydraPresetCollection
{
    int curPresetIndex;
    string curPresetCategory;

    fun HydraPresetCollection()
    {
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun HydraPreset getNextPreset() 
    {
        (curPresetIndex + 1) % hydraPresets.cap() => curPresetIndex;
        hydraPresets[curPresetIndex] @=> HydraPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun HydraPreset getPreviousPreset() 
    {
        ((curPresetIndex - 1) + hydraPresets.cap()) % hydraPresets.cap() => curPresetIndex;
        hydraPresets[curPresetIndex] @=> HydraPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun HydraPreset getNextCategory()
    {
        for (curPresetIndex+1 => int i; i < hydraPresets.cap(); i++) {
            if (hydraPresets[i].category != curPresetCategory) {
                i => curPresetIndex;
                hydraPresets[curPresetIndex] @=> HydraPreset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        0 => curPresetIndex;
        hydraPresets[0] @=> HydraPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun HydraPreset getPreviousCategory()
    {
        for (curPresetIndex => int i; i >= 0; i--) {
            if (hydraPresets[i].category != curPresetCategory) {
                i => curPresetIndex;
                hydraPresets[curPresetIndex] @=> HydraPreset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        hydraPresets.cap() - 1 => curPresetIndex;
        hydraPresets[curPresetIndex] @=> HydraPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun string normalizePresetName(string s)
    {
        s => string copy;
        copy.replace("\"", "'");
        return copy;
    }

    fun int hasPreset(string presetName)
    {
        normalizePresetName(presetName) => string norm;
        for( HydraPreset preset: hydraPresets) {
            if (preset.name == presetName || preset.name == norm || preset.code == presetName)
                return true;
        }
        return false;
    }

    fun HydraPreset getPreset(string presetName)
    {
        normalizePresetName(presetName) => string norm;
        for( HydraPreset preset: hydraPresets) {
            if (preset.name == presetName || preset.name == norm || preset.code == presetName)
                return preset;
        }
        <<< "Can't find preset: ", presetName >>>;
        return hydraPresets[0];
    }

    fun void setPresetState(string presetName)
    {
        normalizePresetName(presetName) => string norm;
        for( 0 => int i; i < hydraPresets.cap(); i++) {
            if (hydraPresets[i].name == presetName || hydraPresets[i].name == norm || hydraPresets[i].code == presetName) {
                i => curPresetIndex;
                hydraPresets[curPresetIndex] @=> HydraPreset preset;
                preset.category @=> curPresetCategory;
                return;
            }
        }
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

// All Presets for the Hydrasynth (Banks A, B, C, D, E)
[
// Bank A
new HydraPreset(0, 0, "A001", "Sawpressive GD", "A"),
new HydraPreset(1, 0, "A002", "GX Ultra Pad PS", "A"),
new HydraPreset(2, 0, "A003", "Venus Pluck ET", "A"),
new HydraPreset(3, 0, "A004", "BladeTitles PS", "A"),
new HydraPreset(4, 0, "A005", "Chow's Arp GD", "A"),
new HydraPreset(5, 0, "A006", "Doppler Bass MP", "A"),
new HydraPreset(6, 0, "A007", "Clean FM Pad MP", "A"),
new HydraPreset(7, 0, "A008", "The Real Owl MF", "A"),
new HydraPreset(8, 0, "A009", "Cory's Lead GD", "A"),
new HydraPreset(9, 0, "A010", "Poly Risers MP", "A"),
new HydraPreset(10, 0, "A011", "Frantasia FP", "A"),
new HydraPreset(11, 0, "A012", "Beyond Bob SCD", "A"),
new HydraPreset(12, 0, "A013", "SpiralBallad PS", "A"),
new HydraPreset(13, 0, "A014", "FM Simple Bass", "A"),
new HydraPreset(14, 0, "A015", "Ribbon FX Arp MP", "A"),
new HydraPreset(15, 0, "A016", "Etherpad RJ", "A"),
new HydraPreset(16, 0, "A017", "Hydra Drawbar RJ", "A"),
new HydraPreset(17, 0, "A018", "FLUXR SOUP KFP", "A"),
new HydraPreset(18, 0, "A019", "Wavescan GD", "A"),
new HydraPreset(19, 0, "A020", "LHR-JFK-LAX", "A"),
new HydraPreset(20, 0, "A021", "NobleBell GD", "A"),
new HydraPreset(21, 0, "A022", "Altern8r FP", "A"),
new HydraPreset(22, 0, "A023", "GnarlyDude GD", "A"),
new HydraPreset(23, 0, "A024", "MAGESTIC STRGSdf", "A"),
new HydraPreset(24, 0, "A025", "Synthwave Bs DA", "A"),
new HydraPreset(25, 0, "A026", "FM Moues MP", "A"),
new HydraPreset(26, 0, "A027", "Press&Summon DA", "A"),
new HydraPreset(27, 0, "A028", "BladeBluesLd PS", "A"),
new HydraPreset(28, 0, "A029", "Damp Beat ET", "A"),
new HydraPreset(29, 0, "A030", "Chord Grooves MP", "A"),
new HydraPreset(30, 0, "A031", "Volf Palm GD", "A"),
new HydraPreset(31, 0, "A032", "Swarm Bass RJ", "A"),
new HydraPreset(32, 0, "A033", "St.Genviv FP", "A"),
new HydraPreset(33, 0, "A034", "Slide Circus ET", "A"),
new HydraPreset(34, 0, "A035", "Earthshine ET", "A"),
new HydraPreset(35, 0, "A036", "LoveArp SCD", "A"),
new HydraPreset(36, 0, "A037", "Cine Perc LoopMP", "A"),
new HydraPreset(37, 0, "A038", "Twilight ET", "A"),
new HydraPreset(38, 0, "A039", "FundaMental SCD", "A"),
new HydraPreset(39, 0, "A040", "Ambisines FP", "A"),
new HydraPreset(40, 0, "A041", "FightBot KFP", "A"),
new HydraPreset(41, 0, "A042", "Midlight ET", "A"),
new HydraPreset(42, 0, "A043", "Tubular FP", "A"),
new HydraPreset(43, 0, "A044", "Spectral FP", "A"),
new HydraPreset(44, 0, "A045", "World 1-2 MF", "A"),
new HydraPreset(45, 0, "A046", "Pew Pew Pew MF", "A"),
new HydraPreset(46, 0, "A047", "Akhenaten MF", "A"),
new HydraPreset(47, 0, "A048", "BPM Ramp Pad MP", "A"),
new HydraPreset(48, 0, "A049", "Automata ET", "A"),
new HydraPreset(49, 0, "A050", "Ed Wood Calling", "A"),
new HydraPreset(50, 0, "A051", "Go Your Own Way", "A"),
new HydraPreset(51, 0, "A052", "EazyPeZE KFP", "A"),
new HydraPreset(52, 0, "A053", "Hydra EP RJ", "A"),
new HydraPreset(53, 0, "A054", "Metal Worx DA", "A"),
new HydraPreset(54, 0, "A055", "RhythmArp PS", "A"),
new HydraPreset(55, 0, "A056", "Lunar Bender MF", "A"),
new HydraPreset(56, 0, "A057", "SDS Snare GD", "A"),
new HydraPreset(57, 0, "A058", "Vox Strings MP", "A"),
new HydraPreset(58, 0, "A059", "Techno Locker MP", "A"),
new HydraPreset(59, 0, "A060", "Fretless ET", "A"),
new HydraPreset(60, 0, "A061", "Temple Trap DA", "A"),
new HydraPreset(61, 0, "A062", "BowedPPG PS", "A"),
new HydraPreset(62, 0, "A063", "CycleOfThoughtMF", "A"),
new HydraPreset(63, 0, "A064", "PearlsOf Wisdom", "A"),
new HydraPreset(64, 0, "A065", "Mixologist GD", "A"),
new HydraPreset(65, 0, "A066", "BPM Fall Pad MP", "A"),
new HydraPreset(66, 0, "A067", "Hyper8 KFP", "A"),
new HydraPreset(67, 0, "A068", "Monstah FP", "A"),
new HydraPreset(68, 0, "A069", "Nostromo GD", "A"),
new HydraPreset(69, 0, "A070", "OberMine GD", "A"),
new HydraPreset(70, 0, "A071", "Wave Hits SCD", "A"),
new HydraPreset(71, 0, "A072", "GellPMP KFP", "A"),
new HydraPreset(72, 0, "A073", "Stereolab GD", "A"),
new HydraPreset(73, 0, "A074", "Duo Patterns MP", "A"),
new HydraPreset(74, 0, "A075", "Styx Chords MF", "A"),
new HydraPreset(75, 0, "A076", "TexanTurtles SCD", "A"),
new HydraPreset(76, 0, "A077", "Felt KFP", "A"),
new HydraPreset(77, 0, "A078", "AbbaAndI PS", "A"),
new HydraPreset(78, 0, "A079", "Filth Rolls MP", "A"),
new HydraPreset(79, 0, "A080", "Trancer MP", "A"),
new HydraPreset(80, 0, "A081", "HitChords! SCD", "A"),
new HydraPreset(81, 0, "A082", "XTH RJ", "A"),
new HydraPreset(82, 0, "A083", "Wind King FP", "A"),
new HydraPreset(83, 0, "A084", "LukesLazr PS", "A"),
new HydraPreset(84, 0, "A085", "Slow-esto SCD", "A"),
new HydraPreset(85, 0, "A086", "Caspian SCD", "A"),
new HydraPreset(86, 0, "A087", "Ribbon8bitGameRJ", "A"),
new HydraPreset(87, 0, "A088", "Simplicite MF", "A"),
new HydraPreset(88, 0, "A089", "Goodbyes MF", "A"),
new HydraPreset(89, 0, "A090", "SYNC GD", "A"),
new HydraPreset(90, 0, "A091", "Suitcase MP", "A"),
new HydraPreset(91, 0, "A092", "Trade Some KFP", "A"),
new HydraPreset(92, 0, "A093", "Muted Glass Perc", "A"),
new HydraPreset(93, 0, "A094", "MACHNE WELCOMEdf", "A"),
new HydraPreset(94, 0, "A095", "Future Forest DA", "A"),
new HydraPreset(95, 0, "A096", "HeauenEleven PS", "A"),
new HydraPreset(96, 0, "A097", "2007 LDN Bass", "A"),
new HydraPreset(97, 0, "A098", "FracturedBloopMP", "A"),
new HydraPreset(98, 0, "A099", "The Cube FP", "A"),
new HydraPreset(99, 0, "A100", "Yuno GD", "A"),
new HydraPreset(100, 0, "A101", "VHS Dreams MP", "A"),
new HydraPreset(101, 0, "A102", "Nymphs MF", "A"),
new HydraPreset(102, 0, "A103", "MinionsLulliby", "A"),
new HydraPreset(103, 0, "A104", "PWM-ASM GD", "A"),
new HydraPreset(104, 0, "A105", "Foster Growth", "A"),
new HydraPreset(105, 0, "A106", "CS BASS PS", "A"),
new HydraPreset(106, 0, "A107", "Krina tou Agrou", "A"),
new HydraPreset(107, 0, "A108", "Freezing TM", "A"),
new HydraPreset(108, 0, "A109", "Ohhh GD", "A"),
new HydraPreset(109, 0, "A110", "88 mph DA", "A"),
new HydraPreset(110, 0, "A111", "2 Simple GD", "A"),
new HydraPreset(111, 0, "A112", "ResoSpread PS", "A"),
new HydraPreset(112, 0, "A113", "ReversOrgan ET", "A"),
new HydraPreset(113, 0, "A114", "InYoFace Bass PS", "A"),
new HydraPreset(114, 0, "A115", "Soda Fizz", "A"),
new HydraPreset(115, 0, "A116", "StepFun BS", "A"),
new HydraPreset(116, 0, "A117", "BigSaws GD", "A"),
new HydraPreset(117, 0, "A118", "DirtClav KFP", "A"),
new HydraPreset(118, 0, "A119", "90124 SCD", "A"),
new HydraPreset(119, 0, "A120", "The Hi-Garden MF", "A"),
new HydraPreset(120, 0, "A121", "Venus Dawn RJ", "A"),
new HydraPreset(121, 0, "A122", "CompThat Funk PS", "A"),
new HydraPreset(122, 0, "A123", "NZ Funk Bass MP", "A"),
new HydraPreset(123, 0, "A124", "Play w Jen KFP", "A"),
new HydraPreset(124, 0, "A125", "Future PWM MP", "A"),
new HydraPreset(125, 0, "A126", "BUGS IN LOVE df", "A"),
new HydraPreset(126, 0, "A127", "Calies Lead GD", "A"),
new HydraPreset(127, 0, "A128", "FM Piano FP", "A"),
// Bank B
new HydraPreset(0, 1, "B001", "Na'vi River GD", "B"),
new HydraPreset(1, 1, "B002", "The 3rd Wife MF", "B"),
new HydraPreset(2, 1, "B003", "Broken Base TM", "B"),
new HydraPreset(3, 1, "B004", "KeepItLow SCD", "B"),
new HydraPreset(4, 1, "B005", "Reeds PS", "B"),
new HydraPreset(5, 1, "B006", "Rust Piano TM", "B"),
new HydraPreset(6, 1, "B007", "FM Percussion TM", "B"),
new HydraPreset(7, 1, "B008", "Exit SCD", "B"),
new HydraPreset(8, 1, "B009", "PPGChoir MW PS", "B"),
new HydraPreset(9, 1, "B010", "DesiDrop GD", "B"),
new HydraPreset(10, 1, "B011", "SawMiller BS", "B"),
new HydraPreset(11, 1, "B012", "Harm0nMe KFP", "B"),
new HydraPreset(12, 1, "B013", "Dragon Bass DA", "B"),
new HydraPreset(13, 1, "B014", "Dictator DA", "B"),
new HydraPreset(14, 1, "B015", "Moon=Mars SCD", "B"),
new HydraPreset(15, 1, "B016", "Boards of CV TM", "B"),
new HydraPreset(16, 1, "B017", "3am Somewhere", "B"),
new HydraPreset(17, 1, "B018", "Modepluk FP", "B"),
new HydraPreset(18, 1, "B019", "Lovedrive ET", "B"),
new HydraPreset(19, 1, "B020", "WaveTrain BS", "B"),
new HydraPreset(20, 1, "B021", "Alaska PS", "B"),
new HydraPreset(21, 1, "B022", "Over TheFalls", "B"),
new HydraPreset(22, 1, "B023", "Back to Bass", "B"),
new HydraPreset(23, 1, "B024", "CheekyMorning MF", "B"),
new HydraPreset(24, 1, "B025", "P5 num12 GD", "B"),
new HydraPreset(25, 1, "B026", "Silent Cinema", "B"),
new HydraPreset(26, 1, "B027", "Emotional TingDA", "B"),
new HydraPreset(27, 1, "B028", "Formant Pluck ET", "B"),
new HydraPreset(28, 1, "B029", "Grasslands", "B"),
new HydraPreset(29, 1, "B030", "FLYLYKE df", "B"),
new HydraPreset(30, 1, "B031", "Mr.Sinus BS", "B"),
new HydraPreset(31, 1, "B032", "RoachRun GD", "B"),
new HydraPreset(32, 1, "B033", "DeepBass GD", "B"),
new HydraPreset(33, 1, "B034", "Phase Mountain", "B"),
new HydraPreset(34, 1, "B035", "Mr. Hazard MF", "B"),
new HydraPreset(35, 1, "B036", "FractInversModMP", "B"),
new HydraPreset(36, 1, "B037", "Cassini FP", "B"),
new HydraPreset(37, 1, "B038", "Dusting KFP", "B"),
new HydraPreset(38, 1, "B039", "Big Kick GD", "B"),
new HydraPreset(39, 1, "B040", "Sparse Chaos MP", "B"),
new HydraPreset(40, 1, "B041", "Rhythmize FP", "B"),
new HydraPreset(41, 1, "B042", "Moments ET", "B"),
new HydraPreset(42, 1, "B043", "Lotus ET", "B"),
new HydraPreset(43, 1, "B044", "BeatPPL Bass KFP", "B"),
new HydraPreset(44, 1, "B045", "Polymorph FP", "B"),
new HydraPreset(45, 1, "B046", "TinFoilHat GD", "B"),
new HydraPreset(46, 1, "B047", "Worldmallet FP", "B"),
new HydraPreset(47, 1, "B048", "Androish KFP", "B"),
new HydraPreset(48, 1, "B049", "SadDust KFP", "B"),
new HydraPreset(49, 1, "B050", "Itchy Lead", "B"),
new HydraPreset(50, 1, "B051", "Wave Scanner TM", "B"),
new HydraPreset(51, 1, "B052", "Terpsichore PS", "B"),
new HydraPreset(52, 1, "B053", "Swipe Bass RJ", "B"),
new HydraPreset(53, 1, "B054", "Taper Pad MP", "B"),
new HydraPreset(54, 1, "B055", "Lucid Dreamer MF", "B"),
new HydraPreset(55, 1, "B056", "FindSoul KFP", "B"),
new HydraPreset(56, 1, "B057", "Sunrise FP", "B"),
new HydraPreset(57, 1, "B058", "Luna Zither MP", "B"),
new HydraPreset(58, 1, "B059", "Constantine DA", "B"),
new HydraPreset(59, 1, "B060", "Jupiter's Chd MP", "B"),
new HydraPreset(60, 1, "B061", "Angry Analog RJ", "B"),
new HydraPreset(61, 1, "B062", "SparklFairies PS", "B"),
new HydraPreset(62, 1, "B063", "E=mc^2 MF", "B"),
new HydraPreset(63, 1, "B064", "TripHit GD", "B"),
new HydraPreset(64, 1, "B065", "Cityscape RJ", "B"),
new HydraPreset(65, 1, "B066", "VHS Warbler JC", "B"),
new HydraPreset(66, 1, "B067", "AT Octaves MP", "B"),
new HydraPreset(67, 1, "B068", "VeloStack RJ", "B"),
new HydraPreset(68, 1, "B069", "Recordr PS", "B"),
new HydraPreset(69, 1, "B070", "SadLofi KFP", "B"),
new HydraPreset(70, 1, "B071", "Del302 KFP", "B"),
new HydraPreset(71, 1, "B072", "Gl'tc# Arp$", "B"),
new HydraPreset(72, 1, "B073", "Charon's Core MF", "B"),
new HydraPreset(73, 1, "B074", "Dyson GD", "B"),
new HydraPreset(74, 1, "B075", "Sproingg PS", "B"),
new HydraPreset(75, 1, "B076", "FM Tines df", "B"),
new HydraPreset(76, 1, "B077", "CSViolin PS", "B"),
new HydraPreset(77, 1, "B078", "Almost Analog MP", "B"),
new HydraPreset(78, 1, "B079", "FutRtude KFP", "B"),
new HydraPreset(79, 1, "B080", "Glottle Bass MP", "B"),
new HydraPreset(80, 1, "B081", "Basic Bass", "B"),
new HydraPreset(81, 1, "B082", "RIBBN DESCENT df", "B"),
new HydraPreset(82, 1, "B083", "Telekonesis RJ", "B"),
new HydraPreset(83, 1, "B084", "Carnation", "B"),
new HydraPreset(84, 1, "B085", "Table Pads MP", "B"),
new HydraPreset(85, 1, "B086", "RIGHTEOUS ORG df", "B"),
new HydraPreset(86, 1, "B087", "Robots Rev4 DA", "B"),
new HydraPreset(87, 1, "B088", "BetteDavis PS", "B"),
new HydraPreset(88, 1, "B089", "Elevate ET", "B"),
new HydraPreset(89, 1, "B090", "Angry Lowend TM", "B"),
new HydraPreset(90, 1, "B091", "Gulliver Pads DA", "B"),
new HydraPreset(91, 1, "B092", "Punjab", "B"),
new HydraPreset(92, 1, "B093", "Deep Space TM", "B"),
new HydraPreset(93, 1, "B094", "StumblingLayerMP", "B"),
new HydraPreset(94, 1, "B095", "WATER ANGELS df", "B"),
new HydraPreset(95, 1, "B096", "Galatea 1989 MF", "B"),
new HydraPreset(96, 1, "B097", "WaveLength SCD", "B"),
new HydraPreset(97, 1, "B098", "Rockin Roll TM", "B"),
new HydraPreset(98, 1, "B099", "Poor Me KFP", "B"),
new HydraPreset(99, 1, "B100", "Royal Pulses RJ", "B"),
new HydraPreset(100, 1, "B101", "Dandelion", "B"),
new HydraPreset(101, 1, "B102", "4VoiceMemoriesRJ", "B"),
new HydraPreset(102, 1, "B103", "FM Flight TM", "B"),
new HydraPreset(103, 1, "B104", "WideOpen SCD", "B"),
new HydraPreset(104, 1, "B105", "BAYCE! df", "B"),
new HydraPreset(105, 1, "B106", "Roadsy FP", "B"),
new HydraPreset(106, 1, "B107", "SundayDreamer MF", "B"),
new HydraPreset(107, 1, "B108", "Bumble ET", "B"),
new HydraPreset(108, 1, "B109", "Europa RJ", "B"),
new HydraPreset(109, 1, "B110", "GermanDelightSCD", "B"),
new HydraPreset(110, 1, "B111", "Typical SCD", "B"),
new HydraPreset(111, 1, "B112", "Cloudburst PS", "B"),
new HydraPreset(112, 1, "B113", "Pad 4 AllSeasons", "B"),
new HydraPreset(113, 1, "B114", "ChorlPressr PS", "B"),
new HydraPreset(114, 1, "B115", "Hydroborea SCD", "B"),
new HydraPreset(115, 1, "B116", "FM Slap Bass RJ", "B"),
new HydraPreset(116, 1, "B117", "SINE TIFIC df", "B"),
new HydraPreset(117, 1, "B118", "GospelToLord SCD", "B"),
new HydraPreset(118, 1, "B119", "WaveChop PS", "B"),
new HydraPreset(119, 1, "B120", "LUXIOUS df", "B"),
new HydraPreset(120, 1, "B121", "Pandemic RJ", "B"),
new HydraPreset(121, 1, "B122", "Gamelan DJ SCD", "B"),
new HydraPreset(122, 1, "B123", "Metal Bed TM", "B"),
new HydraPreset(123, 1, "B124", "Mystery Theater", "B"),
new HydraPreset(124, 1, "B125", "Rewind Time RJ", "B"),
new HydraPreset(125, 1, "B126", "#ANLGSTRG", "B"),
new HydraPreset(126, 1, "B127", "Tronic Bass TM", "B"),
new HydraPreset(127, 1, "B128", "RoboOboe BS", "B"),
// Bank C
new HydraPreset(0, 2, "C001", "BAHJA BS", "C"),
new HydraPreset(1, 2, "C002", "Breathe! SCD", "C"),
new HydraPreset(2, 2, "C003", "Fireplace SCD", "C"),
new HydraPreset(3, 2, "C004", "Synth Beef BS", "C"),
new HydraPreset(4, 2, "C005", "LongAgo... SCD", "C"),
new HydraPreset(5, 2, "C006", "01010101", "C"),
new HydraPreset(6, 2, "C007", "Tonewheel FP", "C"),
new HydraPreset(7, 2, "C008", "Fan Fauorite", "C"),
new HydraPreset(8, 2, "C009", "ALIEN CELLO df", "C"),
new HydraPreset(9, 2, "C010", "Big Snare MP", "C"),
new HydraPreset(10, 2, "C011", "PRO1 Square GD", "C"),
new HydraPreset(11, 2, "C012", "FolkDance ofMars", "C"),
new HydraPreset(12, 2, "C013", "Pluckverb DA", "C"),
new HydraPreset(13, 2, "C014", "DRONER BS", "C"),
new HydraPreset(14, 2, "C015", "Box O' Toyz RJ", "C"),
new HydraPreset(15, 2, "C016", "JAZZ GTR+BASS df", "C"),
new HydraPreset(16, 2, "C017", "StarBase 225", "C"),
new HydraPreset(17, 2, "C018", "BramAgema SCD", "C"),
new HydraPreset(18, 2, "C019", "DirtyMono SCD", "C"),
new HydraPreset(19, 2, "C020", "WetPlate SCD", "C"),
new HydraPreset(20, 2, "C021", "Funkified ET", "C"),
new HydraPreset(21, 2, "C022", "Slimtone ET", "C"),
new HydraPreset(22, 2, "C023", "DxPiano GD", "C"),
new HydraPreset(23, 2, "C024", "Choppy Seas JC", "C"),
new HydraPreset(24, 2, "C025", "Elly redKFP", "C"),
new HydraPreset(25, 2, "C026", "Crush On You MF", "C"),
new HydraPreset(26, 2, "C027", "LostSpaceTapesJC", "C"),
new HydraPreset(27, 2, "C028", "Seabed ET", "C"),
new HydraPreset(28, 2, "C029", "90s Workstation", "C"),
new HydraPreset(29, 2, "C030", "Nasty ET", "C"),
new HydraPreset(30, 2, "C031", "Vox Shock MP", "C"),
new HydraPreset(31, 2, "C032", "Kerberos Bells MF", "C"),
new HydraPreset(32, 2, "C033", "AgroStep KFP", "C"),
new HydraPreset(33, 2, "C034", "SpaceCave SCD", "C"),
new HydraPreset(34, 2, "C035", "Deltr0n KFP", "C"),
new HydraPreset(35, 2, "C036", "Liven ET", "C"),
new HydraPreset(36, 2, "C037", "Hydraphonic TM", "C"),
new HydraPreset(37, 2, "C038", "Chakra Keys RJ", "C"),
new HydraPreset(38, 2, "C039", "BigDeuce KFP", "C"),
new HydraPreset(39, 2, "C040", "PinPoint SCD", "C"),
new HydraPreset(40, 2, "C041", "Glass Finger ET", "C"),
new HydraPreset(41, 2, "C042", "NewMan GD", "C"),
new HydraPreset(42, 2, "C043", "Bubble Vision RJ", "C"),
new HydraPreset(43, 2, "C044", "P0CKY BS", "C"),
new HydraPreset(44, 2, "C045", "BamBooz KFP", "C"),
new HydraPreset(45, 2, "C046", "Lost In Leads", "C"),
new HydraPreset(46, 2, "C047", "NegaFlux KFP", "C"),
new HydraPreset(47, 2, "C048", "StepzIn KFP", "C"),
new HydraPreset(48, 2, "C049", "LFO Girls TM", "C"),
new HydraPreset(49, 2, "C050", "Radiance 2055 MF", "C"),
new HydraPreset(50, 2, "C051", "HydraTines PS", "C"),
new HydraPreset(51, 2, "C052", "Tempt KFP", "C"),
new HydraPreset(52, 2, "C053", "Passing KFP", "C"),
new HydraPreset(53, 2, "C054", "NeuroPulse RJ", "C"),
new HydraPreset(54, 2, "C055", "V0KASS KFP", "C"),
new HydraPreset(55, 2, "C056", "Ancient ForestJC", "C"),
new HydraPreset(56, 2, "C057", "Ribbonvox FP", "C"),
new HydraPreset(57, 2, "C058", "Super Puncher TM", "C"),
new HydraPreset(58, 2, "C059", "Monofier ET", "C"),
new HydraPreset(59, 2, "C060", "BabaORolley PS", "C"),
new HydraPreset(60, 2, "C061", "Space Flight TM", "C"),
new HydraPreset(61, 2, "C062", "Spindles RJ", "C"),
new HydraPreset(62, 2, "C063", "RatchetPlay PS", "C"),
new HydraPreset(63, 2, "C064", "Angst KFP", "C"),
new HydraPreset(64, 2, "C065", "Evil Lurks RJ", "C"),
new HydraPreset(65, 2, "C066", "POPPIN KFP", "C"),
new HydraPreset(66, 2, "C067", "94 Zap! RJ", "C"),
new HydraPreset(67, 2, "C068", "ThickY KiKY KFP", "C"),
new HydraPreset(68, 2, "C069", "16-bit Church MF", "C"),
new HydraPreset(69, 2, "C070", "Deceptin KFP", "C"),
new HydraPreset(70, 2, "C071", "Jaunty Chapeau", "C"),
new HydraPreset(71, 2, "C072", "Arcade FP", "C"),
new HydraPreset(72, 2, "C073", "TXopolis BS", "C"),
new HydraPreset(73, 2, "C074", "Organic Waste TM", "C"),
new HydraPreset(74, 2, "C075", "Yeah Bass RJ", "C"),
new HydraPreset(75, 2, "C076", "Mallet Hang RJ", "C"),
new HydraPreset(76, 2, "C077", "BoutDat KFP", "C"),
new HydraPreset(77, 2, "C078", "Chopflip FP", "C"),
new HydraPreset(78, 2, "C079", "Drenched KFP", "C"),
new HydraPreset(79, 2, "C080", "Aluminum Birds", "C"),
new HydraPreset(80, 2, "C081", "AltTyme Pad BS", "C"),
new HydraPreset(81, 2, "C082", "DeadGrey KFP", "C"),
new HydraPreset(82, 2, "C083", "GoEAGLES KFP", "C"),
new HydraPreset(83, 2, "C084", "GlitchZ PAD KFP", "C"),
new HydraPreset(84, 2, "C085", "PressuRing PS", "C"),
new HydraPreset(85, 2, "C086", "AxiAs", "C"),
new HydraPreset(86, 2, "C087", "Dirty Machine TM", "C"),
new HydraPreset(87, 2, "C088", "PianoWarp PS", "C"),
new HydraPreset(88, 2, "C089", "Nyx Heights MF", "C"),
new HydraPreset(89, 2, "C090", "Doc's Coin DA", "C"),
new HydraPreset(90, 2, "C091", "Bangkok PS", "C"),
new HydraPreset(91, 2, "C092", "Wheelie Ring DA", "C"),
new HydraPreset(92, 2, "C093", "4gotten Lands MF", "C"),
new HydraPreset(93, 2, "C094", "Nuthras Keys KFP", "C"),
new HydraPreset(94, 2, "C095", "Here In My FP", "C"),
new HydraPreset(95, 2, "C096", "CREEPER JC", "C"),
new HydraPreset(96, 2, "C097", "Glasshouse RJ", "C"),
new HydraPreset(97, 2, "C098", "Swela KFP", "C"),
new HydraPreset(98, 2, "C099", "SimplerTines", "C"),
new HydraPreset(99, 2, "C100", "Car+Strong 3 BS", "C"),
new HydraPreset(100, 2, "C101", "NextFrontier SCD", "C"),
new HydraPreset(101, 2, "C102", "Moonlighter ET", "C"),
new HydraPreset(102, 2, "C103", "UnterVerld 1Fing", "C"),
new HydraPreset(103, 2, "C104", "Rocket Boy TM", "C"),
new HydraPreset(104, 2, "C105", "GoAhedN Shred PS", "C"),
new HydraPreset(105, 2, "C106", "ArpSwirl PS", "C"),
new HydraPreset(106, 2, "C107", "RingMod Organ TM", "C"),
new HydraPreset(107, 2, "C108", "Bustin' Good MF", "C"),
new HydraPreset(108, 2, "C109", "Moon Landing DA", "C"),
new HydraPreset(109, 2, "C110", "Crispus BS", "C"),
new HydraPreset(110, 2, "C111", "Washed Organ TM", "C"),
new HydraPreset(111, 2, "C112", "PastMe KFP", "C"),
new HydraPreset(112, 2, "C113", "Synphony FP", "C"),
new HydraPreset(113, 2, "C114", "L0M3 BS", "C"),
new HydraPreset(114, 2, "C115", "Memories ET", "C"),
new HydraPreset(115, 2, "C116", "Cybrdyne", "C"),
new HydraPreset(116, 2, "C117", "Sub Roads SCD", "C"),
new HydraPreset(117, 2, "C118", "RibbonPiano PS", "C"),
new HydraPreset(118, 2, "C119", "8 Bit Bee TM", "C"),
new HydraPreset(119, 2, "C120", "DreamOutLoud SCD", "C"),
new HydraPreset(120, 2, "C121", "From NowKFP", "C"),
new HydraPreset(121, 2, "C122", "LifeB4Yr Eyes df", "C"),
new HydraPreset(122, 2, "C123", "MeaNe KFP", "C"),
new HydraPreset(123, 2, "C124", "Throaty Vox PS", "C"),
new HydraPreset(124, 2, "C125", "PIPE ORG df", "C"),
new HydraPreset(125, 2, "C126", "Fire Ender SCD", "C"),
new HydraPreset(126, 2, "C127", "ELSA BS", "C"),
new HydraPreset(127, 2, "C128", "Eff Emm COMP df", "C"),
// Bank D
new HydraPreset(0, 3, "D001", "Neural Scan", "D"),
new HydraPreset(1, 3, "D002", "Phaezra", "D"),
new HydraPreset(2, 3, "D003", "FairVoice", "D"),
new HydraPreset(3, 3, "D004", "Panners", "D"),
new HydraPreset(4, 3, "D005", "Xpander Bass", "D"),
new HydraPreset(5, 3, "D006", "Synclavier Dive", "D"),
new HydraPreset(6, 3, "D007", "Hydra Analog Bas", "D"),
new HydraPreset(7, 3, "D008", "Romantix 88", "D"),
new HydraPreset(8, 3, "D009", "FM Arp", "D"),
new HydraPreset(9, 3, "D010", "Neon City", "D"),
new HydraPreset(10, 3, "D011", "Purest Feeling", "D"),
new HydraPreset(11, 3, "D012", "Lifeforms", "D"),
new HydraPreset(12, 3, "D013", "Zone of Twilight", "D"),
new HydraPreset(13, 3, "D014", "AtmoString", "D"),
new HydraPreset(14, 3, "D015", "Rave Talker", "D"),
new HydraPreset(15, 3, "D016", "OB Brazzer", "D"),
new HydraPreset(16, 3, "D017", "Nordic Strings", "D"),
new HydraPreset(17, 3, "D018", "Computer Worlds", "D"),
new HydraPreset(18, 3, "D019", "Woofy VA Bass", "D"),
new HydraPreset(19, 3, "D020", "Pleasure Dome", "D"),
new HydraPreset(20, 3, "D021", "Mart's PPG", "D"),
new HydraPreset(21, 3, "D022", "Xpander SloStrng", "D"),
new HydraPreset(22, 3, "D023", "Synclavier Bass", "D"),
new HydraPreset(23, 3, "D024", "Jukno 60 ARP", "D"),
new HydraPreset(24, 3, "D025", "Ulrich's", "D"),
new HydraPreset(25, 3, "D026", "Nemo Studio", "D"),
new HydraPreset(26, 3, "D027", "Notchy Stringer", "D"),
new HydraPreset(27, 3, "D028", "Digi Wave Bass", "D"),
new HydraPreset(28, 3, "D029", "PWM Poly 106 Pad", "D"),
new HydraPreset(29, 3, "D030", "Kirk & Mal 60", "D"),
new HydraPreset(30, 3, "D031", "Hit the G Bass", "D"),
new HydraPreset(31, 3, "D032", "Synthetic Vowel", "D"),
new HydraPreset(32, 3, "D033", "Hydra Pulse Clav", "D"),
new HydraPreset(33, 3, "D034", "Euro Piano Organ", "D"),
new HydraPreset(34, 3, "D035", "OB-X", "D"),
new HydraPreset(35, 3, "D036", "Comp This!", "D"),
new HydraPreset(36, 3, "D037", "Stories Of Old", "D"),
new HydraPreset(37, 3, "D038", "Talking Metal", "D"),
new HydraPreset(38, 3, "D039", "OB-X Brass Stab", "D"),
new HydraPreset(39, 3, "D040", "Video Igra", "D"),
new HydraPreset(40, 3, "D041", "OB Rez Sweep", "D"),
new HydraPreset(41, 3, "D042", "Bamboo ChopStix", "D"),
new HydraPreset(42, 3, "D043", "UK 88 ChordMemry", "D"),
new HydraPreset(43, 3, "D044", "Watery Pond", "D"),
new HydraPreset(44, 3, "D045", "Brash Bass", "D"),
new HydraPreset(45, 3, "D046", "NASA", "D"),
new HydraPreset(46, 3, "D047", "Kraftwerkian", "D"),
new HydraPreset(47, 3, "D048", "Synclavier Kalmb", "D"),
new HydraPreset(48, 3, "D049", "Helium", "D"),
new HydraPreset(49, 3, "D050", "Oranic Harmonic", "D"),
new HydraPreset(50, 3, "D051", "JP8 PWM Soft", "D"),
new HydraPreset(51, 3, "D052", "Synclavier Bell", "D"),
new HydraPreset(52, 3, "D053", "Dialtone Arp", "D"),
new HydraPreset(53, 3, "D054", "Black Celebraton", "D"),
new HydraPreset(54, 3, "D055", "Flyover", "D"),
new HydraPreset(55, 3, "D056", "Cronenberg Organ", "D"),
new HydraPreset(56, 3, "D057", "JP8 ARP", "D"),
new HydraPreset(57, 3, "D058", "FM Bass", "D"),
new HydraPreset(58, 3, "D059", "DX EP", "D"),
new HydraPreset(59, 3, "D060", "Riverbed", "D"),
new HydraPreset(60, 3, "D061", "Crystal Palace", "D"),
new HydraPreset(61, 3, "D062", "PPG Bass & Keys", "D"),
new HydraPreset(62, 3, "D063", "Astral Float", "D"),
new HydraPreset(63, 3, "D064", "Akashic Gates", "D"),
new HydraPreset(64, 3, "D065", "Lurker", "D"),
new HydraPreset(65, 3, "D066", "Belief Bass", "D"),
new HydraPreset(66, 3, "D067", "Digital EthnoLed", "D"),
new HydraPreset(67, 3, "D068", "Duracel Modular", "D"),
new HydraPreset(68, 3, "D069", "Oral Exam", "D"),
new HydraPreset(69, 3, "D070", "Rhytmus Samplus", "D"),
new HydraPreset(70, 3, "D071", "Nice Mover", "D"),
new HydraPreset(71, 3, "D072", "Forever PadStrng", "D"),
new HydraPreset(72, 3, "D073", "Cave Man", "D"),
new HydraPreset(73, 3, "D074", "TV Show", "D"),
new HydraPreset(74, 3, "D075", "Deep UniBass", "D"),
new HydraPreset(75, 3, "D076", "Friendly Arp", "D"),
new HydraPreset(76, 3, "D077", "Builder Race", "D"),
new HydraPreset(77, 3, "D078", "P5 Hello HardSnc", "D"),
new HydraPreset(78, 3, "D079", "Harpsitone", "D"),
new HydraPreset(79, 3, "D080", "Electrik Gitargh", "D"),
new HydraPreset(80, 3, "D081", "Trancer Arp", "D"),
new HydraPreset(81, 3, "D082", "Arco Pet Shop", "D"),
new HydraPreset(82, 3, "D083", "Slow Pad", "D"),
new HydraPreset(83, 3, "D084", "The Running Man", "D"),
new HydraPreset(84, 3, "D085", "Gentle Rods", "D"),
new HydraPreset(85, 3, "D086", "DCO Poly Pad", "D"),
new HydraPreset(86, 3, "D087", "Woody Tines", "D"),
new HydraPreset(87, 3, "D088", "Whispers", "D"),
new HydraPreset(88, 3, "D089", "Sunrise FM", "D"),
new HydraPreset(89, 3, "D090", "Synclav Organ", "D"),
new HydraPreset(90, 3, "D091", "80's Bass", "D"),
new HydraPreset(91, 3, "D092", "Shaarrrp", "D"),
new HydraPreset(92, 3, "D093", "Ice Haus", "D"),
new HydraPreset(93, 3, "D094", "Magnetic Equinox", "D"),
new HydraPreset(94, 3, "D095", "Alpha Keys", "D"),
new HydraPreset(95, 3, "D096", "Breaded Butter", "D"),
new HydraPreset(96, 3, "D097", "Sync Risky Biz", "D"),
new HydraPreset(97, 3, "D098", "Glassy Fifths", "D"),
new HydraPreset(98, 3, "D099", "Brass Bars", "D"),
new HydraPreset(99, 3, "D100", "Moag Bass", "D"),
new HydraPreset(100, 3, "D101", "Cutting Dbl Stab", "D"),
new HydraPreset(101, 3, "D102", "Forrests", "D"),
new HydraPreset(102, 3, "D103", "WaveSweep", "D"),
new HydraPreset(103, 3, "D104", "Bird on a Wire", "D"),
new HydraPreset(104, 3, "D105", "Mouth Area Lead", "D"),
new HydraPreset(105, 3, "D106", "Rubbing Glass", "D"),
new HydraPreset(106, 3, "D107", "1 Os Bass", "D"),
new HydraPreset(107, 3, "D108", "Compass Point", "D"),
new HydraPreset(108, 3, "D109", "Double Impact", "D"),
new HydraPreset(109, 3, "D110", "Christmas Island", "D"),
new HydraPreset(110, 3, "D111", "Shar Bass", "D"),
new HydraPreset(111, 3, "D112", "Sizzler", "D"),
new HydraPreset(112, 3, "D113", "DCO Chord Arp", "D"),
new HydraPreset(113, 3, "D114", "Spreader", "D"),
new HydraPreset(114, 3, "D115", "OB Keys", "D"),
new HydraPreset(115, 3, "D116", "Sound Designer", "D"),
new HydraPreset(116, 3, "D117", "Deep Diver", "D"),
new HydraPreset(117, 3, "D118", "File Under X", "D"),
new HydraPreset(118, 3, "D119", "Noisy Gallop", "D"),
new HydraPreset(119, 3, "D120", "DigiClav", "D"),
new HydraPreset(120, 3, "D121", "Akordian", "D"),
new HydraPreset(121, 3, "D122", "Sub Mission", "D"),
new HydraPreset(122, 3, "D123", "Steel Keys", "D"),
new HydraPreset(123, 3, "D124", "Bad Dream Orchs", "D"),
new HydraPreset(124, 3, "D125", "DX Pad", "D"),
new HydraPreset(125, 3, "D126", "Ugly Bass Arp", "D"),
new HydraPreset(126, 3, "D127", "Gated Vox", "D"),
new HydraPreset(127, 3, "D128", "Patches byINHALT", "D"),
// Bank E
new HydraPreset(0, 4, "E001", "Northern Heat RA", "E"),
new HydraPreset(1, 4, "E002", "Nordlandsbane RA", "E"),
new HydraPreset(2, 4, "E003", "Polar Diva RA", "E"),
new HydraPreset(3, 4, "E004", "M12 XyloPad RA", "E"),
new HydraPreset(4, 4, "E005", "E-mu Orchasm RA", "E"),
new HydraPreset(5, 4, "E006", "VCO Polydream RA", "E"),
new HydraPreset(6, 4, "E007", "Dewey Dawn RA", "E"),
new HydraPreset(7, 4, "E008", "Forever Young RA", "E"),
new HydraPreset(8, 4, "E009", "Alpine Strngs RA", "E"),
new HydraPreset(9, 4, "E010", "Glocken Tams RA", "E"),
new HydraPreset(10, 4, "E011", "M12 WinterSun RA", "E"),
new HydraPreset(11, 4, "E012", "OB DX Cello RA", "E"),
new HydraPreset(12, 4, "E013", "Bear Island RA", "E"),
new HydraPreset(13, 4, "E014", "AtlanticRealm RA", "E"),
new HydraPreset(14, 4, "E015", "Bit99 Slowpad RA", "E"),
new HydraPreset(15, 4, "E016", "Stereo Poly6 RA", "E"),
new HydraPreset(16, 4, "E017", "Vinterpiano RA", "E"),
new HydraPreset(17, 4, "E018", "Alpine Split RA", "E"),
new HydraPreset(18, 4, "E019", "Jutulhogg RA", "E"),
new HydraPreset(19, 4, "E020", "Space Days RA", "E"),
new HydraPreset(20, 4, "E021", "Squear Bass RA", "E"),
new HydraPreset(21, 4, "E022", "Poly6 UnisBas RA", "E"),
new HydraPreset(22, 4, "E023", "2600 Bass Rez RA", "E"),
new HydraPreset(23, 4, "E024", "Basto Ferry RA", "E"),
new HydraPreset(24, 4, "E025", "Hybridene RA", "E"),
new HydraPreset(25, 4, "E026", "Vaarpiano RA", "E"),
new HydraPreset(26, 4, "E027", "Bit99 Sweep RA", "E"),
new HydraPreset(27, 4, "E028", "ASM-101 Bass RA", "E"),
new HydraPreset(28, 4, "E029", "Spider Dust RA", "E"),
new HydraPreset(29, 4, "E030", "Summer Bass RA", "E"),
new HydraPreset(30, 4, "E031", "Delay Line RA", "E"),
new HydraPreset(31, 4, "E032", "A Bit of cold RA", "E"),
new HydraPreset(32, 4, "E033", "Lazer Harp RA", "E"),
new HydraPreset(33, 4, "E034", "2600 Rings RA", "E"),
new HydraPreset(34, 4, "E035", "OB PWMclassic RA", "E"),
new HydraPreset(35, 4, "E036", "Old Prophet RA", "E"),
new HydraPreset(36, 4, "E037", "Bit99 Resopad RA", "E"),
new HydraPreset(37, 4, "E038", "Poly Evolved RA", "E"),
new HydraPreset(38, 4, "E039", "Aqua Vita RA", "E"),
new HydraPreset(39, 4, "E040", "Poly6 Seaflur RA", "E"),
new HydraPreset(40, 4, "E041", "Prophet Bells RA", "E"),
new HydraPreset(41, 4, "E042", "Prophet Tines RA", "E"),
new HydraPreset(42, 4, "E043", "Below RA", "E"),
new HydraPreset(43, 4, "E044", "OB Bandpad RA", "E"),
new HydraPreset(44, 4, "E045", "OB UnisonBand RA", "E"),
new HydraPreset(45, 4, "E046", "OB 99 Ballons RA", "E"),
new HydraPreset(46, 4, "E047", "SynthX RingMd RA", "E"),
new HydraPreset(47, 4, "E048", "M12 Layers RA", "E"),
new HydraPreset(48, 4, "E049", "JX PulsePad RA", "E"),
new HydraPreset(49, 4, "E050", "Mare Nubium RA", "E"),
new HydraPreset(50, 4, "E051", "JX Slaw RA", "E"),
new HydraPreset(51, 4, "E052", "SH Reso Bass RA", "E"),
new HydraPreset(52, 4, "E053", "SH Resequence RA", "E"),
new HydraPreset(53, 4, "E054", "Plastic Pearl RA", "E"),
new HydraPreset(54, 4, "E055", "MurmanskStringRA", "E"),
new HydraPreset(55, 4, "E056", "OB IntroSound RA", "E"),
new HydraPreset(56, 4, "E057", "Tirpitz RA", "E"),
new HydraPreset(57, 4, "E058", "Arp Afternoon RA", "E"),
new HydraPreset(58, 4, "E059", "OB SAW RA", "E"),
new HydraPreset(59, 4, "E060", "Pseiko DS-310 RA", "E"),
new HydraPreset(60, 4, "E061", "M12 SoftStrng RA", "E"),
new HydraPreset(61, 4, "E062", "Poly6 Sub Arp RA", "E"),
new HydraPreset(62, 4, "E063", "Snow Cave RA", "E"),
new HydraPreset(63, 4, "E064", "Snowflower RA", "E"),
new HydraPreset(64, 4, "E065", "Art Deco RA", "E"),
new HydraPreset(65, 4, "E066", "Noisy Poly6 RA", "E"),
new HydraPreset(66, 4, "E067", "Bit99 Saw RA", "E"),
new HydraPreset(67, 4, "E068", "Bit99 Ephemra RA", "E"),
new HydraPreset(68, 4, "E069", "Analog Women RA", "E"),
new HydraPreset(69, 4, "E070", "Analog Men RA", "E"),
new HydraPreset(70, 4, "E071", "Bit99 Bass RA", "E"),
new HydraPreset(71, 4, "E072", "Haltenbank RA", "E"),
new HydraPreset(72, 4, "E073", "Atlas RA", "E"),
new HydraPreset(73, 4, "E074", "Lunar Wind RA", "E"),
new HydraPreset(74, 4, "E075", "Greener Left RA", "E"),
new HydraPreset(75, 4, "E076", "Greener Right RA", "E"),
new HydraPreset(76, 4, "E077", "Cosmosynth RA", "E"),
new HydraPreset(77, 4, "E078", "LassooMrsLuna RA", "E"),
new HydraPreset(78, 4, "E079", "OB Saw Pulse RA", "E"),
new HydraPreset(79, 4, "E080", "JX Pulsewarm RA", "E"),
new HydraPreset(80, 4, "E081", "Autumn '86 RA", "E"),
new HydraPreset(81, 4, "E082", "StringsForSki RA", "E"),
new HydraPreset(82, 4, "E083", "Half Moon RA", "E"),
new HydraPreset(83, 4, "E084", "Air Vent RA", "E"),
new HydraPreset(84, 4, "E085", "Barentsburg RA", "E"),
new HydraPreset(85, 4, "E086", "Blizzard RA", "E"),
new HydraPreset(86, 4, "E087", "Winterfilter RA", "E"),
new HydraPreset(87, 4, "E088", "Mountain Birk RA", "E"),
new HydraPreset(88, 4, "E089", "Suartisen RA", "E"),
new HydraPreset(89, 4, "E090", "Dolce Vita RA", "E"),
new HydraPreset(90, 4, "E091", "Mouge Piano RA", "E"),
new HydraPreset(91, 4, "E092", "Mouge Police RA", "E"),
new HydraPreset(92, 4, "E093", "JP-IV RA", "E"),
new HydraPreset(93, 4, "E094", "Hoesten RA", "E"),
new HydraPreset(94, 4, "E095", "Celestial OB RA", "E"),
new HydraPreset(95, 4, "E096", "Soft Strings RA", "E"),
new HydraPreset(96, 4, "E097", "Reso Pad RA", "E"),
new HydraPreset(97, 4, "E098", "Three Sisters RA", "E"),
new HydraPreset(98, 4, "E099", "Irlande RA", "E"),
new HydraPreset(99, 4, "E100", "Leutenhaven RA", "E"),
new HydraPreset(100, 4, "E101", "Bit99pulsesaw RA", "E"),
new HydraPreset(101, 4, "E102", "OB PWM RA", "E"),
new HydraPreset(102, 4, "E103", "Lunar Choir RA", "E"),
new HydraPreset(103, 4, "E104", "IcefjordSweep RA", "E"),
new HydraPreset(104, 4, "E105", "Poly6 Pad RA", "E"),
new HydraPreset(105, 4, "E106", "Poly6 Strings RA", "E"),
new HydraPreset(106, 4, "E107", "Bass-Ace RA", "E"),
new HydraPreset(107, 4, "E108", "OB Poly PWM RA", "E"),
new HydraPreset(108, 4, "E109", "Bob Bass RA", "E"),
new HydraPreset(109, 4, "E110", "Pulse RA", "E"),
new HydraPreset(110, 4, "E111", "Slap Cod RA", "E"),
new HydraPreset(111, 4, "E112", "Seastrings RA", "E"),
new HydraPreset(112, 4, "E113", "Glittertind RA", "E"),
new HydraPreset(113, 4, "E114", "Berlevaag RA", "E"),
new HydraPreset(114, 4, "E115", "SouthernBreez RA", "E"),
new HydraPreset(115, 4, "E116", "Liquid E-mu RA", "E"),
new HydraPreset(116, 4, "E117", "Electroangels RA", "E"),
new HydraPreset(117, 4, "E118", "VCO OctaveSaw RA", "E"),
new HydraPreset(118, 4, "E119", "PhasingModwhl RA", "E"),
new HydraPreset(119, 4, "E120", "Emax Passage RA", "E"),
new HydraPreset(120, 4, "E121", "L`apocalypse RA", "E"),
new HydraPreset(121, 4, "E122", "Icicles RA", "E"),
new HydraPreset(122, 4, "E123", "SilverminePad RA", "E"),
new HydraPreset(123, 4, "E124", "Lo-fi sweep RA", "E"),
new HydraPreset(124, 4, "E125", "Saw Door RA", "E"),
new HydraPreset(125, 4, "E126", "Sub Tempest", "E"),
new HydraPreset(126, 4, "E127", "Reverb Spring RA", "E"),
new HydraPreset(127, 4, "E128", "Patches by RA", "E")
] @=> static HydraPreset @ hydraPresets[];

}

// Hydrasynth is a class that represents a Hydrasynth MIDI device in the framework.
// It extends Patch and adds a preset name.
//
// This class is used to create Hydrasynth patches for MIDI devices.
public class Hydrasynth extends Patch
{
    string presetName;

    fun Hydrasynth()
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        0 => midiChannel;
        "A001" => presetName;
        "Sawpressive GD" => patchName;
        0 => bank;
        0 => program;
    }

    fun Hydrasynth(string preset, int v)
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        0 => midiChannel;
        resolvePreset(preset);
        Patch(v);
    }

    fun Hydrasynth(int channel, string preset, int v)
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        channel - 1 => midiChannel;
        resolvePreset(preset);
        Patch(v);
    }

    fun void resolvePreset(string preset)
    {
        if (preset == "" || preset == "default") {
            preset => presetName;
            preset => patchName;
            -1 => program;
            -1 => bank;
            return;
        }
        HydraPresetCollection collection;
        if (collection.hasPreset(preset)) {
            collection.getPreset(preset) @=> HydraPreset @ p;
            p.program => program;
            p.bank => bank;
            p.code => presetName;
            p.name => patchName;
        } else if (preset.length() >= 2) {
            preset => presetName;
            preset => patchName;
            preset.substring(0, 1) => string bankStr;
            preset.substring(1) => string programStr;
            bankStr.charAt(0) - "A".charAt(0) => bank;
            programStr.toInt() - 1 => program;
        } else {
            preset => presetName;
            preset => patchName;
            -1 => program;
            -1 => bank;
        }
    }

    fun void setPreset()
    {
        if (bank >= 0 && program >= 0) 
        {
            programChangeHydra(program, bank);
        }
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetString("presetName", presetName);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        openDevice();
        "" => string savedPreset;
        if (config.findChild("presetName") >= 0) {
            config.GetString("presetName") => savedPreset;
        }
        HydraPresetCollection collection;
        if (patchName != "" && patchName != savedPreset && collection.hasPreset(patchName)) {
            resolvePreset(patchName);
        } else if (savedPreset != "" && collection.hasPreset(savedPreset)) {
            resolvePreset(savedPreset);
        } else if (patchName != "") {
            resolvePreset(patchName);
        } else if (savedPreset != "") {
            resolvePreset(savedPreset);
        } else {
            resolvePreset("A001");
        }
        updateControllers();
    }
}

// MoogMessenger is a class that represents a Moog Messenger MIDI device in the framework.
// It extends Patch and uses the same bank/program MIDI sequence as Hydrasynth (CC0/CC32 + program change).
//
// bank is 0-based (same as Hydrasynth letter banks: A=0, B=1, ...). program is 1-based (1-128), matching
// the numeric part of a Hydrasynth preset string.
public class MoogMessenger extends Patch
{
    fun MoogMessenger()
    {
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        0 => midiChannel;
        0 => bank;
        0 => program;
        "Bank: 1 Program: 1" => patchName;
    }

    fun MoogMessenger(int channel, int bank, int program, int v)
    {
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        channel - 1 => midiChannel;
        bank - 1 => this.bank;
        program  - 1 => this.program;
        "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        Patch(v);
    }

    fun void programChangeMoogMessenger(int program, int bank)
    {
        MidiMsg msg;
        0xC0 | midiChannel => msg.data1;
        program => msg.data2;
        0 => msg.data3;
        gma.send(msg);
    }
    
    fun void setPreset()
    {
    }


    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        } else {
            0 => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        } else {
            0 => bank;
        }
        if (patchName == "") {
            "Bank: " + Std.itoa(bank + 1) + " Program: " + Std.itoa(program + 1) => patchName;
        }
        updateControllers();
    }
}


// RolandS1 is a class that represents a Roland S-1 MIDI device in the framework.
// It extends Patch and adds a program and bank.
//
// This class is used to create Roland S-1 patches for MIDI devices.
public class RolandS1 extends Patch
{
    fun RolandS1()
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        2 => midiChannel;
        1 => program;
        1 => bank;
        "Bank: 1 Program: 1" => patchName;
    }

    fun RolandS1(int b, int p, int v)
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        2 => midiChannel;
        p => program;
        b => bank;
        "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        Patch(-1);
    }

    fun RolandS1(int channel, int b, int p, int v)
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        Patch(v);
    }

    fun void setPreset()
    {
        (bank - 1) * 16 + program - 1 => int preset; 
        programChangeS1(preset);
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        } else {
            1 => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        } else {
            1 => bank;
        }
        if (program < 1) { 1 => program; }
        if (bank < 1) { 1 => bank; }
        if (patchName == "") {
            "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        }
        updateControllers();
    }
}

// SH4dPreset is a class that represents a Roland SH-4d tone preset in the framework.
// It contains the program (0-based PC), bank (LSB 64-77; MSB is always 88), name, and category (OSC model).
public class SH4dPreset
{
    int program;
    int bank;
    string name;
    string category;
    fun SH4dPreset(int p, int b, string n, string cat) {
        p => program;
        b => bank;
        n => name;
        cat => category;
    }
}

// SH4dPresetCollection is a class that represents a collection of Roland SH-4d tone presets in the framework.
public class SH4dPresetCollection
{
    int curPresetIndex;
    string curPresetCategory;

    fun SH4dPresetCollection()
    {
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun SH4dPreset getNextPreset()
    {
        (curPresetIndex + 1) % sh4dPresets.cap() => curPresetIndex;
        sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun SH4dPreset getPreviousPreset()
    {
        ((curPresetIndex - 1) + sh4dPresets.cap()) % sh4dPresets.cap() => curPresetIndex;
        sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun SH4dPreset getNextCategory()
    {
        for (curPresetIndex + 1 => int i; i < sh4dPresets.cap(); i++) {
            if (sh4dPresets[i].category != curPresetCategory) {
                i => curPresetIndex;
                sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        0 => curPresetIndex;
        sh4dPresets[0] @=> SH4dPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun SH4dPreset getPreviousCategory()
    {
        for (curPresetIndex => int i; i >= 0; i--) {
            if (sh4dPresets[i].category != curPresetCategory) {
                i => curPresetIndex;
                sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        sh4dPresets.cap() - 1 => curPresetIndex;
        sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun string normalizePresetName(string s)
    {
        s => string copy;
        copy.replace("\"", "'");
        return copy;
    }

    fun int hasPreset(string presetName)
    {
        if (presetName == "") return false;
        normalizePresetName(presetName) => string norm;
        for (SH4dPreset preset : sh4dPresets) {
            if (preset.name == presetName || preset.name == norm) {
                return true;
            }
        }
        return false;
    }

    fun int matchesPreset(string presetName, int b, int p)
    {
        if (presetName == "" || b < 0 || p < 0) return false;
        normalizePresetName(presetName) => string norm;
        for (SH4dPreset preset : sh4dPresets) {
            if ((preset.name == presetName || preset.name == norm) && preset.bank == b && preset.program == p) {
                return true;
            }
        }
        return false;
    }

    fun SH4dPreset getPreset(string presetName)
    {
        normalizePresetName(presetName) => string norm;
        if (curPresetCategory != "") {
            for (SH4dPreset preset : sh4dPresets) {
                if (preset.category == curPresetCategory && (preset.name == presetName || preset.name == norm))
                    return preset;
            }
        }
        for (SH4dPreset preset : sh4dPresets) {
            if (preset.name == presetName || preset.name == norm)
                return preset;
        }
        <<< "Can't find SH-4d preset: ", presetName >>>;
        return sh4dPresets[0];
    }

    fun SH4dPreset getPreset(int b, int p)
    {
        for (SH4dPreset preset : sh4dPresets) {
            if (preset.bank == b && preset.program == p)
                return preset;
        }
        return null;
    }

    fun void setPresetState(string presetName)
    {
        normalizePresetName(presetName) => string norm;
        if (curPresetCategory != "") {
            for (0 => int i; i < sh4dPresets.cap(); i++) {
                if (sh4dPresets[i].category == curPresetCategory && (sh4dPresets[i].name == presetName || sh4dPresets[i].name == norm)) {
                    i => curPresetIndex;
                    sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
                    preset.category @=> curPresetCategory;
                    return;
                }
            }
        }
        for (0 => int i; i < sh4dPresets.cap(); i++) {
            if (sh4dPresets[i].name == presetName || sh4dPresets[i].name == norm) {
                i => curPresetIndex;
                sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
                preset.category @=> curPresetCategory;
                return;
            }
        }
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun void setPresetState(string presetName, int b, int p)
    {
        if (b >= 0 && p >= 0) {
            for (0 => int i; i < sh4dPresets.cap(); i++) {
                if (sh4dPresets[i].bank == b && sh4dPresets[i].program == p) {
                    i => curPresetIndex;
                    sh4dPresets[curPresetIndex] @=> SH4dPreset preset;
                    preset.category @=> curPresetCategory;
                    return;
                }
            }
        }
        setPresetState(presetName);
    }

[
new SH4dPreset(0, 64, "Brilliant", "SH-4d OSC model"),
new SH4dPreset(1, 64, "Synth Bass 1", "SH-4d OSC model"),
new SH4dPreset(2, 64, "Synth Lead 1", "SH-4d OSC model"),
new SH4dPreset(3, 64, "Willkommen!", "SH-4d OSC model"),
new SH4dPreset(4, 64, "November 2019", "SH-4d OSC model"),
new SH4dPreset(5, 64, "CollapsedCircuit", "SH-4d OSC model"),
new SH4dPreset(6, 64, "Echoes from Eons", "SH-4d OSC model"),
new SH4dPreset(7, 64, "SK Seqsy Pluck", "SH-4d OSC model"),
new SH4dPreset(8, 64, "1901 Bass", "SH-4d OSC model"),
new SH4dPreset(9, 64, "JU OSC 7th Stack", "SH-4d OSC model"),
new SH4dPreset(10, 64, "Undulation Rate", "SH-4d OSC model"),
new SH4dPreset(11, 64, "28 Saw Hit & Run", "SH-4d OSC model"),
new SH4dPreset(12, 64, "Brasscal", "SH-4d OSC model"),
new SH4dPreset(13, 64, "Recently Bass", "SH-4d OSC model"),
new SH4dPreset(14, 64, "Bend Chord", "SH-4d OSC model"),
new SH4dPreset(15, 64, "Wheel Drums", "SH-4d OSC model"),
new SH4dPreset(16, 64, "Mod Apart Pluck", "SH-4d OSC model"),
new SH4dPreset(17, 64, "Cinematic", "SH-4d OSC model"),
new SH4dPreset(18, 64, "SH-4d Pulse", "SH-4d OSC model"),
new SH4dPreset(19, 64, "Minor Riser", "SH-4d OSC model"),
new SH4dPreset(20, 64, "Dark Wave", "SH-4d OSC model"),
new SH4dPreset(21, 64, "Pls Arpg Me <3", "SH-4d OSC model"),
new SH4dPreset(22, 64, "Fragile Pad", "SH-4d OSC model"),
new SH4dPreset(23, 64, "Double JX Pad", "SH-4d OSC model"),
new SH4dPreset(24, 64, "Inf Down", "SH-4d OSC model"),
new SH4dPreset(25, 64, "Rotary Organ", "SH-4d OSC model"),
new SH4dPreset(26, 64, "5th Stack Lead", "SH-4d OSC model"),
new SH4dPreset(27, 64, "Brite Syn Brass", "SH-4d OSC model"),
new SH4dPreset(28, 64, "Switch On", "SH-4d OSC model"),
new SH4dPreset(29, 64, "Super Super", "SH-4d OSC model"),
new SH4dPreset(30, 64, "Strange Point", "SH-4d OSC model"),
new SH4dPreset(31, 64, "Synth Hall", "SH-4d OSC model"),
new SH4dPreset(32, 64, "7 Lead", "SH-4d OSC model"),
new SH4dPreset(33, 64, "Kick LFO Bass 2", "SH-4d OSC model"),
new SH4dPreset(34, 64, "PulseStack Stab1", "SH-4d OSC model"),
new SH4dPreset(35, 64, "PulseStack Stab2", "SH-4d OSC model"),
new SH4dPreset(36, 64, "Perfect Rise", "SH-4d OSC model"),
new SH4dPreset(37, 64, "Alternate", "SH-4d OSC model"),
new SH4dPreset(38, 64, "Progressive Plk", "SH-4d OSC model"),
new SH4dPreset(39, 64, "Pulsating Pad", "SH-4d OSC model"),
new SH4dPreset(40, 64, "Matrix Sweep FX", "SH-4d OSC model"),
new SH4dPreset(41, 64, "Step F Lead", "SH-4d OSC model"),
new SH4dPreset(42, 64, "PsyTrance Bass 2", "SH-4d OSC model"),
new SH4dPreset(43, 64, "Electro Bow", "SH-4d OSC model"),
new SH4dPreset(44, 64, "808 Long Bass", "SH-4d OSC model"),
new SH4dPreset(45, 64, "Black Hole Pluck", "SH-4d OSC model"),
new SH4dPreset(46, 64, "Techy Stab", "SH-4d OSC model"),
new SH4dPreset(47, 64, "Saw&Pulse Bass", "SH-4d OSC model"),
new SH4dPreset(48, 64, "Synth Pad/Str 1", "SH-4d OSC model"),
new SH4dPreset(49, 64, "Synth Pad/Str 2", "SH-4d OSC model"),
new SH4dPreset(50, 64, "Synth Pad/Str 3", "SH-4d OSC model"),
new SH4dPreset(51, 64, "Synth Pad/Str 4", "SH-4d OSC model"),
new SH4dPreset(52, 64, "Synth Pad/Str 5", "SH-4d OSC model"),
new SH4dPreset(53, 64, "Synth Pad/Str 6", "SH-4d OSC model"),
new SH4dPreset(54, 64, "Synth PolyKey 1", "SH-4d OSC model"),
new SH4dPreset(55, 64, "Synth PolyKey 2", "SH-4d OSC model"),
new SH4dPreset(56, 64, "Synth Lead 2", "SH-4d OSC model"),
new SH4dPreset(57, 64, "Synth Bass 2", "SH-4d OSC model"),
new SH4dPreset(58, 64, "Synth Bass 3", "SH-4d OSC model"),
new SH4dPreset(59, 64, "Synth Pad/Str 7", "SH-4d OSC model"),
new SH4dPreset(60, 64, "Synth Pad/Str 8", "SH-4d OSC model"),
new SH4dPreset(61, 64, "Synth Pad/Str 9", "SH-4d OSC model"),
new SH4dPreset(62, 64, "Pulsating 1", "SH-4d OSC model"),
new SH4dPreset(63, 64, "Synth Pad/Str 10", "SH-4d OSC model"),
new SH4dPreset(64, 64, "Synth Pad/Str 11", "SH-4d OSC model"),
new SH4dPreset(65, 64, "Synth Pad/Str 12", "SH-4d OSC model"),
new SH4dPreset(66, 64, "Synth Pad/Str 13", "SH-4d OSC model"),
new SH4dPreset(67, 64, "Synth Pad/Str 14", "SH-4d OSC model"),
new SH4dPreset(68, 64, "Synth Pad/Str 15", "SH-4d OSC model"),
new SH4dPreset(69, 64, "Bell 1", "SH-4d OSC model"),
new SH4dPreset(70, 64, "Synth Brass 1", "SH-4d OSC model"),
new SH4dPreset(71, 64, "Synth Bass 4", "SH-4d OSC model"),
new SH4dPreset(72, 64, "Synth Bass 5", "SH-4d OSC model"),
new SH4dPreset(73, 64, "Synth Bass 6", "SH-4d OSC model"),
new SH4dPreset(74, 64, "Synth PolyKey 3", "SH-4d OSC model"),
new SH4dPreset(75, 64, "Bell 2", "SH-4d OSC model"),
new SH4dPreset(76, 64, "Synth Lead 3", "SH-4d OSC model"),
new SH4dPreset(77, 64, "Synth Lead 4", "SH-4d OSC model"),
new SH4dPreset(78, 64, "Synth Lead 5", "SH-4d OSC model"),
new SH4dPreset(79, 64, "Synth Lead 6", "SH-4d OSC model"),
new SH4dPreset(80, 64, "Synth Bass 7", "SH-4d OSC model"),
new SH4dPreset(81, 64, "Synth Seq/Pop 1", "SH-4d OSC model"),
new SH4dPreset(82, 64, "Pulsating 2", "SH-4d OSC model"),
new SH4dPreset(83, 64, "Synth FX 1", "SH-4d OSC model"),
new SH4dPreset(84, 64, "Synth FX 2", "SH-4d OSC model"),
new SH4dPreset(85, 64, "Chordy Pants", "SH-4d OSC model"),
new SH4dPreset(86, 64, "Tube FX", "SH-4d OSC model"),
new SH4dPreset(87, 64, "Quad Saw", "SH-4d OSC model"),
new SH4dPreset(88, 64, "Synth Lead 7", "SH-4d OSC model"),
new SH4dPreset(89, 64, "Synth Bass 8", "SH-4d OSC model"),
new SH4dPreset(90, 64, "Synth PolyKey 4", "SH-4d OSC model"),
new SH4dPreset(91, 64, "Heavy J Pluck", "SH-4d OSC model"),
new SH4dPreset(92, 64, "LongStory2B Hold", "SH-4d OSC model"),
new SH4dPreset(93, 64, "Jovian Strings", "SH-4d OSC model"),
new SH4dPreset(94, 64, "Additive 4 Bass", "SH-4d OSC model"),
new SH4dPreset(95, 64, "Yuya Bass R4", "SH-4d OSC model"),
new SH4dPreset(96, 64, "Phoenix Pf", "SH-4d OSC model"),
new SH4dPreset(97, 64, "Asimov Bots", "SH-4d OSC model"),
new SH4dPreset(98, 64, "14 Saw OctUnison", "SH-4d OSC model"),
new SH4dPreset(99, 64, "NeoWorldSymphony", "SH-4d OSC model"),
new SH4dPreset(100, 64, "Tweak Box", "SH-4d OSC model"),
new SH4dPreset(101, 64, "Modul Arpg", "SH-4d OSC model"),
new SH4dPreset(102, 64, "Bubble Boy", "SH-4d OSC model"),
new SH4dPreset(103, 64, "2 Many Cables", "SH-4d OSC model"),
new SH4dPreset(104, 64, "Melancholy", "SH-4d OSC model"),
new SH4dPreset(105, 64, "Smooth Fat", "SH-4d OSC model"),
new SH4dPreset(106, 64, "Liquid Stab", "SH-4d OSC model"),
new SH4dPreset(107, 64, "Simple Pluck", "SH-4d OSC model"),
new SH4dPreset(108, 64, "Cacophony Stack", "SH-4d OSC model"),
new SH4dPreset(109, 64, "Dirty SSaws", "SH-4d OSC model"),
new SH4dPreset(110, 64, "Sidechain SSaws", "SH-4d OSC model"),
new SH4dPreset(111, 64, "Super Square!", "SH-4d OSC model"),
new SH4dPreset(112, 64, "Super Pluck", "SH-4d OSC model"),
new SH4dPreset(113, 64, "Saw Delay", "SH-4d OSC model"),
new SH4dPreset(114, 64, "Standard Lead", "SH-4d OSC model"),
new SH4dPreset(115, 64, "HPF Lead", "SH-4d OSC model"),
new SH4dPreset(116, 64, "HPF Sweep Pad", "SH-4d OSC model"),
new SH4dPreset(117, 64, "Ya-I", "SH-4d OSC model"),
new SH4dPreset(118, 64, "Saw Oct Stack Bs", "SH-4d OSC model"),
new SH4dPreset(119, 64, "7th Stack Lead", "SH-4d OSC model"),
new SH4dPreset(120, 64, "Phaser Pad", "SH-4d OSC model"),
new SH4dPreset(121, 64, "Flanger Pad", "SH-4d OSC model"),
new SH4dPreset(122, 64, "S-Saw Stack Key", "SH-4d OSC model"),
new SH4dPreset(123, 64, "Solid Lead", "SH-4d OSC model"),
new SH4dPreset(124, 64, "Buzz Lead", "SH-4d OSC model"),
new SH4dPreset(125, 64, "Saw Stack Stab", "SH-4d OSC model"),
new SH4dPreset(126, 64, "Silent Lead", "SH-4d OSC model"),
new SH4dPreset(127, 64, "Bit Force", "SH-4d OSC model"),
new SH4dPreset(0, 65, "Rumors Bass", "SH-4d OSC model"),
new SH4dPreset(1, 65, "Analog Magic", "SH-4d OSC model"),
new SH4dPreset(2, 65, "Kick LFO Bass 1", "SH-4d OSC model"),
new SH4dPreset(3, 65, "Bit Bass", "SH-4d OSC model"),
new SH4dPreset(4, 65, "Bit Bass SQ", "SH-4d OSC model"),
new SH4dPreset(5, 65, "B Pluck", "SH-4d OSC model"),
new SH4dPreset(6, 65, "BP Wide", "SH-4d OSC model"),
new SH4dPreset(7, 65, "7 Lead P", "SH-4d OSC model"),
new SH4dPreset(8, 65, "PWM SQ", "SH-4d OSC model"),
new SH4dPreset(9, 65, "Tri Kick Bass", "SH-4d OSC model"),
new SH4dPreset(10, 65, "Analog Stab", "SH-4d OSC model"),
new SH4dPreset(11, 65, "Happy Lead", "SH-4d OSC model"),
new SH4dPreset(12, 65, "SuperSaw Pad", "SH-4d OSC model"),
new SH4dPreset(13, 65, "LoFi Ravy", "SH-4d OSC model"),
new SH4dPreset(14, 65, "US House Bass", "SH-4d OSC model"),
new SH4dPreset(15, 65, "JUNO Reso Pad", "SH-4d OSC model"),
new SH4dPreset(16, 65, "SSaw&Sine Pad", "SH-4d OSC model"),
new SH4dPreset(17, 65, "Quad Color", "SH-4d OSC model"),
new SH4dPreset(18, 65, "Sunset Pad", "SH-4d OSC model"),
new SH4dPreset(19, 65, "Fall Down FX", "SH-4d OSC model"),
new SH4dPreset(20, 65, "4D Stab", "SH-4d OSC model"),
new SH4dPreset(21, 65, "Fly High Pad", "SH-4d OSC model"),
new SH4dPreset(22, 65, "PsyTrance Bass 1", "SH-4d OSC model"),
new SH4dPreset(23, 65, "Pop Pop Sqr", "SH-4d OSC model"),
new SH4dPreset(24, 65, "Noise Impact", "SH-4d OSC model"),
new SH4dPreset(25, 65, "808 Bass", "SH-4d OSC model"),
new SH4dPreset(26, 65, "Trance Chord", "SH-4d OSC model"),
new SH4dPreset(27, 65, "Saw&Noise Pluck", "SH-4d OSC model"),
new SH4dPreset(28, 65, "Epic Pluck", "SH-4d OSC model"),
new SH4dPreset(29, 65, "Wow!!", "SH-4d OSC model"),
new SH4dPreset(30, 65, "Sine Lead", "SH-4d OSC model"),
new SH4dPreset(31, 65, "Soft Syn Brass", "SH-4d OSC model"),
new SH4dPreset(32, 65, "Siren", "SH-4d OSC model"),
new SH4dPreset(33, 65, "Rituals", "SH-4d OSC model"),
new SH4dPreset(34, 65, "Wind Wave 1", "SH-4d OSC model"),
new SH4dPreset(35, 65, "Whistle", "SH-4d OSC model"),
new SH4dPreset(36, 65, "Wah Keys", "SH-4d OSC model"),
new SH4dPreset(37, 65, "Round Bass", "SH-4d OSC model"),
new SH4dPreset(38, 65, "Bass Saw", "SH-4d OSC model"),
new SH4dPreset(39, 65, "Synth Pad/Str 16", "SH-4d OSC model"),
new SH4dPreset(40, 65, "Synth Pad/Str 17", "SH-4d OSC model"),
new SH4dPreset(41, 65, "Synth Pad/Str 18", "SH-4d OSC model"),
new SH4dPreset(42, 65, "Synth Pad/Str 19", "SH-4d OSC model"),
new SH4dPreset(43, 65, "Synth Pad/Str 20", "SH-4d OSC model"),
new SH4dPreset(44, 65, "Synth Pad/Str 21", "SH-4d OSC model"),
new SH4dPreset(45, 65, "Synth Pad/Str 22", "SH-4d OSC model"),
new SH4dPreset(46, 65, "Synth Pad/Str 23", "SH-4d OSC model"),
new SH4dPreset(47, 65, "Synth Pad/Str 24", "SH-4d OSC model"),
new SH4dPreset(48, 65, "Synth Pad/Str 25", "SH-4d OSC model"),
new SH4dPreset(49, 65, "Synth Pad/Str 26", "SH-4d OSC model"),
new SH4dPreset(50, 65, "Synth Pad/Str 27", "SH-4d OSC model"),
new SH4dPreset(51, 65, "Synth Pad/Str 28", "SH-4d OSC model"),
new SH4dPreset(52, 65, "Synth Pad/Str 29", "SH-4d OSC model"),
new SH4dPreset(53, 65, "Synth Pad/Str 30", "SH-4d OSC model"),
new SH4dPreset(54, 65, "Synth Pad/Str 31", "SH-4d OSC model"),
new SH4dPreset(55, 65, "Synth Pad/Str 32", "SH-4d OSC model"),
new SH4dPreset(56, 65, "Synth PolyKey 5", "SH-4d OSC model"),
new SH4dPreset(57, 65, "Synth PolyKey 6", "SH-4d OSC model"),
new SH4dPreset(58, 65, "Synth PolyKey 7", "SH-4d OSC model"),
new SH4dPreset(59, 65, "Synth PolyKey 8", "SH-4d OSC model"),
new SH4dPreset(60, 65, "Pulsating 3", "SH-4d OSC model"),
new SH4dPreset(61, 65, "Pulsating 4", "SH-4d OSC model"),
new SH4dPreset(62, 65, "Pulsating 5", "SH-4d OSC model"),
new SH4dPreset(63, 65, "Synth Brass 2", "SH-4d OSC model"),
new SH4dPreset(64, 65, "Synth Brass 3", "SH-4d OSC model"),
new SH4dPreset(65, 65, "Synth Lead 8", "SH-4d OSC model"),
new SH4dPreset(66, 65, "Synth Lead 9", "SH-4d OSC model"),
new SH4dPreset(67, 65, "Synth Lead 10", "SH-4d OSC model"),
new SH4dPreset(68, 65, "Synth Lead 11", "SH-4d OSC model"),
new SH4dPreset(69, 65, "Synth Lead 12", "SH-4d OSC model"),
new SH4dPreset(70, 65, "Synth Bass 9", "SH-4d OSC model"),
new SH4dPreset(71, 65, "Synth Lead 13", "SH-4d OSC model"),
new SH4dPreset(72, 65, "Synth Bass 10", "SH-4d OSC model"),
new SH4dPreset(73, 65, "Synth Bass 11", "SH-4d OSC model"),
new SH4dPreset(74, 65, "Synth Bass 12", "SH-4d OSC model"),
new SH4dPreset(75, 65, "Synth Bass 13", "SH-4d OSC model"),
new SH4dPreset(76, 65, "Synth Bass 14", "SH-4d OSC model"),
new SH4dPreset(77, 65, "Synth Bass 15", "SH-4d OSC model"),
new SH4dPreset(78, 65, "Synth Bass 16", "SH-4d OSC model"),
new SH4dPreset(79, 65, "Synth Bass 17", "SH-4d OSC model"),
new SH4dPreset(80, 65, "Synth Bass 18", "SH-4d OSC model"),
new SH4dPreset(81, 65, "Synth Bass 19", "SH-4d OSC model"),
new SH4dPreset(82, 65, "Synth Bass 20", "SH-4d OSC model"),
new SH4dPreset(83, 65, "Synth Seq/Pop 2", "SH-4d OSC model"),
new SH4dPreset(84, 65, "Synth Seq/Pop 3", "SH-4d OSC model"),
new SH4dPreset(85, 65, "Synth Seq/Pop 4", "SH-4d OSC model"),
new SH4dPreset(86, 65, "Synth FX 3", "SH-4d OSC model"),
new SH4dPreset(87, 65, "Synth Brass 4", "SH-4d OSC model"),
new SH4dPreset(88, 65, "Synth Pad/Str 33", "SH-4d OSC model"),
new SH4dPreset(89, 65, "Synth Pad/Str 34", "SH-4d OSC model"),
new SH4dPreset(90, 65, "Synth PolyKey 9", "SH-4d OSC model"),
new SH4dPreset(91, 65, "Synth PolyKey 10", "SH-4d OSC model"),
new SH4dPreset(92, 65, "Synth PolyKey 11", "SH-4d OSC model"),
new SH4dPreset(93, 65, "Synth PolyKey 12", "SH-4d OSC model"),
new SH4dPreset(94, 65, "Synth PolyKey 13", "SH-4d OSC model"),
new SH4dPreset(95, 65, "Synth PolyKey 14", "SH-4d OSC model"),
new SH4dPreset(96, 65, "Synth Brass 5", "SH-4d OSC model"),
new SH4dPreset(97, 65, "Synth Pad/Str 35", "SH-4d OSC model"),
new SH4dPreset(98, 65, "Synth PolyKey 15", "SH-4d OSC model"),
new SH4dPreset(99, 65, "Synth PolyKey 16", "SH-4d OSC model"),
new SH4dPreset(100, 65, "Synth Bass 21", "SH-4d OSC model"),
new SH4dPreset(101, 65, "Synth Lead 14", "SH-4d OSC model"),
new SH4dPreset(102, 65, "Synth Lead 15", "SH-4d OSC model"),
new SH4dPreset(103, 65, "Synth PolyKey 17", "SH-4d OSC model"),
new SH4dPreset(104, 65, "Synth Bass 22", "SH-4d OSC model"),
new SH4dPreset(105, 65, "Synth PolyKey 18", "SH-4d OSC model"),
new SH4dPreset(106, 65, "Synth Pad/Str 36", "SH-4d OSC model"),
new SH4dPreset(107, 65, "Synth FX 4", "SH-4d OSC model"),
new SH4dPreset(108, 65, "Synth FX 5", "SH-4d OSC model"),
new SH4dPreset(109, 65, "Synth FX 6", "SH-4d OSC model"),
new SH4dPreset(110, 65, "Synth Pad/Str 37", "SH-4d OSC model"),
new SH4dPreset(111, 65, "Synth Pad/Str 38", "SH-4d OSC model"),
new SH4dPreset(112, 65, "Synth PolyKey 19", "SH-4d OSC model"),
new SH4dPreset(113, 65, "Synth PolyKey 20", "SH-4d OSC model"),
new SH4dPreset(114, 65, "Synth PolyKey 21", "SH-4d OSC model"),
new SH4dPreset(115, 65, "Synth PolyKey 22", "SH-4d OSC model"),
new SH4dPreset(116, 65, "Synth PolyKey 23", "SH-4d OSC model"),
new SH4dPreset(117, 65, "Synth Pad/Str 39", "SH-4d OSC model"),
new SH4dPreset(118, 65, "Synth Pad/Str 40", "SH-4d OSC model"),
new SH4dPreset(119, 65, "Synth Pad/Str 41", "SH-4d OSC model"),
new SH4dPreset(120, 65, "Pulsating 6", "SH-4d OSC model"),
new SH4dPreset(121, 65, "Pulsating 7", "SH-4d OSC model"),
new SH4dPreset(122, 65, "Pulsating 8", "SH-4d OSC model"),
new SH4dPreset(123, 65, "Synth Bass 23", "SH-4d OSC model"),
new SH4dPreset(124, 65, "Synth Brass 6", "SH-4d OSC model"),
new SH4dPreset(125, 65, "Synth Brass 7", "SH-4d OSC model"),
new SH4dPreset(126, 65, "Synth Pad/Str 42", "SH-4d OSC model"),
new SH4dPreset(127, 65, "Synth PolyKey 24", "SH-4d OSC model"),
new SH4dPreset(0, 66, "Synth Pad/Str 43", "SH-4d OSC model"),
new SH4dPreset(1, 66, "Synth Pad/Str 44", "SH-4d OSC model"),
new SH4dPreset(2, 66, "Synth Pad/Str 45", "SH-4d OSC model"),
new SH4dPreset(3, 66, "Synth PolyKey 25", "SH-4d OSC model"),
new SH4dPreset(4, 66, "Synth Pad/Str 46", "SH-4d OSC model"),
new SH4dPreset(5, 66, "Synth PolyKey 26", "SH-4d OSC model"),
new SH4dPreset(6, 66, "Synth Pad/Str 47", "SH-4d OSC model"),
new SH4dPreset(7, 66, "Synth Pad/Str 48", "SH-4d OSC model"),
new SH4dPreset(8, 66, "Synth Pad/Str 49", "SH-4d OSC model"),
new SH4dPreset(9, 66, "Synth Pad/Str 50", "SH-4d OSC model"),
new SH4dPreset(10, 66, "Synth Pad/Str 51", "SH-4d OSC model"),
new SH4dPreset(11, 66, "Synth Pad/Str 52", "SH-4d OSC model"),
new SH4dPreset(12, 66, "Synth Pad/Str 53", "SH-4d OSC model"),
new SH4dPreset(13, 66, "Bell 3", "SH-4d OSC model"),
new SH4dPreset(14, 66, "Synth PolyKey 27", "SH-4d OSC model"),
new SH4dPreset(15, 66, "Synth Lead 16", "SH-4d OSC model"),
new SH4dPreset(16, 66, "Pulsating 9", "SH-4d OSC model"),
new SH4dPreset(17, 66, "Synth Brass 8", "SH-4d OSC model"),
new SH4dPreset(18, 66, "Synth Brass 9", "SH-4d OSC model"),
new SH4dPreset(19, 66, "Synth Brass 10", "SH-4d OSC model"),
new SH4dPreset(20, 66, "Synth Brass 11", "SH-4d OSC model"),
new SH4dPreset(21, 66, "Synth Brass 12", "SH-4d OSC model"),
new SH4dPreset(22, 66, "Synth Brass 13", "SH-4d OSC model"),
new SH4dPreset(23, 66, "Synth Brass 14", "SH-4d OSC model"),
new SH4dPreset(24, 66, "Synth Lead 17", "SH-4d OSC model"),
new SH4dPreset(25, 66, "Synth Lead 18", "SH-4d OSC model"),
new SH4dPreset(26, 66, "Synth Lead 19", "SH-4d OSC model"),
new SH4dPreset(27, 66, "Synth Lead 20", "SH-4d OSC model"),
new SH4dPreset(28, 66, "Synth Lead 21", "SH-4d OSC model"),
new SH4dPreset(29, 66, "Synth Bass 24", "SH-4d OSC model"),
new SH4dPreset(30, 66, "Synth Bass 25", "SH-4d OSC model"),
new SH4dPreset(31, 66, "Synth Bass 26", "SH-4d OSC model"),
new SH4dPreset(32, 66, "Synth Seq/Pop 5", "SH-4d OSC model"),
new SH4dPreset(33, 66, "Synth Seq/Pop 6", "SH-4d OSC model"),
new SH4dPreset(34, 66, "Synth Seq/Pop 7", "SH-4d OSC model"),
new SH4dPreset(35, 66, "Synth Seq/Pop 8", "SH-4d OSC model"),
new SH4dPreset(36, 66, "Synth Seq/Pop 9", "SH-4d OSC model"),
new SH4dPreset(37, 66, "Synth Bass 27", "SH-4d OSC model"),
new SH4dPreset(38, 66, "Synth FX 7", "SH-4d OSC model"),
new SH4dPreset(39, 66, "Synth FX 8", "SH-4d OSC model"),
new SH4dPreset(40, 66, "Synth PolyKey 28", "SH-4d OSC model"),
new SH4dPreset(41, 66, "Synth PolyKey 29", "SH-4d OSC model"),
new SH4dPreset(42, 66, "Synth PolyKey 30", "SH-4d OSC model"),
new SH4dPreset(43, 66, "Synth Pad/Str 54", "SH-4d OSC model"),
new SH4dPreset(44, 66, "Synth Pad/Str 55", "SH-4d OSC model"),
new SH4dPreset(45, 66, "Synth PolyKey 31", "SH-4d OSC model"),
new SH4dPreset(46, 66, "Synth PolyKey 32", "SH-4d OSC model"),
new SH4dPreset(47, 66, "Synth Bass 28", "SH-4d OSC model"),
new SH4dPreset(48, 66, "Synth Pad/Str 56", "SH-4d OSC model"),
new SH4dPreset(49, 66, "Synth Pad/Str 57", "SH-4d OSC model"),
new SH4dPreset(50, 66, "Synth FX 9", "SH-4d OSC model"),
new SH4dPreset(51, 66, "Synth PolyKey 33", "SH-4d OSC model"),
new SH4dPreset(52, 66, "Synth Lead 22", "SH-4d OSC model"),
new SH4dPreset(53, 66, "Synth Brass 15", "SH-4d OSC model"),
new SH4dPreset(54, 66, "Synth Brass 16", "SH-4d OSC model"),
new SH4dPreset(55, 66, "Synth Brass 17", "SH-4d OSC model"),
new SH4dPreset(56, 66, "Synth PolyKey 34", "SH-4d OSC model"),
new SH4dPreset(57, 66, "Synth PolyKey 35", "SH-4d OSC model"),
new SH4dPreset(58, 66, "Synth Brass 18", "SH-4d OSC model"),
new SH4dPreset(59, 66, "Synth Pad/Str 58", "SH-4d OSC model"),
new SH4dPreset(60, 66, "Synth Pad/Str 59", "SH-4d OSC model"),
new SH4dPreset(61, 66, "Synth Pad/Str 60", "SH-4d OSC model"),
new SH4dPreset(62, 66, "Synth Pad/Str 61", "SH-4d OSC model"),
new SH4dPreset(63, 66, "Synth Seq/Pop 10", "SH-4d OSC model"),
new SH4dPreset(64, 66, "Synth PolyKey 36", "SH-4d OSC model"),
new SH4dPreset(65, 66, "Bell 4", "SH-4d OSC model"),
new SH4dPreset(66, 66, "Bell 5", "SH-4d OSC model"),
new SH4dPreset(67, 66, "Synth Bass 29", "SH-4d OSC model"),
new SH4dPreset(68, 66, "Synth FX 10", "SH-4d OSC model"),
new SH4dPreset(69, 66, "Synth Pad/Str 62", "SH-4d OSC model"),
new SH4dPreset(70, 66, "Synth Pad/Str 63", "SH-4d OSC model"),
new SH4dPreset(71, 66, "Synth Pad/Str 64", "SH-4d OSC model"),
new SH4dPreset(72, 66, "Synth Pad/Str 65", "SH-4d OSC model"),
new SH4dPreset(73, 66, "Synth Pad/Str 66", "SH-4d OSC model"),
new SH4dPreset(74, 66, "Synth Pad/Str 67", "SH-4d OSC model"),
new SH4dPreset(75, 66, "Synth Pad/Str 68", "SH-4d OSC model"),
new SH4dPreset(76, 66, "Synth PolyKey 37", "SH-4d OSC model"),
new SH4dPreset(77, 66, "Synth Lead 23", "SH-4d OSC model"),
new SH4dPreset(78, 66, "Synth Seq/Pop 11", "SH-4d OSC model"),
new SH4dPreset(79, 66, "Synth Lead 24", "SH-4d OSC model"),
new SH4dPreset(80, 66, "Synth Lead 25", "SH-4d OSC model"),
new SH4dPreset(81, 66, "Synth Lead 26", "SH-4d OSC model"),
new SH4dPreset(82, 66, "Synth Lead 27", "SH-4d OSC model"),
new SH4dPreset(83, 66, "Synth Lead 28", "SH-4d OSC model"),
new SH4dPreset(84, 66, "Synth Bass 30", "SH-4d OSC model"),
new SH4dPreset(85, 66, "Synth Lead 29", "SH-4d OSC model"),
new SH4dPreset(86, 66, "Synth Lead 30", "SH-4d OSC model"),
new SH4dPreset(87, 66, "Synth Lead 31", "SH-4d OSC model"),
new SH4dPreset(88, 66, "Synth Lead 32", "SH-4d OSC model"),
new SH4dPreset(89, 66, "Synth Lead 33", "SH-4d OSC model"),
new SH4dPreset(90, 66, "Synth Lead 34", "SH-4d OSC model"),
new SH4dPreset(91, 66, "Synth Lead 35", "SH-4d OSC model"),
new SH4dPreset(92, 66, "Synth Lead 36", "SH-4d OSC model"),
new SH4dPreset(93, 66, "Synth Lead 37", "SH-4d OSC model"),
new SH4dPreset(94, 66, "Synth Lead 38", "SH-4d OSC model"),
new SH4dPreset(95, 66, "Synth Lead 39", "SH-4d OSC model"),
new SH4dPreset(96, 66, "Synth Lead 40", "SH-4d OSC model"),
new SH4dPreset(97, 66, "Synth Bass 31", "SH-4d OSC model"),
new SH4dPreset(98, 66, "Synth Bass 32", "SH-4d OSC model"),
new SH4dPreset(99, 66, "Synth Bass 33", "SH-4d OSC model"),
new SH4dPreset(100, 66, "Synth Bass 34", "SH-4d OSC model"),
new SH4dPreset(101, 66, "Synth Bass 35", "SH-4d OSC model"),
new SH4dPreset(102, 66, "Synth Bass 36", "SH-4d OSC model"),
new SH4dPreset(103, 66, "Synth Bass 37", "SH-4d OSC model"),
new SH4dPreset(104, 66, "Synth Bass 38", "SH-4d OSC model"),
new SH4dPreset(105, 66, "Synth Bass 39", "SH-4d OSC model"),
new SH4dPreset(106, 66, "Synth Bass 40", "SH-4d OSC model"),
new SH4dPreset(107, 66, "Synth Bass 41", "SH-4d OSC model"),
new SH4dPreset(108, 66, "Synth Bass 42", "SH-4d OSC model"),
new SH4dPreset(109, 66, "Synth Bass 43", "SH-4d OSC model"),
new SH4dPreset(110, 66, "Synth Bass 44", "SH-4d OSC model"),
new SH4dPreset(111, 66, "Synth Bass 45", "SH-4d OSC model"),
new SH4dPreset(112, 66, "Synth Bass 46", "SH-4d OSC model"),
new SH4dPreset(113, 66, "Synth Bass 47", "SH-4d OSC model"),
new SH4dPreset(114, 66, "Synth Bass 48", "SH-4d OSC model"),
new SH4dPreset(115, 66, "Synth Bass 49", "SH-4d OSC model"),
new SH4dPreset(116, 66, "Synth Bass 50", "SH-4d OSC model"),
new SH4dPreset(117, 66, "Synth Bass 51", "SH-4d OSC model"),
new SH4dPreset(118, 66, "Synth Bass 52", "SH-4d OSC model"),
new SH4dPreset(119, 66, "Synth Bass 53", "SH-4d OSC model"),
new SH4dPreset(120, 66, "Synth Seq/Pop 12", "SH-4d OSC model"),
new SH4dPreset(121, 66, "Synth Seq/Pop 13", "SH-4d OSC model"),
new SH4dPreset(122, 66, "Synth Seq/Pop 14", "SH-4d OSC model"),
new SH4dPreset(123, 66, "Synth Seq/Pop 15", "SH-4d OSC model"),
new SH4dPreset(124, 66, "Synth Seq/Pop 16", "SH-4d OSC model"),
new SH4dPreset(125, 66, "Synth Seq/Pop 17", "SH-4d OSC model"),
new SH4dPreset(126, 66, "Bell 6", "SH-4d OSC model"),
new SH4dPreset(127, 66, "Synth Pad/Str 69", "SH-4d OSC model"),
new SH4dPreset(0, 67, "Synth Lead 41", "SH-4d OSC model"),
new SH4dPreset(1, 67, "Synth PolyKey 38", "SH-4d OSC model"),
new SH4dPreset(2, 67, "Synth PolyKey 39", "SH-4d OSC model"),
new SH4dPreset(3, 67, "Pulsating 10", "SH-4d OSC model"),
new SH4dPreset(4, 67, "Pulsating 11", "SH-4d OSC model"),
new SH4dPreset(5, 67, "Pulsating 12", "SH-4d OSC model"),
new SH4dPreset(6, 67, "Synth Seq/Pop 18", "SH-4d OSC model"),
new SH4dPreset(7, 67, "Synth PolyKey 40", "SH-4d OSC model"),
new SH4dPreset(8, 67, "Synth FX 11", "SH-4d OSC model"),
new SH4dPreset(9, 67, "Synth FX 12", "SH-4d OSC model"),
new SH4dPreset(10, 67, "Synth Lead 42", "SH-4d OSC model"),
new SH4dPreset(11, 67, "Synth Lead 43", "SH-4d OSC model"),
new SH4dPreset(12, 67, "Synth Lead 44", "SH-4d OSC model"),
new SH4dPreset(13, 67, "Synth Pad/Str 70", "SH-4d OSC model"),
new SH4dPreset(14, 67, "Synth PolyKey 41", "SH-4d OSC model"),
new SH4dPreset(15, 67, "Bass Fifth", "SH-4d OSC model"),
new SH4dPreset(16, 67, "Phaso Pulse", "SH-4d OSC model"),
new SH4dPreset(0, 68, "Synth Bass 54", "SH-3d OSC model"),
new SH4dPreset(1, 68, "Synth Bass 55", "SH-3d OSC model"),
new SH4dPreset(2, 68, "Froggy Triplet", "SH-3d OSC model"),
new SH4dPreset(3, 68, "SH Professional", "SH-3d OSC model"),
new SH4dPreset(4, 68, "Distant Past", "SH-3d OSC model"),
new SH4dPreset(5, 68, "Chemical Drop", "SH-3d OSC model"),
new SH4dPreset(6, 68, "PWM Go", "SH-3d OSC model"),
new SH4dPreset(7, 68, "Behooves You", "SH-3d OSC model"),
new SH4dPreset(8, 68, "Morning Dew", "SH-3d OSC model"),
new SH4dPreset(9, 68, "SciFi Lead", "SH-3d OSC model"),
new SH4dPreset(10, 68, "3OSC Acid Arpg", "SH-3d OSC model"),
new SH4dPreset(11, 68, "5th Ambi Pluck", "SH-3d OSC model"),
new SH4dPreset(12, 68, "Tri Stack Lead", "SH-3d OSC model"),
new SH4dPreset(13, 68, "Random 7", "SH-3d OSC model"),
new SH4dPreset(14, 68, "Reese Lead", "SH-3d OSC model"),
new SH4dPreset(15, 68, "EmotionalAmbient", "SH-3d OSC model"),
new SH4dPreset(16, 68, "Crazy Pad 3D", "SH-3d OSC model"),
new SH4dPreset(17, 68, "Synwave Bass", "SH-3d OSC model"),
new SH4dPreset(18, 68, "LoFi Piano Stab", "SH-3d OSC model"),
new SH4dPreset(19, 68, "Resonance Pad", "SH-3d OSC model"),
new SH4dPreset(20, 68, "Mother Ship", "SH-3d OSC model"),
new SH4dPreset(21, 68, "In the Cloud", "SH-3d OSC model"),
new SH4dPreset(22, 68, "Synth Lead 45", "SH-3d OSC model"),
new SH4dPreset(23, 68, "Synth Bass 56", "SH-3d OSC model"),
new SH4dPreset(24, 68, "Synth Brass 19", "SH-3d OSC model"),
new SH4dPreset(25, 68, "Synth Lead 46", "SH-3d OSC model"),
new SH4dPreset(26, 68, "Synth Lead 47", "SH-3d OSC model"),
new SH4dPreset(27, 68, "Synth Lead 48", "SH-3d OSC model"),
new SH4dPreset(28, 68, "Synth Lead 49", "SH-3d OSC model"),
new SH4dPreset(29, 68, "Synth Brass 20", "SH-3d OSC model"),
new SH4dPreset(30, 68, "Synth Lead 50", "SH-3d OSC model"),
new SH4dPreset(31, 68, "Synth Lead 51", "SH-3d OSC model"),
new SH4dPreset(32, 68, "Synth Bass 57", "SH-3d OSC model"),
new SH4dPreset(33, 68, "Synth Lead 52", "SH-3d OSC model"),
new SH4dPreset(34, 68, "Synth Lead 53", "SH-3d OSC model"),
new SH4dPreset(35, 68, "Synth Lead 54", "SH-3d OSC model"),
new SH4dPreset(36, 68, "Synth Bass 58", "SH-3d OSC model"),
new SH4dPreset(37, 68, "Synth Bass 59", "SH-3d OSC model"),
new SH4dPreset(38, 68, "Synth Lead 55", "SH-3d OSC model"),
new SH4dPreset(39, 68, "Bell 7", "SH-3d OSC model"),
new SH4dPreset(40, 68, "Synth PolyKey 42", "SH-3d OSC model"),
new SH4dPreset(41, 68, "Synth FX 13", "SH-3d OSC model"),
new SH4dPreset(42, 68, "Synth Seq/Pop 19", "SH-3d OSC model"),
new SH4dPreset(43, 68, "Synth Lead 56", "SH-3d OSC model"),
new SH4dPreset(44, 68, "ThereGoes Fluffy", "SH-3d OSC model"),
new SH4dPreset(45, 68, "NeucleoGenesis 3", "SH-3d OSC model"),
new SH4dPreset(46, 68, "MartiansComeHome", "SH-3d OSC model"),
new SH4dPreset(47, 68, "BehindThePolyMo", "SH-3d OSC model"),
new SH4dPreset(48, 68, "Daughter of '72", "SH-3d OSC model"),
new SH4dPreset(49, 68, "Son of '69", "SH-3d OSC model"),
new SH4dPreset(50, 68, "Soul Flight '69", "SH-3d OSC model"),
new SH4dPreset(51, 68, "Half Deity", "SH-3d OSC model"),
new SH4dPreset(52, 68, "Storm Singer", "SH-3d OSC model"),
new SH4dPreset(53, 68, "Flutter Pad", "SH-3d OSC model"),
new SH4dPreset(54, 68, "Sweet Keys", "SH-3d OSC model"),
new SH4dPreset(55, 68, "Noi Sine", "SH-3d OSC model"),
new SH4dPreset(56, 68, "TB-3d Saw Dry", "SH-3d OSC model"),
new SH4dPreset(57, 68, "TB-3d Sqr Dist", "SH-3d OSC model"),
new SH4dPreset(58, 68, "TB-3d Modded", "SH-3d OSC model"),
new SH4dPreset(59, 68, "Wheel Riser", "SH-3d OSC model"),
new SH4dPreset(60, 68, "Liquid Radio", "SH-3d OSC model"),
new SH4dPreset(61, 68, "Wind Control", "SH-3d OSC model"),
new SH4dPreset(62, 68, "Psy Lead", "SH-3d OSC model"),
new SH4dPreset(63, 68, "Oct Glider", "SH-3d OSC model"),
new SH4dPreset(64, 68, "SH RNDM Pluck", "SH-3d OSC model"),
new SH4dPreset(65, 68, "Gravity Bounce", "SH-3d OSC model"),
new SH4dPreset(66, 68, "I've seen things", "SH-3d OSC model"),
new SH4dPreset(67, 68, "Rndm Mod Lead", "SH-3d OSC model"),
new SH4dPreset(68, 68, "Slow Organ", "SH-3d OSC model"),
new SH4dPreset(69, 68, "Lofi B", "SH-3d OSC model"),
new SH4dPreset(70, 68, "Dual Square", "SH-3d OSC model"),
new SH4dPreset(71, 68, "Sqr Cho Pluck", "SH-3d OSC model"),
new SH4dPreset(72, 68, "FLead 505", "SH-3d OSC model"),
new SH4dPreset(73, 68, "Synth Poly Key", "SH-3d OSC model"),
new SH4dPreset(74, 68, "Dist Lead 1", "SH-3d OSC model"),
new SH4dPreset(75, 68, "S&H Pad", "SH-3d OSC model"),
new SH4dPreset(76, 68, "FX Scan", "SH-3d OSC model"),
new SH4dPreset(77, 68, "Lead 7", "SH-3d OSC model"),
new SH4dPreset(78, 68, "CAOSiN", "SH-3d OSC model"),
new SH4dPreset(79, 68, "CAOSiN P", "SH-3d OSC model"),
new SH4dPreset(80, 68, "Attack Bass", "SH-3d OSC model"),
new SH4dPreset(81, 68, "Open Pluck", "SH-3d OSC model"),
new SH4dPreset(82, 68, "Euro Synth", "SH-3d OSC model"),
new SH4dPreset(83, 68, "Deep Reese Bass", "SH-3d OSC model"),
new SH4dPreset(84, 68, "Future Org Bass", "SH-3d OSC model"),
new SH4dPreset(85, 68, "Disco Lead", "SH-3d OSC model"),
new SH4dPreset(86, 68, "LoFiWarm E.Piano", "SH-3d OSC model"),
new SH4dPreset(87, 68, "Sweep Pad", "SH-3d OSC model"),
new SH4dPreset(88, 68, "Seq Pad", "SH-3d OSC model"),
new SH4dPreset(89, 68, "Seq Noise Delay", "SH-3d OSC model"),
new SH4dPreset(90, 68, "Pop Lead 1", "SH-3d OSC model"),
new SH4dPreset(91, 68, "Pop Lead 2", "SH-3d OSC model"),
new SH4dPreset(92, 68, "Alien Dialogue", "SH-3d OSC model"),
new SH4dPreset(93, 68, "Wind Wave 2", "SH-3d OSC model"),
new SH4dPreset(94, 68, "Storm Wave", "SH-3d OSC model"),
new SH4dPreset(95, 68, "Choppp", "SH-3d OSC model"),
new SH4dPreset(0, 69, "Synth Lead 57", "Sync OSC model"),
new SH4dPreset(1, 69, "Progression", "Sync OSC model"),
new SH4dPreset(2, 69, "Sync Shredder", "Sync OSC model"),
new SH4dPreset(3, 69, "Sync Riffer", "Sync OSC model"),
new SH4dPreset(4, 69, "Sweeper", "Sync OSC model"),
new SH4dPreset(5, 69, "Punch", "Sync OSC model"),
new SH4dPreset(6, 69, "Doggie Lead", "Sync OSC model"),
new SH4dPreset(7, 69, "Polymisterio", "Sync OSC model"),
new SH4dPreset(8, 69, "SyncSweep Lead 1", "Sync OSC model"),
new SH4dPreset(9, 69, "Sync Sweep 1", "Sync OSC model"),
new SH4dPreset(10, 69, "Sync Lead 1", "Sync OSC model"),
new SH4dPreset(11, 69, "Bad Sync", "Sync OSC model"),
new SH4dPreset(12, 69, "Reverse Pluck", "Sync OSC model"),
new SH4dPreset(13, 69, "Cosmic Sync", "Sync OSC model"),
new SH4dPreset(14, 69, "PWM Acid", "Sync OSC model"),
new SH4dPreset(15, 69, "Slow Sync Pad", "Sync OSC model"),
new SH4dPreset(16, 69, "Synth Bass 60", "Sync OSC model"),
new SH4dPreset(17, 69, "Pulsating 13", "Sync OSC model"),
new SH4dPreset(18, 69, "Synth Bass 61", "Sync OSC model"),
new SH4dPreset(19, 69, "Pulsating 14", "Sync OSC model"),
new SH4dPreset(20, 69, "Synth Lead 58", "Sync OSC model"),
new SH4dPreset(21, 69, "Synth Lead 59", "Sync OSC model"),
new SH4dPreset(22, 69, "Synth PolyKey 43", "Sync OSC model"),
new SH4dPreset(23, 69, "Synth FX 14", "Sync OSC model"),
new SH4dPreset(24, 69, "Synth Bass 62", "Sync OSC model"),
new SH4dPreset(25, 69, "Synth Lead 60", "Sync OSC model"),
new SH4dPreset(26, 69, "Nasal Sync Pad", "Sync OSC model"),
new SH4dPreset(27, 69, "Sync Different", "Sync OSC model"),
new SH4dPreset(28, 69, "Harmony X", "Sync OSC model"),
new SH4dPreset(29, 69, "Keyfollow Wobble", "Sync OSC model"),
new SH4dPreset(30, 69, "Sync Pulse", "Sync OSC model"),
new SH4dPreset(31, 69, "Deep Sync$", "Sync OSC model"),
new SH4dPreset(32, 69, "Space Shift", "Sync OSC model"),
new SH4dPreset(33, 69, "Sync Pluck", "Sync OSC model"),
new SH4dPreset(34, 69, "Dist Lead 1", "Sync OSC model"),
new SH4dPreset(35, 69, "Sync Magic", "Sync OSC model"),
new SH4dPreset(36, 69, "Drum n Lead", "Sync OSC model"),
new SH4dPreset(37, 69, "Sync Jet", "Sync OSC model"),
new SH4dPreset(38, 69, "Sync Lead 2", "Sync OSC model"),
new SH4dPreset(39, 69, "Game Attack", "Sync OSC model"),
new SH4dPreset(40, 69, "Lazer Gun", "Sync OSC model"),
new SH4dPreset(41, 69, "Sync Sweep 2", "Sync OSC model"),
new SH4dPreset(42, 69, "Dream Pad", "Sync OSC model"),
new SH4dPreset(43, 69, "SyncSweep Lead 2", "Sync OSC model"),
new SH4dPreset(44, 69, "Sync Saw Acid", "Sync OSC model"),
new SH4dPreset(45, 69, "Sync Zap FX", "Sync OSC model"),
new SH4dPreset(46, 69, "Rock Solo Lead", "Sync OSC model"),
new SH4dPreset(47, 69, "Sync Saw", "Sync OSC model"),
new SH4dPreset(48, 69, "Kick The Square", "Sync OSC model"),
new SH4dPreset(49, 69, "Space Clav", "Sync OSC model"),
new SH4dPreset(50, 69, "OD Sync", "Sync OSC model"),
new SH4dPreset(0, 70, "SHlime Bass", "SH-101d OSC model"),
new SH4dPreset(1, 70, "SHoly Pad", "SH-101d OSC model"),
new SH4dPreset(2, 70, "SH Bass Gate", "SH-101d OSC model"),
new SH4dPreset(3, 70, "SH-Dark Bass", "SH-101d OSC model"),
new SH4dPreset(4, 70, "101 Bass Drone", "SH-101d OSC model"),
new SH4dPreset(5, 70, "Noisy Pad", "SH-101d OSC model"),
new SH4dPreset(6, 70, "Tronic Bass", "SH-101d OSC model"),
new SH4dPreset(7, 70, "Filter Velo Bass", "SH-101d OSC model"),
new SH4dPreset(8, 70, "PW & SQR Bass", "SH-101d OSC model"),
new SH4dPreset(9, 70, "Tight Bass", "SH-101d OSC model"),
new SH4dPreset(10, 70, "Space Colony", "SH-101d OSC model"),
new SH4dPreset(11, 70, "Smooth 101", "SH-101d OSC model"),
new SH4dPreset(12, 70, "Shore", "SH-101d OSC model"),
new SH4dPreset(13, 70, "Teen's Regime 17", "SH-101d OSC model"),
new SH4dPreset(14, 70, "Acid Bugs", "SH-101d OSC model"),
new SH4dPreset(15, 70, "Analog Flop", "SH-101d OSC model"),
new SH4dPreset(16, 70, "Simple Sub", "SH-101d OSC model"),
new SH4dPreset(17, 70, "Steady SH", "SH-101d OSC model"),
new SH4dPreset(18, 70, "SH Res Pad", "SH-101d OSC model"),
new SH4dPreset(19, 70, "NoisePulse Track", "SH-101d OSC model"),
new SH4dPreset(20, 70, "Tricky Bass", "SH-101d OSC model"),
new SH4dPreset(21, 70, "PWM Drone Bass", "SH-101d OSC model"),
new SH4dPreset(22, 70, "Rubber Bass", "SH-101d OSC model"),
new SH4dPreset(23, 70, "8th Timeline", "SH-101d OSC model"),
new SH4dPreset(24, 70, "Dty Ba$$", "SH-101d OSC model"),
new SH4dPreset(25, 70, "Biyoon", "SH-101d OSC model"),
new SH4dPreset(26, 70, "Crazy DTMF", "SH-101d OSC model"),
new SH4dPreset(27, 70, "Disco Pad?", "SH-101d OSC model"),
new SH4dPreset(28, 70, "Unstable P", "SH-101d OSC model"),
new SH4dPreset(29, 70, "Noise Lead", "SH-101d OSC model"),
new SH4dPreset(30, 70, "SQR Reso Bass", "SH-101d OSC model"),
new SH4dPreset(31, 70, "White Bass", "SH-101d OSC model"),
new SH4dPreset(32, 70, "Tomorrow FX", "SH-101d OSC model"),
new SH4dPreset(33, 70, "Space Lead", "SH-101d OSC model"),
new SH4dPreset(34, 70, "Random Slash", "SH-101d OSC model"),
new SH4dPreset(35, 70, "Portamento Bass", "SH-101d OSC model"),
new SH4dPreset(36, 70, "Lead 101", "SH-101d OSC model"),
new SH4dPreset(37, 70, "SH Tech Bass", "SH-101d OSC model"),
new SH4dPreset(38, 70, "Sqr&Sub Bass", "SH-101d OSC model"),
new SH4dPreset(39, 70, "Damage SH01", "SH-101d OSC model"),
new SH4dPreset(40, 70, "SH SQR Lead", "SH-101d OSC model"),
new SH4dPreset(41, 70, "Reso Melo SH", "SH-101d OSC model"),
new SH4dPreset(42, 70, "Fat Saw Lead", "SH-101d OSC model"),
new SH4dPreset(43, 70, "NRG SQR Lead", "SH-101d OSC model"),
new SH4dPreset(44, 70, "NRG HPF Lead", "SH-101d OSC model"),
new SH4dPreset(45, 70, "Solo Bass", "SH-101d OSC model"),
new SH4dPreset(46, 70, "Square Lead", "SH-101d OSC model"),
new SH4dPreset(47, 70, "SH Bass", "SH-101d OSC model"),
new SH4dPreset(48, 70, "Square Syn Kick", "SH-101d OSC model"),
new SH4dPreset(49, 70, "Reso Env Pad", "SH-101d OSC model"),
new SH4dPreset(50, 70, "SH-|()| Bass", "SH-101d OSC model"),
new SH4dPreset(0, 71, "NothinButTheRain", "JUNO-106 OSC model"),
new SH4dPreset(1, 71, "Green Grid", "JUNO-106 OSC model"),
new SH4dPreset(2, 71, "Ju-Funk Bass", "JUNO-106 OSC model"),
new SH4dPreset(3, 71, "PulseControl Pad", "JUNO-106 OSC model"),
new SH4dPreset(4, 71, "Cordion", "JUNO-106 OSC model"),
new SH4dPreset(5, 71, "JUNO Viola", "JUNO-106 OSC model"),
new SH4dPreset(6, 71, "106 Swell", "JUNO-106 OSC model"),
new SH4dPreset(7, 71, "Glow Pad", "JUNO-106 OSC model"),
new SH4dPreset(8, 71, "Ice & Fire", "JUNO-106 OSC model"),
new SH4dPreset(9, 71, "Brilliant JUNO", "JUNO-106 OSC model"),
new SH4dPreset(10, 71, "JUNO Strings", "JUNO-106 OSC model"),
new SH4dPreset(11, 71, "JUNO Pad 1", "JUNO-106 OSC model"),
new SH4dPreset(12, 71, "Super Moon", "JUNO-106 OSC model"),
new SH4dPreset(13, 71, "JUNO Bass 1", "JUNO-106 OSC model"),
new SH4dPreset(14, 71, "SubSpace 106", "JUNO-106 OSC model"),
new SH4dPreset(15, 71, "U Know Bass 106", "JUNO-106 OSC model"),
new SH4dPreset(16, 71, "Harmonica Lead", "JUNO-106 OSC model"),
new SH4dPreset(17, 71, "Insert Coin!", "JUNO-106 OSC model"),
new SH4dPreset(18, 71, "Computer Clav", "JUNO-106 OSC model"),
new SH4dPreset(19, 71, "Harp Breeze", "JUNO-106 OSC model"),
new SH4dPreset(20, 71, "Quacky JUNO", "JUNO-106 OSC model"),
new SH4dPreset(21, 71, "Analog Saw Poly", "JUNO-106 OSC model"),
new SH4dPreset(22, 71, "JUNO Pad 2", "JUNO-106 OSC model"),
new SH4dPreset(23, 71, "JUNO Bass 2", "JUNO-106 OSC model"),
new SH4dPreset(24, 71, "JUNO Pad 3", "JUNO-106 OSC model"),
new SH4dPreset(25, 71, "JUNO Bass 3", "JUNO-106 OSC model"),
new SH4dPreset(26, 71, "JUNO Pad 4", "JUNO-106 OSC model"),
new SH4dPreset(27, 71, "PWM&Sub Bass", "JUNO-106 OSC model"),
new SH4dPreset(28, 71, "Above the Clouds", "JUNO-106 OSC model"),
new SH4dPreset(29, 71, "Old Days Key", "JUNO-106 OSC model"),
new SH4dPreset(30, 71, "Ye Olde JUNO Ld", "JUNO-106 OSC model"),
new SH4dPreset(0, 72, "Bell 8", "Cross FM OSC model"),
new SH4dPreset(1, 72, "Hit & Hold", "Cross FM OSC model"),
new SH4dPreset(2, 72, "Noisy Marbles", "Cross FM OSC model"),
new SH4dPreset(3, 72, "Incoming in Big", "Cross FM OSC model"),
new SH4dPreset(4, 72, "Slow Attack Bell", "Cross FM OSC model"),
new SH4dPreset(5, 72, "Kick Bass", "Cross FM OSC model"),
new SH4dPreset(6, 72, "Bot Bell", "Cross FM OSC model"),
new SH4dPreset(7, 72, "Alien Temple", "Cross FM OSC model"),
new SH4dPreset(8, 72, "Whiny Wub", "Cross FM OSC model"),
new SH4dPreset(9, 72, "Dripper EP", "Cross FM OSC model"),
new SH4dPreset(10, 72, "Bwoink", "Cross FM OSC model"),
new SH4dPreset(11, 72, "Marimba Phone", "Cross FM OSC model"),
new SH4dPreset(12, 72, "Dirty Bass", "Cross FM OSC model"),
new SH4dPreset(13, 72, "PWM", "Cross FM OSC model"),
new SH4dPreset(14, 72, "Space Marimba", "Cross FM OSC model"),
new SH4dPreset(15, 72, "Pluck", "Cross FM OSC model"),
new SH4dPreset(16, 72, "Classic Bass", "Cross FM OSC model"),
new SH4dPreset(17, 72, "Avantgarde", "Cross FM OSC model"),
new SH4dPreset(18, 72, "Tubolar Bell", "Cross FM OSC model"),
new SH4dPreset(19, 72, "Ambiente", "Cross FM OSC model"),
new SH4dPreset(20, 72, "Crystal Glass", "Cross FM OSC model"),
new SH4dPreset(21, 72, "Silence-B", "Cross FM OSC model"),
new SH4dPreset(22, 72, "E.Piano 1", "Cross FM OSC model"),
new SH4dPreset(23, 72, "Bell B", "Cross FM OSC model"),
new SH4dPreset(24, 72, "Lead", "Cross FM OSC model"),
new SH4dPreset(25, 72, "Lead C", "Cross FM OSC model"),
new SH4dPreset(26, 72, "Lead P", "Cross FM OSC model"),
new SH4dPreset(27, 72, "Delay Glass Plk", "Cross FM OSC model"),
new SH4dPreset(28, 72, "Glassy Brass", "Cross FM OSC model"),
new SH4dPreset(29, 72, "Old Tape Bell", "Cross FM OSC model"),
new SH4dPreset(30, 72, "Plastic Pluck", "Cross FM OSC model"),
new SH4dPreset(31, 72, "Grass Land", "Cross FM OSC model"),
new SH4dPreset(32, 72, "Satellites", "Cross FM OSC model"),
new SH4dPreset(33, 72, "Echo Pluck", "Cross FM OSC model"),
new SH4dPreset(34, 72, "Synth Lead 61", "Cross FM OSC model"),
new SH4dPreset(35, 72, "Synth Lead 62", "Cross FM OSC model"),
new SH4dPreset(36, 72, "Synth Bass 63", "Cross FM OSC model"),
new SH4dPreset(37, 72, "Bell 9", "Cross FM OSC model"),
new SH4dPreset(38, 72, "Fujio-chang", "Cross FM OSC model"),
new SH4dPreset(39, 72, "Silver Droplets", "Cross FM OSC model"),
new SH4dPreset(40, 72, "One Hundred", "Cross FM OSC model"),
new SH4dPreset(41, 72, "Wind Caves", "Cross FM OSC model"),
new SH4dPreset(42, 72, "Berly Keys", "Cross FM OSC model"),
new SH4dPreset(43, 72, "Gnissel Lead", "Cross FM OSC model"),
new SH4dPreset(44, 72, "Uncontrolla Bell", "Cross FM OSC model"),
new SH4dPreset(45, 72, "OrganI C", "Cross FM OSC model"),
new SH4dPreset(46, 72, "Odd Pluck", "Cross FM OSC model"),
new SH4dPreset(47, 72, "Mosquito 1", "Cross FM OSC model"),
new SH4dPreset(48, 72, "Light Bell", "Cross FM OSC model"),
new SH4dPreset(49, 72, "Buzz Bell", "Cross FM OSC model"),
new SH4dPreset(50, 72, "PP Dash", "Cross FM OSC model"),
new SH4dPreset(51, 72, "Small Talk", "Cross FM OSC model"),
new SH4dPreset(52, 72, "Cross Bell 1", "Cross FM OSC model"),
new SH4dPreset(53, 72, "Donk Bass", "Cross FM OSC model"),
new SH4dPreset(54, 72, "Marimba", "Cross FM OSC model"),
new SH4dPreset(55, 72, "Mystery Pluck", "Cross FM OSC model"),
new SH4dPreset(56, 72, "Space Journey", "Cross FM OSC model"),
new SH4dPreset(57, 72, "Bite", "Cross FM OSC model"),
new SH4dPreset(58, 72, "Cry Lead", "Cross FM OSC model"),
new SH4dPreset(59, 72, "Pluck 2", "Cross FM OSC model"),
new SH4dPreset(60, 72, "Dream", "Cross FM OSC model"),
new SH4dPreset(61, 72, "Cross Bell 2", "Cross FM OSC model"),
new SH4dPreset(62, 72, "Lead B", "Cross FM OSC model"),
new SH4dPreset(63, 72, "Pluck C", "Cross FM OSC model"),
new SH4dPreset(64, 72, "E.Piano 2", "Cross FM OSC model"),
new SH4dPreset(65, 72, "Clavi", "Cross FM OSC model"),
new SH4dPreset(66, 72, "Dist Bass", "Cross FM OSC model"),
new SH4dPreset(67, 72, "Reso Pluck", "Cross FM OSC model"),
new SH4dPreset(68, 72, "S&H Robot", "Cross FM OSC model"),
new SH4dPreset(69, 72, "E.Marinba", "Cross FM OSC model"),
new SH4dPreset(70, 72, "2OP Plack", "Cross FM OSC model"),
new SH4dPreset(71, 72, "Detroit Solid Bs", "Cross FM OSC model"),
new SH4dPreset(72, 72, "Soft Melo", "Cross FM OSC model"),
new SH4dPreset(73, 72, "Dirty Bell Brass", "Cross FM OSC model"),
new SH4dPreset(74, 72, "Remote Rave", "Cross FM OSC model"),
new SH4dPreset(75, 72, "Plastic Bass", "Cross FM OSC model"),
new SH4dPreset(76, 72, "Caramel Box", "Cross FM OSC model"),
new SH4dPreset(77, 72, "Pad 1", "Cross FM OSC model"),
new SH4dPreset(78, 72, "Pad 2", "Cross FM OSC model"),
new SH4dPreset(79, 72, "Hollow Space", "Cross FM OSC model"),
new SH4dPreset(80, 72, "Ripple Chime", "Cross FM OSC model"),
new SH4dPreset(81, 72, "Robot Lead", "Cross FM OSC model"),
new SH4dPreset(82, 72, "Space Pan", "Cross FM OSC model"),
new SH4dPreset(83, 72, "Pluck One", "Cross FM OSC model"),
new SH4dPreset(84, 72, "Soft Bell", "Cross FM OSC model"),
new SH4dPreset(85, 72, "Porta Mono Lead", "Cross FM OSC model"),
new SH4dPreset(86, 72, "313 Ring", "Cross FM OSC model"),
new SH4dPreset(87, 72, "Glissen", "Cross FM OSC model"),
new SH4dPreset(0, 73, "Synth Bass 64", "Ring OSC model"),
new SH4dPreset(1, 73, "Ring Mod Sweep", "Ring OSC model"),
new SH4dPreset(2, 73, "Mo Drum", "Ring OSC model"),
new SH4dPreset(3, 73, "Ring Wash BPF", "Ring OSC model"),
new SH4dPreset(4, 73, "Broke Box", "Ring OSC model"),
new SH4dPreset(5, 73, "Tek Blip", "Ring OSC model"),
new SH4dPreset(6, 73, "Ring LFO Sweep", "Ring OSC model"),
new SH4dPreset(7, 73, "Electric Ring", "Ring OSC model"),
new SH4dPreset(8, 73, "Overdriven Ring", "Ring OSC model"),
new SH4dPreset(9, 73, "Anello Pad", "Ring OSC model"),
new SH4dPreset(10, 73, "Spinning Ring", "Ring OSC model"),
new SH4dPreset(11, 73, "Dimension Ring", "Ring OSC model"),
new SH4dPreset(12, 73, "Dark Ambience", "Ring OSC model"),
new SH4dPreset(13, 73, "Mono Ring Bell", "Ring OSC model"),
new SH4dPreset(14, 73, "Ring Matic", "Ring OSC model"),
new SH4dPreset(15, 73, "Ring Vel", "Ring OSC model"),
new SH4dPreset(16, 73, "Ring Harm", "Ring OSC model"),
new SH4dPreset(17, 73, "Ring Harm B", "Ring OSC model"),
new SH4dPreset(18, 73, "Ringin Bass", "Ring OSC model"),
new SH4dPreset(19, 73, "Dark Fantasy", "Ring OSC model"),
new SH4dPreset(20, 73, "Proxima", "Ring OSC model"),
new SH4dPreset(21, 73, "Ambient Lead", "Ring OSC model"),
new SH4dPreset(22, 73, "Raga Bass", "Ring OSC model"),
new SH4dPreset(23, 73, "Haunting", "Ring OSC model"),
new SH4dPreset(24, 73, "Synth Seq/Pop 20", "Ring OSC model"),
new SH4dPreset(25, 73, "Kinda Modulated", "Ring OSC model"),
new SH4dPreset(26, 73, "Drop Module", "Ring OSC model"),
new SH4dPreset(27, 73, "Silo Pluck", "Ring OSC model"),
new SH4dPreset(28, 73, "Pesky Lead", "Ring OSC model"),
new SH4dPreset(29, 73, "Ring Tone", "Ring OSC model"),
new SH4dPreset(30, 73, "Ring Hit", "Ring OSC model"),
new SH4dPreset(31, 73, "LFO Key", "Ring OSC model"),
new SH4dPreset(32, 73, "IS S&H", "Ring OSC model"),
new SH4dPreset(33, 73, "Black Bell", "Ring OSC model"),
new SH4dPreset(34, 73, "Ring Bell", "Ring OSC model"),
new SH4dPreset(35, 73, "Ring FX", "Ring OSC model"),
new SH4dPreset(36, 73, "Fade Point", "Ring OSC model"),
new SH4dPreset(37, 73, "Ring Attack", "Ring OSC model"),
new SH4dPreset(38, 73, "Ring Panic", "Ring OSC model"),
new SH4dPreset(39, 73, "Ring Magic B", "Ring OSC model"),
new SH4dPreset(40, 73, "Sub Bass R", "Ring OSC model"),
new SH4dPreset(41, 73, "Future House Bs", "Ring OSC model"),
new SH4dPreset(42, 73, "UK Bass Lead", "Ring OSC model"),
new SH4dPreset(43, 73, "Future Bass Stab", "Ring OSC model"),
new SH4dPreset(44, 73, "Retro Wave Pad", "Ring OSC model"),
new SH4dPreset(45, 73, "Space Wave Pad", "Ring OSC model"),
new SH4dPreset(46, 73, "Solid Ring Bass", "Ring OSC model"),
new SH4dPreset(47, 73, "Tech 'n' Bass", "Ring OSC model"),
new SH4dPreset(48, 73, "Pulsing Train", "Ring OSC model"),
new SH4dPreset(0, 74, "Synth Lead 62", "Wavetable OSC model"),
new SH4dPreset(1, 74, "Bell Pad ALiVE", "Wavetable OSC model"),
new SH4dPreset(2, 74, "Industrial Rev4d", "Wavetable OSC model"),
new SH4dPreset(3, 74, "LearningMachines", "Wavetable OSC model"),
new SH4dPreset(4, 74, "FeedbackOsc Izit", "Wavetable OSC model"),
new SH4dPreset(5, 74, "IndexTransitions", "Wavetable OSC model"),
new SH4dPreset(6, 74, "Resurgence 4D", "Wavetable OSC model"),
new SH4dPreset(7, 74, "FM Parade", "Wavetable OSC model"),
new SH4dPreset(8, 74, "Lozza Wub", "Wavetable OSC model"),
new SH4dPreset(9, 74, "Metal Droid Bass", "Wavetable OSC model"),
new SH4dPreset(10, 74, "Morph Mode", "Wavetable OSC model"),
new SH4dPreset(11, 74, "WT Scanner", "Wavetable OSC model"),
new SH4dPreset(12, 74, "Series Finale", "Wavetable OSC model"),
new SH4dPreset(13, 74, "Circuit Breath 1", "Wavetable OSC model"),
new SH4dPreset(14, 74, "Round Sub Glide", "Wavetable OSC model"),
new SH4dPreset(15, 74, "Circuit Breath 2", "Wavetable OSC model"),
new SH4dPreset(16, 74, "UniSqr Spctl Hit", "Wavetable OSC model"),
new SH4dPreset(17, 74, "Vactrol Strike", "Wavetable OSC model"),
new SH4dPreset(18, 74, "Gargantua Bass", "Wavetable OSC model"),
new SH4dPreset(19, 74, "Table GL1t[#", "Wavetable OSC model"),
new SH4dPreset(20, 74, "Robot Talk", "Wavetable OSC model"),
new SH4dPreset(21, 74, "Oh Yeah !!!", "Wavetable OSC model"),
new SH4dPreset(22, 74, "Radioactive Wind", "Wavetable OSC model"),
new SH4dPreset(23, 74, "Lo-Fi Bell", "Wavetable OSC model"),
new SH4dPreset(24, 74, "Wavefolder Bass", "Wavetable OSC model"),
new SH4dPreset(25, 74, "Reverse Dream", "Wavetable OSC model"),
new SH4dPreset(26, 74, "Frog Talk", "Wavetable OSC model"),
new SH4dPreset(27, 74, "Tron Pad", "Wavetable OSC model"),
new SH4dPreset(28, 74, "Future Acid", "Wavetable OSC model"),
new SH4dPreset(29, 74, "Saw Spectral", "Wavetable OSC model"),
new SH4dPreset(30, 74, "Circuit Error", "Wavetable OSC model"),
new SH4dPreset(31, 74, "8Bit Game Bass", "Wavetable OSC model"),
new SH4dPreset(32, 74, "WT Gamelan 1", "Wavetable OSC model"),
new SH4dPreset(33, 74, "Music Box WT", "Wavetable OSC model"),
new SH4dPreset(34, 74, "Future Pop Chord", "Wavetable OSC model"),
new SH4dPreset(35, 74, "Glacier Cave", "Wavetable OSC model"),
new SH4dPreset(36, 74, "Vibration", "Wavetable OSC model"),
new SH4dPreset(37, 74, "Circuit Bass", "Wavetable OSC model"),
new SH4dPreset(38, 74, "Deep Sauce", "Wavetable OSC model"),
new SH4dPreset(39, 74, "Synth Lead 61", "Wavetable OSC model"),
new SH4dPreset(40, 74, "Synth Lead 63", "Wavetable OSC model"),
new SH4dPreset(41, 74, "Ohh Yeah!?", "Wavetable OSC model"),
new SH4dPreset(42, 74, "FM EP on Wavtabl", "Wavetable OSC model"),
new SH4dPreset(43, 74, "Water Beneath Us", "Wavetable OSC model"),
new SH4dPreset(44, 74, "Dellinger Effect", "Wavetable OSC model"),
new SH4dPreset(45, 74, "Wave Speak", "Wavetable OSC model"),
new SH4dPreset(46, 74, "Big Mouth", "Wavetable OSC model"),
new SH4dPreset(47, 74, "Walker", "Wavetable OSC model"),
new SH4dPreset(48, 74, "Pad Pastures", "Wavetable OSC model"),
new SH4dPreset(49, 74, "Morph Pad", "Wavetable OSC model"),
new SH4dPreset(50, 74, "Yikes", "Wavetable OSC model"),
new SH4dPreset(51, 74, "Stack Feedback", "Wavetable OSC model"),
new SH4dPreset(52, 74, "Deep Pad", "Wavetable OSC model"),
new SH4dPreset(53, 74, "Sine Garden Pad", "Wavetable OSC model"),
new SH4dPreset(54, 74, "Wave Edge", "Wavetable OSC model"),
new SH4dPreset(55, 74, "Chit Chat", "Wavetable OSC model"),
new SH4dPreset(56, 74, "AIOIEA", "Wavetable OSC model"),
new SH4dPreset(57, 74, "Metal Drop", "Wavetable OSC model"),
new SH4dPreset(58, 74, "Tap FX", "Wavetable OSC model"),
new SH4dPreset(59, 74, "S&H Bass", "Wavetable OSC model"),
new SH4dPreset(60, 74, "Rhythm Warp", "Wavetable OSC model"),
new SH4dPreset(61, 74, "Voxylor", "Wavetable OSC model"),
new SH4dPreset(62, 74, "Radio Tune", "Wavetable OSC model"),
new SH4dPreset(63, 74, "Wow Lead", "Wavetable OSC model"),
new SH4dPreset(64, 74, "Fold Bell", "Wavetable OSC model"),
new SH4dPreset(65, 74, "Sync Bass B", "Wavetable OSC model"),
new SH4dPreset(66, 74, "Warp Pad", "Wavetable OSC model"),
new SH4dPreset(67, 74, "Hexa Bass", "Wavetable OSC model"),
new SH4dPreset(68, 74, "Space Alien", "Wavetable OSC model"),
new SH4dPreset(69, 74, "Scat Pluck", "Wavetable OSC model"),
new SH4dPreset(70, 74, "Digital Harpsico", "Wavetable OSC model"),
new SH4dPreset(71, 74, "Wave Dist Gtr", "Wavetable OSC model"),
new SH4dPreset(72, 74, "Mosquito 2", "Wavetable OSC model"),
new SH4dPreset(73, 74, "FM Oct Mod", "Wavetable OSC model"),
new SH4dPreset(74, 74, "Digi Mid Bass", "Wavetable OSC model"),
new SH4dPreset(75, 74, "West Coast", "Wavetable OSC model"),
new SH4dPreset(76, 74, "Mustache Wave", "Wavetable OSC model"),
new SH4dPreset(77, 74, "Uni HPF Warp", "Wavetable OSC model"),
new SH4dPreset(78, 74, "Wavetable Clavi", "Wavetable OSC model"),
new SH4dPreset(79, 74, "WT Gamelan 2", "Wavetable OSC model"),
new SH4dPreset(80, 74, "Tribal Acid", "Wavetable OSC model"),
new SH4dPreset(81, 74, "Choco Mint Synth", "Wavetable OSC model"),
new SH4dPreset(82, 74, "Elek Banjo", "Wavetable OSC model"),
new SH4dPreset(83, 74, "Clean Guitar WT", "Wavetable OSC model"),
new SH4dPreset(84, 74, "OD-1 Guitar WT", "Wavetable OSC model"),
new SH4dPreset(85, 74, "Clean Synth WT", "Wavetable OSC model"),
new SH4dPreset(86, 74, "Clean Square WT", "Wavetable OSC model"),
new SH4dPreset(87, 74, "Up Sweep Pad", "Wavetable OSC model"),
new SH4dPreset(88, 74, "Table", "Wavetable OSC model"),
new SH4dPreset(89, 74, "Oye", "Wavetable OSC model"),
new SH4dPreset(90, 74, "Hammer Down", "Wavetable OSC model"),
new SH4dPreset(91, 74, "Harmonics Seq", "Wavetable OSC model"),
new SH4dPreset(92, 74, "Uni Sqr Warp Ld", "Wavetable OSC model"),
new SH4dPreset(93, 74, "Fly Bye FX", "Wavetable OSC model"),
new SH4dPreset(94, 74, "Flutable", "Wavetable OSC model"),
new SH4dPreset(0, 75, "Synth Pad/Str 71", "Chord OSC model"),
new SH4dPreset(1, 75, "Synth Pad/Str 72", "Chord OSC model"),
new SH4dPreset(2, 75, "7 Fluctuations", "Chord OSC model"),
new SH4dPreset(3, 75, "Sustainability 4", "Chord OSC model"),
new SH4dPreset(4, 75, "Descendant 7sus4", "Chord OSC model"),
new SH4dPreset(5, 75, "Chordplex", "Chord OSC model"),
new SH4dPreset(6, 75, "Bit Chord", "Chord OSC model"),
new SH4dPreset(7, 75, "Fade Chord", "Chord OSC model"),
new SH4dPreset(8, 75, "Major Memories", "Chord OSC model"),
new SH4dPreset(9, 75, "4th Magic <>", "Chord OSC model"),
new SH4dPreset(10, 75, "9th Lead", "Chord OSC model"),
new SH4dPreset(11, 75, "Chord Pad P2", "Chord OSC model"),
new SH4dPreset(12, 75, "Cloud Ripples", "Chord OSC model"),
new SH4dPreset(13, 75, "Pingpong", "Chord OSC model"),
new SH4dPreset(14, 75, "Pulsating 15", "Chord OSC model"),
new SH4dPreset(15, 75, "Pulsating 16", "Chord OSC model"),
new SH4dPreset(16, 75, "Synth Pad/Str 73", "Chord OSC model"),
new SH4dPreset(17, 75, "Basic Stab", "Chord OSC model"),
new SH4dPreset(18, 75, "Chord Pad", "Chord OSC model"),
new SH4dPreset(19, 75, "Chord Pad P", "Chord OSC model"),
new SH4dPreset(20, 75, "Chord Slice", "Chord OSC model"),
new SH4dPreset(21, 75, "Chord Sine", "Chord OSC model"),
new SH4dPreset(22, 75, "Wavy Brass", "Chord OSC model"),
new SH4dPreset(23, 75, "Chord Ripples", "Chord OSC model"),
new SH4dPreset(24, 75, "Chordy Dance", "Chord OSC model"),
new SH4dPreset(0, 76, "Scribble Bass", "Drawing OSC model"),
new SH4dPreset(1, 76, "Box Bot Lead", "Drawing OSC model"),
new SH4dPreset(2, 76, "Vision EP", "Drawing OSC model"),
new SH4dPreset(3, 76, "Drawing Guitar", "Drawing OSC model"),
new SH4dPreset(4, 76, "Foreign Pluck", "Drawing OSC model"),
new SH4dPreset(5, 76, "Load '*', 8,1", "Drawing OSC model"),
new SH4dPreset(6, 76, "Draw Dream", "Drawing OSC model"),
new SH4dPreset(7, 76, "Morning Organ", "Drawing OSC model"),
new SH4dPreset(8, 76, "Drawing Sine Ld", "Drawing OSC model"),
new SH4dPreset(9, 76, "Refresh Rate", "Drawing OSC model"),
new SH4dPreset(10, 76, "DigitizerTab 100", "Drawing OSC model"),
new SH4dPreset(11, 76, "Deetar", "Drawing OSC model"),
new SH4dPreset(12, 76, "Phase Pluck", "Drawing OSC model"),
new SH4dPreset(13, 76, "Direct Lead", "Drawing OSC model"),
new SH4dPreset(14, 76, "Drawing Bell", "Drawing OSC model"),
new SH4dPreset(15, 76, "DrawingTri Bs MW", "Drawing OSC model"),
new SH4dPreset(16, 76, "Building", "Drawing OSC model"),
new SH4dPreset(17, 76, "Drawing Organ", "Drawing OSC model"),
new SH4dPreset(18, 76, "Fat Draw Bass", "Drawing OSC model"),
new SH4dPreset(19, 76, "Draw", "Drawing OSC model"),
new SH4dPreset(20, 76, "Drawn Droid", "Drawing OSC model"),
new SH4dPreset(21, 76, "Toy Chime", "Drawing OSC model"),
new SH4dPreset(0, 77, "JD Piano", "PCM OSC model"),
new SH4dPreset(1, 77, "Cosine Bass", "PCM OSC model"),
new SH4dPreset(2, 77, "Warm Pad", "PCM OSC model"),
new SH4dPreset(3, 77, "Warm Stack Pad", "PCM OSC model"),
new SH4dPreset(4, 77, "Cathedral", "PCM OSC model"),
new SH4dPreset(5, 77, "Harmonic Bars", "PCM OSC model"),
new SH4dPreset(6, 77, "FM Brass", "PCM OSC model"),
new SH4dPreset(7, 77, "Organ 1", "PCM OSC model"),
new SH4dPreset(8, 77, "Organ 2", "PCM OSC model"),
new SH4dPreset(9, 77, "Organ 3", "PCM OSC model"),
new SH4dPreset(10, 77, "Nasty Bass", "PCM OSC model")
] @=> static SH4dPreset @ sh4dPresets[];

}

// RolandSH4d is a class that represents a Roland SH-4d MIDI device in the framework.
// It extends Patch and supports pattern bank selection, channels in that bank, and individual channel tone presets.
//
// This class is used to create Roland SH-4d patches for MIDI devices.
public class RolandSH4d extends Patch
{
    int programChange;
    string presetType; // "bank", "channel", or "tone"
    int toneProgram;
    int toneBank;

    fun RolandSH4d()
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        0 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        "channel" => presetType;
        "Channel 1" => patchName;
    }

    fun RolandSH4d(int channel, int b, int p, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        if (b >= 64) {
            0 => program;
            0 => bank;
            false => programChange;
            b => toneBank;
            p => toneProgram;
            "tone" => presetType;
            SH4dPresetCollection collection;
            collection.getPreset(b, p) @=> SH4dPreset @ preset;
            if (preset != null) {
                preset.name => patchName;
            } else {
                "Tone Bank: " + Std.itoa(b) + " Program: " + Std.itoa(p + 1) => patchName;
            }
        } else {
            p => program;
            b => bank;
            true => programChange;
            -1 => toneProgram;
            -1 => toneBank;
            "bank" => presetType;
            "Bank: " + Std.itoa(bank) + " Program: " + Std.itoa(program) => patchName;
        }
        Patch(v);
    }

    fun RolandSH4d(int channel, string pName, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        resolvePreset(pName);
        Patch(v);
    }

    fun RolandSH4d(int channel, int b, int p, string pName, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        resolvePreset(pName);
        Patch(v);
    }

    fun RolandSH4d(int channel, int b, int p, int tb, int tp, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        tb => toneBank;
        tp => toneProgram;
        "tone" => presetType;
        SH4dPresetCollection collection;
        collection.getPreset(tb, tp) @=> SH4dPreset @ preset;
        if (preset != null) {
            preset.name => patchName;
        } else {
            "Tone Bank: " + Std.itoa(tb) + " Program: " + Std.itoa(tp + 1) => patchName;
        }
        Patch(v);
    }

    fun RolandSH4d(int channel, int v)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        -1 => toneProgram;
        -1 => toneBank;
        "channel" => presetType;
        "Channel " + Std.itoa(channel) => patchName;
        Patch(v);
    }

    fun void resolvePreset(string pName)
    {
        SH4dPresetCollection collection;
        if (collection.hasPreset(pName)) {
            collection.getPreset(pName) @=> SH4dPreset @ p;
            p.program => toneProgram;
            p.bank => toneBank;
            p.name => patchName;
            "tone" => presetType;
        } else {
            -1 => toneProgram;
            -1 => toneBank;
            pName => patchName;
            if (programChange) {
                "bank" => presetType;
            } else {
                "channel" => presetType;
            }
        }
    }

    fun void setChannelPreset(string presetName)
    {
        resolvePreset(presetName);
        if (presetType == "tone" && toneBank >= 0 && toneProgram >= 0) {
            programChangeSH4dChannel(toneProgram, toneBank);
        }
    }

    fun void setChannelPreset(int tb, int tp)
    {
        tb => toneBank;
        tp => toneProgram;
        "tone" => presetType;
        SH4dPresetCollection collection;
        collection.getPreset(tb, tp) @=> SH4dPreset @ p;
        if (p != null) {
            p.name => patchName;
        } else {
            "Tone Bank: " + Std.itoa(tb) + " Program: " + Std.itoa(tp + 1) => patchName;
        }
        programChangeSH4dChannel(toneProgram, toneBank);
    }

    fun void setPreset()
    {
        if (programChange) 
        {
            (bank - 1) * 16 + program - 1 => int preset; 
            programChangeSH4d(preset);
            0.1::second => now;
        }
        if (presetType == "tone" && toneBank >= 0 && toneProgram >= 0)
        {
            programChangeSH4dChannel(toneProgram, toneBank);
            0.1::second => now;
        }
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
        config.SetInt("programChange", programChange);
        config.SetString("presetType", presetType);
        if (presetType == "tone") {
            config.SetInt("toneProgram", toneProgram);
            config.SetInt("toneBank", toneBank);
        }
    }
    
    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        if (config.findChild("programChange") >= 0) {
            config.GetInt("programChange") => programChange;
        }
        if (config.findChild("presetType") >= 0) {
            config.GetString("presetType") => presetType;
        } else {
            if (programChange) {
                "bank" => presetType;
            } else {
                "channel" => presetType;
            }
        }
        if (config.findChild("toneProgram") >= 0) {
            config.GetInt("toneProgram") => toneProgram;
        } else {
            -1 => toneProgram;
        }
        if (config.findChild("toneBank") >= 0) {
            config.GetInt("toneBank") => toneBank;
        } else {
            -1 => toneBank;
        }
        SH4dPresetCollection collection;
        if (presetType == "tone" || collection.hasPreset(patchName)) {
            "tone" => presetType;
            if (!collection.matchesPreset(patchName, toneBank, toneProgram)) {
                if (collection.hasPreset(patchName)) {
                    collection.getPreset(patchName) @=> SH4dPreset @ p;
                    p.program => toneProgram;
                    p.bank => toneBank;
                    p.name => patchName;
                } else if (toneBank >= 0 && toneProgram >= 0) {
                    collection.getPreset(toneBank, toneProgram) @=> SH4dPreset @ p;
                    if (p != null) {
                        p.name => patchName;
                    }
                }
            } else {
                collection.getPreset(toneBank, toneProgram) @=> SH4dPreset @ p;
                if (p != null) {
                    p.name => patchName;
                }
            }
        }
        if (patchName == "") {
            "Channel " + Std.itoa(midiChannel + 1) => patchName;
        }
        updateControllers();
    }
}

// BehringerRD6 is a class that represents a Behringer RD-6 MIDI device in the framework.
// It extends Patch and adds a preset name.
//
// This class is used to create Behringer RD-6 patches for MIDI devices.
public class BehringerRD6 extends Patch
{
    string presetName;

    fun BehringerRD6()
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        0 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;
    }

    fun BehringerRD6(int v)
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        0 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;

        Patch(v);
    }

    fun BehringerRD6(int channel, int v)
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        channel - 1 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;
        "RHYTHM DESIGNER RD-6" => presetName;

        Patch(v);
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetString("presetName", presetName);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        openDevice();
        if (config.findChild("presetName") >= 0) {
            config.GetString("presetName") => presetName;
        } else {
            "RHYTHM DESIGNER RD-6" => presetName;
        }
        if (patchName == "") {
            "RHYTHM DESIGNER RD-6" => patchName;
        }
        updateControllers();
    }
}

// V3Preset is a class that represents a V3 preset in the framework.
// It contains the program, bank, name, and category.
//
// This class is used to create V3 presets for MIDI devices.
public class V3Preset
{
    int program;
    int bank;
    string name;
    string category;
    fun V3Preset(int p, int b, string n, string cat) {
        p => program;
        b => bank;
        n => name;
        cat => category;
    }
}

// V3PresetCollection is a class that represents a collection of V3 presets in the framework.
// It contains the current preset index, current preset category, and a list of V3 presets.
//
// This class is used to create V3 preset collections for MIDI devices.
public class V3PresetCollection
{
    int curPresetIndex;
    string curPresetCategory;

    fun V3PresetCollection()
    {
        0 => curPresetIndex;
        "" @=> curPresetCategory;
    }

    fun V3Preset getNextPreset() 
    {
        (curPresetIndex + 1) % v3Presets.cap() => curPresetIndex;
        v3Presets[curPresetIndex] @=> V3Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun V3Preset getPreviousPreset() 
    {
        (curPresetIndex - 1) % v3Presets.cap() => curPresetIndex;
        v3Presets[curPresetIndex] @=> V3Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun V3Preset getNextCategory()
    {
        for (curPresetIndex+1 => int i; i < v3Presets.cap(); i++) {
            if (v3Presets[i].category != curPresetCategory) {
                i => curPresetIndex;
                v3Presets[curPresetIndex] @=> V3Preset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        0 => curPresetIndex;
        v3Presets[0] @=> V3Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun V3Preset getPreviousCategory()
    {
        for (curPresetIndex => int i; i >= 0; i--) {
            if (v3Presets[i].category != curPresetCategory) {
                i => curPresetIndex;
                v3Presets[curPresetIndex] @=> V3Preset preset;
                preset.category @=> curPresetCategory;
                return preset;
            }
        }
        v3Presets.cap() - 1 => curPresetIndex;
        v3Presets[curPresetIndex] @=> V3Preset preset;
        preset.category @=> curPresetCategory;
        return preset;
    }

    fun V3Preset getPreset(string presetName)
    {
        if (curPresetCategory != "") {
            for( V3Preset preset: v3Presets) {
                if (preset.category == curPresetCategory && preset.name == presetName)
                    return preset;
            }
        }
        for( V3Preset preset: v3Presets) {
            if (preset.name == presetName)
            return preset;
        }
        <<< "Can't find preset: ", presetName >>>;
        return v3Presets[0];
    }

    fun void setPresetState(string presetName)
    {
        if (curPresetCategory != "") {
            for( 0 => int i; i < v3Presets.cap(); i++) {
                if (v3Presets[i].category == curPresetCategory && v3Presets[i].name == presetName) {
                    i => curPresetIndex;
                    v3Presets[curPresetIndex] @=> V3Preset preset;
                    preset.category @=> curPresetCategory;
                    return;
                }
            }
        }
        for( 0 => int i; i < v3Presets.cap(); i++) {
            if (v3Presets[i].name == presetName) {
                i => curPresetIndex;
                v3Presets[curPresetIndex] @=> V3Preset preset;
                preset.category @=> curPresetCategory;
                return;
            }
        }
    }

// All Presets for the V3 Grand Piano XXL
[
new V3Preset(0, 0, "Grand Piano Vienna", "Grand Piano"),
new V3Preset(1, 0, "Grand Piano Hamburg", "Grand Piano"),
new V3Preset(2, 0, "Grand Piano Vienna - Rock", "Grand Piano"),
new V3Preset(3, 0, "Grand Piano Hamburg - Rock", "Grand Piano"),
new V3Preset(4, 0, "Grand Piano Vienna - original", "Grand Piano"),
new V3Preset(5, 0, "Grand Piano Hamburg - original", "Grand Piano"),
new V3Preset(6, 0, "Grand Piano Vienna - softer", "Grand Piano"),
new V3Preset(7, 0, "Grand Piano Hamburg - softer", "Grand Piano"),
new V3Preset(8, 0, "Honky Tonk", "Grand Piano"),
new V3Preset(9, 0, "Upright Piano Variation", "Grand Piano"),
new V3Preset(10, 0, "Grand Latin Vienna - Octave", "Grand Piano"),
new V3Preset(11, 0, "Grand Latin Hamburg - Octave", "Grand Piano"),
new V3Preset(12, 0, "Grand Vienna Layered EP-FM - - 4", "Grand Piano & Layer"),
new V3Preset(13, 0, "Grand Hamburg Layered MKS - - 3", "Grand Piano & Layer"),
new V3Preset(14, 0, "Grand Vienna Layered E-Piano - - 3", "Grand Piano & Layer"),
new V3Preset(15, 0, "Grand Hamburg Layered MKS + CP80 Attack - - 3", "Grand Piano & Layer"),
new V3Preset(16, 0, "Grand Vienna Layered Pad - - 4", "Grand Piano & Layer"),
new V3Preset(17, 0, "Grand Hamburg Layered Pad - - 4", "Grand Piano & Layer"),
new V3Preset(18, 0, "Grand Vienna Layered Strings - - 4", "Grand Piano & Layer"),
new V3Preset(19, 0, "Grand Hamburg Layered Strings - - 4", "Grand Piano & Layer"),
new V3Preset(20, 0, "Grand Vienna Dream Sus Resonance - - 3", "Grand Piano & Layer"),
new V3Preset(21, 0, "Grand Hamburg Dream Sus Resonance - - 3", "Grand Piano & Layer"),
new V3Preset(22, 0, "Electric Grand - - - 3", "Electric Piano"),
new V3Preset(23, 0, "Electric Grand Rock layer - hard attack - - 4", "Electric Piano"),
new V3Preset(24, 0, "Electric Grand Tremolo 1 - - 3", "Electric Piano"),
new V3Preset(25, 0, "Electric Grand Tremolo 2 - - 3", "Electric Piano"),
new V3Preset(26, 0, "Electric Grand Layered MKS - - 2", "Electric Piano"),
new V3Preset(27, 0, "Electric Grand Layered MKS Rock - - 4", "Electric Piano"),
new V3Preset(28, 0, "Electric Grand use as layer Microphon Attack - dynamic curve - - 1", "Electric Piano"),
new V3Preset(29, 0, "E-Piano MK1 Dyno - velocity splits 9 2", "E-Piano"),
new V3Preset(30, 0, "E-Piano MK1 Dyno soft velocity splits 6 2", "E-Piano"),
new V3Preset(31, 0, "E-Piano MK1 Dyno Tremolo velocity splits 9 2", "E-Piano"),
new V3Preset(32, 0, "E-Piano MK1 Dyno Layered Pad velocity splits 9 4", "E-Piano"),
new V3Preset(33, 0, "E-Piano MK1 Dyno Layered FM velocity splits 9 5", "E-Piano"),
new V3Preset(34, 0, "E-Piano MK1 Dyno Layered MKS Sus. velocity splits 9 3", "E-Piano"),
new V3Preset(35, 0, "E-Piano MK1 Classic - velocity splits 2", "E-Piano"),
new V3Preset(36, 0, "E-Piano MK1 Classic soft velocity splits 2", "E-Piano"),
new V3Preset(37, 0, "E-Piano MK1 Classic Tremolo velocity splits 2", "E-Piano"),
new V3Preset(38, 0, "E-Piano MK1 Classic Layered Bell velocity splits 4", "E-Piano"),
new V3Preset(39, 0, "E-Piano MK1 Classic Layered FM velocity splits 5", "E-Piano"),
new V3Preset(40, 0, "E-Piano MK1 Classic Layered MKS Atk. velocity splits 3", "E-Piano"),
new V3Preset(41, 0, "E-Piano Wurl. A200 - velocity splits 2", "E-Piano"),
new V3Preset(42, 0, "E-Piano Wurl. A200 soft velocity splits 2", "E-Piano"),
new V3Preset(43, 0, "E-Piano Wurl. A200 Tremolo 1 velocity splits 2", "E-Piano"),
new V3Preset(44, 0, "E-Piano Wurl. A200 Tremolo 2 velocity splits 4", "E-Piano"),
new V3Preset(45, 0, "E-Piano Wurl. A200 Tremolo 3 velocity splits 5", "E-Piano"),
new V3Preset(46, 0, "E-Piano Wurl. A200 no tines velocity splits 3", "E-Piano"),
new V3Preset(47, 0, "E-Piano DX Classic - note-off 5", "E-Piano"),
new V3Preset(48, 0, "E-Piano FM - note-off 4", "E-Piano"),
new V3Preset(49, 0, "E-Piano FM Tremolo note-off 4", "E-Piano"),
new V3Preset(50, 0, "E-Piano FM Layered Pad - 5", "E-Piano"),
new V3Preset(51, 0, "E-Piano FM & MKS - Repetition Attack 4", "E-Piano"),
new V3Preset(52, 0, "E-Piano V3 Bella - velocity splits 1", "E-Piano"),
new V3Preset(53, 0, "E-Piano V3 Bella Note off 1 Oct. up velocity splits 2", "E-Piano"),
new V3Preset(54, 0, "E-Piano V3 Bella Layered Cortales velocity splits 3", "E-Piano"),
new V3Preset(55, 0, "E-Piano V3 Bella Layered Pad velocity splits 4", "E-Piano"),
new V3Preset(56, 0, "Clavinet - 2", "Stringed"),
new V3Preset(57, 0, "Harpsichord - 2", "Stringed"),
new V3Preset(58, 0, "Organ 776555678 slow 4", "Organs"),
new V3Preset(59, 0, "Organ 776555678 fast 4", "Organs"),
new V3Preset(60, 0, "Organ 800000000 slow 4", "Organs"),
new V3Preset(61, 0, "Organ 800000000 fast 4", "Organs"),
new V3Preset(62, 0, "Organ 807800000 slow 4", "Organs"),
new V3Preset(63, 0, "Organ 807800000 fast 4", "Organs"),
new V3Preset(64, 0, "Organ 800000008 slow 4", "Organs"),
new V3Preset(65, 0, "Organ 800000008 fast 4", "Organs"),
new V3Preset(66, 0, "Organ 687600000 slow 4", "Organs"),
new V3Preset(67, 0, "Organ 687600000 fast 4", "Organs"),
new V3Preset(68, 0, "Organ 888 perc slow 4", "Organs"),
new V3Preset(69, 0, "Organ Ham Full 4", "Organs"),
new V3Preset(70, 0, "Theatre Organ Mighty Tower 4", "Organs"),
new V3Preset(71, 0, "Combo Organ Vibrato 4", "Organs"),
new V3Preset(72, 0, "Classic Organ Tutti 4", "Organs"),
new V3Preset(73, 0, "Classic Organ Pipe 4", "Organs"),
new V3Preset(74, 0, "Accordion French Musette 4", "Accordions"),
new V3Preset(75, 0, "Accordion French Celeste 4", "Accordions"),
new V3Preset(76, 0, "Accordion Jazz Reed 16´ 2", "Accordions"),
new V3Preset(77, 0, "Harmonica 2", "Accordions"),
new V3Preset(78, 0, "Glockenspiel 1", "Tuned Instruments"),
new V3Preset(79, 0, "Vibraphone 2", "Tuned Instruments"),
new V3Preset(80, 0, "Marimba 1", "Tuned Instruments"),
new V3Preset(81, 0, "Xylophone 1", "Tuned Instruments"),
new V3Preset(82, 0, "Harp 3", "Tuned Instruments"),
new V3Preset(83, 0, "Full Strings Chamber 1 Emotion 6", "Strings"),
new V3Preset(84, 0, "Full Strings Chamber 1 6", "Strings"),
new V3Preset(85, 0, "Full Strings Orchestra 2 6", "Strings"),
new V3Preset(86, 0, "Full Strings Orchestra 3 Emotion 6", "Strings"),
new V3Preset(87, 0, "Full Strings Tremolo 2", "Strings"),
new V3Preset(88, 0, "Full Strings Pizzicato 2", "Strings"),
new V3Preset(89, 0, "Solo Violin Vibrato 2", "Strings"),
new V3Preset(90, 0, "Synth Strings PWM 2", "Strings"),
new V3Preset(91, 0, "Synth Strings analog M12 2", "Strings"),
new V3Preset(92, 0, "Choir Classic Aah 2", "Choir"),
new V3Preset(93, 0, "Choir Pop Ooh 3", "Choir"),
new V3Preset(94, 0, "Trumpet 2", "Brass"),
new V3Preset(95, 0, "Cornet 2", "Brass"),
new V3Preset(96, 0, "Mute Trumpet 2", "Brass"),
new V3Preset(97, 0, "Trombone 2", "Brass"),
new V3Preset(98, 0, "Brass Section Pop 4", "Brass"),
new V3Preset(99, 0, "Brass Section Classic 4", "Brass"),
new V3Preset(100, 0, "Alto Saxophone 2", "Woodwinds"),
new V3Preset(101, 0, "Tenor Saxophone 2", "Woodwinds"),
new V3Preset(102, 0, "Tenor Saxophone - Jazz 2", "Woodwinds"),
new V3Preset(103, 0, "Tenor Saxophone Funky 2", "Woodwinds"),
new V3Preset(104, 0, "Flute 2", "Woodwinds"),
new V3Preset(105, 0, "Oboe 2", "Woodwinds"),
new V3Preset(106, 0, "Englishhorn 2", "Woodwinds"),
new V3Preset(107, 0, "Bassoon 2", "Woodwinds"),
new V3Preset(108, 0, "Clarinet 2", "Woodwinds"),
new V3Preset(109, 0, "Nylon Guitar 2", "Guitar"),
new V3Preset(110, 0, "Jazz Guitar 2", "Guitar"),
new V3Preset(111, 0, "Overdrive Guitar 2", "Guitar"),
new V3Preset(112, 0, "BellPad 4", "Synthesizer"),
new V3Preset(113, 0, "SoftPad 4", "Synthesizer"),
new V3Preset(114, 0, "Classic Polysynth 4", "Synthesizer"),
new V3Preset(115, 0, "Square Lead 4", "Synthesizer"),
new V3Preset(116, 0, "P5Brazz 4", "Synthesizer"),
new V3Preset(117, 0, "SawLead 4", "Synthesizer"),
new V3Preset(118, 0, "HookLead 2", "Synthesizer"),
new V3Preset(119, 0, "Pad 2", "Synthesizer"),
new V3Preset(120, 0, "Bells 2", "Synthesizer"),
new V3Preset(121, 0, "OberBrass 2", "Synthesizer"),
new V3Preset(122, 0, "T8SuperBrass 2", "Synthesizer"),
new V3Preset(123, 0, "Grand Piano & Double bass Splite note 48 - C Repetition & Random 4", "Piano & Bass & Cymbal Split "),
new V3Preset(124, 0, "Grand Piano & Double bass & Ride Splite note 48 - C Repetition & Cym. velo. split 4", "Piano & Bass & Cymbal Split "),
new V3Preset(125, 0, "Grand Piano Vienna Pedal & Sympathetic Resonance 9", "Sympathetic Resonance"),
new V3Preset(126, 0, "Orchestra Percussion Mapping Page 23 2", "Orchestra Percussion"),
new V3Preset(0, 1, "Organ 776555678 slow", "Organ"),
new V3Preset(1, 1, "Organ 776555678 fast", "Organ"),
new V3Preset(2, 1, "Organ 800000568 slow", "Organ"),
new V3Preset(3, 1, "Organ 800000568 fast", "Organ"),
new V3Preset(4, 1, "Organ 008530000 slow", "Organ"),
new V3Preset(5, 1, "Organ 008530000 fast", "Organ"),
new V3Preset(6, 1, "Organ 800000000 slow", "Organ"),
new V3Preset(7, 1, "Organ 800000000 fast", "Organ"),
new V3Preset(8, 1, "Organ 807800000 slow", "Organ"),
new V3Preset(9, 1, "Organ 807800000 fast", "Organ"),
new V3Preset(10, 1, "Organ 804708000 slow", "Organ"),
new V3Preset(11, 1, "Organ 804708000 fast", "Organ"),
new V3Preset(12, 1, "Organ 800008000 slow", "Organ"),
new V3Preset(13, 1, "Organ 800008000 fast", "Organ"),
new V3Preset(14, 1, "Organ 800000008 slow", "Organ"),
new V3Preset(15, 1, "Organ 800000008 fast", "Organ"),
new V3Preset(16, 1, "Organ 687600000 slow", "Organ"),
new V3Preset(17, 1, "Organ 687600000 fast", "Organ"),
new V3Preset(18, 1, "Organ 888 perc slow", "Organ"),
new V3Preset(19, 1, "Rock Organ", "Organ"),
new V3Preset(20, 1, "Ham Full", "Organ"),
new V3Preset(21, 1, "Ham L100 Retro KW1", "Organ"),
new V3Preset(22, 1, "Ham L100 Retro KW2", "Organ"),
new V3Preset(23, 1, "German Organ DB slow", "Organ"),
new V3Preset(24, 1, "German Organ DB fast", "Organ"),
new V3Preset(25, 1, "German Organ FL slow", "Organ"),
new V3Preset(26, 1, "German Organ FL fast", "Organ"),
new V3Preset(27, 1, "Version UK", "Organ"),
new V3Preset(28, 1, "Theatre Organ Mighty Tower", "Organ"),
new V3Preset(29, 1, "Theatre Organ + Xylo Reiteration", "Organ"),
new V3Preset(30, 1, "Theatre Organ + Glocken Reiter.", "Organ"),
new V3Preset(31, 1, "Theatre Organ Piston 2", "Organ"),
new V3Preset(32, 1, "Theatre O. Piston 2+ Xylo Reiteration", "Organ"),
new V3Preset(33, 1, "Theatre O. Piston 2 + Glocken Reiter.", "Organ"),
new V3Preset(34, 1, "Theatre Organ Royal", "Organ"),
new V3Preset(35, 1, "Theatre O. Royal + Xylo Reiteration", "Organ"),
new V3Preset(36, 1, "Theatre O. Royal + Glocken Reiter.", "Organ"),
new V3Preset(37, 1, "Theatre Organ Pedal Bass", "Organ"),
new V3Preset(38, 1, "Organ House", "Organ"),
new V3Preset(39, 1, "Combo Retro Vibrato 1", "Organ"),
new V3Preset(40, 1, "Combo Retro Vibrato 2", "Organ"),
new V3Preset(41, 1, "Classic Organ Tutti 1", "Organ"),
new V3Preset(42, 1, "Classic Organ Tutti 2", "Organ"),
new V3Preset(43, 1, "Classic Organ Pipe Pos Nazard", "Organ"),
new V3Preset(44, 1, "Classic Organ Pipe Combi Funds 8", "Organ"),
new V3Preset(45, 1, "Classic Organ Pedal Flute 16", "Organ"),
new V3Preset(46, 1, "Jimmy Smith 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(47, 1, "Joey DeFrancesco 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(48, 1, "Charles Earland 8 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(49, 1, "Brian Auger 8 8 8 6 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(50, 1, "Garner-Set 8 8 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(51, 1, "Piano Set 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(52, 1, "Walter Wanderley 8 7 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(53, 1, "Whistle 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(54, 1, "Gospel Set 8 8 8 4 4 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(55, 1, "Blues Set 8 8 5 3 2 3 5 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(56, 1, "EasyListening 8 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(57, 1, "Jimmy Smith 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(58, 1, "Jimmy Smith 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(59, 1, "Joey Defrancesco 8 8 7 6 4 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(60, 1, "Ballad 2 8 2 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(61, 1, "Jesse Crawford 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(62, 1, "Joey Defrancesco 8 3 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(63, 1, "Booker T. Jones 8 8 8 6 3 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(64, 1, "Green Onions 8 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(65, 1, "Matthew Fisher 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(66, 1, "Jimmy McGriff Gospel 8 8 8 6 6 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(67, 1, "Chords 4 3 7 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(68, 1, "Chords 8 4 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(69, 1, "Walter Wanderley 8 8 6 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(70, 1, "Walter Wanderley 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(71, 1, "Lenny Dee 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(72, 1, "Lenny Dee 8 8 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(73, 1, "Lenny Dee 8 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(74, 1, "Ethel Smith 8 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(75, 1, "Ken Griffin 8 8 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(76, 1, "Jon Lord 8 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(77, 1, "Jimmy Smith 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(78, 1, "Jimmy Smith 8 8 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(79, 1, "Exclusive 8 8 Perc 2 & 3 Repe.", "Organ - Drawbar Registrations"),
new V3Preset(80, 1, "Exclusive 8 3 8 Perc 2 & 3 Repe.", "Organ - Drawbar Registrations"),
new V3Preset(81, 1, "Standard 8 8 8 7 6 6 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(82, 1, "Standard 8 8 8 5 5 5 6 6 6 Perc 2", "Organ - Drawbar Registrations"),
new V3Preset(83, 1, "Standard8 8 8 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(84, 1, "Standard8 8 8 5 4 4 8 8 8 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(85, 1, "Standard 8 8 8 8 7 6 6 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(86, 1, "Experiment8 8 8 6 Perc 1 exp.", "Organ - Drawbar Registrations"),
new V3Preset(87, 1, "Experiment8 7 6 5 Perc 1 exp.", "Organ - Drawbar Registrations"),
new V3Preset(88, 1, "Experiment8 8 8 8 5 Perc 13/5 exp.", "Organ - Drawbar Registrations"),
new V3Preset(89, 1, "Experiment8 7 6 5 Perc 8 exp.", "Organ - Drawbar Registrations"),
new V3Preset(90, 1, "Standard8 7 6 7 Perc 3", "Organ - Drawbar Registrations"),
new V3Preset(91, 1, "Bars 1st Three + Attack", "Organ - Drawbars"),
new V3Preset(92, 1, "Bars 1st Four + Attack", "Organ - Drawbars"),
new V3Preset(93, 1, "Bar 16 + Attack", "Organ - Drawbars"),
new V3Preset(94, 1, "Bars 16 + 8 + Attack", "Organ - Drawbars"),
new V3Preset(95, 1, "Bar 8 + Attack", "Organ - Drawbars"),
new V3Preset(96, 1, "Bar 5 1/3 + Attack", "Organ - Drawbars"),
new V3Preset(97, 1, "Vib A (HPF)", "Organ - Drawbars"),
new V3Preset(98, 1, "Vib B (HPF)", "Organ - Drawbars"),
new V3Preset(99, 1, "Full Organ (HPF)", "Organ - Drawbars"),
new V3Preset(100, 1, "Highest (HPF)", "Organ - Drawbars"),
new V3Preset(101, 1, "Middle Mixed (HPF)", "Organ - Drawbars"),
new V3Preset(102, 1, "Bars 1st Three", "Organ - Drawbars"),
new V3Preset(103, 1, "Bars 1st Four", "Organ - Drawbars"),
new V3Preset(104, 1, "Bar 16", "Organ - Drawbars"),
new V3Preset(105, 1, "Bar 16 & 8", "Organ - Drawbars"),
new V3Preset(106, 1, "Bar 8", "Organ - Drawbars"),
new V3Preset(107, 1, "Bar 5 1/3", "Organ - Drawbars"),
new V3Preset(108, 1, "Bar 4", "Organ - Drawbars"),
new V3Preset(109, 1, "Bar 2 2/3", "Organ - Drawbars"),
new V3Preset(110, 1, "Bar 2", "Organ - Drawbars"),
new V3Preset(111, 1, "Bar 1 3/5", "Organ - Drawbars"),
new V3Preset(112, 1, "Bar 1 1/3", "Organ - Drawbars"),
new V3Preset(113, 1, "Bar 1", "Organ - Drawbars"),
new V3Preset(114, 1, "Percussion 2", "Organ - Drawbars"),
new V3Preset(115, 1, "Percussion 2 long", "Organ - Drawbars"),
new V3Preset(116, 1, "Percussion 3", "Organ - Drawbars"),
new V3Preset(117, 1, "Percussion 3 long", "Organ - Drawbars"),
new V3Preset(118, 1, "Theatre Organ Glocken Hit", "Organ - Drawbars"),
new V3Preset(119, 1, "Theatre Organ Glocken short", "Organ - Drawbars"),
new V3Preset(120, 1, "Theatre O. Glocken Reiteration", "Organ - Drawbars"),
new V3Preset(121, 1, "Theatre Organ Xylo Hit", "Organ - Drawbars"),
new V3Preset(122, 1, "Theatre Organ Xylo Reiteration", "Organ - Drawbars"),
new V3Preset(123, 1, "Theatre Organ Xylo H & R", "Organ - Drawbars"),
new V3Preset(124, 1, "T. O. Glocken Reiter velocity", "Organ - Drawbars"),
new V3Preset(125, 1, "T. O. Xylo Reiter velocity", "Organ - Drawbars"),
new V3Preset(126, 1, "Organ Click", "Organ - Drawbars"),
new V3Preset(127, 1, "Silence", "Organ - Drawbars"),
new V3Preset(0, 2, "Bells & Pad", "Synthesizer"),
new V3Preset(1, 2, "Digital Pad", "Synthesizer"),
new V3Preset(2, 2, "OBX & Wavebell", "Synthesizer"),
new V3Preset(3, 2, "DX1 Toy", "Synthesizer"),
new V3Preset(4, 2, "Star Them", "Synthesizer"),
new V3Preset(5, 2, "Brightness", "Synthesizer"),
new V3Preset(6, 2, "OB & Noise", "Synthesizer"),
new V3Preset(7, 2, "Atmos", "Synthesizer"),
new V3Preset(8, 2, "Brass Comp", "Synthesizer"),
new V3Preset(9, 2, "Brass Rex", "Synthesizer"),
new V3Preset(10, 2, "Polysynth Classic", "Synthesizer"),
new V3Preset(11, 2, "Halo Pad", "Synthesizer"),
new V3Preset(12, 2, "Caliope", "Synthesizer"),
new V3Preset(13, 2, "Charang", "Synthesizer"),
new V3Preset(14, 2, "Fairly Space", "Synthesizer"),
new V3Preset(15, 2, "Echo Drop", "Synthesizer"),
new V3Preset(16, 2, "VF Vox", "Synthesizer"),
new V3Preset(17, 2, "Bass & Lead", "Synthesizer"),
new V3Preset(18, 2, "Fantasia", "Synthesizer"),
new V3Preset(19, 2, "Bowed Glass", "Synthesizer"),
new V3Preset(20, 2, "Soft Pad", "Synthesizer"),
new V3Preset(21, 2, "Ice Rain", "Synthesizer"),
new V3Preset(22, 2, "Goblin", "Synthesizer"),
new V3Preset(23, 2, "SoundTrack", "Synthesizer"),
new V3Preset(24, 2, "Atmosguitar", "Synthesizer"),
new V3Preset(25, 2, "Bottle soft", "Synthesizer"),
new V3Preset(26, 2, "Polysynth Classic 5th", "Synthesizer"),
new V3Preset(27, 2, "SquareLead", "Synthesizer"),
new V3Preset(28, 2, "P5Brass", "Synthesizer"),
new V3Preset(29, 2, "Saw", "Synthesizer"),
new V3Preset(30, 2, "SawEnv", "Synthesizer"),
new V3Preset(31, 2, "C-Lead", "Synthesizer"),
new V3Preset(32, 2, "SoloVox", "Synthesizer"),
new V3Preset(33, 2, "MetalPad", "Synthesizer"),
new V3Preset(34, 2, "JunoSweep", "Synthesizer"),
new V3Preset(35, 2, "Vangbrass", "Synthesizer"),
new V3Preset(36, 2, "Crystal", "Synthesizer"),
new V3Preset(37, 2, "FM8", "Synthesizer"),
new V3Preset(38, 2, "Mo55", "Synthesizer"),
new V3Preset(39, 2, "DXBell", "Synthesizer"),
new V3Preset(40, 2, "OBS1", "Synthesizer"),
new V3Preset(41, 2, "OBSoft", "Synthesizer"),
new V3Preset(42, 2, "Hook", "Synthesizer"),
new V3Preset(43, 2, "FMPluk", "Synthesizer"),
new V3Preset(44, 2, "FMBrazz", "Synthesizer"),
new V3Preset(45, 2, "Ice", "Synthesizer"),
new V3Preset(46, 2, "BoHook", "Synthesizer"),
new V3Preset(47, 2, "VPhrase", "Synthesizer"),
new V3Preset(48, 2, "VP1", "Synthesizer"),
new V3Preset(49, 2, "Grace", "Synthesizer"),
new V3Preset(50, 2, "Noise", "Synthesizer"),
new V3Preset(51, 2, "Digirace", "Synthesizer"),
new V3Preset(52, 2, "Shinner", "Synthesizer"),
new V3Preset(53, 2, "Pad-A", "Synthesizer"),
new V3Preset(54, 2, "Vibro", "Synthesizer"),
new V3Preset(55, 2, "Digisi", "Synthesizer"),
new V3Preset(56, 2, "Alex", "Synthesizer"),
new V3Preset(57, 2, "VZBell", "Synthesizer"),
new V3Preset(58, 2, "VZ1", "Synthesizer"),
new V3Preset(59, 2, "Mizoo", "Synthesizer"),
new V3Preset(60, 2, "Bellko", "Synthesizer"),
new V3Preset(61, 2, "Bellz", "Synthesizer"),
new V3Preset(62, 2, "AnalogOB", "Synthesizer"),
new V3Preset(63, 2, "M3Osc", "Synthesizer"),
new V3Preset(64, 2, "M12Brass", "Synthesizer"),
new V3Preset(65, 2, "M12Brass ENV", "Synthesizer"),
new V3Preset(66, 2, "OBLead", "Synthesizer"),
new V3Preset(67, 2, "OBArp", "Synthesizer"),
new V3Preset(68, 2, "OBell", "Synthesizer"),
new V3Preset(69, 2, "OBrass", "Synthesizer"),
new V3Preset(70, 2, "Mach1", "Synthesizer"),
new V3Preset(71, 2, "Brazza", "Synthesizer"),
new V3Preset(72, 2, "Brasso", "Synthesizer"),
new V3Preset(73, 2, "T8SuperBrass", "Synthesizer"),
new V3Preset(74, 2, "T8SuperBrass ENV", "Synthesizer"),
new V3Preset(75, 2, "Dells", "Synthesizer"),
new V3Preset(76, 2, "Pulse", "Synthesizer"),
new V3Preset(77, 2, "Pulso", "Synthesizer"),
new V3Preset(78, 2, "PWD24", "Synthesizer"),
new V3Preset(79, 2, "Xypho", "Synthesizer"),
new V3Preset(80, 2, "Charpo", "Synthesizer"),
new V3Preset(81, 2, "Jippo", "Synthesizer"),
new V3Preset(82, 2, "JXArp", "Synthesizer"),
new V3Preset(83, 2, "Bamarimba", "Synthesizer"),
new V3Preset(84, 2, "JCO10", "Synthesizer"),
new V3Preset(85, 2, "JXBell", "Synthesizer"),
new V3Preset(86, 2, "StabBrass", "Synthesizer"),
new V3Preset(87, 2, "Clouds", "Synthesizer"),
new V3Preset(88, 2, "BellHit HP Filter", "Synthesizer"),
new V3Preset(89, 2, "OBNoise", "Synthesizer"),
new V3Preset(90, 2, "Noise down", "Synthesizer"),
new V3Preset(91, 2, "Voxo (Notch filter 12)", "Synthesizer"),
new V3Preset(92, 2, "APad Notch (Notch filter 12)", "Synthesizer"),
new V3Preset(93, 2, "PWD (Notch filter 12)", "Synthesizer"),
new V3Preset(94, 2, "MOSC (Notch filter 12)", "Synthesizer"),
new V3Preset(95, 2, "Square (Band pass filter 24)", "Synthesizer"),
new V3Preset(96, 2, "OXB (Band pass filter 24)", "Synthesizer"),
new V3Preset(97, 2, "Hook (Band pass filter 24)", "Synthesizer"),
new V3Preset(98, 2, "Pulso (Band pass filter 24)", "Synthesizer"),
new V3Preset(99, 2, "Jops (Band pass filter 12)", "Synthesizer"),
new V3Preset(100, 2, "Filter (Band pass filter 24)", "Synthesizer"),
new V3Preset(101, 2, "PolyS (Band pass filter 24)", "Synthesizer"),
new V3Preset(102, 2, "OBLead (Band pass filter 24)", "Synthesizer"),
new V3Preset(103, 2, "JXBell (Notch Filter 24)", "Synthesizer"),
new V3Preset(104, 2, "Barimbo (Band pass filter 24)", "Synthesizer"),
new V3Preset(105, 2, "Arpp (Band pass filter 24)", "Synthesizer"),
new V3Preset(106, 2, "Bottle (High pass filter 12)", "Synthesizer"),
new V3Preset(107, 2, "Jells (Band pass filter 24)", "Synthesizer"),
new V3Preset(108, 2, "Poly (High pass filter 24)", "Synthesizer"),
new V3Preset(109, 2, "Mogo (High pass filter 24)", "Synthesizer"),
new V3Preset(110, 2, "HBells (High pass filter 24)", "Synthesizer"),
new V3Preset(111, 2, "HBelly (High pass filter 6)", "Synthesizer"),
new V3Preset(112, 2, "HBrass (High pass filter 24)", "Synthesizer"),
new V3Preset(113, 2, "ClassicPoly (High pass filter 12)", "Synthesizer"),
new V3Preset(114, 2, "Harppo (High pass filter 24)", "Synthesizer"),
new V3Preset(115, 2, "Hipps (High pass filter 6)", "Synthesizer"),
new V3Preset(116, 2, "Classic Synth Bass", "Synthesizer"),
new V3Preset(117, 2, "Classic Synth Bass Rezo", "Synthesizer"),
new V3Preset(118, 2, "JBass 1", "Synthesizer"),
new V3Preset(119, 2, "JBass 2", "Synthesizer"),
new V3Preset(120, 2, "JBass 3", "Synthesizer"),
new V3Preset(121, 2, "JBass soft", "Synthesizer"),
new V3Preset(122, 2, "CS Classic Bass", "Synthesizer"),
new V3Preset(123, 2, "MoBass", "Synthesizer"),
new V3Preset(124, 2, "MoBass ENV", "Synthesizer"),
new V3Preset(125, 2, "XBass 1", "Synthesizer"),
new V3Preset(126, 2, "XBass 2", "Synthesizer"),
new V3Preset(127, 2, "Silence", "Synthesizer"),
new V3Preset(0, 3, "Glockenspiel", "Percussion Instruments"),
new V3Preset(1, 3, "Music Box", "Percussion Instruments"),
new V3Preset(2, 3, "Music Box Octave", "Percussion Instruments"),
new V3Preset(3, 3, "Vibraphone Tremolo", "Percussion Instruments"),
new V3Preset(4, 3, "Vibraphone Tremolo short", "Percussion Instruments"),
new V3Preset(5, 3, "Vibraphone Tremolo soft", "Percussion Instruments"),
new V3Preset(6, 3, "Vibraphone", "Percussion Instruments"),
new V3Preset(7, 3, "Vibraphone shot", "Percussion Instruments"),
new V3Preset(8, 3, "Vibraphone fast Tremolo", "Percussion Instruments"),
new V3Preset(9, 3, "Celeste", "Percussion Instruments"),
new V3Preset(10, 3, "Tinkle", "Percussion Instruments"),
new V3Preset(11, 3, "Marimba", "Percussion Instruments"),
new V3Preset(12, 3, "Marimba Octave", "Percussion Instruments"),
new V3Preset(13, 3, "Marimba & Xylophon", "Percussion Instruments"),
new V3Preset(14, 3, "Xylophon", "Percussion Instruments"),
new V3Preset(15, 3, "Xylophone Octave", "Percussion Instruments"),
new V3Preset(16, 3, "Tubular Bell", "Percussion Instruments"),
new V3Preset(17, 3, "Tubular Bell 2", "Percussion Instruments"),
new V3Preset(18, 3, "Timpani", "Percussion Instruments"),
new V3Preset(19, 3, "Kalimba", "Percussion Instruments"),
new V3Preset(20, 3, "Cortales", "Percussion Instruments"),
new V3Preset(21, 3, "Steel drums", "Percussion Instruments"),
new V3Preset(22, 3, "Guitar Nylon", "Percussion Instruments"),
new V3Preset(23, 3, "Guitar Nylon soft", "Percussion Instruments"),
new V3Preset(24, 3, "Guitar Nylon Octave", "Percussion Instruments"),
new V3Preset(25, 3, "G. Nylon Slide (velo. 116-127 Slide)", "Percussion Instruments"),
new V3Preset(26, 3, "Guitar Steel", "Percussion Instruments"),
new V3Preset(27, 3, "Guitar Steel soft", "Percussion Instruments"),
new V3Preset(28, 3, "G. Steel Slide (velo. 116-127 Slide)", "Percussion Instruments"),
new V3Preset(29, 3, "Banjo", "Percussion Instruments"),
new V3Preset(30, 3, "Banjo Slide", "Percussion Instruments"),
new V3Preset(31, 3, "Mandoline Ensemble Tremolo", "Percussion Instruments"),
new V3Preset(32, 3, "Mandoline Ensemble", "Percussion Instruments"),
new V3Preset(33, 3, "M. Ens. Split (velo. 116-127 Split)", "Percussion Instruments"),
new V3Preset(34, 3, "Git. Jazz 1", "Stringed Instruments"),
new V3Preset(35, 3, "Git. Jazz 2", "Stringed Instruments"),
new V3Preset(36, 3, "Git. Jazz & Octave", "Stringed Instruments"),
new V3Preset(37, 3, "Pedal Steel Vib.", "Stringed Instruments"),
new V3Preset(38, 3, "Pedal Steel", "Stringed Instruments"),
new V3Preset(39, 3, "Pedal Steel bowed", "Stringed Instruments"),
new V3Preset(40, 3, "P. Steel Slide (velo. 116-127 Slide)", "Stringed Instruments"),
new V3Preset(41, 3, "Git. Jazz Chicken Picking 1", "Stringed Instruments"),
new V3Preset(42, 3, "Git. Jazz Chicken Picking 2", "Stringed Instruments"),
new V3Preset(43, 3, "E-Guitar clean", "Stringed Instruments"),
new V3Preset(44, 3, "E-Guitar Overdrive", "Stringed Instruments"),
new V3Preset(45, 3, "E-Guitar Distortion", "Stringed Instruments"),
new V3Preset(46, 3, "Mute Guitar", "Stringed Instruments"),
new V3Preset(47, 3, "Harpsichord", "Stringed Instruments"),
new V3Preset(48, 3, "Harpsichord & Octave", "Stringed Instruments"),
new V3Preset(49, 3, "Clavinet 1", "Stringed Instruments"),
new V3Preset(50, 3, "Clavinet 2", "Stringed Instruments"),
new V3Preset(51, 3, "Dulcimer 3 strings", "Stringed Instruments"),
new V3Preset(52, 3, "Dulcimer 3 strings+", "Stringed Instruments"),
new V3Preset(53, 3, "Dulcimer 3 strings Tremolo", "Stringed Instruments"),
new V3Preset(54, 3, "Dulcimer 3 strings bowed", "Stringed Instruments"),
new V3Preset(55, 3, "Dulcimer 5 strings", "Stringed Instruments"),
new V3Preset(56, 3, "Dulcimer 5 strings+", "Stringed Instruments"),
new V3Preset(57, 3, "Dulcimer 5 strings Tremolo", "Stringed Instruments"),
new V3Preset(58, 3, "Dulcimer 5 strings bowed", "Stringed Instruments"),
new V3Preset(59, 3, "Harp", "Stringed Instruments"),
new V3Preset(60, 3, "Harp long", "Stringed Instruments"),
new V3Preset(61, 3, "Sitar", "Stringed Instruments"),
new V3Preset(62, 3, "Shamisen", "Stringed Instruments"),
new V3Preset(63, 3, "Koto", "Stringed Instruments"),
new V3Preset(64, 3, "Shanai", "Stringed Instruments"),
new V3Preset(65, 3, "Upright Jazz Bass Random", "Bass"),
new V3Preset(66, 3, "Upright Jazz Bass Random Note off", "Bass"),
new V3Preset(67, 3, "Upright Jazz Bass velo 96 - 105", "Bass"),
new V3Preset(68, 3, "Upright Jazz Bass velo 96 - 105 Note off", "Bass"),
new V3Preset(69, 3, "Upright Jazz Bass velo. 120", "Bass"),
new V3Preset(70, 3, "Upright Jazz Bass velo. 120 Note off", "Bass"),
new V3Preset(71, 3, "Upright Jazz Bass no finger attack", "Bass"),
new V3Preset(72, 3, "Upright Bass finger attack", "Bass"),
new V3Preset(73, 3, "Upright Bass more finger attack", "Bass"),
new V3Preset(74, 3, "Upright Bass no finger attack", "Bass"),
new V3Preset(75, 3, "Bowed Upright Bass", "Bass"),
new V3Preset(76, 3, "Bowed Upright Bass shorter release", "Bass"),
new V3Preset(77, 3, "E-Bass Flat", "Bass"),
new V3Preset(78, 3, "E-Bass Flat Repetition", "Bass"),
new V3Preset(79, 3, "E-Bass US 1", "Bass"),
new V3Preset(80, 3, "E-Bass US 2", "Bass"),
new V3Preset(81, 3, "E-Bass US 2 Filter", "Bass"),
new V3Preset(82, 3, "E-Bass Pick", "Bass"),
new V3Preset(83, 3, "E-Bass Pick dark", "Bass"),
new V3Preset(84, 3, "EBass Fretless", "Bass"),
new V3Preset(85, 3, "Slap Bass", "Bass"),
new V3Preset(86, 3, "Slap Bass", "Bass"),
new V3Preset(87, 3, "EB & Baritone horn layered", "Bass"),
new V3Preset(88, 3, "Accordion Musette VM German", "Accordion"),
new V3Preset(89, 3, "Accordion Musette VM +16 German", "Accordion"),
new V3Preset(90, 3, "Accordion Musette VM +4+16 German", "Accordion"),
new V3Preset(91, 3, "Accordion Musette Gala Italian", "Accordion"),
new V3Preset(92, 3, "Accordion Musette French", "Accordion"),
new V3Preset(93, 3, "Accordion Musette +16 French", "Accordion"),
new V3Preset(94, 3, "Accordion Musette +4 French", "Accordion"),
new V3Preset(95, 3, "Accordion Musette +4+16 French", "Accordion"),
new V3Preset(96, 3, "Accordion French Celeste French", "Accordion"),
new V3Preset(97, 3, "Accordion French Celeste +4 French", "Accordion"),
new V3Preset(98, 3, "Accordion French Celeste +16 French", "Accordion"),
new V3Preset(99, 3, "Accordion French Celeste +4+16 French", "Accordion"),
new V3Preset(100, 3, "Accordion 4+16 universal", "Accordion"),
new V3Preset(101, 3, "Accordion 4+8+16 universal", "Accordion"),
new V3Preset(102, 3, "Tango French", "Accordion"),
new V3Preset(103, 3, "Tango +4 French", "Accordion"),
new V3Preset(104, 3, "Accordion 8+16 universal", "Accordion"),
new V3Preset(105, 3, "Accordion 4+8+16 universal", "Accordion"),
new V3Preset(106, 3, "Reed 4+8", "Accordion"),
new V3Preset(107, 3, "Reed 8+8", "Accordion"),
new V3Preset(108, 3, "Accordion Celeste 88", "Accordion"),
new V3Preset(109, 3, "Accordion Celeste 88 +", "Accordion"),
new V3Preset(110, 3, "Accordion Celeste 88 ++", "Accordion"),
new V3Preset(111, 3, "Reed 16", "Accordion"),
new V3Preset(112, 3, "Reed 8 Casotto", "Accordion"),
new V3Preset(113, 3, "Reed 8", "Accordion"),
new V3Preset(114, 3, "Reed 4", "Accordion"),
new V3Preset(115, 3, "Melodeon Austrian", "Accordion"),
new V3Preset(116, 3, "Melodeon Irish", "Accordion"),
new V3Preset(117, 3, "Accordina", "Accordion"),
new V3Preset(118, 3, "Harmonica", "Accordion"),
new V3Preset(119, 3, "Harmonica Slide velo. 116-127 Slide", "Accordion"),
new V3Preset(120, 3, "E-Accordion Retro", "Accordion"),
new V3Preset(121, 3, "E-Accordion Retro long release", "Accordion"),
new V3Preset(127, 3, "Silence no sound", "Accordion"),
new V3Preset(00, 4,  "Full Strings 1 Chamber Emotion velocity to attack", "Strings Ensembles"),
new V3Preset(01, 4,  "Full Strings 1 Chamber short Release shot", "Strings Ensembles"),
new V3Preset(02, 4,  "Full Strings 1 Chamber medium Release medium", "Strings Ensembles"),
new V3Preset(03, 4,  "Full Strings 1 Chamber long Release long", "Strings Ensembles"),
new V3Preset(04, 4,  "Full Strings 1 Chamber slow Slow Attack", "Strings Ensembles"),
new V3Preset(05, 4,  "Full Strings 2 short Release shot", "Strings Ensembles"),
new V3Preset(06, 4,  "Full Strings 2 medium Release medium", "Strings Ensembles"),
new V3Preset(07, 4,  "Full Strings 2 long Release long", "Strings Ensembles"),
new V3Preset(08, 4,  "Full Strings 2 forte forte only", "Strings Ensembles"),
new V3Preset(09, 4,  "Full Strings 2 piano piano only", "Strings Ensembles"),
new V3Preset(10, 4,  "Full Strings 3 Emotion velocity to attack", "Strings Ensembles"),
new V3Preset(11, 4,  "Full Strings 3 FAD layered 4", "Strings Ensembles"),
new V3Preset(12, 4,  "Full Strings 3 slow slow", "Strings Ensembles"),
new V3Preset(13, 4,  "Full Strings 3 standard", "Strings Ensembles"),
new V3Preset(14, 4,  "Full Strings Tremolo", "Strings Ensembles"),
new V3Preset(15, 4,  "Full Strings Pizzicato", "Strings Ensembles"),
new V3Preset(16, 4,  "Disco Strings long", "Strings Ensembles"),
new V3Preset(17, 4,  "Disco Strings short", "Strings Ensembles"),
new V3Preset(18, 4,  "Disco Strings Glide down", "Strings Ensembles"),
new V3Preset(19, 4,  "Disco Strings Slide velo. 116-127 Slide", "Strings Ensembles"),
new V3Preset(20, 4,  "String Ensemble Detache Dynamic curve 1", "Strings Ensembles"),
new V3Preset(21, 4,  "String Ensemble Detache Dynamic curve 2", "Strings Ensembles"),
new V3Preset(22, 4,  "Violin", "Solo Strings"),
new V3Preset(23, 4,  "Viola", "Solo Strings"),
new V3Preset(24, 4,  "Cello", "Solo Strings"),
new V3Preset(25, 4,  "Contrabass", "Solo Strings"),
new V3Preset(26, 4,  "Celtic fiddle", "Solo Strings"),
new V3Preset(27, 4,  "Celtic fiddle (softer attack)", "Solo Strings"),
new V3Preset(28, 4,  "C. fiddle Slide (velo. 116-127 Slide)", "Solo Strings"),
new V3Preset(29, 4,  "Strings PWM A", "Synth Strings"),
new V3Preset(30, 4,  "Strings PWM B", "Synth Strings"),
new V3Preset(31, 4,  "Strings PWM C", "Synth Strings"),
new V3Preset(32, 4,  "Strings PWM D", "Synth Strings"),
new V3Preset(33, 4,  "Strings MKS 70A", "Synth Strings"),
new V3Preset(34, 4,  "Strings MKS 70B", "Synth Strings"),
new V3Preset(35, 4,  "Strings MKS 70C", "Synth Strings"),
new V3Preset(36, 4,  "Strings MKS 70D", "Synth Strings"),
new V3Preset(37, 4,  "Strings Retro Solino", "Synth Strings"),
new V3Preset(38, 4,  "Stringmaster Retro", "Synth Strings"),
new V3Preset(39, 4,  "Strings M12A", "Synth Strings"),
new V3Preset(40, 4,  "Strings M12B", "Synth Strings"),
new V3Preset(41, 4,  "Strings M12C", "Synth Strings"),
new V3Preset(42, 4,  "Strings M12D", "Synth Strings"),
new V3Preset(43, 4,  "Strings M12E", "Synth Strings"),
new V3Preset(44, 4,  "Strings M12F", "Synth Strings"),
new V3Preset(45, 4,  "Strings MKS 30A", "Synth Strings"),
new V3Preset(46, 4,  "Strings MKS 30B", "Synth Strings"),
new V3Preset(47, 4,  "Strings MKS 30C", "Synth Strings"),
new V3Preset(48, 4,  "Analog Strings", "Synth Strings"),
new V3Preset(49, 4,  "Analog Strings", "Synth Strings"),
new V3Preset(50, 4,  "Analog Strings", "Synth Strings"),
new V3Preset(51, 4,  "JP Strings A", "Synth Strings"),
new V3Preset(52, 4,  "JP Strings B", "Synth Strings"),
new V3Preset(53, 4,  "JP Strings C", "Synth Strings"),
new V3Preset(54, 4,  "JP Strings D", "Synth Strings"),
new V3Preset(55, 4,  "MKS Strings 80A", "Synth Strings"),
new V3Preset(56, 4,  "MKS Strings 80B", "Synth Strings"),
new V3Preset(57, 4,  "MKS Strings 80C", "Synth Strings"),
new V3Preset(58, 4,  "OB Strings A", "Synth Strings"),
new V3Preset(59, 4,  "OB Strings B", "Synth Strings"),
new V3Preset(60, 4,  "OBA Strings", "Synth Strings"),
new V3Preset(64, 4,  "Classic Choir Aah", "Choir"),
new V3Preset(65, 4,  "Classic Choir Aah Filter", "Choir"),
new V3Preset(66, 4,  "Classic Choir Ooh", "Choir"),
new V3Preset(67, 4,  "Classic Choir Ooh Filter", "Choir"),
new V3Preset(68, 4,  "Choir Ooh", "Choir"),
new V3Preset(69, 4,  "Choir Ooh Filter", "Choir"),
new V3Preset(70, 4,  "Boys Aah", "Choir"),
new V3Preset(71, 4,  "Boys Ohh", "Choir"),
new V3Preset(72, 4,  "Boys Doo", "Choir"),
new V3Preset(73, 4,  "Boys Doo Bass", "Choir"),
new V3Preset(74, 4,  "Girls Aah", "Choir"),
new V3Preset(75, 4,  "Girls Ohh", "Choir"),
new V3Preset(76, 4,  "Girls Doo", "Choir"),
new V3Preset(77, 4,  "Boys & Girls Octave Ahh", "Choir"),
new V3Preset(78, 4,  "Boys & Girls Octave Doo", "Choir"),
new V3Preset(79, 4,  "Synth Voice", "Choir"),
new V3Preset(80, 4,  "Voiceless", "Choir"),
new V3Preset(100, 4,  "Orch Hit Major", "Choir"),
new V3Preset(101, 4,  "Orch Hit Minor", "Choir"),
new V3Preset(120, 4,  "Pop Drum Kit (page 43)", "Drums & Percussion"),
new V3Preset(121, 4,  "Jazz Drum Kit (page 43)", "Drums & Percussion"),
new V3Preset(122, 4,  "Orchestra Percussion (page 43)", "Drums & Percussion"),
new V3Preset(123, 4,  "Voice Kit (page 43)", "Drums & Percussion"),
new V3Preset(0, 5, "Trumpet velo. split 48 - 96", "Brass"),
new V3Preset(1, 5, "Trumpet velo. split 64", "Brass"),
new V3Preset(2, 5, "Trumpet piano", "Brass"),
new V3Preset(3, 5, "Trumpet mezzo", "Brass"),
new V3Preset(4, 5, "Trumpet forte", "Brass"),
new V3Preset(5, 5, "Trumpet fall Split velo. 116-127 fall", "Brass"),
new V3Preset(6, 5, "Trumpet goup Split velo. 116-127 goup", "Brass"),
new V3Preset(7, 5, "Trumpet Slide velo. 116-127 Slide", "Brass"),
new V3Preset(8, 5, "Forte Trumpet vibrato Repetition", "Brass"),
new V3Preset(9, 5, "Cornet Repetition", "Brass"),
new V3Preset(10, 5, "Cornet soft Repetition", "Brass"),
new V3Preset(11, 5, "Cornet hard Repetition", "Brass"),
new V3Preset(12, 5, "Cornet porta attack Repetition", "Brass"),
new V3Preset(13, 5, "Trumpet mute", "Brass"),
new V3Preset(14, 5, "Trumpet mute AV", "Brass"),
new V3Preset(15, 5, "Flugelhorn", "Brass"),
new V3Preset(16, 5, "Trombone", "Brass"),
new V3Preset(17, 5, "Horn", "Brass"),
new V3Preset(18, 5, "Bariton horn vibrato", "Brass"),
new V3Preset(19, 5, "Bariton horn staccato", "Brass"),
new V3Preset(20, 5, "Tuba", "Brass"),
new V3Preset(21, 5, "Tuba soft", "Brass"),
new V3Preset(32, 5, "US Trumpet Section dynamic split", "Brass Section"),
new V3Preset(33, 5, "US Trumpet Section forte forte", "Brass Section"),
new V3Preset(34, 5, "US Trumpet Section mezzo mezzo", "Brass Section"),
new V3Preset(35, 5, "US Trumpet Section fast fall fast fall", "Brass Section"),
new V3Preset(36, 5, "US Trumpet Section Split velo. 116-127 fall", "Brass Section"),
new V3Preset(37, 5, "US Trombone Section dynamic split", "Brass Section"),
new V3Preset(38, 5, "US Trombone Section forte forte", "Brass Section"),
new V3Preset(39, 5, "US Trombone Section mezzo mezzo", "Brass Section"),
new V3Preset(40, 5, "US Trombone Section fast fall fast fall", "Brass Section"),
new V3Preset(41, 5, "US Trombone Section Split velo. 116-127 fall", "Brass Section"),
new V3Preset(42, 5, "US Trump. & Trombone Section dynamic split", "Brass Section"),
new V3Preset(43, 5, "US Trump. & Trombone Section forte forte", "Brass Section"),
new V3Preset(44, 5, "US Trump. & Trombone Section mz mezzo", "Brass Section"),
new V3Preset(45, 5, "Classic Trumpet Ensemble dynamic split", "Brass Section"),
new V3Preset(46, 5, "Classic Trumpet Ensemble piano piano", "Brass Section"),
new V3Preset(47, 5, "Classic Trombone Ensemble dynamic split", "Brass Section"),
new V3Preset(48, 5, "Classic Trombone Ensemble piano", "Brass Section"),
new V3Preset(49, 5, "Classic Horn Ensemble", "Brass Section"),
new V3Preset(50, 5, "Classic Full Brass dynamic split", "Brass Section"),
new V3Preset(51, 5, "Classic Full Brass+ forte", "Brass Section"),
new V3Preset(63, 5, "Soprano Saxophone dynamic split", "Saxophone"),
new V3Preset(64, 5, "Soprano Saxophone softer softer zones", "Saxophone"),
new V3Preset(65, 5, "Soprano Saxophone harder harder zones", "Saxophone"),
new V3Preset(66, 5, "Soprano Saxophone breath breath noise", "Saxophone"),
new V3Preset(67, 5, "Soprano Saxophone Slide velo. 116-127 slide", "Saxophone"),
new V3Preset(68, 5, "Soprano 2 more Vibrato", "Saxophone"),
new V3Preset(69, 5, "Alto Saxophone dynamic split", "Saxophone"),
new V3Preset(70, 5, "Alto Saxophone softer softer zones", "Saxophone"),
new V3Preset(71, 5, "Alto Saxophone harder harder zones", "Saxophone"),
new V3Preset(72, 5, "Alto Saxophone breath breath noise", "Saxophone"),
new V3Preset(73, 5, "Alto Saxophone Slide velo. 116-127 slide", "Saxophone"),
new V3Preset(74, 5, "Tenor Saxophone dynamic split", "Saxophone"),
new V3Preset(75, 5, "Tenor Saxophone softer softer zones", "Saxophone"),
new V3Preset(76, 5, "Tenor Saxophone harder harder zones", "Saxophone"),
new V3Preset(77, 5, "Tenor Saxophone breath breath noise", "Saxophone"),
new V3Preset(78, 5, "Tenor Saxophone Slide velo. 116-127 slide", "Saxophone"),
new V3Preset(79, 5, "Max Jazz Tenor velo. split 116 Random Key & breath noise", "Saxophone"),
new V3Preset(80, 5, "Max Jazz Tenor velo. split 64 Random Key & breath noise", "Saxophone"),
new V3Preset(81, 5, "Max Jazz Tenor soft soft only Random Key & breath noise", "Saxophone"),
new V3Preset(82, 5, "Max Jazz Tenor velo. split 96", "Saxophone"),
new V3Preset(83, 5, "Max Jazz Tenor Vibrato less delay velo. split 96", "Saxophone"),
new V3Preset(84, 5, "Max Jazz Tenor soft soft only breath noise", "Saxophone"),
new V3Preset(85, 5, "Max Jazz Tenor Slide velo. 116-127 slide Random Key & breath noise", "Saxophone"),
new V3Preset(86, 5, "Max Jazz Tenor Slide soft velo. 116-127 slide Random Key & breath noise", "Saxophone"),
new V3Preset(87, 5, "Tenor Saxophone Funky", "Saxophone"),
new V3Preset(88, 5, "Tenor Saxophone Funky growl", "Saxophone"),
new V3Preset(89, 5, "Tenor Saxophone Funky Split velo. split 116", "Saxophone"),
new V3Preset(90, 5, "Baritone Saxophone", "Saxophone"),
new V3Preset(91, 5, "Saxophone Section 1", "Saxophone"),
new V3Preset(92, 5, "Saxophone Section 2", "Saxophone"),
new V3Preset(93, 5, "Oboe", "Winds"),
new V3Preset(94, 5, "Englishhorn", "Winds"),
new V3Preset(95, 5, "Bassoon", "Winds"),
new V3Preset(96, 5, "Clarinet", "Winds"),
new V3Preset(97, 5, "Clarinet soft", "Winds"),
new V3Preset(98, 5, "Cla. Slide (velo. 116-127) velo. 116-127 Slide", "Winds"),
new V3Preset(99, 5, "Hugo Clarinet no loop", "Winds"),
new V3Preset(100, 5, "Hugo Cla. Slide (velo. 116-127) velo. 116-127 Slide no loop", "Winds"),
new V3Preset(101, 5, "Piccolo", "Winds"),
new V3Preset(102, 5, "Flute", "Winds"),
new V3Preset(103, 5, "Flute EQ", "Winds"),
new V3Preset(104, 5, "Flute High Pass Filter", "Winds"),
new V3Preset(105, 5, "Panflute", "Winds"),
new V3Preset(106, 5, "Shakuhachi", "Winds"),
new V3Preset(107, 5, "Celtic High Whistle", "Winds"),
new V3Preset(108, 5, "Celtic High Whistle Grace note AV Auto Grace note", "Winds"),
new V3Preset(109, 5, "C. High Wh. Slide (velo. 116-127) velo. 116-127 Slide", "Winds"),
new V3Preset(110, 5, "Bottle", "Winds"),
new V3Preset(111, 5, "Bottle soft", "Winds"),
new V3Preset(112, 5, "Bottle Q", "Winds"),
new V3Preset(113, 5, "Bottle LFO", "Winds"),
new V3Preset(114, 5, "Whistle", "Winds"),
new V3Preset(115, 5, "Whistle GS", "Winds"),
new V3Preset(116, 5, "Hl. Pipers & Drone (split note 60-c1) split note 60 - c1", "Winds"),
new V3Preset(117, 5, "Ullian Piper & Drone Repetition", "Winds"),
new V3Preset(118, 5, "Ullian Piper & Drone Grace note AV Auto Grace note Repetition", "Winds"),
new V3Preset(119, 5, "U. Piper & Dr. Slide (velo. 116-127) velo. 116-127 Slide", "Winds"),
new V3Preset(120, 5, "Ullian Drone & Chords", "Winds"),

] @=> static V3Preset @ v3Presets[];

}

// V3GrandPiano is a class that represents a V3 grand piano in the framework.
// It extends Patch and adds a program change flag and preset.
//
// This class is used to create V3 grand piano patches for MIDI devices.
public class V3GrandPiano extends Patch
{
    int programChange;

    fun V3GrandPiano()
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        0 => midiChannel;
        0 => program;
        0 => bank;
        true => programChange;
        "Grand Piano Vienna" => patchName;
    }

    fun V3GrandPiano(int channel, int b, int p, int v)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        Patch(v);
    }

    fun V3GrandPiano(int channel, int v)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        Patch(v);
    }

    fun V3GrandPiano(int channel, string presetName, int v)
    {
        V3PresetCollection collection;
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        collection.getPreset(presetName) @=> V3Preset preset;
        preset.program => program;
        preset.bank => bank;
        true => programChange;
        preset.name => patchName;
        Patch(v);
    }

    fun void setPreset()
    {
        if (programChange) 
        {
            programChangeV3GrandPiano(program, bank);
            0.1::second => now;
        }
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
        config.SetInt("programChange", programChange);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            config.GetInt("program") => program;
        }
        if (config.findChild("bank") >= 0) {
            config.GetInt("bank") => bank;
        }
        true => programChange;
        if (patchName == "") {
            "Grand Piano Vienna" => patchName;
        }
        updateControllers();
    }
}

