# Mentored Engineering System for Claude Code — v6 (fixed)

A multi-agent setup for engineers growing into senior AI/ML + DevOps roles. Learning-first, top-down architecture. This is **v6 (fixed)** — the original v6 design with all known issues resolved through several iterations of audit and refinement.

## What changed from raw v6

This release consolidates fixes for issues found during real-world testing of v6:

1. **Path resolution for state files now works for both install scopes.** Agents at `.claude/agents/` (project) OR `~/.claude/agents/` (user, shared) both find state files reliably. The new `state-file-resolver` skill handles this with strategy-based dispatch (Bash agents use `git rev-parse`; non-Bash agents use `Glob`).
2. **Skills extracted from agent prompts.** Common rules (style, reporting format, escalation checklist, confidence rubric) moved into 7 reusable skills. Agent files dropped 30-50% in length. Updates are atomic — change one skill, all agents inherit.
3. **Enforcement hooks added.** Four shell-script hooks turn soft prompt rules into hard enforcement: secrets-scan before write, format-on-edit, tests-before-commit gating, debugger-completion logging to patterns.md.
4. **Native auto-memory acknowledged.** Claude Code 2.1.59+ has built-in cross-session memory. State files now hold only the _deliberate_ contract (decisions, validated assumptions, anti-patterns) — not duplicating what Claude Code already provides.
5. **Human-in-the-loop model routing.** Agents pause and recommend model switches; you stay in control of cost. New `model-switch-protocol` skill defines the standard format.
6. **`session_state.md` made optional.** Only for L tasks or multi-day M tasks resumed via named sessions. Default workflows skip it entirely.
7. **L-task power-ups in mentor.** Mentor suggests Extended Thinking (`Alt+T`) and native `/plan` for L tasks before delegating to our `planner` agent.
8. **Stop conditions per tier** explicitly defined in STATE_PROTOCOL.md to prevent "one more review" loops.

The architecture (Size × Risk triage, light/heavy variants, Confidence propagation, plan critique) is unchanged from v6. These are all fixes and refinements, not redesigns.

---

## Directory layout

```
v6/                       (the v6 distribution)
├── agents/                 → copy to your-project/.claude/agents/
│   ├── mentor.md
│   ├── planner.md
│   └── ... (8 total)
├── skills/                 → copy to your-project/.claude/skills/
│   ├── code-style-python-ml/SKILL.md
│   ├── model-switch-protocol/SKILL.md
│   └── ... (7 total)
├── hooks/                  → copy *.sh to ~/.claude/hooks/
│   ├── secrets-scan.sh
│   └── ... (4 total)
└── state/                  → copy to your-project/ (repo root)
    ├── agent_state.md
    ├── patterns.md
    └── session_state.md

your-project/              (your actual repo)
├── .claude/
│   ├── agents/            ← agent .md files go here
│   └── skills/            ← skill folders go here
├── agent_state.md         ← state files go at REPO ROOT
├── patterns.md
├── session_state.md       (optional)
├── STATE_PROTOCOL.md
├── your-code/
├── tests/
└── README.md
```

---

## Installation

### One-command setup

```bash
cd your-project

# Project scope (default — agents version-controlled with your repo)
bash v6/install.sh

# User scope (agents shared across all your projects)
bash v6/install.sh --user-agents

# Include enforcement hooks
bash v6/install.sh --hooks
bash v6/install.sh --user-agents --hooks
```

### Agents and skills: two valid install locations

**Project scope (default)**

```
your-project/.claude/agents/     ← agents here
your-project/.claude/skills/     ← skills here
```

- Version-controlled with your code ✓
- Different projects can have different agents ✓
- Team members get everything when they clone ✓

**User scope (`--user-agents`)**

```
~/.claude/agents/                 ← agents here (shared across all projects)
~/.claude/skills/                 ← skills here (shared across all projects)
```

- Set up once, works in every project ✓
- No per-project agent installation needed ✓

**In both cases, state files always live at project root:**

```
your-project/agent_state.md      ← always here
your-project/patterns.md         ← always here
your-project/STATE_PROTOCOL.md   ← always here
```

**How agents find state files regardless of install scope:**
Claude Code runs agents with the working directory set to the **project root** (where you launched Claude Code). Agents resolve state files at runtime via:

```bash
git rev-parse --show-toplevel 2>/dev/null || pwd
```

