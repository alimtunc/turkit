# Plan Templates

Single source of truth for ticket plan markdown. Consumed by `ticket`. Every `--plan` run writes exactly one canonical file at the agent-agnostic local path `docs/plans/<TICKET-ID>.md`: use the full plan for a standard ticket or the mini-plan for a one-shot ticket. Same-session one-shot flows may keep the mini-plan inline. Plans wait for approval in manual mode or continue immediately under `--auto` unless genuinely blocked.

## Full plan

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

## One-shot mini-plan

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

Tickets that genuinely mix unrelated scopes are not planned. Stop and recommend separate tickets instead of creating sub-plans.
