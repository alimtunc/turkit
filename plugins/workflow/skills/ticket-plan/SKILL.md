---
name: ticket-plan
description: Write a structured plan to `.claude/plans/<TICKET>.md` for operator review before any code. Scans the workspace for reuse opportunities. Does not modify code. Ends by emitting a fresh-session prompt for `ticket-execute`.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Read, Grep, Glob, Write, Edit
---

# Ticket Plan

Produce a written plan for a ticket so the operator can validate the approach **before** any code is written.

## Format de sortie obligatoire — LIS CECI EN PREMIER

Ton message final, après avoir écrit le plan, est **exactement** ce bloc, et **rien d'autre** :

````
✅ Plan écrit — `.claude/plans/<TICKET-ID>.md`

Prochaine action — ouvre une nouvelle session et colle ce prompt :

```
Invoque ticket-execute sur <TICKET-ID>. Le plan est dans .claude/plans/<TICKET-ID>.md.
```
````

Pas de phrase d'intro avant. Pas de phrase de conclusion après. Pas de résumé du plan. Le plan écrit dans `.claude/plans/<TICKET-ID>.md` parle de lui-même — l'opérateur l'ouvre s'il veut le détail.

### Anti-pattern observé (NE JAMAIS reproduire)

Tu viens d'écrire un gros plan et tu vas avoir envie de le résumer dans le chat. Ne le fais pas. Voici exactement le type d'output qui a déjà cassé ce skill en prod et qui ne doit jamais revenir :

> Plan written to .claude/plans/SUP-28.md.
> Triage decision: plan-then-execute.
> Plan summary (10 ACs):
> - Append a second SettingsItem ("Delete my account") to the existing PrivacySection…
> - Build DeleteAccountWarning.tsx as the UX-DR26-named sheet…
> - New personal-data-wipe.ts orchestrator that cancels the scheduled commitment notification…
> - …
> Key walkback decisions (documented):
> - "Deletion window" → immediate device-local wipe…
> - …
> Risks flagged: Turkish locale-aware uppercase, bodyList i18next array typing…
> Ready for operator review. Next step is ticket-execute once you approve.

Ce format viole quatre règles :
1. Il **résume le plan** au lieu de pointer vers le fichier (l'opérateur peut lire `.claude/plans/SUP-28.md` lui-même).
2. Il **ne fournit aucun prompt copy/paste** pour la nouvelle session — l'opérateur doit demander "donne-moi le prompt" à la main.
3. Il **finit par une phrase** ("Ready for operator review…") au lieu d'un bloc fence copiable.
4. Il **propose plusieurs prochaines actions** ("once you approve") au lieu d'une seule action concrète.

Ton output correct, pour le même plan, est exactement :

````
✅ Plan écrit — `.claude/plans/SUP-28.md`

Prochaine action — ouvre une nouvelle session et colle ce prompt :

```
Invoque ticket-execute sur SUP-28. Le plan est dans .claude/plans/SUP-28.md.
```
````

Trois lignes utiles, une fence copiable, fin. C'est tout.

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

5. **Émets le bloc de sortie strict défini en haut, puis arrête.** Rien d'autre. Pas de résumé, pas de "ready for review", pas de récap des ACs, pas d'alternative.

## Guardrails

- No code changes. Only `.claude/plans/<TICKET-ID>.md` is written.
- If `.claude/plans/<TICKET-ID>.md` already exists, read it first, then propose updates as a diff rather than overwriting silently.
- Never auto-invoke `ticket-execute`. The fresh-session boundary is intentional: it forces the operator to review the plan before code is written.
- Respond in the conversation's language by default — sauf pour le bloc de sortie qui reste tel quel (le format est universel et copy/pasteable).
