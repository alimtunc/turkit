# Code Quality Baseline

Authoring-time rules for clean, well-structured code. This is the dev-time mirror of `review-rubric.md` (§1–§10): reviews flag what these rules prevent. Update the two files together — a rule added here needs its review check there, and vice versa.

Projects seed this baseline into their rules docs (`.turkit.yaml → rules.docs`) via `turkit-init` or `adopt-project`, then own the copy: sharpen it, add project-specific rules, and record documented tradeoffs that override a rule.

## 1. Separation of Concerns

- A renderer renders, a handler/hook orchestrates, a util computes. One concern per file.
- Pure helpers, formatters, predicates, mappers, and shape transforms live in helper/shared modules, never in entry-point/render files.
- Domain types and interfaces live in shared type modules; only local props/return types colocate.
- Non-trivial constants (option lists, defaults, regexes, config objects) live in constants/shared modules.
- One exported public unit per renderer/orchestrator file, except a tiny local presentational sub-unit or a framework-mandated file contract.
- Split any unit branching on more than ~2 distinct shapes/modes.

## 2. DRY

- Before writing a helper, grep for the existing one; import it instead of duplicating.
- No copy-pasted blocks differing only by parameters — extract at 3 occurrences.
- Do not extract prematurely: three clear lines can beat one bad abstraction. Shapes are duplicates only when they change for the same reason — two policies that coincide today stay separate.

## 3. Over-engineering

- No single-call-site abstractions or generic wrappers; inline until a second caller exists.
- No extension points, config knobs, or polymorphic parameters without a consumer today.
- No feature flags or compat shims when the code can simply change.
- No defensive `try/catch` around cases that cannot happen; let clean failures surface.
- No one-method manager/service/helper indirections.

## 4. Naming

- Names state intent: no `data`, `info`, `util`, `helper`, `temp`, `result` when intent is knowable.
- No abbreviations that hide meaning; no names that lie about shape or side effects.
- Rename when behavior changes and the old name stops being true.

## 5. Comments

- Default zero comments. A one-line why is acceptable when the reason is genuinely non-obvious.
- Never: narrative or history comments, task references, banners, commented-out code, TODOs without tickets, debug prints.

## 6. Complexity

- Functions stay under ~40 lines and ~3 nesting levels; units take at most ~5 parameters.
- If a chained pipeline stops reading top-to-bottom, break it up.

## 7. Error Handling

- Never swallow errors (`catch {}`, `.catch(() => {})`, `except: pass`, `_ = err`).
- No optional chaining that hides an error-created undefined.
- Give callers/users explicit loading, error, and empty states where they need them.

## 8. Types and Contracts

- No `any`, `interface{}`, `# type: ignore`, or force casts. Fix the upstream type instead.
- Casts only in narrow idioms (`as const`, `as unknown`) or immediately after real validation.
- One shared definition per union/enum; never redeclare it in a second file.
- Values non-null by contract are typed non-null — no defensive optionality.

## 9. Boundaries

- Respect the project's module/layer architecture; no cross-layer imports.
- Use established aliases over deep relative imports.
- Use project primitives (data fetching, state, i18n catalogs) over hand-rolled equivalents.

## 10. Simplification

- Before adding a branch, mode, flag, or layer: ask whether a reframing deletes the complexity instead — a state model that removes the branches, an ownership move that makes the feature a natural extension of an existing abstraction, a default flow that absorbs the special case.
- Prefer the shape that makes the change feel inevitable in hindsight; delete complexity rather than relocate it.