This works whether agents are at `.claude/agents/` or `~/.claude/agents/` — the working directory is always the project root.

### Step-by-step

**1. Install (choose scope)**

```bash
bash v6/install.sh              # project scope
bash v6/install.sh --user-agents   # user scope
```

**2. Install hooks (optional but strongly recommended)**

```bash
bash v6/install.sh --hooks
# Merge hooks/settings.json.snippet into ~/.claude/settings.json
```

**3. Set up state files (always at project root)**

```bash
# Done automatically by install.sh — just edit agent_state.md with your stack
nano agent_state.md
```

**4. Install MCP servers (optional)**

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

**5. Restart Claude Code**

### Optional: Hooks (strongly recommended for enforcement)

```bash
# Install hooks (also included in main install.sh)
bash v6/install.sh --hooks

# This installs 4 shell-script hooks to ~/.claude/hooks/
# Hooks are global, applied to all your projects
```

Hooks enforce rules:

- `secrets-scan.sh` — blocks writes containing API keys, tokens, etc.
- `format-python.sh` — auto-formats Python files after edits
- `tests-before-commit.sh` — requires tests to run before allowing git commit
- `debugger-completion-log.sh` — logs bug fixes to patterns.md

### Optional: MCP servers (for richer research)

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

### 5. Restart Claude Code

---

## Agent overview

| Agent              | Role                                    | Model  | Skills preloaded                                                                         |
| ------------------ | --------------------------------------- | ------ | ---------------------------------------------------------------------------------------- |
| `mentor`           | Triage Size×Risk, teach, critique plans | Opus   | confidence-rating-rubric, model-switch-protocol                                          |
| `mentor-light`     | Compressed teaching for plain S × Low   | Sonnet | escalation-checklist-risk, model-switch-protocol                                         |
| `planner`          | Plans M/L (read-only)                   | Opus   | confidence-rating-rubric, model-switch-protocol                                          |
| `implementer`      | Executes M/L plans                      | Sonnet | code-style-python-ml, code-style-infra, reporting-format-stepwise, model-switch-protocol |
| `implementer-fast` | XS/S × Low execution                    | Haiku  | escalation-checklist-risk, reporting-format-stepwise, model-switch-protocol              |
| `debugger`         | Hypothesis-driven debug + reviews       | Opus   | confidence-rating-rubric, reporting-format-stepwise, model-switch-protocol               |
| `debugger-light`   | Compressed S × Low debug                | Sonnet | escalation-checklist-risk, model-switch-protocol                                         |
| `researcher`       | Multi-source research                   | Opus   | confidence-rating-rubric, model-switch-protocol                                          |

---

## Hooks: what they do

| Hook                         | Event                                     | Effect                                                                                                         |
| ---------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `secrets-scan.sh`            | PreToolUse on Write/Edit                  | Blocks file write if content contains likely secrets (API keys, tokens, private keys)                          |
| `format-python.sh`           | PostToolUse on Write/Edit                 | Auto-runs `ruff format` and lint on changed Python files; non-blocking                                         |
| `tests-before-commit.sh`     | PreToolUse on Bash (matches `git commit`) | Blocks commit unless tests have been run in this session within 30 min. `--no-verify` overrides explicitly.    |
| `debugger-completion-log.sh` | SubagentStop on debugger/debugger-light   | Appends a one-line entry to `patterns.md` Failure patterns when debugger finishes a Medium/High-confidence fix |

These turn "the agent should..." rules into "the system enforces..." rules. Hooks are deterministic in a way prompts aren't.

---

## State system: native + deliberate

### Native auto-memory (Claude Code, automatic)

Claude Code 2.1.59+ writes its own memory across sessions. `/memory` to view. **You don't manage this.** Our agents don't read it directly — Claude Code injects it before our agents run.

### Deliberate memory (you write, agents read)

| File                          | Purpose                                                                           | Update frequency                        |
| ----------------------------- | --------------------------------------------------------------------------------- | --------------------------------------- |
| `agent_state.md`              | The contract: Stack, Conventions, Validated assumptions, Decisions, Anti-patterns | When something fundamental changes      |
| `patterns.md`                 | Meta-learning: confidence patterns, failure patterns, skill gaps                  | Append-only, weekly review              |
| `session_state.md` (optional) | Cross-session bridge for one feature                                              | Per-session, archived when feature done |

See `STATE_PROTOCOL.md` for full read/write rules per agent.

