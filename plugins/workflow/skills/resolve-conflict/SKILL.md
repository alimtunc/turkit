---
name: resolve-conflict
description: Use when a git merge, rebase, cherry-pick, release script, or backport pauses on conflicts, or when git status shows unmerged paths/conflicted files. Resolve conflict markers only, preserve the intended current and incoming changes, verify no conflicts remain, and stop before git add/continue/commit/push.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git show:*), Bash(git log:*), Bash(git ls-files:*), Bash(git rev-parse:*), Bash(rg:*), Bash(grep:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Resolve Conflict

Resolve the current git conflicts and stop. Do not stage files or continue the merge/rebase/cherry-pick.

## Workflow

1. **Confirm conflict state.**
   - Run `git status --short`.
   - Run `git diff --name-only --diff-filter=U`.
   - If no conflicted files are listed, stop and report that there is nothing to resolve.

2. **Understand each side before editing.**
   For every conflicted file:
   - Read the working file with markers.
   - Inspect the combined conflict with `git diff --cc -- <file>`.
   - When text stages exist, inspect:
     - `git show :1:<file>` = common base
     - `git show :2:<file>` = ours / current target branch
     - `git show :3:<file>` = theirs / incoming merge, rebase, or cherry-pick side
   - Use `git status` text to infer whether this is a merge, rebase, or cherry-pick. During a release/backport/cherry-pick conflict, prefer preserving the incoming commit's intent when both sides are valid.

3. **Resolve semantically.**
   - Prefer integrating both sides when they are compatible.
   - Prefer incoming changes only when both sides are valid alternatives and the current operation is clearly a cherry-pick/backport/release replay.
   - Preserve target-branch invariants, imports, API shapes, formatting, and nearby conventions.
   - If a conflict is structural or product/architecture intent is ambiguous, stop and ask which direction to keep.
   - For delete/modify conflicts, binary files, lockfiles, or generated files, do not guess. Explain the options and ask unless the correct resolution is obvious from the operation and surrounding files.

4. **Edit only conflicted files.**
   - Remove all `<<<<<<<`, `=======`, `>>>>>>>`, and related marker lines.
   - Do not refactor unrelated code.
   - Do not edit files that are not part of the conflict unless a resolved conflicted file cannot compile without a directly required adjacent edit; if that happens, report it explicitly.

5. **Verify conflict cleanup.**
   Run:
   ```bash
   git diff --name-only --diff-filter=U
   git diff --check
   rg -n '^(<<<<<<<|=======|>>>>>>>)' . || true
   ```
   If `rg` is unavailable, use `grep -RInE '^(<<<<<<<|=======|>>>>>>>)' . || true`.

6. **Report and stop.**
   Output:
   ```markdown
   ## Conflict Resolution

   Status: resolved | partial | blocked
   Files:
   - <file> - <resolution summary>
   Verification:
   - <commands run and result>
   Needs operator:
   - <none or decisions needed>

   Next steps for operator:
   - Review the diff.
   - Run git add / continue / commit yourself or let the release script continue.
   ```

## Hard Rules

- Never run `git add`, `git commit`, `git merge --continue`, `git rebase --continue`, `git cherry-pick --continue`, `git push`, `git reset`, or `git abort`.
- Never choose `ours` or `theirs` blindly.
- Never leave conflict markers in files.
- Never claim conflicts are resolved until `git diff --name-only --diff-filter=U` is empty.
- Apply `references/output-preferences.md` for operator-facing language/style.
