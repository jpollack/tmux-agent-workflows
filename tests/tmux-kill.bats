setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-kill --help prints usage" {
    run tmux-kill --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-kill terminates a running pane" {
    tmux-run --prefix "$TEST_PREFIX" --name victim -- sleep 60
    sleep 0.3
    run tmux-kill --prefix "$TEST_PREFIX" --name victim
    [ "$status" -eq 0 ]
    # Window should be gone
    ! tmux list-windows -t "$TEST_PREFIX" -F '#{window_name}' | grep -qx victim
}

@test "tmux-kill fails for missing pane" {
    run tmux-kill --prefix "$TEST_PREFIX" --name nonexistent
    [ "$status" -ne 0 ]
}
