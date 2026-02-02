setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-run rejects name with colon" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --prefix "$TEST_PREFIX" --name "bad:name" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-run rejects name with dot" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --prefix "$TEST_PREFIX" --name "bad.name" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-run rejects name with exclamation" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --prefix "$TEST_PREFIX" --name "bad!name" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-session rejects prefix with colon" {
    run tmux-session create --prefix "bad:prefix"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-session rejects prefix with dot" {
    run tmux-session create --prefix "bad.prefix"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-read rejects name with special chars" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-read --prefix "$TEST_PREFIX" --name "bad:name"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-send rejects name with special chars" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-send --prefix "$TEST_PREFIX" --name "bad.name" --text "hi"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-kill rejects name with special chars" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-kill --prefix "$TEST_PREFIX" --name "bad!name"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}
