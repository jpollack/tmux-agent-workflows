# tests/tmux-session.bats

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
}

teardown() {
    tmux kill-session -t "${TEST_PREFIX}" 2>/dev/null || true
}

@test "tmux-session --help prints usage" {
    run tmux-session --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-session create makes a new session" {
    run tmux-session create --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    tmux has-session -t "$TEST_PREFIX" 2>/dev/null
}

@test "tmux-session create fails if session exists" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session create --prefix "$TEST_PREFIX"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "tmux-session destroy kills session" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session destroy --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    ! tmux has-session -t "$TEST_PREFIX" 2>/dev/null
}

@test "tmux-session destroy fails if session missing" {
    run tmux-session destroy --prefix "nonexistent-$$"
    [ "$status" -ne 0 ]
}

@test "tmux-session list shows sessions" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_PREFIX"* ]]
}

@test "tmux-session list empty is not an error" {
    run tmux-session list --prefix "nonexistent-$$"
    [ "$status" -eq 0 ]
}

@test "tmux-session list uses exact match not prefix match" {
    local prefix2="${TEST_PREFIX}-extra"
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-session create --prefix "$prefix2"
    run tmux-session list --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == "$TEST_PREFIX" ]]
    [[ "$output" != *"$prefix2"* ]]
    tmux kill-session -t "$prefix2" 2>/dev/null || true
}

@test "tmux-session list --all shows all sessions" {
    local prefix2="${TEST_PREFIX}-extra"
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-session create --prefix "$prefix2"
    run tmux-session list --all
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_PREFIX"* ]]
    [[ "$output" == *"$prefix2"* ]]
    tmux kill-session -t "$prefix2" 2>/dev/null || true
}

@test "tmux-session create --quiet suppresses output" {
    run tmux-session create --prefix "$TEST_PREFIX" --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    tmux has-session -t "$TEST_PREFIX" 2>/dev/null
}

@test "tmux-session create is not fooled by prefix-matching session" {
    local longer="${TEST_PREFIX}-extra"
    tmux-session create --prefix "$longer"
    # The longer session exists, but TEST_PREFIX itself does not — create should succeed
    run tmux-session create --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    # Destroy TEST_PREFIX should only destroy TEST_PREFIX, not the longer one
    run tmux-session destroy --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    # The longer session should still exist
    tmux list-sessions -F '#{session_name}' | grep -qx "$longer"
    tmux kill-session -t "$longer" 2>/dev/null || true
}

@test "tmux-session exists returns 0 when session exists" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session exists --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
}

@test "tmux-session exists returns 1 when session missing" {
    run tmux-session exists --prefix "nonexistent-$$"
    [ "$status" -eq 1 ]
}

@test "tmux-session exists uses exact match" {
    local longer="${TEST_PREFIX}-extra"
    tmux-session create --prefix "$longer"
    run tmux-session exists --prefix "$TEST_PREFIX"
    [ "$status" -eq 1 ]
    tmux kill-session -t "$longer" 2>/dev/null || true
}

@test "tmux-session destroy --quiet suppresses output" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session destroy --prefix "$TEST_PREFIX" --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "tmux-session status shows pane counts" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name running -- sleep 60
    tmux-run --prefix "$TEST_PREFIX" --name exited -- true
    tmux-run --prefix "$TEST_PREFIX" --name failed -- false
    sleep 2
    run tmux-session status --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Session: $TEST_PREFIX"* ]]
    [[ "$output" == *"Total panes: 3"* ]]
    [[ "$output" == *"Running: 1"* ]]
    [[ "$output" == *"Exited: 2"* ]]
    [[ "$output" == *"failed: 1"* ]]
}

@test "tmux-session status --format json outputs valid JSON" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name task1 -- sleep 60
    tmux-run --prefix "$TEST_PREFIX" --name task2 -- true
    sleep 1
    run tmux-session status --prefix "$TEST_PREFIX" --format json
    [ "$status" -eq 0 ]
    echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['total']==2; assert d['running']==1; assert d['exited']==1"
}

@test "tmux-session status fails if session missing" {
    run tmux-session status --prefix "nonexistent-$$"
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "tmux-session status with empty session shows zero counts" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-session status --prefix "$TEST_PREFIX"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Total panes: 0"* ]]
}

@test "tmux-session --format invalid fails" {
    run tmux-session status --prefix "$TEST_PREFIX" --format xml
    [ "$status" -ne 0 ]
    [[ "$output" == *"--format must be"* ]]
}
