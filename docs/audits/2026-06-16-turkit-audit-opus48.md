# turkit — Audit & Benchmark

**Auditor:** Claude Opus 4.8 · **Date:** 2026-06-16 · **Method:** 17 per-skill scorers + 4 cross-cut analysts (merge / over-fit / gaps / robustness), each reading source directly, plus author verification of repo-level claims.

**Scope:** 17 skills across `turkit-workflow` (16) + `turkit-react` (1). Every claim cites `file:line`. Where a sub-finding contradicted the repo's stated design, the repo wins (flagged inline).

---

## Scorecard

D1 LLM-agnostic · D2 Project-agnostic · D3 Distinct value · D4 Clarity/maintainability · D5 Instruction robustness (1=poor … 5=excellent).

| Skill | D1 | D2 | D3 | D4 | D5 | Avg | Note |
|---|---|---|---|---|---|---|---|
| pre-commit-review | 5 | 5 | 4 | 5 | 5 | **4.8** | Portable, config-driven diff gatekeeper; value lives in shared rubric, scoped to working tree. |
| goal-review | 5 | 5 | 4 | 4 | 5 | **4.6** | Loop+apply review engine; textbook capability tiering (SKILL.md:99); overlaps pre-pr-review --branch. |
| test-instructions | 5 | 5 | 4 | 5 | 4 | **4.6** | Tool-agnostic checklist emitter; 3-edge cap + no-placeholder discipline beats default. |
| install | 5 | 5 | 4 | 4 | 5 | **4.6** | LLM-agnostic by design (writes AGENTS.md/GEMINI.md); never-clobber/idempotent; glue-heavy. |
| ship | 4 | 5 | 4 | 5 | 4 | **4.4** | Lean ship orchestrator; machine-parseable `#<PR>` trailer; non-idempotent reruns. |
| turkit-init | 5 | 5 | 4 | 4 | 4 | **4.4** | Portable config bootstrapper; example advertises keys it never writes. |
| ticket-execute | 5 | 5 | 4 | 3 | 4 | **4.2** | Disciplined executor (re-verify plan, never commit); contracts don't ship with plugin. |
| pre-pr-review | 4 | 4 | 4 | 4 | 5 | **4.2** | Solid branch reviewer; closed build-tool allowlist + vestigial "Subagents launched: N" field. |
| pr-description | 5 | 4 | 3 | 5 | 3 | **4.0** | Clean git-only generator; thin value-add; no empty-diff/no-commit guards. |
| adopt-project | 4 | 4 | 4 | 4 | 4 | **4.0** | Genuine never-delete migration; AGENTS-gen duplicated w/ install; stale owned-names list. |
| react-review | 3 | 5 | 4 | 4 | 4 | **4.0** | Stack-agnostic React-19 rubric; command entrypoint hard-wired to Skill tool, no fallback. |
| ticket | 4 | 5 | 3 | 3 | 4 | **3.8** | Single-session orchestrator; duplicates the triage/plan/execute trio's lifecycle. |
| ticket-plan | 4 | 4 | 4 | 3 | 4 | **3.8** | Config-driven plan-writer w/ real output discipline; FR/EN mix. |
| shipoff | 4 | 4 | 2 | 5 | 4 | **3.8** | Self-admitted zero-logic alias for `/handoff ship`; inherits handoff's Linear/ExitWorktree. |
| rules-refresh | 2 | 4 | 3 | 5 | 4 | **3.6** | Clean rules auditor but judgment hard-anchored to "what Claude knows," degrades silently off-Claude. |
| ticket-triage | 4 | 5 | 2 | 2 | 4 | **3.4** | Tracker-agnostic router; 3-row table buried under 6×-repeated bilingual anti-recap prose. |
| handoff | 3 | 2 | 3 | 3 | 3 | **2.8** | Useful discipline wrapper but hardcodes Linear `save_issue`/`DEV-XXXX` + ExitWorktree; data-loss risk on worktree remove. |

Suite mean Avg ≈ **4.1**.

---

## A. Merge

**1. Ticket family (`ticket` vs `ticket-triage`/`ticket-plan`/`ticket-execute`) — KEEP skills, DE-DUP refs.** `ticket/SKILL.md:9` frames itself as the one-session alternative to the trio; intake/route (ticket:22-34 ≈ ticket-triage:62-85), plan, execute and handoff are each restated. But the two paths encode genuinely different ergonomics (one-session-one-pause vs three-session hard plan gate) — that *is* the point of both. Merge **shape**: unify the route vocabulary (`standard`↔`plan-then-execute`, `split`↔`split-first`) so the suite stops carrying two names for one route. Lost: nothing behavioral. Gained: consistency.

