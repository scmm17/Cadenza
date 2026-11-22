// GuiLink
// Purpose: Single shared OSC sender to the GUI bridge (localhost:9450).
// Imports: framework/core/constants.ck
// Imported by: framework/devices/patch.ck, framework/composition/fragment.ck, framework/control/state-broadcaster.ck

@import "constants.ck"

public class GuiLink
{
    static OscSend @ xmit;
    static int disabled;

    fun static void setEnabled(int on)
    {
        if (on) {
            0 => GuiLink.disabled;
        } else {
            1 => GuiLink.disabled;
        }
    }

    fun static void init()
    {
        if (GuiLink.xmit == null) {
            new OscSend @=> GuiLink.xmit;
            GuiLink.xmit.setHost("localhost", CadenzaConstants.OSC_GUI_PORT());
        }
    }

    fun static void sendNoteOn(int devIndex, int note, int velocity)
    {
        if (GuiLink.disabled || devIndex <= 0) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/noteOn", "i i i");
        devIndex => GuiLink.xmit.addInt;
        note => GuiLink.xmit.addInt;
        velocity => GuiLink.xmit.addInt;
    }

    fun static void sendNoteOff(int devIndex, int note)
    {
        if (GuiLink.disabled || devIndex <= 0) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/noteOff", "i i");
        devIndex => GuiLink.xmit.addInt;
        note => GuiLink.xmit.addInt;
    }

    fun static void sendAllNotesOff(int devIndex)
    {
        if (GuiLink.disabled || devIndex <= 0) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/allNotesOff", "i");
        devIndex => GuiLink.xmit.addInt;
    }

    fun static void sendTransition(string fromName, string toName)
    {
        if (GuiLink.disabled) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/transition", "s s");
        fromName => GuiLink.xmit.addString;
        toName => GuiLink.xmit.addString;
    }

    fun static void sendState(string json)
    {
        if (GuiLink.disabled) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/state", "s");
        json => GuiLink.xmit.addString;
    }

    fun static void sendGraphNode(int index, int total, string json)
    {
        if (GuiLink.disabled) return;
        init();
        GuiLink.xmit.startMsg("/cadenza/graphNode", "i i s");
        index => GuiLink.xmit.addInt;
        total => GuiLink.xmit.addInt;
        json => GuiLink.xmit.addString;
    }

    fun static void sendActivateSynth(string synthUiName)
    {
        if (GuiLink.disabled || synthUiName == "") return;
        init();
        GuiLink.xmit.startMsg("/cadenza/activateSynth", "s");
        synthUiName => GuiLink.xmit.addString;
    }
}
