---
name: explain-diff
description: Use before commit or review when the operator wants to understand the current staged, unstaged, untracked, branch, or PR diff without reading a long audit.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Read, Grep, Glob
---

# Explain Diff

Compress the diff into what the operator needs to understand before committing.

## Steps

1. Inspect `git status --short`, staged diff, unstaged diff, and untracked files.
2. If no local diff exists, compare the current branch to the resolved base branch.
3. Read only the files needed to understand intent, risk, and verification.
4. Favor behavior and ownership over file lists.

## Output

Emit at most 12 lines:

```markdown
Diff brief
- Change: <one sentence>
- Why: <one sentence, or "not obvious from diff">
- User impact: <none/internal/visible + one sentence>
- Dev impact: <APIs/config/scripts/docs affected>
- Main files: <3-6 paths max>
- Risk: <one concrete risk>
- Verify: <commands/manual check>
- I would reread: <1-3 files or hunks>
```

Then ask exactly one question:

```text
Does this match what you intended to commit?
```

## Guardrails

- Do not stage, commit, push, or edit.
- Do not list every changed file.
- If the diff contains generated/vendor noise, separate it from meaningful changes.
- If intent is unclear, say so directly.
