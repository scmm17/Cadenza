// Shared assertion helpers for test suite

public class TestCounter {
    static int passed;
    static int failed;
}

public class Assert {
    fun static void equalInt(string name, int a, int b) {
        if (a != b) {
            <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
            TestCounter.failed++;
        } else {
            TestCounter.passed++;
        }
    }

    fun static void equalFloat(string name, float a, float b, float epsilon) {
        (a - b) => float d;
        if (d < 0) { -d => d; }
        if (d > epsilon) {
            <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
            TestCounter.failed++;
        } else {
            TestCounter.passed++;
        }
    }

    fun static void equalString(string name, string a, string b) {
        if (a != b) {
            <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
            TestCounter.failed++;
        } else {
            TestCounter.passed++;
        }
    }

    fun static void arraysEqualInt(string name, int a[], int b[]) {
        if (a.cap() != b.cap()) {
            <<< "ASSERT FAIL (", name, "): arrays have different sizes:", a.cap(), "!=", b.cap() >>>;
            TestCounter.failed++;
            return;
        }
        for (0 => int i; i < a.cap(); i++) {
            if (a[i] != b[i]) {
                <<< "ASSERT FAIL (", name, "): array mismatch at index", i, ":", a[i], "!=", b[i] >>>;
                TestCounter.failed++;
                return;
            }
        }
        TestCounter.passed++;
    }

    fun static void arraysEqualFloat(string name, float a[], float b[], float epsilon) {
        if (a.cap() != b.cap()) {
            <<< "ASSERT FAIL (", name, "): arrays have different sizes:", a.cap(), "!=", b.cap() >>>;
            TestCounter.failed++;
            return;
        }
        for (0 => int i; i < a.cap(); i++) {
            (a[i] - b[i]) => float d;
            if (d < 0) { -d => d; }
            if (d > epsilon) {
                <<< "ASSERT FAIL (", name, "): array mismatch at index", i, ":", a[i], "!=", b[i] >>>;
                TestCounter.failed++;
                return;
            }
        }
        TestCounter.passed++;
    }

    fun static void isTrue(string name, int condition) {
        if (!condition) {
            <<< "ASSERT FAIL (", name, "): expected true but was false" >>>;
            TestCounter.failed++;
        } else {
            TestCounter.passed++;
        }
    }

    fun static void isFalse(string name, int condition) {
        if (condition) {
            <<< "ASSERT FAIL (", name, "): expected false but was true" >>>;
            TestCounter.failed++;
        } else {
            TestCounter.passed++;
        }
    }
}
