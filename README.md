# Mentored Engineering System for Claude Code (v4)

A multi-agent setup for engineers growing into senior AI/ML + DevOps roles. Learning-first, not automation-first. Now with **deterministic escalation triggers**, **Size × Risk triage**, **confidence propagation**, **prototype mode**, and **shared state via `agent_state.md`**.

## What's new in v4

v3 had the right architecture and right model routing. v4 closes five real-world failure modes that would only show up after weeks of use:

1. **Deterministic escalation triggers** — every lightweight agent now has an explicit checklist. If any item is checked, escalate. No judgment calls, no drift.
2. **Size × Risk as first-class triage** — a 15-line concurrency patch is "S" by size but "High" by risk. Mentor classifies on both dimensions and routes accordingly.
3. **Hard "interpretation = escalation" rule for Haiku** — `implementer-fast` escalates the moment a spec needs interpretation. Prevents the "Haiku confidently does the wrong thing" failure mode.
4. **Confidence propagation** — `planner` outputs Low/Medium/High confidence; `mentor` and `implementer` adapt behavior based on it. `debugger` rates confidence in root cause too.
5. **Prototype mode** — explicit fast-path that bypasses ceremony for exploratory work. "Harden it" command re-triages as M and runs full flow on the prototype.

Plus: optional **`agent_state.md`** at repo root — a user-owned shared scratchpad agents read for context. Stops re-litigation of settled decisions across long sessions.

---

## All 8 agents (+ template)

| Agent | Role | Model |
|---|---|---|
| `mentor` | Triage on Size×Risk, teach, critique plans | Opus |
| `mentor-light` | Compressed teaching for plain S × Low | Sonnet |
| `planner` | Plans M/L changes (read-only, with Confidence) | Opus |
| `implementer` | Executes plans for M/L (learn/ship modes) | Sonnet |
| `implementer-fast` | XS/S × Low execution, prototype mode | Haiku |
| `debugger` | Hypothesis-driven debug + review for M/L | Opus |
| `debugger-light` | Compressed debug + quick review for S × Low | Sonnet |
| `researcher` | Multi-source research (2+ search threshold) | Opus |
| `agent_state.md` | User-owned shared context (template) | n/a |

---

## Triage: Size × Risk

Mentor classifies every task on both dimensions:

### Size

| | Definition |
|---|---|
| **XS** | < 20 lines, obvious fix, typo, rename, one-liner |
| **S** | Single file, clear scope, no architectural decisions |
| **M** | Multi-file, some risk, or new pattern |
| **L** | Architectural, cross-cutting, novel territory |

### Risk

| | Triggers (any one) |
|---|---|
| **Low** | None of the High triggers apply |
| **High** | Concurrency, async, threads, shared state. Security (auth, secrets, injection, permissions). Data integrity (migrations, irreversible writes, financial). Production blast radius. Reproducibility-critical ML. External API contracts. User-flagged risk. |

### Routing

| Triage | Flow |
|---|---|
| **XS × Low** | `implementer-fast` (Haiku) |
| **XS × High** | `mentor` (Opus) → `implementer` (Sonnet) |
| **S × Low** | `mentor-light` (Sonnet) → `implementer-fast` (Haiku) → optional `debugger-light` |
| **S × High** | `mentor` (Opus) → `implementer` (Sonnet) → `debugger` (Opus) |
| **M × Low** | `mentor` → `planner` → critique → `implementer` → `debugger` |
| **M × High** | Same as M × Low + mandatory `debugger` review per step |
| **L × any** | `mentor` + `researcher` upfront → `planner` → critique → `implementer` → `debugger` |

**The override-upward rule**: Risk overrides Size for model selection. S × High runs the M-tier model stack.

---

## Confidence propagation

Every reasoning agent outputs a confidence level. Downstream agents read it and adapt.

### Planner outputs `Confidence: High | Medium | Low`

| Plan confidence | Mentor's response | Implementer's response |
|---|---|---|
| **High** | Standard critique | Standard execution |
| **Medium** | Probe assumptions deeper | Note assumptions used per step |
| **Low** | Don't auto-approve. Send back, OR escalate model tier and add per-step review checkpoint | Treat plan as draft. Verify with user after step 1, then between every step until confidence rises. |

### Researcher outputs `Confidence: High | Medium | Low`
- High = primary sources agree, recent, directly addresses question
- Medium = primary source partial, or only secondary sources agree
- Low = best inference; treat as starting point

### Debugger outputs `Confidence in root cause: High | Medium | Low`
- High = experiment directly confirmed; bug gone after fix
- Medium = strongly inferred but not fully isolated; watch in prod
- Low = best current theory; recommend monitoring + observability

