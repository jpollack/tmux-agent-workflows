setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-read --help prints usage" {
    run tmux-read --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-read captures pane output" {
    local helper="$BATS_TEST_TMPDIR/echoer.sh"
    printf '#!/bin/bash\necho "TESTOUTPUT123"\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name echoer -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name echoer
    [ "$status" -eq 0 ]
    [[ "$output" == *"TESTOUTPUT123"* ]]
}

@test "tmux-read --last N returns last N lines" {
    # Create a helper script to avoid quoting issues with tmux send-keys
    local helper="$BATS_TEST_TMPDIR/liner.sh"
    printf '#!/bin/bash\nfor i in $(seq 1 20); do echo "line$i"; done\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name liner -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name liner --last 5
    [ "$status" -eq 0 ]
    [[ "$output" == *"line20"* ]]
    # Ensure early lines are not present (line5 would not appear in last 5 of 20 lines)
    [[ "$output" != *"line5"* ]]
}

@test "tmux-read --start N skips first N lines" {
    local helper="$BATS_TEST_TMPDIR/starter.sh"
    printf '#!/bin/bash\nfor i in $(seq 1 10); do echo "sline$i"; done\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name starter -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name starter --start 8
    [ "$status" -eq 0 ]
    [[ "$output" == *"sline9"* ]]
    [[ "$output" == *"sline10"* ]]
    [[ "$output" != *"sline8"* ]]
}

@test "tmux-read --start with --last combines correctly" {
    local helper="$BATS_TEST_TMPDIR/combo.sh"
    printf '#!/bin/bash\nfor i in $(seq 1 10); do echo "cline$i"; done\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name combo -- "$helper"
    sleep 1
    # Skip first 5, then take last 2 of remaining (lines 6-10 -> last 2 = 9,10)
    run tmux-read --prefix "$TEST_PREFIX" --name combo --start 5 --last 2
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [[ "$output" == *"cline9"* ]]
    [[ "$output" == *"cline10"* ]]
}

@test "tmux-read fails for missing pane" {
    run tmux-read --prefix "$TEST_PREFIX" --name nonexistent
    [ "$status" -ne 0 ]
}

@test "tmux-read --grep waits for pattern" {
    local helper="$BATS_TEST_TMPDIR/delayed.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
sleep 1
echo "BUILD SUCCEEDED"
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name grepper -- "$helper"
    run tmux-read --prefix "$TEST_PREFIX" --name grepper --grep "BUILD SUCCEEDED" --timeout 10
    [ "$status" -eq 0 ]
    [[ "$output" == *"BUILD SUCCEEDED"* ]]
}

@test "tmux-read --grep times out with exit 124" {
    tmux-run --prefix "$TEST_PREFIX" --name grepper2 -- sleep 300
    run tmux-read --prefix "$TEST_PREFIX" --name grepper2 --grep "NEVER" --timeout 3 --poll 1
    [ "$status" -eq 124 ]
}

@test "tmux-read strips trailing blank lines" {
    local helper="$BATS_TEST_TMPDIR/blanks.sh"
    printf '#!/bin/bash\necho "CONTENT"\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name blanks -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name blanks
    [ "$status" -eq 0 ]
    # Last line of output should not be blank
    last_line="${lines[${#lines[@]}-1]}"
    [[ -n "$last_line" ]]
    [[ "$last_line" != *[[:space:]]* || "$last_line" == *[^[:space:]]* ]]
}

@test "tmux-read strips Pane is dead line" {
    tmux-run --prefix "$TEST_PREFIX" --name deadpane -- echo "DEADTEST"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name deadpane
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEADTEST"* ]]
    [[ "$output" != *"Pane is dead"* ]]
}

@test "tmux-read --grep with --last N returns last N lines" {
    local helper="$BATS_TEST_TMPDIR/greplines.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
for i in $(seq 1 20); do echo "gline$i"; done
echo "MARKER"
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name greplines -- "$helper"
    run tmux-read --prefix "$TEST_PREFIX" --name greplines --grep "MARKER" --timeout 10 --last 3
    [ "$status" -eq 0 ]
    # Should have exactly 3 lines
    [ "${#lines[@]}" -eq 3 ]
    [[ "$output" == *"MARKER"* ]]
}

@test "tmux-read --grep rejects non-positive --poll" {
    tmux-run --prefix "$TEST_PREFIX" --name polltest -- sleep 300
    run tmux-read --prefix "$TEST_PREFIX" --name polltest --grep "X" --poll 0
    [ "$status" -eq 1 ]
    [[ "$output" == *"--poll must be positive"* ]]
}

@test "tmux-read --history controls scrollback capture" {
    local helper="$BATS_TEST_TMPDIR/manylines.sh"
    printf '#!/bin/bash\nfor i in $(seq 1 50); do echo "histline$i"; done\nsleep 60\n' > "$helper"
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name histtest -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name histtest --history 5000
    [ "$status" -eq 0 ]
    [[ "$output" == *"histline1"* ]]
    [[ "$output" == *"histline50"* ]]
}

@test "tmux-read --grep-regex uses extended regex" {
    local helper="$BATS_TEST_TMPDIR/regextest.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
echo "BUILD OK 42"
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name regextest -- "$helper"
    run tmux-read --prefix "$TEST_PREFIX" --name regextest --grep "BUILD OK [0-9]+" --grep-regex --timeout 10
    [ "$status" -eq 0 ]
    [[ "$output" == *"BUILD OK 42"* ]]
}

@test "tmux-read --grep without --grep-regex uses fixed string" {
    local helper="$BATS_TEST_TMPDIR/fixedtest.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
echo "[OK]"
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name fixedtest -- "$helper"
    # [OK] as fixed string matches literally, not as regex char class
    run tmux-read --prefix "$TEST_PREFIX" --name fixedtest --grep "[OK]" --timeout 10
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}
