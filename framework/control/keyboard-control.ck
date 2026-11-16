// KeyboardControl
// Purpose: Handles interactive terminal keyboard shortcuts during live playback.
// Imports: framework/composition/fragment.ck
// Imported by: framework/song/song.ck

@import "../composition/fragment.ck"

public class KeyboardControl
{
    fun void keyboardLoop(SongState @ song)
    {
        KBHit kb;

        if (song.currentDevice == null && song.devices[0] != null) {
            song.devices[0] @=> song.currentDevice;
        }
        if (song.currentDevice != null) {
            song.setMidiThruChannel(song.currentDevice.midiChannel);
        }

        while (true) {
            kb => now;
            while (kb.more()) {
                kb.getchar() => int key;
                if (SongContext.debug) {
                    <<< "ascii: ", key >>>;
                }
                if (key >= "1".charAt(0) && key <= "9".charAt(0)) {
                    key - "1".charAt(0) => int i;
                    if (song.selectDevice(i)) {
                        song.notifyStateChanged();
                    }
                }
                if ("Q".charAt(0) == key) {
                    song.shutdown();
                }
                if ("g".charAt(0) == key) {
                    !SongContext.golden => SongContext.golden;
                    song.notifyStateChanged();
                }
                if ("w".charAt(0) == key) {
                    song.saveConfig();
                    <<< "Saved config", "" >>>;
                }
                if ("a".charAt(0) == key) {
                    !song.allMode => song.allMode;
                    song.notifyStateChanged();
                }
            }
        }
    }
}
