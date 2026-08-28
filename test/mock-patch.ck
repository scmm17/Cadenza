@import "../framework/patch.ck"
@import "../framework/song.ck"

public class MockPatch extends Patch {
    // Override deviceName to prevent gma.open()
    "" => deviceName;
    
    // Record last played note for assertions
    int lastNotePlayed;
    int lastVelocityPlayed;
    dur lastDurationPlayed;

    fun MockPatch() {
        Patch(); // Call our new no-arg constructor
    }

    fun void noteOn(int note, int velocity, dur duration) {
        note => lastNotePlayed;
        velocity => lastVelocityPlayed;
        duration => lastDurationPlayed;
    }
    
    fun void noteOff(int note) {
        // No-op for testing
    }
}

public class MockSong extends Song {
    fun MockSong() {
        // Minimal setup to avoid event loops and live MIDI
        // We override initialization fields without starting LaunchControl or timers
        60 => rootNote; // Middle C
        120 => BPM;
        // Don't call LaunchControl or anything else
    }

    fun void addPart(Part part) {
        // No-op or minimal
    }
    
    fun void advance(dur d) {
        // Mock advancing time
        // E.g., skip doing actual `d => now;` to keep tests instantaneous if possible
        // but if methods depend on time advancing, we could allow it.
        // For testing logic, advancing is often not strictly needed to block.
        // `d => now;` might be okay if it's small, but let's just do a tiny fast-forward if needed, 
        // or actually `d => now;` if tests run sequentially and we want them to pass instantly, we can just do 0::ms => now;
        0::ms => now;
    }
}
