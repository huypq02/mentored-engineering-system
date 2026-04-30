---
name: state-file-resolver
description: Teaches agents how to reliably locate state files at the project root, regardless of whether the agent definition lives at .claude/agents/ (project scope) or ~/.claude/agents/ (user scope). Run before reading any state file.
---

# State File Resolver

## The problem this solves

Agent definition files may live at:
- `.claude/agents/mentor.md` (project scope)
- `~/.claude/agents/mentor.md` (user scope, shared across projects)

In both cases, Claude Code runs agents with the **working directory set to the project root** — the directory where the user launched Claude Code. Relative paths resolve from the project root, not from the agent file location.

But agents shouldn't blindly assume cwd is correct. This skill provides a deterministic path resolution strategy that works for every agent, regardless of which tools they have.

---

## Two strategies (pick the one your tools allow)

### Strategy A — Bash available (debugger, debugger-light, implementer, implementer-fast)

Use git for the most reliable resolution:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "Project root: $PROJECT_ROOT"
ls -1 "$PROJECT_ROOT"/agent_state.md "$PROJECT_ROOT"/patterns.md "$PROJECT_ROOT"/session_state.md 2>&1 | head -10
```

Then use the resolved path with the Read tool.

### Strategy B — No Bash (mentor, mentor-light, planner, researcher)

Use the `Glob` tool (which every agent has) to discover state files from cwd:

```
Glob: agent_state.md
Glob: patterns.md
Glob: session_state.md
```

Glob searches from the current working directory, which is the project root during agent execution. Each glob returns the path of the file (if present) or empty (if missing).

Then read using the path returned by Glob.

If Glob returns empty for `agent_state.md`, the file is missing — handle per "Missing files" section below.

---

## Reading state files (works for both strategies)

After resolving the path, use the **Read** tool with the path returned:

| Scenario | Resolution |
|---|---|
| Bash agent finds via git | `<PROJECT_ROOT>/agent_state.md` (absolute) |
| Bash agent in non-git dir | `<pwd>/agent_state.md` (absolute) |
| Non-Bash agent via Glob | Returned path |
| Fallback (any agent) | Bare filename `agent_state.md` works because cwd is project root |

**Prefer absolute paths.** Bare filenames work in practice but can fail silently if cwd shifts unexpectedly.

---

## Missing files — what to do

### `agent_state.md` missing

This file is the project contract — most agents need it for full context.

> "I don't see `agent_state.md` at the project root. This file holds your project's stack, conventions, and decisions — agents work better with it. You can create one from the template at `state/agent_state.md`, or I'll proceed without it and ask you about stack/conventions as needed."

For lightweight agents (mentor-light, debugger-light, implementer-fast): silently proceed without it. The cost of pestering on every small task isn't worth the benefit.

### `patterns.md` missing

This is fine for new projects.

> "No `patterns.md` found yet — that's normal early on. Skipping the meta-learning read."

### `session_state.md` missing

Always optional. Silently skip — only relevant for multi-day L work.

---

## Diagnostic if a Read fails

If you successfully resolved a path but the Read tool then errors on it:

1. (Bash agents) Run `pwd` and `ls -la agent_state.md patterns.md 2>&1` to inspect actual filesystem state
2. (Non-Bash agents) Run `Glob: **/agent_state.md` to search recursively in case it's in a subdirectory
3. Report findings to user rather than silently proceeding with no context:
   > "I resolved project root to `/path/X` but can't read `agent_state.md` there. Found these state files via search: [list]. Should I use one of them, or has the file been renamed?"

---

## Path resolution by install scenario

| Agent location | State file location | Working directory at runtime | Resolution works? |
|---|---|---|---|
| `.claude/agents/mentor.md` | project root | project root | ✓ |
| `~/.claude/agents/mentor.md` | project root | project root | ✓ |

In every supported scenario, **cwd is the project root during agent execution**. The agent file location does not affect this.

---

## Why explicit resolution matters

Without this skill, agents using bare filenames silently proceed with stale or missing context when something is unexpected. With this skill:

- Missing files surface clearly with helpful messages
- Path resolution works for all agent types (Bash and non-Bash)
- Debugging is straightforward when something does break
- Both project-scope and user-scope installs work identically
