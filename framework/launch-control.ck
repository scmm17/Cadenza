public class LaunchControl
{
    string inputDeviceName;
    string outputDeviceName;
    int outputChannel;

    MidiIn min;
    MidiMsg msg;
    Song song;
    
    fun LaunchControl(Song s)
    {
        "Launch Control XL" => inputDeviceName;
        s => song;
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
            }
        }
    }
}
