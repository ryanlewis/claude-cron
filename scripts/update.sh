#!/bin/bash
# claude-cron update — pull latest and redeploy
set -euo pipefail
cd "$HOME/claude-cron"
git pull --ff-only
claude -p --dangerously-skip-permissions /deploy
