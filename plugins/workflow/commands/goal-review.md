---
description: "Review-and-fix loop for staged changes, a branch, or the whole repo. Modes: --diff (staged+unstaged, single pass), --branch (committed diff vs base, loop-until-clean — default), --repo (whole codebase, single pass per package). Loops review→fix until clean, then a final verification pass. Never commits."
argument-hint: "[--diff|--branch|--repo] [base-branch]"
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git log:*), Bash(git rev-list:*), Bash(git symbolic-ref:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Edit, MultiEdit, Write, Grep, Glob, Task
---

# Goal Review

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `goal-review` skill with `$ARGUMENTS` (default `--branch` when no argument is given). The skill is the source of truth for modes, the review→fix loop, the rubric, the fix policy, and the output format — do not restate them here.
