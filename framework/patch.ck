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

    fun void programChange(int program, int bank)
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
            programChange(program-1, bank);
        }
    }
}

public class RolandS1 extends Patch
{
    string presetName;

    fun RolandS1(string preset)
    {
        "S-1 MIDI IN" => deviceName;
        2 => midiChannel;
        preset => presetName;
        Patch();
    }

    fun void setPreset()
    {
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

