---
name: goal-review
description: Operator-invoked review→fix loop (`--diff` / `--branch` / `--repo`, default `--branch`). Invoke only when the operator types `/goal-review` or explicitly asks to review-and-fix code until it is clean, DRY, and SoC-respecting. Slow and multi-agent — it fans out reviewer subagents and applies fixes in place. Other skills (`/ticket`, …) must NOT auto-invoke it; they may only suggest it. Loops review→fix until clean (`--branch`), then a final verification pass. Never commits. Language-agnostic.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git rev-list:*), Bash(git symbolic-ref:*), Bash(git ls-files:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write, Task
---

# Goal Review

Operator-invoked. Reviews **and fixes** until the scoped code is clean, DRY, and SOC-respecting, then verifies once. This is the Workflow-native review→fix entry point; `pre-commit-review` and `pre-pr-review` remain the single-pass alternatives.

Slow and multi-agent — **never auto-chained** by another skill. `/ticket` only _suggests_ it.

## Source of Truth

This skill does **not** inline a rubric. The judgment pass forwards the shared rubric **verbatim** to every reviewer:

- [`references/review-rubric.md`](references/review-rubric.md) — severity, categories, fix policy (2 buckets), language-agnostic checklist, output format. Forward it whole to each reviewer.
- For `--branch` only, also forward [`references/branch-review.md`](references/branch-review.md) — the branch-level checklist (B1–B4) and branch output sections. B4's lint-only verification guidance applies to reviewers; this skill's final verification step supersedes it for the orchestrator.

The 3-tier fix policy below **supersedes** the rubric's 2-bucket policy **for this skill only** (the rubric's buckets still govern what each reviewer reports).

## Modes

| Mode                 | Scope                                          | Loop                                   |
| -------------------- | ---------------------------------------------- | -------------------------------------- |
| `--diff`             | staged + unstaged + untracked working tree     | single pass (no deep loop)             |
| `--branch` (default) | committed diff `base..HEAD`                     | loop until clean (K = 2 dry rounds, cap `--max-rounds`) |
| `--repo`             | whole codebase                                 | single pass per package (no deep loop) |

Parse the mode from the skill argument. No argument → `--branch`. A bare path argument (e.g. `src/features/billing`) implies a scoped `--repo`-style sweep of that path. Also parse `--max-rounds <N>` (the `--branch` loop cap; see `## Loop control`).

Resolve the base branch (`--branch`) per `references/build-tool-detection.md#base_branch`:

1. `.turkit.yaml → base_branch`
2. `git symbolic-ref refs/remotes/origin/HEAD` (strip the `refs/remotes/origin/` prefix)
3. fallback `main`

## Loop control

- Only `--branch` runs the deep loop: review→fix repeats until **K = 2** consecutive rounds produce no new findings, **`--max-rounds` is reached**, or the token budget is exhausted. `--max-rounds` defaults to **4** and is hard-capped at **6** — going past 6 requires the operator to explicitly confirm.
- **`--max-rounds` is the real backstop, not the budget.** Token counts cannot be measured reliably (see Output), so the budget stop rarely fires. Without a round cap, a reviewer that surfaces even one fresh finding per round — common when fixes land unstaged and get re-reviewed (see Re-scope) — never reaches K = 2 and the loop runs away (20+ rounds). The cap bounds that; K = 2 is the fast-path exit when the code genuinely converges.
- **Light path (skip the loop for small scopes).** Before the loop, size the surviving scope: if it is small — roughly ≤ 2 files, single package, no behavioral (tier-b) candidate expected — run **one** reviewer, a single review→fix pass, and fold the regression check into the orchestrator's own before/after re-read (no K = 2, no separate regression agent). Otherwise run the **full path**. State the chosen path under Loop & Cost.
- `--diff` and `--repo` run a single review→fix pass (`--repo` per package) — no multi-round loop. A whole-repo loop-until-clean is unbounded; if a package needs deeper iteration, rerun `--repo <package-path>` or `--branch` on it.
- **Re-scope after fixes.** Fixes land unstaged, so `git diff <base>..HEAD` stops describing the code under review the moment a fix lands. From the second round on, build the `--branch` scope with `git diff <base>` (committed **plus** working tree) so the fixes' own hunks are re-reviewed. A dry round counts only if the reviewers saw the current working tree.
- Identify a finding by `rule + enclosing symbol + the hunk's current content` — never by line number, which shifts as fixes land. Never re-fix an already-applied finding, and never re-surface a vet-rejected one **while its hunk is unchanged**; if a later edit touches a rejected finding's hunk, the rejection lapses and the finding is re-evaluated.
- Any coverage cap (top-N findings, sampling, a package skipped for budget) must be surfaced explicitly — no silent truncation.

