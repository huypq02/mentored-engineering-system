# Agent State — Shared Context

This file is the team memory for the agent system. **You (the user) own this file.** Agents read it for context but never write to it. They will *suggest* additions in their output; you decide what to record.

Keep it short. Aim for under 200 lines. If it grows past that, archive old sections.

---

## Project context

<!-- Brief description of what this project is, what it does, what it doesn't do -->

## Stack

<!-- Versions matter. Pin them. -->

- Language: <e.g., Python 3.11>
- ML framework: <e.g., PyTorch 2.6>
- MLOps: <e.g., MLflow 2.x, DVC>
- Infra: <e.g., AWS EKS, Terraform, GitHub Actions>
- Observability: <e.g., Datadog, Prometheus>

## Conventions

<!-- Things that took time to establish; agents should follow without re-litigating -->

- Code style: <e.g., black + ruff, line length 100>
- Testing: <e.g., pytest, fixtures in conftest.py>
- Branching: <e.g., trunk-based, PRs >300 lines need extra review>
- Logging: <e.g., structlog with JSON output in prod>

## Validated assumptions

<!-- Things we've checked are true. Don't re-verify these unless they could have changed. -->

- <e.g., "Production GPUs are A100-40GB, not 80GB" — verified 2026-03>
- <e.g., "The data pipeline always emits sorted timestamps" — verified by debugger 2026-04>

## Known constraints

<!-- Hard limits that bound the design space -->

- <e.g., "Inference latency budget: p99 < 200ms">
- <e.g., "Cannot upgrade torch past 2.6 until vendor X supports it">
- <e.g., "Training data PII must not leave region us-west-2">

## Decisions made (and why)

<!-- Architectural / design decisions that shouldn't be reopened casually -->

- <YYYY-MM-DD> — <decision> — <one-sentence rationale>
- <YYYY-MM-DD> — <decision> — <one-sentence rationale>

## Open questions

<!-- Things we haven't decided. Agents should flag if their work depends on resolving these. -->

- <question 1>
- <question 2>

## Anti-patterns to avoid

<!-- Mistakes we've already made and don't want to repeat -->

- <e.g., "Don't use mp.spawn for distributed training — use torchrun. Spawn caused N issues in March.">
- <e.g., "Don't hand-roll retry logic — use tenacity, we standardized on it.">

---

*Last updated: <date>*