**2. Review family (`pre-commit-review`/`pre-pr-review`/`goal-review`) — strongest content overlap.** `goal-review`'s `--diff` mode *is* pre-commit-review's scope and `--branch` *is* pre-pr-review's; the three differ only on fix-posture (single-pass surface vs loop+apply+adversarial-regression). Merged shape option: one `review` skill with `--scope {diff|branch|repo}` × `--fix {report|safe|loop}`. **Gain:** ~120 lines of duplicated scaffolding collapse. **Loss:** the cheap-vs-expensive affordance in the palette (`/pre-commit-review` *reads* as fast; `--fix loop` hides cost behind a flag) and the auto-invocation safety boundary that keeps the expensive multi-agent loop from being auto-chained. Verdict: **defensible to keep three thin wrappers**; if merged, keep a cheap-alias command.

**3. Ship family — DELETE `shipoff` skill (clearest cut in the library).** Pure alias: "Ce skill ne réimplémente rien" (shipoff:11), "Le résultat est strictement identique" (:21). An alias should be a **command**, not a skill — and no `commands/shipoff.md` exists. Replace the skill dir with `commands/shipoff.md → handoff ship`. Keep `ship` and `handoff` separate (different verbs) but stop `handoff` re-implementing commit+close divergently from `ship`.

**4. Install family (`install`/`adopt-project`/`turkit-init`) — KEEP three, extract shared bricks.** Distinct pipeline points (generate config / greenfield bootstrap / brownfield migration). But `adopt-project:60-84` re-implements a *third* `.turkit.yaml` proposal instead of delegating to `turkit-init` the way `install:34` does, and both `install` and `adopt-project` re-narrate the same ~15-line AGENTS.md/GEMINI.md merge algorithm. Fix: `adopt-project` delegates config to `turkit-init`; AGENTS-gen prose lives once.

> **Repo-contradiction note (trust-the-repo):** a sub-analysis flagged the byte-identical `references/` copies (`review-rubric.md` ×3, `plan-template.md` ×3, etc.) as "pure liability — collapse to one." That contradicts the repo's **deliberate** design: README.md:157 + `scripts/sync-references.sh`/`check-references.sh` single-source each brick in `plugins/<plugin>/references/` then **denormalize** copies into every skill so skills stay self-contained for per-skill `npx skills add`; `check-references.sh` fails the build if a skill carries a `../../references/` share-link. So do **not** collapse to shared links — that would break the portability guarantee. Genuine defects are narrower: (a) each denormalized copy's prose still calls itself "the single source of truth" — should read "generated copy; edit the canonical in `plugins/<plugin>/references/`"; (b) `docs/contracts/*` is the one shared asset **not** vendored into skills, so per-skill installs can't resolve detection (see B).

---

## B. Rework

