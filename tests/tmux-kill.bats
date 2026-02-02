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

@test "tmux-kill --all kills all panes except _init" {
    tmux-run --prefix "$TEST_PREFIX" --name a -- sleep 60
    tmux-run --prefix "$TEST_PREFIX" --name b -- sleep 60
    sleep 0.3
    run tmux-kill --prefix "$TEST_PREFIX" --all
    [ "$status" -eq 0 ]
    # Only _init should remain
    run tmux-list --prefix "$TEST_PREFIX"
    [ -z "$output" ]
    # Session should still exist
    tmux has-session -t "$TEST_PREFIX" 2>/dev/null
}

@test "tmux-kill --all and --name are mutually exclusive" {
    run tmux-kill --prefix "$TEST_PREFIX" --all --name foo
    [ "$status" -ne 0 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "tmux-kill fails for missing pane" {
    run tmux-kill --prefix "$TEST_PREFIX" --name nonexistent
    [ "$status" -ne 0 ]
}
