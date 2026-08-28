// Runner script to execute all test modules

@import "test-helpers.ck"

// Import all test modules
@import "test-note-collection.ck"
@import "test-lsystem.ck"
@import "test-part-rhythm.ck"
@import "test-fragment-transitions.ck"
@import "test-drum-machine.ck"

// Explicitly call the runner functions from each module
// since @import does not execute top-level statements.
NoteCollectionTests.run();
LSystemTests.run();
PartRhythmTests.run();
FragmentTransitionsTests.run();
DrumMachineTests.run();

// Print final summary
<<< "===========================" >>>;
<<< "  TOTAL: ", TestCounter.passed, "passed,", TestCounter.failed, "failed" >>>;
<<< "===========================" >>>;

if (TestCounter.failed > 0) {
    Machine.crash(); // Exit with error code if tests fail
}
