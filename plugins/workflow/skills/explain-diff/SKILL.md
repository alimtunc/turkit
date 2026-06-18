---
name: explain-diff
description: Use before commit or review when the operator wants to quickly understand the current staged, unstaged, untracked, branch, or PR diff without reading a long audit.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Read, Grep, Glob
---

# Explain Diff

Compress the diff into a short before/after brief the operator can understand before committing.

## Steps

1. Inspect `git status --short`, staged diff, unstaged diff, and untracked files.
2. If no local diff exists, compare the current branch to the resolved base branch.
3. Read only the files needed to understand before/after behavior, intent, risk, and verification.
4. Favor behavior and ownership over file lists.
5. If the diff is too broad to explain safely in 12 lines, summarize the main slice and say what must be inspected next.

## Output

Emit at most 12 lines. Do not use diagrams or long prose.

```markdown
Diff brief
- Before: <what existed before, one sentence>
- After: <what exists now, one sentence>
- Why: <reason, or "not obvious from diff">
- Constraint: <main constraint/tradeoff that shaped the change>
- Impact: <user/dev/config/none + one sentence>
- Scope: <UI/API/DB/config/docs touched or unchanged, only if useful>
- Risk: <one concrete risk>
- Verify: <commands/manual check>
- Reread: <1-3 files or hunks max>
```

Then ask exactly one question:

```text
Does this match what you intended to commit?
```

## Guardrails

- Do not stage, commit, push, or edit.
- Do not list every changed file.
- Do not output a full audit, code tour, or file-by-file walkthrough.
- Do not invent intent. If the "why" or constraint is not visible in the diff, say so.
- If the diff contains generated/vendor noise, separate it from meaningful changes.
- If intent is unclear, say so directly.
