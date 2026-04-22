# turkit

Project-agnostic Claude Code workflow skills. One plugin, ten skills: init, ticket lifecycle, reviews, ship, handoff — installable into any repo.

## Why

Because copy-pasting the same skills between projects gets old. turkit is the opinionated workflow I've found useful across codebases, in a single installable plugin.

## Install (Claude Code)

```bash
/plugin marketplace add alimtunc/turkit
/plugin install turkit@alimtunc/turkit
/turkit:init
```

The last step detects your build tool, package manager, base branch, and issue tracker, and writes a `.turkit.yaml` tailored to the repo (opt-in — nothing is written without confirmation). You can skip it and turkit still works with runtime detection.

Skills are then available as `/turkit:ticket-triage`, `/turkit:ship`, etc.

## How the ticket flow fits together

```mermaid
flowchart TD
    A[📋 New ticket] --> T[/turkit:ticket-triage/]

    T -->|one-shot — &lt; 1h| E[/turkit:ticket-execute/]
    T -->|plan-then-execute — 1h to 1d| P[/turkit:ticket-plan/]
    T -->|split-first — multi-day| S[🔀 Split into sub-tickets<br/>re-triage each]

    P -->|operator validates the plan| E
    E --> W[🔧 Implements in a worktree<br/>never commits]
    W --> V[🧪 Operator manually verifies]

    V --> PCR[/turkit:pre-commit-review/]
    PCR -. branch &gt; 1 commit .-> PPR[/turkit:pre-push-review/]
    PCR --> SHIP[/turkit:ship/]
    PPR --> SHIP
    SHIP --> DONE[🚀 PR opened + ticket Done]

    V -. helpers .-> TI[/turkit:test-instructions/]
    SHIP -. delegates to .-> PRD[/turkit:pr-description/]
    V -. escape hatch .-> HO[/turkit:handoff/<br/>resume in another session]
```

**How to read it** — the operator always drives: every arrow is a deliberate slash-command invocation, nothing auto-chains. Typical usage:

- **Small tickets**: `triage` → (`one-shot`) → `execute` → verify → `pre-commit-review` → `ship`.
- **Medium tickets**: `triage` → (`plan-then-execute`) → `plan` → operator review → `execute` → verify → `pre-commit-review` → `ship`.
- **Large tickets**: `triage` → (`split-first`) → split into sub-tickets in your tracker → start over on each.
- **Long branches**: before `ship`, run `pre-push-review` instead of (or in addition to) `pre-commit-review`.
- **Running out of context**: `handoff` at any point to pass the baton to a fresh session.

## Skills

| Skill | What it does |
|---|---|
| `/turkit:init` | Detects your project's build tool, package manager, base branch, and tracker. Proposes a `.turkit.yaml`. |
| `/turkit:ticket-triage` | Routes a ticket to one-shot / plan-then-execute / split-first. Emits a next-step prompt. |
| `/turkit:ticket-plan` | Writes a structured plan to `.claude/plans/<TICKET>.md` for operator review. |
| `/turkit:ticket-execute` | Executes a validated plan, criterion by criterion, in a worktree. Never commits. |
| `/turkit:pre-commit-review` | Reviews the current diff against clean-code principles and auto-fixes low-risk issues. |
| `/turkit:pre-push-review` | Full-branch review iterating over every commit vs. the base branch. |
| `/turkit:pr-description` | Generates a short PR description from the branch diff. |
| `/turkit:test-instructions` | Emits a concise manual-test checklist after an issue is implemented. |
| `/turkit:ship` | Commit + push + PR + close the ticket. Operator invokes after manual verification. |
| `/turkit:handoff` | Summarizes the current conversation so it can be pasted into another LLM. |

## Configuration

turkit works with zero config. Run `/turkit:init` to generate a `.turkit.yaml` tailored to your project. Typical output on a pnpm + TypeScript repo:

```yaml
commands:
  check: pnpm typecheck
  lint: pnpm lint
  fmt: pnpm format
  test: pnpm test
  build: pnpm build
base_branch: main
```

All fields optional. See `.turkit.yaml.example` for the full shape and `docs/contracts/build-tool-detection.md` for the resolution order (pnpm, bun, yarn, npm, just, make, cargo, poetry, uv, go).

## Issue tracker support

Skills that touch tickets (triage, plan, execute, ship, handoff) detect your tracker at runtime:

1. **MCP tools** whose names match `*issue*get*`, `*issue*save*`, etc. — known-good: Linear MCP.
2. **Branch-name fallback** — `sup-80-xxx` → `SUP-80`.
3. **No tracker** — skills degrade gracefully and operate without one.

See `docs/contracts/issue-tracker-detection.md` for the full detection rules.

## Codex / other platforms

SKILL.md files under `skills/` follow the standard format. Copy any folder into your Codex skills directory to use them outside Claude Code.

## Contributing

- File an issue describing the use case before a PR.
- Skill prompts stay language-agnostic and project-agnostic. Stack-specific logic belongs in separate packs.
- Commit messages: short subject, no AI credit, no `Co-Authored-By`.

## License

MIT — see [LICENSE](./LICENSE).
