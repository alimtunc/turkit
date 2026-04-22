---
name: rules-refresh
description: Audit a rules document (SKILL.md, CLAUDE.md, AGENTS.md, or convention doc) and propose updates that leverage what the current Claude version knows natively. Classifies each rule as Keep / Sharpen / Add-rationale / Redundant / Stale, and applies all proposed changes only on one explicit confirmation.
---

# Rules Refresh

Audit a rules document and propose a tighter version. Writes only after a single explicit confirmation.

## Input

- Optional path argument (e.g., `plugins/react/skills/react-review/SKILL.md`, `CLAUDE.md`, `docs/conventions/frontend.md`).
- If omitted: scan the repo for candidate files (any `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `docs/conventions/*.md`, `docs/contracts/*.md`) and ask the operator which one to refresh.

## Steps

1. **Read the target file in full.** Preserve frontmatter boundaries, section headings, and non-rule content — they will not be rewritten.

2. **Classify each rule** into exactly one of five buckets:

   | Bucket | Signal | Action |
   |---|---|---|
   | **Keep** | Rule is valuable, actionable, non-obvious. | Leave unchanged. |
   | **Sharpen** | Valuable but vague or un-checkable ("write clean code"). | Propose a version with explicit, checkable criteria. |
   | **Add rationale** | Concrete rule, missing the *why*. | Propose adding a one-line `Why: <reason>` so edge cases can be reasoned about. |
   | **Redundant** | Claude handles this natively today (naming, formatting, trivial hygiene). | Propose removal with a one-line reason. |
   | **Stale** | References deprecated APIs, old model behavior, abandoned patterns. | Propose replacement or removal. |

   Classification heuristics:
   - Redundant signal: *would I do this without being told?* If yes → redundant.
   - Sharpen signal: rule interpretable two ways, or no checkable criterion. Turn "Keep functions small" into "Flag functions > 40 lines or > 3 nesting levels".
   - Rationale signal: a hidden constraint, past incident, or non-obvious trade-off. If removing the rule would make a junior engineer's code subtly wrong → add rationale.
   - Stale signal: mentions `React.FC` as recommended, `useMemo` everywhere, old lifecycle methods, old Claude version behaviors.
   - When unsure between Redundant and Sharpen, prefer **Sharpen**. Do not delete rules whose rationale you can't reconstruct.

3. **Emit a single audit report** with all five buckets visible. Format below.

4. **Ask once**: *"Apply all proposed changes? [y/n]"*. Never apply without explicit yes. Never apply partial subsets — the audit is all-or-nothing from the operator's perspective. If they want partial, they decline and rerun on a narrower scope.

5. **On yes**: rewrite the target file in place. Preserve frontmatter, headings, and non-rule prose. Commit is NOT automatic — the operator commits after manual verification.

## Audit report format

```
Rules refresh — <path>
<N> rules total: Keep=<k> Sharpen=<s> Add-rationale=<a> Redundant=<r> Stale=<st>

KEEP
- <rule snippet>
- ...

SHARPEN
- Before: <vague rule>
  After:  <sharpened rule>
  Why: <one-line rationale for the change>

ADD RATIONALE
- Rule: <rule snippet>
  Proposed addition: "Why: <reason>"

REDUNDANT
- Rule: <rule snippet>
  Reason: <why Claude handles this natively now>

STALE
- Rule: <rule snippet>
  Problem: <what changed>
  Proposed replacement: <new rule> | REMOVE
```

Respond in the conversation's language by default.

## Guardrails

- **Read-only until confirmation.** Never write before the operator says yes.
- **Self-audit footgun.** If the operator points `rules-refresh` at its own `SKILL.md` (the file you are reading now), refuse and ask for an explicit confirmation naming the file. Auditing the auditor risks breaking the audit logic.
- **No partial apply.** All or nothing. If the operator wants a subset, they rerun.
- **Commit discipline.** Do not commit the rewrite. Leave it for the operator to verify and commit via `/turkit-workflow:ship` or manually.
- **Never invent rules** that weren't in the input file. `rules-refresh` only proposes changes to existing rules, not net-new ones.
