---
name: install
description: "Bootstrap Turkit in a repository. Use when setting up Turkit skills for a project: detect the stack, recommend workflow/react plugin installs, and create or update .turkit.yaml only after operator confirmation."
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Read, Grep, Glob, Write, Edit
---

# Turkit Install

Set up Turkit for the current repository. This is an operator-invoked bootstrap; do not run automatically.

## Steps

1. **Confirm repository context.**
   - Read the repo root and current branch.
   - Inspect `git status --short`.
   - Read global Turkit preferences if present (`~/.config/turkit/config.yaml`, then `~/.turkit.yaml`) and report only inherited `output.*` / `workflow.token_budget`.
   - If `.claude/skills/*` or `.claude/commands/*` exists, note that the repo
     already has local Claude assets. Recommend
     `/turkit:adopt-project` after install so generic workflow skills
     do not stay duplicated locally.
   - If the tree has unrelated user changes, continue read-only until the operator approves writing `.turkit.yaml`.

2. **Detect stack packs.** Inspect root manifests and common package locations.
   - React project signals: `package.json` dependency/devDependency on `react`, `react-dom`, `next`, `@vitejs/plugin-react`, `remix`, `@remix-run/*`, `expo`, or `react-native`.
   - If React is detected, recommend:
     ```bash
     /plugin install turkit-react@turkit
     ```
   - If React is detected, also inspect `package.json` for a pinned React gate script (`react-review`, `react:review`, or `react-doctor`). If found, recommend adding it to `.turkit.yaml` as `commands.react_review`.
   - If no stack-specific pack matches, say that only `turkit` is recommended for now.
   - Do not claim a plugin is installed unless the runtime exposes that fact. Phrase recommendations as "install if not already installed".

3. **Set up project config.**
   - If `.turkit.yaml` is missing, follow [`turkit-init/SKILL.md`](../turkit-init/SKILL.md) as the source of truth to propose one.
   - If `.turkit.yaml` exists, read it and report whether required commands appear covered (`check`, `lint`, `fmt`, `test`, `build`, `base_branch`) and whether optional `commands.dev`, repo overrides for `workflow.token_budget`, `output.style`, `output.language`, and `output.technical_terms` are configured or inherited globally. For React projects, also report whether `commands.react_review` is configured or whether the React review will use its fallback.
   - Never overwrite or edit `.turkit.yaml` without showing the proposed content or diff and getting explicit confirmation.

4. **Generate `AGENTS.md` + `GEMINI.md` (multi-LLM entry points).** Give non-Claude agents (Codex, Gemini, …) a thin pointer at the turkit workflow without restating project rules. Use [`references/agents-md-template.md`](references/agents-md-template.md) as the source of truth for the body and merge rules.
   - Resolve the three placeholders:
     - `<PROJECT>` — a `name` field in the root manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, …) if present, else the repo directory name (`git rev-parse --show-toplevel` basename).
     - `<RULES_DOCS>` — `.turkit.yaml → rules.docs` if set; else whichever of `CLAUDE.md`, an existing separate `AGENTS.md`, or `docs/conventions/` actually exist. If none exist, write `the repo's conventions (none detected yet — see CLAUDE.md once added)`.
     - `<SKILLS_PATH>` — the installed `turkit` plugin's `skills/` directory, or `.claude/skills/` if the repo has adopted the skills locally. **If it resolves to the plugin path** (no local copy), warn in the summary that this path is Claude-Code-local and machine-specific: a committed `AGENTS.md` pointing there will not resolve for Codex/Gemini on another machine or in CI. Recommend `/turkit:adopt-project` to vendor the skills into `.claude/skills/` for a portable in-repo path.
   - Fill the template body with those values.
   - Write `AGENTS.md` at the repo root with the substituted body **only if it does not already exist**. Never clobber an existing `AGENTS.md`: if one is present, append a clearly-marked `## Workflow (operator-invoked) — turkit` section instead, and skip entirely if that section is already present.
   - Write `GEMINI.md` at the repo root. Default to the one-line pointer (`See [AGENTS.md](AGENTS.md). Same workflow guidance applies to Gemini.`) when `AGENTS.md` is present, to avoid two copies drifting; write the full body into `GEMINI.md` only when the repo has no `AGENTS.md`. Apply the same never-clobber/append-only merge semantics if a `GEMINI.md` already exists.
   - Show the proposed file or diff and get explicit confirmation before writing. Never inject project-specific hard rules (React/i18n/import-alias/etc.) into the body — those stay in `<RULES_DOCS>`.

5. **Emit the setup summary.** Keep it short:
   - Detected stack.
   - Global preferences status: none / inherited / ignored project-specific or invalid keys.
   - Recommended plugin install commands.
   - `.turkit.yaml` status: created / update proposed / already OK / skipped.
   - `AGENTS.md` / `GEMINI.md` status: created / section appended / already OK / skipped.
   - Available skills now reachable: `/ticket` (with `--triage`, `--plan`, `--execute`, `--grill`, `--fast`), `/goal-loop`, `/goal-review`, plus `pre-commit-review` / `pre-pr-review`.
   - Conflict helper now reachable: `/turkit:resolve-conflict`.
   - Preview helper now reachable: `/turkit:preview-test`.
   - Upgrade cleanup now reachable: `/turkit:clean-skill`.
   - Understanding gates now reachable: `/turkit:zoom-out`, `/turkit:work-brief`, `/turkit:explain-diff`, `/turkit:teachback-gate`, `/turkit:merge-brief`, `/turkit:release-brief`.
   - Suggested first quality command: `/turkit:pre-commit-review`, plus `/turkit-react:react-review` when React is detected.
   - If local Claude assets were detected, suggested migration command:
     `/turkit:adopt-project`.

## Guardrails

- This skill may only write `.turkit.yaml`, `AGENTS.md`, and `GEMINI.md`, and only after explicit confirmation. Never clobber an existing `AGENTS.md`/`GEMINI.md`; append a marked section instead.
- Do not install plugins directly; output the `/plugin install ...` commands for the operator.
- Do not add React-specific rules to `.turkit.yaml`; React behavior belongs in `turkit-react`.
- Apply `references/output-preferences.md` for operator-facing language/style.
