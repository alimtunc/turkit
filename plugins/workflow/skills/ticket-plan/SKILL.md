---
name: ticket-plan
description: Write a structured plan to `.claude/plans/<TICKET>.md` for operator review before any code. Scans the workspace for reuse opportunities. Does not modify code. Does not auto-invoke ticket-execute.
---

# Ticket Plan

Produce a written plan for a ticket so the operator can validate the approach **before** any code is written.

## Steps

1. **Resolve the ticket.** Via `docs/contracts/issue-tracker-detection.md`, or accept an explicit ID as argument. Fetch title + body.

2. **Scan the workspace for reuse.** Before designing, look for:
   - Existing modules/components that solve a similar problem.
   - Patterns the codebase already uses for this class of change.
   - Utility functions whose signature fits the new work.

   Prefer reusing over re-inventing. If reuse is unsuitable, say *why* in the plan.

3. **Write the plan** to `.claude/plans/<TICKET-ID>.md` (create the directory if missing). Structure:

   ```markdown
   # <TICKET-ID> — <short title>

   ## Context
   <1–3 sentences: what the ticket asks for, in our words>

   ## Acceptance criteria
   - [ ] <criterion 1>
   - [ ] <criterion 2>

   ## Approach
   <2–5 paragraphs: key design decisions, trade-offs considered>

   ## Reuse
   <list of existing code we'll leverage, or explicit "no reuse" with reason>

   ## Files to touch
   - Create: `path/to/new.ext` — <responsibility>
   - Modify: `path/to/existing.ext:L–L` — <change>

   ## Risks / unknowns
   - <risk 1>
   - <risk 2>

   ## Out of scope
   - <thing we deliberately aren't doing here>
   ```

4. **Stop.** Do not implement. Do not invoke `ticket-execute`. Tell the operator the plan path and ask them to review.

## Guardrails

- No code changes. Only `.claude/plans/<TICKET-ID>.md` is written.
- If `.claude/plans/<TICKET-ID>.md` already exists, read it first, then propose updates as a diff rather than overwriting silently.
- Respond in the conversation's language by default.
