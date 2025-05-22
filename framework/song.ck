@import "patch.ck"
@import "../framework/midi-events.ck"

// Overall structure of a song

public class Song 
{
    // Tempo in beats-per-minute
    float BPM;
    // Duration of a single beat. Set from BPM;
    dur beat;
    // Root-note of chords, as a midi note number
    int rootNote;

    // All the parts playing in parallel
    Part @ parts[];

    // One patch per midi device
    Patch @ devices[16];

    // All the Fragments. A song can have Parts or Fragments, but not both
    Fragment @ startFragment;
    Fragment @ currentFragment;

    int forever;

    // Interactive controls
    static int pause;
    static int debug;
    static int golden;
    static int shuttingDown;

    // All the currently active shreds playing parts
    static Shred shreds[];

    LaunchControl @ launchControl;
    MidiMapper @ hydraEvents;
    
    if (startFragment != null) {
    }


    fun Song(float bpm, int root, Part allParts[])
    {
        setBPM(bpm);
        root => rootNote;
        allParts @=> parts;
        false => forever;
        false => pause;
        false => debug;
        false => shuttingDown;
        false => golden;
        initDevicesFromParts();
        <<< "*** Devices ***", "" >>>;
        for(0 => int i; i < devices.cap(); i++) {
            if (devices[i] == null) {
                break;
            }
            devices[i] @=> Patch device;
            <<< "Device:", i, device.deviceName, "Preset:", device.patchName, "Channel:", device.midiChannel >>>;
        }
    }

    fun Song(float bpm, int root, Fragment startFrag)
    {
        setBPM(bpm);
        root => rootNote;
        startFrag @=> startFragment;
        .25::second => now;
        false => pause;
        false => debug;
        false => shuttingDown;
        false => golden;
        new MidiMapper("HYDRASYNTH EXPLORER", "U2MIDI Pro", 1) @=> hydraEvents;
        <<< "Adding Launch Control to:", this >>>;
        new LaunchControl(this) @=> launchControl;

        spork ~ hydraEvents.startEventLoop();       
        spork ~ launchControl.startEventLoop();
        spork ~ keyboardLoop(); 
    }

