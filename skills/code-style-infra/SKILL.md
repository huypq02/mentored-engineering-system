---
name: code-style-infra
description: Infrastructure-as-code conventions for Dockerfiles, Terraform, Kubernetes YAML, GitHub Actions, and shell scripts. Auto-invoked when editing infra files.
---

# Infrastructure Code Style

## Version pinning (universal rule)
- **Never use `latest` tags or unpinned versions.** Pin everything.
- Docker base images: `python:3.11.9-slim` not `python:slim`
- npm packages: exact version or `~` for patch only
- Helm charts: pinned to specific chart version
- Action versions in GitHub Actions: pinned SHA or version tag, not `@main`

## Dockerfile
- Multi-stage builds for anything compiled
- One concern per RUN where reasonable, but combine related apt-get/pip into single RUN to keep layers compact
- USER non-root in production images
- HEALTHCHECK on long-running services
- COPY only what's needed; use `.dockerignore`

## Terraform / Kubernetes YAML
- Comment any non-obvious flag, especially security-relevant ones
- Use modules / kustomize overlays — don't copy-paste configs across environments
- Resource limits (CPU/memory) on every k8s container — no exceptions
- Never inline secrets; reference from Secret/SealedSecret/external secret manager

## Shell scripts
- First two lines of every script:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- Quote all variable expansions: `"$var"` not `$var`
- Use `[[ ]]` for tests, not `[ ]`
- Trap signals when long-running

## GitHub Actions
- Pin actions by full commit SHA for security-sensitive workflows
- Use `permissions:` to scope down `GITHUB_TOKEN` to only what's needed
- Avoid `${{ github.event.* }}` injection points without validation

## Secrets
- Never commit secrets, ever, even briefly. Pre-commit hooks catch this.
- Use env vars with `.env.example` showing the keys (no values)
- For CI, use repository secrets or OIDC federation, not long-lived keys

## What to avoid
- Hardcoded paths that only work in one environment
- `chmod 777` (use the minimum permissions needed)
- `curl | bash` from untrusted sources
- Disabled TLS verification (`--insecure`, `verify=false`)
