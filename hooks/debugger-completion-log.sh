#!/usr/bin/env bash
# debugger-completion-log.sh
# SubagentStop hook, scoped to debugger and debugger-light agents.
# Appends a one-line entry to $PROJECT_ROOT/patterns.md when debugger finishes a bug fix.
#
# Reads agent name from $AGENT_NAME and final response from $AGENT_RESPONSE.

set -uo pipefail

AGENT="${AGENT_NAME:-}"
RESPONSE="${AGENT_RESPONSE:-}"

# Only fire for debugger agents
if [[ "$AGENT" != "debugger" ]] && [[ "$AGENT" != "debugger-light" ]]; then
  exit 0
fi

# Only fire if a root cause was actually identified (response contains "Root cause" section)
if ! echo "$RESPONSE" | grep -q "## Root cause"; then
  exit 0
fi

# Extract one-liner root cause and confidence
ROOT_CAUSE=$(echo "$RESPONSE" | sed -n '/## Root cause/,/##/p' | sed -n '2p' | head -c 200)
CONFIDENCE=$(echo "$RESPONSE" | grep -E -o "Confidence (in root cause)?: (High|Medium|Low)" | head -1 | grep -E -o "(High|Medium|Low)")

# Only log if Medium or High confidence (Low confidence findings are too speculative for $PROJECT_ROOT/patterns.md)
if [[ "$CONFIDENCE" != "High" ]] && [[ "$CONFIDENCE" != "Medium" ]]; then
  exit 0
fi

DATE=$(date +%Y-%m-%d)
PATTERNS_FILE="$PROJECT_ROOT/patterns.md"

# Find $PROJECT_ROOT/patterns.md — try repo root first
if [[ ! -f "$PATTERNS_FILE" ]]; then
  exit 0  # No $PROJECT_ROOT/patterns.md, nothing to log to
fi

# Append under "Failure patterns" section if not already there
ENTRY="- ${DATE} ${AGENT} (Confidence: ${CONFIDENCE}) — ${ROOT_CAUSE}"

# Avoid duplicate entries
if grep -F -q "$ROOT_CAUSE" "$PATTERNS_FILE"; then
  exit 0
fi

# Append to Failure patterns section
if grep -q "^## Failure patterns" "$PATTERNS_FILE"; then
  # Insert after the Failure patterns header
  awk -v entry="$ENTRY" '
    /^## Failure patterns/ { print; getline; print; print entry; next }
    { print }
  ' "$PATTERNS_FILE" > "${PATTERNS_FILE}.tmp" && mv "${PATTERNS_FILE}.tmp" "$PATTERNS_FILE"
  echo "Logged debugger completion to $PROJECT_ROOT/patterns.md" >&2
fi

exit 0
