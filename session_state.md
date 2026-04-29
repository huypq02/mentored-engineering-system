# session_state.md — Active Session State

**Lifetime: hours to days. Write authority: agents propose, user confirms.** Captures in-flight work so agents in later turns don't lose context.

Clear or archive when the session ends.

---

## Active task

<!-- What we're currently working on. One paragraph. -->

**Triage:** <Size × Risk> — <set by mentor at task start>
**Status:** <planning | implementing | debugging | reviewing | done>

## Active plan (if any)

<!-- Copied from planner output once approved by mentor. Steps marked [done] / [in-progress] / [pending] -->

- [ ] Step 1: <title>
- [ ] Step 2: <title>
- [ ] Step 3: <title>

**Plan confidence (from planner):** <High | Medium | Low>

## In-flight decisions

<!-- Decisions made during this task that aren't yet promoted to agent_state.md -->

- <decision> — made by <agent or user> at <step N>

## Bounded interpretations active

<!-- When implementer-fast proceeds with a marked assumption, log it here -->

- <YYYY-MM-DD HH:MM> file.py — assumed: <X> — reversible because: <reason>

## Open loops

<!-- Things deferred but not forgotten -->

- <e.g., "Add docstrings after step 4 lands">
- <e.g., "Confirm with user whether to pin numpy version">

## Notes from this session

<!-- Anything worth carrying forward but not yet structured -->

-

---

*Session started: <date>*
