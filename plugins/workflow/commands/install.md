---
description: Bootstrap Turkit in this repo: detect stack-specific packs, recommend plugin install commands, and set up .turkit.yaml.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Read, Grep, Glob, Write, Edit
---

# Turkit Install

## Context

- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `install` skill. Detect the current project's stack, recommend the Turkit plugin packs that should be installed, and guide the operator through project setup.

The skill is the source of truth for what may be written and which plugin install commands to suggest.
