# turkit

Project-agnostic agent skills — ticket lifecycle, code review, ship, handoff. Authored as a Claude Code marketplace, but the skills use the open [Agent-Skills](https://github.com/vercel-labs/skills) format, so they also run on Codex, Cursor, Gemini, and any Agent-Skills host. See [Install on other agents](#install-on-codex--cursor--gemini--any-agent-skills-host).

Two plugins today; more to come:

- **`turkit-workflow`** — ticket lifecycle, code review, ship, handoff, rules-refresh. The workflow backbone that works in any repo.
- **`turkit-react`** — opinionated React review. Modern React 19+ only, strict component boundaries, disciplined hooks.

## Install (Claude Code)

```bash
# One-time: register the marketplace
/plugin marketplace add alimtunc/turkit

# Install the core workflow (everyone)
/plugin install turkit-workflow@turkit

# Optional: add the React pack
/plugin install turkit-react@turkit

# Per-project setup (detects stack packs + writes .turkit.yaml, opt-in)
/turkit-workflow:install
```

**Not on Claude Code?** Codex / Cursor / Gemini / any Agent-Skills host install with a single `npx skills add` command — see [Install on other agents](#install-on-codex--cursor--gemini--any-agent-skills-host).

## How the ticket flow fits together

```mermaid
flowchart TD
    A["📋 New ticket"] --> CHOICE{"single-session<br/>or multi-session?"}

    CHOICE -->|"single-session (Workflow-native)"| TK["/turkit-workflow:ticket<br/>intake → reuse-survey plan →<br/>one approval pause → execute → handoff"]
    CHOICE -->|"multi-session"| T["/turkit-workflow:ticket-triage"]

    T -->|"one-shot — under 1h"| E["/turkit-workflow:ticket-execute"]
    T -->|"plan-then-execute — 1h to 1d"| P["/turkit-workflow:ticket-plan"]
    T -->|"split-first — multi-day"| S["🔀 Split into sub-tickets<br/>re-triage each"]

    P -->|"operator validates the plan"| E
    E --> W["🔧 Implements on a feature branch<br/>(worktree if requested, never commits)"]
    TK --> W
    W --> V["🧪 Operator manually verifies"]

    V -. "operator-invoked review+fix loop<br/>review → fix until clean, then verify" .-> GR["/turkit-workflow:goal-review<br/>--diff / --branch / --repo"]
    V --> PCR["/turkit-workflow:pre-commit-review"]
    PCR -. "branch has multiple commits" .-> PPR["/turkit-workflow:pre-pr-review"]
    PCR --> SHIP["/turkit-workflow:ship"]
    PPR --> SHIP
    GR -. "back to the operator" .-> SHIP
    SHIP --> DONE["🚀 PR opened + ticket Done"]

    V -. "helper" .-> TI["/turkit-workflow:test-instructions"]
    SHIP -. "delegates to" .-> PRD["/turkit-workflow:pr-description"]
    V -. "escape hatch" .-> HO["/turkit-workflow:handoff<br/>resume in another session"]
```

**Typical usage:**
- **Small tickets**: `ticket-triage` → `ticket-execute` → `pre-commit-review` → `ship`.
- **Medium tickets**: `ticket-triage` → `ticket-plan` → operator validates → `ticket-execute` → `pre-commit-review` → `ship`.
- **Large tickets**: `ticket-triage` (split-first) → split into sub-tickets → re-triage each.
- **Long branches**: `pre-pr-review` instead of (or in addition to) `pre-commit-review`.
- **Running out of context**: `handoff` at any point.
- **Stack-specific review**: pair `pre-commit-review` with `/turkit-react:react-review` for React-specific findings.
- **Rules drifting**: `/turkit-workflow:rules-refresh <path>` to re-audit a rules doc against the current Claude version.
- **Existing local Claude skills**: `/turkit-workflow:adopt-project` to migrate project-specific rules into `.turkit.yaml`/docs and archive duplicated local workflow skills.

**Two ways to run the ticket flow.** The multi-session `ticket-triage` → `ticket-plan` → `ticket-execute` chain (each a discrete step, ideal across separate sessions) stays the default. New and **additive**: the single-session `/turkit-workflow:ticket` orchestrator, which runs intake/route → reuse-survey plan → **one approval pause** → execute → handoff in a single Workflow-native session. Pick `/ticket` when you want one continuous run with a single checkpoint; pick the three-step chain when you want explicit hand-offs between sessions.

**Two review entry points.** The single-shot `pre-commit-review` / `pre-pr-review` skills stay the default. New and **additive**: the operator-invoked `/turkit-workflow:goal-review` loop, which iterates review → fix until clean (on `--branch`) before a final verification pass. Pick `/goal-review` when you want it to keep fixing until the diff/branch/repo is clean; pick `pre-commit-review` / `pre-pr-review` for a single pass tied to a commit or PR.

## `turkit-workflow` skills

| Skill | What it does |
|---|---|
| `/turkit-workflow:install` | Bootstraps Turkit in a repo: detects stack-specific packs (React when applicable), prints plugin install commands, and sets up `.turkit.yaml` via the init workflow. |
| `/turkit-workflow:adopt-project` | Migrates an existing repo that already has local `.claude/skills` or `.claude/commands`: keeps project-specific knowledge, updates `.turkit.yaml`, and archives workflow duplicates outside the active skill path. |
| `/turkit-workflow:turkit-init` | Detects the project's build tool, package manager, base branch, tracker, proposes `.turkit.yaml`. |
| `/turkit-workflow:ticket` | Single-session orchestrator: intake/route → reuse-survey plan → one plan-approval pause → execute → handoff. Never commits; suggests `/goal-review` at the end. The Workflow-native alternative to the multi-session `ticket-triage` → `ticket-plan` → `ticket-execute` chain. |
| `/turkit-workflow:ticket-triage` | Routes a ticket to one-shot / plan-then-execute / split-first. |
| `/turkit-workflow:ticket-plan` | Writes a structured plan to `.claude/plans/<TICKET>.md` for operator review. |
| `/turkit-workflow:ticket-execute` | Executes a validated plan on a feature branch (worktree opt-in). Never commits. |
| `/turkit-workflow:goal-review` | Operator-invoked review+fix loop over `--diff` / `--branch` / `--repo`. Loops review → fix until clean (on `--branch`) then runs a final verification pass. Never commits. The looping alternative to the single-shot `pre-commit-review` / `pre-pr-review`. |
| `/turkit-workflow:pre-commit-review` | Strict review of the current diff. Mechanical pre-pass via the project's lint, judgment pass against an opinionated checklist (SOC, DRY, over-engineering, comments, types, error handling). Auto-fixes mechanical violations (unstaged), surfaces judgment calls as required changes. |
| `/turkit-workflow:pre-pr-review` | Strict full-branch review vs. the base branch before opening or updating a PR. Same per-diff rubric as `pre-commit-review`, plus branch-level checks (per-commit coherence, cross-commit drift, dead intermediate files, intent). Auto-fixes mechanical violations. |
| `/turkit-workflow:pr-description` | Concise PR description from the branch diff. |
| `/turkit-workflow:test-instructions` | Short manual-test checklist post-implementation. |
| `/turkit-workflow:ship` | Commit + push + PR + close the ticket. Host-agnostic: resolves the PR command via `.turkit.yaml → vcs`, then `gh`, then `glab`, then a manual fallback. |
| `/turkit-workflow:handoff` | Summarize the current conversation for another LLM. **Read-only by default** (never commits, pushes, removes worktrees, or touches the tracker). Accepts `ship` to delegate shipping to `ship` after the summary. `/shipoff` is a thin command alias for `/handoff ship`. |
| `/turkit-workflow:rules-refresh` | Audit a rules doc and propose Keep / Sharpen / Add-rationale / Redundant / Stale updates. |

## `turkit-react` skills

| Skill | What it does |
|---|---|
| `/turkit-react:react-review` | Strict React review (React 19+). Mechanical pre-pass via [`react-doctor`](https://www.npmjs.com/package/react-doctor) (oxlint-based), judgment pass against an opinionated checklist (useless `useEffect`, SOC inside `.tsx`, JSX hygiene, hooks discipline, types). Auto-fixes mechanical violations (unstaged), surfaces judgment calls as required changes. |

## Configuration

Run `/turkit-workflow:install` for full setup (stack pack recommendations + `.turkit.yaml`). Run `/turkit-workflow:turkit-init` when you only want to generate or update `.turkit.yaml`. Example output on a pnpm + TypeScript repo:

```yaml
commands:
  check: pnpm typecheck
  lint: pnpm lint
  fmt: pnpm format
  test: pnpm test
  build: pnpm build
  # Optional, used by /turkit-react:react-review when present.
  react_review: pnpm react-review
base_branch: main
workflow:
  workspace: feature_branch # or worktree_required
  worktree_dir: .worktrees
  branch_template: "{ticket_id_lower}-{slug}"
  init:
    - pnpm install
rules:
  docs:
    - CLAUDE.md
    - docs/conventions/*.md
# Optional: override the PR host (otherwise gh → glab → manual fallback).
vcs:
  pr_create: gh pr create --title "$TITLE" --body-file "$BODY_FILE"
  pr_view: gh pr view "$PR_NUMBER"
# Optional: review strictness knobs (defaults shown).
review:
  strictness: standard # relaxed | standard | strict
  comments: allow-why-only # allow | allow-why-only | zero-new-comments
  react:
    min_version: 19
```

All fields optional. See `.turkit.yaml.example` for the full shape and `docs/contracts/build-tool-detection.md` for the resolution order (pnpm, bun, yarn, npm, just, make, cargo, poetry, uv, go).

**Review strictness.** The review skills/rubrics default to the current strict behavior (`strictness: standard`, `comments: allow-why-only`, React 19+). Projects can opt down — `relaxed` downgrades P1 cleanup findings to suggestions (P0 structural/behavioral findings always stay blocking), `zero-new-comments` forbids any added comment — without editing the skill files. `review.react.min_version` keeps React 19+ as the `turkit-react` default while making the rule configurable.

## Issue tracker support

Skills that touch tickets detect your tracker at runtime:

1. **MCP tools** whose names match `*issue*get*`, `*issue*save*`, etc. — known-good: Linear MCP.
2. **Branch-name fallback** — `sup-80-xxx` → `SUP-80`.
3. **No tracker** — skills degrade gracefully and operate without one.

See `docs/contracts/issue-tracker-detection.md` for the full detection rules.

## VCS host support

`ship` (PR create) and `handoff` (PR view) are not tied to GitHub. They resolve the host command in this order:

1. **`.turkit.yaml → vcs.pr_create` / `vcs.pr_view`** — explicit override (variables: `$TITLE`, `$BODY_FILE`, `$PR_NUMBER`).
2. **GitHub CLI** (`gh`) when available.
3. **GitLab CLI** (`glab`) when available.
4. **Manual fallback** — prints the PR title/body and the pushed branch so you can open it in your host UI. No hard failure when no CLI is installed.

PR body generation stays delegated to `pr-description`. See `docs/contracts/vcs-host-detection.md` for the full resolution and config shape.

## Install on Codex / Cursor / Gemini / any Agent-Skills host

Turkit skills use the open Agent-Skills format (`SKILL.md`), so they install on any agent that supports it via [`npx skills`](https://github.com/vercel-labs/skills) — no Claude Code required. Turkit's `.claude-plugin/marketplace.json` makes the skills discoverable directly from the repo, and each skill is **self-contained** (its `references/` travel with it), so per-skill install works on every host.

```bash
npx skills add alimtunc/turkit -a codex          # Codex
npx skills add alimtunc/turkit -a claude-code    # Claude Code (alternative to /plugin install)
npx skills add alimtunc/turkit -a cursor         # Cursor
npx skills add alimtunc/turkit -a gemini         # Gemini CLI
```

| Agent | Skills land in | Update |
|---|---|---|
| Codex | the agent's skills dir (`.agents/skills` / `~/.codex/skills`) | re-run `npx skills add …` |
| Claude Code | `~/.claude/skills/` (or use `/plugin install …@turkit`) | re-run, or `/plugin` update |
| Cursor / Gemini / Copilot / … | each agent's own skills dir | re-run `npx skills add …` |

After installing, run the `turkit-init` skill in your agent to generate `.turkit.yaml` (and optionally `AGENTS.md`) for the project. The Claude Code plugin marketplace flow (`/plugin install turkit-workflow@turkit`) remains the Claude-native option and is unchanged.

**Maintainers — canonical sources vs. denormalized copies.** Two kinds of shared content are single-sourced and vendored into each consumer skill so per-skill installs stay self-contained:

- **Shared rubrics/templates** — canonical under `plugins/<plugin>/references/` (e.g. `review-rubric.md`, `branch-review.md`, `worktree-bootstrap.md`).
- **Detection contracts** — canonical under `docs/contracts/` (`build-tool-detection.md`, `issue-tracker-detection.md`, `vcs-host-detection.md`). Skills cite them as `references/<contract>.md`, never the repo-root path.

`scripts/sync-references.sh` copies both into each skill's own `references/` (rewriting any `../../references/` sibling links to `references/`); `scripts/check-references.sh` fails on drift — a colocated copy that differs from its canonical source, a leftover `../../references/` link, or a skill that still cites repo-root `docs/contracts/*` directly. `react-rubric.md` has no canonical under either root, so it is its own source and is left untouched. Run `scripts/sync-references.sh` before publishing a release; the React rubric is edited in place.

## Contributing

- File an issue describing the use case before a PR.
- Workflow skills stay language-agnostic. Stack-specific logic belongs in its own `turkit-<stack>` plugin.
- Commit messages: short subject, no AI credit, no `Co-Authored-By`.

## License

MIT — see [LICENSE](./LICENSE).
