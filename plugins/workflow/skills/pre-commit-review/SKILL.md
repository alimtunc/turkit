---
name: pre-commit-review
description: Operator-invoked review of the current local diff (staged + unstaged + untracked) before committing. Strict gatekeeper stance with mechanical auto-fixes and required-change findings. Language-agnostic.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Pre-Commit Review

Review the local diff before committing. This skill is operator-invoked and may edit files only for mechanical auto-fixes, which land unstaged.

## Source of Truth

Before judging or fixing, read [`../../references/review-rubric.md`](../../references/review-rubric.md). It defines severity, categories, fix policy, checklist, and output format.

## Reviewer Mindset

The bar is clean, minimal, DRY, SOC-respecting code. "Works" is the floor.

- The diff must justify itself; unrelated changes are scope creep.
- Touched lines are the author's responsibility, even when nearby legacy code is worse.
- Structural violations are blocking. Do not downgrade them because the diff is large or deadline-driven.
- When in doubt, flag with a concrete rationale.

## Workflow

1. Inspect:
   - `git status --short`
   - `git diff --cached`
   - `git diff`
   - `git ls-files --others --exclude-standard`
2. If there are no staged, unstaged, or untracked changes, stop and report nothing to review.
3. Keep findings labeled `staged`, `unstaged`, or `untracked` when multiple scopes exist.
4. Run the project's lint command:
   - `.turkit.yaml → commands.lint`
   - fallback per `docs/contracts/build-tool-detection.md`
   - if unavailable, continue and report "lint unavailable"
5. Review changed hunks first. For untracked files, review the full file.
6. Walk the shared rubric checklist in order.
7. Apply only the shared rubric's Auto-fix bucket. Do not stage or commit.
8. Re-run lint after auto-fixes and capture residual failures.
9. Report using the shared rubric's Pre-Commit Output Format.

## Review Sizing

- **Fast**: renames, docs, config, dependency bumps. Walk the checklist quickly.
- **Medium**: bounded logic/UI/module changes. Walk every section.
- **Deep**: auth, payments, schemas, core state, public API, or heterogeneous large diffs. Split by scope when useful, then synthesize before fixing.

## Guardrails

- Do not turn this into a broad refactor.
- Do not edit unrelated files.
- Do not stage, commit, push, amend, rebase, reset, or rewrite history.
- If staged changes existed before auto-fixes, state clearly that fixes landed unstaged.
- Respond in the conversation's language by default.
