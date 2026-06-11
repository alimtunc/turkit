# Worktree Bootstrap (Literal)

The canonical worktree setup + verify sequence. Consumed by `ticket-execute` (set up
workspace) and `ticket` (execute phase). It is the single source of truth for the worktree
procedure — both skills point here instead of inlining their own bash.

A worktree is an isolated working copy checked out on its own branch. This procedure exists so
edits land in the intended working copy: the verification gate below is what prevents an `Edit`
or `Write` from silently landing in the wrong tree, where the diff never reaches the feature
branch.

## When to bootstrap a worktree

Worktrees are **opt-in**. The default is to work in the current tree on a feature branch — do
**not** spin up a worktree unprompted. Bootstrap one only when **either** of these holds:

- The operator explicitly asked for an isolated worktree.
- `.turkit.yaml → workflow.workspace` is `worktree_required`.

If `workflow.workspace` is missing or `feature_branch`, skip this procedure entirely: create or
reuse a feature branch in the current tree and edit in place.

When `worktree_required` is set and `pwd` already contains the configured `<dir>` segment, you
are inside a worktree already — skip creation, verify (Step 2), and continue.

## Parameters

Resolve these before running any command. Substitute them literally; do not reorder, skip, or
replace a step.

- `<dir>` — `.turkit.yaml → workflow.worktree_dir`, default `.worktrees`.
- `<slug>` — the ticket slug used as the worktree directory leaf.
- `<branch>` — `.turkit.yaml → workflow.branch_template` rendered with the available
  placeholders `{ticket_id}`, `{ticket_id_lower}`, `{slug}`. If no template is configured, use
  `<slug>`.
- `<base>` — the base branch, resolved per
  `docs/contracts/build-tool-detection.md#base_branch`.
- `<repo-root>` — the absolute path of the current (main) working copy, from
  `git rev-parse --show-toplevel` before you `cd`.

The worktree path is `<dir>/<slug>` (relative to `<repo-root>`).

## Step 1 — Create the worktree if it does not yet exist

```bash
git worktree list
```

If `<dir>/<slug>` is **not** listed:

```bash
git worktree add <dir>/<slug> -b <branch> <base>
```

If it **is** listed, skip creation and move on.

## Step 2 — Enter the worktree and verify (stop on mismatch)

```bash
cd <dir>/<slug> && pwd && git rev-parse --show-toplevel && git branch --show-current
```

Expected output:

- `pwd` prints the absolute path of `<dir>/<slug>`.
- `git rev-parse --show-toplevel` prints that same path.
- `git branch --show-current` prints `<branch>`.

If **any** of these three values disagrees with what you expect, **stop immediately and report
the mismatch.** Do not call any other tool, and do not edit a single file. A mismatch means
later `Edit` / `Write` calls would land in the wrong working copy and the diff would never
appear in source control for the intended branch.

## Step 3 — Copy env files into a fresh worktree

Only when the worktree was just created in Step 1 (env files are not tracked, so a fresh
worktree starts without them):

```bash
cp <repo-root>/.env* <dir>/<slug>/ 2>/dev/null || true
```

## Step 4 — Run init commands

After the worktree is set up and verified, run the project's init steps if any are configured:

- `.turkit.yaml → workflow.init` — run each listed command exactly, in order, from the worktree
  root. Stop on the first failure.
- If no `workflow.init` is configured but the repo documents init steps in its rules docs
  (`CLAUDE.md` / `AGENTS.md` / `docs/conventions/*`), run those instead.

Init commands are project-defined; this reference prescribes none.

## Step 5 — Root all subsequent tool calls at the worktree

Once verified, the worktree path is the active working directory for the rest of the session:

- Every `Read` / `Edit` / `Write` / `Glob` / `Grep` path is absolute and starts with
  `<dir>/<slug>/...` — never a bare relative path, never the original `<repo-root>`.
- Every `Bash` command either re-`cd`s into `<dir>/<slug>` first or relies on the Step 2 `cd`
  still being in effect (Bash cwd persists across calls). When in doubt, re-`cd` and re-`pwd`
  before anything non-trivial.

If you catch yourself about to edit a file under `<repo-root>` instead of `<dir>/<slug>`,
**stop** — that edit would live in the wrong working copy and never reach the feature branch.
