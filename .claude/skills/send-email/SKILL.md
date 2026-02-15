---
name: send-email
description: "Send an email to the VM owner via exe.dev's email gateway."
argument-hint: "<subject>"
---

Send an email using the exe.dev metadata gateway. The recipient is always the VM owner.

Run this command, replacing the subject and body with appropriate content:

```bash
curl -s -X POST http://169.254.169.254/gateway/email/send \
  -H "Content-Type: application/json" \
  -d "{\"subject\":\"$ARGUMENTS\",\"body\":\"<compose the email body here>\"}"
```

- Body must be plain text (no HTML)
- Rate-limited — don't send more than a few emails per task run
