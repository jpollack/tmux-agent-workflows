setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-wait --help prints usage" {
    run tmux-wait --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-wait returns 0 for successful command" {
    tmux-run --prefix "$TEST_PREFIX" --name quickjob -- true
    run tmux-wait --prefix "$TEST_PREFIX" --name quickjob --timeout 10
    [ "$status" -eq 0 ]
}

@test "tmux-wait returns command exit code on failure" {
    tmux-run --prefix "$TEST_PREFIX" --name failjob -- false
    run tmux-wait --prefix "$TEST_PREFIX" --name failjob --timeout 10
    [ "$status" -eq 1 ]
}

@test "tmux-wait times out with exit code 124" {
    tmux-run --prefix "$TEST_PREFIX" --name slowjob -- sleep 300
    run tmux-wait --prefix "$TEST_PREFIX" --name slowjob --timeout 2 --poll 1
    [ "$status" -eq 124 ]
}

@test "tmux-wait fails for nonexistent pane" {
    run tmux-wait --prefix "$TEST_PREFIX" --name nope --timeout 5
    [ "$status" -ne 0 ]
}

@test "tmux-wait returns non-zero for killed process" {
    tmux-run --prefix "$TEST_PREFIX" --name killed -- bash -c 'trap "" INT; sleep 300'
    sleep 0.5
    # Get the pane PID and kill it with SIGKILL
    local pane_pid
    pane_pid=$(tmux list-windows -t "$TEST_PREFIX" -F '#{window_name}|#{pane_pid}' \
        | awk -F'|' '$1 == "killed" {print $2}')
    kill -9 "$pane_pid"
    run tmux-wait --prefix "$TEST_PREFIX" --name killed --timeout 10
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown status"* ]]
}

@test "tmux-wait rejects non-positive --poll" {
    run tmux-wait --prefix "$TEST_PREFIX" --name nope --poll 0
    [ "$status" -eq 1 ]
    [[ "$output" == *"--poll must be positive"* ]]
}
