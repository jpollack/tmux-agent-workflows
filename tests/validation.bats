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

@test "tmux-run rejects name with space" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --prefix "$TEST_PREFIX" --name "has space" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-run rejects name with tab" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --prefix "$TEST_PREFIX" --name $'has\ttab' -- echo hi
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

@test "tmux-list rejects prefix with special chars" {
    run tmux-list --prefix "bad:prefix"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

# Bug #1: Missing argument values
@test "tmux-run --name without value fails gracefully" {
    run tmux-run --name
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-session create --prefix without value fails gracefully" {
    run tmux-session create --prefix
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-read --name without value fails gracefully" {
    run tmux-read --name
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-wait --name without value fails gracefully" {
    run tmux-wait --name
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-send --name without value fails gracefully" {
    run tmux-send --name
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-kill --name without value fails gracefully" {
    run tmux-kill --name
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "tmux-list --format without value fails gracefully" {
    run tmux-list --format
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

# Bug #2: JSON injection prevention
@test "tmux-run rejects name with double quote" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --name 'bad"name' --prefix "$TEST_PREFIX" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}

@test "tmux-run rejects name with backslash" {
    tmux-session create --prefix "$TEST_PREFIX"
    run tmux-run --name 'bad\name' --prefix "$TEST_PREFIX" -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain"* ]]
}
