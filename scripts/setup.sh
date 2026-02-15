#!/bin/bash
# claude-cron setup — one-time provisioning for an exe.dev VM
# Run after: git clone https://github.com/you/claude-cron ~/claude-cron
#
# Prerequisites (do these yourself first):
#   - claude auth: run `claude` interactively, or set ANTHROPIC_API_KEY in ~/.claude/settings.local.json
#   - gh auth: run `gh auth login` if tasks use GitHub
#   - MCP servers: claude mcp add ... (local scope, stored in ~/.claude.json)

set -euo pipefail

CLAUDE_CRON_DIR="$HOME/claude-cron"

echo "claude-cron setup"
echo "============="

mkdir -p "$CLAUDE_CRON_DIR/data/logs"
chmod +x "$CLAUDE_CRON_DIR"/scripts/*.sh

echo "Running /deploy..."
cd "$CLAUDE_CRON_DIR"
claude -p --dangerously-skip-permissions /deploy

echo ""
echo "Setup complete!"
