<!-- Badges (replace URLs when repo is public) -->
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Hook-blueviolet)](#)

English | [中文](README_CN.md)

# cc-swarm

**Architect Mode for Claude Code — Main agent plans, subagents execute.**

cc-swarm turns the Claude Code main agent into a pure **architect**: it only plans, coordinates, and reviews. All file editing, code development, documentation writing, and code review are delegated to **subagents**. Enforcement is done via [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) that intercept tool calls at runtime, and agents communicate through a shared **file-system protocol** (markdown files under `cc-swarm/<session_id>/`).

## How It Works

| Component | Role |
|---|---|
| **SessionStart Hook** | Creates the `cc-swarm/<session_id>/` communication directory and persists `session_id` as an environment variable for the session. |
| **PreToolUse Hook** | Intercepts `Write` / `Edit` calls from the main agent. Uses `agent_id` to distinguish main agent from subagents — only subagents are allowed to write files. |
| **CLAUDE.md** | Global instructions that define the architect role, delegation workflow, and communication protocol. |

## Quick Start

```bash
git clone <repo-url>
cd cc-swarm
./run.sh              # English (default)
./run.sh --lang cn    # 中文
```

Restart Claude Code after installation for changes to take effect.

## File Communication Protocol

All task files live under `cc-swarm/<session_id>/`:

| File | Purpose |
|---|---|
| `STATUS.md` | Current session status and progress overview |
| `PLAN.md` | Architect's high-level plan for the session |
| `TODO.md` | Task queue with priorities and assignments |
| `task-NNN-*.md` | Task specification dispatched to a subagent |
| `output-NNN-*.md` | Subagent's deliverable / result |
| `review-NNN-*.md` | Architect's review feedback on a task output |

## Workflow

```
Main Agent (Architect)          Subagent
        |                           |
        |-- write task-NNN-*.md --> |
        |                      [executes task]
        |                           |
        | <-- write output-NNN-*.md |
        |                           |
   [review output]                  |
        |-- write review-NNN-*.md ->|
        |                      [revise if needed]
        ...
```

1. Architect analyzes the user request and creates `PLAN.md` + `TODO.md`.
2. Architect writes a `task-NNN-*.md` file and spawns a subagent.
3. Subagent reads the task, executes it, and writes `output-NNN-*.md`.
4. Architect reviews the output and writes `review-NNN-*.md` (approve / request changes).
5. Repeat until all tasks are complete.

## Uninstall

```bash
./uninstall.sh
```

## License

[MIT](LICENSE)
