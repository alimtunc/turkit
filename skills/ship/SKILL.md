---
name: ship
description: Commit, push, open a PR, and mark the issue done — one command to ship a finished change. Operator invokes only after manual verification.
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

7. **Report.** Show the operator the PR URL, the commit short hash, and confirm the ticket transition (or state "no tracker detected").

## Guardrails

- Never `--force`, never `--no-verify`, never skip hooks.
- Never amend an already-pushed commit.
- If a pre-commit hook fails: fix the underlying issue, re-stage, create a **new** commit. Do not amend.
- Respond in the conversation's language by default.
