@import "patch.ck"

// Overall structure of a song

public class Song 
{
    // Tempo in beats-per-minute
    float BPM;
    // Duration of a single beat. Set from BPM;
    dur beat;
    // How many beats per bar
    int beatsPerMeasure;

    // Root-note of chords, as a midi note number
    int rootNote;

    // All the parts playing in parallel
    Part @ parts[];

    int forever;

    // All the Fragments. A song can have Parts or Fragments, but not both
    Fragment @ startFragment;

    fun Song(float bpm, int root, int beatsInABar, Part allParts[])
    {
        setBPM(bpm);
        root => rootNote;
        allParts @=> parts;
        beatsInABar => beatsPerMeasure;
        false => forever;
    }

    fun Song(float bpm, int root, int beatsInABar, Fragment startFrag)
    {
        setBPM(bpm);
        root => rootNote;
        startFrag @=> startFragment;
        beatsInABar => beatsPerMeasure;
        .25::second => now;
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
                 frag.play() @=> frag) {
                 }
        }
    }

    // play the song
    fun void playParts()
    {
        <<< "Starting song, num parts: ", parts.cap() >>>;
        0::second => dur total;
        Shred shreds[parts.cap()];
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
            total => now;
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
    Song song;
    FragmentTransition nextFragments[];

    fun Fragment(int r, Song s)
    {
        r => repeatCount;
        s @=> song;
    }

    fun Fragment getNextSongFragment()
    {
        Math.random2f(0.0, 1.0) => float r;
        0 => float prob;

        <<< "Random: ", r >>>;
        <<< "Num next fragments: " + nextFragments.cap() >>>;
        for(0 => int i; i < nextFragments.cap(); i++)
        {
            nextFragments[i] @=> FragmentTransition frag;
            frag.probability + prob => prob;
            <<< "NF Prob: ", nextFragments[i].probability, "Prob: ", prob >>>;
            if (r <= prob)
            {
                <<< "Picked number: ", i >>>;
                return frag.nextFragment;
            }
        }
        return nextFragments[0].nextFragment;
    }

    fun Fragment play()
    {
        for(0 => int i; i < repeatCount; i++) {
            <<< "Play count: ", i >>>;
            song.play();
        }
        return getNextSongFragment();
    }
}