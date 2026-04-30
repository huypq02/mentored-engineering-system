# session_state.md — Cross-Session Bridge (Optional)

**Use only when work spans multiple sessions on the same feature.** For single-session XS/S/M tasks, native auto-memory + conversation context is sufficient. This file is the bridge for L tasks or multi-day M tasks resumed via named sessions.

When a feature is complete, archive this file (rename to `session_state.<feature-slug>.archive.md`) or clear it.

---

## Active feature

**Slug**: <feature-name> (matches `claude -c -r <slug>` for resuming)
**Triage**: <Size × Risk>
**Status**: <planning | implementing | debugging | reviewing | done>
**Started**: <date>

## Active plan

<!-- Copy from planner once approved by mentor. Keep step status fresh. -->

**Plan confidence (from planner)**: <High | Medium | Low>

- [ ] Step 1: <title>
- [ ] Step 2: <title>
- [ ] Step 3: <title>

## In-flight decisions

<!-- Decisions made during this feature, not yet promoted to $PROJECT_ROOT/agent_state.md -->

- <decision> — made by <agent or user> on <date>

## Bounded interpretations active

<!-- When implementer-fast proceeds with a marked assumption, log it here -->

- <YYYY-MM-DD HH:MM> file.py:line — assumed: <X> — reversible because: <reason>

## Open loops

<!-- Things deferred but not forgotten -->

-

## Notes from sessions

<!-- Anything worth carrying forward not yet structured -->

-

---

_Last touched: <date>_
