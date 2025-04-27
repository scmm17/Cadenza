public class MidiMapper
{
    string inputDeviceName;
    string outputDeviceName;
    int outputChannel;

    MidiIn min;
    MidiOut mout;
    MidiMsg msg;
    
    fun MidiMapper(string inputName, string outputName, int outChannel)
    {
        inputName => inputDeviceName;
        outputName => outputDeviceName;
        outChannel-1 => outputChannel;
    }

    fun startEventLoop()
    {
        midi_events();
    }   

    fun midi_events() {
        // open midi receiver, exit on fail
        min.open(inputDeviceName) => int status;
        <<< "Input open status:", status, "name:", min.name() >>>;
        if ( !status )
            me.exit(); 

        mout.open(outputDeviceName) => status;
        if ( !status ) 
            me.exit();         

        <<< "Output open status:", status, "name:", mout.name() >>>;
        while( true )
        {
            // wait on midi event
            min => now;

            // receive midimsg(s)
            while( min.recv( msg ) )
            {
                // <<< "In d1:", msg.data1, "d2:", msg.data2, "d3:", msg.data3 >>>;
                if (msg.data1 == 144) 
                {
                    0x90 | (outputChannel) => msg.data1;
                    mout.send(msg);
                    <<< "Out d1:", msg.data1, "d2:", msg.data2, "d3:", msg.data3  >>>;
                }

                if (msg.data1 == 128) 
                {
                    0x80 | (outputChannel) => msg.data1;
                    mout.send(msg);
                    // <<< "Out d1:", msg.data1, "d2:", msg.data2, "d3:", msg.data3  >>>;
                }
            }
        }
    }
}
