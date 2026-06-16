# Ticket: Fix turkit portability and workflow over-fit issues

## Goal

Apply the reconciled audit findings for `turkit` so the skill library is more
LLM-agnostic, project-agnostic, and maintainable without removing the existing
Claude Code marketplace flow.

This is implementation work. Read the relevant source before editing:

- `plugins/*/skills/*/SKILL.md`
- `plugins/*/commands/*.md`
- `plugins/*/references/*.md`
- `docs/contracts/*.md`
- `.turkit.yaml.example`
- `README.md`
- `scripts/sync-references.sh`
- `scripts/check-references.sh`

Do not read only the audit summary. Trust the repository source when there is a
conflict.

## Background

Two independent audits were reconciled. The strongest agreed findings were:

- `handoff` is the weakest skill: it commits by default, hardcodes Linear, and
  has risky worktree cleanup behavior.
- `ship` is too coupled to GitHub CLI (`gh pr create`).
- `shipoff` is useful ergonomically, but it is only an alias for `handoff ship`
  and should not be a standalone skill.
- French load-bearing instructions reduce portability for non-French users.
- `references/` copies are intentional and should stay self-contained, but
  `docs/contracts/*` should also be vendored or otherwise made available to
  per-skill installs.
- Review rubrics are too opinionated without project-level strictness knobs.

Reconciled composite targets after the fixes:

- Agnostic-readiness should move above 68/100.
- General-purpose fit should move above 63/100.

## Scope

### 1. Normalize French load-bearing sections to English

Update these skills so all procedural, output-format, and guardrail text is in
English:

- `plugins/workflow/skills/handoff/SKILL.md`
- `plugins/workflow/skills/shipoff/SKILL.md`, if it remains during migration
- `plugins/workflow/skills/ticket-plan/SKILL.md`
- `plugins/workflow/skills/ticket-triage/SKILL.md`

Keep this behavior:

- Respond in the conversation's language by default.

Acceptance criteria:

- No French-only operational instructions remain.
- Examples and output blocks are English and copy-pasteable.
- Workflow behavior is unchanged except where this ticket explicitly changes it.
- Remove author-specific example details that do not generalize.

### 2. Fix `handoff`

Current problems:

- Default mode commits all uncommitted changes before summarizing.
- It hardcodes Linear instead of using the tracker detection contract.
- It can remove a worktree as part of handoff cleanup.
- `handoff ship` partially overlaps with `ship`.

Required behavior:

- `/handoff` default mode is summary-only and read-only.
- `/handoff` must never commit, push, remove worktrees, or update tracker state.
- `/handoff ship` delegates shipping to `ship`; it must not reimplement
  commit, push, PR creation, or tracker updates.
- Remove direct Linear references. Any tracker interaction must go through
  `docs/contracts/issue-tracker-detection.md`.
- Do not automatically remove worktrees. If cleanup is useful, report safe
  manual cleanup steps instead.

Acceptance criteria:

- `handoff` contains no direct `Linear`, `save_issue`, `stateId`, or `DEV-XXXX`
  workflow logic.
- Default `handoff` is read-only.
- Ship mode delegates to `ship`.
- Output remains concise and copy-pasteable.
- Worktree cleanup is reported as an optional manual step, not executed.

### 3. Add VCS host abstraction

`ship` currently assumes GitHub CLI. Add a generic PR-host detection contract.

Create:

- `docs/contracts/vcs-host-detection.md`

The contract should define PR creation and PR viewing resolution in this order:

1. `.turkit.yaml -> vcs.pr_create` and `.turkit.yaml -> vcs.pr_view`, if
   configured.
2. GitHub CLI, `gh`, when available.
3. GitLab CLI, `glab`, when available.
4. Manual fallback: generate the PR title/body and tell the operator what to
   run or paste in their host UI.

Update:

- `plugins/workflow/skills/ship/SKILL.md`
- `plugins/workflow/skills/pr-description/SKILL.md`
- `plugins/workflow/skills/handoff/SKILL.md`
- `.turkit.yaml.example`
- `README.md`

Acceptance criteria:

