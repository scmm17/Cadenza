// Part
// Purpose: Abstract base class for modular musical parts with probability-driven rhythms.
// Imports: framework/composition/song-context.ck, framework/devices/patch.ck
// Imported by: framework/composition/fragment.ck, framework/composition/chord-progression.ck, framework/composition/melody.ck

@import "song-context.ck"
@import "../devices/patch.ck"

public class Part
{
    string midiDevice;

    int notesPerMeasure;
    int numberOfMeasures;

    float rhythmProbabilities[];
    string rhythmProbabilityStrings[];
    float rhythmProbabilityMins[];
    float rhythmProbabilityMaxs[];
    float rhythmProbabilityRanges[];
    int velocities[];
    float durations[0];
    int legato;
    float mutateProbabilityRange;

    Patch patch;

    fun void initPart(Patch initPatch)
    {
        initPatch @=> patch;
        0.0 => mutateProbabilityRange;

        string emptyStrings[0];
        float emptyFloats[0];
        emptyStrings @=> rhythmProbabilityStrings;
        emptyFloats @=> rhythmProbabilityMins;
        emptyFloats @=> rhythmProbabilityMaxs;
        emptyFloats @=> rhythmProbabilityRanges;
    }

    fun Part(Patch initPatch)
    {
        initPart(initPatch);
    }

    fun void play(SongContext song)
    {
        <<< "Part::play() Not Implemented!!" >>>;
    }

    fun dur totalDuration(SongContext song)
    {
        <<< "totalDuration not implemented!" >>>;
        return 1::second;
    }

