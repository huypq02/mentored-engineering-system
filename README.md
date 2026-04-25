# 5-Agent Mentored Engineering System (v2)

A multi-agent Claude Code setup for engineers growing into a senior AI/ML + DevOps role. Learning-first, not automation-first. Redesigned after a real review round to fix friction points.

## What's new in v2

Compared to v1, this version fixes five real-world friction points:

1. **Task-size triage** — mentor classifies every task as XS/S/M/L and routes accordingly. No more 4-agent ceremony for a 10-line fix.
2. **Sharp mentor / researcher boundary** — mentor gets ONE search per response; anything bigger goes to researcher. Quantitative, not fuzzy.
3. **Planner is now read-only** — Bash removed. Can't inspect runtime state, must state assumptions as open questions. Role purity preserved.
4. **Implementer has learn mode and ship mode** — default is verbose + teaching; "ship mode" on request for production speed.
5. **Feedback loops added** — mentor critiques planner's plan before implementer runs it; debugger reports design-level findings back to planner; implementer escalates to mentor when it detects conceptual confusion.

Plus one bonus: debugger now does proactive "quick reviews" after non-trivial implementer steps.

## Agents

| Agent | Role | Tools | Model |
|---|---|---|---|
| **mentor** | Triage, teach, critique plans, route | Read, Grep, Glob, WebSearch, WebFetch | opus |
| **planner** | Plans changes (read-only, no execution) | Read, Grep, Glob, WebSearch, WebFetch | opus |
| **implementer** | Executes plan (learn/ship mode) | Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch | sonnet |
| **debugger** | Debug + review + quick-review + design feedback | Read, Edit, Bash, Grep, Glob, WebSearch, WebFetch | opus |
| **researcher** | Multi-source research (2+ searches minimum) | WebSearch, WebFetch, Read, Grep | opus |

---

## Installation

### Step 1 — Drop agent files in place

```bash
mkdir -p .claude/agents
```

Copy all 5 `.md` files into `.claude/agents/` (project-level) or `~/.claude/agents/` (global). Restart Claude Code.

### Step 2 — Add MCP servers (recommended)

Built-in `WebSearch` is generic. For technical work, add these:

**Context7 — version-accurate library docs**
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_CONTEXT7_API_KEY
```
Free key at `context7.com/dashboard`. Works without a key but rate-limited.

**GitHub MCP — search issues, PRs, code**
```bash
claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github
```
Then:
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```
Create a token at `github.com/settings/tokens` with `repo` and `read:org` scopes.

**Verify:**
```bash
claude mcp list
```
And inside Claude Code: `/mcp`.

### Step 3 — VS Code Copilot custom agents (global profile)

If you want this same 5-agent system inside VS Code Copilot Chat, create these files under your user profile agents folder:

`%APPDATA%\\Code\\User\\prompts\\agents\\mentor.agent.md`
`%APPDATA%\\Code\\User\\prompts\\agents\\planner.agent.md`
`%APPDATA%\\Code\\User\\prompts\\agents\\implementer.agent.md`
`%APPDATA%\\Code\\User\\prompts\\agents\\debugger.agent.md`
`%APPDATA%\\Code\\User\\prompts\\agents\\researcher.agent.md`

Then reload VS Code and pick an agent from the Copilot Chat agent selector.

Recommended usage in VS Code:

1. Start with **mentor** for triage and routing.
2. Use **planner** for M/L tasks before code edits.
3. Use **implementer** for code changes (`learn mode` by default, `ship mode` when requested).
4. Use **debugger** when tests fail or runtime behavior is unexpected.
5. Use **researcher** when you need 2+ searches or multi-source comparison.

Tool alias note for VS Code custom agents:

- `read` = file reads
- `search` = text/file search
- `edit` = file edits
- `execute` = terminal commands
- `web` = web search/fetch
- `agent` = subagent invocation
- `todo` = task tracking

---

## How the flows work

### XS task flow (trivial fix)
```
You → implementer (directly)
```
No ceremony. Implementer does it, one paragraph of explanation.

### S task flow (single file, clear scope)
```
You → mentor (1 response, concept + approach) → implementer
```
Skip planner. Mentor still teaches, implementer still codes in learn mode.

### M task flow (multi-file, some risk)
```
You → mentor (triage, teach, approach) → planner (draft plan) → 
mentor (CRITIQUE plan) → implementer (one step at a time) → 
debugger (quick-review after non-trivial steps) → [debugger full-debug if bugs]
```
The mentor-critiques-plan step is the key addition — catches planner mistakes before they reach code.

### L task flow (architectural / novel)
```
You → mentor → researcher (current best practices) → mentor (teach) → 
planner (informed plan) → mentor (critique) → implementer → debugger
```
Researcher is pulled in up front to establish the 2026 landscape before planning.

### Bug flow
```
debugger → [if root cause is a planning flaw] → feedback to planner → 
planner updates assumptions
```

### Concept-confusion flow (new)
```
implementer notices user is confused → pauses → escalates to mentor → 
mentor teaches → implementer resumes
```

---

## Mode signals you can use

Tell the agents how you want to work:

- **`fast mode`** — mentor skips Socratic questions, gives direct answer
- **`ship mode`** — implementer writes minimal production code, no teaching comments
- **`learn mode`** — default; verbose teaching comments (usually not needed to say)
- **`triage this as S`** — override mentor's task-size classification
- **`deep research`** — tell researcher to exceed its 5-search cap

---

## Key design choices

- **Mentor uses Opus** — teaching requires deep reasoning.
- **Mentor has NO Write/Edit** — forced to teach, not silently solve.
- **Planner has NO Bash/Write/Edit** — read-only. Forces clear assumptions instead of runtime poking.
- **Implementer requires plan for M/L only** — XS/S can proceed without ceremony.
- **Debugger forbids guess-and-check** — searches known issues first, hypothesizes second, fixes third.
- **Researcher is isolated** — handles multi-source work so other agents keep clean context.
- **Mentor reviews plans** — senior reviewer move, catches design flaws before they become code.
- **Debugger feeds back to planner** — closes the loop so planning gets better over time.

---

## Tips to learn faster

1. **Respect the triage.** If mentor says "this is M," don't push for S — the planning step is where most senior-level growth happens.
2. **Read mentor's plan critique carefully.** That critique *is* the senior lesson. It teaches you what to look for when you read juniors' plans later.
3. **Keep a `learnings.md`.** Log every mentor checkpoint question + your answer. Review monthly.
4. **When out of ideas:** "mentor, give me 3 approaches with trade-offs" — unstuck framework.
5. **When under deadline:** "fast mode + ship mode" — direct answer, minimal code, but still 2 sentences of reasoning so you learn something.
6. **Use ship mode sparingly.** It's there for real time pressure, not as the default. Ship mode too often = no learning happens.
7. **Verify citations.** If any agent claims a fact without a source, push back: "what's the source?" — trains you to hold yourself to the same standard.

---

## Optional: CLAUDE.md

A `CLAUDE.md` at the repo root describing your stack (framework versions, MLOps tools, conventions) makes all 5 agents far more accurate. Share your stack (ML framework + versions, MLOps, deploy target) and I'll write a tailored template.