---

## Mode signals

| Signal                       | Effect                                                     |
| ---------------------------- | ---------------------------------------------------------- |
| `fast mode`                  | mentor skips Socratic, direct + 2-sentence reason          |
| `ship mode`                  | implementer writes minimal production code                 |
| `learn mode`                 | implementer's default (verbose teaching)                   |
| `prototype mode`             | bypass triage, fast-path to implementer-fast               |
| `harden it`                  | re-triage prototype as M, run full flow                    |
| `rough plan` / `fast-plan`   | planner emits compressed plan (forbidden when Risk = High) |
| `exploratory debug`          | debugger probes first, hypothesizes after observation      |
| `triage this as M` (or S, L) | override mentor's classification                           |
| `high stakes`                | force Risk = High                                          |
| `deep research`              | researcher exceeds 5-search cap                            |

For L tasks, mentor will also suggest:

- Toggle Extended Thinking (`Alt+T` / `Option+T`)
- Use native `/plan` before our `planner` agent
- Name the session: `claude -c -r feature/<slug>` for cross-session continuity

## Human-in-the-loop model routing

**You are the router.** Agents don't switch models silently — they pause, recommend a switch, and wait for you to act.

### How it works

When an agent realizes the current model tier is wrong for the task, it emits a structured switch request and stops:

```
## Model switch request

**Direction**: Upgrade
**Pattern**: B (main session model)
**Current tier**: Sonnet
**Recommended tier**: Opus

### Why
This is L territory now — we're designing distributed training topology.
Extended Thinking will help me reason about the trade-offs.

### Action for you
Run `/model opus` then say "continue".

### What I've established so far
- Affected files mapped
- Two design alternatives sketched
- Open question on memory budget unresolved
```

You then either:

- **Switch and continue**: `/model opus` then `continue`
- **Stay current tier**: `stay current tier` — agent proceeds at current model with trade-off acknowledged
- **Force a specific tier**: `force opus` / `force sonnet` / `force haiku`
- **Disable switches for the session**: `no switches this session`

### Two switch patterns

**Pattern A — agent variant**: Re-invoke as a different agent (e.g., `mentor-light` recommends switching to `mentor`). Used when there's a heavy/light pair available.

**Pattern B — main session model**: Run `/model <tier>`. Used when an agent needs the main conversation upgraded, or when working without subagents.

### When agents request switches

| Agent              | Typical upgrade trigger            | Typical downgrade trigger                         |
| ------------------ | ---------------------------------- | ------------------------------------------------- |
| `mentor-light`     | Escalation checklist hits          | (no lighter option)                               |
| `mentor`           | (already top tier)                 | Task turned out smaller, route via `mentor-light` |
| `planner`          | (already top tier)                 | Plan is 3-5 mechanical steps, skip planning       |
| `implementer`      | Step reveals architectural concern | Remaining work is plumbing → `implementer-fast`   |
| `implementer-fast` | Bounded interpretation fails       | (no lighter option)                               |
| `debugger`         | (already top tier)                 | Bug turned out to be a typo                       |
| `debugger-light`   | Two hypotheses both wrong          | (no lighter option)                               |
| `researcher`       | (already top tier)                 | Question is single-fact, bounce back to caller    |

### Why this matters

- **You stay in control of cost.** The system never burns Opus tokens without you knowing.
- **Routing becomes visible learning.** Over time you'll see _which_ tasks need Opus and _which_ are fine on Haiku — that's senior intuition being trained.
- **No runaway escalation.** Each switch requires explicit user action, so the system can't ladder itself up to Opus by accident.

---

## What changed from v6 in concrete terms

- **Agent files are ~30-50% shorter** because shared content moved to skills
- **Style updates are atomic** — change `code-style-python-ml` once, both implementers inherit
- **Hooks enforce 4 critical rules** that v6 only hoped agents would follow
- **`session_state.md` removed from default workflow** — only present when needed
- **Native Claude Code features integrated** rather than reinvented (auto-memory, /plan, Extended Thinking, named sessions)

## What stayed the same from v6

- Size × Risk triage (the architectural core)
- Confidence propagation across agents
- Light/heavy variants by task tier
- Bounded interpretation rule (5 strict conditions)
- Plan critique by mentor
- Stop conditions per tier
- Top-down system design

The architecture is unchanged. v6 (fixed) is a refinement, not a redesign.
