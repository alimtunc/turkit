---
description: "Resolve current git merge, rebase, or cherry-pick conflicts without staging, continuing, committing, or pushing."
argument-hint: "[optional context about the conflict]"
allowed-tools: Skill, Read, Edit, MultiEdit, Write, Glob, Grep, Bash(git status:*), Bash(git diff:*), Bash(git show:*), Bash(git log:*), Bash(git ls-files:*), Bash(git rev-parse:*), Bash(rg:*), Bash(grep:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*)
---

# Resolve Conflict

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Conflicted files: !`git diff --name-only --diff-filter=U`

## Your task

Invoke the `resolve-conflict` skill with `$ARGUMENTS`.

Resolve only the current conflicts. Do not run `git add`, any `--continue` command, commit, push, reset, or abort.
