---
name: ticket-triage
description: Entry point for any ticket. Fetches the issue (if a tracker is available), evaluates scope, picks the path (one-shot / plan-then-execute / split-first), and dispatches the next skill in the same session. Only plan-then-execute requires a fresh session for execution.
---

# Ticket Triage

Route a ticket toward the right workflow **and dispatch it in the same session**.

- **one-shot** → triage writes a minimal plan then auto-invokes `ticket-execute` here and now.
- **plan-then-execute** → triage auto-invokes `ticket-plan` here and now. `ticket-plan` ends by printing a fresh-session prompt for `ticket-execute`. Operator runs that in a new session.
- **split-first** → triage writes a split proposal and stops. No implementation.

## Format de sortie obligatoire — LIS CECI EN PREMIER

Triage est un dispatcher. Sa sortie n'est **jamais** un résumé du travail à venir — c'est soit le bloc de sortie du skill dispatché (one-shot / plan-then-execute), soit le bloc strict de split-first.

### Pour `one-shot` et `plan-then-execute`

Le dernier bloc visible à l'opérateur est celui émis par `ticket-execute` (handoff) ou `ticket-plan` (fresh-session prompt). **Triage n'ajoute rien après.** Pas de récap, pas de "scope walkbacks resolved", pas de "architecture summary", pas de "ready for review". Le triage report (étape 4) sort avant le dispatch ; ensuite tu laisses le skill dispatché parler en dernier.

### Pour `split-first`

Le dernier message est **exactement** ce bloc, et **rien d'autre après** :

````
✅ Split proposé — `.claude/plans/<TICKET-ID>-split.md`

Prochaine action — crée les sous-tickets dans le tracker, puis re-triage chacun avec ce prompt :

```
/turkit-workflow:ticket-triage <SOUS-TICKET-ID>
```
````

Pas de résumé du split dans le chat — le fichier parle de lui-même. Une seule fence interne, copy/paste en un clic.

### Anti-pattern observé (NE JAMAIS reproduire)

Tu viens de dispatcher `ticket-plan` et tu vas avoir envie de résumer le plan que ton sous-skill vient d'écrire. Ne le fais pas. Voici exactement le type d'output qui a déjà cassé ce skill en prod après dispatch et qui ne doit jamais revenir :

> Plan written to .claude/plans/SUP-28.md.
> Triage decision: plan-then-execute.
> Plan summary (10 ACs):
> - Append a second SettingsItem ("Delete my account")…
> - Build DeleteAccountWarning.tsx…
> - …
> Key walkback decisions: …
> Risks flagged: …
> Ready for operator review. Next step is ticket-execute once you approve.

Quatre violations :
1. **Résume le plan** au lieu de pointer vers le fichier que `ticket-plan` vient d'écrire.
2. **Ne propose aucun prompt copy/paste** pour la nouvelle session — `ticket-plan` est censé l'avoir fait, et si tu ajoutes ce narratif derrière, tu détruis son bloc copiable.
3. **Finit par une phrase** ("Ready for operator review…") au lieu de laisser la fence interne du sous-skill en dernier.
4. **Propose une condition** ("once you approve") au lieu d'une action directe et copiable.

Ton output correct après dispatch est exactement ce qu'a émis le sous-skill, point. Tu ne touches à rien après.

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

5. **Dispatch** based on path. The fresh-session boundary lives **only** between `ticket-plan` and `ticket-execute`. Triage never asks the operator to start a new session for `ticket-plan` and never prints a copy-paste prompt for the next skill — it invokes it.

   - **one-shot** → write a minimal plan to `.claude/plans/<TICKET-ID>.md` (template below), then **invoke `ticket-execute` via the Skill tool in this same session**. Tu n'ajoutes rien après le retour du sous-skill — son handoff block est le dernier message.
   - **plan-then-execute** → **invoke `ticket-plan` via the Skill tool in this same session**. `ticket-plan` writes the plan AND emits the fresh-session prompt. Tu n'ajoutes rien après son retour — son bloc fence est le dernier message. Pas de résumé du plan, pas de récap des ACs, pas de "scope walkbacks resolved".
   - **split-first** → write the split proposal to `.claude/plans/<TICKET-ID>-split.md` (template below), then émets le bloc de split-first défini en haut, puis arrête.

## One-shot minimal plan template

Use the `## One-shot mini-plan` section of `../../references/plan-template.md`. Write to `.claude/plans/<TICKET-ID>.md` before invoking `ticket-execute`.

## Split-first proposal template

Use the `## Split sub-plan` section of `../../references/plan-template.md`. Write to `.claude/plans/<TICKET-ID>-split.md`.

## Guardrails

- Never invoke any review skill (`pre-commit-review`, `pre-pr-review`, `ship`, `test-instructions`).
- Split-first never auto-invokes anything.
- **`one-shot` and `plan-then-execute` always auto-invoke the next skill in the same session.** Printing a copy-paste prompt like "`/turkit-workflow:ticket-plan SUP-14`" instead of invoking the skill is a bug — it breaks the workflow by forcing an unnecessary session boundary on the operator.
- **After dispatching `ticket-plan` or `ticket-execute`, add nothing.** Voir la section "Format de sortie obligatoire" en haut et l'anti-pattern qui suit. La dernière fence interne de la conversation doit être un copy/paste propre en un clic, émise par le sous-skill.
- If the ticket body is missing or trivially short, ask the operator to flesh it out before choosing a path.
- Respond in the conversation's language by default.