- **handoff (avg 2.8 — weakest, two real bugs).** (1) *Correctness:* `handoff:24` hardcodes Linear (`save_issue`/`stateId`/`DEV-XXXX`), bypassing `issue-tracker-detection.md` that every sibling honors — a Jira/GitHub-Issues team's ticket silently never closes. Fix: route through the contract, silent-skip if no tracker (mirror `ship:33`). (2) *Data-loss:* `git worktree remove` (handoff:22) runs *before* the push-verify at :23 — reorder so a confirmed-pushed clean tree **gates** the remove. Also: `ExitWorktree`→note `git worktree remove` fallback; resolve the contradiction where `handoff-format.md:21` says "list one line per modified file" but `SKILL.md:43` says don't; translate to English.
- **rules-refresh.** Replace the three Claude-anchored phrasings (SKILL.md:3,28,35) with "the **running agent** does this natively" so the prune axis tracks whatever model executes it. Add a post-write diff-preview before the in-place rewrite (:42).
- **ticket-triage.** Collapse the ~6 restatements of "add nothing after dispatch" to one rule + the split-first fence; cut the 18-line hardcoded SUP-28/DeleteAccountWarning.tsx transcript (:42-58) to a 2-line note; pick one language. The actual routing value is a 3-row table.
- **ship.** Add idempotent re-run: if a PR already exists for the branch, reuse and report its number instead of erroring (ship:28) — the single most likely real-world failure. Add an empty-diff abort.
- **pr-description.** Add empty-range/`branch==base`/detached-HEAD guards; soften `gh pr create` (:21) to "paste into your host's PR body"; drop the `Closes` line when no ticket resolves.
- **pre-pr-review.** Delete the dead "Review Cost / Subagents launched: N" output block (:106-108) — copy-paste residue; this skill spawns nothing.
- **react-review.** Command entrypoint requires the `Skill` tool with no fallback (react-review.md:16) — add "if no Skill tool, Read the SKILL.md and follow it."
- **Library-wide.** Vendor `docs/contracts/build-tool-detection.md` + `issue-tracker-detection.md` into each plugin (or each skill's `references/`) and switch the repo-root-relative references to plugin-relative, so standalone per-skill installs resolve detection — referenced by ~12 skills, currently breaks the "self-contained" claim.

---

## C. Keep

- **pre-commit-review (4.8)** — tightest skill; rubric single-sourced, guardrails complete, nothing to lose off-Claude.
- **goal-review (4.6)** — best-in-class capability tiering + bounded loop + adversarial regression gate; real superset capability.
- **test-instructions (4.6)** — opinionated anti-over-testing discipline a default agent won't reproduce.
- **install (4.6)** — only skill that designs for re-run; portability-trap warning is exactly the codified knowledge that earns a skill.
- **turkit-init (4.4)** — canonical `.turkit.yaml` author the whole suite reads.
- **ship (4.4)** — machine-parseable PR-number contract makes it composable (minor idempotency rework in B).
- **ticket-execute (4.2)** — concrete never-commit + plan-drift-reverify invariants.
- **adopt-project (4.0)**, **react-review (4.0)** — solid, minor fixes in B.

---

## D. Add (missing for a generic multi-LLM, multi-project loop)

1. **`reproduce`** — turn a bug report into a deterministic minimal repro (failing test/command) *before* any fix. Highest-leverage debugging artifact; the loop currently jumps straight to triage with no reproduce-first gate (the classic "fixed code that was never confirmed broken" failure mode).
2. **`deps-audit`** — supply-chain hygiene (vulnerable/outdated/unused deps → scoped reversible bumps). Review skills police *your* diff, never the dependency tree where most real incidents originate. Project-agnostic via the existing build-tool contract.
3. **`release-notes`** — changelog from `last-tag..HEAD` grouped by type. The loop dead-ends at "PR opened"; nothing serves the after-merge half. Conventional-Commits detection already exists in `ship`.
4. **`rollback`** — incident-time revert-vs-forward-fix planner with exact git commands + blast-radius note. The whole library is happy-path; there's no "production is on fire, undo it correctly" skill.
5. **`explain`** — read-only orientation map of an unfamiliar subsystem (entry points, data flow, invariants). Tooling setup exists; code *understanding* before planning does not. Feeds `ticket-plan`'s reuse scan.
6. **`refactor`** — behavior-preserving restructure with a **mandatory** before/after verification gate. `goal-review` only cleans code already in a diff; LLMs silently drift behavior during refactors, so a verify-gated refactor skill directly counters that.

(Top 4 — `reproduce`, `deps-audit`, `release-notes`, `rollback` — have zero overlap with the 17.)

---

## E. Over-fit (blunt)

1. **Four skills are authored in French only** — `handoff`, `shipoff` fully; `ticket-plan:12-63` and `ticket-triage:14-58,89-106` have their **load-bearing output-format rules** in French while steps are English. Worst over-fit: contradicts README.md:3/:162 selling Codex/Cursor/Gemini portability — a non-French solo dev runs `/handoff` and cannot read/edit the spec. Leaked personal context: `ticket-plan:43`'s anti-pattern cites "Turkish locale-aware uppercase, i18next array typing" (author's own app); `ticket.md:3` hardcodes the French trigger `"implémente cette issue"`.
2. **GitHub + `gh` is a hard constant, not detected.** `ship:5,28`, `pr-description:21`, `handoff:86` assume `gh`. Careful tracker + build contracts exist but **no VCS-host detection contract** — a GitLab/Bitbucket team's `/ship` cannot open a PR.
3. **Linear in the wiring despite "agnostic on paper."** `handoff:24` names Linear `save_issue`/`stateId`/`DEV-XXXX` directly; `issue-tracker-detection.md:33` blesses "Linear MCP… tested ✅" as the only validated tracker.
4. **pnpm/JS-first everywhere a default is shown** — `.turkit.yaml.example`, README's one config example, `turkit-init`'s lead example, and detection order checking `package.json` before `Justfile`/`Makefile`. `allowed-tools` lists pnpm/npm/yarn/bun first and **omits `dotnet`/`gradle`/`mvn`/`swift`/`bundle`/`composer`** — a JVM/.NET/Ruby/PHP team hits permission prompts the JS user never sees.
5. **Review rubrics are one senior dev's CLAUDE.md asserted as objective P0 gates.** "Default zero new comments / doc-blocks = **P0**" (`review-rubric.md:99-108`), "renderer/hook/util SOC = **P0**" (`:59-64`), and the 40-line/3-nest/5-param thresholds trace **verbatim** to the author's global CLAUDE.md/RTK — shipped as blocking failures with **no per-project override knob**. `react-rubric` is React-19-only and *stops the review* on React <19.
6. **Personal preference dressed as rule:** "no `Co-Authored-By`" (`ship:23` et al.), "**Never** default to `master`" (`turkit-init:46`, editorializing inside a contract), always-new-commit-never-amend, and the `prefix-number` branch regex (`issue-tracker-detection.md:14`) that yields "no ticket" for `feature/`, `username/`, or no-ticket branches.

