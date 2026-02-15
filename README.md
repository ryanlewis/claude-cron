# claude-cron

Run Claude Code on a schedule. Write tasks as markdown files. Push to deploy.

Designed for quick setup on [exe.dev](https://exe.dev) VMs ($20/mo).

## Setup

### 1. Create your repo

Click **"Use this template"** on GitHub to create your own copy.

### 2. Create a VM

```bash
ssh exe.dev new --name=my-cron
```

### 3. Set up the VM

SSH in, auth Claude, clone your repo, and run setup:

```bash
ssh my-cron.exe.xyz

# Log into Claude (interactive prompt — do this once)
claude

# Clone your repo and run setup
git clone https://github.com/YOUR-USERNAME/claude-cron ~/claude-cron
~/claude-cron/scripts/setup.sh
```

Done. Your crontab is now managed by Claude.

## Adding a Task

Create a `.md` file in `tasks/`. Write what you want and when:

```markdown
Run every weekday at 9am UTC. Max 50 turns, $1 budget. Use haiku.

Check https://github.com/you/project for open PRs older than 7 days.
Post a reminder comment on each one. Email me a summary.
```

Then redeploy on the VM:

```bash
~/claude-cron/scripts/update.sh
```

One file per task. Delete the file to remove the task. You can also set up [CI](#ci-deploy-optional) to deploy automatically on `git push`.

### Frontmatter (optional)

If you prefer explicit config over prose:

```markdown
---
schedule: "*/30 9-17 * * 1-5"
max-turns: 50
timeout: 600
model: claude-haiku-4-5-20251001
---

Check CI status for the main branch. If any checks are failing,
open an issue with the failure details.
```

## CI Deploy (Optional)

Auto-deploy on every push to main. Commit a task, push, done.

### 1. Generate a deploy key

```bash
ssh-keygen -t ed25519 -C "claude-cron-ci" -f ~/.ssh/claude-cron-ci -N ""
```

### 2. Add it to exe.dev

```bash
cat ~/.ssh/claude-cron-ci.pub | ssh exe.dev ssh-key add
```

### 3. Enable the workflow

```bash
cp .github/workflows/deploy.yml.example .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Enable CI deploy"
```

### 4. Set GitHub secrets

```bash
gh variable set EXE_DEV_HOST --body "VMNAME.exe.xyz"
gh variable set EXE_DEV_USER --body "exedev"
gh secret set EXE_DEV_SSH_KEY < ~/.ssh/claude-cron-ci
```

Replace `VMNAME` with your VM name from step 2.

### 5. Push

```bash
git push
```

Check it worked: `gh run list`

## How It Works

- Tasks live in `tasks/*.md` — one file per task
- On deploy, Claude reads every task file, extracts the schedule and limits, and generates the crontab
- At runtime, `run-task.sh` pipes the task file to Claude with the right CLI flags
- Logs go to `data/logs/<task>/`, rotated to the last 50 runs
- Failed tasks send an email via exe.dev's built-in gateway

## Skills

| Skill | What it does |
|-------|-------------|
| `/deploy` | Reads task files, generates and installs the crontab |
| `/send-email` | Sends an email via exe.dev's gateway |
| `/list-tasks` | Shows all tasks with schedules and recent run status |

## MCP Servers

MCP servers give your tasks access to external services like GitHub, Slack, etc.

Run these commands **on the VM, from `~/claude-cron`**. Secrets are stored in `~/.claude.json` on the VM — never in the repo.

### Example: GitHub (remote)

```bash
cd ~/claude-cron
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_PAT"
```

Create a [Personal Access Token](https://github.com/settings/tokens) with the scopes your tasks need.

### Example: any HTTP MCP server

```bash
cd ~/claude-cron
claude mcp add --transport http NAME URL \
  --header "Authorization: Bearer YOUR_TOKEN"
```

### Verify

```bash
claude mcp list
```

Then just mention the service in your task prompt — Claude will use the MCP server automatically.

## Repo Structure

```
claude-cron/
  .claude/skills/
    deploy/SKILL.md
    send-email/SKILL.md
    list-tasks/SKILL.md
  .github/workflows/
    deploy.yml.example
  scripts/
    run-task.sh
    setup.sh
    update.sh
  tasks/
    your-tasks-here.md
  CLAUDE.md
```
