# Mentored Engineering System for Claude Code (v6)

A multi-agent setup for engineers growing into senior AI/ML + DevOps roles. Learning-first, top-down architecture. v6 is a **surgical upgrade** of v5 — same architecture, better use of native Claude Code features.

## What's new in v6

After analyzing the `claude-howto` tutorial repo, six gaps in v5 were identified and fixed:

1. **Native auto-memory acknowledged.** Claude Code 2.1.59+ has built-in memory that survives sessions. v6 stops duplicating it. Our state files now hold only the *deliberate* contract (decisions, validated assumptions, anti-patterns) — the things you want every agent to follow on purpose.
2. **Skills extracted.** Common content (code style, escalation checklist, reporting format, confidence rubric) moved into 5 reusable skills that agents preload via the `skills:` frontmatter field. Updates to style or reporting are now atomic — change one skill, all agents inherit.
3. **Enforcement hooks added.** Four shell-script hooks turn soft prompt rules into hard enforcement: secret scanning, format-on-edit, test-before-commit gating, debugger-completion logging.
4. **`session_state.md` is now optional.** Only used for L tasks or multi-day M tasks resumed via named sessions (`claude -c -r feature/<slug>`). Default workflows skip it entirely.
5. **L-task power-ups.** Mentor now suggests Extended Thinking (`Alt+T`) and native `/plan` for L tasks before our `planner` agent runs. Layered on top of v5's flow, not replacing it.
6. **Cleaner directory structure.** Files grouped by purpose so installation is one command per concern.

---

## Directory layout

```
v6/
├── agents/              # 8 subagent definitions → .claude/agents/
│   ├── mentor.md
│   ├── mentor-light.md
│   ├── planner.md
│   ├── implementer.md
│   ├── implementer-fast.md
│   ├── debugger.md
│   ├── debugger-light.md
│   └── researcher.md
├── skills/              # 5 reusable skills → .claude/skills/
│   ├── code-style-python-ml/SKILL.md
│   ├── code-style-infra/SKILL.md
│   ├── reporting-format-stepwise/SKILL.md
│   ├── escalation-checklist-risk/SKILL.md
│   └── confidence-rating-rubric/SKILL.md
├── hooks/               # 4 enforcement hooks → ~/.claude/hooks/
│   ├── secrets-scan.sh
│   ├── format-python.sh
│   ├── tests-before-commit.sh
│   ├── debugger-completion-log.sh
│   └── settings.json.snippet
├── state/               # Templates → repo root
│   ├── agent_state.md   # required: project contract
│   ├── patterns.md      # required: meta-learning, append-only
│   └── session_state.md # optional: cross-session work
├── STATE_PROTOCOL.md    # the memory contract → repo root
└── README.md            # this file
```

---

## Quick Install

```bash
bash install.sh
```

Flags: `--hooks` (also installs enforcement hooks), `--user-agents` (agents global instead of per-project), `--all` (everything + MCP reminder).

---

## Installation

### 1. Agents
```bash
mkdir -p .claude/agents
cp agents/*.md .claude/agents/
```

### 2. Skills
```bash
mkdir -p .claude/skills
cp -r skills/* .claude/skills/
```

### 3. Hooks (optional but strongly recommended)
```bash
mkdir -p ~/.claude/hooks
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
# Then merge hooks/settings.json.snippet into ~/.claude/settings.json
```

### 4. State files
```bash
cp state/agent_state.md ./agent_state.md
cp state/patterns.md ./patterns.md
cp STATE_PROTOCOL.md ./STATE_PROTOCOL.md
# Edit agent_state.md to reflect your stack/conventions
```

For multi-session L work, also `cp state/session_state.md ./session_state.md`.

### 5. MCP servers (recommended for Gap 2 of analysis)
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_KEY
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

### 6. Restart Claude Code

---

## Agent overview

