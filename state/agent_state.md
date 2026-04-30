# agent_state.md — Project Contract

**Lifetime: months. Write authority: user only.** Agents read this for stable project context. They suggest additions in their output; you decide what to record. Native auto-memory handles transient learning — this file holds the deliberate contract.

Keep under 200 lines.

---

## Project context

<!-- 2-3 sentences: what this project is, what it does, what's out of scope -->

## Stack

- Language: <e.g., Python 3.11>
- ML framework: <e.g., PyTorch 2.6>
- MLOps: <e.g., MLflow 2.x, DVC>
- Infra: <e.g., AWS EKS, Terraform, GitHub Actions>
- Observability: <e.g., Datadog, Prometheus>

## Conventions

- Code style: <e.g., black + ruff, line length 100>
- Testing: <e.g., pytest, fixtures in conftest.py>
- Branching: <e.g., trunk-based, PRs >300 lines need extra review>
- Logging: <e.g., structlog with JSON output in prod>
- Imports: <e.g., absolute imports only>

## Validated assumptions

<!-- Things we've verified are true. Don't re-verify these unless they could plausibly have changed. -->

- <YYYY-MM-DD> "Production GPUs are A100-40GB" — verified by checking deployment config
- <YYYY-MM-DD> "Data pipeline emits sorted timestamps" — verified by debugger

## Known constraints

<!-- Hard limits that bound the design space -->

- "Inference latency budget: p99 < 200ms"
- "Cannot upgrade torch past 2.6 until vendor X supports it"
- "Training data PII must not leave region us-west-2"

## Decisions made

<!-- Architectural / design decisions that shouldn't be reopened casually -->

- <YYYY-MM-DD> — <decision> — <one-sentence rationale>

## Open questions

<!-- Unresolved. Agents flag if their work depends on resolution. -->

- <question 1>

## Anti-patterns to avoid

<!-- Mistakes already made; don't repeat -->

- "Don't use mp.spawn — use torchrun. Spawn caused issues in March 2026."
- "Don't hand-roll retry logic — use tenacity, standardized."

---

*Last updated: <date>*
