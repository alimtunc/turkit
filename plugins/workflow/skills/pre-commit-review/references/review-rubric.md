# Shared Review Rubric

Use this rubric for language-agnostic reviews. It complements the project's own linter / formatter / type-checker; do not re-flag a line already covered by a mechanical rule unless extra context matters.

The authoring-time mirror of this rubric is `rules-baseline.md`, seeded into project rules docs by `turkit-init` / `adopt-project`. Update the two together.

## Out of Scope

This rubric reviews structure and cleanliness: DRY, separation of concerns, over-engineering, naming, comments, complexity, error-shape hygiene, types, boundaries. It does **not** check security (authorization, tenant isolation, injection), atomicity/races, resource lifetimes, migration/rollout compatibility, or test adequacy. A clean review does not imply any of those; never report them as covered. Route correctness and security review to the project's dedicated tooling.

## Strictness Profiles

Reviews read optional knobs from `.turkit.yaml → review`. All are optional; the defaults reproduce this rubric's standard behavior. Resolve them once before judging, and state the resolved profile in the output (`Strictness: <profile> · Comments: <mode>`).

| Key | Values | Default | Effect |
|---|---|---|---|
| `strictness` | `relaxed` \| `standard` \| `strict` | `standard` | Shifts how aggressively judgment-call findings are surfaced. |
| `comments` | `allow` \| `allow-why-only` \| `zero-new-comments` | `allow-why-only` | Governs the Comments checklist (§5). |

- **`standard`** (default) — apply this rubric exactly as written: P0/P1 as defined below, Suggested for true judgment calls.
- **`relaxed`** — downgrade P1 *cleanup* findings (DRY duplication under 3 occurrences, Over-engineering §3, Complexity §6, Naming §4) to Suggested, and skip §10 Simplification entirely. **Never** downgrade P0 structural violations, behavioral regressions, broken contracts, swallowed errors, or unsafe type escapes — those stay blocking. The Auto-fix bucket is unchanged.
- **`strict`** — promote borderline Suggested findings to P1, treat the §3 Over-engineering and §6 Complexity thresholds as hard (any single-call-site abstraction or >~40-line function is P1, not a judgment call), and promote a §10 Simplification finding with a named behavior-preserving move to P0.

Comments knob (§5):

- **`allow-why-only`** (default) — a one-line *why* comment is acceptable; narrative / history / banner / commented-out / TODO-without-ticket comments introduced by the diff are P0.
- **`zero-new-comments`** — any comment introduced by the diff is P0, including why-comments.
- **`allow`** — only flag comments that are misleading or stale; do not flag an added comment solely because it is new.

If `.turkit.yaml` is absent or omits `review`, use the defaults. Projects opt down or up here instead of editing this rubric.

## Fix Policy

Reviews fix mechanical problems and surface judgment calls. Two buckets only.

### Auto-fix

Apply in place when the fix is mechanical, unambiguous, reversible by reading the diff, and does not change behavior:

- delete comments introduced by the diff that narrate implementation, reference the task/review, contain history, decorative banners, TODOs without tickets, non-project-language prose, multiline internal doc blocks, or commented-out code
- remove debug prints introduced by the diff (`console.log`, `console.debug`, `debugger`, `print`, `dbg!`, `dump`, equivalents)
- remove unused imports introduced by the diff
- fix deep relative imports to the project's established alias/module path when one clearly exists
- move helpers/types/constants out of entry-point/render files only when an obvious existing ownership target exists and the move cannot introduce cycles or public API changes
- replace a new duplicate helper with an import of the existing symbol and delete the duplicate
- remove dead props, parameters, enum variants, options, or wrapper files only after a repo-wide grep of the symbol confirms no caller anywhere — "no caller in the diff/touched files" is not sufficient (spread props, dynamic access, other modules)
- inline one-method `manager` / `service` / `helper` wrappers introduced by the diff

### Required Changes

Surface these; do not auto-fix:

