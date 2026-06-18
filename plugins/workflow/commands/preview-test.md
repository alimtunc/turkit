---
description: "Functionally test a deployed PR preview from config or an operator-provided URL."
argument-hint: "[preview-url | pr-number | scenario]"
allowed-tools: Skill, Read, Glob, Grep, Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(command -v:*), Bash(gh pr view:*), Bash(glab mr view:*)
---

# Preview Test

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `preview-test` skill with `$ARGUMENTS`.

Resolve the preview URL through configuration or operator input. Do not assume any hostname.
