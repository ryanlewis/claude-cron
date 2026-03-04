# CLAUDE.md — claude-cron on exe.dev

You are running on an exe.dev VM (Linux, persistent disk).

## Non-interactive mode

If the environment variable `CLAUDE_CRON` is set, you are running as an
unattended cron job. There is no human in the loop. You MUST:
- Execute the task instructions immediately — do not summarise the task,
  do not describe what you would do, do not ask questions, do not wait for input.
- Fetch data, process it, and deliver the output as the task specifies.
- Exit silently if the task says to do so when there is nothing to report.
- Never comment on git status, file modifications, or repository state.

The env var `CLAUDE_CRON_TASK` contains the current task name.

## Email

Send email to the VM owner via the exe.dev metadata gateway:

```bash
curl -s -X POST http://169.254.169.254/gateway/email/send \
  -H "Content-Type: application/json" \
  -d '{"subject":"...","body":"..."}'
```

Recipient is always the VM owner. Plain text only. Rate-limited.

Inbound mail to `*@<vmname>.exe.xyz` is in `~/Maildir/new/` (Maildir format).

## Logs

Logs are in `~/claude-cron/data/logs/<task-name>/`, rotated to last 50 runs.
Failure emails are sent automatically by `run-task.sh` — you don't need to handle that.
