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
