# React Review Rubric

Use this rubric for React 19+ reviews. It complements `react-doctor`; do not duplicate a `react-doctor` finding on the same line unless extra context matters.

## Strictness Profiles

This rubric reads the same optional `.turkit.yaml → review` knobs as the shared rubric (`strictness`, `comments`), plus one React-specific knob. Defaults reproduce the standard React 19+ behavior. Resolve them once before judging and state the resolved profile in the output (`Strictness: <profile> · Comments: <mode> · React: >=<min_version>`).

| Key | Values | Default | Effect |
|---|---|---|---|
| `strictness` | `relaxed` \| `standard` \| `strict` | `standard` | Same shift as the shared rubric — `relaxed` downgrades P1 cleanups (DRY under 3 occurrences, Over-engineering §4, premature memoization, JSX hygiene §6) to Suggested; `strict` promotes borderline Suggested to P1. P0 structural / behavioral / React-19-ban findings always stay blocking. |
| `comments` | `allow` \| `allow-why-only` \| `zero-new-comments` | `allow-why-only` | Governs §5 Comments, same semantics as the shared rubric. |
| `react.min_version` | integer | `19` | The React major this rubric targets. At `19` (default) the §6 React-19 bans apply. Set lower (e.g. `18`) to keep the structural / hooks / data-flow checks but **not** auto-fix or flag the React-19-only API rules (`React.FC`, `forwardRef`, `defaultProps`, namespace import, `JSX.Element`). |

`turkit-react` defaults to React 19+; the version rule is configurable here rather than hardcoded. If `.turkit.yaml` is absent or omits `review`, use the defaults.

## Fix Policy

When a finding maps to a `react-doctor` rule, resolve the canonical fix recipe first — `npx -y react-doctor@latest rules explain <rule>` — and apply that fix shape instead of improvising. The recipe governs both the Auto-fix edit and the suggestion attached to a Required Change.

### Auto-fix

Apply only when mechanical, behavior-preserving, and scoped to touched files:

- remove `React.FC`, `React.FunctionComponent`, `forwardRef`, `defaultProps`, `JSX.Element`, `React.JSX.Element` typing introduced by the diff when the project is confirmed React 19+
- rewrite React namespace imports to named imports
- convert component default exports to named exports unless the route/framework allowlist requires default exports
- replace `cond && <X />` with `cond ? <X /> : null` on touched lines
- replace `return <></>` with `return null`
- remove violating comments, debug prints, and unused imports
- fix deep relative imports to established aliases
- move helpers/types/constants out of `.tsx`/`.jsx` only when an obvious existing ownership target exists and the move cannot introduce cycles/public API changes
- replace a new duplicate helper/hook/component with an existing shared symbol
- remove dead props/enum variants/wrapper files with no caller in the diff/touched files
- replace `key={index}` only when a stable `id`/`uuid`/`slug` is obvious and behavior-preserving

### Required Changes

Surface these; do not auto-fix:

- `useEffect` refactors that require behavior decisions
- splitting render shapes, hooks with multiple responsibilities, or component/hook ownership changes
- removing `any`/casts that need upstream type tightening, validation, or type guards
- creating shared schemas/enums to converge duplicated unions
- hoisting nested components when captured closure needs review
- query invalidation/cache-key changes when the correct key set is not obvious
- accessibility semantics where UX intent matters
- replacing `key={index}` when stable identity is ambiguous
- behavioral regressions

## Severity

- **P0**: broken behavior/contract, unsafe type escape, missing effect cleanup, fetch outside project data primitive, missing cache invalidation, component defined inside component, React 19 banned APIs in new code, structural SOC violation, duplicate shared helper, violating comments/debug prints.
- **P1**: must-fix before merge: branching complexity, over-engineering, JSX hygiene, a11y baselines, optional chaining hiding a type bug, broad store subscriptions, waterfalls, non-functional state updates, reorderable `key={index}`.
- **Suggested**: true judgment calls only.

Weight judgment-call severity by render path: code that runs per keystroke, per list row, per frame, or on every route escalates a borderline finding to P1; a rarely-mounted surface (settings modal, onboarding step) can demote it to Suggested or noise. Never downgrade P0 structural/behavioral findings this way.

## Categories

Use one tag per finding: `useEffect`, `SOC`, `DRY`, `OverEng`, `Comments`, `React 19`, `Hooks`, `Types`, `Query`, `Mutation`, `Waterfall`, `Store`, `A11y`, `Verification`, `Regression`.

## Checklist

### 1. Useless `useEffect`