- splitting a function/component/module with mixed responsibilities
- extracting helpers/types/constants when ownership is not obvious, no sibling/shared module exists, or extraction may affect public API/import cycles
- converging duplication across 3+ places when the canonical home/signature needs a design decision
- replacing a typed cast/escape hatch that requires upstream type or validation changes
- adding missing error handling, accessibility semantics, or stable IDs where behavior/UX must be verified
- removing legacy comments/dead code on touched lines unless clearly safe
- behavioral regressions

### Hard Rules

- Never stage, commit, push, amend, rebase, reset, or rewrite history.
- Never edit outside review scope unless an in-scope auto-fix requires a new sibling/shared file.
- If an auto-fix may change behavior, promote it to Required Changes.
- If checks fail after fixes, report residual failures verbatim. Do not revert auto-fixes unless the operator asks.

## Severity

- **P0**: structural violation, behavioral regression, broken contract, silenced error, unsafe type escape, dead public surface, duplicate helper shadowing an existing helper.
- **P1**: must-fix cleanup before commit/PR; behavior-sensitive but not immediately broken.
- **Suggested**: true judgment calls only. Structural issues do not go here.

If unsure between Suggested and P1, choose P1. If unsure between P1 and P0, ask whether the issue is structural or contract-breaking; if yes, P0.