    fun void playProbabilityRhythm(SongContext song)
    {
        notesPerMeasure * numberOfMeasures => int numNotes;
        int notesToPlay[numNotes];
        int velocitiesToPlay[numNotes];

        for (0 => int i; i < numberOfMeasures; i++) {
            for (0 => int j; j < notesPerMeasure; j++) {
                false => int playNote;
                i * notesPerMeasure + j => int index;
                if (rhythmProbabilities.cap() > 0) {
                    rhythmProbabilities[index % rhythmProbabilities.cap()] => float prob;
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
        mutateProbabilities();

        for (0 => int i; i < notesToPlay.cap(); i++) {
            notesToPlay[i] => int note;
            if (note > 0) {
                getNextNotePosition(notesToPlay, i) => int pos;
                (pos - i) * (song.whole() / notesPerMeasure) => dur duration;
                if (legato) {
                    0::ms => duration;
                } else if (durations.cap() > 0) {
                    durations[i % durations.cap()] => float durationFactor;
                    if (durationFactor > 0.0) {
                        durationFactor * song.whole() / notesPerMeasure => duration;
                    }
                }
                (notesToPlay.cap() - i) * (song.whole() / notesPerMeasure) => dur remainInPart;
                if (duration > remainInPart) {
                    remainInPart => duration;
                }
                patch.noteOn(note, velocitiesToPlay[i], duration);
            }
            song.advance(song.whole() / notesPerMeasure);
        }
    }

    fun mutateProbabilities()
    {
        if (mutateProbabilityRange == 0.0 && (rhythmProbabilityStrings == null || rhythmProbabilityStrings.cap() == 0)) {
            return;
        }
        <<< "probabilities: ", arrayToString(rhythmProbabilities) >>>;
        for (0 => int i; i < rhythmProbabilities.cap(); i++) {
            mutateProbabilityRange => float currentRange;
            if (rhythmProbabilityRanges.cap() > i && rhythmProbabilityRanges[i] >= 0.0) {
                rhythmProbabilityRanges[i] => currentRange;
            }

            if (currentRange == 0.0 ||
                (rhythmProbabilityMins.cap() > i && rhythmProbabilityMins[i] < 0.0)) {
                continue;
            }

            Math.random2f(-1.1, 1.1) => float r;
            (1.0 - Math.exp(-r * r)) * currentRange => float change;
            if (r < 0.0) {
                -change => change;
            }
            rhythmProbabilities[i] + change => change;

            if (rhythmProbabilityMins.cap() > i && rhythmProbabilityMins[i] >= 0.0) {
                if (change < rhythmProbabilityMins[i]) {
                    rhythmProbabilityMins[i] => change;
                }
            } else {
                if (change < 0.0) {
                    0.0 => change;
                }
            }

            if (rhythmProbabilityMaxs.cap() > i && rhythmProbabilityMaxs[i] >= 0.0) {
                if (change > rhythmProbabilityMaxs[i]) {
                    rhythmProbabilityMaxs[i] => change;
                }
            } else {
                if (change > 1.0) {
                    1.0 => change;
                }
            }

            change => rhythmProbabilities[i];
        }
    }

    fun string arrayToString(float a[])
    {
        "[" => string s;
        for (0 => int i; i < a.cap(); i++) {
            s + Std.ftoa(a[i], 2) => s;
            if (i < a.cap() - 1) {
                s + ", " => s;
            }
        }
        return s + "]";
    }

    // Parse a probability string in format: "prob", "prob:min:max", or "prob:min:max:range"
    fun void parseProbabilityString(string probStr, int index)
    {
        string parts[0];
        0 => int start;
        for (0 => int i; i <= probStr.length(); i++) {
            if (i == probStr.length() || probStr.charAt(i) == ':') {
                if (i > start) {
                    probStr.substring(start, i - start) => string part;
                    parts << part;
                }
                i + 1 => start;
            }
        }

        if (parts.cap() == 1) {
            Std.atof(parts[0]) => rhythmProbabilities[index];
            -1.0 => rhythmProbabilityMins[index];
            -1.0 => rhythmProbabilityMaxs[index];
            -1.0 => rhythmProbabilityRanges[index];
        } else if (parts.cap() == 3) {
            Std.atof(parts[0]) => rhythmProbabilities[index];
            Std.atof(parts[1]) => rhythmProbabilityMins[index];
            Std.atof(parts[2]) => rhythmProbabilityMaxs[index];
            -1.0 => rhythmProbabilityRanges[index];
        } else if (parts.cap() == 4) {
            Std.atof(parts[0]) => rhythmProbabilities[index];
            Std.atof(parts[1]) => rhythmProbabilityMins[index];
            Std.atof(parts[2]) => rhythmProbabilityMaxs[index];
            Std.atof(parts[3]) => rhythmProbabilityRanges[index];
        } else {
            <<< "Invalid probability string format:", probStr >>>;
            1.0 => rhythmProbabilities[index];
            -1.0 => rhythmProbabilityMins[index];
            -1.0 => rhythmProbabilityMaxs[index];
            -1.0 => rhythmProbabilityRanges[index];
        }
    }

    fun void setProbabilitiesFromStrings(string probStrings[])
    {
        probStrings @=> rhythmProbabilityStrings;

        float newProbs[probStrings.cap()];
        float newMins[probStrings.cap()];
        float newMaxs[probStrings.cap()];
        float newRanges[probStrings.cap()];

        newProbs @=> rhythmProbabilities;
        newMins @=> rhythmProbabilityMins;
        newMaxs @=> rhythmProbabilityMaxs;
        newRanges @=> rhythmProbabilityRanges;

        for (0 => int i; i < probStrings.cap(); i++) {
            parseProbabilityString(probStrings[i], i);
        }
    }

    fun int getNextNotePosition(int notes[], int noteIndex)
    {
        for (noteIndex + 1 => int i; i < notes.cap(); i++) {
            if (notes[i] > 0) {
                return i;
            }
        }
        return notes.cap();
    }

    fun int generateNote(SongContext song, int measure, int noteInMeasure)
    {
        <<< "Generate Note not implemented!" >>>;
        return song.rootNote;
    }
}
