setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-test-$$"
    tmux-session create --prefix "$TEST_PREFIX"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "tmux-run --help prints usage" {
    run tmux-run --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "tmux-run executes command in named pane" {
    run tmux-run --prefix "$TEST_PREFIX" --name mypane -- echo hello
    [ "$status" -eq 0 ]
    # Pane should exist — check by window name
    tmux list-windows -t "$TEST_PREFIX" -F '#{window_name}' | grep -q mypane
}

@test "tmux-run fails without --name" {
    run tmux-run --prefix "$TEST_PREFIX" -- echo hello
    [ "$status" -ne 0 ]
    [[ "$output" == *"--name"* ]]
}

@test "tmux-run fails if name already exists" {
    tmux-run --prefix "$TEST_PREFIX" --name dupe -- sleep 60
    run tmux-run --prefix "$TEST_PREFIX" --name dupe -- echo hi
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "tmux-run fails if session missing" {
    run tmux-run --prefix "nonexistent-$$" --name foo -- echo hi
    [ "$status" -ne 0 ]
}

@test "tmux-run preserves command quoting" {
    local helper="$BATS_TEST_TMPDIR/quoter.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
echo "ARGS:$#"
for arg in "$@"; do echo "ARG:$arg"; done
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name quoter -- "$helper" "hello world" "foo bar"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name quoter
    [[ "$output" == *"ARGS:2"* ]]
    [[ "$output" == *"ARG:hello world"* ]]
    [[ "$output" == *"ARG:foo bar"* ]]
}

@test "tmux-run --env sets environment variables" {
    local helper="$BATS_TEST_TMPDIR/envcheck.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
echo "MY_VAR=$MY_VAR"
echo "OTHER=$OTHER"
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name envtest --env MY_VAR=hello --env OTHER=world -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name envtest
    [[ "$output" == *"MY_VAR=hello"* ]]
    [[ "$output" == *"OTHER=world"* ]]
}

@test "tmux-run --dir sets working directory" {
    local workdir="$BATS_TEST_TMPDIR/workdir"
    mkdir -p "$workdir"
    local helper="$BATS_TEST_TMPDIR/pwder.sh"
    cat > "$helper" <<'SCRIPT'
#!/bin/bash
pwd
sleep 60
SCRIPT
    chmod +x "$helper"
    tmux-run --prefix "$TEST_PREFIX" --name dirtest --dir "$workdir" -- "$helper"
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name dirtest
    [[ "$output" == *"$workdir"* ]]
}
