---
name: confidence-rating-rubric
description: How to rate Confidence as High/Medium/Low when producing plans, root causes, or research findings. Used by planner, debugger, and researcher.
---

# Confidence Rating Rubric

When you (planner, debugger, or researcher) produce output that other agents will act on, rate your Confidence as **High**, **Medium**, or **Low**. The rating changes downstream behavior, so accuracy matters more than looking decisive.

## High

You used this rating when:
- Affected files / hypotheses / sources have been **directly verified**
- Conventions, patterns, or signals from the codebase / sources are **clear and consistent**
- **No critical assumption is unverified**
- No Open questions block execution / fix / use
- If a peer reviewed your output, you would not be surprised by their findings

## Medium

You used this rating when:
- Output is workable but **1-2 unverified assumptions exist**
- Conventions or signals are partially clear, with some inference filling gaps
- You are extrapolating from limited context (e.g., small codebase sample, single source)
- A peer reviewer might surface assumptions you should have made explicit

## Low

You used this rating when:
- **Multiple unknowns** remain
- Codebase / source signal is weak; you guessed at territory
- Output should be treated as a **starting draft**, not an executable spec
- You would expect a peer reviewer to find significant flaws

## The honesty test

Before assigning a rating, ask yourself: **"If a peer reviews this and finds a flaw, would I be surprised?"**

- Would not be surprised → Confidence is Medium or Low
- Would be surprised → High is honest

Inflating confidence to look decisive is the most expensive failure mode in this system. Low confidence is **useful information** — it triggers downstream agents to escalate model tier, add review checkpoints, or verify with the user. Hiding low confidence breaks the safety net.

## What downstream agents do with each rating

For **planner output**:
- High → mentor critiques normally, implementer executes standard
- Medium → mentor probes assumptions, implementer notes assumptions per step
- Low → mentor doesn't auto-approve (returns to planner OR escalates model tier); implementer pauses after step 1 to verify

For **debugger root cause**:
- High → fix is final, regression test added
- Medium → fix lands but "watch in prod" is documented
- Low → fix lands as best theory, plus monitoring + observability recommended

For **researcher findings**:
- High → calling agent uses directly
- Medium → calling agent uses with stated caveats
- Low → calling agent treats as starting point, may verify before acting
