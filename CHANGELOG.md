# Changelog

All notable changes to turkit are tracked here. The project follows [SemVer](https://semver.org/).

## turkit v3.5.0 — 2026-06-18

### Added

- `ticket --fast` runs the normal ticket flow with compact operator output and a narrower reuse survey while keeping approval and verification gates.
- `.turkit.yaml → workflow.token_budget` lets projects default workflow skills to `low`, `normal`, or `high` exploration.
- `.turkit.yaml → output.style` lets projects choose `compact`, `standard`, or `full` operator-facing responses.
- `commands.dev` is now part of the command-resolution contract for skills that explicitly need a live local app.

## turkit v3.4.0 — 2026-06-18

### Added

- `preview-test` functionally tests deployed PR previews from `.turkit.yaml → preview.url_template` or an operator-provided URL, then returns a structured PASS/FAIL verdict for review/fix loops.
- Preview detection contract and optional `.turkit.yaml → preview` settings for URL templates, readiness hints, and vision mode.

## turkit v3.3.0 — 2026-06-18

### Added

- `clean-skill` audits installed skill folders for stale Turkit-owned skills left behind by additive updates, then deletes only confirmed stale paths.

## turkit v3.2.0 — 2026-06-18

### Changed

- README install and skill catalog now emphasize the generic `npx skills add alimtunc/turkit` path and list skills by purpose instead of internal pack names.
- Turkit now explicitly recommends `mattpocock/skills` alongside Turkit for standalone plan grilling, TDD, debugging, domain modeling, and codebase design.
- Removed Turkit's standalone `grill-me` skill and slash command to avoid duplicating Matt Pocock's skill. `/turkit:ticket --grill` remains available as an inline ticket-plan challenge checkpoint.

## turkit v2.0.0 — 2026-06-17

### Breaking

- Main plugin renamed from `turkit-workflow` to `turkit`. Claude Code install and slash commands now use `/plugin install turkit@turkit` and `/turkit:<skill>`.

### Added

- Operator-understanding skills: `grill-me`, `zoom-out`, `explain-diff`, `teachback-gate`, `merge-brief`, and `release-brief`.

### Changed

- README, generated AGENTS/GEMINI guidance, and bootstrap skills now point at the shorter `/turkit:*` namespace.

## turkit-workflow v1.8.0 — 2026-06-17

### Added

- VCS host detection contract with `.turkit.yaml`, `gh`, `glab`, and manual PR fallback paths.
- Per-skill vendored copies of `docs/contracts/` detection rules so installed skills stay self-contained.
- Configurable review strictness profiles through `.turkit.yaml` (`relaxed`, `standard`, `strict`) and comment policy controls.

### Changed

- `handoff` is read-only by default, with `ship` delegated instead of reimplemented.
- `ship` no longer hard-requires GitHub CLI and reports a manual PR fallback when no supported host CLI is available.
- `shipoff` is now a thin slash-command alias for `handoff ship` instead of a standalone skill.
- French load-bearing instructions in the ticket/handoff workflow were translated to English.

### Fixed

- Local `superkick.db*` runtime files are ignored to avoid accidental publication.

## turkit-react v0.2.0 — 2026-06-17

### Changed

- `react-review` now reads the shared review strictness/comment controls and exposes `review.react.min_version` for projects below React 19.

## turkit-workflow v1.7.0 — 2026-06-11

### Changed

- Skills désormais **autonomes** : les références partagées (`review-rubric`, `branch-review`, `plan-template`, `handoff-format`, `worktree-bootstrap`, `agents-md-template`) sont colocalisées dans chaque skill qui les consomme. La source unique reste dans `plugins/workflow/references/` ; `scripts/sync-references.sh` les dénormalise (liens markdown **et** code-spans) et `scripts/check-references.sh` garde-fou contre la dérive. Rend les skills installables sur Codex / Cursor / Gemini et tout hôte Agent-Skills via `npx skills add alimtunc/turkit -a <agent>` — la découverte passe par le `marketplace.json` existant, sans restructuration.
- `ticket-triage` : note de repli séquentiel quand l'agent n'a pas de Skill tool — le chaînage suit alors directement le `SKILL.md` du skill suivant dans la même session.

## turkit-workflow v1.6.0 — 2026-06-05

### Added

- `/ticket` + `/goal-review` : orchestrateurs Workflow-native en session unique, **additifs** — les skills multi-session (`ticket-triage` → `ticket-plan` → `ticket-execute`) et les reviews (`pre-commit-review` / `pre-pr-review`) restent disponibles et inchangés.
    - `/ticket` : intake → route (one-shot / standard / split) → plan reuse-survey → **une seule** pause d'approbation → execute critère par critère → handoff. Ne commit jamais ; suggère `/goal-review`, ne le lance jamais.
    - `/goal-review` : boucle review→fix (`--diff` / `--branch` / `--repo`, défaut `--branch` jusqu'à 2 rounds propres), fix policy à 3 niveaux (mécaniques appliqués · comportementaux appliqués+vérifiés · unsafe surfacés), vérif finale + check de régression adversariale.
- Briques partagées `references/` (`plan-template`, `worktree-bootstrap`, `handoff-format`, `branch-review`, `agents-md-template`) qui dédupliquent les orchestrateurs contre les skills existants (source unique par brique).
- `install` / `adopt-project` génèrent désormais `AGENTS.md` + `GEMINI.md` (points d'entrée multi-LLM : Codex, Gemini, …) pointant vers `/ticket` + `/goal-review`. Les skills dégradent gracieusement (Workflow → agents parallèles → séquentiel) — aucune dépendance à une primitive plateforme-spécifique.

## turkit-workflow v1.5.0 — 2026-05-24

### Changed

- `ticket-plan` et `ticket-triage` : section "Format de sortie obligatoire" hissée tout en haut du skill (juste après l'intro), avant les steps, avec un anti-pattern concret extrait d'un cas réel de prod. v1.4.0 avait les règles correctes mais en bas du fichier — le modèle les lisait après avoir déjà mentalement préparé son résumé narratif. La nouvelle position et l'exemple littéral du mauvais output ("Plan summary (10 ACs)…", "Ready for operator review…", etc.) forcent le format strict avant que le modèle commence à exécuter les steps.

## turkit-workflow v1.4.0 — 2026-05-24

### Added

- `ticket-plan` : section "Format de sortie" obligatoire qui exige un trailer strict — `✅ Plan écrit` + ligne vide + fence interne copy/paste contenant le prompt `ticket-execute` pour la nouvelle session. Plus aucun résumé du plan, aucune liste d'ACs, aucune option alternative après la fence.
- `ticket-triage` : trailer strict pour le path `split-first` (fence interne copy/paste avec `/turkit-workflow:ticket-triage <SOUS-TICKET-ID>`).

### Changed

- `ticket-triage` : nouveau guardrail "After dispatching, add nothing" — interdit explicitement le narratif post-dispatch ("Routing decision", "Architecture summary", "Key scope walkbacks resolved", récap des ACs) qui noyait le trailer de copy/paste du skill dispatché.

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
