# VCS Host Detection Contract

Skills that open or view a pull/merge request (`ship`, `handoff`, `pr-description`) MUST resolve the host command via this order instead of hardcoding GitHub CLI (`gh`).

PR body generation always stays delegated to `pr-description`; this contract only governs **how the title/body are submitted** and **how an existing PR is viewed**.

## Resolution order

Resolve `pr_create` and `pr_view` independently. For each, use the first option that applies:

1. **`.turkit.yaml → vcs.pr_create` / `vcs.pr_view`** — explicit user override. If configured, use it verbatim with the variables below substituted.

2. **GitHub CLI (`gh`)** — when `gh` is on `PATH`:
   - create: `gh pr create --title "$TITLE" --body-file "$BODY_FILE"`
   - view: `gh pr view "$PR_NUMBER"`

3. **GitLab CLI (`glab`)** — when `glab` is on `PATH` and `gh` is not:
   - create: `glab mr create --title "$TITLE" --description "$(cat "$BODY_FILE")"`
   - view: `glab mr view "$PR_NUMBER"`

4. **Manual fallback** — no configured command and neither CLI is available. Do **not** hard-fail. Instead:
   - Print the PR title and the generated body (from `pr-description`) in a copy-pasteable block.
   - Tell the operator exactly what to do: paste them into their host's "New PR/MR" UI, or run their own host CLI.
   - Report the pushed branch name so the operator can open the PR against it.

## Configuration shape

```yaml
vcs:
  # Command run to create the PR/MR. Receives the variables below.
  pr_create: gh pr create --title "$TITLE" --body-file "$BODY_FILE"
  # Command run to view an existing PR/MR by number.
  pr_view: gh pr view "$PR_NUMBER"
```

Both keys are optional. Define one without the other if only that side needs an override.

## Supported variables

A skill substitutes these into the resolved command before running it:

- `$TITLE` — the PR/MR title (short, under ~70 chars).
- `$BODY_FILE` — path to a temp file holding the `pr-description` body. The body is passed **by file**, never inlined, so multi-line markdown and shell metacharacters never have to be quoted into the command line. If a host CLI cannot read a body file, read it with `"$(cat "$BODY_FILE")"` as shown for `glab`.
- `$PR_NUMBER` — the bare PR/MR number (no `#`), used only by `pr_view`.

Keep custom `pr_create` / `pr_view` templates simple: reference only the variables above and quote them as shown. If a host needs richer flags (reviewers, labels, target branch), put them in the template verbatim — the skill does not parse the command, it only substitutes the variables and runs it.

## Known-compatible hosts (updated as tested)

- GitHub via `gh` — tested ✅
- GitLab via `glab` — supported via the documented template, lightly tested.
- Any other host — works through an explicit `.turkit.yaml → vcs` template, or the manual fallback.
