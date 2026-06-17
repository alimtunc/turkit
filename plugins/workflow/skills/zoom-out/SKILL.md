---
name: zoom-out
description: Use when the operator feels lost in a codebase, diff, PR, module, or feature and needs a higher-level map before deciding what to do.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Read, Grep, Glob
---

# Zoom Out

Give the operator a map of the area, not a file-by-file dump.

## Steps

1. Inspect the requested area. If no area is named, use the current diff or branch.
2. Identify the smallest useful boundary: feature, module, workflow, route, package, or subsystem.
3. Trace only the relevant callers, callees, data flow, and domain terms.
4. Explain at the highest level that still lets the operator make the next decision.

## Output

Emit at most 12 lines:

```markdown
Map
- Area: <feature/module/workflow>
- Purpose: <what this area does>
- Entry points: <1-3 files/functions/commands>
- Flow: <A -> B -> C>
- Key state/data: <important models/config/files>
- Owners/boundaries: <what belongs here vs elsewhere>
- Current change touches: <why these files matter>
- Risk to understand: <one risk>
- Open next: <the one file or command to inspect next>
```

## Guardrails

- Do not explain every file.
- Do not make changes.
- If the map is uncertain, state the uncertainty instead of guessing.
- Use the project's own vocabulary when docs or code reveal it.
