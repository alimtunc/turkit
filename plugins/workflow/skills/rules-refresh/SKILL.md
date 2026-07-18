---
name: rules-refresh
description: Audit a rules document (SKILL.md, CLAUDE.md, AGENTS.md, or convention doc) and propose updates that leverage what the current Claude version knows natively. Classifies each rule as Keep / Sharpen / Add-rationale / Redundant / Stale, proposes Missing rules from the shared quality baseline, and applies all proposed changes only on one explicit confirmation. A guided --interactive mode replaces the batch confirmation with per-rule decisions.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Rules Refresh

Audit a rules document and propose a tighter version. Writes only after a single explicit confirmation.

## Input

- Optional path argument (e.g., `plugins/react/skills/react-review/SKILL.md`, `CLAUDE.md`, `docs/conventions/frontend.md`).
- Optional `--interactive` flag: run the guided per-rule session (see Interactive Mode) instead of the batch audit.
- If omitted: scan the repo for candidate files (any `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `docs/conventions/*.md`, `docs/contracts/*.md`) and ask the operator which one to refresh.

## Steps (batch — default)

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

3. **Diff against the baseline.** When the target is a project rules doc (`CLAUDE.md`, `AGENTS.md`, `docs/conventions/*.md` — not a `SKILL.md`), read [`references/rules-baseline.md`](references/rules-baseline.md) and list baseline rules with no equivalent in the target as **Missing** proposals. Skip any rule the project has documented a tradeoff against. Missing proposals come from the baseline verbatim or sharpened for the repo's stack, never free-form.

4. **Emit a single audit report** with all buckets visible. Format below.

5. **Ask once**: *"Apply all proposed changes? [y/n]"*. Never apply without explicit yes. Never apply partial subsets — the audit is all-or-nothing from the operator's perspective. If they want partial, they decline and rerun on a narrower scope.

6. **On yes**: rewrite the target file in place. Preserve frontmatter, headings, and non-rule prose. Commit is NOT automatic — the operator commits after manual verification.

## Interactive Mode (`--interactive`)

Guided per-rule session over a project rules doc. Batch stays the default; this mode replaces its all-or-nothing confirmation with one decision per rule.

1. **State of play.** Resolve the target doc (path argument, else `.turkit.yaml → rules.docs`, else the Input scan). Summarize in ≤5 lines: docs found, rule count, baseline coverage by section (e.g. "6/10 sections covered; missing: Simplification, Types, Boundaries, Error Handling").

2. **Menu.** Offer the applicable paths, omitting empty ones:

   ```text
   1. Add missing baseline rules (<n> sections)
   2. Sharpen existing rules (<n> candidates)
   3. Add a project rule (operator describes, skill formulates)
   4. Record a documented tradeoff (reviews stop flagging it)
   5. Prune (<n> redundant/stale candidates)
   ```

   Use the platform's structured-question UI when available; plain text otherwise. When a path completes, return to the menu until the operator stops.

3. **Per-rule loop.** For each item on the chosen path, show one concrete proposal, then ask: **accept / rephrase / skip**.
   - **accept** → apply immediately to the doc (unstaged), move on.
   - **rephrase** → the operator adjusts or dictates; reformulate as one checkable line plus `Why:`, confirm once more, apply.
   - **skip** → record it; never re-propose in this session.

4. **Proposal sources** — these three, nothing else:
   - **Baseline** — Missing rules from `references/rules-baseline.md`, section by section.
   - **Repo evidence** — a dominant convention not yet written down, proposed only with cited evidence (files and occurrence counts, e.g. "14 files import via `@/lib`, 2 use deep relative paths → alias rule?"). Never propose from impression alone.
   - **Operator free-form** — the operator asks for a rule; formulate it as one checkable line plus `Why:`. Explicit operator request replaces the baseline requirement.

5. **Session recap.** Added / sharpened / tradeoffs recorded / pruned / skipped, then the manual-commit reminder.

Tradeoffs (path 4) land where the target doc keeps them — a `Tradeoffs` section, or an inline `Why:` on the overridden rule. Reviews suppress documented tradeoffs, so recording one here is the legitimate way to silence a recurring finding.

## Audit report format

```
Rules refresh — <path>
<N> rules total: Keep=<k> Sharpen=<s> Add-rationale=<a> Redundant=<r> Stale=<st> Missing=<m>

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

MISSING (from rules-baseline.md — project rules docs only)
- Baseline rule: <rule>
  Proposed addition: <verbatim or sharpened for this repo>
```

Apply `references/output-preferences.md` for operator-facing language/style.

## Guardrails

- **Read-only until confirmation.** Never write before the operator says yes.
- **Self-audit footgun.** If the operator points `rules-refresh` at its own `SKILL.md` (the file you are reading now), refuse and ask for an explicit confirmation naming the file. Auditing the auditor risks breaking the audit logic.
- **No partial apply (batch mode).** All or nothing; a subset means decline and rerun. In `--interactive`, consent is per rule — partial is the design.
- **Commit discipline.** Do not commit the rewrite. Leave it for the operator to verify and commit via `/turkit:ship` or manually.
- **Never invent rules.** Every proposal traces to the input file, `references/rules-baseline.md`, cited repo evidence, or an explicit operator request (interactive mode). No silent free-form rules.
- **Interactive writes are per-confirmation.** Nothing lands before its own accept; a skip is final for the session.
