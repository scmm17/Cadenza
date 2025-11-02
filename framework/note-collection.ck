@import "song.ck"
@import "yaml.ck"

// NoteCollection is a fundamental class for managing collections of musical notes in the framework.
// It provides static factory methods for creating common musical scales, chords, and note patterns,
// as well as methods for converting note indices to MIDI note numbers.
//
// The class stores notes as integer arrays representing semitone offsets from a root note.
// These offsets can be positive or negative, allowing for notes above and below the root.
//
// Static factory methods include:
// - majorScale(), minorScale(): Standard 8-note scales
// - majorChordNotes(), minorChordNotes(): Basic triads with octave
// - I_notes(), IV_notes(), V_notes(), etc.: Common chord progressions
// - mixolydian_notes(), mixolydian_octave_notes(): Modal scales
// - Various circle of fifths chord progressions (circle_vi_notes, etc.)
//
// The getMidiNote() method converts a note index to an actual MIDI note number
// by adding the song's root note and any octave offset to the stored semitone offset.
//
// This class serves as the foundation for more complex note generation systems
// like LSystemNotes, which extends it to create algorithmic note sequences.

public class NoteCollection
{
    int notes[];

    fun static NoteCollection majorScale()
    {
        [0, 2, 4, 5, 7, 9, 11, 12] @=> int majorScaleNotes[];
        NoteCollection major(majorScaleNotes);
        return major;
    }

    fun static NoteCollection minorScale()
    {
        [0, 2, 3, 5, 7, 9, 11, 12] @=> int minorScaleNotes[];
        NoteCollection minor(minorScaleNotes);
        return minor;
    }

    fun static NoteCollection majorChordNotes()
    {
        [0,4,7,12] @=> int major[];
        NoteCollection majorChordNotes(major);
        return majorChordNotes;
    }

    fun static NoteCollection minorChordNotes()
    {
        [0,3,7,12] @=> int minor[];
        NoteCollection minorChordNotes(minor);
        return minorChordNotes;
    }

