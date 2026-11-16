// CadenzaConstants
// Purpose: Central numeric constants for OSC ports, MIDI CCs, and LaunchControl XL note/color mappings.
// Imports: none
// Imported by: framework/core/gui-link.ck, framework/devices/patch.ck, framework/control/*.ck

public class CadenzaConstants
{
    // OSC ports
    fun static int OSC_CONTROL_PORT() { return 9449; }
    fun static int OSC_GUI_PORT()     { return 9450; }

    // Standard & device MIDI CCs
    fun static int CC_BANK_MSB()       { return 0; }
    fun static int CC_VOLUME()         { return 7; }
    fun static int CC_PAN()            { return 10; }
    fun static int CC_BANK_LSB()       { return 32; }
    fun static int CC_RESONANCE()      { return 71; }
    fun static int CC_CUTOFF()         { return 74; }
    fun static int CC_ALL_NOTES_OFF()  { return 123; }
    fun static int CC_MOOG_CUTOFF()    { return 19; }
    fun static int CC_MOOG_RESONANCE() { return 21; }

    // LaunchControl XL MIDI notes & LED colors
    fun static int LC_SELECT_BASE()    { return 41; }
    fun static int LC_MUTE_BASE()      { return 73; }
    fun static int LC_PREV_CAT()       { return 104; }
    fun static int LC_NEXT_CAT()       { return 105; }
    fun static int LC_PREV_PRESET()    { return 106; }
    fun static int LC_NEXT_PRESET()    { return 107; }
    fun static int LC_MUTE_MODE()      { return 109; }
    fun static int LC_SOLO_MODE()      { return 110; }
    fun static int LC_LED_GREEN()      { return 0x3c; }
    fun static int LC_LED_RED()        { return 0x0F; }
}
