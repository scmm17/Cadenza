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

    // All the parts in the song
    Part @ parts[];
    // The currently playing parts
    Part @ currentParts[];
    // The single solo part
    Patch @ soloPatch;
    // The muted parts
    Patch @ mutedPatches[];
    int muteMode;
    int soloMode;

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
        true => muteMode;
        false => soloMode;
        Patch empty[0];
        empty @=> mutedPatches;
        initDevicesFromParts();
        for(Patch device : devices) {
            if (device == null) {
                break;
            }
            device @=> Patch device;
        }
    }

    fun Song(float bpm, int root, Fragment startFrag, Part allParts[])
    {
        setBPM(bpm);
        root => rootNote;
        allParts @=> parts;
        startFrag @=> startFragment;
        false => pause;
        false => debug;
        false => shuttingDown;
        false => golden;
        true => muteMode;
        false => soloMode;
        Patch empty[0];
        empty @=> mutedPatches;
        initDevicesFromParts();
        startFrag.parts @=> currentParts;
        new MidiMapper("HYDRASYNTH EXPLORER", "U2MIDI Pro", 1) @=> hydraEvents;
        new LaunchControl(this) @=> launchControl;

        .25 ::second => now;

        spork ~ hydraEvents.startEventLoop();       
        spork ~ launchControl.startEventLoop();
        spork ~ keyboardLoop(); 
    }

    fun initDevicesFromParts()
    {
        parts[0].patch @=> currentDevice;
        0 => int deviceIndex;
        for(Part part : parts) 
        {
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
        preset.name => currentDevice.patchName;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setNextPresetCategory() 
    {
        presets.getNextCategory() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        preset.name => currentDevice.patchName;
        <<< "Category:", preset.category >>>;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setPreviousPreset() 
    {
        presets.getPreviousPreset() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        preset.name => currentDevice.patchName;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    fun setPreviousPresetCategory() 
    {
        presets.getPreviousCategory() @=> V3Preset preset;
        V3GrandPiano v3(hydraEvents.outputChannel+1);
        v3.programChangeV3GrandPiano(preset.program, preset.bank);
        preset.name => currentDevice.patchName;
        <<< "Category:", preset.category >>>;
        <<< getPresetDeclaration(preset), "" >>>;
    }

    Patch @ currentDevice;

    fun keyboardLoop()
    {
        KBHit kb;

        devices[0] @=> currentDevice;
        devices[0].midiChannel => hydraEvents.outputChannel;
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
                    key - "1".charAt(0) => int i;
                    if (i >= 0 && i < devices.cap() && devices[i] != null) {
                        devices[i] @=> currentDevice;
                        devices[i].midiChannel => hydraEvents.outputChannel;
                        launchControl.printDevices();
                    }
                }
                if ("q".charAt(0) == key) {
                    shutdown();
                }
                if ("n".charAt(0) == key) {
                    setNextPreset();
                    launchControl.printDevices();
                }
                if ("m".charAt(0) == key) {
                    setPreviousPreset();
                    launchControl.printDevices();
                }
                if ("N".charAt(0) == key) {
                    setNextPresetCategory();
                    launchControl.printDevices();
                }
                if ("M".charAt(0) == key) {
                    setPreviousPresetCategory();
                    launchControl.printDevices();
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
        // Turn off the active selection LED
        launchControl.setActiveSelectionLED(0, 41, 0, 0x3c);
        if (soloMode) {
            toggleSoloMode(110);
        }
        if (muteMode) {
            toggleMuteMode(109);
        }
        launchControl.setActiveMutedLED(0, 73, 0, 0x0F);
        // Turn off the mute LED
        launchControl.setLED(0, 109, 0x3c, false);
        // Turn off the solo LED
        launchControl.setLED(0, 110, 0x3c, false);
        // Shut off all current notes.
        for(Patch device : devices) {
            if (device != null) {
                device.sendAllNotesOff();
            }
        }

        if (debug) {
            <<< "Stopping shreds" >>>;
        }
        for(Shred shred : shreds) 
        {
            shred.exit();
        }        
        true => shuttingDown;
        me.exit();
    }

    fun void setBPM(float bpm)
    {
        bpm => BPM;
        60::second / bpm => beat;
    }

    fun void startMuteMode()
    {
        true => muteMode;
    }

    fun void endMuteMode()
    {
        false => muteMode;
        for(Patch p : mutedPatches) {
            false => p.muted;
        }
        mutedPatches.clear();
    }

    fun void mutePatch(Patch patch)
    {
        true => patch.muted;
        mutedPatches << patch;
    }

    fun void unMutePatch(Patch patch)
    {
        false => patch.muted;
        for(0 => int i; i < mutedPatches.cap(); i++) {
            if (mutedPatches[i] != patch) {
                mutedPatches.erase(i);
                break;
            }
        }
    }

    fun void startSoloMode()
    {
        true => soloMode;
    }

    fun void endSoloMode()
    {
        false => soloMode;
        null @=> soloPatch;
        for(Patch p : devices) {
            if (p != null) {
                false => p.muted;
            }
        }
    }

    fun void setSoloPatch(Patch patch)
    {
        <<< "Setting solo patch:", patch.deviceName >>>;
        patch @=> soloPatch;
        for(Patch p : devices) {
            if (p == patch) {
                false => p.muted;
            } else if (p != null)   {
                true => p.muted;
            }
        }
    }

    fun void unsetSoloPatch()
    {
        <<< "Unsetting solo patch:", soloPatch.deviceName >>>;
        for(Patch p : devices) {
            if (p != null) {
                false => p.muted;
            }
        }
        null @=> soloPatch;
    }

    fun void toggleMute(Patch patch)
    {
        if (patch.muted) {
            unMutePatch(patch);
        } else {
            mutePatch(patch);
        }
    }

    fun void toggleSoloPatch(Patch patch)
    {
        <<< "Toggling solo patch:", patch.deviceName >>>;
        soloPatch @=> Patch originalSoloPatch;
        if (soloPatch != null) {
            unsetSoloPatch();
        }
        if (originalSoloPatch != patch) {
            setSoloPatch(patch);
        } else {
            null @=> soloPatch;
        }
    }

    fun void toggleMuteMode(int note)
    {
        if (soloMode) {
            endSoloMode();
        }

        if (muteMode) {
            endMuteMode();
        } else {
            startMuteMode();
        }
    }

    fun void toggleSoloMode(int note) 
    {
        if (muteMode) {
            endMuteMode();
        }

        if (soloMode) {
            endSoloMode();
        } else {
            startSoloMode();
        }
    }

    fun void play()
    {
        if (startFragment != null) {
            for( startFragment @=>  Fragment frag; 
                 frag != null; 
                 playFragment(frag) @=> frag) {
                    frag @=> currentFragment;
                 }
        }
        if (parts != null) 
        {
            playParts();
        }
    }

    fun void playPartOnce() 
    {
        if (currentParts != null) {
            playParts();
        }
    }

    fun Fragment playFragment(Fragment frag) 
    {
        return frag.play();
    }

    fun int containsPart(Part part) 
    {
        if (currentParts == null) {
            return true;
        }
        for(Part currentPart : currentParts) {
            if (currentPart == part) {
                return true;
            }
        }
        return false;
    }

    // play the song
    fun void playParts()
    {
        // <<< "Starting song, num parts: ", parts.cap() >>>;
        0::second => dur total;
        Shred myShreds[parts.cap()];
        myShreds @=> shreds;
        0 => int partIndex;
        for(Part part : parts) 
        {
            if (!containsPart(part)) {
                partIndex++;
                continue;
            }
            if (part.totalDuration(this) > total) 
            {
                part.totalDuration(this) => total;
            }
            spork ~ playPart(part) @=> shreds[partIndex];
            partIndex++;
        }
        if (forever) {
            while(true) {
                5::second => now;
            }
        } else {
            total => now;
            if (shuttingDown) {
                <<< "Exiting" >>> ;
                me.exit();
            }
            // Shut off all current notes.
            for(Patch device : devices) {
                if (device != null) {
                    device.sendAllNotesOff();
                }
            }
            for(Shred shred : shreds) 
            {
                if (shred != null) {
                    shred.exit();
                }
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
    Song @ owningSong;
    FragmentTransition nextFragments[];
    Part @ parts[];
    string name;

    fun Fragment(string n, int r, Part p[])
    {
        n => name;
        r => repeatCount;
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
        for(FragmentTransition frag : nextFragments)
        {
            frag.probability + prob => prob;
            if (r <= prob)
            {
                // <<< "Picked number: ", i >>>;
                return frag.nextFragment;
            }
        }
        return nextFragments[0].nextFragment;
    }

    fun Fragment play()
    {
        for(0 => int i; i < repeatCount; i++) {
            // <<< "Play count: ", i >>>;
            if (owningSong != null) {
                parts @=> owningSong.currentParts;
                owningSong.launchControl.printDevices();
                <<< "\n    Fragment:", name >>>;
                owningSong.playPartOnce();
            }
        }
        getNextSongFragment() @=> Fragment next;
        <<< "Next Fragment:", next.name >>>;
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
    MidiOut mout;
    MidiMsg msg;
    Song @ song;
    
    [ 
      new ControlChange("Volume", 77, 84, 7),
      new ControlChange("Mod Wheel", 13, 20, 74),
      new ControlChange("Resonance", 29, 36, 71),
      new ControlChange("Pan", 49, 56, 10),
    ]  
    @=> static ControlChange ccHandlers[];

    fun LaunchControl(Song @ s)
    {
        "Launch Control XL" => inputDeviceName;
        s @=> song;

        printDevices();
    }

    fun string padString(int len) 
    {
        "" => string s;
        for(0 => int i; i < len; i++) {
            s + " " => s;
        }
        return s;
    }

    fun int isActiveDevice(Patch p) 
    {
        return p == song.currentDevice;
    }

    fun int isPlaying(Patch p) 
    {
        for (Part currentPart : song.currentParts) {
            if (currentPart.patch == p) {
                return true;
            }
        }
        return false;
    }

    fun void printDevices()
    {
        <<< "\033c", "" >>>;
        0 => int maxLength;
        for(Patch patch : song.devices) {
            if (patch != null) {
                if (patch.patchName.length() + patch.uiName.length() > maxLength) {
                    patch.patchName.length() + patch.uiName.length() => maxLength;
                }
            }
        }
        0 => int deviceNum;
        for(Patch patch : song.devices) {
            if (patch != null) {
                " " => string pad;
                " " => string prefix;
                if (isActiveDevice(patch)) {
                    "*" => prefix;
                } 
                if (isPlaying(patch)) {
                    "X" => pad;
                }
                patch.patchName => string name;
                "| " + patch.uiName + ":" => string n;
                <<< prefix, pad, "Device:", deviceNum + 1, n, name, padString(maxLength-(name.length()+patch.uiName.length())), "| Volume:", patch.volume >>>;
            }
            deviceNum++;
        }

        <<< "Mute Mode:", song.muteMode, "Solo Mode:", song.soloMode, "Muted Patches:", song.mutedPatches.cap() >>>;

        write_markdown_panel();
    }

    fun write_markdown_panel()
    {
        // filename
        "dashboard.md" => string filename;
        // instantiate a file IO object
        FileIO fout;
        // open for write (default mode: ASCII)
        fout.open( filename, FileIO.WRITE );
        fout.write("| Status | Device | Patch | Volume |\n");
        fout.write("| :---: | :---: | --- | :---: |\n");

        0 => int deviceNum;
        for(Patch patch : song.devices) {
            if (patch != null) {
                " " => string pad;
                " " => string prefix;
                " " => string muteString;
                if (isActiveDevice(patch)) {
                    " 👁️" => prefix;
                } 
                if (isPlaying(patch)) {
                    " ☑️" => pad;
                }
                if (patch.muted) {
                    " ❌" => muteString;
                }
                "_" + patch.patchName + "_" => string name;
                patch.uiName + ": " => string n;
                "| " + prefix + pad + muteString + " | " + Std.itoa(deviceNum + 1) + " | " + n + name +  " | " + patch.volume + " |\n" => string line;
                fout.write(line);
            }
            deviceNum++;
        }
        fout.close();
    }

    fun startEventLoop()
    {
        midi_events();
    }   

    fun midi_events() {
        // open midi receiver, exit on fail
        min.open(inputDeviceName) => int status;
        if ( !status ) {
            <<< "Filed to open Launch Control input", inputDeviceName >>>;
            me.exit(); 
        }
        mout.open(inputDeviceName) => status;
        if ( !status ) {
            <<< "Filed to open Launch Control output", inputDeviceName >>>;
            me.exit(); 
        }

        setActiveSelectionLED(0, 41, 41, 0x3c);
        setActiveMutedLED(0, 73, 0, 0x3c);
        setLED(0, 109, 0x3c, song.muteMode);
        setLED(0, 110, 0x3c, song.soloMode);

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
                <<< "CC:", cc, "channel:", channel >>>;
                false => int handled;
                if (cc == 0xB0) {
                    handControlChange(msg.data2, msg.data3) => handled;
                }
                if (handled) {
                    continue;
                }
                if (cc == 0x90) {
                    handleButtonDown(channel, msg.data2, msg.data3) => handled;
                } else if (cc == 0x80) {
                    handleButtonUp(channel, msg.data2, msg.data3) => handled;
                }
                if (handled) {
                    continue;
                }
            }
        }
    }

    fun int handControlChange(int baseControlNumber, int value) 
    {
        for(ControlChange cc : ccHandlers) {
            if (baseControlNumber >= cc.minController &&
                baseControlNumber <= cc.maxController) {
                    baseControlNumber - cc.minController => int channel;
                    song.devices[channel] @=> Patch patch;
                    if (patch != null) {
                        // <<< "Handle control change:", cc.name >>>;
                        patch.sendControllerChange(cc.mapToController, value);
                        if (cc.mapToController == 7) {
                            value => patch.volume;
                            spork ~ printDevices();
                        }
                        return true;
                    }
                    return false;
                }
        }
        return false;
    }

    fun void setLED(int channel, int note, int color, int on)
    {
        if (on) {
            0x90 => msg.data1;
        } else {
            0x80 => msg.data1;
        }
        note => msg.data2;
        color => msg.data3;
        mout.send(msg);        
    }

    fun void setActiveSelectionLED(int channel, int baseNote, int note, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            setLED(channel, i, color, i == note);
        }
    }

    fun void setActiveMutedLED(int channel, int baseNote, int note, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            i - baseNote => int j;
            if (song.muteMode && j >= 0 && j < song.devices.cap() && song.devices[j] != null) {
                setLED(channel, i, color, song.devices[j].muted);
            } else {
                setLED(channel, i, color, false);
            }
        }
    }

    fun void setActiveSoloLED(int channel, int baseNote, int note, int color)
    {
        for (baseNote => int i; i < baseNote + 8; i++) {
            i - baseNote => int j;
            if (song.soloMode && j >= 0 && j < song.devices.cap() && song.devices[j] != null) {
                setLED(channel, i, color, !song.devices[j].muted);
            } else {
                setLED(channel, i, color, false);
            }
        }            
    }

    fun int handleButtonDown(int channel, int note, int velocity)
    {
        if (note >= 41 && note <= 48) {
            // Select device
            note - 41 => int i;
            if (i >= 0 && i < song.devices.cap() && song.devices[i] != null) {
                song.devices[i] @=> song.currentDevice;
                song.devices[i].midiChannel => song.hydraEvents.outputChannel;
                setActiveSelectionLED(channel, 41, note, 0x3c);
                song.launchControl.printDevices();
                return true;
            }
        }
        if (song.muteMode && note >= 73 && note <= 80) {
            // Select patch
            note - 73 => int i;
            if (i >= 0 && i < song.devices.cap() && song.devices[i] != null) {
                song.toggleMute(song.devices[i]);
                setActiveMutedLED(channel, 73, note, 0x0F);
                song.launchControl.printDevices();
                return true;
            }
        }
        if (song.soloMode && note >= 73 && note <= 80) {
            // Select patch
            note - 73 => int i;
            if (i >= 0 && i < song.devices.cap() && song.devices[i] != null) {
                song.toggleSoloPatch(song.devices[i]);
                setActiveSoloLED(channel, 73, note, 0x3C);
                song.launchControl.printDevices();
                return true;
            }
        }
        if (note == 104) {
            song.setPreviousPresetCategory();
            song.launchControl.printDevices();
            return true;
        }
        if (note == 105) {
            song.setNextPresetCategory();
            song.launchControl.printDevices();
            return true;
        }
        if (note == 106) {
            song.setPreviousPreset();
            song.launchControl.printDevices();
            return true;
        }
        if (note == 107) {
            song.setNextPreset();
            song.launchControl.printDevices();
            return true;
        }
        if (note == 109) {
            song.toggleMuteMode(note);
            setLED(channel, 109, 0x3c, song.muteMode);
            setLED(channel, 110, 0x3c, song.soloMode);
            setActiveMutedLED(channel, 73, 0, 0x0F);
            song.launchControl.printDevices();
            return true;
        }
        if (note == 110) {
            song.toggleSoloMode(note);
            setLED(channel, 110, 0x3c, song.soloMode);
            setLED(channel, 109, 0x3c, song.muteMode);
            setActiveSoloLED(channel, 73, 0, 0x3C);
            song.launchControl.printDevices();
            return true;
        }
        return false;
    }

    fun int handleButtonUp(int channel, int note, int velocity)
    {
        // <<< "Button Up, note:", note, "Velocity:", velocity >>>;
        return true;
    }
}
