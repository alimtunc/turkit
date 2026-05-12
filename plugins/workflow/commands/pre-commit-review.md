---
description: Strict review of the current diff. Auto-fixes mechanical violations (unstaged), surfaces judgment calls as required changes.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Pre-Commit Review

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Staged diff: !`git diff --cached --stat`
- Unstaged diff: !`git diff --stat`
- Untracked files: !`git ls-files --others --exclude-standard`

## Your task

Invoke the `pre-commit-review` skill. Follow its workflow: run the project's lint as a mechanical pre-pass, walk the shared review rubric on the changed hunks, auto-fix everything in the `Auto-fix` bucket, and surface everything in the `Required changes` bucket as findings for the operator. Report in the skill's output format.

The skill is the source of truth for review sizing, fix policy, severity calibration, and output structure — don't restate them here.
