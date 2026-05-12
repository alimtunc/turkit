---
name: ticket-plan
description: Write a structured plan to `.claude/plans/<TICKET>.md` for operator review before any code. Scans the workspace for reuse opportunities. Does not modify code. Does not auto-invoke ticket-execute.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Read, Grep, Glob, Write, Edit
---

# Ticket Plan

Produce a written plan for a ticket so the operator can validate the approach **before** any code is written.

## Steps

1. **Resolve the ticket.** Via `docs/contracts/issue-tracker-detection.md`, or accept an explicit ID as argument. Fetch title + body.

2. **Scan the workspace for reuse and ownership.** Before designing, look for:
   - Existing modules/components that solve a similar problem.
   - Patterns the codebase already uses for this class of change.
   - Utility functions whose signature fits the new work.
   - The correct ownership home for new helpers, types, constants, schemas, and tests.
   - Stack-specific quality gates that should apply (for example `react-doctor` for React projects).

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

   ## Quality contract
   - Reuse: <existing modules/helpers/components to reuse, or "none" with reason>
   - Ownership: <where helpers/types/constants/schemas/components belong; call out what must not be colocated>
   - Boundaries: <module/layer/import boundaries that must not be crossed>
   - Verification: <check/lint/test/build/manual checks required before handoff>
   - Stack-specific gates: <e.g. react-doctor/react-review when React files are touched, or "none">

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
