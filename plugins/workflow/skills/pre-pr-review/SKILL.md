---
name: pre-pr-review
description: Operator-invoked review of the full branch (every commit vs. the base branch) plus any uncommitted local changes before opening or updating a PR. Strict gatekeeper stance with per-diff and branch-level checks. Language-agnostic.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git rev-list:*), Bash(git symbolic-ref:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Pre-PR Review

Review the full branch before opening or updating a PR. This skill sees the branch as one coherent change, then adds checks that a single-diff review cannot catch. If the working tree is dirty, it also reviews the local changes against the same rubric — the operator is one step away from committing them into the PR, so they get reviewed too.

## Source of Truth

Use [`references/review-rubric.md`](references/review-rubric.md) for the shared per-diff rubric: severity, categories, fix policy, and language-agnostic checklist.

## When to Use

- `pre-commit-review` reviews staged, unstaged, and untracked local changes only.
- `pre-pr-review` reviews committed branch state (`<base>..HEAD`) plus branch-level history/intent. If the tree is dirty, it folds local changes into the same review.
- Run it before opening a PR, or before updating a PR after meaningful branch rewrites.

## Workflow

1. Resolve the base branch:
   - `.turkit.yaml → base_branch`
   - `git symbolic-ref refs/remotes/origin/HEAD`
   - fallback `main`
2. Inspect `git status --short`. Set `LOCAL_DIRTY = true` if anything is staged, unstaged, or untracked. **Do not** redirect the operator to `pre-commit-review` — they invoked `pre-pr-review` deliberately. Continue.
3. Count commits with `git rev-list --count <base>..HEAD`. If > 20, warn and ask whether to proceed.
4. Gather:
   - `git log --oneline <base>..HEAD`
   - `git log --stat <base>..HEAD`
   - `git diff <base>..HEAD`
   - `git diff <base>..HEAD --name-only`
   - `git show <hash>` only when a cross-commit finding needs deeper inspection
   - If `LOCAL_DIRTY`: also `git diff --cached`, `git diff`, and `git ls-files --others --exclude-standard`. Treat the union of staged + unstaged + untracked content as the **Local** scope; the committed `<base>..HEAD` diff is the **Branch** scope.
5. Load project rules before judging:
   - Read `.turkit.yaml` if present.
   - If it defines `rules.docs`, read the relevant listed docs.
   - Otherwise read relevant defaults when present: `CLAUDE.md`, `AGENTS.md`,
     and `docs/conventions/*.md`.
6. Run the project's lint command (`.turkit.yaml → commands.lint`, fallback per `references/build-tool-detection.md`). If unavailable, continue and report it.
7. Walk the shared rubric against the full branch diff, then apply any loaded
   project rules that are relevant to the branch. If `LOCAL_DIRTY`, walk the same rubric against the Local scope (changed hunks for staged/unstaged, full file for untracked). Label every finding with its scope (`Branch` or `Local`).
8. Walk the branch-level checklist and use the branch output sections in [`references/branch-review.md`](references/branch-review.md). The checklist applies to the Branch scope; the Local scope is judged on per-diff rubric only.
9. Apply only the shared rubric's Auto-fix bucket. Auto-fixes land unstaged on current `HEAD`; do not create/amend commits or rewrite history.
10. Re-run lint. If auto-fixes landed, the verdict cannot be `Ready for PR`; the operator must commit/amend and re-run this review.
11. Report using the output format below.

## Branch-Level Checklist

Walk the branch-level checklist and use the branch output sections in [`references/branch-review.md`](references/branch-review.md). It owns the checklist (B1–B4) and the branch output sections (Branch summary, Per-Commit, Cross-Commit, Branch-Level, Verdict). The checklist applies to the Branch scope; the Local scope is judged on per-diff rubric only.

## Output Format

> The Branch summary, Per-Commit, Cross-Commit, Branch-Level, and Verdict sections live in [`references/branch-review.md`](references/branch-review.md). The per-diff sections below are specific to this skill.

```markdown
## Mechanical Pre-pass (lint)

- Ran: `<exact command>`
- Findings kept: N
- Findings dropped as false positives: N — list with reasons
- Notable rules triggered: short list with file:line

## Local (uncommitted)

> Only present when the working tree was dirty. Findings against the per-diff rubric on staged + unstaged + untracked.

- [P0|P1] [Category] [Local] [file:line] What and why
- Or: "No findings — local diff is clean and ready to commit."

## Fixes Applied

> Auto-fixes from the shared rubric. All landed **unstaged** on current HEAD.

- [Category] [file:line] What changed

## Required Changes

- [P0|P1] [Category] [file:line | commit:<hash>] What must change and why it cannot be auto-fixed
- Suggested rebase plan, if history rewrite is required (do not execute it)

## Blocking Issues

- [P0|P1] [Category] [file:line | commit:<hash>] Rare issue not covered above

## Suggested Improvements

- [Category] Improvement and expected benefit

## Positive Signals

- Short bullet only when it reduces review ambiguity

## Verification

- Ran: exact commands
- Residual failures, if any
- Skipped: relevant checks not run and why

## Residual Risks

- Remaining uncertainty

## Review Cost

- Subagents launched: N
```

## Guardrails

- Never stage, commit, amend, rebase, reset, push, force-push, or rewrite history.
- Never edit outside branch diff scope unless an in-scope auto-fix requires a sibling/shared file.
- Branch history changes are recommendations only.
- Respond in the conversation's language by default.
