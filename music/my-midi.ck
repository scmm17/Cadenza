63 => float bpm;
60::second / bpm => dur beat;
// 0.95::second => dur beat;

MidiOut gma;
gma.open(0);
MidiMsg msg;

// Drum Machine part

SndBuf kick => dac;
SndBuf snare => dac;
SndBuf cHat => dac;
SndBuf oHat => dac;

me.dir() + "kick.wav" => string kickFilename;
me.dir() + "clap.wav" => string snareFilename;
me.dir() + "c-hat.wav" => string cHatFilename;
me.dir() + "o-hat.wav" => string oHatFilename;

kickFilename => kick.read;
0.3 => kick.gain;
snareFilename => snare.read;
.25 => snare.gain;
cHatFilename => cHat.read;
.15 => cHat.gain;
oHatFilename => oHat.read;
.25 => oHat.gain;

fun void SilenceAllBuffers() 
{
    kick.samples() => kick.pos;
    snare.samples() => snare.pos;
    cHat.samples() => cHat.pos;
    oHat.samples() => oHat.pos;

}

SilenceAllBuffers();

fun void Drum(int select, dur duration)
{

    if (select == 0) 
    {
        0 => kick.pos;
        0 => cHat.pos;
    }
    if (select == 1) 
    {
        0 => oHat.pos;
    }    
    if (select == 2) 
    {
        0 => kick.pos;
        0 => cHat.pos;
        0 => snare.pos;
    }

    duration => now;
    SilenceAllBuffers();
}

fun void DrumMachine() {
    while (true) 
    {
        4 => int poly;
        for(0 => int i; i < poly; i++ )
        {
            Drum(0, beat/poly);
        }
        Math.random2f(0, 1) => float r;
        if (r > .25)
        {
            Drum(2, beat/4);
            Drum(2, beat/4);
        } else {
            Drum(2, beat/2);
        }
        Drum(0, beat/4);
        Drum(1, beat/4);
        for( 0 => int i; i < 4; i++)
        {
            Drum(0, beat/4);
        }
        Drum(2, beat);
    }
}

// Chord progressions

// Set up voices
PulseOsc osc1 => ADSR env1 => NRev rev1 => Pan2 pan1 => dac;
SawOsc osc2 => ADSR env2 => NRev rev2 => Pan2 pan2 => dac;
env2 => Delay delay1 => dac;
delay1 => delay1;
-0.75 => pan1.pan;
 0.25  => pan2.pan;
SndBuf guitar => dac;

me.dir() + "sounds_guitar.wav" => string filename;
filename => guitar.read;
.0 => guitar.gain;

// 0.2 => osc1.gain;
// 0.4 => osc2.gain;
0.0 => osc1.gain;
0.0 => osc2.gain;
0.2 => rev1.mix;
0.2 => rev2.mix;

// Chords
[0,4,7,12] @=> int major[];
[0,3,7,12] @=> int minor[];

// Chords
[0, -3, 5, 7] @=> int progression[];
[1, 0, 1, 1] @=> int majorMinor[];

60 => int offset;
int position;

// Duration of one beat
// 1.5::second => dur beat;

// Set up envenlopes for the voices
(beat*0.5, beat*.25, .2, 1::ms) => env1.set;
(1::ms, beat/32, 0, 1::ms) => env2.set;

// Set the delay params
beat => delay1.max;
beat/16 => delay1.delay;
0.0 => delay1.gain;

fun Chords()
{
    while (true) 
    {
        playProgession(progression, majorMinor);
    }
}

fun noteOffFun(int note, dur duration)
{
    duration => now;
    noteOff(note);
    duration => now;
}

fun void noteOn(int note, int velocity, dur duration)
{
    144 => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    gma.send(msg);
    if (duration  > 0::ms) {
        spork ~ noteOffFun(note, duration);
    }
}
    
fun void noteOff(int note)
{
    128 => msg.data1;
    note => msg.data2;
    gma.send(msg);
}

fun void playProgession(int progression[], int majorMinor[])
{
    for(0 => int k; k < progression.cap(); k++) 
    {
        progression[k] => position;
        if (k % 2 == 0) {
           0 => guitar.pos;
        }

        for(0 => int i; i < 4; i++)
        {
            if (i%2 == 0) {
                setFreq(0, k, osc1);
                1 => env1.keyOn;
                noteOn(getNote(i/2, k)-12, 24, beat*4);
            }
            for( 0 => int j; j < 4; j++)
            {
                if (j == 0 || Math.random2f(0,1) > .25) 
                {
                    if (j == 0) {
                        // .4 => osc2.gain;
                        .0 => osc2.gain;
                    }
                    else {
                        // .35 => osc2.gain;
                        .0 => osc2.gain;
                    }
                    Math.random2(0,3) => int note;
                    setFreq(note, k, osc2);
                    1 => env2.keyOn;
                    // noteOn(getNote(note, k), 64, beat/4);
                    noteOn(getNote(note, k), 64, 0::ms);
                    beat/4 => now;
                } else {
                    0 => env2.keyOn;
                    // noteOff()
                    beat/4 => now;
                }
            }
        }
    }    
}

fun void setFreq(int note, int k, Osc osc)
{
    if (majorMinor[k]) 
    {
        Std.mtof(major[note] + offset + position) => osc.freq;
    } else {
        Std.mtof(minor[note] + offset + position) => osc.freq;
    }    
}

fun int getNote(int note, int k)
{
    if (majorMinor[k]) 
    {
        return major[note] + offset + position;
    } else {
        return minor[note] + offset + position;
    }     
}

spork ~ DrumMachine();
spork ~ Chords();

while ( true)
{
    beat * 16 => now;
}