These severities describe the `standard` profile. `.turkit.yaml → review.strictness` shifts judgment-call findings (not P0 structural/behavioral) — see [Strictness Profiles](#strictness-profiles).

## Categories

Use one tag per finding: `SOC`, `DRY`, `OverEng`, `Comments`, `DeadCode`, `Naming`, `Complexity`, `Simplify`, `ErrorHandling`, `Types`, `Boundary`, `I18n`, `Verification`, `Regression`.

## Finding Discipline

- Report structural findings first. When structural findings exist, drop cosmetic nits — a few high-conviction findings beat an exhaustive list.
- A tradeoff the project has documented (ADR, rules doc, `.turkit.yaml`, a deliberately disabled rule) is a decision, not a finding. Suppress it and cite the source.

## Checklist

### 1. Separation of Concerns

A renderer renders. A handler/hook orchestrates. A util computes. Flag:

- **P0** pure helpers, formatters, builders, predicates, sorters, mappers, key derivation, or shape transforms inside an entry-point/render file when an obvious helper/shared module exists
- **P0** domain types/interfaces inside an entry-point/render file when a shared/sibling type module exists; local props/return types may colocate
- **P0** non-trivial constants (option lists, defaults, regexes, magic numbers, config objects) inside an entry-point/render file when a constants/shared module exists
- **P0** more than one exported public unit per file when the file's primary concern is a single renderer/orchestrator, except a tiny local presentational sub-unit or a framework-mandated file contract (e.g. a route module exporting `loader` / `ErrorBoundary`); cite the convention when waiving
- **P1** a unit branching on more than ~2 distinct shapes/modes
- **P1** a unit doing rendering/orchestration plus data fetching plus derived state

### 2. DRY

Flag:

- **P0** new helper/function/module duplicating one already in shared code or the same feature; grep and cite the existing symbol
- **P0** two units doing almost the same thing under different names
- **P1** copy-pasted blocks differing only by parameters/props, especially 3+ occurrences
- **P1** repeated mapping/filter/derive chains over the same domain object

Do not extract prematurely. Three clear lines can beat one bad abstraction. Identical shapes are duplicates only when they change for the same reason — two policies that coincide today (same formula, different owners or change schedules) stay separate.

### 3. Over-engineering

Flag diff weight that does not earn itself today:

- **P1** single-call-site abstractions/generic wrappers
- **P1** extension points/config knobs/polymorphic parameters with no consumer
- **P1** feature flags/backwards-compat shims when the code can simply change
- **P1** defensive `try/catch` or impossible-case handling that hides clean failures
- **P0** dead options/props/params/enum variants
- **P0** one-method manager/service/helper indirections

### 4. Naming

Flag **P1**:

- placeholders (`data`, `info`, `util`, `helper`, `handle`, `manager`, `temp`, `result`, `obj`) when intent is knowable
- abbreviations hiding meaning
- names that lie about shape/side effects
- names no longer matching behavior after the diff

### 5. Comments and Dead Weight

Default is zero new comments. A comment is acceptable only when it explains a non-obvious why in one line. The severity of *new* comments follows the `review.comments` knob (default `allow-why-only`) — see [Strictness Profiles](#strictness-profiles).

Introduced by the diff = **P0** (under `allow-why-only`; under `zero-new-comments` a why-comment is P0 too, under `allow` only misleading/stale comments are flagged):

- narrative comments, history comments, task/review references, decorative banners
- internal doc-comments, multiline comment blocks, commented-out code
- TODOs without ticket references
- non-project-language comments unless the repo uses that language
- debug prints, unused imports, empty exports

Legacy comments on touched lines = **P1** unless deletion is clearly mechanical.

### 6. Complexity

Flag **P1**:

- function > ~40 lines or > 3 nesting levels
- unit with > ~5 parameters
- chained pipeline that loses readability

### 7. Error Handling

Flag:

- **P0** introduced swallowed errors (`catch {}`, `.catch(() => {})`, `except: pass`, `_ = err`, equivalents)
- **P0** null propagation / optional chaining that hides an error-created undefined
- **P1** missing explicit loading/error/empty states where the caller/user needs them
- **P1** logging without surfacing where the caller/user needs visibility

### 8. Types and Contracts

When typed:

- **P0** broad escape hatches (`any`, `interface{}`, `# type: ignore`, force casts, equivalents)
- **P0** typed casts outside narrow allowed idioms (`as const`, `as unknown`) when they bypass source typing/validation
- **P0** duplicated string unions/enums in 2+ files
- **P0** domain types in entry-point/render files when a shared type module exists
- **P1** optional/null handling over values that should be non-null by contract

### 9. Boundaries and Imports

Flag:

- **P0** cross-module/layer imports that violate project architecture
- **P1** deep relative imports when aliases/package paths exist
- **P1** hardcoded user-facing strings when i18n/string catalogs exist
- **P1** hand-rolled equivalents of project primitives

### 10. Simplification

For every meaningful hunk, ask once: would a reframing delete this complexity instead of polishing it — a state model that removes the branches, an ownership move that makes the feature a natural extension of an existing abstraction, a default flow that absorbs the special cases?

- **P1** `Simplify` only when you can name the concrete move and its behavior-preserving path: what disappears (branches, layers, modes, wrappers) and where the remaining logic lands.
- If you cannot name the move, stay silent. An open-ended "restructure this" is not a finding.
- Prefer moves that delete complexity over moves that relocate it.

`relaxed` skips this section; `strict` promotes a named move to P0 — see [Strictness Profiles](#strictness-profiles).

### 11. Verification

After auto-fixes, re-run the mechanical command. If checks were unavailable, report why. If the operator claimed testing without evidence, list it under Residual Risks.

## Shared Output Format

Composition rule: every review entry point renders these sections in this order. A skill may append extra sections it declares in its own SKILL.md; it never renames, reorders, or drops a shared section. Non-review skills (e.g. `goal-loop`'s result report) are exempt.

```markdown
## Profile

- Strictness: `<relaxed|standard|strict>` · Comments: `<allow|allow-why-only|zero-new-comments>` (resolved from `.turkit.yaml → review`, defaults when absent)

## Mechanical Pre-pass (lint)

- Ran: `<exact command>`
- Findings kept: N (validated against the diff)
- Findings dropped as false positives: N — list with reasons
- Notable rules triggered: short list with file:line

## Fixes Applied

> Auto-fixes from the shared rubric. All landed **unstaged**; the operator stages.

- [Category] [file:line] What changed
- New files created by extractions, if any: `path/to/file.ext`

## Required Changes

- [P0|P1] [Category] [file:line] What must change and why it cannot be auto-fixed

## Blocking Issues

- [P0|P1] [Category] [file:line] Rare issue not covered above

## Suggested Improvements

- [Category] [file:line] Improvement and expected benefit

## Positive Signals

- Short bullet only when it reduces review ambiguity

## Verification

- Ran: exact commands
- Residual failures, if any
- Skipped: relevant checks not run and why

## Residual Risks

- Remaining uncertainty

## Tree state after fixes

- Staged: `<files>` / unchanged from before
- Unstaged (auto-fixes): `<files>`
```
