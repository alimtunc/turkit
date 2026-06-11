# Plan Templates

Single source of truth for ticket plan markdown. Consumed by `ticket-plan`, `ticket-triage`, and `ticket`. Pick the section that matches the chosen path: a full plan for plan-then-execute, a one-shot mini-plan for a single well-understood change, or a split sub-plan file per piece when a ticket is decomposed locally.

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

## Split sub-plan

When a ticket genuinely mixes unrelated concerns, decompose it into local sub-ticket plan files **in the repo** under `.claude/plans/` — never as tracker issues. One file per piece, named `<TICKET-ID>-1.md`, `<TICKET-ID>-2.md`, …, each a full plan in its own right:

```markdown
# <TICKET-ID>-<n> — <short title>

## Résumé (reformulé)
<2–3 lines describing intent>

## Critères d'acceptation
1. <precise, verifiable criterion>
2. ...

## Fichiers à toucher
- `path/to/file` — <what + approach>

## Reuse check
- <existing modules/helpers/components reused, or "none">

## Depends on
<other sub-ticket file, or "none">
```

Present the full set at the plan-approval pause. On approval, execute each sub-ticket plan in dependency order, in the same session.
