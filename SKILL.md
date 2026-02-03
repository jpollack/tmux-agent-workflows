---
name: tmux-agent-workflows
description: Use when running concurrent commands, background processes, or parallel subagents. Use when needing to monitor, interact with, or wait for long-running tasks. Use when orchestrating multi-process workflows from a single session.
---

# Tmux Agent Workflows

Run concurrent commands, monitor output, wait for completion, and interact with processes via tmux.

## Quick Start

```bash
# Create session
tmux-session create

# Run parallel tasks
tmux-run --name build -- make -j8
tmux-run --name lint -- npm run lint
tmux-run --name test -- npm test

# Wait for all to complete
tmux-wait --all --timeout 300

# Check results
tmux-list

# Read any failures
tmux-read --name build --last 50

# Cleanup
tmux-session destroy
```

## Quick Reference

| Task | Command |
|------|---------|
| Start session | `tmux-session create [--prefix NAME]` |
| Check session exists | `tmux-session exists [--prefix NAME]` |
| Run command | `tmux-run --name build -- make -j4` |
| Run in directory | `tmux-run --name build --dir /project -- make` |
| Restart dead pane | `tmux-run --name build --replace -- make -j4` |
| Read output | `tmux-read --name build --last 20` |
| Read more history | `tmux-read --name build --history 5000` |
| Wait for pattern | `tmux-read --name build --grep "DONE" --timeout 60 --last 20` |
| Wait for regex | `tmux-read --name build --grep "OK\|DONE" --grep-regex --timeout 60` |
| Wait for disappearance | `tmux-read --name build --grep "COMPILING" --grep-invert --timeout 60` |
| Wait for exit | `tmux-wait --name build --timeout 300 --poll 5` |
| Wait for all panes | `tmux-wait --all --timeout 300` |
| Wait and print code | `tmux-wait --name build --timeout 300 --print` |
| Send input | `tmux-send --name repl --text "quit" --keys Enter` |
| Send Ctrl-C | `tmux-send --name server --keys C-c` |
| List panes | `tmux-list` |
| List as JSON | `tmux-list --format json` |
| List running only | `tmux-list --filter running` |
| List exited only | `tmux-list --filter exited` |
| Count panes | `tmux-list --count` |
| Count running | `tmux-list --filter running --count` |
| List all sessions | `tmux-session list --all` |
| Session status | `tmux-session status` |
| Status as JSON | `tmux-session status --format json` |
| Set env vars | `tmux-run --name build --env CI=true --env DEBUG=1 -- make` |
| Kill pane | `tmux-kill --name build` |
| End session | `tmux-session destroy` |

All scripts support `--prefix NAME` (default: `agent`) and `--help`. `--quiet`/`-q` is available on `tmux-session`, `tmux-run`, `tmux-kill`, and `tmux-wait`.

## Workflow

```
tmux-session create
  -> tmux-run --name NAME -- COMMAND
     -> tmux-read / tmux-wait / tmux-send (monitor, wait, interact)
        -> tmux-kill --name NAME (when done)
           -> tmux-session destroy (cleanup)
```

