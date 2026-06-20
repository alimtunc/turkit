---
name: handoff
description: Summarize the current conversation as a markdown block another LLM can paste in to pick up the thread. Read-only by default. Pass `ship` to delegate commit + push + PR to the `ship` skill, then append the PR pointer. Usage - /turkit:handoff or /turkit:handoff ship
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git worktree list:*), Read, Grep, Glob, Skill
---

# Handoff

Produce a markdown summary of **this conversation**, ready to paste into another LLM so it can resume the work.

## Argument

- **(none)** — summary only. Read-only: never commits, pushes, creates or removes a worktree, or updates tracker state.
- **`ship`** — delegate commit + push + PR + ticket update to the `ship` skill, then show the summary with the PR pointer.

## Default mode (summary only)

This mode is **read-only**. It inspects state with read-only git commands and writes nothing. It does **not** commit, push, create or remove worktrees, delete branches, or change tracker state — those are the operator's call (or `/turkit:handoff ship`).

1. **Gather state** with read-only commands: `git status --short`, `git branch --show-current`, `git log --oneline -5`, `git worktree list`, `git diff --stat`. Resolve the ticket (if any) via `references/issue-tracker-detection.md` — read only; do **not** update it.
2. **Write the summary** — short and high-level. The other LLM should see **where we are** and **what we did**, not a file-by-file diff. Cover:
   - Context (what we were working on, associated ticket if any).
   - Important decisions / trade-offs / pitfalls avoided.
   - What we did (functional summary + gate results: tests, lint, typecheck, and manual verification if applicable).
   - Environment state (worktree present or not, branch pushed or not, tracker status if known, PR open / bundled / none).
   - Pointer to the commit(s) — short hash + branch — telling the other LLM to read them (`git show <hash>`) for the detail.
3. **Print the summary** in a copy-pasteable markdown block (fenced).

### Optional cleanup (report, never execute)

If a worktree is no longer needed, **do not remove it.** Report the safe manual steps for the operator to run themselves once the branch is merged, e.g.:

```
Worktree <path> can be removed manually once its branch is merged:
  git worktree remove <path>
```

Never run worktree removal, branch deletion, or any state-changing git command as part of handoff.

## Ship mode (`/turkit:handoff ship`)

Shipping is delegated entirely to the `ship` skill — handoff does **not** reimplement commit, push, PR creation, or tracker updates.

1. **Draft the summary** from `git diff` and `git diff --cached` (the commit does not exist yet).
2. **Invoke the `ship` skill.** It handles commit + push + PR + ticket update. If `ship` fails (pre-commit hook, rejected push, no PR host, etc.), surface its error verbatim and do **not** print a summary.
3. **Capture the PR URL and number** from ship's output (the `PR :` line and the bare `#<PR_NUMBER>` last line).
4. **Print the summary** with the PR pointer instead of a commit pointer, in the copy-pasteable block.
5. **Re-emit ship's final block** right after the summary's closing fence. The bare `#<PR_NUMBER>` stays the very last line of the response.

## Writing rules

- **Do not list changed files.** If the other LLM needs detail, it reads the commit.
- **No "remaining work" section.** The handoff describes the current state, not a backlog.
- **Always include environment state**: worktree (path / none), branch (pushed or not), tracker (current status if known, or "no tracker"), PR (open with URL / bundled / none). That is what tells the other LLM where to resume.
- **Always include gate results** under "What we did": tests (n/n), lint, typecheck, and explicitly note if manual UI verification was not done.
- Stay factual and dense: no filler, no restating the ticket.

## Output format

Always print the summary in a **markdown code block** so the user can copy it in one click. No intro sentence before the fence, nothing after the closing fence (except in `ship` mode, where ship's trailer follows). Example:

````
```markdown
# Handoff — [ticket title or subject]

## Context
...

## Decisions / key points
...

## What we did
- ...
- Gates: `<test cmd>` X/X ✅ · `<lint cmd>` ✅ · `<check cmd>` ✅. **Manual verification <surface>: done / not yet done.**

## Environment state
- Worktree `<path>` present / none.
- Branch `<branch>` pushed to origin / not pushed.
- Tracker `<ID>`: **<status>** (reason if not Done), or "no tracker".
- PR: `<url>` / bundled with `<other PR>` / none.

## To get up to date
Read the commit(s) on branch `<branch>`:
- `<hash>` — <commit subject>

Run `git show <hash>` to see the detail.
```
````

### `ship` mode variant

Same template, with two adjustments:

- **`## Environment state`**: the `PR:` line carries the URL **and** number (`<url> (#<PR_NUMBER>)`).
- **`## To get up to date`**: point to the PR instead of the commits — `Read the PR: <url>`, then "view it with your host's PR-view command (resolved per `references/vcs-host-detection.md`, e.g. `gh pr view <PR_NUMBER>` or `glab mr view <PR_NUMBER>`)".

After the closing fence, re-emit ship's strict trailer (`✅ Shipped` … `#<PR_NUMBER>`). The bare `#<PR_NUMBER>` is the very last line of the response.

## Guardrails

- Default mode is **read-only**: never stage, commit, push, amend, create/remove worktrees, delete branches, or update tracker state.
- All tracker interaction goes through `references/issue-tracker-detection.md` and is **read-only** in default mode; tracker status changes happen only inside `ship` (ship mode).
- Worktree cleanup is reported as an optional manual step, never executed.
- Do not assume a specific PR host. Resolve PR viewing via `references/vcs-host-detection.md`.
- Apply `references/output-preferences.md` for operator-facing language/style — the summary content follows the configured language; the field labels above are a template.
