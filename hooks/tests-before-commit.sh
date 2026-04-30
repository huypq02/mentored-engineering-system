#!/usr/bin/env bash
# tests-before-commit.sh
# PreToolUse hook for Bash tool with `git commit` matcher.
# Blocks commits unless tests have been run in this session.
#
# Tracks test runs via a marker file in /tmp scoped to the Claude Code session.

set -euo pipefail

COMMAND="${TOOL_INPUT:-}"

# Only check git commit commands
if ! echo "$COMMAND" | grep -E -q '^\s*git\s+commit\b'; then
  exit 0
fi

# Allow --no-verify as explicit user override
if echo "$COMMAND" | grep -E -q '\-\-no-verify\b'; then
  echo "WARNING: --no-verify used. Tests skipped. Make sure this is intentional." >&2
  exit 0
fi

# Session-scoped marker — if Claude Code sets a session id, use it; otherwise fall back
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
MARKER="/tmp/claude-tests-run-${SESSION_ID}"

# Marker created by separate hook on test command, or written manually
if [[ -f "$MARKER" ]]; then
  AGE_SECONDS=$(( $(date +%s) - $(stat -f %m "$MARKER" 2>/dev/null || stat -c %Y "$MARKER") ))
  if [[ $AGE_SECONDS -lt 1800 ]]; then  # 30 min freshness
    exit 0
  fi
fi

echo "BLOCKED: tests have not been run in this session (or last run > 30 min ago)." >&2
echo "Run your test suite first. Then retry the commit." >&2
echo "" >&2
echo "If this commit is intentionally skipping tests (docs change, comment-only edit)," >&2
echo "use 'git commit --no-verify' to bypass this check." >&2
echo "" >&2
echo "To mark tests as run after running them:" >&2
echo "  touch $MARKER" >&2
exit 1
