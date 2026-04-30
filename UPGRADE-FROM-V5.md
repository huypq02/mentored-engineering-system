# Upgrading from v5 to v6

If you already installed v5, here's exactly what changes. v6 keeps the same architecture; the upgrade is **subtractive plus additive**, not a rewrite.

## What to remove

```bash
# Remove old agent files (v6 replaces all of them)
rm .claude/agents/mentor.md
rm .claude/agents/mentor-light.md
rm .claude/agents/planner.md
rm .claude/agents/implementer.md
rm .claude/agents/implementer-fast.md
rm .claude/agents/debugger.md
rm .claude/agents/debugger-light.md
rm .claude/agents/researcher.md

# Remove session_state.md if you weren't using it for L tasks
# (It's now optional; keep it only if you have ongoing multi-day work)
# rm session_state.md   # only if not in active use
```

## What to keep as-is

```
agent_state.md     # your project contract — keep all your customizations
patterns.md        # your meta-learning — append-only, keep everything
```

These files don't change format between v5 and v6.

## What to add (the new bits)

```bash
# 1. Skills folder (NEW in v6)
mkdir -p .claude/skills
cp -r v6/skills/* .claude/skills/

# 2. New agent files (replace the ones you removed)
cp v6/agents/*.md .claude/agents/

# 3. Hooks (NEW in v6 — optional but recommended)
mkdir -p ~/.claude/hooks
cp v6/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
# Then merge v6/hooks/settings.json.snippet into ~/.claude/settings.json

# 4. Updated STATE_PROTOCOL.md
cp v6/STATE_PROTOCOL.md ./STATE_PROTOCOL.md   # overwrite v5 version
```

Or just run the install script:
```bash
bash v6/install.sh --hooks
```

## What changes in agent behavior (visible to you)

After upgrade, you'll notice:

1. **Mentor mentions native features for L tasks.** First time you trigger an L task, mentor will say "Toggle Extended Thinking, consider /plan, name this session." This is intentional — you weren't using these levers before.

2. **Lazy entry works the same.** No behavior change for direct coding requests.

3. **Reports look identical.** The `reporting-format-stepwise` skill produces the same output structure as v5's inline rules — that's the point. Format moved, format unchanged.

4. **Style enforcement is sharper.** With hooks installed, secret commits get blocked, Python files auto-format, and `git commit` requires tests-run-this-session. None of this happened in v5.

5. **`session_state.md` may be missing.** That's fine — it's now optional. If you don't have multi-day work, you don't need it.

## What stays the same

- Size × Risk triage
- Confidence propagation
- Agent variants by tier (light/heavy)
- Bounded interpretation rule
- Mentor's plan critique
- Stop conditions per tier
- All mode signals (`fast mode`, `ship mode`, `prototype mode`, etc.)

The architecture is the same. v6 just uses Claude Code's native features properly and reduces duplication.

## Sanity check after upgrade

Run a quick test in Claude Code:

```
You: "fix this typo in README.md: 'recieve' should be 'receive'"
```

Expected: `mentor` triages as XS × Low silently, routes directly to `implementer-fast`, fix lands, you see "Triage: XS × Low — routed to implementer-fast." That's the lazy-entry path working correctly.

```
You: "I want to add distributed training across 4 GPUs"
```

Expected: `mentor` triages as L × High, suggests Extended Thinking + `/plan` + named session, asks a Socratic question, hands to `researcher` for current 2026 best practices, then to `planner`. That's the L-task power-up path working.

If either of these doesn't behave as expected, check that:
1. Skills are in `.claude/skills/` and accessible
2. Agent files have `skills:` in their YAML frontmatter
3. You restarted Claude Code after install
