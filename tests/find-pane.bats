setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "find_pane does exact match, not regex" {
    tmux-run --prefix "$TEST_PREFIX" --name "a-b" -- sleep 60
    sleep 0.3

    # "a_b" should NOT match "a-b"
    run tmux-read --prefix "$TEST_PREFIX" --name "a_b"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]

    # "a-b" should match exactly
    run tmux-read --prefix "$TEST_PREFIX" --name "a-b"
    [ "$status" -eq 0 ]
}