## Workflow

1. **Dirty-tree gate (`--branch` only).** `git status --short`. If the tree is dirty, warn that the `base..HEAD` scope will miss uncommitted work; offer `--diff`, or proceed with a clearly-labeled committed-only partial review. (`--diff` and `--repo` skip this gate.)
2. **Build the scope** per mode:
    - `--diff`: `git diff --name-only HEAD` (staged + unstaged) plus `git ls-files --others --exclude-standard` (untracked). Review changed hunks for tracked files, full files for untracked.
    - `--branch`: `git diff --name-only <base>..HEAD` and `git diff <base>..HEAD`; gather `git log --oneline <base>..HEAD` and `git log --stat <base>..HEAD` for the branch-level checklist.
    - `--repo`: enumerate workspace packages and process package-by-package.
3. **Load project rules** before judging:
    - Read `.turkit.yaml` if present; if it defines `rules.docs`, read the listed docs.
    - Otherwise read repo defaults when present: `CLAUDE.md`, `AGENTS.md`, `docs/conventions/*.md`.
4. **Mechanical pre-pass** = the **project's lint**, not a hardcoded tool:
    - Resolve `lint` via `.turkit.yaml → commands.lint`, fallback per `references/build-tool-detection.md`. If unavailable, note "lint unavailable" and continue.
    - **React gate (only when React files are in scope and a gate is configured).** If the scope contains React files (`*.tsx` / `*.jsx` / `*.ts` with hooks or JSX) and either `.turkit.yaml → commands.react_review` is set or the `turkit-react` pack is installed, run that React gate too (delegate to the `turkit-react` `react-review` skill when the pack is present; otherwise run `commands.react_review`). If neither is configured, skip it — never hardcode a specific React linter.
5. **Review→fix loop** (single pass for `--diff`, `--repo`, and the light path; `--repo` runs steps a–e per package; the full `--branch` path repeats them up to `--max-rounds`):
   a. **Review fan-out.** Launch generic reviewer agents in parallel — **max 4 per round**; when the scope needs more, shard by package/directory and surface the cap. Each runs on its scoped subset, seeded with `review-rubric.md` **verbatim** (plus `branch-review.md` for `--branch`) and its slice of the mechanical pre-pass output. Delegate any React surface to the `turkit-react` pack when present; otherwise a generic reviewer covers it with the shared rubric. **Subagents are read-only — they report findings only.** The orchestrator applies fixes. Each reported finding carries a `Confidence` (0–100) — the reviewer's estimate that it is real and correctly located — consumed by the vet and the tier-(b) gate.

   **Reviewer output contract (token discipline).** Reviewers emit the **findings table only** — one row per finding, no re-quoted code blocks, no narration, no praise, no restating the rubric back:

   ```
   | Category | Severity | Confidence | file:symbol | Issue (1 line) | Fix (1 line, concrete) |
   ```

   `file:symbol` = enclosing symbol, never a line number (it shifts as fixes land). `Fix` names the exact edit or the existing shared symbol to call, so the orchestrator applies rather than re-derives. A reviewer that finds nothing emits an empty table, not an essay. Prose belongs only in the orchestrator's final report.
   b. **Vet — refute, don't confirm.** Reviewers over-report by design — that is their job, not a defect; the rubric's Finding Discipline governs the final report, not their raw output. Before fixing anything, re-check each finding **de-anchored**: read only `rule + the current cited hunk`, **not** the reviewer's rationale, and default the verdict to **reject** — keep the finding only if you cannot construct a plausible reason the code is correct as-is. For a finding citing a rules-doc / `CLAUDE.md` clause, confirm the clause **literally** covers this case; if not, reject. Attach a `confidence` (0–100) to each survivor. Record each rejection as `rule @ symbol — refutation`; rejected findings join the dedup set and stay suppressed while their hunk is unchanged.
   c. **Dedup** surviving findings against the already-fixed and rejected sets by `rule + symbol + hunk content` (see Loop control).
   d. **Fix** every new finding in place per `## Fix policy` (the orchestrator edits; subagents never do). Unstaged. Never commit.
   e. **`--branch` full path only:** if no new findings landed this round, increment the clean-round counter. Stop at **K = 2** dry rounds, or when the round count reaches **`--max-rounds`** (default 4, hard cap 6) — whichever comes first. If the cap stopped the loop before K = 2, say so under Loop & Cost and note that residual findings may remain (rerun to continue). Surface any coverage cap.
