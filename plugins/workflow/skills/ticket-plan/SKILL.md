---
name: ticket-plan
description: Write a structured plan to `.claude/plans/<TICKET>.md` for operator review before any code. Scans the workspace for reuse opportunities. Does not modify code. Ends by emitting a fresh-session prompt for `ticket-execute`.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Read, Grep, Glob, Write, Edit
---

# Ticket Plan

Produce a written plan for a ticket so the operator can validate the approach **before** any code is written.

## Required output format — READ THIS FIRST

After writing the plan, your final message is **exactly** this block, and **nothing else**:

````
✅ Plan written — `.claude/plans/<TICKET-ID>.md`

Next action — open a new session and paste this prompt:

```
Invoke ticket-execute on <TICKET-ID>. The plan is in .claude/plans/<TICKET-ID>.md.
```
````

No intro sentence before. No closing sentence after. No summary of the plan. The plan written to `.claude/plans/<TICKET-ID>.md` speaks for itself — the operator opens it if they want the detail.

### Observed anti-pattern (NEVER reproduce)

You just wrote a large plan and you will be tempted to summarize it in the chat. Do not. Here is exactly the kind of output that has already broken this skill in production and must never come back:

> Plan written to .claude/plans/PROJ-42.md.
> Triage decision: plan-then-execute.
> Plan summary (10 ACs):
> - Append a second item to the existing settings section…
> - Build a new confirmation component…
> - New orchestrator module that cancels the scheduled job…
> - …
> Key walkback decisions (documented):
> - "Deletion window" → immediate local wipe…
> - …
> Risks flagged: locale-aware casing, array typing…
> Ready for operator review. Next step is ticket-execute once you approve.

This format violates four rules:
1. It **summarizes the plan** instead of pointing to the file (the operator can read `.claude/plans/PROJ-42.md` themselves).
2. It **provides no copy/paste prompt** for the new session — the operator has to ask for one by hand.
3. It **ends with a sentence** ("Ready for operator review…") instead of a copy-pasteable fence.
4. It **proposes multiple next actions** ("once you approve") instead of one concrete action.

Your correct output, for the same plan, is exactly:

````
✅ Plan written — `.claude/plans/PROJ-42.md`

Next action — open a new session and paste this prompt:

```
Invoke ticket-execute on PROJ-42. The plan is in .claude/plans/PROJ-42.md.
```
````

Three useful lines, one copy-pasteable fence, done. That is all.

## Steps

1. **Resolve the ticket.** Via `references/issue-tracker-detection.md`, or accept an explicit ID as argument. Fetch title + body.

2. **Load project rules.** Read `.turkit.yaml` when present. If it defines
   `rules.docs`, read the listed docs relevant to this ticket. Otherwise use the
   repo defaults when present: `CLAUDE.md`, `AGENTS.md`, and
   `docs/conventions/*.md`. Keep context focused; do not bulk-load unrelated
   large docs.

3. **Scan the workspace for reuse and ownership.** Before designing, look for:
   - Existing modules/components that solve a similar problem.
   - Patterns the codebase already uses for this class of change.
   - Utility functions whose signature fits the new work.
   - The correct ownership home for new helpers, types, constants, schemas, and tests.
   - Stack-specific quality gates that should apply (for example `react-doctor` for React projects).

   Prefer reusing over re-inventing. If reuse is unsuitable, say *why* in the plan.

4. **Write the plan** to `.claude/plans/<TICKET-ID>.md` (create the directory if missing) using the `## Full plan` template in `references/plan-template.md`.

5. **Emit the strict output block defined at the top, then stop.** Nothing else. No summary, no "ready for review", no AC recap, no alternatives.

## Guardrails

- No code changes. Only `.claude/plans/<TICKET-ID>.md` is written.
- If `.claude/plans/<TICKET-ID>.md` already exists, read it first, then propose updates as a diff rather than overwriting silently.
- Never auto-invoke `ticket-execute`. The fresh-session boundary is intentional: it forces the operator to review the plan before code is written.
- Respond in the conversation's language by default — except the output block, which stays as written (the format is universal and copy-pasteable).
