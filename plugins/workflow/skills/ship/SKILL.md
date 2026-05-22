---
name: ship
description: Commit, push, open a PR, and mark the issue done — one command to ship a finished change. Operator invokes only after manual verification.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*), Read, Grep, Glob
---

# Ship

Finalize a validated change: commit → push → PR → close out the ticket.

**Preconditions:** the operator has manually verified the change works. This skill does not run the test suite.

## Steps

1. **Confirm branch is not the base branch.** Resolve base via `docs/contracts/build-tool-detection.md#base_branch`. If `git rev-parse --abbrev-ref HEAD` equals the base, abort with a clear message — never commit on `main`/the base branch.

2. **Confirm a worktree or feature branch exists.** If on a detached HEAD or a suspicious state, abort.

3. **Stage and commit changes.**
   - Write a commit subject in the conversation's language using the project's convention if detectable (Conventional Commits if prior commits follow it — check `git log --oneline -20`).
   - Include a 1–3 sentence body only if the diff needs motivation; otherwise subject-only.
   - **Never** add `Co-Authored-By` or AI credit.
   - Run commit via HEREDOC to preserve formatting.

4. **Push.** `git push -u origin HEAD`.

5. **Create the PR** with `gh pr create`:
   - Title: short, under 70 chars.
   - Body: delegate to `/pr-description` (or re-use its output if already generated this session).
   - Use a HEREDOC for the body.

6. **Mark the ticket Done.** Via `docs/contracts/issue-tracker-detection.md`. If no tracker, skip silently.

7. **Report.** Emit the [Output format](#output-format) block exactly — no prose before it, no prose after it. The bare `#<PR_NUMBER>` MUST be the very last line of the entire response so the operator (and other tools) can extract it without parsing.

## Output format

The final response of this skill MUST end with this exact block. Fill placeholders, keep field labels and order intact, keep the blank line before `#<PR_NUMBER>`, and emit nothing after the number:

```
✅ Shipped
- Commit : <short-hash> — <subject>
- Branch : <branch>
- Ticket : <ID> → Done       (or: no tracker detected)
- PR     : <url>

#<PR_NUMBER>
```

Rules:

- **No trailing prose.** The `#<PR_NUMBER>` line is the last line of the response. Do not add a recap, next steps, or commentary after it.
- **No prefix prose.** Optionally one short status line before the block if a step needs explanation (e.g. pre-commit hook fix). Otherwise: jump straight to the block.
- **Always include all four fields** (Commit, Branch, Ticket, PR), even if redundant. If the ticket field is "no tracker detected", keep the line.
- **`#<PR_NUMBER>` is the bare PR number** prefixed by `#` (e.g. `#42`), on its own line. Not the URL, not a hash — the number.

## Guardrails

- Never `--force`, never `--no-verify`, never skip hooks.
- Never amend an already-pushed commit.
- If a pre-commit hook fails: fix the underlying issue, re-stage, create a **new** commit. Do not amend.
- Respond in the conversation's language by default.
