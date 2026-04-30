# STATE_PROTOCOL.md — Memory Contract (v6)

This document defines how agents interact with memory. v6 distinguishes between **native auto-memory** (handled by Claude Code) and **deliberate memory** (our `$PROJECT_ROOT/agent_state.md` and `$PROJECT_ROOT/patterns.md`). They have different jobs and don't overlap.

---

## Two memory layers

### Layer 1: Native auto-memory (Claude Code, automatic)

Claude Code 2.1.59+ has built-in auto-memory. Claude itself decides what's worth remembering across sessions and writes notes to a managed memory folder. Toggle via `/memory` in a session.

**This handles:**

- Build commands and how to run things
- Debugging insights from past sessions
- Code style observations Claude noticed
- Workflow habits and preferences

**You do not write to this.** Claude writes it. You can read and edit it via `/memory` if you want, but the value is that it accumulates without effort.

**Our agents do NOT read or manage this.** Native auto-memory is loaded automatically into every session by Claude Code itself, before our agents even run. They benefit from it transparently.

### Layer 2: Deliberate memory (you write, agents read)

Two files in your repo root:

| File                           | Purpose                                                                                                 | Lifetime | Append-only?                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------- |
| `$PROJECT_ROOT/agent_state.md` | The deliberate contract — pinned versions, conventions, validated assumptions, decisions, anti-patterns | Months   | No                                           |
| `$PROJECT_ROOT/patterns.md`    | Meta-learning — confidence patterns, failure patterns, skill gaps over time                             | Months   | Yes (mark resolved/superseded, don't delete) |

Optional third file for multi-session work:

| File                             | Purpose                                       | When to use                                                             |
| -------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------- |
| `$PROJECT_ROOT/session_state.md` | Cross-session bridge for one specific feature | Only for L tasks or multi-day M tasks resumed via `claude -c -r <slug>` |

---

## Why we separate native and deliberate

Native auto-memory is **opportunistic** — Claude saves what it notices. Deliberate memory is **intentional** — you record what you want every agent to follow.

Auto-memory might note "uses pytest in tests/ folder." Deliberate memory says "Don't use mp.spawn — caused issues in March 2026, use torchrun." The first is observation; the second is law.

Both have their place. Don't try to migrate one into the other.

---

## Read protocol (for our deliberate memory)

### When agents read

| Agent              | $PROJECT_ROOT/agent_state.md         | $PROJECT_ROOT/patterns.md                | $PROJECT_ROOT/session_state.md (if present) |
| ------------------ | ------------------------------------ | ---------------------------------------- | ------------------------------------------- |
| `mentor`           | Every M/L turn                       | Every M/L turn                           | Every turn if file exists                   |
| `mentor-light`     | First turn only (cache)              | Skip                                     | Every turn if file exists                   |
| `planner`          | Every invocation                     | Every invocation                         | Every invocation if file exists             |
| `implementer`      | First turn only                      | Skip                                     | Every turn if file exists                   |
| `implementer-fast` | Skip (too small to matter)           | Skip                                     | First turn only if file exists              |
| `debugger`         | Every invocation                     | Every invocation                         | Every invocation if file exists             |
| `debugger-light`   | First turn only (Anti-patterns only) | Skip                                     | Skip                                        |
| `researcher`       | First turn (Stack section only)      | First turn (Recurring research findings) | Skip                                        |

**"First turn only"** means: read once when first invoked in a session, then rely on conversation context. Don't re-read the same file every turn.

### What to extract per agent

Each agent cares about specific sections. Don't dump the whole file into reasoning.

| Agent              | Sections used                                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `mentor`           | Conventions, Decisions, Open questions, Anti-patterns; all of $PROJECT_ROOT/patterns.md                                                |
| `mentor-light`     | Conventions, Anti-patterns                                                                                                             |
| `planner`          | Stack, Conventions, Validated assumptions, Known constraints, Decisions, Anti-patterns; in $PROJECT_ROOT/patterns.md: Failure patterns |
| `implementer`      | Stack, Conventions, Anti-patterns                                                                                                      |
| `implementer-fast` | (skip)                                                                                                                                 |
| `debugger`         | Validated assumptions (any wrong now?), Anti-patterns (have we hit this before?), Failure patterns                                     |
| `debugger-light`   | Anti-patterns                                                                                                                          |
| `researcher`       | Stack (scope queries to right versions); Recurring research findings (already answered?)                                               |

### Conflict resolution (CRITICAL)

If a state file contradicts current code/codebase → **code wins**, state is stale, agent flags it explicitly:

> "$PROJECT_ROOT/agent_state.md says PyTorch 2.6 but `requirements.txt` shows 2.7. Treating 2.7 as truth. Suggest user update $PROJECT_ROOT/agent_state.md."

If state file contradicts something said in this conversation → state file wins (state was deliberately recorded; conversation may be hallucinated).

---

## Write protocol

Agents do **not** write to state files directly. Two exceptions:

1. **The `debugger-completion-log.sh` hook** may append a single line to `$PROJECT_ROOT/patterns.md` when debugger finishes a Medium/High-confidence fix. This is automated and bounded.
2. **The user.** That's it.

Agents emit structured **suggestions** in their output. The user copies what they want.

### Suggestion format (consistent across all agents)

```
## Suggested state updates

### To $PROJECT_ROOT/agent_state.md
- Section: <Validated assumptions | Known constraints | Decisions made | Anti-patterns>
- Entry: <one-line addition>
- Reason: <why this is worth recording>

### To $PROJECT_ROOT/patterns.md
- Section: <Confidence patterns | Failure patterns | Skill gaps>
- Entry: <one-line observation>
- Evidence: <what triggered this observation>
```

Only emit sections that have actual updates. Empty sections = omit the whole "Suggested state updates" block.

### When to suggest updates (specific triggers)

**Mentor** suggests update when:

- Teaching reveals a new convention or principle
- Plan critique surfaces a hidden assumption that should be made explicit
- User confirms a decision that wasn't previously recorded

**Planner** suggests update when:

- A new constraint is discovered while mapping the territory
- A library version or service limit was verified
- An assumption is explicitly validated by reading the code

**Implementer** suggests update when:

- An assumption from the plan held up under execution (validates it)
- A non-obvious pattern in the codebase is worth recording

**Debugger** suggests update when:

- Root cause reveals a previously-unknown constraint or invariant
- A bug pattern is recurring (failure pattern entry)
- A previously-validated assumption turned out to be wrong (correction)

**Researcher** suggests update when:

- A finding has long-term value (current best practice, version-specific behavior)
- The same question would otherwise be researched again

---

## Stop conditions

Each tier has explicit exit criteria. No "one more review" loops.

| Triage        | Stop when                                                                 |
| ------------- | ------------------------------------------------------------------------- |
| **XS × Low**  | implementer-fast completes                                                |
| **XS × High** | debugger quick-review = no Blockers                                       |
| **S × Low**   | implementer-fast + (optional) debugger-light = no Blockers                |
| **S × High**  | debugger Confidence ≥ Medium on fixes, or no issues found                 |
| **M × Low**   | implementer + debugger reviews = no Blockers                              |
| **M × High**  | All per-step reviews clear AND debugger Confidence ≥ Medium on bugs fixed |
| **L × any**   | Full flow + checkpoints answered + no blocking Open questions             |

If exit criterion not met, the gap-detecting agent states what's missing rather than starting another loop.

---

## Hygiene rules

- Each state file should stay under 200 lines. Past that → archive old sections to `<file>.archive.md`.
- `$PROJECT_ROOT/session_state.md` should be archived when its feature is complete.
- `$PROJECT_ROOT/patterns.md` is append-only — never delete observations, mark them `[resolved]` or `[superseded]`.
- Agents never read state files larger than 500 lines (defensive cap; flag the user if hit).

---

## Multi-session pattern (named sessions)

For L tasks and multi-day M tasks, use Claude Code's named sessions:

```bash
# Start a feature
claude -c -r feature/auth-retries

# Resume same session next day
claude -c -r feature/auth-retries
```

When you resume a named session that has a `$PROJECT_ROOT/session_state.md`, mentor reads it on first turn to restore context. This is the only case where `$PROJECT_ROOT/session_state.md` adds value over native auto-memory.
