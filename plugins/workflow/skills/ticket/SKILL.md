---
name: ticket
description: Single-session ticket orchestrator (intake → route → plan → ⏸ approval → execute → verify + handoff), all in one session. Invoke when the operator types `/ticket` or explicitly asks to run a ticket through its full lifecycle. Do NOT invoke just because a message carries a ticket id, a tracker link, a pasted issue, or "implémente cette issue" — handle those per the repo's rules docs unless `/ticket` is explicit. Never commits; suggests `/goal-review`, never auto-runs it.
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git checkout:*), Bash(git switch:*), Bash(git worktree:*), Bash(git diff:*), Bash(git ls-files:*), Bash(pwd:*), Bash(cp:*), Bash(mkdir:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write, Task
---

# Ticket

Single-session orchestrator for one ticket: intake → route → plan → ⏸ plan approval → execute → verify, all in this session. An alternative to the multi-session path (`ticket-triage → ticket-plan → ticket-execute`) for operators who want the one-session flow. No fresh-session handoff, no auto-continue gate.

## Invocation boundary

- **Operator-invoked.** Never self-trigger on a bare ticket mention — a tracker link, a ticket id, a pasted issue, or "implémente cette issue" do **not** invoke this skill. Handle those per the repo's rules docs unless `/ticket` is explicit.
- **One internal forward chain:** intake → route → plan → execute. There is no separate triage/plan/execute skill to dispatch; this skill owns the whole flow.
- **Never auto-invoke `/goal-review`** or any reviewer subagent. The handoff suggests `/goal-review`; the operator runs it.
- **Never commit.**

## Phases

### 1. Intake + route

- Resolve the ticket per `docs/contracts/issue-tracker-detection.md`: an explicit id passed as an argument wins; otherwise scan the active MCP tracker tools (`get_issue` / `search_issue`), then fall back to the branch-name regex, then to an operator-provided description. Never hardcode a specific tracker MCP.
- Read the title and body **verbatim** — do not paraphrase away detail. If the ticket references a product brief or mockup, resolve it through the repo's rules docs; never guess a machine-specific path. If no tracker and no description is available, ask the operator for a short description before routing.
- Classify the scope:

    | Signal | Path |
    |---|---|
    | Known pattern, no ambiguity, diff describable in one sentence | **one-shot** |
    | Real implementation, coherent well-defined goal | **standard** |
    | Genuinely mixes unrelated concerns / too vague for criteria | **split** (exceptional) |

    Route on **pertinence, not file count.** Ten files of mechanical rename is one-shot; one file of novel state logic warrants a plan.

- **split** is the escape hatch, not routine — keep the bar high. Use it only when the ticket genuinely mixes unrelated concerns, never for a ticket that is merely large but coherent (that is a normal `standard` plan). When warranted, decompose locally into one sub-plan file per piece (Phase 2); present the decomposition at the Phase 3 pause; on approval, execute each sub-plan in dependency order in this same session. Never create tracker issues — the sub-tickets live only as repo plan files.

### 2. Plan (reuse survey)

- **Load project rules** before planning. Read `.turkit.yaml → rules.docs`; if absent, fall back to `CLAUDE.md` / `AGENTS.md` / `docs/conventions/*.md`. These set ownership, boundaries, and conventions the plan's quality contract must encode.
- **Reuse survey.** Fan out (degradable — see `## Orchestration & platform`) over the workspace to find reusable modules / components / helpers / schemas **before inventing new ones**. Cross-check the relevant contract or boundary if the ticket touches an API or shared surface. Synthesize the findings into the plan's `Reuse` / `Quality contract` sections.
- Produce the plan from `../../references/plan-template.md` — do not inline a template, point to the matching section:
    - **standard** → write `.claude/plans/<TICKET-ID>.md` using the **Full plan** section.
    - **one-shot** → keep an inline mini-plan using the **One-shot mini-plan** section; no plan file.
    - **split** → write one sub-plan file per piece, `.claude/plans/<TICKET-ID>-1.md`, `<TICKET-ID>-2.md`, …, using the **Split sub-plan** section, with `Depends on` set so the execution order is unambiguous.

### 3. ⏸ Plan approval — the only human checkpoint

- Print the plan (the full plan, the inline mini-plan, or the split decomposition) and **stop for operator validation before any edit.** This is the cheapest moment to catch a scope misunderstanding.
- On approval, proceed to execute. On amendment, revise the plan and re-present. Do not start editing until the plan is approved.

### 4. Execute

- **Verify the environment first.** Resolve the workspace policy from `.turkit.yaml → workflow.workspace`:
    - `worktree_required`, or the operator explicitly asked for isolation → bootstrap a worktree following `../../references/worktree-bootstrap.md` **literally** (create-if-absent → enter → `pwd` / `git rev-parse --show-toplevel` / `git branch --show-current` verification with stop-on-mismatch → env copy → init). Do not reorder or skip a step.
    - Missing or `feature_branch` → work in the current tree on a feature branch; skip the worktree procedure.
- **Implement criterion by criterion.** For each acceptance criterion: read the relevant files, make the change, verify it typechecks via the project's `check` command (resolved per `docs/contracts/build-tool-detection.md`), then mark the criterion `[x]` in the plan file (or track it inline for a one-shot).
- Full project conventions apply at write time — honor the rules loaded in Phase 2 (ownership / boundaries / comment hygiene). When a guardrail or hook blocks a change, **fix the underlying type or logic — never bypass it** by commenting it out, masking the pattern, or adding a disable directive.
- For **split**, execute each sub-plan in dependency order, in this same session.
- Execution stays in the main session. **Never commit.**

### 5. Verify + handoff

- **Self-check the diff** against the plan's quality contract: every acceptance criterion maps to a concrete change, no scope creep, no half-implementation. Quick pass on touched files for reuse (no duplicated helper/component/schema), ownership (helpers/types/constants in the planned module, not opportunistically inside entry points or render files), boundaries (no new cross-layer import or hidden public surface), and comment hygiene.
- **Run the project gate** from the active working-tree root (the worktree root if one was bootstrapped). Resolve `check` / `lint` / `fmt` per `docs/contracts/build-tool-detection.md`. Run a **React gate only when** React files were changed **and** a gate is configured — `.turkit.yaml → commands.react_review`, or the `turkit-react` pack when installed. Never hardcode a specific React tool; if no gate is configured, skip it. Fix root causes or report them; do not bypass a guardrail to make a check pass.
- **Emit the handoff** from `../../references/handoff-format.md` — fill every field. It **suggests** `/goal-review` (`--diff` before commit, `--branch` before PR) and the commit, prefixed "do NOT run these yourself", and never runs them.

## Orchestration & platform

When the **Workflow** tool is available, encode the Phase 2 reuse survey as a Workflow `pipeline` / `parallel`: fan out one reader per shared package (or workspace area) plus the target feature, then synthesize their findings into the plan's `Reuse` / `Quality contract`. When the Workflow tool is not available but subagents are, run the same fan-out as parallel `Agent` / `Task` calls in a single message. When neither is available, run the reads sequentially in this session. The behavior is identical; only the mechanism differs — never require a remote orchestrator or any platform-only capability for correctness; it only makes the same survey faster.

**Execution (Phase 4) is never parallelized.** Implementation files are interdependent; they are written sequentially in the main session regardless of which orchestration tier is available.

## Anti-patterns

- Routing without reading the ticket end-to-end — scope estimates become guesses.
- Splitting a ticket that is merely large but coherent — split only for genuinely unrelated concerns; a big coherent ticket is a normal `standard` plan.
- Freelancing past a `standard` route into execution without the Phase 3 plan-approval pause — the pause protects against ambiguous scope; it is not a suggestion.
- Inlining a plan template instead of pointing at `../../references/plan-template.md` — the brick is the single source of truth.
- Hardcoding a specific tracker MCP, build command, or React tool — resolve via the contracts (`issue-tracker-detection.md`, `build-tool-detection.md`) and `.turkit.yaml`.
- Auto-invoking `/goal-review` or any reviewer subagent — review is always operator-gated.
- Bypassing a guardrail or hook by commenting it out or masking the pattern with a disable directive — fix the underlying type/logic instead.
- Editing files under the original repo root when a worktree was bootstrapped — the diff lands on the wrong working copy and silently disappears from source control on the feature branch.
- Committing inside this skill — commits are operator-gated.

Respond in the conversation's language by default.
