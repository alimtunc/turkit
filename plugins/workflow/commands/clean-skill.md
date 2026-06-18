---
description: "Audit and optionally remove stale Turkit skills left behind by additive skill updates."
argument-hint: "[optional install path]"
allowed-tools: Skill, Read, Glob, Grep, Bash(pwd:*), Bash(ls:*), Bash(find:*), Bash(test:*), Bash(rg:*), Bash(grep:*), Bash(diff:*), Bash(rm:*)
---

# Clean Skill

## Context

- Current directory: !`pwd`
- Local stale Turkit candidates: !`find .agents/skills .claude/skills .claude/commands .codex/skills -maxdepth 2 \( -name grill-me -o -name ticket-triage -o -name ticket-plan -o -name ticket-execute -o -name shipoff -o -name 'shipoff.md' \) 2>/dev/null || true`

## Your task

Invoke the `clean-skill` skill with `$ARGUMENTS`.

Audit first. Delete only stale Turkit-owned paths that were shown to the operator and explicitly confirmed.
