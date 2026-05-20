---
name: ticket-triage
description: Entry point for any ticket. Fetches the issue (if a tracker is available), evaluates scope, picks the path (one-shot / plan-then-execute / split-first), and dispatches the next skill in the same session. Only plan-then-execute requires a fresh session for execution.
---

# Ticket Triage

Route a ticket toward the right workflow **and dispatch it in the same session**.

- **one-shot** → triage writes a minimal plan then auto-invokes `ticket-execute` here and now.
- **plan-then-execute** → triage auto-invokes `ticket-plan` here and now. `ticket-plan` ends by printing a fresh-session prompt for `ticket-execute`. Operator runs that in a new session.
- **split-first** → triage writes a split proposal and stops. No implementation.

## Steps

1. **Resolve the ticket.**
   - Accept an explicit ticket ID as argument, **or**
   - Detect via `docs/contracts/issue-tracker-detection.md`.
   - If no tracker is available, ask the operator for the ticket ID or a short description of the work.

2. **Fetch issue context** if a tracker is available. Read title + body. If not, use the operator-provided description.

3. **Scope the work** and pick one of three paths. Use these heuristics:

   | Path | Signals |
   |---|---|
   | **one-shot** | < 1 hour. One well-understood change. Single file or tight cluster. Clear acceptance criteria. |
   | **plan-then-execute** | 1 hour – 1 day. Multiple files / modules. Some design decisions to make. Tests need thought. |
   | **split-first** | Multi-day. Cuts across unrelated subsystems. Mixes infra + product + tests. Multiple operator reviews needed. |

   If between two options, prefer the heavier one. Operator can downgrade.

4. **Emit the triage report** (block below), then dispatch.

   ```
   Ticket : <TICKET-ID> — <short title>
   Path   : <one-shot | plan-then-execute | split-first>
   Reason : <1–2 sentences>
   ```

5. **Dispatch** based on path. The fresh-session boundary lives **only** between `ticket-plan` and `ticket-execute`. Triage never asks the operator to start a new session and never prints a copy-paste prompt for the next skill — it invokes it.

   - **one-shot** → write a minimal plan to `.claude/plans/<TICKET-ID>.md` (template below), then **invoke `ticket-execute` via the Skill tool in this same session**. Do not stop after the triage report.
   - **plan-then-execute** → **invoke `ticket-plan` via the Skill tool in this same session**. Do not stop after the triage report. Do not print "copy-paste this" or "run `/ticket-plan` next" — that is a bug. `ticket-plan` itself writes the full plan and ends with the fresh-session prompt for `ticket-execute`. Triage never invokes `ticket-execute` directly.
   - **split-first** → write the split proposal to `.claude/plans/<TICKET-ID>-split.md` (template below), display it, and stop. The operator creates the sub-tickets and re-triages each one.

## One-shot minimal plan template

Write to `.claude/plans/<TICKET-ID>.md` before invoking `ticket-execute`:

```markdown
# <TICKET-ID> — <short title>

## Context
<1–2 sentences>

## Acceptance criteria
- [ ] <criterion 1>
- [ ] <criterion 2 if needed>

## Approach
<2–4 lines. One-shot scope means design is obvious.>

## Files to touch
- Modify: `path/to/file` — <change>

## Quality contract
- Reuse: <existing helper/module to use, or "none">
- Ownership: <where new code lives if any>
- Verification: <project check/lint/test command(s)>
```

## Split-first proposal template

Write to `.claude/plans/<TICKET-ID>-split.md`:

```markdown
# <TICKET-ID> — Split proposal

## Reason for split
<why the ticket can't merge as one unit>

## Proposed sub-tickets
### <TICKET-ID>.1 — <title>
Scope: ...
Acceptance criteria:
  1. ...

### <TICKET-ID>.2 — <title>
...
```

## Guardrails

- Never invoke any review skill (`pre-commit-review`, `pre-pr-review`, `ship`, `test-instructions`).
- Split-first never auto-invokes anything.
- **`one-shot` and `plan-then-execute` always auto-invoke the next skill in the same session.** Printing a copy-paste prompt like "`/turkit-workflow:ticket-plan SUP-14`" instead of invoking the skill is a bug — it breaks the workflow by forcing an unnecessary session boundary on the operator.
- If the ticket body is missing or trivially short, ask the operator to flesh it out before choosing a path.
- Respond in the conversation's language by default.
