# turkit

Project-agnostic Agent-Skills for AI-assisted development. Turkit adds a reusable workflow around coding agents: ticket planning, review, shipping, handoff, and small human-understanding gates before commits, merges, and releases.

The skills use the open [Agent-Skills](https://github.com/vercel-labs/skills) `SKILL.md` format with colocated references. They run on Codex, Claude Code, Cursor, Gemini, and any Agent-Skills host. Claude Code plugin install is supported, but the simplest path is `npx skills add`.

## Install

```bash
npx skills add alimtunc/turkit
```

The CLI lets you choose one or more target agents interactively. You can use the skills immediately after install. The `install` skill is optional: run it only when you want a repo diagnostic, stack-pack recommendations, or a proposed `.turkit.yaml` / `AGENTS.md` setup.

### Claude Code Plugin Alternative

Claude Code users can install through the plugin marketplace instead of `npx`:

```bash
/plugin marketplace add alimtunc/turkit
/plugin install turkit@turkit

# Optional React pack
/plugin install turkit-react@turkit
```

`turkit` replaces the old `turkit-workflow` plugin name. Existing v1 commands moved from `/turkit-workflow:<skill>` to `/turkit:<skill>`.

## Recommended Workflow

```mermaid
flowchart LR
    T["ticket"] --> A["plan approval"]
    A --> E["execute<br/>never commits"]
    E --> R["review"]
    R --> S["ship"]

    T -. "focused modes" .-> F["--triage<br/>--plan<br/>--execute<br/>--grill"]
    E -. "non-ticket objective" .-> G["goal-loop"]
    E -. "pause/resume" .-> H["handoff"]
    S -. "understand before irreversible steps" .-> B["merge-brief<br/>release-brief"]
```

Use `/turkit:ticket` by default. It reads the ticket, chooses one-shot / standard / split, produces a plan, pauses once for approval, then executes without committing.

| Command | Use when |
|---|---|
| `/turkit:ticket <ticket>` | Default ticket flow: plan -> approval -> execute -> handoff. |
| `/turkit:ticket --triage <ticket>` | Classify scope and stop. |
| `/turkit:ticket --plan <ticket>` | Write/present the plan and stop before edits. |
| `/turkit:ticket --execute <ticket>` | Execute an already-approved `.claude/plans/<TICKET>.md`. |
| `/turkit:ticket --grill <ticket>` | Add a `grill-me` challenge before plan approval. |

`ticket-triage`, `ticket-plan`, and `ticket-execute` were folded into these flags in `turkit` v3.0.0. Same behavior, smaller public command surface.

## Skills

Names below are skill names. In Claude Code, use `/turkit:<skill>` for core workflow skills and `/turkit-react:react-review` for the React pack. On other Agent-Skills hosts, invoke the same skill by name.

| Skill | Pack | What it does |
|---|---|---|
| `ticket` | `turkit` | Main ticket workflow: plan, approval, execute, and handoff; supports `--triage`, `--plan`, `--execute`, and `--grill`. |
| `goal-loop` | `turkit` | Iterates on a bounded non-ticket objective until criteria pass, budget is exhausted, or a human decision is needed. |
| `goal-review` | `turkit` | Review/fix loop for a diff, branch, or repo; useful when you want the agent to keep fixing until clean. |
| `pre-commit-review` | `turkit` | Strict review of the current working-tree diff before committing. |
| `pre-pr-review` | `turkit` | Strict full-branch review before opening or updating a PR. |
| `react-review` | `turkit-react` | React 19+ review focused on component boundaries, hooks, JSX hygiene, types, and unnecessary effects. |
| `resolve-conflict` | `turkit` | Resolves current git merge/rebase/cherry-pick conflicts without staging, continuing, committing, or pushing. |
| `grill-me` | `turkit` | Challenges a ticket, plan, or design before implementation. |
| `zoom-out` | `turkit` | Builds a compact map when the code area, diff, branch, or feature feels confusing. |
| `explain-diff` | `turkit` | Explains staged, unstaged, or branch changes in a short operator-readable brief. |
| `teachback-gate` | `turkit` | Asks the operator to explain the change back before commit, PR, push, or release. |
| `merge-brief` | `turkit` | Summarizes what enters the base branch, risks, verification, rollback, and files to reread. |
| `release-brief` | `turkit` | Summarizes release target, public delta, risk, verification, and rollback. |
| `pr-description` | `turkit` | Writes a concise PR description from the branch diff. |
| `test-instructions` | `turkit` | Produces a short manual-test checklist after implementation. |
| `ship` | `turkit` | Commit, push, open a PR, and close the ticket with host fallbacks. |
| `handoff` | `turkit` | Creates a read-only session handoff for another agent or a later session. |
| `rules-refresh` | `turkit` | Reviews a rules document and proposes keep, sharpen, redundant, or stale updates. |
| `install` | `turkit` | Optional setup diagnostic: recommends packs and proposes `.turkit.yaml`, `AGENTS.md`, or `GEMINI.md` changes. |
| `turkit-init` | `turkit` | Proposes a `.turkit.yaml` from detected commands, base branch, tracker, workflow, and rules docs. |
| `adopt-project` | `turkit` | Migrates repos that already have local Claude skills, commands, or duplicated workflow rules. |

## Human-Control Gates

These are intentionally compact and read-only. They are meant to help the operator understand and decide, not produce another long audit.

```text
Before coding      /turkit:grill-me
When lost          /turkit:zoom-out
Before commit      /turkit:explain-diff
Before ship        /turkit:teachback-gate
Before merge       /turkit:merge-brief
Before release     /turkit:release-brief
```

## Optional Project Config

You do **not** need `.turkit.yaml` to try Turkit. The skills detect common package managers, base branches, issue trackers, and PR hosts at runtime, then degrade to manual fallbacks when something is missing.

Add `.turkit.yaml` only when you want to pin project-specific behavior:

- commands such as `check`, `lint`, `test`, `build`, or `react_review`
- rule docs to load before planning/reviewing
- branch/worktree policy
- PR host overrides for GitHub, GitLab, Bitbucket, Gerrit, etc.
- review strictness knobs

Minimal example:

```yaml
commands:
  check: pnpm typecheck
  lint: pnpm lint
  test: pnpm test
base_branch: main
rules:
  docs:
    - CLAUDE.md
    - AGENTS.md
    - docs/conventions/*.md
```

Run `install` for guided setup, or `turkit-init` when you only want a proposed `.turkit.yaml`. See [.turkit.yaml.example](.turkit.yaml.example) for the full schema.

## Portability Notes

- **Issue trackers are optional.** Turkit resolves tickets from MCP tracker tools when available, then branch names, then operator-provided descriptions. No tracker is a supported mode.
- **PR hosts are optional.** `ship` resolves PR creation through `.turkit.yaml`, then `gh`, then `glab`, then prints a manual fallback.
- **Parallel orchestration is optional.** When a host has Workflow/Task/Agent tools, Turkit uses them for faster surveys and reviews. Without them, skills run the same steps sequentially.
- **Goal loops are bounded.** `goal-loop` defaults to a small round budget and stops on ambiguity, repeated verification failure, or scope expansion.
- **References are self-contained.** Shared rubrics and detection contracts are vendored into each skill so per-skill installs work outside this repo.

## Maintainers

Canonical shared files live in two places:

- `plugins/<plugin>/references/` for shared rubrics/templates
- `docs/contracts/` for detection contracts

Run these before publishing:

```bash
scripts/sync-references.sh
scripts/check-references.sh
scripts/test-sync-references.sh
```

`scripts/sync-references.sh` vendors canonical references into each consuming skill. `scripts/check-references.sh` fails on drift, leftover `../../references/` links, or direct `docs/contracts/*` citations from skill files.

## Contributing

- File an issue describing the use case before a PR.
- Workflow skills stay language-agnostic. Stack-specific logic belongs in its own `turkit-<stack>` plugin.
- Commit messages: short subject, no AI credit, no `Co-Authored-By`.

## License

MIT — see [LICENSE](./LICENSE).
