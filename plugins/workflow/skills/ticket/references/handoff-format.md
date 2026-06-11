# Execution Handoff Format

The canonical handoff block emitted at the end of an execution pass. Consumed by
`ticket-execute` (step 9) and `ticket` (verify + handoff phase). It is the single source of
truth for the handoff shape — both skills point here instead of inlining their own.

The handoff is a status report, not an action. It **suggests** the next operator steps
(`/goal-review`, then commit) and never runs them: review and commit are always
operator-gated.

## Template

Fill every field. Use the literal labels below so the operator can scan the block at a glance.
For Workspace, name the branch when working in the current tree, or the absolute worktree path
when a worktree was used. List one line per modified file.

```
Ticket: <TICKET-ID> — <title>
Source: <plan file path | inline mini-plan>
Workspace: <branch name | worktree path>
Branch: <branch name>
Files modified:
  - path/to/file1 — <1 line: what changed>
  - path/to/file2 — <1 line: what changed>
Criteria covered: [1, 2, 3]
Criteria not covered: [list, or "none"]
Manual tests done: [list, or "none"]
Blockers/questions: [list, or "none"]

Suggested next actions for the operator (do NOT run these yourself):
  - Invoke `/goal-review` to review + fix the work (`--diff` before commit, `--branch` before PR).
  - Commit when ready, following the repo's commit convention (see CLAUDE.md / the repo's
    rules docs).
```

## Field notes

- **Source** — the plan file path (`.claude/plans/<TICKET-ID>.md`) for a `standard`/`split`
  route, or `inline mini-plan` for a `one-shot` route with no plan file.
- **Workspace / Branch** — Workspace is the branch name when execution ran in the current tree,
  or the absolute worktree path when a worktree was used. Branch is always the feature branch
  name. Use `n/a (current branch)` for Workspace only when no worktree was involved.
- **Criteria covered / not covered** — reference the numbered acceptance criteria from the plan.
  Every criterion belongs in exactly one of the two lists.
- **Manual tests done** — only tests actually run by hand this session; do not list checks you
  assumed or skipped.
- **Blockers/questions** — anything that stopped a criterion or needs an operator decision; the
  matching detail belongs in `.claude/plans/<TICKET-ID>.md#notes` when a plan file exists.

## Suggested-actions block

The suggested-actions block is fixed: it names `/goal-review` and the commit, prefixed with
"do NOT run these yourself" so the orchestrator never auto-chains them.

- **`/goal-review`** — `--diff` reviews the working tree before a commit; `--branch` reviews the
  committed branch before a PR. Suggest the mode that matches where the operator is headed.
- **Commit** — phrase it as "follow the repo's commit convention". Resolve the convention from
  the repo's own rules docs (`CLAUDE.md` / `AGENTS.md` / `docs/conventions/*`); do not hardcode
  a tracker-specific rule such as a ticket id in the commit subject.
