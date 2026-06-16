---
name: ship
description: Commit, push, open a PR, and mark the issue done — one command to ship a finished change. Operator invokes only after manual verification.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(command -v:*), Bash(mktemp:*), Bash(gh pr create:*), Bash(glab mr create:*), Read, Grep, Glob, Write, Skill
---

# Ship

Finalize a validated change: commit → push → PR → close out the ticket.

**Preconditions:** the operator has manually verified the change works. This skill does not run the test suite. It does not hard-require GitHub CLI — the PR host is resolved per `references/vcs-host-detection.md`.

## Steps

1. **Confirm branch is not the base branch.** Resolve base via `references/build-tool-detection.md#base_branch`. If `git rev-parse --abbrev-ref HEAD` equals the base, abort with a clear message — never commit on `main`/the base branch.

2. **Confirm a worktree or feature branch exists.** If on a detached HEAD or a suspicious state, abort.

3. **Stage and commit changes.**
   - Write a commit subject in the conversation's language using the project's convention if detectable (Conventional Commits if prior commits follow it — check `git log --oneline -20`).
   - Include a 1–3 sentence body only if the diff needs motivation; otherwise subject-only.
   - **Never** add `Co-Authored-By` or AI credit.
   - Run commit via HEREDOC to preserve formatting.

4. **Push.** `git push -u origin HEAD`.

5. **Create the PR.** Resolve the create command via `references/vcs-host-detection.md` (`.turkit.yaml → vcs.pr_create`, else `gh`, else `glab`, else the manual fallback).
   - Title: short, under 70 chars (`$TITLE`).
   - Body: delegate to `/pr-description` (or re-use its output if already generated this session). Write it to a temp file and pass it as `$BODY_FILE` so multi-line markdown never has to be shell-quoted.
   - Detect CLIs with `command -v gh` / `command -v glab` before choosing a fallback. Do not treat "CLI missing" as an error when the manual fallback is available.
   - If a configured custom `vcs.pr_create` command is blocked by the host/tool sandbox, do not bypass approval. Print the exact manual command plus title/body/branch and use the manual fallback output.
   - **No PR host available** (no config, no `gh`, no `glab`): do not fail. Print the title + body and the pushed branch name, and tell the operator to open the PR in their host UI or CLI. Report with `PR : opened manually — <branch>` and the `#<PR_NUMBER>` line carrying the number the operator assigns (or `#-` if unknown).

6. **Mark the ticket Done.** Via `references/issue-tracker-detection.md`. If no tracker, skip silently.

7. **Report.** Emit the [Output format](#output-format) block exactly — no prose before it, no prose after it. The bare `#<PR_NUMBER>` MUST be the very last line of the entire response so the operator (and other tools) can extract it without parsing.

## Output format

The final response of this skill MUST end with this exact block. Fill placeholders, keep field labels and order intact, keep the blank line before `#<PR_NUMBER>`, and emit nothing after the number:

```
✅ Shipped
- Commit : <short-hash> — <subject>
- Branch : <branch>
- Ticket : <ID> → Done       (or: no tracker detected)
- PR     : <url>                (or: opened manually — <branch>)

#<PR_NUMBER>
```

Rules:

- **No trailing prose.** The `#<PR_NUMBER>` line is the last line of the response. Do not add a recap, next steps, or commentary after it.
- **No prefix prose.** Optionally one short status line before the block if a step needs explanation (e.g. pre-commit hook fix). Otherwise: jump straight to the block.
- **Always include all four fields** (Commit, Branch, Ticket, PR), even if redundant. If the ticket field is "no tracker detected", keep the line. If the PR was opened manually (no host CLI), use `opened manually — <branch>`.
- **`#<PR_NUMBER>` is the bare PR number** prefixed by `#` (e.g. `#42`), on its own line. Not the URL, not a hash — the number. If the host could not assign one (manual fallback), use `#-`.

## Guardrails

- Never `--force`, never `--no-verify`, never skip hooks.
- Never amend an already-pushed commit.
- If a pre-commit hook fails: fix the underlying issue, re-stage, create a **new** commit. Do not amend.
- Do not assume GitHub. Resolve PR creation per `references/vcs-host-detection.md`; a missing host CLI degrades to the manual fallback, never a hard failure.
- Custom `vcs.pr_create` commands may require operator approval depending on the host/tool sandbox. If approval is unavailable, use the manual fallback.
- Respond in the conversation's language by default.
