---
description: Strict pre-PR full-branch review vs. the base branch. Adds branch-level checks (per-commit coherence, cross-commit drift, intent) on top of the per-diff rubric.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git rev-list:*), Bash(git symbolic-ref:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Pre-PR Review

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Default remote head: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo "(unset)"`

## Your task

Invoke the `pre-pr-review` skill against `${1:-main}` (override only if the operator passed a base branch). Resolve the base branch per the skill's workflow (`.turkit.yaml → base_branch`, then `git symbolic-ref refs/remotes/origin/HEAD`, then `main`); the `${1}` value is only a hint.

Follow the skill's workflow: gate on tree cleanliness and branch size, run the project's lint as a mechanical pre-pass, walk the shared per-diff rubric plus the branch-level checklist, auto-fix everything in the `Auto-fix` bucket, and surface everything in the `Required changes` bucket. Report in the skill's output format.

The skill is the source of truth for review sizing, fix policy, severity calibration, branch-level checks, and output structure — don't restate them here.
