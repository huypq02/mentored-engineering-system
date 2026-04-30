# CHANGELOG — v6 (fixed)

This document records the issues found in raw v6 and how each was fixed during the iteration cycle that produced **v6 (fixed)**.

---

## Issue 1: Path resolution broke for user-scoped agents

**Symptom:** When agents installed at `~/.claude/agents/` (user scope, shared across projects), they would silently fail to find `agent_state.md` and other state files at the project root.

**Root cause:** Agents used bare filenames like `read agent_state.md` — relying on cwd being the project root. This works when cwd is correct, but fails silently when it isn't.

**Fix:** New `state-file-resolver` skill, preloaded by all 8 agents. Defines two strategies:

- **Strategy A** (Bash agents — debugger, debugger-light, implementer, implementer-fast): use `git rev-parse --show-toplevel` to find project root explicitly, then read with absolute path.
- **Strategy B** (non-Bash agents — mentor, mentor-light, planner, researcher): use the `Glob` tool to discover state files from cwd, then read the returned path.

Both strategies are robust to install scope (project or user).

**Audit confirms:** All 8 agents use the correct strategy for their tool set. Non-Bash agents have no `$PROJECT_ROOT` references; Bash agents have explicit git-based resolution.

---

## Issue 2: Style rules and reporting formats duplicated across agents

**Symptom:** Updating "how the implementer reports a step" required editing every implementer variant. Three different rules for confidence rating across mentor, planner, and debugger could drift apart.

**Fix:** Extracted 7 reusable skills:

- `code-style-python-ml` — Python/ML conventions (preloaded by implementer)
- `code-style-infra` — Dockerfile, Terraform, k8s, shell (preloaded by implementer)
- `reporting-format-stepwise` — step report format (preloaded by all implementers and debugger)
- `escalation-checklist-risk` — High-risk triggers (preloaded by all light agents)
- `confidence-rating-rubric` — High/Medium/Low calibration (preloaded by mentor, planner, debugger, researcher)
- `model-switch-protocol` — model switch request format (preloaded by all 8 agents)
- `state-file-resolver` — state file path resolution (preloaded by all 8 agents)

Result: agent files dropped 30-50% in length; updates are atomic.

---

## Issue 3: No enforcement of safety rules

**Symptom:** Rules like "don't commit secrets," "run tests before committing," "format Python on edit" lived only in agent prompts. A model could ignore them.

**Fix:** Four shell-script hooks added (in `hooks/`):

- `secrets-scan.sh` — PreToolUse on Write/Edit, blocks if content matches secret patterns
- `format-python.sh` — PostToolUse on Edit, runs ruff format/check
- `tests-before-commit.sh` — PreToolUse on `git commit`, blocks unless tests run within 30 min
- `debugger-completion-log.sh` — SubagentStop on debugger, appends fixes to patterns.md

Wired up via `hooks/settings.json.snippet`.

---

## Issue 4: Native Claude Code memory was being duplicated

**Symptom:** Claude Code 2.1.59+ has built-in cross-session auto-memory. Our `session_state.md` was reinventing it less effectively, requiring manual maintenance.

**Fix:** STATE_PROTOCOL.md now distinguishes:

- **Layer 1 — Native auto-memory** (Claude Code, automatic): observational memory, build commands, code style noticed, debugging insights from past sessions.
- **Layer 2 — Deliberate memory** (our state files, you maintain): the project contract, validated assumptions, decisions, anti-patterns, meta-learning.

`session_state.md` made optional — only used for L tasks or multi-day M tasks via named sessions (`claude -c -r feature/<slug>`).

---

## Issue 5: No human-in-the-loop on model selection

**Symptom:** Agents either ran on whatever model their YAML said, or escalated to other agents silently. User had no visibility into when work needed Opus vs Haiku.

**Fix:** `model-switch-protocol` skill defines a structured "model switch request" format. Agents pause when they detect a tier mismatch and emit:

