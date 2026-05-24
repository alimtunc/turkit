# Changelog

All notable changes to turkit are tracked here. The project follows [SemVer](https://semver.org/).

## turkit-workflow v1.3.1 — 2026-05-24

### Fixed

- `handoff` : section "Format de sortie" simplifiée pour mirror la référence personnelle. Les règles strictes qui noyaient l'instruction principale sont retirées ; le mode `ship` est isolé en sous-section "Variante". L'output reste fiablement wrappé dans une fence markdown copiable au lieu d'être rendu visuellement.

## turkit-workflow v1.3.0 — 2026-05-22

### Changed

- `ship` : format de sortie final strict et obligatoire (`✅ Shipped` + 4 champs + ligne vide + bare `#<PR_NUMBER>`). Plus aucune prose après le numéro de PR — extractable sans parser.
- `handoff` : règles de bloc markdown durcies (une seule paire de fences, rien avant la fence d'ouverture, rien après la fermeture sauf le trailer de `ship` en mode `ship`). Sections du gabarit toutes obligatoires.

### Fixed

- `handoff ship` : ordre corrigé — `ship` s'exécute **avant** l'affichage du résumé pour que l'URL et le numéro de PR figurent dans le bloc. Le `#<PR_NUMBER>` reste la toute dernière ligne de la réponse.

## turkit-workflow v1.2.0 — 2026-05-21

### Added

- `shipoff` : raccourci d'un seul mot pour `/handoff ship`. Délègue à `handoff` en mode `ship` — pas de duplication de logique.

## turkit-workflow v1.1.0 — 2026-05-20

### Added

- `handoff` : exige l'état d'environnement (worktree, branche, Linear, PR) et le résultat des gates dans le template de résumé.
- Resserrage des skills workflow autour des frontières de session.

### Fixed

- `ticket-triage` : interdit une frontière de session prématurée avant `ticket-plan`.

### Changed

- `handoff` aligné avec la version globale personnelle.

## turkit v1.0.0 — 2026-04-22

### Breaking

- Repo restructured from a single plugin to a **marketplace** with two plugins: `turkit-workflow` and `turkit-react`.
- Slash-command namespace: `/turkit:xxx` → `/turkit-workflow:xxx` (or `/turkit-react:xxx`).
- Install command changed: `/plugin install turkit@alimtunc/turkit` → `/plugin install turkit-workflow@alimtunc/turkit` (plus optional `turkit-react`).

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
