# Mentored Engineering System for Claude Code (v5)

A multi-agent setup for engineers growing into senior AI/ML + DevOps roles. Learning-first, not automation-first. v5 adds **proper shared memory**, **lazy entry**, **fast-plan mode**, **bounded interpretation**, **exploratory debug**, and **explicit stop conditions**.

## What's new in v5

v4 had the right architecture but its shared-memory implementation was shallow. v5 fixes that and addresses six other real-world friction points your testing surfaced:

1. **Three-layer state system** (`agent_state.md`, `session_state.md`, `patterns.md`) governed by `STATE_PROTOCOL.md` — explicit read rules per agent, explicit write triggers, conflict resolution, hygiene rules. Replaces v4's vague single-file state.
2. **Lazy entry mode** — direct coding requests get fast-routed with retroactive triage announcement. Keeps flow natural without losing structure.
3. **Confidence memory via patterns.md** — recurring confidence levels surface skill gaps over time. Confidence becomes a learning signal, not just routing.
4. **Fast-plan mode** — `rough plan` signal makes planner emit compressed plans (3-5 steps) for low-risk M tasks. Reduces drag for users who know the territory. Forbidden for High-risk tasks.
5. **Bounded interpretation** for `implementer-fast` — proceed with marked assumption ONLY when 5 strict conditions all hold (local scope, no business-logic effect, immediately observable, <5 line revert, no data mutation). Otherwise escalate.
6. **Exploratory debug mode** for `debugger` — probe-first flow for messy bugs that don't yet support clean hypotheses. Returns to disciplined hypothesis testing once observation is sufficient.
7. **Explicit stop conditions per tier** — defined in STATE_PROTOCOL.md. Prevents "one more review" loops.

---

## File inventory

### Agents (8 files, drop in `.claude/agents/`)

| Agent | Role | Model |
|---|---|---|
| `mentor.md` | Triage Size×Risk, teach, critique plans, lazy entry | Opus |
| `mentor-light.md` | Compressed teaching for plain S × Low | Sonnet |
| `planner.md` | Plans M/L (read-only), supports fast-plan mode | Opus |
| `implementer.md` | Executes plans for M/L (learn/ship modes) | Sonnet |
| `implementer-fast.md` | XS/S × Low execution, prototype mode, bounded interpretation | Haiku |
| `debugger.md` | Hypothesis-driven + exploratory debug, reviews | Opus |
| `debugger-light.md` | Compressed S × Low debug + quick reviews | Sonnet |
| `researcher.md` | Multi-source research (2+ search threshold) | Opus |

### State files (4 files, drop in repo root)

| File | Purpose | Lifetime | Write authority |
|---|---|---|---|
| `STATE_PROTOCOL.md` | The read/write contract — every agent follows it | Permanent reference | Don't edit |
| `agent_state.md` | Project-stable context (stack, conventions, decisions) | Months | User only |
| `session_state.md` | Active task state | Hours-days | Agents propose, user confirms |
| `patterns.md` | Meta-learning (confidence patterns, failure patterns, skill gaps) | Months, append-only | User only |

---

## How shared state works (the v4 problem fixed)

In v4, agents were told "read agent_state.md if present" and "suggest additions if relevant." That was too vague — agents would re-read the whole file every turn (waste tokens), miss relevant sections (waste signal), or forget to suggest updates (waste learning).

In v5, `STATE_PROTOCOL.md` defines exactly:

**WHEN each agent reads each file:**
- mentor reads all 3 files every M/L turn
- mentor-light reads only `agent_state.md` (Conventions + Anti-patterns) once per session
- implementer-fast skips agent_state.md entirely (too small to matter)
- debugger reads all 3 every invocation
- etc. (see STATE_PROTOCOL.md for full table)

**WHICH sections matter to which agent:**
- planner cares about: Stack, Conventions, Validated assumptions, Known constraints, Decisions, Anti-patterns
- debugger cares about: Validated assumptions (any wrong now?), Anti-patterns (have we hit this before?), Failure patterns
- mentor-light cares about: Conventions, Anti-patterns only

**HOW conflicts resolve:**
- State contradicts code → code wins, agent flags staleness explicitly
- State contradicts conversation → state wins (state was deliberately recorded; conversation may be hallucinated)

