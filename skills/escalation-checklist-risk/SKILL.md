---
name: escalation-checklist-risk
description: Deterministic escalation triggers for lightweight agents (mentor-light, implementer-fast, debugger-light). Run this checklist BEFORE starting work — any checked box means escalate to the heavy variant.
---

# Risk Escalation Checklist

Lightweight agents (`mentor-light`, `implementer-fast`, `debugger-light`) MUST run this checklist before doing any work. **If ANY box is checked, escalate to the heavy variant. No exceptions, no partial handling.**

## Universal triggers (apply to all light agents)

```
[ ] Multiple files involved (more than one file is being read or written)
[ ] State persists across multiple steps (module-level variables, session, cache)
[ ] Concurrency, async, threading, or shared resources
[ ] Security-sensitive surface (auth, secrets, validation, permissions, injection)
[ ] Hard-to-undo data mutation (migrations, deletes, financial calculations)
[ ] Production blast radius (touches prod infra, prod data)
[ ] ML reproducibility-critical (training, eval, seed-sensitive)
[ ] User flagged any concern about risk or correctness
[ ] An anti-pattern from $PROJECT_ROOT/agent_state.md applies to this area
[ ] A failure pattern from $PROJECT_ROOT/patterns.md shows recurring issues here
```

## Mentor-light specific triggers

Add these on top of universal:

```
[ ] User asked a deep "why" question that needs full Socratic teaching
[ ] You are unsure about correctness of the recommended approach
[ ] Spec you would write contains ambiguous phrases ("should probably", "if appropriate")
```

## Implementer-fast specific triggers

Add these on top of universal:

```
[ ] Spec contains interpretive language ("should probably", "if needed", "as appropriate")
[ ] Spec doesn't tell me explicitly what to do for an edge case I can think of
[ ] Non-obvious design decision the spec doesn't cover
[ ] New dependency required
[ ] Existing code more complex than the spec suggests
```

## Debugger-light specific triggers

Add these on top of universal:

```
[ ] Failure is intermittent or timing-dependent
[ ] Symptom suggests race condition / concurrency / async
[ ] Silent data corruption suspected (no error, just wrong output)
[ ] Failure spans multiple files or services
[ ] Stack trace involves more than one library boundary
[ ] First two hypotheses already eliminated
[ ] Unsure even what to hypothesize → would need exploratory probing
[ ] Bug touches code that isn't obviously the cause (action-at-a-distance)
```

## Escalation message format

When escalating, use:

> "Escalating to full `<agent name>` (Opus) — flagged: [specific item from checklist]. So far: [brief summary of what was found while scanning]."

Always include the summary so the heavy variant doesn't have to re-discover what you already know.

## Why this exists

Subjective escalation drifts. Different runs of the same agent will judge "is this risky?" differently, and over weeks you get inconsistent behavior. A checklist removes judgment: if a box is checked, escalate. Period.

False-positive escalations are cheap (you get a slightly slower, more thorough response than necessary). Missed escalations are expensive (silent wrong behavior, production incidents). The asymmetry justifies erring toward escalation.
