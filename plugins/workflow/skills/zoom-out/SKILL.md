---
name: zoom-out
description: Use when the operator feels lost in a codebase, diff, PR, module, feature, file, function, config, script, or tool and needs a short explanation before deciding what to do.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Read, Grep, Glob
---

# Zoom Out

Give the operator a short, useful explanation of the area, not a file-by-file dump.

## Steps

1. Inspect the requested area. If no area is named, use the current diff or branch.
2. Identify the smallest useful boundary: function, file, config, script, feature, module, workflow, route, package, or subsystem.
3. Trace only the relevant callers, callees, data flow, and domain terms.
4. Read `references/output-preferences.md` and apply the configured output language/style.
5. Explain at the highest level that still lets the operator make the next decision.

## Output

Emit 8-18 lines. Prefer short explanatory prose plus a few bullets over a rigid field dump. Keep technical terms in code spans when helpful.

```markdown
<area> in brief

<1-2 short sentences: what it does and why it exists.>

Flow: <entry> -> <important step> -> <result>

What it connects / protects:
- <rule, boundary, owner, state, or dependency>
- <rule, boundary, owner, state, or dependency>

Key points:
1. <main reason this shape exists>
2. <main constraint or edge case>

Risk: <one concrete risk>
Open next: <one file/function/command>
```

Translate headings naturally according to `references/output-preferences.md`. For `language: fr`, prefer concise French connective prose while keeping technical nouns in English when `technical_terms: keep-english`.

## Guardrails

- Do not explain every file.
- Do not make changes.
- If the map is uncertain, state the uncertainty instead of guessing.
- Use the project's own vocabulary when docs or code reveal it.
- Do not output a long audit. If the target is large, explain the top-level map and name the next smaller area to inspect.