1. **Create session** once per task: `tmux-session create`
2. **Run commands** in named panes: `tmux-run --name build -- make -j4`
3. **Monitor** with `tmux-read --name build --last 20` or wait for specific output with `--grep`
4. **Wait for completion** with `tmux-wait --name build --timeout 300` (returns the command's exit code, or 124 on timeout)
5. **Check status** with `tmux-list` — shows `running` or `exited(N)` per pane
6. **Interact** with `tmux-send --name repl --text "input" --keys Enter`
7. **Cleanup**: `tmux-kill --name NAME` per pane, then `tmux-session destroy`

### Waiting for a Process to Be Ready

After starting a process, wait for a readiness indicator before proceeding:

```bash
tmux-run --name server -- ./start-server.sh
tmux-read --name server --grep "Listening on port" --timeout 30
# Server is now ready
```

### Environment Variables

Pass environment variables to commands with `--env KEY=VALUE` (repeatable):

```bash
tmux-run --name ci --env CI=true --env NODE_ENV=test -- npm test
```

Note: `--env` flags must appear before `--`.

## Spawning Subagents

Run Claude in isolated tmux panes for parallel subtasks:

```bash
tmux-run --name subtask1 -- claude -p "do something" --output-file /tmp/result1.txt
tmux-run --name subtask2 -- claude -p "do other thing" --output-file /tmp/result2.txt

# Wait for all panes at once
tmux-wait --all --timeout 600

# Or wait individually (order doesn't matter — already-exited panes return immediately)
tmux-wait --name subtask1 --timeout 600
tmux-wait --name subtask2 --timeout 600

# Check exit codes and collect output
for name in subtask1 subtask2; do
  tmux-wait --name "$name" --timeout 600 --print
  # exit code is in $? and also printed to stdout with --print
done

# Read results from output files
```

## Naming Rules

Names and prefixes must **not** start with '-' or contain ':', '.', '!', '"', '\\', or whitespace — tmux treats these as target separators, quotes and backslashes break JSON output, and whitespace breaks field parsing. Names must be unique within a session.

## Cleanup on Error

Use a trap to ensure the session is destroyed even if the script fails:

```bash
cleanup() { tmux-session destroy --quiet 2>/dev/null || true; }
trap cleanup EXIT
tmux-session create
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Flooding context with full output | Use `--last N` to limit lines |
| Polling in a loop for output | Use `tmux-read --grep PATTERN --timeout N` |
| Polling in a loop for exit | Use `tmux-wait --name NAME --timeout N` |
| Forgetting to destroy session | Always `tmux-session destroy` when done |
| Using special chars in names | Stick to alphanumeric and hyphens |
| Sending input to a dead pane | Check `tmux-list` status before `tmux-send` |
| Expecting precise timeouts | Timeouts are checked after each poll interval, so actual wait time may exceed `--timeout` by up to one `--poll` period. For precise timeouts, use `--poll 1` |
| Using bare `bash` as command | `tmux-run --name x -- bash` starts a non-interactive shell that may exit immediately. Use `bash -c '...'` or `bash -i` instead |
| Missing output from long commands | `tmux-read` captures 1000 lines by default. For commands producing more output, use `--history N` with a larger value, or `--last N` to get only recent lines |

## Troubleshooting

### "session does not exist"
Run `tmux-session create` before using other commands. Each workflow starts with session creation.

### "pane not found"
Check pane names with `tmux-list`. Names are case-sensitive and must match exactly.

### Output is truncated
Use `--history N` with a larger value (default 1000). For very long output, pipe through `wc -l` first to understand the scale.

### --dir appears to be ignored
The directory must exist. Non-existent directories now cause an error (previously tmux silently fell back to CWD).

### Process appears stuck
Use `tmux-list` to check if status is `running` or `exited(N)`. If running but unresponsive, try `tmux-send --name X --keys C-c`.

### tmux-read --grep never matches
- Check if the pattern has regex special chars - use `--grep-regex` for regex, or escape for fixed string
- Check if the output uses ANSI colors that interfere with matching
- Try `tmux-read --name X --last 50` to see actual output

## Agent Workflow Examples

### Parallel Code Analysis

```bash
tmux-session create
tmux-run --name lint -- eslint src/ --format json > /tmp/lint.json
tmux-run --name types -- tsc --noEmit 2>&1 > /tmp/types.txt
tmux-run --name tests -- npm test 2>&1 > /tmp/tests.txt

tmux-wait --all --timeout 300

# Collect results
cat /tmp/lint.json /tmp/types.txt /tmp/tests.txt
tmux-session destroy
```

### Long-Running Server with Health Check

```bash
tmux-session create
tmux-run --name server -- npm start

# Wait for server ready
tmux-read --name server --grep "Server listening" --timeout 60

# Run tests against server
tmux-run --name e2e -- npm run test:e2e
tmux-wait --name e2e --timeout 300

# Cleanup
tmux-send --name server --keys C-c
tmux-wait --name server --timeout 10
tmux-session destroy
```

### Spawning Claude Subagents

```bash
tmux-session create --prefix parallel-agents

# Dispatch independent analysis tasks
tmux-run --prefix parallel-agents --name analyze-api -- \
    claude -p "Analyze src/api for security issues" --output-file /tmp/api-analysis.md
tmux-run --prefix parallel-agents --name analyze-db -- \
    claude -p "Review database queries for N+1 problems" --output-file /tmp/db-analysis.md

# Wait for both
tmux-wait --prefix parallel-agents --all --timeout 600

# Aggregate results
cat /tmp/api-analysis.md /tmp/db-analysis.md

tmux-session destroy --prefix parallel-agents
```