    fun static NoteCollection I_notes()
    {
        [0,7,12,16,19,24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection IV_notes()
    {
        [0,5,12,17,21,24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection V_notes()
    {
        [-5, 2, 7, 11, 14, 19] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection bVII_notes()
    {
        [-2,5,10,14,17,22] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection I7_notes()
    {
        [0, 4, 7, 10] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection IV7_notes()
    {
        [-7, -3, 0, 3] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection V7_notes()
    {
        [-5, -1, 2, 5] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }
    
    fun static NoteCollection I7_bass_notes()
    {
        [0, 4, 7, 9, 10, 9, 7, 4] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection IV7_bass_notes()
    {
        [5, 9, 12, 14, 15, 14, 12, 9, 5] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection V7_bass_notes()
    {
        [7, 11, 14, 16, 17, 16, 14, 11, 7] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }
    fun static NoteCollection coltrane1_notes()
    {
        [0, 4, 7, 10] @=> int notes[]; // Major 7th (Cmaj7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane2_notes() 
    {
        [-3, 0, 3, 7] @=> int notes[]; // Minor 7th (Dm7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane3_notes()
    {
        [-5, -2, 2, 5] @=> int notes[]; // Minor 7th (Em7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane4_notes()
    {
        [-7, -3, 0, 3] @=> int notes[]; // Major 7th (Fmaj7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane5_notes()
    {
        [-5, -1, 2, 5] @=> int notes[]; // Dominant 7th (G7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane6_notes()
    {
        [-3, 0, 3, 7] @=> int notes[]; // Minor 7th (Am7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection coltrane7_notes()
    {
        [-2, 2, 5, 8] @=> int notes[]; // Half Diminished (Bm7b5)
        NoteCollection chord(notes);
        return chord;
    }
    fun static NoteCollection trane1_notes()
    {
        [0, 4,7, 12] @=> int notes[]; // Major 7th (Cmaj7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection trane2_notes() 
    {
        [3,10,13,19] @=> int notes[]; // Minor 7th (Dm7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection trane3_notes()
    {
        [8,12,15,20] @=> int notes[]; // Minor 7th (Em7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection trane4_notes()
    {
        [-1,6,12,15] @=> int notes[]; // Major 7th (Fmaj7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection trane5_notes()
    {
        [4,8,11,16] @=> int notes[]; // Dominant 7th (G7)
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_I_notes()
    {
        [-12, -5, 0, 4] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_IV_notes()
    {
        [-18, -3, 0, 5] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_viio_notes()
    {
        [-13, -7, -1, 2] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_iii_notes()
    {
        [-19, -5, -1, 4] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_vi_notes()
    {
        [-15, -8, -3, 0] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_ii_notes()
    {
        [-21, -7, -3, 2] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_V_notes()
    {
        [-17, -10, -5, -1] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection circle_I2_notes()
    {
        [-22, -8, -5, 0] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection mixolydian_notes()
    {
        [-12, -10, -8, -7, -5, -3, -2, 0, 2, 4, 5, 7, 9, 10, 12] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection mixolydian_octave_notes()
    {
        [0, 2, 4, 5, 7, 9, 10, 12] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_I_chord_Low()
    {
        [-12, -8, -5, 0, 4, 7, 12] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_I_chord_High()
    {
        [0, 4, 7, 12, 16, 19, 24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_IV_chord_Low()
    {
        [-7, -3, 0, 5, 9, 12, 17] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_IV_chord_High()
    {
        [5, 9, 12, 17, 21, 24] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_V_chord_Low()
    {
        [-5, -1, 2, 7, 11, 14, 19] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun static NoteCollection F_V_chord_High()
    {
        [7, 11, 14, 19, 23, 26] @=> int notes[];
        NoteCollection chord(notes);
        return chord;
    }

    fun NoteCollection(int theNotes[])
    {
        theNotes @=> notes;
    }

    fun int numNotes()
    {
        return notes.cap();
    }

    fun int getMidiNote(Song song, int noteIndex, int offset)
    {
        // get the note, adding or subtracting octaves, as needed
        return song.rootNote + offset + notes[noteIndex % numNotes()] /* + 12 * (noteIndex / numNotes()) */;
    }
}

// LSystemNotes extends NoteCollection to generate note sequences using L-systems (Lindenmayer systems).
// L-systems are a type of formal grammar that can generate complex patterns through recursive rewriting rules.
// This class reads L-system definitions from YAML files and expands them into sequences of musical notes.
//
// The L-system is defined by:
// - A start symbol (initial state)
// - A set of rewriting rules that replace symbols with sequences of other symbols
// - Offset values that modify the pitch when expanding symbols
// - A maximum depth to control the recursion level
//
// Example YAML structure:
// startSymbol: "A"
// maxDepth: 3
// rules:
//   A: ["A", "B"]
//   B: ["A"]
// offsets:
//   A: [0, 2]
//   B: [1]
//
// The expansion process recursively applies the rules until maxDepth is reached,
// then maps the final positions to actual MIDI notes from the basis note collection.

public class LSystemNotes extends NoteCollection
{
    NoteCollection @ basisNotes;
   
    YamlNode @ lSystem;
    int maxDepth;
    string startSymbol;
    YamlNode @ rules;
    YamlNode @ offsets;
    int currentIndex;

    int expandedNotes[];

    fun LSystemNotes(NoteCollection theNotes, string lSystemFilename)
    {
        theNotes @=> basisNotes;
        YamlNode.ParseFile(lSystemFilename) @=> lSystem;
        lSystem.GetString("startSymbol") => startSymbol;
        lSystem.GetInt("maxDepth") => maxDepth;
        lSystem.GetMap("rules") @=> rules;
        lSystem.GetMap("offsets") @=> offsets;
        computeSize(startSymbol, 0) => int size;
        <<< "l-system size: ", size, " maxDepth: ", maxDepth >>>;
        int eNotes[size];
        eNotes @=> expandedNotes;
        expandedNotes[size-1] => int lastNote;
        0 => currentIndex;
        expand(startSymbol, 0, 0);
        expandedNotes @=> notes;
    }

    fun void expand(string currentSymbol, int currentOffset, int currentDepth)
    {
        rules.GetValue(currentSymbol) @=> YamlNode@ ruleNode;
        ruleNode.GetArray() @=> YamlNode@ ruleArray[];
        offsets.GetValue(currentSymbol) @=> YamlNode@ offsetNode;
        offsetNode.GetArray() @=> YamlNode@ offsetArray[];
        if (currentDepth == maxDepth)
        {
            // currentOffset % basisNotes.numNotes() => octave;
            basisNotes.notes[currentOffset % basisNotes.notes.cap()] => expandedNotes[currentIndex++];
            return;
        }
        for (0 => int i; i < ruleArray.cap(); i++)
        {
            ruleArray[i].GetString() => string nextSymbol;
            offsetArray[i].GetInt() => int nextOffset;
            expand(nextSymbol, currentOffset + nextOffset, currentDepth + 1);
        }
        return;
    }

    fun int computeSize(string currentSymbol, int currentDepth)
    {
        rules.GetValue(currentSymbol) @=> YamlNode@ ruleNode;
        ruleNode.GetArray() @=> YamlNode@ ruleArray[];
        if (currentDepth == maxDepth-1)
        {
            return ruleArray.cap();
        }
        0 => int size;
        for (0 => int i; i < ruleArray.cap(); i++)
        {
            ruleArray[i].GetString() => string nextSymbol;
            computeSize(nextSymbol, currentDepth + 1) => int nextSize;
            size + nextSize => size;
        }
        return size;
    }

    fun int getMidiNote(Song song, int noteIndex, int offset)
    {
        // get the note, adding or subtracting octaves, as needed
        return song.rootNote + offset + expandedNotes[noteIndex % numNotes()] /* + 12 * (noteIndex / numNotes()) */;
    }

    fun string arrayToString(int a[])
    {
        "[" => string s;
        for(0 => int i; i < a.cap(); i++) {
            s + Std.itoa(a[i]) => s;
            if (i < a.cap() - 1) {
                s + ", " => s;
            }
        }
        return s + "]";
    }
}