    fun Song(float bpm, int root, Fragment startFrag, Part allParts[]))
    {
        setBPM(bpm);
        root => rootNote;
        allParts @=> parts;
        startFrag @=> startFragment;
        .25::second => now;
        false => pause;
        false => debug;
        false => shuttingDown;
        false => golden;
        initDevicesFromParts();
        new MidiMapper("HYDRASYNTH EXPLORER", "U2MIDI Pro", 1) @=> hydraEvents;
        <<< "Adding Launch Control to:", this >>>;
        new LaunchControl(this) @=> launchControl;

        spork ~ hydraEvents.startEventLoop();       
        spork ~ launchControl.startEventLoop();
        spork ~ keyboardLoop(); 
    }

    fun initDevicesFromParts()
    {
        for(0 => int i; i < parts.cap(); i++) 
        {
            parts[i] @=> Part part;
            part.patch @=> Patch patch;
            for(0 => int j; j < devices.cap(); j++) 
            {
                if (devices[j] == null) 
                {
                    patch @=> devices[j];
                    break;
                }
                if (patch.deviceName == devices[j].deviceName &&
                    patch.midiChannel == devices[j].midiChannel) 
                    {
                        break;
                    }
            }
        }
    }

    V3PresetCollection presets;

    fun string getPresetDeclaration(V3Preset preset)
    {
        return "V3GrandPiano instrument(" + Std.itoa(hydraEvents.outputChannel+1) + ", \"" + preset.name + "\");";
    }

    fun setNextPreset() 
    {
        presets.getNextPreset() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);

        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setNextPresetCategory() 
    {
        presets.getNextCategory() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        <<< "Category:", preset.category >>>;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setPreviousPreset() 
    {
        presets.getPreviousPreset() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setPreviousPresetCategory() 
    {
        presets.getPreviousCategory() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        <<< "Category:", preset.category >>>;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun keyboardLoop()
    {
        KBHit kb;

        // time-loop
        while( true )
        {
            // wait on kbhit event
            kb => now;

            // potentially more than 1 key at a time
            while( kb.more() )
            {
                // print key value
                kb.getchar() => int key;
                if (debug) {
                    <<< "ascii: ", key >>>;
                }
                if (key >= "1".charAt(0) && key <= "9".charAt(0)) {
                    key - "1".charAt(0) => hydraEvents.outputChannel;
                    <<< "Setting midi mapper out:", hydraEvents.outputChannel+1 >>>;
                }
                if ("q".charAt(0) == key) {
                    shutdown();
                }
                if ("n".charAt(0) == key) {
                    setNextPreset();
                }
                if ("m".charAt(0) == key) {
                    setPreviousPreset();
                }
                if ("N".charAt(0) == key) {
                    setNextPresetCategory();
                }
                if ("M".charAt(0) == key) {
                    setPreviousPresetCategory();
                }
                if ("p".charAt(0) == key) {
                    !pause => pause;
                    <<< "Pause: ", pause >>>;
                }
                if ("g".charAt(0) == key) {
                    !golden => golden;
                    <<< "Golden: ", golden >>>;
                }
            }
        }
    }

    fun shutdown() {
        <<< "Shutting Down" >>>;
        if (debug) {
            <<< "Stopping shreds" >>>;
        }
        for(0 => int i; i < shreds.cap(); i++) 
        {
            shreds[i].exit();
        }        
        true => shuttingDown;
    }

    fun void setBPM(float bpm)
    {
        bpm => BPM;
        60::second / bpm => beat;
    }


    fun void play()
    {
        if (parts != null) 
        {
            playParts();
        } else if (startFragment != null) {
            for( startFragment @=>  Fragment frag; 
                 frag != null; 
                 playFragment(frag) @=> frag) {
                    frag @=> currentFragment;
                 }
        }
    }

    fun Fragment playFragment(Fragment frag) 
    {
        frag.song @=> this.launchControl.song;
        <<< "On Song:", this, "Setting LC song: ", frag.song >>>;
        return frag.play();
    }

    // play the song
    fun void playParts()
    {
        // <<< "Starting song, num parts: ", parts.cap() >>>;
        0::second => dur total;
        Shred myShreds[parts.cap()];
        myShreds @=> shreds;
        for(0 => int i; i < parts.cap(); i++) 
        {
            parts[i] @=> Part part;

            if (part.totalDuration(this) > total) 
             {
                 part.totalDuration(this) => total;
             }

            spork ~ playPart(part) @=> shreds[i];
        }
        if (forever) {
            while(true) {
                5::second => now;
            }
        } else {
            if (debug) {
                <<< "Advancing time:", total >>>;
            }
            total => now;
            if (debug) {
                <<< "Stopping shreds" >>>;
            }
            if (shuttingDown) {
                <<< "Exiting" >>> ;
                me.exit();
            }
            for(0 => int i; i < parts.cap(); i++) 
            {
                shreds[i].exit();
            }
        }
    }

    fun void playPart(Part part)
    {
        while (true)
        {
            part.play(this);
        }
    }

    fun dur whole()
    {
        return beat * 4;
    }

    fun dur half()
    {
        return beat * 2;
    }

    fun dur quarter()
    {
        return beat;
    }

    fun dur eighth()
    {
        return beat/2;
    }

    fun dur sixteenth()
    {
        return beat/4;
    }

    fun dur dottedQuarter()
    {
        return quarter() + eighth();
    }

    fun dur dottedHalf()
    {
        return half() + quarter();
    }

    fun dur tripletEighth()
    {
        return quarter()/3;
    }
}

public class Part 
{
    string midiDevice;
    int midiChannel;

    int notesPerMeasure;
    int numberOfMeasures;

    float rhythmProbabilities[];
    int velocities[];
    int legato;

    Patch patch;

    fun Part(Patch initPatch)
    {
        initPatch @=> patch;
    }

   fun void play(Song song)
    {
        <<< "Part::play() Not Implemented!!" >>>;
    }

    fun dur totalDuration(Song song)
     {
         <<< "totalDuration not implemented!" >>>;
         return 1::second;
     }
 
    fun void playProbabilityRhythm(Song song)
    {
        // First generate notes for a single bar, so we know durations
        notesPerMeasure * numberOfMeasures => int numNotes;
        int notesToPlay[numNotes];
        int velocitiesToPlay[numNotes];

        for(0 => int i; i < numberOfMeasures; i++)
        {
            for(0 => int j; j < notesPerMeasure; j++)
            {
                false => int playNote;
                i * notesPerMeasure + j => int index;
                if (rhythmProbabilities.cap() > 0) 
                {
                    rhythmProbabilities[j % rhythmProbabilities.cap()] => float prob;
                    Math.random2f(0.0, 1.0) => float rand;
                    prob > rand => playNote;
                } else {
                    true => playNote;
                }
                if (playNote) {
                    velocities[index % velocities.cap()] => velocitiesToPlay[index];
                    generateNote(song, i, j) => int note;
                    note => notesToPlay[index];
                } else {
                    0 => velocitiesToPlay[index];
                    0 => notesToPlay[index];
                }
            }
        }
        // Now Play the notes, determining note length.
        for( 0 => int i; i < notesToPlay.cap(); i++) 
        {
            notesToPlay[i] => int note;
            if (note > 0) {
                getNextNotePosition(notesToPlay, i) => int pos;
                (pos - i) * (song.whole() / notesPerMeasure) => dur duration;
                if (legato) 
                {
                    0::ms => duration;
                }
                patch.noteOn(note, velocitiesToPlay[i], duration);
            }
            song.whole()/notesPerMeasure => now;
        }
    }

    fun int getNextNotePosition(int notes[], int noteIndex)
    {
        for(noteIndex + 1 => int i; i < notes.cap(); i++) 
        {
            if (notes[i] > 0) 
            {
                return i;
            }
        }

        return notes.cap();
    }

    fun int generateNote(Song song, int measure, int noteInMeasure)
    {
        <<< "Generate Note not implemented!" >>>;
        return song.rootNote;
    }

}

public class FragmentTransition
{
    Fragment nextFragment;
    float probability;

    fun FragmentTransition(Fragment frag, float p)
    {
        frag @=> nextFragment;
        p => probability;
    }
}

public class Fragment 
{
    int repeatCount;
    Song @ song;
    Song @ owningSong;
    FragmentTransition nextFragments[];
    Part @ parts[];

    fun Fragment(int r, Song s)
    {
        r => repeatCount;
        s @=> song;
    }

    fun Fragment(int r, Song os, Part p[])
    {
        r => repeatCount;
        os @=> owningSong;
        p @=> parts;
    }

    fun Fragment getNextSongFragment()
    {
        Math.random2f(0.0, 1.0) => float r;
        if (Song.golden) {
            0.0 => r;
        }
        0 => float prob;

        // <<< "Random: ", r >>>;
        // <<< "Num next fragments: ", nextFragments.cap() >>>;
        for(0 => int i; i < nextFragments.cap(); i++)
        {
            nextFragments[i] @=> FragmentTransition frag;
            frag.probability + prob => prob;
            // <<< "NF Prob: ", nextFragments[i].probability, "Prob: ", prob >>>;
            if (r <= prob)
            {
//                <<< "Picked number: ", i >>>;
                return frag.nextFragment;
            }
        }
        return nextFragments[0].nextFragment;
    }

    fun Fragment play()
    {
        for(0 => int i; i < repeatCount; i++) {
            // <<< "Play count: ", i >>>;
            song.play();
        }
        return getNextSongFragment();
    }
}

public class ControlChange
{
    string name;
    int minController;
    int maxController;
    int mapToController;
    static int ccMsg;

    fun ControlChange(string n, int min, int max, int outController) {
        min => minController;
        max => maxController;
        outController => mapToController;
        n => name;
        0xB0 => ccMsg;
    }
}



public class LaunchControl
{
    string inputDeviceName;
    string outputDeviceName;
    int outputChannel;

    MidiIn min;
    MidiMsg msg;
    Song @ song;
    
    [ 
      new ControlChange("Volume", 77, 84, 7),
      new ControlChange("Mod Wheel", 13, 20, 1),
      new ControlChange("Resonance", 29, 36, 71),
      new ControlChange("Pan", 49, 56, 10),
    ]  
    @=> static ControlChange ccHandlers[];

    fun LaunchControl(Song @ s)
    {
        "Launch Control XL" => inputDeviceName;
        s @=> song;
        <<< "Lc Constructor song: ", song, "Devices:", song.devices >>>;
        <<< "Creating Launch Control, num devices: ", song.devices.cap() >>>;
    }

    fun startEventLoop()
    {
        midi_events();
    }   

    fun midi_events() {
        // open midi receiver, exit on fail
        min.open(inputDeviceName) => int status;
        <<< "Midi controller open status:", status, "name:", min.name() >>>;
        if ( !status )
            me.exit(); 

        while( true )
        {
            // wait on midi event
            min => now;

            // receive midimsg(s)
            while( min.recv( msg ) )
            {
                <<< "In d1:", msg.data1, "d2:", msg.data2, "d3:", msg.data3 >>>;
                msg.data1 & 0x0F => int channel;
                msg.data1 & 0xFFF0 => int cc;
                // <<< "CC:", cc, "channel:", channel >>>;
                handControlChange(msg.data2, msg.data3);
            }
        }
    }

    fun handControlChange(int baseControlNumber, int value) 
    {
        for(0 => int i; i < ccHandlers.cap(); i++) {
            ccHandlers[i] @=> ControlChange cc;
            if (baseControlNumber >= cc.minController &&
                baseControlNumber <= cc.maxController) {
                    baseControlNumber - cc.minController => int channel;
                    song.devices[channel] @=> Patch patch;
                    if (patch != null) {
                        <<< "Handle control change:", cc.name >>>;
                        patch.sendControllerChange(cc.mapToController, value);
                    }
                    return;
                }
        }
    }
}
