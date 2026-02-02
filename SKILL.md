---
name: tmux-agent-workflows
description: Use when running concurrent commands, long-running processes, or multiple background tasks. Use when needing to monitor output from several processes, interact with running programs, or spawn subagents in isolated sessions.
---

# Tmux Agent Workflows

Run concurrent commands, monitor output, and interact with processes via tmux.

## Setup

Scripts live in `bin/` of this project. Add to PATH or use full paths.

## Quick Reference

| Task | Command |
|------|---------|
| Start session | `tmux-session create` |
| Run command | `tmux-run --name build -- make -j4` |
| Read output | `tmux-read --name build --last 20` |
| Send input | `tmux-send --name repl --text "print(1)" --keys Enter` |
| List panes | `tmux-list` |
| Kill pane | `tmux-kill --name build` |
| End session | `tmux-session destroy` |

## Workflow

1. `tmux-session create` — once per task
2. `tmux-run --name NAME -- COMMAND` — for each concurrent process
3. `tmux-read --name NAME --last N` — check output (use `--last` to limit context)
4. `tmux-send --name NAME --text/--keys` — interact when needed
5. `tmux-list` — check what's running
6. `tmux-kill --name NAME` — stop processes you're done with
7. `tmux-session destroy` — cleanup when finished

## Tips

- Use `--last N` with tmux-read to avoid flooding context with output
- Use `--prefix` to isolate different agent tasks from each other
- All scripts support `--help` for full usage
- Pane names must be unique within a session
- Send `C-c` via `tmux-send --name NAME --keys C-c` to interrupt a process

## Spawning Subagents

Run Claude in a tmux pane for isolated subtasks:

```bash
tmux-run --name subtask1 -- claude -p "do something" --output-file /tmp/result1.txt
```

Check completion with `tmux-list` (look for "exited(0)"), read result from file.
