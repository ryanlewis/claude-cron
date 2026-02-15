# claude-cron

Run Claude Code on a schedule. Clone the repo, run setup on an [exe.dev](https://exe.dev) VM, start writing tasks as natural language markdown files. Push to deploy.

## Getting Started

### 1. Create your repo

Use this as a template or fork it. This is your task repo — you'll commit task files and skills here.

### 2. Run setup on the box

SSH into your exe.dev VM, authenticate your tools, clone your repo, and run setup:

```bash
ssh vmname.exe.xyz

# Auth — do this yourself before setup
# Set ANTHROPIC_API_KEY in ~/.claude/settings.local.json (under the "env" key)
gh auth login   # if tasks use GitHub

# Clone and setup
git clone https://github.com/you/claude-cron ~/claude-cron
~/claude-cron/scripts/setup.sh
```

Setup creates data directories and runs `/deploy` (which generates the crontab).

### 3. Start writing tasks

Create a `.md` file in `tasks/`, describe what you want and when:

```markdown
Run every weekday at 9am UTC. Max 10 turns, $1 budget. Use haiku.

Check https://github.com/you/project for open PRs older than 7 days.
Post a reminder comment on each one. Email me a summary.
```

Then deploy — either manually on the VM or via CI (see below):

```bash
# On the VM
~/claude-cron/scripts/update.sh
```

## Task Format

A task is a single markdown file — a natural language prompt that includes its own scheduling and execution config as prose. No YAML required (but optional frontmatter is supported too):

```markdown
---
schedule: "*/30 9-17 * * 1-5"
max-turns: 5
timeout: 600
model: claude-haiku-4-5-20251001
---

Check CI status for the main branch. If any checks are failing,
open an issue with the failure details.
```

## How It Works

- **Claude-as-deployer**: the deploy step is itself a Claude invocation that reads task files and generates the crontab
- **Thin wrapper**: `run-task.sh` handles logging, timeout, and failure emails — no config parsing
- **Manual deploy**: SSH in and run `scripts/update.sh` (pulls latest + runs `/deploy`)
- **Optional CI**: set up GitHub Actions to deploy on push (see below)

## Skills

| Skill | Description |
|-------|-------------|
| `/deploy` | Read task files, generate and install the crontab |
| `/send-email` | Send an email via exe.dev's gateway |
| `/list-tasks` | Show all tasks with schedules and recent run status |

## MCP Servers

Configure MCP servers at local scope on the VM:

```bash
claude mcp add discord https://mcp.discord.com/...
```

Or edit `~/.claude.json` directly. Local-scoped servers have no confirmation prompts, which is required for headless automation.

## CI Deploy (Optional)

To auto-deploy on push to main, copy the example workflow into place:

```bash
cp .github/workflows/deploy.yml.example .github/workflows/deploy.yml
```

Then add these to your GitHub repo settings (Settings > Secrets and variables > Actions):

| Type | Name | Value |
|------|------|-------|
| Variable | `EXE_DEV_HOST` | `vmname.exe.xyz` |
| Variable | `EXE_DEV_USER` | `user` (or your VM username) |
| Secret | `EXE_DEV_SSH_KEY` | Your SSH private key |

Pushes to `main` will SSH into the VM, pull the repo, and run `claude -p /deploy`.

## Repo Structure

```
claude-cron/
  ├── .github/workflows/deploy.yml.example
  ├── CLAUDE.md
  ├── scripts/
  │   ├── run-task.sh
  │   ├── setup.sh
  │   └── update.sh
  ├── skills/
  │   ├── deploy/SKILL.md
  │   ├── send-email/SKILL.md
  │   └── list-tasks/SKILL.md
  └── tasks/
      └── your-tasks-here.md
```
