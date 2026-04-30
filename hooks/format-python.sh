#!/usr/bin/env bash
# format-python.sh
# PostToolUse hook for Edit and Write tools.
# Auto-formats and lints Python files. Non-blocking — reports issues but doesn't fail.
#
# Reads file path from $TOOL_INPUT_PATH (set by Claude Code).

set -uo pipefail

FILE="${TOOL_INPUT_PATH:-}"

if [[ -z "$FILE" ]] || [[ ! -f "$FILE" ]]; then
  exit 0
fi

# Only Python files
if [[ "${FILE##*.}" != "py" ]]; then
  exit 0
fi

# Format with ruff if available
if command -v ruff > /dev/null 2>&1; then
  ruff format "$FILE" > /dev/null 2>&1 || echo "ruff format failed on $FILE" >&2
  
  # Lint and report (non-blocking)
  if ! ruff check "$FILE" 2>&1; then
    echo "Lint issues in $FILE — review before continuing." >&2
  fi
elif command -v black > /dev/null 2>&1; then
  # Fallback to black if ruff not available
  black --quiet "$FILE" 2>/dev/null || echo "black failed on $FILE" >&2
fi

# Type check with mypy if config exists and tool available
if [[ -f "mypy.ini" ]] || [[ -f "pyproject.toml" ]] && grep -q "\[tool.mypy\]" pyproject.toml 2>/dev/null; then
  if command -v mypy > /dev/null 2>&1; then
    mypy "$FILE" --no-error-summary 2>&1 | head -20 >&2 || true
  fi
fi

exit 0
