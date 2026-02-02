setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-list --help prints usage" {
    run tmux-list --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-list shows running panes" {
    tmux-run --prefix "$TEST_PREFIX" --name proc1 -- sleep 60
    sleep 0.3
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"proc1"* ]]
}

@test "tmux-list shows exited panes" {
    tmux-run --prefix "$TEST_PREFIX" --name quickjob -- true
    sleep 0.5
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"quickjob"* ]]
}

@test "tmux-list empty session shows no output" {
    # Session created in setup has only the default window.
    # tmux-list should filter it out.
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "tmux-list shows exited(0) for completed command" {
    tmux-run --prefix "$TEST_PREFIX" --name done-job -- true
    sleep 1
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"done-job"*"exited(0)"* ]]
}

@test "tmux-list --format json outputs JSON lines for running pane" {
    tmux-run --prefix "$TEST_PREFIX" --name proc1 -- sleep 60
    sleep 0.3
    run tmux-list --prefix "$TEST_PREFIX" --format json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"name":"proc1"'* ]]
    [[ "$output" == *'"status":"running"'* ]]
}

@test "tmux-list --format json outputs exit_code for exited pane" {
    tmux-run --prefix "$TEST_PREFIX" --name done1 -- true
    sleep 1
    run tmux-list --prefix "$TEST_PREFIX" --format json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"status":"exited"'* ]]
    [[ "$output" == *'"exit_code":0'* ]]
}

@test "tmux-list --format invalid fails" {
    run tmux-list --prefix "$TEST_PREFIX" --format xml
    [ "$status" -ne 0 ]
    [[ "$output" == *"--format must be"* ]]
}

@test "tmux-list shows correct status when process is killed" {
    tmux-run --prefix "$TEST_PREFIX" --name killed -- sleep 300
    sleep 0.5
    # Kill the process with SIGTERM via tmux
    tmux send-keys -t "$TEST_PREFIX:killed" C-c
    sleep 1
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    # Status field should NOT contain "sleep" (the command name)
    [[ "$output" == *"killed"*"exited("* ]]
    [[ "$output" != *"exited(sleep)"* ]]
}

@test "tmux-list shows exited(1) for failed command" {
    tmux-run --prefix "$TEST_PREFIX" --name fail-job -- false
    sleep 1
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fail-job"*"exited(1)"* ]]
}

@test "tmux-list --format json produces valid JSON for each line" {
    tmux-run --prefix "$TEST_PREFIX" --name jsontest -- sleep 60
    sleep 0.3
    run tmux-list --prefix "$TEST_PREFIX" --format json
    [ "$status" -eq 0 ]
    # Validate each line is valid JSON using python (widely available)
    while IFS= read -r line; do
        echo "$line" | python3 -c "import sys,json; json.load(sys.stdin)"
    done <<< "$output"
}
