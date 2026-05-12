---
description: Strict React review (modern React 19+). Mechanical pre-pass via react-doctor, judgment pass via the skill. Auto-fixes mechanical violations (unstaged), surfaces judgment calls as required changes.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(npx:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# React Review

## Context

- Current branch: !`git branch --show-current`
- Changed React / TS files: !`git diff --name-only HEAD -- '*.tsx' '*.jsx' '*.ts'`
- Untracked React / TS files: !`git ls-files --others --exclude-standard -- '*.tsx' '*.jsx' '*.ts'`

## Your task

Invoke the `react-review` skill. Follow its workflow: resolve and run the configured React mechanical gate, walk the React rubric on the in-scope files, auto-fix everything in the `Auto-fix` bucket, and surface everything in the `Required changes` bucket as findings for the operator. Report in the skill's output format.

The skill is the source of truth for severity calibration, fix policy, and output structure — don't restate them here.