6. **Final verification (single pass).**
    - Run the project's lint/test gate (`commands.lint` / `commands.test`, fallback per the build-tool contract) over the scope — the narrowest relevant gate (touched packages when the runner supports it); full-suite runs only when the operator asks.
    - **Adversarial regression check (de-anchored):** feed one reviewer only the before/after hunks of the `## Behavioral Fixes Applied (verify)` entries plus each behavioral claim — **not** the reasoning that produced the fix — and have it flag any fix that changed behavior unsafely. (The light path folds this into the orchestrator's own before/after re-read.)
    - On failure → run **one** corrective round → re-verify **once**. If a regression survives, **revert the offending tier-(b) fix** (an unstaged edit of this run — reverting it is not a git operation), then surface the original finding under `## Required Changes`.
7. **Report** per `## Output format`. Never `git add` / commit / push.

## Reviewer mindset

Reviewers are **gatekeepers, not advisors**. The bar is "clean, minimal, DRY, SOC-respecting code" — **not** "works" and **not** "looks like the rest of the codebase".

- The diff must justify itself. Any change that cannot be tied to an acceptance criterion or an explicit fix is scope creep — flag it.
- If code could be deleted, inlined, or replaced with an existing shared helper **without changing behavior**, flag it.
- "The rest of the file already does this" is **not** a defense. The touched lines are the author's responsibility.
- Default stance is **flag, then justify silence**. A clean diff is one where the reviewer searched hard and found nothing.
- When in doubt, **flag**. The cost of a false positive is one sentence from the author; the cost of a missed finding is a permanent regression to code quality.

## Fix policy

This skill **fixes everything it safely can** and **surfaces (does not apply)** a narrow unsafe/ambiguous bucket. The safety net is the final verification pass + adversarial regression check for what it applies, and `## Required Changes` for what it leaves.

Three tiers, **extending** `review-rubric.md`'s Auto-fix / Required-Changes buckets **for this skill**. Apply with `Edit` / `MultiEdit`, always **unstaged**:

- **(a) Mechanical** — unambiguous, reversible by reading the diff, **no behavior change**. The rubric's Auto-fix bucket: comment hygiene, debug-print removal, unused imports, deep relative imports → established alias, extract helpers/types/constants out of entry-point/render files when an obvious ownership target exists, replace a duplicate helper with the existing symbol, remove dead props/params/variants/wrapper files, inline one-method `manager`/`service`/`helper` indirections. **Apply in place, unstaged.**
- **(b) Behavioral** — apply, but **verify and list**. Refactors that change behavior: splitting a unit branching on >2 shapes, splitting a two-responsibility hook/module, removing a typed escape hatch by tightening the upstream type or adding a parse/guard, converging duplicated unions/enums into a shared schema, resolving a cross-module import by moving code to a shared module, adding missing invalidation/error/empty states, accessibility primitives, swapping an unstable list key for a stable id. **Apply only when the finding's `confidence` ≥ the strictness threshold** (relaxed 90 / standard 80 / strict 70, resolved from `.turkit.yaml → review.strictness`); below the threshold, **demote to tier (c)** and surface it instead of guessing. Applied tier-(b) fixes **list under `## Behavioral Fixes Applied (verify)`** — the focus of the adversarial regression check.
- **(c) Unsafe / ambiguous** — **surface only, never guess-apply**. Anything whose intended behavior is ambiguous from the diff alone, or that needs a product/UX decision, a backend/contract change, or author intent to determine the correct target shape. Flag with a concrete suggestion under `## Required Changes`.

### Hard rules

- Never `git add` / stage / commit / push / amend / rebase / reset / rewrite history. Fixes land unstaged.
- Never edit outside the review scope unless an in-scope extraction genuinely requires a new sibling/shared file (list new files explicitly).
- If an auto-fix may change behavior, promote it from tier (a) to tier (b).
- If fixing one finding would recreate another (SOC extraction vs OverEng single-call-site, and similar rule pairs), do not flip-flop across rounds: pick the shape with less total complexity once, and record the losing finding as a rejection with that reason.
- If the final verification flags a regression, run **one** corrective round; if it persists, revert the offending tier-(b) fix and surface the original finding under `## Required Changes`. Never leave a known-broken fix in the tree.

## Orchestration & platform

> When the **Workflow** tool is available, encode steps 4–5 as a Workflow `pipeline`: review dimensions fan out, each finding set verifies as it completes, and the loop accumulates until two dry rounds. When Workflow is not available but subagents are, run the same fan-out as parallel `Agent` / `Task` calls in a single message. When neither is available, run the steps sequentially in this session. The behavior is identical; only the mechanism differs. Never require any platform-only orchestration or cloud capability for correctness — they only make the same procedure faster.

## Output format

Reuse the shared rubric's output format from [`references/review-rubric.md`](references/review-rubric.md) (Mechanical Pre-pass, Fixes Applied, Required Changes, Blocking Issues, Suggested Improvements, Positive Signals, Verification, Residual Risks). Use the rubric's categories and severity calibration; one tag per finding.

Add to it, for this skill:

- For `--branch`, the branch-level sections from [`references/branch-review.md`](references/branch-review.md): Branch summary, Per-Commit, Cross-Commit, Branch-Level, Verdict.
- A `## Behavioral Fixes Applied (verify)` section — tier (b) fixes the operator should verify; the focus of the adversarial regression check.
- A `## Required Changes` section — tier (c) findings the loop could not safely apply, plus any regression that survived the corrective round (P0/P1 only).
- A `## Rejected Findings` section — vet-pass rejections with reasons, so they do not resurface next run.

```markdown
## Mechanical Pre-pass (lint)

- Ran: `<exact command>` (and the React gate command, if one was configured)
- Findings kept: N (validated against the scope)
- Findings dropped as false positives: N — list with reasons
- Notable rules triggered: short list with file:line

## Fixes Applied

> Tier (a) mechanical fixes. All landed **unstaged**; the operator stages.

- [Category] [file:line] What changed
- New files created by extractions, if any: `path/to/file.ext`

## Behavioral Fixes Applied (verify)

> Tier (b) fixes that changed behavior. The operator should verify these — they are the focus of the adversarial regression check.

- [Category] [file:line] What changed and why it is safe (one sentence)

## Required Changes

> Tier (c) findings the loop could not safely apply (needs a contract/UX/product decision or author intent), or a regression that survived the corrective round.

- [P0|P1] [Category] [file:line | commit:<hash>] What must change and why it cannot be auto-fixed

## Rejected Findings

> Vet-pass rejections — reported by a reviewer, dropped because the cited code does not support them. Suppressed while their hunk is unchanged.

- [rule @ file:symbol] Reason (one sentence)

## Blocking Issues

- [P0|P1] [Category] [file:line] Rare issue not covered above

## Suggested Improvements

- [Category] [file:line] Improvement and expected benefit

## Positive Signals

- Short bullet only when it reduces review ambiguity

## Verification

- Ran: exact commands (mechanical pre-pass, post-fix lint/test, adversarial regression check)
- Residual failures after fixes, if any
- Corrective round: ran | not needed
- Skipped: relevant checks not run and why

## Residual Risks

- Remaining uncertainty or paths not verified

## Loop & Cost

- Mode: `--diff` | `--branch` | `--repo` · Path: light | full
- Rounds run (`--branch`): N / <max-rounds> (stopped at: K = 2 dry rounds | max-rounds | budget exhausted)
- Strictness: `<relaxed|standard|strict>` · tier-(b) confidence threshold: `<90|80|70>`
- Coverage caps surfaced: none | list
- Reviewer agents launched: N
- Findings rejected by vet: N
```

If a section has no entries, say so explicitly with `- None.`

For `--branch`, append the Branch summary / Per-Commit / Cross-Commit / Branch-Level / Verdict sections from `branch-review.md`. The `Verdict` cannot be `Ready for PR` while unstaged fixes remain — the operator must commit (or discard) them and re-run.

Do not invent token counts or durations — they cannot be measured reliably.

## Guardrails

- Never stage, commit, push, amend, rebase, reset, or rewrite history. Fixes land unstaged.
- Never turn the loop into a broad refactor beyond the scope.
- Subagents are read-only; only the orchestrator applies fixes.
- Apply `references/output-preferences.md` for operator-facing language/style.
