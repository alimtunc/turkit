# Changelog

All notable changes to turkit are tracked here. The project follows [SemVer](https://semver.org/).

## turkit v3.12.0 — 2026-07-23

### Added

- `goal-review`: `--max-rounds` loop cap (default 4, hard cap 6) as the real backstop — the token-budget stop is unmeasurable and never fires, so a chatty reviewer surfacing one finding per round could run away past 20 rounds.
- `goal-review`: light path for small scopes (≤2 files / single package / no tier-b candidate) — one reviewer, single pass, no K=2 loop.
- `goal-review`: per-finding confidence (0–100) and a confidence gate on tier-b behavioral fixes (relaxed 90 / standard 80 / strict 70), demoting sub-threshold findings to surface-only.

### Changed

- `goal-review` vet is now refute-by-default and de-anchored: it re-checks each finding from `rule + hunk` alone, defaulting to reject, instead of re-reading and dropping unsupported findings.
- `goal-review` reviewers emit a findings-table-only output contract (no re-quoted code, narration, or praise) to cut per-round token burn; the adversarial regression check is de-anchored from the fix's reasoning.

## turkit v3.11.0 — 2026-07-18

### Added

- `rules-baseline.md`: authoring-time code-quality baseline (DRY, SOC, over-engineering, naming, comments, complexity, error handling, types, boundaries, simplification), the dev-time mirror of the review rubric.
- `turkit-init` and `adopt-project` seed `docs/conventions/code-quality.md` from the baseline and wire `rules.docs` when the repo has no rules doc.
- `rules-refresh`: Missing bucket sourced from the baseline, and a guided `--interactive` mode with per-rule accept/rephrase/skip decisions, repo-evidence proposals, and documented-tradeoff recording.
- `goal-loop --review`: optional single-pass quality gate on the loop's diff against the shared rubric.
- Shared rubric: Simplification section (named behavior-preserving moves only, wired to `review.strictness`), Out of Scope statement, and Finding Discipline (structural first, documented tradeoffs respected).

### Changed

- `goal-review` hardened: scope is recomputed from the working tree after each fix round, findings are identified by rule + symbol + hunk content instead of line numbers, a vet pass drops unsupported reviewer findings with per-run rejection memory, reviewer fan-out is capped at 4 per round, and a regression surviving the corrective round now reverts the offending fix.
- Shared rubric output format renamed to Shared Output Format with an explicit composition rule for entry points; dead-symbol auto-fixes now require a repo-wide grep; DRY and single-export rules gain same-reason-to-change and framework-contract qualifiers.
- `pre-pr-review` drops the unused Review Cost section.

## turkit v3.10.0 — 2026-07-05

### Added

- `visual-map` now documents Codiff as the recommended companion for interactive diff walkthroughs and file-by-file review.
- `visual-map --trace [command|name]` for mapping a typical execution path from command/script to entrypoint, functions, DB/API/filesystem/events, and output without running the command.
- `visual-map --diff` is now scoped to architecture impact from the current diff instead of full diff walkthrough generation.

### Changed

- `visual-map` is refocused on durable architecture artifacts: topology, execution traces, package interactions, database maps, feature/call paths, external systems, boundaries, key files, and unknowns.
- README now separates responsibilities: Codiff for diff review UX, Visual Map for architecture, relation, package, workflow, and database context.

## turkit v3.9.0 — 2026-07-04

### Added

- `visual-map --diff` now produces a change-review map with an exhaustive changed-file ledger, changed-file tree, why/impact cards, relationship map, complete diff explorer, and rejected/excluded changes section.
- `visual-map --diff-review` and `visual-map --change-map` aliases for diff-centered review maps.
- Optional `graphify` integration for `visual-map`, used as a code graph index for imports, reverse imports, tests, symbols, package edges, and changed-file context before falling back to Git/rg.

### Changed

- README now documents `visual-map` modes, diff-review output, and the optional `graphify` acceleration path.

## turkit v3.8.0 — 2026-06-20

### Added

- Global Turkit preferences via `~/.config/turkit/config.yaml`, with `~/.turkit.yaml` as a legacy fallback.
- Repo `.turkit.yaml` now overrides global preferences per key for supported personal settings.

### Changed

- Output preferences and `workflow.token_budget` can be inherited globally, while project-specific settings remain repo-local.
- `install` and `turkit-init` now report inherited global preferences instead of copying them into every repo config.

## turkit-react v0.5.0 — 2026-07-18

### Added

- Severity weighting by render path: hot-path findings (per keystroke, per list row, per frame) escalate; rarely-mounted surfaces demote judgment calls. P0 structural/behavioral findings never downgrade.
- Fix policy now resolves the canonical react-doctor recipe (`npx react-doctor rules explain <rule>`) before fixing a gate finding instead of improvising.

## turkit-react v0.4.0 — 2026-06-20

### Changed

- `react-review` inherits global output preferences through the shared output-preferences contract.

## turkit v3.7.0 — 2026-06-20

### Added

- `.turkit.yaml → output.language` and `output.technical_terms` configure operator-facing prose while keeping code, CLI, API, and common technical terms stable.
- `output-preferences` contract is vendored into skills that emit operator-facing text so per-skill installs stay self-contained.

### Changed

- `zoom-out` now explains focused targets such as functions, files, configs, scripts, and code areas with a short why/how/risk shape instead of a rigid map dump.
- Understanding gates now localize their labels and final questions through the shared output-preferences contract.

## turkit-react v0.3.0 — 2026-06-20

### Changed

- `react-review` now reads the shared output-preferences contract for operator-facing language/style.

## turkit v3.6.0 — 2026-06-19

### Added

- `work-brief` summarizes what an AI work session produced, why it matters, the key pieces, linked files, quality evidence, and current git/ticket/PR state.
- Generated `AGENTS.md` / `GEMINI.md` guidance and setup/adoption flows now include `work-brief` as an understanding gate after AI work.

## turkit v3.5.1 — 2026-06-18

### Changed

- `explain-diff` now emits a compact before/after brief with explicit constraint, impact, scope, risk, verification, and reread fields.
- `explain-diff` now forbids diagrams, long prose, file-by-file walkthroughs, and invented intent.

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