**Honesty matters more than looking decisive.** Agents are trained to flag Medium/Low when warranted instead of inflating to High. The signal is load-bearing.

---

## Prototype mode

Tell mentor (or any agent): "**prototype mode**" or "this is exploratory."

What happens:
- Triage skipped
- Routes directly to `implementer-fast`
- Quality bar drops to "works enough to learn from"
- Skip error handling, edge cases, defensive coding, tests
- Comments minimal
- BUT: risk-item escalation checklist (concurrency, security, data integrity) still applies

When done prototyping, say "**harden it**" — mentor re-triages as M and runs the full flow on the prototype as input.

This addresses the "too much ceremony for exploration" friction without creating a backdoor for risky shortcuts.

---

## Shared state: `agent_state.md`

Optional but recommended for any project lasting more than a few sessions. A markdown file at the repo root that the user maintains. Agents read it for context but never write to it.

What goes in it:
- Stack and pinned versions
- Conventions (style, testing, branching, logging)
- Validated assumptions (things we've checked are true)
- Known constraints (hard limits)
- Decisions made (and why)
- Open questions
- Anti-patterns to avoid

Agents will **suggest additions** in their output ("Suggested addition to agent_state.md: …") — you decide what to record. This pattern stops the "we keep relitigating the same decision" problem on long projects.

The file `agent_state.md` in this distribution is a template — copy it to your repo root and fill it in.

---

## Installation

### Step 1 — Drop agent files in place

```bash
mkdir -p .claude/agents
```

Copy all 8 agent `.md` files into `.claude/agents/` (project-level) or `~/.claude/agents/` (global). Restart Claude Code.

Copy `agent_state.md` to your repo root if you want shared state.

### Step 2 — Add MCP servers (recommended)

**Context7 — version-accurate library docs**
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_CONTEXT7_API_KEY
```

**GitHub MCP — search issues, PRs, code**
```bash
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
```
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

**Verify:**
```bash
claude mcp list
```

---

## Mode signals you can use

- `fast mode` — mentor skips Socratic, direct answer
- `ship mode` — implementer writes minimal production code
- `learn mode` — implementer's default, verbose teaching comments
- `prototype mode` — bypass triage, fast-path to implementer-fast
- `harden it` — re-triage prototype as M, run full flow
- `triage this as M` (or S, L) — override mentor's classification
- `high stakes` — force Risk = High even if mentor classified it Low
- `deep research` — researcher exceeds its 5-search cap

---

## Tips to learn faster

1. **Respect the triage.** If mentor says "M × High," don't push for "S × Low." The escalation is the lesson.
2. **Read mentor's plan critique carefully.** That critique IS the senior lesson.
3. **Watch escalations.** When `implementer-fast` escalates to full `implementer`, read the reason — that's "what makes this harder than it looks," exactly the senior intuition you're building.
4. **Pay attention to Confidence: Low signals.** When planner or researcher flags Low confidence, ask why before continuing. The reason is usually a concept-shaped hole in your understanding.
5. **Maintain `agent_state.md`.** Five minutes a week. Stops you from re-deriving the same conclusions month after month.
6. **Use prototype mode on purpose.** Spike, learn, throw away, then harden. Don't let the prototype become production by accident — that's why "harden it" exists as an explicit step.
7. **Keep `learnings.md` separately.** Every checkpoint question + your answer. Review monthly.
8. **Verify citations.** If any agent claims a fact without a source, ask "what's the source?"

---

## What this system is good at

✅ Backend systems with real correctness stakes
✅ AI/ML pipelines (training, eval, inference)
✅ DevOps / infra changes with rollback concerns
✅ Structured refactoring with multi-file blast radius
✅ Learning new architectural patterns deliberately
✅ Debugging non-obvious failures

## What it's less suited for

⚠️ Highly ambiguous product/UX work — use prototype mode and don't expect deep teaching
⚠️ Pure UI iteration — overhead exceeds benefit
⚠️ Pair-programming on something you've done 100 times — use ship mode

If you find yourself fighting the system on simple work, that's a signal: either use prototype/ship mode, or step outside the system entirely. The system is a teacher, not a yoke.

---

## Optional: CLAUDE.md

A `CLAUDE.md` at the repo root describing your stack makes all 8 agents far more accurate. Different file from `agent_state.md`:
- `CLAUDE.md` — static project context (long-lived, rarely edited)
- `agent_state.md` — evolving team memory (updated as work progresses)

Share your stack (ML framework + versions, MLOps tools, deploy target) and a tailored `CLAUDE.md` template can be written.