For every introduced/modified effect, ask if it should be:

- derived during render
- moved into the event handler that caused it
- handled by the project's data-fetching primitive
- handled by the project's state primitive
- represented by `useSyncExternalStore`
- split into one effect per external concern
- rewritten with `useEffectEvent` for latest callback/state without resubscribing

Flag **P0** unless there is a clear external-system justification:

- mirror prop into state
- cascading state updates
- effect-as-handler
- fetch in component effect instead of project data primitive
- prop-callback fired from an effect
- subscription/listener/interval/observer without cleanup
- mutable/inline dependency values
- one effect handling unrelated concerns

### 2. React SOC

In changed `.tsx`/`.jsx`, flag:

- **P0** pure helpers, domain types, or non-trivial constants colocated when an obvious helper/types/constants module exists
- **P0** multiple exported components outside a tiny local presentational exception
- **P0** component defined inside another component
- **P1** component branching on more than ~2 render shapes
- **P1** renderer doing data orchestration plus derived state

In changed hook files, flag:

- **P0** domain types/helpers that belong in shared modules
- **P1** unrelated responsibilities inside one hook

### 3. DRY

Flag:

- **P0** new helper/hook/component duplicating one already in shared code
- **P0** duplicated query keys/mutation bodies/cache helpers across hooks
- **P0** near-identical hooks under different names
- **P1** copy-pasted JSX blocks, especially 3+ occurrences
- **P1** repeated derive chains over the same domain object

### 4. Over-Engineering

Flag:

- **P1** single-call-site abstractions, extension props, unused config knobs, unnecessary compat shims
- **P1** premature `useMemo`/`useCallback`/`React.memo`
- **P0** dead props/options/enum variants
- **P0** one-method manager/service/helper wrappers

### 5. Comments and Dead Weight

Introduced by the diff = **P0**:

- narrative/history/task/review comments
- JSDoc on internal components/hooks/functions
- decorative banners, TODOs without ticket refs, commented-out code/JSX
- non-project-language comments
- `console.log`, `console.debug`, `debugger`
- unused imports, empty exports, dead barrel exports

### 6. React 19 and JSX Hygiene

The React-19 API bans below apply when `review.react.min_version >= 19` (the default). Below 19, keep the JSX-hygiene and a11y checks but do not flag or auto-fix the React-19-only API rules. Flag:

- **P0** `React.FC`, `forwardRef`, `defaultProps`, `JSX.Element`, namespace React import, component default export outside allowlist
- **P1** `cond && <X />`, chained ternaries, empty fragments returned as UI
- **P1** inline object/array literals in hook deps
- **P1** icon-only buttons without labels, non-interactive elements with click handlers but no keyboard/role, images without alt, inputs without labels
- **P1** `key={index}` on reorderable/insertable/filterable lists

### 7. Hooks Discipline

Flag:

- **P0** nested component definitions
- **P1** derived state stored with `useState` + effect
- **P1** non-functional `setState` when next value depends on previous
- **P1** conditional custom hooks
- **P1** hook with no consumer in diff/touched files

### 8. Types and Schemas

Flag:

- **P0** `any`, `as any`, `<any>`, `any[]`, including tests/mocks
- **P0** `as Foo` casts except `as const` / `as unknown`
- **P0** duplicated string unions in 2+ files
- **P0** domain types in `.tsx`/`.jsx`/hook files when shared types exist
- **P1** optional chaining over values that should be non-null by contract

### 9. Data Flow

Flag:

- **P0** fetches in components/random utils/effects instead of project data primitive
- **P0** missing cache invalidation/refetch after server-visible mutation
- **P1** avoidable dependent waterfalls
- **P1** implicit loading/error/empty states
- **P1** broad store subscriptions or selectors returning fresh objects without compare strategy

### 10. Verification

After auto-fixes, re-run the resolved React gate and lint. If the React gate is unavailable, report why and rely on the judgment pass.

## Output Format

```markdown
## Profile

- Strictness: `<relaxed|standard|strict>` · Comments: `<allow|allow-why-only|zero-new-comments>` · React: `>=<min_version>` (resolved from `.turkit.yaml → review`, defaults when absent)

## Mechanical Pre-pass (react-doctor)

- Ran: `<resolved React gate command>`
- Score: `N/100` (if available)
- Findings kept: N
- Findings dropped as false positives: N — list with reasons
- Notable rules triggered: short list with file:line

## Fixes Applied

- [Category] [file:line] What changed
- New files created by extractions, if any: `path/to/file.ts`

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
```
