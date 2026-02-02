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

@test "tmux-read fails for missing pane" {
    run tmux-read --prefix "$TEST_PREFIX" --name nonexistent
    [ "$status" -ne 0 ]
}
