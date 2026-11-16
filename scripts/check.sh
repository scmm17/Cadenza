#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== 1. Running ChucK unit test suite ==="
test_out=$(chuck -s test/run-all.ck 2>&1)
echo "$test_out" | grep -v "^probabilities:"
if ! echo "$test_out" | grep -q "TOTAL:"; then
    echo "FAIL: test/run-all.ck did not reach summary"
    exit 1
fi
if echo "$test_out" | grep -q "ASSERT FAIL"; then
    echo "FAIL: test/run-all.ck reported assertion failures"
    exit 1
fi

echo "=== 2. Running standalone YAML tests ==="
yaml_out=$(cd test && chuck -s test-yaml.ck 2>&1)
echo "$yaml_out" | grep -E "PASS|FAIL|ASSERT|error" || true
if echo "$yaml_out" | grep -q "ASSERT FAIL"; then
    echo "FAIL: test-yaml.ck reported assertion failures"
    exit 1
fi
if echo "$yaml_out" | grep -qi "error:"; then
    echo "FAIL: test-yaml.ck reported errors"
    exit 1
fi

echo "=== 3. Syntax-checking music/*.ck ==="
# Pre-existing legacy scripts that predate current constructor signatures
SKIP_SONGS="first-song.ck lc-test.ck midi-keys.ck refactor.ck v3-midi.ck"
song_failures=0
song_count=0
for f in music/*.ck; do
    base=$(basename "$f")
    skip=0
    for s in $SKIP_SONGS; do
        if [ "$base" = "$s" ]; then
            skip=1
            break
        fi
    done
    if [ "$skip" -eq 1 ]; then
        continue
    fi
    song_count=$((song_count + 1))
    out=$(cd music && chuck --syntax "$base" 2>&1 || true)
    if echo "$out" | grep -qi "error"; then
        echo "FAIL: $f"
        echo "$out"
        song_failures=$((song_failures + 1))
    fi
done
if [ "$song_failures" -gt 0 ]; then
    echo "FAIL: $song_failures music script(s) failed syntax check"
    exit 1
fi
echo "OK: $song_count music scripts syntax-checked cleanly"

echo "=== 4. Checking Node/JS syntax ==="
node --check gui/server.js
if compgen -G "gui/server/*.js" > /dev/null; then
    for jsf in gui/server/*.js; do
        node --check "$jsf"
    done
fi
if compgen -G "gui/js/*.js" > /dev/null; then
    for jsf in gui/js/*.js; do
        node --check "$jsf"
    done
fi
echo "OK: JS files passed syntax check"

if [ -f "tools/gen-presets.js" ]; then
    echo "=== 5. Checking generated preset files ==="
    node tools/gen-presets.js --check
fi

echo "=== ALL CHECKS PASSED ==="
