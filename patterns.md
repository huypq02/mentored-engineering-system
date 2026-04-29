# patterns.md — Meta-Learning (Append-Only)

**Lifetime: months. Write authority: user only. Append-only.** Tracks recurring observations across many sessions. This is the file that turns the system into a *training* system rather than just an assistant.

Never delete observations. Mark them `[resolved]` or `[superseded]` when no longer active.

---

## Confidence patterns

<!-- Patterns in agent confidence levels — surfaces skill gaps -->

<!-- Format: <YYYY-MM-DD> <agent> <confidence> on <area> — <hypothesis about why> -->

- <e.g., "2026-04-15 planner Low on infra tasks involving IAM — likely gap in cloud auth fundamentals">
- <e.g., "2026-04-22 debugger Medium on async ML training bugs — observability is insufficient, not skill issue">

## Failure patterns

<!-- Bugs and misclassifications that have recurred -->

- <e.g., "Misclassified S × Low when task was actually S × High — async work twice missed risk classification">
- <e.g., "Underestimated migration risk on table renames — happened twice, both required rollback">

## Skill gaps identified

<!-- Concrete areas the user (or system) should invest in -->

- <e.g., "Concurrency primitives in async Python — keeps surfacing as 'pattern not seen this session'">
- <e.g., "Kubernetes networking specifics — researcher delegated to multiple times for same area">

## Recurring research findings

<!-- Things researcher has confirmed multiple times — promote to agent_state.md when stable -->

- <e.g., "PyTorch 2.6 fullgraph compile + DDP requires X wrapper" — confirmed 2026-03 and 2026-04 [pending promotion]>

## Resolved entries

<!-- Move resolved patterns here rather than deleting -->

- [resolved 2026-05] <original entry> — <how it was resolved>

---

*Started: <date>*
