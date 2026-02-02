# tests/tmux-send.bats

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-send --help prints usage" {
    run tmux-send --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-send sends text to pane" {
    tmux-run --prefix "$TEST_PREFIX" --name target -- cat
    sleep 0.3
    run tmux-send --prefix "$TEST_PREFIX" --name target --text "hello world"
    [ "$status" -eq 0 ]
}

@test "tmux-send sends enter key" {
    tmux-run --prefix "$TEST_PREFIX" --name target -- cat
    sleep 0.3
    run tmux-send --prefix "$TEST_PREFIX" --name target --keys Enter
    [ "$status" -eq 0 ]
}

@test "tmux-send fails for missing pane" {
    run tmux-send --prefix "$TEST_PREFIX" --name nonexistent --text "hi"
    [ "$status" -ne 0 ]
}
