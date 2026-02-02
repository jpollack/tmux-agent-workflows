---
name: tmux-agent-workflows
description: Use when running concurrent commands, background processes, or parallel subagents. Use when needing to monitor, interact with, or wait for long-running tasks. Use when orchestrating multi-process workflows from a single session.
---

# Tmux Agent Workflows

Run concurrent commands, monitor output, wait for completion, and interact with processes via tmux.

## Quick Reference

| Task | Command |
|------|---------|
| Start session | `tmux-session create [--prefix NAME]` |
| Run command | `tmux-run --name build -- make -j4` |
| Run in directory | `tmux-run --name build --dir /project -- make` |
| Restart dead pane | `tmux-run --name build --replace -- make -j4` |
| Read output | `tmux-read --name build --last 20` |
| Read more history | `tmux-read --name build --history 5000` |
| Wait for pattern | `tmux-read --name build --grep "DONE" --timeout 60 --last 20` |
| Wait for regex | `tmux-read --name build --grep "OK\|DONE" --grep-regex --timeout 60` |
| Wait for exit | `tmux-wait --name build --timeout 300 --poll 5` |
| Send input | `tmux-send --name repl --text "quit" --keys Enter` |
| Send Ctrl-C | `tmux-send --name server --keys C-c` |
| List panes | `tmux-list` |
| List all sessions | `tmux-session list --all` |
| Kill pane | `tmux-kill --name build` |
| End session | `tmux-session destroy` |

All scripts support `--prefix NAME` (default: `agent`), `--quiet`/`-q`, and `--help`.

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

## Spawning Subagents

Run Claude in isolated tmux panes for parallel subtasks:

```bash
tmux-run --name subtask1 -- claude -p "do something" --output-file /tmp/result1.txt
tmux-run --name subtask2 -- claude -p "do other thing" --output-file /tmp/result2.txt

# Wait for both
tmux-wait --name subtask1 --timeout 600
tmux-wait --name subtask2 --timeout 600

# Read results from output files
```

## Naming Rules

Names and prefixes must **not** contain ':', '.', '!', '"', '\\', or whitespace — tmux treats these as target separators, quotes and backslashes break JSON output, and whitespace breaks field parsing. Names must be unique within a session.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Flooding context with full output | Use `--last N` to limit lines |
| Polling in a loop for output | Use `tmux-read --grep PATTERN --timeout N` |
| Polling in a loop for exit | Use `tmux-wait --name NAME --timeout N` |
| Forgetting to destroy session | Always `tmux-session destroy` when done |
| Using special chars in names | Stick to alphanumeric and hyphens |
| Sending input to a dead pane | Check `tmux-list` status before `tmux-send` |
