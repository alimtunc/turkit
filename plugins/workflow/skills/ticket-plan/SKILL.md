---
name: ticket-plan
description: Write a structured plan to `.claude/plans/<TICKET>.md` for operator review before any code. Scans the workspace for reuse opportunities. Does not modify code. Ends by emitting a fresh-session prompt for `ticket-execute`.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Read, Grep, Glob, Write, Edit
---

# Ticket Plan

Produce a written plan for a ticket so the operator can validate the approach **before** any code is written.

## Steps

1. **Resolve the ticket.** Via `docs/contracts/issue-tracker-detection.md`, or accept an explicit ID as argument. Fetch title + body.

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

4. **Write the plan** to `.claude/plans/<TICKET-ID>.md` (create the directory if missing). Structure:

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
   - Project rules: <docs/rules loaded and the highest-risk rule for this ticket>
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

5. **Emit the fresh-session prompt and stop.** Do not implement. Do not invoke `ticket-execute`. The operator reviews the plan, then starts a new session and pastes the prompt below.

   Print exactly this block (substituting the ticket id) as the final output:

   ```
   Plan écrit : .claude/plans/<TICKET-ID>.md

   Reprends dans une nouvelle session avec :
   ---
   Invoque ticket-execute sur <TICKET-ID>. Le plan est dans .claude/plans/<TICKET-ID>.md.
   ---
   ```

## Guardrails

- No code changes. Only `.claude/plans/<TICKET-ID>.md` is written.
- If `.claude/plans/<TICKET-ID>.md` already exists, read it first, then propose updates as a diff rather than overwriting silently.
- Never auto-invoke `ticket-execute`. The fresh-session boundary is intentional: it forces the operator to review the plan before code is written.
- Respond in the conversation's language by default.
