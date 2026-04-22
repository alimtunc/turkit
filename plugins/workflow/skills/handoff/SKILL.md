---
name: handoff
description: Summarize the current conversation so it can be pasted into another LLM to continue the work. Commits pending changes, returns worktree work to the parent branch, optionally marks the issue as done, then outputs a copy-pasteable markdown summary.
---

# Handoff

Produce a markdown summary of **this conversation**, ready to paste into another LLM so it can pick up where you left off.

## Steps

1. **Commit pending changes.** Follow the project's commit rules (concise subject, no `Co-Authored-By`). If nothing to commit, skip.

2. **Worktree → parent branch.** If the current workspace is a git worktree:
   - Identify the parent branch (the branch the worktree was created from).
   - Push the worktree commits to the parent branch: `git push origin HEAD:<parent-branch>` (or cherry-pick if the history has diverged).
   - Exit the worktree back to the parent workspace.
   - Remove the worktree: `git worktree remove <path>`.
   - Verify the commits landed on the parent branch: `git log --oneline -5`.

3. **Move the issue to Done** (optional). If an issue tracker is available (per `docs/contracts/issue-tracker-detection.md`) and a ticket ID is associated with the conversation, update its status to the tracker's "Done" equivalent. Skip silently if no tracker.

4. **Write the summary.** Keep it short and high-level. The goal is for the other LLM to understand **where we are** and **what we did**, not every file change. Cover:
   - Context (what we were working on, associated ticket if any)
   - Important decisions, trade-offs, and pitfalls avoided
   - What we did (functional summary, not a file list)
   - Pointer to commit(s) — short hash + branch — with an explicit instruction to `git show <hash>` to get the full detail.

5. **Display the summary** in a copy-pasteable markdown block (triple-backtick fenced).

## Writing rules

- **Do not list modified files.** If the other LLM needs detail, it reads the commit.
- **No "remaining work" section.** The handoff describes current state, not a backlog.
- Factual and dense: no filler, no restating the ticket.
- Respond in the conversation's language by default.

## Output format

Always wrap the summary in a fenced markdown block so the operator can one-click copy. Example:

```
# Handoff — [ticket or topic]

**Context.** …

**Decisions / pitfalls.** …

**What we did.** …

**Pointers.** Commit `abc1234` on `feat/foo`. Run `git show abc1234` for the full diff.
```
