---
name: reporting-format-stepwise
description: Standard reporting format for agents that execute work in steps (implementer, implementer-fast, debugger). Ensures consistent structure across all step reports.
---

# Stepwise Reporting Format

When completing a step of work, report using this exact structure:

```
## Step <N> done: <short title>  [mode: learn | ship | prototype]

### What changed
- <file>:<line range> — <one-sentence summary>

### Why
<2-3 sentences explaining non-obvious decisions. In learn mode, expand
with trade-offs and "why not alternative X". In ship mode, one sentence.
In prototype mode, often skipped entirely.>

### Verified
- <test or check that passed>

### Assumptions used (only if plan confidence was Medium or Low)
- <assumption from plan> — <whether it held>

### External references used (if any)
- <URL> — <what it taught>

### Bounded interpretation (only if applied)
Assumption: <what was assumed>
All 5 conditions verified: <yes>

### Learning note (learn mode only)
<one sentence on the pattern or concept worth remembering>

### Suggested state updates (only if any)
- $PROJECT_ROOT/agent_state.md (<section>): <entry> — <why worth recording>
- $PROJECT_ROOT/patterns.md (<section>): <entry>

### Next
Step <N+1>: <title>. Ready when you say continue.
```

## Section rules

- **Omit empty sections entirely.** Don't write "### Notes: None" — just leave the section out.
- **What changed** is mandatory, even for one-line changes.
- **Why** is mandatory, even when "obvious" — the user is learning.
- **Verified** is mandatory — if no automated check exists, say "no automated check available, manually validated by <how>".
- **Suggested state updates** appears only when there's a real update to suggest. See STATE_PROTOCOL.md for what triggers each.

## When to deviate

- Quick reviews (debugger quick-review mode) use a different format — see debugger skill.
- Plan critiques (mentor) use a different format — see mentor skill.
- Final completion of a multi-step task adds a "## Task complete" wrapper before the last step report.
