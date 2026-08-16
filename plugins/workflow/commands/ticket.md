---
description: Single ticket entrypoint. Default pauses for plan approval; --auto plans, executes, and verifies autonomously from attached or explicit ticket context.
argument-hint: "[--auto|--triage|--plan|--execute] [--grill] [--fast] [ticket-id | tracker-url | free-form description]"
allowed-tools: Skill, Read, Edit, MultiEdit, Write, Glob, Grep, Task, Bash(git status:*), Bash(git branch:*), Bash(git worktree:*), Bash(git checkout:*), Bash(git switch:*), Bash(git fetch:*), Bash(git log:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*)
---

# Ticket

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `ticket` skill with `$ARGUMENTS`.

The skill is the source of truth for: parsing flags; preferring an explicit ticket argument, then attached session issue context, then tracker/branch/description fallbacks; classifying scope (one-shot / standard / split); stopping after `--triage` when requested; applying low-token mode with `--fast`; conducting the reuse survey; producing the plan; optionally challenging it with `--grill`; either stopping for manual plan approval or continuing under `--auto`; executing criterion by criterion; verifying; and emitting the handoff.

Never commit. When the handoff is emitted, suggest `/goal-review` (run `--diff` before a commit, `--branch` before a PR) — do not auto-invoke it.
