# CLAUDE.md — claude-cron on exe.dev

You are running as a scheduled task on an exe.dev VM (Linux, persistent disk).
This is an unattended, non-interactive execution — there is no human in the loop.

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
