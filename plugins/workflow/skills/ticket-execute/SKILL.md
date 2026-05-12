---
name: ticket-execute
description: Execute a validated plan at `.claude/plans/<TICKET>.md`. Verifies plan alignment with current code, sets up a feature branch (or worktree if the operator asks for one), implements criterion by criterion, emits a handoff. Never commits.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git checkout:*), Bash(git switch:*), Bash(git worktree:*), Bash(git diff:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write
---

# Ticket Execute

Execute a validated plan. The operator has reviewed the plan and approved its approach.

## Preconditions

- `.claude/plans/<TICKET-ID>.md` exists and looks current.
- The current branch is **not** the base branch. If it is, Step 3 will set up a feature branch (default) or a worktree (if you ask).

## Steps

1. **Read the plan** at `.claude/plans/<TICKET-ID>.md`. If missing, stop and tell the operator to run `/turkit-workflow:ticket-plan <TICKET-ID>` first.

2. **Verify plan alignment with current code.** Since the plan was written, the codebase may have moved. For each "Files to touch" entry, verify the file still exists (for Modify) or the target path is still free (for Create). Verify the plan has a `Quality contract`; if it is missing, synthesize one from the current code and update the plan before coding. If file ownership or boundaries no longer match the plan, stop and propose a plan update.

3. **Set up workspace.** Worktrees are opt-in, not default.
   - If already on a non-base branch → continue.
   - If currently on the base branch:
     - **Default** — create a feature branch in the current workspace:
       ```bash
       git checkout -b <ticket-slug>
       ```
       Base branch resolved per `docs/contracts/build-tool-detection.md#base_branch`.
     - **Opt-in worktree** — only if the operator explicitly asks for isolation (e.g., to keep the main workspace untouched while they review another branch):
       ```bash
       git worktree add .worktrees/<ticket-slug> -b <ticket-slug> <base-branch>
       cd .worktrees/<ticket-slug>
       ```
       Do NOT create a worktree silently — the operator has to ask for it.
   - If the project has init steps documented in its `CLAUDE.md` / `AGENTS.md` (copy env file, install deps), run them regardless of in-place vs worktree.

4. **Move the ticket to In Progress** if a tracker is available (per `docs/contracts/issue-tracker-detection.md`).

5. **Implement criterion by criterion.** For each acceptance criterion in the plan:
   - Read the relevant files.
   - Make the change.
   - Verify it compiles / typechecks using the project's `check` command (resolved per `docs/contracts/build-tool-detection.md`).
   - Mark the criterion `[x]` in `.claude/plans/<TICKET-ID>.md`.

6. **Self-review before handoff.** Read `git diff` and compare the implementation against the plan's `Quality contract`:
   - Reuse: no duplicated helper/component/schema when an existing one was identified.
   - Ownership: helpers/types/constants live in the planned module, not opportunistically inside entry points or render files.
   - Boundaries: no new cross-layer imports, hidden public surface, or scope creep outside the plan.
   - Simplicity: no single-call-site abstraction, dead option, debug print, unused import, or narrative comment.
   - Verification: every planned check is either run or explicitly reported as skipped with reason.

7. **Run the check/lint/fmt/test suite** at the end. Resolve commands per the build-tool contract. If React files changed, also run the React gate from the plan's stack-specific gates when available (`commands.react_review`, a package script, or the fallback described by `turkit-react`). If any fail, fix or escalate.

8. **Do NOT commit.** The operator commits after manual verification (via `/turkit-workflow:ship`).

9. **Emit a handoff** (structure matches `handoff` skill — context / decisions / what we did / pointer). Include the working path (branch name or worktree path), checks run, React gate result if applicable, and any contract deviations.

## Guardrails

- Never commit. Never push. Never create a PR.
- Never modify files outside those listed in the plan's "Files to touch" without flagging it first.
- If stuck mid-criterion, write what you tried + why it's blocked into `.claude/plans/<TICKET-ID>.md#notes` and stop.
- Respond in the conversation's language by default.
