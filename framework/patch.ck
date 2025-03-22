public class Patch 
{
    string deviceName;
    int midiChannel;

    MidiOut gma;

    fun Patch()
    {   if (deviceName != "") 
        {
            gma.open(deviceName) => int status;
            <<< "Device open status:", status, "name:", gma.name() >>>;
            setPreset();
        }
    }

    fun void setPreset() {
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
        0 => midiChannel;
        preset => presetName;
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
        2 => midiChannel;
        p => program;
        b => bank;
        Patch();
    }

    fun void setPreset()
    {
        (bank - 1) * 16 + program - 1 => int preset; 
        <<< "S1 preset: ", preset >>>;
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
        channel - 1 => midiChannel;
        p => program;
        b => bank;
        true => programChange;
        Patch();
    }

    fun RolandSH4d(int channel)
    {
        "SH-4d" => deviceName;
        channel - 1 => midiChannel;
        0 => program;
        0 => bank;
        false => programChange;
        Patch();
    }

    fun void setPreset()
    {
        if (programChange) 
        {
            (bank - 1) * 16 + program - 1 => int preset; 
            <<< "SH4d preset: ", preset >>>;
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
        0 => midiChannel;
        Patch();
    }

    fun void setPreset()
    {
    }
}

