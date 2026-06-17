---
name: release-brief
description: Use before publishing a tag, package, plugin, app, or marketplace release when the operator wants a compact understanding of what becomes public.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git tag:*), Bash(git describe:*), Bash(git rev-list:*), Read, Grep, Glob
---

# Release Brief

Explain what becomes public before a release is published.

## Steps

1. Inspect working tree cleanliness, current branch, recent commits, latest tags, changelog, manifest versions, and release docs/scripts when present.
2. Identify the release target: plugin/package/app/tag. If unclear, say so.
3. Summarize only the public delta since the last relevant tag or release commit.
4. Do not tag, publish, push, or create a release.

## Output

Emit at most 12 lines:

```markdown
Release brief
- Target: <package/plugin/app>
- Version/tag: <planned or detected>
- Public delta: <one sentence>
- Users affected: <who notices>
- Breaking change: <yes/no + one sentence>
- Verify before release: <commands/manual check>
- Rollback: <how to undo/publish next fix>
- Reread: <changelog/manifest/core files>
```

End with one question:

```text
Release, hold, or run teachback-gate first?
```

## Guardrails

- Do not release.
- Do not assume SemVer level when the changelog or commits disagree; surface the conflict.
- If no rollback path exists, make that the main risk.
