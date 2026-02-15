---
name: list-tasks
description: "List all claude-cron scheduled tasks, their schedules, and recent run status."
---

List all claude-cron tasks. For each `.md` file in `~/claude-cron/tasks/`:

1. Show the task name (filename without .md)
2. Show the first few lines (the schedule/limits description)
3. Show the crontab entry for this task (from `crontab -l`)
4. Show the last run result (most recent log in `~/claude-cron/data/logs/<task>/`)

Format as a clean table or structured list.
