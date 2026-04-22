---
name: pre-push-review
description: Full-branch review iterating over every commit vs. the base branch. Catches issues that emerge across multiple commits (renamed-then-stale references, commits that undo each other, a commit that passes tests individually but breaks a later one). Language-agnostic, principles-only.
---

# Pre-Push Review

Review a feature branch **holistically** before pushing or opening a PR. Complements `pre-commit-review` (which looks at a single diff).

## Scope

- Input: the set of commits on the current branch vs. the base branch.
- Output: a structured report covering (a) per-commit findings, (b) cross-commit findings, (c) branch-level assessment.
- **Does not auto-fix.** Pre-push is a stop-and-think checkpoint; fixes should be a deliberate operator action.

## Steps

1. **Resolve the base branch** via `docs/contracts/build-tool-detection.md#base_branch`.

2. **Gather the branch state.**
   - `git log --oneline <base>..HEAD` — commit list
   - `git log --stat <base>..HEAD` — per-commit diffstats
   - `git diff <base>..HEAD` — total diff
   - For each commit: `git show <hash>` when cross-commit findings need deeper inspection.

3. **Per-commit pass.** For each commit:
   - Does the subject describe the change accurately?
   - Is the commit self-contained (does it make sense without the next ones)?
   - Are there leftover debug prints, `console.log`, `dbg!()`, commented-out code?

4. **Cross-commit pass.** Look for:
   - Symbols renamed in an early commit but still referenced in later commits or in leftover files.
   - Code added in commit N and deleted in commit N+2 (wasted motion — can the intermediate commits be squashed?).
   - Tests added for a behavior that a later commit subtly changes.
   - Two commits that individually pass CI but break together when their changes interact.
   - A "fixup" commit that indicates the previous commit should be amended (operator choice).

5. **Branch-level pass.**
   - Does the branch as a whole match its stated intent (ticket / PR title)?
   - Is the public API surface change minimal and intentional?
   - Are all added files actually used?
   - Are there files that should have been split across commits?

6. **Emit the report** in the format below. Do not modify files.

## Report format

```
Pre-push review — <N> commits, <base>..HEAD

PER-COMMIT
- <hash> <subject>: <OK | 1-line finding>
- …

CROSS-COMMIT
- <finding> | <affected commits> | <suggested action>
- …

BRANCH-LEVEL
- Intent match: <OK | comment>
- API surface: <OK | comment>
- Dead files: <none | list>
- Commit granularity: <OK | comment>

VERDICT
- <ready to push | needs N fixes before push | reconsider branch structure>
```

Respond in the conversation's language by default.

## Guardrails

- Read-only. Never edits files.
- Never rewrites git history (no rebase, no amend, no reset).
- If the branch has > 20 commits, warn the operator and ask whether to proceed (very large reviews often indicate the branch should be split).
