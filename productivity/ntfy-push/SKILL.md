---
name: ntfy-push
description: Send an ntfy push notification to the user's smartphone when a task is completed and ready for review or blocked waiting for user input. Use when finished assigned work or when a question, decision, or clarification blocks progress.
compatibility: Works with any coding agent with shell access to curl or PowerShell. No additional dependencies.
metadata:
  version: "1.0.0"
---

# Ntfy Push Notifications

Send a push notification via the ntfy HTTP API whenever the user's attention or interaction is required. Fire in exactly two situations, immediately when the condition occurs.

## Configuration

Keep configurable; do not hardcode beyond defaults:

- `NTFY_BASE_URL`: default `https://ntfy.sh`
- `NTFY_TOPIC`: default `drskelettos-dev-agents` (override via env var `NTFY_TOPIC` when the user asks for a different topic)

No additional dependencies. Use the ntfy HTTP API directly with `curl` (Linux/macOS/Git Bash) or `Invoke-RestMethod` (Windows PowerShell).

## When to send (exactly two cases)

1. **Task completed:** the assigned task is done and ready for review or further instructions. Title: `Task Completed`.
2. **User input required:** a question, decision, missing info, or ambiguity blocks progress and the agent cannot proceed without the user. Title: `Input Required`.

## When NOT to send

- Routine progress updates, intermediate steps, or status chatter.
- Background operations that do not require interaction.
- More than one notification per blocking event or per completed task.

## Message format

- Keep concise (1-2 lines) and informative: state why attention is needed and what happens next.
- Include the task or project name when available, e.g. `[lifesim] ...`.
- Title header carries the case; body carries the detail.

Examples:

- Title `Task Completed`, body `[lifesim] Implementation of <task> done, ready for review.`
- Title `Input Required`, body `[lifesim] Blocked on <question/decision>: <one-line context>. Awaiting your answer.`

## How to send

Never let a notification failure interrupt the workflow. Use a short timeout and swallow errors (`|| true` / `try-catch`), then continue the task regardless of the result.

Bash / curl:

```bash
NTFY_BASE_URL="${NTFY_BASE_URL:-https://ntfy.sh}"
NTFY_TOPIC="${NTFY_TOPIC:-drskelettos-dev-agents}"
curl -s --max-time 10 -o /dev/null \
  -H "Title: Task Completed" -H "Priority: 4" \
  -d "[lifesim] <concise completion summary>" \
  "$NTFY_BASE_URL/$NTFY_TOPIC" || true
```

For input required, change the title and body (keep `Priority: 4`):

```bash
curl -s --max-time 10 -o /dev/null \
  -H "Title: Input Required" -H "Priority: 4" \
  -d "[lifesim] Blocked: <question> (<context>)" \
  "$NTFY_BASE_URL/$NTFY_TOPIC" || true
```

Windows PowerShell:

```powershell
$base = if ($env:NTFY_BASE_URL) { $env:NTFY_BASE_URL } else { "https://ntfy.sh" }
$topic = if ($env:NTFY_TOPIC) { $env:NTFY_TOPIC } else { "drskelettos-dev-agents" }
try {
  Invoke-RestMethod -Uri "$base/$topic" -Method Post `
    -Headers @{ Title = "Task Completed"; Priority = "4" } `
    -Body "[lifesim] <concise completion summary>" -TimeoutSec 10 | Out-Null
} catch { }
```

Replace `Task Completed` with `Input Required` and describe the blocking question when blocked. Always send `Priority = "4"`.
