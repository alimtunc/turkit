---
name: grill-change
description: Use when the operator wants to stress-test a planned change, ticket, design, or AI-generated plan before implementation starts.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Read, Grep, Glob
---

# Grill Change

Pressure-test the change until the operator and agent share the same understanding.

## Steps

1. Inspect the current branch, working tree, recent commits, and any referenced ticket/plan/docs that are available locally.
2. If the answer is in the repo, read the repo instead of asking.
3. Ask **one question at a time**. Each question must include:
   - the decision or risk being tested;
   - the recommended answer;
   - why that answer is the safer default.
4. Prefer concrete edge cases over abstract debate.
5. Stop when the remaining uncertainty is low enough to implement, then output the compact decision record below.

## Output

When the grill is complete, emit only:

```markdown
Decision record
- Change: <one sentence>
- Chosen approach: <one sentence>
- Rejected alternative: <one sentence>
- Main risk: <one sentence>
- Verification: <one sentence>
```

## Guardrails

- Do not implement.
- Do not ask multiple questions at once.
- Do not produce a long plan unless the operator asks for one.
- If the operator is stuck, propose the smallest reversible next step.
