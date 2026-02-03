# tests/integration.bats

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_PREFIX="bats-int-$$"
}

teardown() {
    tmux kill-session -t "$TEST_PREFIX" 2>/dev/null || true
}

@test "full workflow: create, run, read, send, list, kill, destroy" {
    # Create a helper script for the worker
    HELPER=$(mktemp)
    cat > "$HELPER" <<'SCRIPT'
#!/usr/bin/env bash
echo READY
read line
echo "GOT:$line"
sleep 60
SCRIPT
    chmod +x "$HELPER"

    # Create session
    tmux-session create --prefix "$TEST_PREFIX"

    # Run a command
    tmux-run --prefix "$TEST_PREFIX" --name worker -- "$HELPER"
    sleep 1.5

    # Read output — should see READY
    run tmux-read --prefix "$TEST_PREFIX" --name worker
    [[ "$output" == *"READY"* ]]

    # Send input
    tmux-send --prefix "$TEST_PREFIX" --name worker --text "hello" --keys Enter
    sleep 0.5

    # Read again — should see GOT:hello
    run tmux-read --prefix "$TEST_PREFIX" --name worker
    [[ "$output" == *"GOT:hello"* ]]

    # List — should show worker
    run tmux-list --prefix "$TEST_PREFIX"
    [[ "$output" == *"worker"* ]]

    # Kill the pane
    tmux-kill --prefix "$TEST_PREFIX" --name worker

    # Destroy session
    tmux-session destroy --prefix "$TEST_PREFIX"

    # Session should be gone
    ! tmux has-session -t "$TEST_PREFIX" 2>/dev/null

    # Clean up helper
    rm -f "$HELPER"
}

@test "exit detection: run, wait, list shows exited(0)" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name shortlived -- echo done
    run tmux-wait --prefix "$TEST_PREFIX" --name shortlived --timeout 10
    [ "$status" -eq 0 ]
    run tmux-list --prefix "$TEST_PREFIX"
    [[ "$output" == *"shortlived"*"exited(0)"* ]]
}

@test "parallel tasks with different exit codes" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name ok -- true
    tmux-run --prefix "$TEST_PREFIX" --name fail1 -- bash -c 'exit 1'
    tmux-run --prefix "$TEST_PREFIX" --name fail5 -- bash -c 'exit 5'
    sleep 1
    run tmux-wait --prefix "$TEST_PREFIX" --all --timeout 10
    [ "$status" -eq 5 ]  # Highest exit code
}

@test "environment variables are set correctly" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name envcheck --env MYVAR=hello --env OTHER=world -- bash -c 'echo $MYVAR $OTHER'
    sleep 1
    run tmux-read --prefix "$TEST_PREFIX" --name envcheck
    [[ "$output" == *"hello world"* ]]
}

@test "session status tracks multiple pane states" {
    tmux-session create --prefix "$TEST_PREFIX"
    tmux-run --prefix "$TEST_PREFIX" --name running1 -- sleep 60
    tmux-run --prefix "$TEST_PREFIX" --name running2 -- sleep 60
    tmux-run --prefix "$TEST_PREFIX" --name success -- true
    tmux-run --prefix "$TEST_PREFIX" --name fail -- false
    sleep 1
    run tmux-session status --prefix "$TEST_PREFIX" --format json
    [ "$status" -eq 0 ]
    echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['total'] == 4, f'expected 4, got {d[\"total\"]}'
assert d['running'] == 2, f'expected 2 running, got {d[\"running\"]}'
assert d['exited'] == 2, f'expected 2 exited, got {d[\"exited\"]}'
assert d['failed'] == 1, f'expected 1 failed, got {d[\"failed\"]}'
"
}