| Agent | Role | Model | Skills preloaded |
|---|---|---|---|
| `mentor` | Triage Size×Risk, teach, critique plans | Opus | confidence-rating-rubric |
| `mentor-light` | Compressed teaching for plain S × Low | Sonnet | escalation-checklist-risk |
| `planner` | Plans M/L (read-only) | Opus | confidence-rating-rubric |
| `implementer` | Executes M/L plans | Sonnet | code-style-python-ml, code-style-infra, reporting-format-stepwise |
| `implementer-fast` | XS/S × Low execution | Haiku | escalation-checklist-risk, reporting-format-stepwise |
| `debugger` | Hypothesis-driven debug + reviews | Opus | confidence-rating-rubric, reporting-format-stepwise |
| `debugger-light` | Compressed S × Low debug | Sonnet | escalation-checklist-risk |
| `researcher` | Multi-source research | Opus | confidence-rating-rubric |

---

## Hooks: what they do

| Hook | Event | Effect |
|---|---|---|
| `secrets-scan.sh` | PreToolUse on Write/Edit | Blocks file write if content contains likely secrets (API keys, tokens, private keys) |
| `format-python.sh` | PostToolUse on Write/Edit | Auto-runs `ruff format` and lint on changed Python files; non-blocking |
| `tests-before-commit.sh` | PreToolUse on Bash (matches `git commit`) | Blocks commit unless tests have been run in this session within 30 min. `--no-verify` overrides explicitly. |
| `debugger-completion-log.sh` | SubagentStop on debugger/debugger-light | Appends a one-line entry to `patterns.md` Failure patterns when debugger finishes a Medium/High-confidence fix |

These turn "the agent should..." rules into "the system enforces..." rules. Hooks are deterministic in a way prompts aren't.

---

## State system: native + deliberate

### Native auto-memory (Claude Code, automatic)
Claude Code 2.1.59+ writes its own memory across sessions. `/memory` to view. **You don't manage this.** Our agents don't read it directly — Claude Code injects it before our agents run.

### Deliberate memory (you write, agents read)

| File | Purpose | Update frequency |
|---|---|---|
| `agent_state.md` | The contract: Stack, Conventions, Validated assumptions, Decisions, Anti-patterns | When something fundamental changes |
| `patterns.md` | Meta-learning: confidence patterns, failure patterns, skill gaps | Append-only, weekly review |
| `session_state.md` (optional) | Cross-session bridge for one feature | Per-session, archived when feature done |

See `STATE_PROTOCOL.md` for full read/write rules per agent.

---

## Mode signals

| Signal | Effect |
|---|---|
| `fast mode` | mentor skips Socratic, direct + 2-sentence reason |
| `ship mode` | implementer writes minimal production code |
| `learn mode` | implementer's default (verbose teaching) |
| `prototype mode` | bypass triage, fast-path to implementer-fast |
| `harden it` | re-triage prototype as M, run full flow |
| `rough plan` / `fast-plan` | planner emits compressed plan (forbidden when Risk = High) |
| `exploratory debug` | debugger probes first, hypothesizes after observation |
| `triage this as M` (or S, L) | override mentor's classification |
| `high stakes` | force Risk = High |
| `deep research` | researcher exceeds 5-search cap |

For L tasks, mentor will also suggest:
- Toggle Extended Thinking (`Alt+T` / `Option+T`)
- Use native `/plan` before our `planner` agent
- Name the session: `claude -c -r feature/<slug>` for cross-session continuity

---

## What changed from v5 in concrete terms

- **Agent files are ~30-50% shorter** because shared content moved to skills
- **Style updates are atomic** — change `code-style-python-ml` once, both implementers inherit
- **Hooks enforce 4 critical rules** that v5 only hoped agents would follow
- **`session_state.md` removed from default workflow** — only present when needed
- **Native Claude Code features integrated** rather than reinvented (auto-memory, /plan, Extended Thinking, named sessions)

## What stayed the same from v5

- Size × Risk triage (the architectural core)
- Confidence propagation across agents
- Light/heavy variants by task tier
- Bounded interpretation rule (5 strict conditions)
- Plan critique by mentor
- Stop conditions per tier
- Top-down system design

The architecture is unchanged. v6 is a refinement, not a redesign.
