---
description: Single-session ticket orchestrator — intake → route → reuse-survey plan → one plan-approval pause → execute → handoff. Never commits; suggests /goal-review.
argument-hint: <ticket-id | tracker-url | free-form description>
allowed-tools: Skill, Read, Edit, MultiEdit, Write, Glob, Grep, Task, Bash(git status:*), Bash(git branch:*), Bash(git worktree:*), Bash(git checkout:*), Bash(git switch:*), Bash(git fetch:*), Bash(git log:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*)
---

# Ticket

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Invoke the `ticket` skill with `$ARGUMENTS`.

The skill is the source of truth for: resolving the ticket from the argument (tracker id, URL, or free-form description), classifying scope (one-shot / standard / split), conducting the reuse survey, producing the plan, the single plan-approval pause, executing criterion by criterion, and emitting the handoff.

Never commit. When the handoff is emitted, suggest `/goal-review` (run `--diff` before a commit, `--branch` before a PR) — do not auto-invoke it.
