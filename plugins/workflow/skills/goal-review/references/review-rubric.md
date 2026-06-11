# Shared Review Rubric

Use this rubric for language-agnostic reviews. It complements the project's own linter / formatter / type-checker; do not re-flag a line already covered by a mechanical rule unless extra context matters.

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
- remove dead props, parameters, enum variants, options, or wrapper files that have no caller in the diff/touched files
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

## Categories

Use one tag per finding: `SOC`, `DRY`, `OverEng`, `Comments`, `DeadCode`, `Naming`, `Complexity`, `ErrorHandling`, `Types`, `Boundary`, `I18n`, `Verification`, `Regression`.

## Checklist

### 1. Separation of Concerns

A renderer renders. A handler/hook orchestrates. A util computes. Flag:

- **P0** pure helpers, formatters, builders, predicates, sorters, mappers, key derivation, or shape transforms inside an entry-point/render file when an obvious helper/shared module exists
- **P0** domain types/interfaces inside an entry-point/render file when a shared/sibling type module exists; local props/return types may colocate
- **P0** non-trivial constants (option lists, defaults, regexes, magic numbers, config objects) inside an entry-point/render file when a constants/shared module exists
- **P0** more than one exported public unit per file when the file's primary concern is a single renderer/orchestrator, except a tiny local presentational sub-unit
- **P1** a unit branching on more than ~2 distinct shapes/modes
- **P1** a unit doing rendering/orchestration plus data fetching plus derived state

### 2. DRY

Flag:

- **P0** new helper/function/module duplicating one already in shared code or the same feature; grep and cite the existing symbol
- **P0** two units doing almost the same thing under different names
- **P1** copy-pasted blocks differing only by parameters/props, especially 3+ occurrences
- **P1** repeated mapping/filter/derive chains over the same domain object

Do not extract prematurely. Three clear lines can beat one bad abstraction.

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

Default is zero new comments. A comment is acceptable only when it explains a non-obvious why in one line.

Introduced by the diff = **P0**:

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

### 10. Verification

After auto-fixes, re-run the mechanical command. If checks were unavailable, report why. If the operator claimed testing without evidence, list it under Residual Risks.

## Pre-Commit Output Format

```markdown
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
