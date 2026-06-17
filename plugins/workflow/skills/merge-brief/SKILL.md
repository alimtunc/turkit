---
name: merge-brief
description: Use before merging a branch or PR when the operator wants a compact, decision-ready understanding of what will enter the base branch.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git merge-base:*), Bash(git rev-list:*), Bash(git symbolic-ref:*), Read, Grep, Glob
---

# Merge Brief

Summarize what enters the base branch and what the operator should reread.

## Steps

1. Resolve the base branch from `.turkit.yaml → base_branch`, remote HEAD, then `main`.
2. Compare `<base>..HEAD`; include local dirty state if present.
3. Read the smallest set of files needed to explain behavior, risk, and rollback.
4. Do not run the merge.

## Output

Emit at most 12 lines:

```markdown
Merge brief
- Base: <base branch>
- Branch: <current branch>
- Commits: <count + short subjects if <=3>
- What enters main: <one sentence>
- User impact: <none/internal/visible + one sentence>
- Risk: <one concrete risk>
- Verify before merge: <commands/manual check>
- Rollback: <revert commit/PR, config flag, redeploy previous, etc.>
- Reread: <1-3 files/hunks>
```

End with one question:

```text
Merge, hold, or review one file first?
```

## Guardrails

- Do not merge, push, or delete branches.
- If the branch is dirty, make that the first risk.
- If rollback is not obvious, say "Rollback unclear" and explain why.
