#!/usr/bin/env bash
# secrets-scan.sh
# PreToolUse hook for Write and Edit tools.
# Blocks the tool call if the content being written contains likely secrets.
#
# Reads tool input from $TOOL_INPUT (set by Claude Code).
# Exit 0 = allow, exit non-zero with stderr = block.

set -euo pipefail

CONTENT="${TOOL_INPUT:-}"

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Patterns for common secret formats. Add to this list as needed.
PATTERNS=(
  # AWS
  'AKIA[0-9A-Z]{16}'
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'
  # GitHub
  'ghp_[A-Za-z0-9]{36}'
  'github_pat_[A-Za-z0-9_]{82}'
  # OpenAI / Anthropic
  'sk-[A-Za-z0-9]{32,}'
  'sk-ant-[A-Za-z0-9-]{32,}'
  # Generic high-entropy with key-like name
  '(api[_-]?key|secret|password|token)\s*[:=]\s*["\047][A-Za-z0-9+/=]{20,}["\047]'
  # Private keys
  '-----BEGIN (RSA |OPENSSH |EC |DSA |PGP )?PRIVATE KEY-----'
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -E -q "$pattern"; then
    echo "BLOCKED: content matches secret pattern: $pattern" >&2
    echo "If this is a false positive, edit secrets-scan.sh to refine the pattern." >&2
    echo "Never commit real secrets — use env vars and .env.example instead." >&2
    exit 1
  fi
done

exit 0
