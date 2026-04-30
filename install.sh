#!/usr/bin/env bash
# install.sh — one-command setup for the Mentored Engineering System v6
# Run from inside the v6/ directory at the root of your project.
#
# Usage:
#   bash install.sh                  # install agents + skills + state to current repo
#   bash install.sh --hooks          # also install hooks to ~/.claude/hooks
#   bash install.sh --user-agents    # install agents to ~/.claude/agents (global) instead of project
#   bash install.sh --all            # everything: agents, skills, hooks, state, MCP reminder

set -euo pipefail

# Colors for readable output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

V6_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_HOOKS=false
USER_AGENTS=false

for arg in "$@"; do
  case "$arg" in
    --hooks) INSTALL_HOOKS=true ;;
    --user-agents) USER_AGENTS=true ;;
    --all) INSTALL_HOOKS=true; USER_AGENTS=true ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

echo -e "${BLUE}=== Mentored Engineering System v6 — Install ===${NC}"
echo ""

# 1. Agents
if $USER_AGENTS; then
  AGENTS_DIR="$HOME/.claude/agents"
  echo -e "${YELLOW}Installing agents to user scope: $AGENTS_DIR${NC}"
else
  AGENTS_DIR=".claude/agents"
  echo -e "${YELLOW}Installing agents to project scope: $AGENTS_DIR${NC}"
fi
mkdir -p "$AGENTS_DIR"
cp "$V6_DIR"/agents/*.md "$AGENTS_DIR/"
echo -e "${GREEN}OK${NC} — 8 agents installed"
echo ""

# 2. Skills (global scope when --user-agents, otherwise project scope)
if $USER_AGENTS; then
  SKILLS_DIR="$HOME/.claude/skills"
  echo -e "${YELLOW}Installing skills to user scope: $SKILLS_DIR${NC}"
else
  SKILLS_DIR=".claude/skills"
  echo -e "${YELLOW}Installing skills to: $SKILLS_DIR${NC}"
fi
mkdir -p "$SKILLS_DIR"
cp -r "$V6_DIR"/skills/* "$SKILLS_DIR/"
echo -e "${GREEN}OK${NC} — 5 skills installed"
echo ""

# 3. State files (only if not already present — never overwrite user content)
echo -e "${YELLOW}Installing state files (only if missing)${NC}"
for f in agent_state.md patterns.md; do
  if [[ -f "$f" ]]; then
    echo "  $f already exists — skipping (will not overwrite)"
  else
    cp "$V6_DIR/state/$f" "./$f"
    echo -e "  ${GREEN}OK${NC} — created $f"
  fi
done

# session_state.md is optional, only suggest it
if [[ ! -f "session_state.md" ]]; then
  echo "  session_state.md not created (optional, only for multi-session L work)"
fi

# STATE_PROTOCOL is reference, copy if missing
if [[ ! -f "STATE_PROTOCOL.md" ]]; then
  cp "$V6_DIR/STATE_PROTOCOL.md" "./STATE_PROTOCOL.md"
  echo -e "  ${GREEN}OK${NC} — created STATE_PROTOCOL.md"
fi
echo ""

# 4. Hooks (optional)
if $INSTALL_HOOKS; then
  HOOKS_DIR="$HOME/.claude/hooks"
  echo -e "${YELLOW}Installing hooks to $HOOKS_DIR${NC}"
  mkdir -p "$HOOKS_DIR"
  cp "$V6_DIR"/hooks/*.sh "$HOOKS_DIR/"
  chmod +x "$HOOKS_DIR"/*.sh
  echo -e "${GREEN}OK${NC} — 4 hooks installed and made executable"
  echo ""
  echo -e "${YELLOW}IMPORTANT — manual step required:${NC}"
  echo "  Merge $V6_DIR/hooks/settings.json.snippet"
  echo "  into ~/.claude/settings.json under the 'hooks' key."
  echo "  See README.md for the snippet."
  echo ""
fi

# 5. Reminders
echo -e "${BLUE}=== Next steps ===${NC}"
echo ""
echo "  1. Edit agent_state.md to reflect your project's stack and conventions."
echo "     This is the single most valuable upfront investment (15 min, pays back in days)."
echo ""
echo "  2. Restart Claude Code so it picks up the new agents and skills."
echo ""
if ! $INSTALL_HOOKS; then
  echo "  3. (Optional but recommended) Re-run with --hooks to install the 4 enforcement hooks:"
  echo "       bash install.sh --hooks"
  echo ""
fi
echo "  4. (Optional but recommended) Add MCP servers for richer technical research:"
echo "       claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp"
echo "       claude mcp add --scope user github -- npx -y @modelcontextprotocol/server-github"
echo "       export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_..."
echo ""
echo -e "${GREEN}Done.${NC} Read README.md for the full system overview."
