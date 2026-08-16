---
description: Run the operator-invoked ticket workflow.
argument-hint: "[--auto|--triage|--plan|--execute] [--grill] [--fast] [ticket-id | tracker-url | free-form description]"
allowed-tools: Skill
---

# Ticket

Invoke the `ticket` skill with `$ARGUMENTS`.

The skill is the sole source of truth for ticket behavior and guardrails; do not restate or implement the workflow in this command.