**WHEN to suggest updates** — each agent has explicit triggers, not "if relevant":
- Planner suggests update when an external fact is verified (so it doesn't get re-verified)
- Debugger suggests update when root cause reveals a new constraint, or when a bug pattern recurs
- Researcher suggests update when finding has long-term value
- etc.

**HOW updates are formatted** — consistent structured suggestion that user copies:

```
## Suggested state updates

### To agent_state.md
- Section: Validated assumptions
- Entry: "Production GPUs are A100-40GB" — verified by checking deployment config
- Reason: Avoids re-verification on future infra tasks
```

User decides what to record. No agent ever writes to state files.

---

## Triage: Size × Risk

| Size | Definition |
|---|---|
| XS | < 20 lines, obvious fix |
| S | Single file, clear scope |
| M | Multi-file or new pattern |
| L | Architectural / cross-cutting / novel |

| Risk | Triggers (any one) |
|---|---|
| Low | None of High applies |
| High | Concurrency, async, shared state, security, data integrity, prod blast radius, ML reproducibility-critical, external API contracts, user-flagged risk, recurring failure pattern in this area |

### Routing

| Triage | Flow |
|---|---|
| XS × Low | `implementer-fast` (Haiku) |
| XS × High | `mentor` (Opus) → `implementer` (Sonnet) |
| S × Low | `mentor-light` → `implementer-fast` → optional `debugger-light` |
| S × High | `mentor` → `implementer` → `debugger` |
| M × Low | `mentor` → `planner` → critique → `implementer` → `debugger` |
| M × High | Same + per-step debugger review mandatory |
| L × any | `mentor` + `researcher` upfront → `planner` → critique → `implementer` → `debugger` |

---

## Stop conditions (no infinite-loop reviews)

Defined explicitly in STATE_PROTOCOL.md:

| Triage | Stop when |
|---|---|
| XS × Low | implementer-fast completes |
| XS × High | debugger quick-review = no Blockers |
| S × Low | implementer-fast + (optional) debugger-light = no Blockers |
| S × High | debugger Confidence ≥ Medium on fixes, or no issues found |
| M × Low | implementer + debugger reviews = no Blockers |
| M × High | All per-step reviews clear AND debugger Confidence ≥ Medium on bugs |
| L × any | Full flow + checkpoints answered + no blocking Open questions |

If criterion not met, the gap-detecting agent states what's missing rather than starting another loop.

---

## Mode signals

| Signal | Effect |
|---|---|
| `fast mode` | mentor skips Socratic, direct + 2-sentence reason |
| `ship mode` | implementer writes minimal production code |
| `learn mode` | implementer's default (verbose teaching) |
| `prototype mode` | bypass triage, fast-path to implementer-fast |
| `harden it` | re-triage prototype as M, run full flow |
| `lazy entry` | (auto-detected on direct coding requests) — fast-route + retroactive triage |
| `rough plan` / `fast-plan` | planner emits compressed plan; mentor critique compressed |
| `exploratory debug` | debugger probes first, hypothesizes after observation |
| `triage this as M` (or S, L) | override mentor's classification |
| `high stakes` | force Risk = High |
| `deep research` | researcher exceeds its 5-search cap |

---

## Installation

### Step 1 — Drop files in place

```bash
mkdir -p .claude/agents
```

Copy the 8 agent `.md` files to `.claude/agents/` (project-level) or `~/.claude/agents/` (global).

Copy `STATE_PROTOCOL.md`, `agent_state.md`, `session_state.md`, `patterns.md` to your repo root. Fill in `agent_state.md` with your stack/conventions before first use.

Restart Claude Code.

### Step 2 — Add MCP servers (recommended)

**Context7** — version-accurate library docs:
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY
```

**GitHub MCP** — search issues/PRs/code:
```bash
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token
```

Verify: `claude mcp list`.

---

## Tips for using v5 well

1. **Fill in `agent_state.md` upfront.** Stack + Conventions + Anti-patterns. 15 minutes. Pays back within a day.
2. **Maintain `patterns.md` weekly.** When you notice a confidence pattern (planner Low on infra X, debugger Medium on async Y), record it. Surfaces real skill gaps.
3. **Don't fight escalations.** When `implementer-fast` escalates, read the reason. That's the lesson.
4. **Use lazy entry liberally.** Don't preface every request with "explain to me how to…" — just ask for what you want, the system figures out the rest.
5. **Use bounded interpretation cautiously.** When implementer-fast applies it, verify the marked assumption matches your intent. The 5 conditions are strict but Haiku can still misjudge.
6. **Watch the stop conditions.** When work is declared done by the system, that's intentional. Don't ask for "one more review" out of habit — the criteria were calibrated.
7. **Read STATE_PROTOCOL.md once.** Then trust it. The whole system depends on agents following it consistently.

---

## What v5 is good at

✅ Backend systems with real correctness stakes
✅ AI/ML pipelines (training, eval, inference)
✅ DevOps / infra changes with rollback concerns
✅ Multi-week projects where state continuity matters
✅ Learning new patterns deliberately
✅ Debugging non-obvious failures with exploratory mode
✅ Spotting your own skill gaps over time via patterns.md

## What it's still less suited for

⚠️ Highly ambiguous product/UX work — use prototype mode
⚠️ Pure UI iteration loops — overhead exceeds benefit
⚠️ Rote work you've done 100 times — use ship mode

If fighting the system on simple work, that's a signal: use prototype/ship mode, or step outside.

---

## Optional: CLAUDE.md

A `CLAUDE.md` at repo root holds **static project context** — different from `agent_state.md`:

| File | Content | Updates |
|---|---|---|
| `CLAUDE.md` | Long-lived, rarely-edited project description (used by Claude Code globally) | Rarely |
| `agent_state.md` | Evolving validated assumptions, decisions, anti-patterns | As work progresses |
| `session_state.md` | Active task | Per session |
| `patterns.md` | Meta-learning over months | Append weekly |

Share your stack (ML framework + versions, MLOps tools, deploy target) and a tailored `CLAUDE.md` template can be written.