```
## Model switch request
**Direction**: Upgrade | Downgrade
**Pattern**: A (re-invoke as different agent) | B (switch main session model)
**Current tier**: <Haiku/Sonnet/Opus>
**Recommended tier**: <Haiku/Sonnet/Opus>
### Why
### Action for you
### What I've established so far
```

User then either: switches and says "continue", says "stay current tier" to bypass, or says "force <tier>" to override. Each agent has agent-specific upgrade and downgrade triggers.

---

## Issue 6: No explicit stop conditions per tier

**Symptom:** Reviews could loop indefinitely. "One more review" was a real failure mode.

**Fix:** STATE_PROTOCOL.md now defines explicit stop conditions per Size × Risk tier:

| Triage    | Stop when                                                     |
| --------- | ------------------------------------------------------------- |
| XS × Low  | implementer-fast completes                                    |
| XS × High | debugger quick-review = no Blockers                           |
| S × Low   | implementer-fast + (optional) debugger-light = no Blockers    |
| S × High  | debugger Confidence ≥ Medium on fixes                         |
| M × Low   | implementer + debugger reviews = no Blockers                  |
| M × High  | All per-step reviews clear AND Confidence ≥ Medium            |
| L × any   | Full flow + checkpoints answered + no blocking Open questions |

Plus a "pause condition" for model switch requests — agents wait for user response before continuing.

---

## Issue 7: L-tasks didn't use Claude Code's native power features

**Symptom:** Mentor immediately handed L tasks to our `planner` agent, missing the chance to use Extended Thinking (`Alt+T`) and native `/plan` mode.

**Fix:** Mentor now suggests for L tasks:

> "This is L — before we start: (1) Toggle Extended Thinking with `Alt+T` for deeper reasoning. (2) Consider `/plan` to let Claude Code's native planner sketch first. (3) Name this session: `claude -c -r feature/<slug>` for cross-session continuity."

Layered on top of v6's flow, not replacing it.

---

## Files in this release

```
v6-fixed/
├── README.md                         (system overview)
├── CHANGELOG.md                      (this file)
├── STATE_PROTOCOL.md                 (memory contract)
├── install.sh                        (one-command setup)
├── agents/         (8 agents)        → .claude/agents/ or ~/.claude/agents/
│   ├── mentor.md                     model: opus
│   ├── mentor-light.md               model: sonnet
│   ├── planner.md                    model: opus
│   ├── implementer.md                model: sonnet
│   ├── implementer-fast.md           model: haiku
│   ├── debugger.md                   model: opus
│   ├── debugger-light.md             model: sonnet
│   └── researcher.md                 model: opus
├── skills/         (7 skills)        → .claude/skills/ or ~/.claude/skills/
│   ├── code-style-python-ml/SKILL.md
│   ├── code-style-infra/SKILL.md
│   ├── reporting-format-stepwise/SKILL.md
│   ├── escalation-checklist-risk/SKILL.md
│   ├── confidence-rating-rubric/SKILL.md
│   ├── model-switch-protocol/SKILL.md
│   └── state-file-resolver/SKILL.md
├── hooks/          (4 hooks + config)→ ~/.claude/hooks/
│   ├── secrets-scan.sh
│   ├── format-python.sh
│   ├── tests-before-commit.sh
│   ├── debugger-completion-log.sh
│   └── settings.json.snippet
└── state/          (3 templates)     → project root
    ├── agent_state.md                (required)
    ├── patterns.md                   (required, append-only)
    └── session_state.md              (optional)
```

**Total: 27 files.**

---

## Validation done before release

- ✓ All 8 agents preload `state-file-resolver` skill
- ✓ All 8 agents preload `model-switch-protocol` skill
- ✓ Each agent uses the correct state-read strategy for its tool set (Bash → git, no Bash → Glob)
- ✓ No stale `$PROJECT_ROOT` references in non-Bash agents
- ✓ Frontmatter (name, description, tools, model, skills) intact for all 8 agents
- ✓ Install script supports both `--user-agents` and project-scope (default)
- ✓ State files always at project root regardless of agent install scope
- ✓ All 7 skills present with valid frontmatter
- ✓ All 4 hooks present and self-contained
