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
   - If `.claude/skills/*` or `.claude/commands/*` exists, note that the repo
     already has local Claude assets. Recommend
     `/turkit-workflow:adopt-project` after install so generic workflow skills
     do not stay duplicated locally.
   - If the tree has unrelated user changes, continue read-only until the operator approves writing `.turkit.yaml`.

2. **Detect stack packs.** Inspect root manifests and common package locations.
   - React project signals: `package.json` dependency/devDependency on `react`, `react-dom`, `next`, `@vitejs/plugin-react`, `remix`, `@remix-run/*`, `expo`, or `react-native`.
   - If React is detected, recommend:
     ```bash
     /plugin install turkit-react@turkit
     ```
   - If React is detected, also inspect `package.json` for a pinned React gate script (`react-review`, `react:review`, or `react-doctor`). If found, recommend adding it to `.turkit.yaml` as `commands.react_review`.
   - If no stack-specific pack matches, say that only `turkit-workflow` is recommended for now.
   - Do not claim a plugin is installed unless the runtime exposes that fact. Phrase recommendations as "install if not already installed".

3. **Set up project config.**
   - If `.turkit.yaml` is missing, follow [`turkit-init/SKILL.md`](../turkit-init/SKILL.md) as the source of truth to propose one.
   - If `.turkit.yaml` exists, read it and report whether required commands appear covered (`check`, `lint`, `fmt`, `test`, `build`, `base_branch`). For React projects, also report whether `commands.react_review` is configured or whether the React review will use its fallback.
   - Never overwrite or edit `.turkit.yaml` without showing the proposed content or diff and getting explicit confirmation.

4. **Emit the setup summary.** Keep it short:
   - Detected stack.
   - Recommended plugin install commands.
   - `.turkit.yaml` status: created / update proposed / already OK / skipped.
   - Suggested first quality command: `/turkit-workflow:pre-commit-review`, plus `/turkit-react:react-review` when React is detected.
   - If local Claude assets were detected, suggested migration command:
     `/turkit-workflow:adopt-project`.

## Guardrails

- This skill may only write `.turkit.yaml`, and only after explicit confirmation.
- Do not install plugins directly; output the `/plugin install ...` commands for the operator.
- Do not add React-specific rules to `.turkit.yaml`; React behavior belongs in `turkit-react`.
- Respond in the conversation's language by default.
