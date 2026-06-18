---
description: "Iterate on a bounded objective until its success criteria pass, the loop budget is exhausted, or a human decision is needed. Never commits."
argument-hint: "[--from-plan <path>] [--scope <path>] [--verify <command>] [--max-rounds N] <goal>"
allowed-tools: Skill, Read, Edit, MultiEdit, Write, Glob, Grep, Task, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git ls-files:*), Bash(git rev-parse:*), Bash(pwd:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*)
---

# Goal Loop

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `goal-loop` skill with `$ARGUMENTS`.

The skill is the source of truth for parsing flags, building the goal contract, controlling rounds, verifying, stopping conditions, and output format. Never commit, stage, push, or invoke shipping commands.
