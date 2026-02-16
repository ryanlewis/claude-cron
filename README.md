# claude-cron

Run Claude Code on a schedule. Write tasks as markdown files. Push to deploy.

Designed for quick setup on [exe.dev](https://exe.dev) VMs ($20/mo). Works on any Linux machine — see [Running on Your Own Machine](#running-on-your-own-machine).

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

## Running on Your Own Machine

The core system is just cron + the Claude CLI — it works anywhere Linux runs. A few pieces are wired to exe.dev's infrastructure and need adapting if you're running elsewhere:

- **Failure alert email** (`scripts/run-task.sh`) — On failure, the task runner sends an alert via exe.dev's metadata gateway (`curl 169.254.169.254/gateway/email/send`). Replace the curl block with `sendmail`, an SMTP call, or remove it if you don't need failure alerts.
- **`/send-email` skill** (`.claude/skills/send-email/`) — Tasks that send email use this skill, which wraps the same gateway. Rewrite it for your mail setup or delete it if your tasks don't send email.
- **Email config in `CLAUDE.md`** — The `Email` section documents the gateway endpoint and inbound mail (`~/Maildir`). Update or remove it to match your environment.
- **CI workflow** (`.github/workflows/deploy.yml.example`) — Uses `EXE_DEV_*` secrets to SSH into the VM and redeploy. Rename the variables and update the SSH target to point at your machine.

Everything else — task files, the `/deploy` skill, `run-task.sh`, log rotation, `setup.sh` — is portable as-is.

## Usage & Terms

This project uses the official Claude Code CLI in headless mode (`-p`), a documented and supported feature. It's just cron + the real CLI.

A few things to be aware of:

- **Pro/Max subscriptions:** Scheduled tasks count against the same rolling usage window as interactive Claude Code and claude.ai. Use the safeguards available — `timeout`, model choice, scheduling frequency — to limit execution.
- **API keys:** Usage is billed per-token at standard API rates. No rolling windows — the better option for high-volume or mission-critical automation.
- **Reliability:** Tasks depend on external sites and LLM output. They may fail or produce incorrect results — don't rely on this for anything critical.
- **Terms:** Anthropic's [Consumer Terms of Service](https://www.anthropic.com/legal/consumer-terms) govern subscription usage. This project is a scheduling wrapper — you're responsible for ensuring your usage complies with their terms.

## Extending

You can give your tasks extra capabilities with skills, MCP servers, and plugins. These let Claude interact with external services, follow custom workflows, or use specialised tools.

### Skills

Skills are prompt files that teach Claude reusable workflows. claude-cron ships with three built-in skills:

| Skill | What it does |
|-------|-------------|
| `/deploy` | Reads task files, generates and installs the crontab |
| `/send-email` | Sends an email via exe.dev's gateway |
| `/list-tasks` | Shows all tasks with schedules and recent run status |

Add your own by creating a `SKILL.md` in `.claude/skills/your-skill/`:

```markdown
---
name: your-skill
description: "What this skill does"
---

Instructions for Claude to follow when this skill is invoked.
```

### MCP Servers

MCP servers give your tasks access to external services like GitHub, Slack, etc.

Run these commands **on the VM, from `~/claude-cron`**. Secrets are stored in `~/.claude.json` on the VM — never in the repo.

**GitHub (remote):**

```bash
cd ~/claude-cron
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_PAT"
```

Create a [Personal Access Token](https://github.com/settings/tokens) with the scopes your tasks need.

**Any HTTP MCP server:**

```bash
cd ~/claude-cron
claude mcp add --transport http NAME URL \
  --header "Authorization: Bearer YOUR_TOKEN"
```

**Verify:** `claude mcp list`

Then just mention the service in your task prompt — Claude will use the MCP server automatically.

### Plugins

Any Claude Code plugins you've installed are available to your tasks automatically.

For example, the official [code-review](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) plugin gives your tasks access to `/code-review`. A task could use it like:

```markdown
Run every hour during working hours. Max 50 turns.

Check https://github.com/you/project for open PRs that haven't been reviewed.
Run /code-review on each one.
```

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
