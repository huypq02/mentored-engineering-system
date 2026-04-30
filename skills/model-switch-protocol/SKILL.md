---
name: model-switch-protocol
description: Standard protocol for agents to request a model switch from the user. Agents pause and ask; user decides and switches. Used when an agent realizes mid-task that a different model tier would serve better.
---

# Model Switch Protocol — Human-in-the-Loop Router

This system uses **human-in-the-loop model routing**: agents don't switch models silently. They pause, explain why a different tier would help, and wait for the user to decide and act.

This keeps the user in control of cost, makes the routing visible (you learn when tasks need more or less model), and prevents runaway escalations.

## When to request a switch

Agents request a model switch in two directions:

### Upgrade requests (light → heavy)

Trigger when the current task exceeds the model tier mid-execution:
- Reasoning depth required is greater than expected
- Multiple Open questions are blocking progress
- Confidence keeps coming out Medium/Low after multiple attempts
- The work crosses into architectural / cross-cutting territory
- A bug needs extensive prior-art research or design rethinking

### Downgrade requests (heavy → light)

Trigger when the task turns out to be smaller than triaged:
- Remaining work is pure plumbing / glue / mechanical
- The original concern dissolved (e.g., risk turned out not to apply)
- A "bug" turned out to be a typo or one-line fix
- Research question turned out to be a single-fact lookup

Downgrade requests are **rarer than upgrades** because the system errs toward over-provisioning. But when downgrade is right, it saves cost on the remainder of the work.

## Two switch patterns

### Pattern A — Switch agent variant (preferred when applicable)

Used when there's a heavy/light pair available (e.g., `mentor` ↔ `mentor-light`, `implementer` ↔ `implementer-fast`, `debugger` ↔ `debugger-light`).

Request format:
> "This is going beyond S × Low. Please re-invoke this work with `<heavier agent name>` to continue. I've logged what I found so far below so the heavier agent doesn't have to re-discover it."

### Pattern B — Switch main session model

Used when the work is happening in the main Claude Code session (no subagent), or when you want to upgrade the entire conversation rather than just spawn a different subagent.

Request format:
> "We're entering architectural territory that benefits from deeper reasoning. Please switch your main session to Opus before we continue:
>
> ```
> /model opus
> ```
>
> Then say 'continue' and I'll resume from where we paused."

## Mandatory stop after request

**After requesting a switch, you stop.** No more reasoning, no more code, no more analysis. Wait for the user's next message.

When the user replies with "continue" (or equivalent), resume from where you paused — but check that the switch actually happened. If they continued without switching, ask once:

> "It looks like the switch may not have happened. I'm still on `<current model>`. Did you intend to continue at this tier, or shall I wait for the switch?"

Trust their answer. If they confirm, proceed at the current tier and accept the trade-off.

## Required output format for switch requests

```
## Model switch request

**Direction**: Upgrade | Downgrade
**Pattern**: A (agent variant) | B (main session model)
**Current tier**: <Haiku | Sonnet | Opus>
**Recommended tier**: <Haiku | Sonnet | Opus>

### Why
<2-3 sentences explaining what triggered the request — what specifically about
this task makes the current tier wrong>

### Action for you (user)
<Pattern A>: "Re-invoke this work as `<agent name>` to continue."
<Pattern B>: "Run `/model <opus|sonnet|haiku>` then say 'continue'."

### What I've established so far (for handoff)
- <bullet point of work-in-progress so the next tier doesn't restart>
- <bullet>

### Optional: bypass
If you want me to continue at the current tier despite this recommendation,
say "continue at current tier" and I'll proceed with the trade-off acknowledged.
```

## When NOT to request a switch

- Normal work going as expected — even if it's slightly harder than triage suggested
- One Confidence: Medium output (single signal isn't enough)
- User preference for cost savings overriding the recommendation (their call to make)
- A switch that would interrupt a user-flagged "fast iteration" or deadline situation

The bar for asking should be roughly: **"would I be doing materially worse work at the current tier than at the recommended one?"** Not "would the recommended tier be marginally nicer."

## Bypass signals from the user

Users can explicitly bypass switch requests:

- **`stay light`** / **`stay current tier`** — proceed at current model regardless
- **`force opus`** / **`force sonnet`** / **`force haiku`** — apply the named tier even if agent doesn't recommend it
- **`no switches this session`** — disable switch requests entirely for this conversation

Respect these signals. The user is in control of routing; agents only advise.
