---
name: teachback-gate
description: Use before commit, merge, push, PR, or release when the operator wants to prove they understand what is about to be sent.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git tag:*), Bash(git describe:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Read, Grep, Glob
---

# Teachback Gate

The operator should be able to explain the change before it leaves the machine.

## Steps

1. Inspect the relevant target:
   - local diff for commit;
   - branch diff for merge/PR;
   - changelog, versions, and tags for release.
2. Produce a brief under 12 lines.
3. Ask the operator to explain the change back in exactly three bullets.
4. If the operator's explanation misses a key behavior, risk, or rollback fact, ask one follow-up question.
5. If the explanation is good enough, say `Gate passed` and list the next safe command.

## Brief shape

```markdown
Teachback brief
- Sending: <commit|merge|PR|release + target>
- Change: <one sentence>
- Why: <one sentence>
- Risk: <one concrete risk>
- Verify: <evidence or command>
- Rollback: <how to undo>
```

Then ask:

```text
Explain this back in 3 bullets before we continue.
```

## Guardrails

- Do not perform the commit, merge, push, PR, or release.
- Do not accept vague teachback like "it fixes stuff" or "looks good".
- Do not output a long audit.
- If the diff is too large to summarize safely, say what slice must be reviewed first.
