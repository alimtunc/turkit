# AGENTS.md / GEMINI.md generated body

The canonical body that `install` and `adopt-project` write into a target repo's
`AGENTS.md` (and `GEMINI.md`). It is a **thin pointer**: it tells non-Claude agents
(Codex, Gemini, …) where the project's real rules live and how to invoke the turkit
workflow. It carries **no** project-specific hard rules — those stay in the repo's own
rules docs, which this body points at.

## Template body

Write this verbatim into the target file, substituting the placeholders.

```markdown
# <PROJECT> — agent guide

Conventions live in <RULES_DOCS>. This file points non-Claude agents (Codex, Gemini,
…) at the turkit workflow; it does not restate the project's rules. If this file ever
disagrees with <RULES_DOCS>, the rules docs win.

## Workflow (operator-invoked)

Single-session orchestrators:

- /ticket — intake + route (one-shot / standard / split) → reuse-survey plan → one
  plan-approval pause → execute criterion by criterion → handoff. Never commits;
  suggests /goal-review, never auto-runs it. Use --triage, --plan, or --execute
  when you only want that slice; use --grill to challenge the plan before approval;
  use --fast for a lower-token run with compact output.
- /goal-loop — bounded objective loop for non-ticket work, refactors, cleanup, docs,
  or ticket follow-up. Turns the goal into criteria, edits in rounds, verifies, and
  stops when complete, blocked, or the round budget is exhausted. Never commits.
- /goal-review — review + fix loop (--diff / --branch / --repo). --branch loops
  review→fix until clean, then a final verification pass; --diff and --repo are
  single-pass. Never commits.

Focused modes:

- /ticket --triage — classify the ticket and stop.
- /ticket --plan — write/present the plan and stop before edits.
- /ticket --execute — execute an already-approved .claude/plans/<TICKET-ID>.md.
- /ticket --fast — run the normal ticket flow with narrow reuse survey and compact
  output. Safety gates still apply.
- Reviews: pre-commit-review (working tree) / pre-pr-review (committed branch).

Understanding gates:

- zoom-out when lost, visual-map for a standalone visual HTML doc with nested
  boxes, package arrows, database relations, and a directional feature path,
  work-brief after AI work, explain-diff before commit, teachback-gate before
  ship, merge-brief before merge, release-brief before release.

Conflict helper:

- resolve-conflict resolves current git merge/rebase/cherry-pick conflicts only.
  It never stages files, continues the operation, commits, pushes, resets, or aborts.

Preview helper:

- preview-test tests deployed PR previews from `.turkit.yaml → preview.url_template`
  or an operator-provided URL, with no hardcoded preview host.

Upgrade cleanup:

- clean-skill audits installed skill folders for stale Turkit-owned skills left
  behind by additive updates. It deletes only confirmed stale paths.

Read each skill's SKILL.md under <SKILLS_PATH> for the full procedure. No Workflow
tool? The skills degrade to parallel agents, then to sequential steps — same behavior,
only the mechanism differs. Never commit without an explicit request.
```

## Placeholders and how the generator resolves each

- `<PROJECT>` — the project name. Resolve from the repo: a `name` field in the root
  manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, …) if present, else the
  repository directory name (`git rev-parse --show-toplevel` basename).
- `<RULES_DOCS>` — the human-readable pointer to where conventions live. Resolve from
  `.turkit.yaml → rules.docs` (list the entries, e.g. `CLAUDE.md` + `docs/conventions/*.md`).
  If `.turkit.yaml` has no `rules.docs`, fall back to whichever of `CLAUDE.md`,
  `AGENTS.md` (the existing one, if separate), or `docs/conventions/` actually exist. If
  none exist, write `the repo's conventions (none detected yet — see CLAUDE.md once added)`.
- `<SKILLS_PATH>` — where the turkit skills live so the agent can read each `SKILL.md`.
  The skills ship inside the **installed plugin**, not the target repo, so point at the
  installed `turkit` plugin's `skills/` directory (resolve from the plugin
  install location). If the repo has adopted the skills locally (`.claude/skills/`), point
  there instead — **strongly prefer this for Codex/Gemini.** The plugin path is
  Claude-Code-local and machine-specific: a committed `AGENTS.md` pointing at it will not
  resolve for a non-Claude agent on another machine or in CI. When the only available path
  is the plugin path, the generator should recommend `/turkit:adopt-project` (which
  vendors the skills into `.claude/skills/`) so this pointer becomes a portable, committable
  in-repo path.

## How install fills this in

1. Resolve the three placeholders above from detection (manifest/repo name,
   `.turkit.yaml → rules.docs` else the existing convention docs, installed plugin
   `skills/` path else local `.claude/skills/`).
2. If `AGENTS.md` does not exist, write the substituted body to `AGENTS.md`.
3. If `AGENTS.md` already exists, do **not** clobber project content. Add or refresh only
   the `## Workflow (operator-invoked)` section (and the one-line rules-docs pointer line
   if absent), leaving the rest intact. Show the diff and get confirmation before writing.
4. Never inject project-specific hard rules (no Zod/React/i18n/import-alias rules) into
   this body — those belong in `<RULES_DOCS>`, which the body already references.

`adopt-project` uses the same body. On migration it reconciles any existing `AGENTS.md`:
keep the project's own sections, replace a stale or duplicated workflow section with this
one, and point `<RULES_DOCS>` at wherever the adopted conventions ended up.

## GEMINI.md

`GEMINI.md` uses the **same body** as `AGENTS.md`. If the repo prefers a single source,
write `GEMINI.md` as a one-line pointer instead:

```markdown
# <PROJECT> — agent guide

See [AGENTS.md](AGENTS.md). Same workflow guidance applies to Gemini.
```

Default to the one-line pointer when `AGENTS.md` is present, to avoid two copies drifting;
write the full body into `GEMINI.md` only when the repo has no `AGENTS.md`.
