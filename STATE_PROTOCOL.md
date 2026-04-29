# STATE_PROTOCOL.md — Shared State Contract

This document defines exactly how agents interact with the three state files. **Every agent reads this protocol once and follows it consistently.** Without a strict protocol, shared state degrades into noise.

---

## Three state files (separated by lifetime and write semantics)

| File | Lifetime | Purpose | Write authority |
|---|---|---|---|
| `agent_state.md` | Months | Project-stable context (stack, conventions, validated assumptions, decisions) | User only — agents *suggest* additions |
| `session_state.md` | Hours to days | Active task state (current work, in-flight decisions, open loops) | Agents may *propose* writes; user confirms |
| `patterns.md` | Months, append-only | Meta-learning (confidence patterns, failure patterns, skill gaps) | User only — agents *suggest* entries |

All three live at the **repo root**. If a file is missing, agents proceed without it (don't error or block).

---

## Read protocol

### When to read

| Agent | agent_state.md | session_state.md | patterns.md |
|---|---|---|---|
| `mentor` | Every M/L turn | Every turn | Every M/L turn |
| `mentor-light` | First turn only (cache for session) | Every turn | Skip |
| `planner` | Every invocation | Every invocation | Every invocation |
| `implementer` | First turn only | Every turn | Skip |
| `implementer-fast` | Skip (too small to matter) | First turn only | Skip |
| `debugger` | Every invocation | Every invocation | Every invocation |
| `debugger-light` | First turn only | Every turn | Skip |
| `researcher` | First turn only | Skip | First turn only |

**"First turn only"** means: read once when first invoked in a session, then rely on conversation context for the rest. Don't re-read the same file every turn — wastes context budget.

### What to extract (per agent)

Each agent cares about specific sections. Don't dump the whole file into reasoning.

| Agent | Sections that matter |
|---|---|
| `mentor` | Conventions, Decisions, Open questions, Anti-patterns; **all** of patterns.md |
| `mentor-light` | Conventions, Anti-patterns |
| `planner` | Stack, Conventions, Validated assumptions, Known constraints, Decisions, Anti-patterns; from session_state.md: current task, prior plan if any |
| `implementer` | Stack, Conventions, Anti-patterns; from session_state.md: active plan, in-flight assumptions |
| `implementer-fast` | Conventions only (Stack already obvious from filenames usually) |
| `debugger` | Validated assumptions (to check if any was wrong), Anti-patterns (have we hit this before?), Failure patterns from patterns.md |
| `debugger-light` | Anti-patterns |
| `researcher` | Stack (to scope queries), prior research from patterns.md if any |

### Conflict resolution (CRITICAL)

If state file contradicts current code/codebase → **code wins**, state is stale, flag it explicitly:

> "agent_state.md says PyTorch 2.6 but `requirements.txt` shows 2.7. Treating 2.7 as truth. **Suggest user update agent_state.md.**"

Never proceed silently when state and reality disagree. The flag itself is part of the value.

If state file contradicts something a previous agent said in the same conversation → state file wins (because conversation-level claims may be hallucinated; state file was deliberately recorded).

---

## Write protocol

Agents do **not** write to state files directly. They emit structured suggestions in their output, which the user copies if they choose.

### Suggestion format (consistent across all agents)

```
## Suggested state updates

### To agent_state.md
- Section: <Validated assumptions | Known constraints | Decisions made | Anti-patterns>
- Entry: <one-line addition>
- Reason: <why this is worth recording>

### To session_state.md
- Section: <Active task | In-flight decisions | Open loops>
- Entry: <one-line addition>

### To patterns.md
- Section: <Confidence patterns | Failure patterns | Skill gaps>
- Entry: <one-line observation>
- Evidence: <what triggered this observation>
```

Only emit sections that have actual updates. Empty sections = omit.

### When to suggest updates (specific triggers)

This is where v4 was weak — "if relevant" is too soft. Each agent has explicit triggers:

**Mentor** suggests update when:
- A teaching moment reveals a new convention or principle
- Plan critique surfaces a hidden assumption that should be made explicit
- User confirms a decision that wasn't previously recorded

**Planner** suggests update when:
- A new constraint is discovered while mapping the territory
- A library version or service limit was verified — record so it isn't re-verified
- An assumption is explicitly validated by reading the code

**Implementer** suggests update when:
- An assumption from the plan held up under execution (validates it)
- A pattern in the codebase is non-obvious and worth recording

**Debugger** suggests update when:
- Root cause reveals a previously-unknown constraint or invariant
- The bug pattern is one the system should remember (failure pattern)
- An assumption recorded in agent_state.md turned out to be wrong (correction)

**Researcher** suggests update when:
- A finding has long-term value (current best practice, version-specific behavior)
- The same question would otherwise be researched again

---

## Stop conditions (when does work end?)

Each tier has explicit exit criteria. No "one more review" loops.

| Triage | Stop condition |
|---|---|
| **XS × Low** | After `implementer-fast` completes. No review unless user asks. |
| **XS × High** | After `debugger` quick-review returns no Blockers. |
| **S × Low** | After `implementer-fast` completes + `debugger-light` quick-review (if invoked) returns no Blockers. |
| **S × High** | After `debugger` returns Confidence ≥ Medium on any fixes, or no issues found in review. |
| **M × Low** | After `implementer` completes plan + `debugger` quick-reviews show no Blockers. |
| **M × High** | After `debugger` per-step reviews all clear AND `debugger` confidence ≥ Medium on any bugs fixed. |
| **L × any** | After full flow completes AND mentor confirms checkpoints answered AND no Open questions remain blocking. |

If an exit criterion isn't met, the agent that detected the gap states what's missing rather than starting another loop.

---

## State hygiene rules

- Each state file should stay under 200 lines. Grows past that → archive old sections.
- `session_state.md` should be cleared or archived when a session ends.
- `patterns.md` is append-only — never delete observations, but mark them resolved/superseded.
- Agents never read state files larger than 500 lines (defensive cap; flag the user if hit).
