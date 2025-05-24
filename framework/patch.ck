public class Patch 
{
    string deviceName;
    int midiChannel;
    string patchName;
    int volume;
    string uiName;

    MidiOut gma;

    fun Patch()
    {   
        if (deviceName != "") 
        {
            gma.open(deviceName) => int status;
            <<< "Device open status:", status, "name:", gma.name() >>>;
            setPreset();
            <<< "Patch Name: ", patchName >>>;
        }
        127 => volume;
    }

    fun void setPreset() {
    }

    fun void sendControllerChange(int controller, int value)
    {
        MidiMsg msg;
        0xB0 | midiChannel => msg.data1;
        controller => msg.data2;
        value => msg.data3;
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

    fun void noteOn(int note, int velocity, dur duration)
    {
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
        MidiMsg msg;
        0x80 | midiChannel => msg.data1;
        note => msg.data2;
        gma.send(msg);
    }

    fun noteOffFun(int note, dur duration)
    {
        duration => now;
        noteOff(note);
        duration => now;
    }
}

public class Hydrasynth extends Patch
{
    string presetName;

    fun Hydrasynth(string preset)
    {
        "HYDRASYNTH EXPLORER" => deviceName;
        "Hydrasynth" => uiName;
        0 => midiChannel;
        preset => presetName;
        preset => patchName;
        Patch();
    }

    fun void setPreset()
    {
        if (presetName != "") 
        {
            presetName.substring(0, 1) => string bankStr;
            presetName.substring(1) => string programStr;
            bankStr.charAt(0) - "A".charAt(0) => int bank;
            programStr.toInt() => int program;
            programChangeHydra(program-1, bank);
        }
    }
}

public class RolandS1 extends Patch
{
    int program;
    int bank;

    fun RolandS1(int b, int p)
    {
        "S-1 MIDI IN" => deviceName;
        "S-1" => uiName;
        2 => midiChannel;
        p => program;
        b => bank;
        "S1 bank " + Std.itoa(bank) + " program: ", Std.itoa(program) => patchName;
        Patch();
    }

    fun void setPreset()
    {
        (bank - 1) * 16 + program - 1 => int preset; 
        <<< "S1 preset:", preset >>>;
        programChangeS1(preset);
    }
}

public class RolandSH4d extends Patch
{
    int program;
    int bank;
    int programChange;

    fun RolandSH4d(int channel, int b, int p)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        "SH-4d bank " + Std.itoa(bank) + " program: ", Std.itoa(program) => patchName;
        Patch();
    }

    fun RolandSH4d(int channel, string pName)
    {
        "SH-4d" => deviceName;
        "SH-4d" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        pName => patchName;
        Patch();
    }

    fun void setPreset()
    {
        if (programChange) 
        {
            (bank - 1) * 16 + program - 1 => int preset; 
            <<< "SH4d preset:", preset >>>;
            programChangeSH4d(preset);
        }
    }
}

public class BehringerRD6 extends Patch
{
    string presetName;

    fun BehringerRD6()
    {
        "RHYTHM DESIGNER RD-6" => deviceName;
        "RD-6" => uiName;
        0 => midiChannel;
        "RHYTHM DESIGNER RD-6" => patchName;

        Patch();
    }

    fun void setPreset()
    {
    }
}

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
        for( V3Preset preset: v3Presets) {
            if (preset.name == presetName)
            return preset;
        }
        <<< "Can't find preset: ", presetName >>>;
        return v3Presets[0];
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

public class V3GrandPiano extends Patch
{
    int program;
    int bank;
    int programChange;
    V3Preset preset();

    fun V3GrandPiano(int channel, int b, int p)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        Patch();
    }

    fun V3GrandPiano(int channel)
    {
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        Patch();
    }

    fun V3GrandPiano(int channel, string presetName)
    {
        V3PresetCollection collection;
        "U2MIDI Pro" => deviceName;
        "V3" => uiName;
        channel - 1 => midiChannel;
        collection.getPreset(presetName) @=> V3Preset preset;
        preset.program => program;
        preset.bank => bank;
        true => programChange;
        presetName => patchName;
        Patch();
    }

    fun void setPreset()
    {
        if (programChange) 
        {
            programChangeV3GrandPiano(program, bank);
        }
    }

}

