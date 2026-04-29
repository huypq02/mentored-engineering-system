# agent_state.md — Project-Stable Context

**Lifetime: months. Write authority: user only.** Agents read this for stable project context. They suggest additions in their output; you decide what to record.

Keep under 200 lines. If it grows, archive old sections to `agent_state.archive.md`.

---

## Project context

<!-- 2-3 sentences: what this project is, what it does, what's out of scope -->

## Stack

<!-- Pin versions. -->

- Language: <e.g., Python 3.11>
- ML framework: <e.g., PyTorch 2.6>
- MLOps: <e.g., MLflow 2.x, DVC>
- Infra: <e.g., AWS EKS, Terraform, GitHub Actions>
- Observability: <e.g., Datadog, Prometheus>

## Conventions

<!-- Things that took effort to establish; agents should follow without re-litigation -->

- Code style: <e.g., black + ruff, line length 100>
- Testing: <e.g., pytest, fixtures in conftest.py>
- Branching: <e.g., trunk-based, PRs >300 lines need extra review>
- Logging: <e.g., structlog with JSON output in prod>
- Imports: <e.g., absolute imports only>

## Validated assumptions

<!-- Things we've verified are true. Don't re-verify these unless they could plausibly have changed. -->

- <YYYY-MM-DD> <e.g., "Production GPUs are A100-40GB"> — verified by <agent or user>
- <YYYY-MM-DD> <e.g., "Data pipeline emits sorted timestamps"> — verified by debugger

## Known constraints

<!-- Hard limits that bound the design space -->

- <e.g., "Inference latency budget: p99 < 200ms">
- <e.g., "Cannot upgrade torch past 2.6 until vendor X supports it">
- <e.g., "Training data PII must not leave region us-west-2">

## Decisions made

<!-- Architectural / design decisions that shouldn't be reopened casually -->

- <YYYY-MM-DD> — <decision> — <one-sentence rationale>
- <YYYY-MM-DD> — <decision> — <one-sentence rationale>

## Open questions

<!-- Unresolved. Agents flag if their work depends on resolution. -->

- <question 1>

## Anti-patterns to avoid

<!-- Mistakes already made; don't repeat -->

- <e.g., "Don't use mp.spawn — use torchrun. Spawn caused issues in March 2026.">
- <e.g., "Don't hand-roll retry logic — use tenacity, standardized.">

---

*Last updated: <date>*
