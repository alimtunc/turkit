---
name: pre-commit-review
description: Operator-invoked review of the current local diff (staged + unstaged + untracked) before committing. Strict gatekeeper stance with mechanical auto-fixes and required-change findings. Language-agnostic.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Pre-Commit Review

Review the local diff before committing. This skill is operator-invoked and may edit files only for mechanical auto-fixes, which land unstaged.

## Source of Truth

Before judging or fixing, read [`references/review-rubric.md`](references/review-rubric.md). It defines severity, categories, fix policy, checklist, and output format.

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
4. Load project rules before judging:
   - Read `.turkit.yaml` if present.
   - If it defines `rules.docs`, read the relevant listed docs.
   - Otherwise read relevant defaults when present: `CLAUDE.md`, `AGENTS.md`,
     and `docs/conventions/*.md`.
5. Run the project's lint command:
   - `.turkit.yaml → commands.lint`
   - fallback per `references/build-tool-detection.md`
   - if unavailable, continue and report "lint unavailable"
6. Review changed hunks first. For untracked files, review the full file.
7. Walk the shared rubric checklist in order, then apply any loaded project
   rules that are relevant to the touched files.
8. Apply only the shared rubric's Auto-fix bucket. Do not stage or commit.
9. Re-run lint after auto-fixes and capture residual failures.
10. Report using the shared rubric's Shared Output Format.

## Review Sizing

- **Fast**: renames, docs, config, dependency bumps. Walk the checklist quickly.
- **Medium**: bounded logic/UI/module changes. Walk every section.
- **Deep**: auth, payments, schemas, core state, public API, or heterogeneous large diffs. Split by scope when useful, then synthesize before fixing.

## Guardrails

- Do not turn this into a broad refactor.
- Do not edit unrelated files.
- Do not stage, commit, push, amend, rebase, reset, or rewrite history.
- If staged changes existed before auto-fixes, state clearly that fixes landed unstaged.
- Apply `references/output-preferences.md` for operator-facing language/style.
