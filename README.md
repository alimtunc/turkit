# turkit

Project-agnostic Claude Code workflow skills. One plugin, nine skills: ticket lifecycle, reviews, ship, handoff — installable into any repo.

## Why

Because copy-pasting the same skills between projects gets old. turkit is the opinionated workflow I've found useful across codebases, in a single installable plugin.

## Install (Claude Code)

```bash
/plugin marketplace add SuperTurk/turkit
/plugin install turkit@SuperTurk/turkit
```

Skills are then available as `/turkit:ticket-triage`, `/turkit:ship`, etc.

## Skills

| Skill | What it does |
|---|---|
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

turkit works with zero config. For explicit overrides, drop a `.turkit.yaml` at your repo root:

```yaml
commands:
  check: just check
  lint: just lint
  fmt: just fmt
  test: cargo test --workspace
  build: just build
base_branch: main
```

All fields optional. See `.turkit.yaml.example` for the full shape and `docs/contracts/build-tool-detection.md` for the resolution order.

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
