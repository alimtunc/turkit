---
name: adopt-project
description: Adopt Turkit in an existing repository that already has local Claude skills, commands, or rules. Classifies local workflow duplicates vs project-specific knowledge, asks the operator what to keep/merge/archive, then applies the confirmed migration.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git symbolic-ref:*), Bash(date:*), Bash(mkdir:*), Bash(mv:*), Read, Grep, Glob, Write, Edit, MultiEdit
---

# Adopt Project

Use this when Turkit is installed in a repo that already has `.claude/skills`,
`.claude/commands`, `CLAUDE.md`, `AGENTS.md`, or project convention docs. The
goal is to avoid two active workflow systems.

## Policy

- Turkit owns generic workflow: ticket triage/plan/execute, review, PR
  description, test instructions, ship, handoff, rules refresh.
- The project owns project knowledge: architecture, commands, branch naming,
  worktree policy, setup steps, stack conventions, business rules.
- Prefer not to keep a local skill active when a Turkit skill now owns the same
  job. Recommend extracting useful project rules into docs or `.turkit.yaml`,
  then archiving it outside `.claude/skills`, but let the operator choose.
- Do not delete local skills. Archive them unless the operator explicitly asks
  for deletion.

## Turkit-owned names

Treat local skills/commands with these names as likely workflow duplicates:

`install`, `turkit-init`, `ticket-triage`, `ticket-plan`, `ticket-execute`,
`pre-commit-review`, `pre-pr-review`, `pr-description`, `test-instructions`,
`ship`, `handoff`, `rules-refresh`, `grill-change`, `zoom-out`,
`explain-diff`, `teachback-gate`, `merge-brief`, `release-brief`,
`react-review`.

## Steps

1. **Inspect the repo.**
   - Read `git status --short`.
   - Read `.turkit.yaml` if present.
   - Read `.claude/settings.json` if present.
   - List `.claude/skills/*` and `.claude/commands/*`.
   - Read `CLAUDE.md`, `AGENTS.md`, and `docs/conventions/*.md` when present.

2. **Classify local assets and prepare a decision table.**
   For every local skill/command, propose one of these actions:

   - `keep-active`: project-specific, no Turkit equivalent.
   - `merge-then-archive`: generic workflow duplicate with useful project rules
     that should move into docs or `.turkit.yaml` first.
   - `archive`: generic workflow duplicate fully covered by Turkit.
   - `leave-for-now`: ambiguous; keep active until the operator decides.

   Use this table format:

   ```markdown
   | Asset | Proposed action | Why | Extract to |
   |---|---|---|---|
   | `.claude/skills/ticket-execute` | merge-then-archive | Turkit owns execution; local skill has worktree/init rules | `.turkit.yaml → workflow` |
   ```

3. **Propose `.turkit.yaml` updates.**
   Include only fields justified by the repo:

   ```yaml
   commands:
     check: <command>
     lint: <command>
     fmt: <command>
     test: <command>
     build: <command>
     react_review: <command> # only for React repos
   base_branch: main
   workflow:
     workspace: feature_branch # or worktree_required
     worktree_dir: .worktrees
     branch_template: "{ticket_id_lower}-{slug}"
     init:
       - <copy env / install deps / seed config command>
   rules:
     docs:
       - CLAUDE.md
       - docs/conventions/*.md
   ```

   Keep commands literal and copy-pasteable. Do not invent commands.

4. **Show the migration plan before writing.**
   Output:
   - What Turkit will own.
   - What remains project-local.
   - The decision table for each local skill/command.
   - `.turkit.yaml` diff or full proposed file.
   - Archive moves, with source and destination paths.

5. **Ask for explicit confirmation.**
   Do not ask a yes/no question for the whole migration unless every proposed
   action is unambiguous. Ask the operator to confirm or override decisions:

   ```text
   Confirme les actions à appliquer:
   - apply recommended
   - keep-active: <assets>
   - archive: <assets>
   - leave-for-now: <assets>
   ```

   Only after a clear confirmation:
   - Update `.turkit.yaml`.
   - Move only confirmed duplicate local skills/commands to
     `docs/turkit-migration/legacy-claude-assets/`.
   - Leave `.claude/settings.json` plugin enablement intact.

6. **Generate or merge `AGENTS.md` and `GEMINI.md`.**
   Use the canonical body in `references/agents-md-template.md` and resolve
   its three placeholders (`<PROJECT>`, `<RULES_DOCS>`, `<SKILLS_PATH>`) from
   detection, pointing `<RULES_DOCS>` at wherever the adopted conventions ended
   up after migration.

   - If `AGENTS.md` does not exist, write the substituted body to `AGENTS.md`.
   - If `AGENTS.md` already exists, **preserve the project-specific content**.
     Keep the project's own sections verbatim and append (or refresh) only the
     `## Workflow (operator-invoked)` section plus the one-line rules-docs
     pointer if absent. Never overwrite an existing `AGENTS.md`.
   - `GEMINI.md` uses the same body: default to a one-line pointer to `AGENTS.md`
     when `AGENTS.md` is present; write the full body only when no `AGENTS.md`
     exists.

   Show the diff and get confirmation before writing either file.

7. **Verify.**
   - Re-list `.claude/skills` and `.claude/commands`.
   - Confirm `AGENTS.md` (and `GEMINI.md`) carry the workflow section and that
     pre-existing project content is intact.
   - Show `git status --short`.
   - Recommend `/turkit:install` or the relevant review command next.

## Guardrails

- Never archive a project-specific skill unless the operator explicitly confirms
  that action.
- If an asset is ambiguous, default its proposed action to `leave-for-now`.
- Never leave archived workflow duplicates under `.claude/skills`; active
  duplicates cause drift.
- Never overwrite docs with extracted content silently. If extraction is
  ambiguous, report the target doc and exact rule to add.
- Never clobber an existing `AGENTS.md`. Preserve every project-specific section
  and only append or refresh the workflow section; the body in
  `references/agents-md-template.md` stays a thin pointer and carries no
  project-specific hard rules.
- Respond in the conversation's language by default.
