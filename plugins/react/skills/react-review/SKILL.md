---
name: react-review
description: Review React code against an opinionated rule set — modern React 19+ only, one component per file, named exports, ternary conditional rendering, disciplined hooks. Auto-fixes low-risk violations, flags the rest with rule IDs.
---

# React Review

Audit React code against 13 rules in 4 groups. Auto-fix what's low-risk; flag what needs judgment. Scope: `.tsx` / `.jsx` / `.ts` files containing React hooks or JSX.

## Rules

### 1. Modern React only

- **1.1** No `forwardRef`, `React.FC`, `JSX.Element`, `defaultProps`. Ref is a standard prop; use function component signatures; use `ReactNode` for children.
- **1.2** No React namespace import (`import * as React from 'react'`). Use named imports (`import { useState } from 'react'`).

### 2. Component boundaries

- **2.1** One component per file. A file exporting two components should be split — propose file names in the flag.
- **2.2** Named exports only. No `export default`.
- **2.3** `*Props` type colocated with the component. Shared types live under `src/types/`.

### 3. Conditional rendering

- **3.1** Always `cond ? <X /> : null`. Never `cond && <X />` — falsy values like `0` or `""` render literally instead of hiding.
- **3.2** No nested ternaries. Extract a helper with early returns.

### 4. Hooks and state

- **4.1** One `useEffect` = one concern. Split effects that juggle multiple independent pieces of state.
- **4.2** Derive state during render, never via `useState` + `useEffect`. If expensive, wrap in `useMemo`.
- **4.3** No `any`. Use `unknown` and narrow at boundaries.
- **4.4** No components defined inside components. They create a new component identity every render — kills memoization, breaks hooks, thrashes the DOM.
- **4.5** Use functional `setState` (`setX(prev => ...)`) when the new value depends on the previous. Lets dependent callbacks stay stable.
- **4.6** Interaction logic goes in event handlers, not `useEffect`. Effects are for syncing with external systems (DOM, network, subscriptions), not reacting to user input.

## Review procedure

1. Gather the scope:
   - Operator-supplied file list if provided.
   - Otherwise `git diff HEAD --name-only | grep -E '\.(tsx|jsx|ts)$'` to limit to changed React files.

2. For each file, walk rules 1–4 in order, collecting violations with rule IDs.

3. Classify each finding:
   - **Auto-fix** (low risk, mechanical):
     - 1.1: remove `React.FC<Props>` wrapper, rewrite to `function Name(props: Props)` or arrow.
     - 1.1: remove `forwardRef` wrapper (when ref is the only added concern), add `ref` to `Props`.
     - 1.2: rewrite `import * as React` to named imports.
     - 2.2: rename `export default function Foo` to `export function Foo`.
     - 3.1: rewrite `cond && <X />` to `cond ? <X /> : null`.
   - **Flag** (structural or requires judgment):
     - 2.1 (split), 2.3 (move types), 3.2 (flatten nested ternaries), all of 4.1–4.6.

4. Apply auto-fixes in the actual files. After each fix, re-read the file to confirm the edit is valid JSX/TS.

5. Emit the report (format below).

## Report format

```
React review — <N> files

AUTO-FIXED
- path/to/file.tsx:L — rule 1.1 — removed React.FC
- path/to/file.tsx:L — rule 3.1 — rewrote `&&` to ternary
- ...

FLAGGED
- path/to/file.tsx:L — rule 2.1 | two components in file (Header, HeaderActions) | split into Header.tsx + HeaderActions.tsx
- path/to/file.tsx:L — rule 4.4 | component defined inside parent render | hoist to module scope or memoize
- ...

PASS
<notable good patterns, 1–3 bullets max>
```

Respond in the conversation's language by default.

## Guardrails

- Never delete code the operator wrote outside the current scope.
- Never reformat whole files — trust the formatter.
- Never change public props signatures in auto-fix mode. If a rename would break a consumer, flag instead.
- If in doubt between auto-fix and flag → flag.
- This skill reviews React code only. For non-React files, stop with a clear "outside scope" message.