- `ship` no longer hard-requires `gh`.
- Existing GitHub flow still works.
- Non-GitHub users get a manual fallback instead of a hard failure.
- PR body generation remains delegated to `pr-description`.
- `handoff` does not assume `gh pr view`.

Suggested `.turkit.yaml` shape:

```yaml
vcs:
  pr_create: gh pr create --title "$TITLE" --body-file "$BODY_FILE"
  pr_view: gh pr view "$PR_NUMBER"
```

If shell quoting makes generic command templates too fragile, define the config
shape more conservatively in the contract and explain the supported variables.

### 4. Replace `shipoff` skill with a command alias

`shipoff` is just `handoff ship`. Keep the user experience, remove the standalone
skill.

Implement:

- Remove or deprecate `plugins/workflow/skills/shipoff/`.
- Add `plugins/workflow/commands/shipoff.md` as a thin command wrapper invoking
  `handoff ship`.
- Update `README.md` inventory and any plugin metadata if needed.

Acceptance criteria:

- `/shipoff` UX still exists.
- `shipoff` is no longer counted as an independent skill.
- No duplicated handoff or ship logic remains.

Recommended command wording:

```md
---
description: Shortcut for handoff ship: ship the branch and produce a handoff summary.
argument-hint: ""
---

Invoke the `handoff` skill with the argument `ship`.
```

Adjust syntax to match the repository's command conventions.

### 5. Vendor `docs/contracts/*` into skill references

The README says each skill is self-contained. Current shared references are
denormalized into each consumer skill, but many skills still cite repo-root
`docs/contracts/*`.

Required behavior:

- Skills installed individually must still be able to resolve build-tool,
  tracker, and VCS-host detection instructions.
- Keep canonical sources in `docs/contracts/` or choose a new canonical location,
  but make per-skill copies available where needed.
- Update sync/check scripts so drift is detected.

Update:

- `scripts/sync-references.sh`
- `scripts/check-references.sh`
- skills that currently cite `docs/contracts/*`
- README maintainer notes

Acceptance criteria:

- Skills no longer depend on repo-root `docs/contracts/*` for per-skill install
  correctness.
- `scripts/check-references.sh` catches drift for vendored contracts.
- `scripts/sync-references.sh` updates generated copies.
- README explains canonical source versus denormalized copies clearly.
- Do not collapse intentional `references/` copies into shared relative links.

### 6. Add review strictness profiles

The review rubrics are useful but too opinionated without project-level knobs.

Add `.turkit.yaml` support for review strictness, for example:

```yaml
review:
  strictness: standard # relaxed | standard | strict
  comments: allow-why-only # allow | allow-why-only | zero-new-comments
  react:
    min_version: 19
```

Update:

- `plugins/workflow/references/review-rubric.md`
- `plugins/react/skills/react-review/references/react-rubric.md`
- any generated/copied rubric references
- `.turkit.yaml.example`
- `README.md`

Acceptance criteria:

- Default behavior remains close to the current strict behavior.
- Projects can opt down without editing the skill files.
- React 19+ remains the default for `turkit-react`, but the rule is documented
  as configurable.
- Rubrics explain how to apply relaxed, standard, and strict modes without
  becoming vague.
- Sync generated references after editing canonical rubrics.

## Verification

Run:

```bash
scripts/sync-references.sh
scripts/check-references.sh
```

Then run any existing repository formatting/check command if available and
reasonable for this repo.

Report:

- Files changed
- Behavior changes
- Commands run
- Any unresolved tradeoffs

## Constraints

- Do not change unrelated files.
- Do not commit.
- Preserve the Claude Code marketplace install path.
- Preserve the `npx skills add ...` install path.
- Keep skills self-contained.
- Do not remove useful user-facing commands just because their implementation is
  consolidated.

## Expected final outcome

The library should keep its existing workflow value while reducing the biggest
portability blockers:

- No French-only operational instructions.
- `handoff` is safe and read-only by default.
- `ship` can work outside GitHub.
- `/shipoff` remains available as a command alias, not a standalone skill.
- Per-skill installs can resolve contracts.
- Review strictness can be adapted per project.
