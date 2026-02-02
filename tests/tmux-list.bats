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

@test "tmux-list empty is not error" {
    run tmux-list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
}
