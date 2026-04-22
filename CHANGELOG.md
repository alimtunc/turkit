# Changelog

All notable changes to turkit are tracked here. The project follows [SemVer](https://semver.org/).

## turkit v1.0.0 — 2026-04-22

### Breaking

- Repo restructured from a single plugin to a **marketplace** with two plugins: `turkit-workflow` and `turkit-react`.
- Slash-command namespace: `/turkit:xxx` → `/turkit-workflow:xxx` (or `/turkit-react:xxx`).
- Install command changed: `/plugin install turkit@alimtunc/turkit` → `/plugin install turkit-workflow@alimtunc/turkit` (plus optional `turkit-react`).
- No compatibility shim for v0.2.0 users — uninstall the old plugin and install the new ones.

### Added

- **`turkit-workflow` v1.0.0**: bundled the 10 existing workflow skills, plus a new `rules-refresh` meta-skill that audits any rules document and proposes Keep / Sharpen / Add-rationale / Redundant / Stale updates on a single confirmation.
- **`turkit-react` v0.1.0**: new plugin with a single `react-review` skill. 13 opinionated rules across modern React, component boundaries, conditional rendering, and hooks hygiene. Auto-fixes low-risk violations.
- `.claude-plugin/marketplace.json` at the repo root.
- Each plugin carries its own `plugin.json` under `plugins/<name>/.claude-plugin/`.

### Changed

- `README.md` rewritten for the marketplace layout. Ticket flow diagram updated with the new namespace.
- `ticket-execute` workspace default changed: creates a feature branch in-place via `git checkout -b` instead of a worktree. Worktrees are now opt-in — the operator must explicitly request isolation.

## turkit v0.2.0 — 2026-04-22

- Added `turkit-init` skill.
- README and `.turkit.yaml.example` lean toward TypeScript / pnpm examples.
- `.gitignore` keeps `/docs/specs/` and `/docs/plans/` local.

## turkit v0.1.0 — 2026-04-22

- Initial release: 9 workflow skills, MIT license, published to `alimtunc/turkit`.
