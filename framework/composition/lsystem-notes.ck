// LSystemNotes
// Purpose: Expands YAML-defined L-system rewriting grammars into NoteCollection note sequences.
// Imports: framework/composition/note-collection.ck, framework/core/yaml.ck
// Imported by: framework/cadenza.ck

@import "note-collection.ck"
@import "../core/yaml.ck"

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
        if (currentDepth == maxDepth) {
            basisNotes.notes[currentOffset % basisNotes.notes.cap()] => expandedNotes[currentIndex++];
            return;
        }
        for (0 => int i; i < ruleArray.cap(); i++) {
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
        if (currentDepth == maxDepth - 1) {
            return ruleArray.cap();
        }
        0 => int size;
        for (0 => int i; i < ruleArray.cap(); i++) {
            ruleArray[i].GetString() => string nextSymbol;
            computeSize(nextSymbol, currentDepth + 1) => int nextSize;
            size + nextSize => size;
        }
        return size;
    }

    fun string arrayToString(int a[])
    {
        "[" => string s;
        for (0 => int i; i < a.cap(); i++) {
            s + Std.itoa(a[i]) => s;
            if (i < a.cap() - 1) {
                s + ", " => s;
            }
        }
        return s + "]";
    }
}