What a different team trips on, ranked: non-French operator → 4 unreadable skills · non-GitHub → no PR · non-Linear → tickets never close · non-React-19/non-JS → review refuses/over-flags · JVM/.NET/Ruby/PHP → allowlist friction · documentation culture → every PR P0-flagged.

---

## F. Portability map

**Portable now (most LLMs):** `ticket-plan`, `ticket-execute`, `goal-review`, `pre-commit-review`, `pr-description`, `test-instructions`, `ship`, `turkit-init`, `install`, `adopt-project` — pure file/git/shell + config-driven detection; the best ones spell out a Workflow→Agent/Task→sequential ladder (goal-review:99) so only parallelism (speed) is lost off-Claude, never correctness.

**Works but degraded:** `ticket`, `ticket-triage` (entry leans on the Skill tool / multi-session model; documented sequential fallback exists), `pre-pr-review` (Skill-tool invocation coupling + closed build-tool allowlist), `react-review` (command entrypoint requires Skill, no fallback tier), `shipoff` (own text portable; the *flow* it triggers inherits handoff's breaks), `rules-refresh` (mechanically runs anywhere but its keep/prune judgment is anchored to "what Claude knows" — degrades *silently into wrong answers*), `handoff` (loses worktree-exit via `ExitWorktree` and ticket-close via hardcoded Linear MCP off-Claude).

**Effectively Claude-only: none.** No skill hard-requires a Claude-only API for correctness — every breakage is a convenience (Skill-tool auto-invoke), a degraded feature (parallel fan-out, ExitWorktree), or a wrong-baseline judgment (rules-refresh). A genuine design achievement; gaps are at the edges, not the core.

---

## Composite scores

- **Agnostic-readiness: 74/100.** Method: mean(D1,D2)≈86 across 17 (plumbing — capability tiering, `.turkit.yaml`, two detection contracts — is strong, **install-anywhere** holds), discounted ~12 pts for **degrade-anywhere** breaks: 4 French-only bodies, `gh`-only ship, Linear-only handoff, `docs/contracts/*` not vendored for per-skill installs.
- **General-purpose fit: 62/100.** Method: build→review→ship + ticket-lifecycle arc is genuinely reusable by a non-author team, discounted hard for author-taste rubrics enforced as P0 with **no override knob**, French skills, and GitHub/Linear/pnpm/React-19 bias in high-touch skills (review, ship, handoff).

---

## Top 5 actions

| # | Action | Target | Effort | Payoff |
|---|---|---|---|---|
| 1 | Translate the 4 French-only skill bodies to English | handoff, shipoff, ticket-plan, ticket-triage | M | **High** — kills #1 over-fit; resolves the "sell Gemini/Codex portability while shipping French-only specs" contradiction |
| 2 | Fix handoff correctness + data-loss bugs (route ticket-close via tracker contract; ExitWorktree→git fallback; gate worktree-remove on confirmed-pushed clean tree) | handoff (→ shipoff) | M | **High** — raises the worst skill (2.8); removes a real data-loss path |
| 3 | Add a VCS-host detection/abstraction contract (gh→glab→manual) | ship, pr-description, handoff | M | **High** — unblocks non-GitHub teams; biggest "can't use at all" blocker |
| 4 | Vendor `docs/contracts/*` into plugins + fix the misleading "single source of truth" prose in denormalized bricks | library-wide | S/M | **Med-High** — makes the self-contained per-skill-install claim true; leave the intentional copies in place |
| 5 | Add per-project override knobs to review rubrics (comment policy, SOC-P0, 40-line/3-nest/5-param, React floor) + de-cruft (shipoff→command, ship idempotency, pre-pr-review dead field) | review-rubric/react-rubric + others | M | **Med-High** — lets a non-author team tune review instead of fighting one person's taste |
