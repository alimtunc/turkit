---
name: react-review
description: Strict React review for React 19+ code. Runs a configurable react-doctor gate, then applies the React review rubric for useEffect, SOC, JSX hygiene, hooks, types, and data flow. Auto-fixes mechanical issues unstaged and surfaces required changes.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(npx:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# React Review

Operator-invoked review for React code (`.tsx` / `.jsx` / `.ts` containing hooks or JSX). Mechanical fixes land unstaged; the operator stages.

## Source of Truth

Before judging or fixing, read [`references/react-rubric.md`](references/react-rubric.md). It defines severity, categories, fix policy, checklist, and output format.

## Reviewer Mindset

The bar is clean, minimal, DRY, SOC-respecting React 19+ code.

- Effects are for synchronizing with external systems. Derived values and user-action work usually do not belong in `useEffect`.
- Render files render; hooks orchestrate; utils compute.
- React-specific structural violations block merge unless the operator explicitly accepts an exception.
- Do not normalize legacy patterns just because the surrounding file already has them.

## Workflow

1. Gather scope:
   - operator-supplied file list if provided
   - otherwise `git diff --name-only HEAD -- '*.tsx' '*.jsx' '*.ts'`
   - plus `git ls-files --others --exclude-standard -- '*.tsx' '*.jsx' '*.ts'`
   - for branch scope: `git diff --name-only <base>..HEAD -- '*.tsx' '*.jsx' '*.ts'`
2. If no React/TS files are in scope, stop and recommend `pre-commit-review` for non-React files.
3. Resolve the target React major: `.turkit.yaml → review.react.min_version` if set, else the version from `package.json`, else default `19`. Then:
   - installed React < the target (default 19): stop unless this is explicitly a migration review
   - `review.react.min_version` set below 19: keep structural/hooks/data-flow checks but do not apply the React-19-only API auto-fixes (see the rubric's Strictness Profiles)
   - unknown version: continue generic review but do not apply React 19-only auto-fixes; report uncertainty
4. Resolve the React mechanical gate:
   - `.turkit.yaml → commands.react_review`
   - package script `react-review`, `react:review`, or `react-doctor`
   - fallback `npx -y react-doctor@latest . --diff --verbose`
5. Prefer a project-pinned gate. If using fallback, report that it is unpinned and recommend adding `commands.react_review` or a package script.
6. Run the resolved gate. If unavailable, continue and report "react-doctor unavailable".
7. Walk the React rubric in order. Do not duplicate gate findings on the same line unless extra context matters.
8. Apply only the rubric's Auto-fix bucket. Do not stage or commit.
9. Re-run the project's lint command and the resolved React gate after auto-fixes.
10. Report using the React rubric output format.

## Guardrails

- React code only; route non-React diffs to `pre-commit-review`.
- Never edit outside current scope.
- Never reformat whole files; trust the formatter.
- Never change public props signatures in auto-fix mode.
- If unsure between auto-fix and required change, choose required change.
- Respond in the conversation's language by default.
