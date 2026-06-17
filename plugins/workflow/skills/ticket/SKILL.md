---
name: ticket
description: Use when the operator explicitly invokes `/ticket` to run or inspect a ticket workflow. Supports `--triage`, `--plan`, `--execute`, and optional `--grill`. Do not self-trigger on a bare ticket id, tracker link, pasted issue, or implementation request. Never commits.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git checkout:*), Bash(git switch:*), Bash(git worktree:*), Bash(git diff:*), Bash(git ls-files:*), Bash(pwd:*), Bash(cp:*), Bash(mkdir:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write, Task
---

# Ticket

Single ticket entrypoint. Default flow: intake → route → plan → plan approval → execute → verify, all in this session. Optional flags expose the same workflow as smaller slices without forcing the operator into separate public skills.

## Modes

Parse flags before resolving the ticket:

| Flag | Behavior |
|---|---|
| none | Default full flow: plan, pause for approval, execute, verify, handoff. |
| `--triage` | Route only: read the ticket, classify one-shot / standard / split, print the recommended next `/ticket` command, then stop. |
| `--grill` | Same as default, but runs `grill-me` against the plan before approval. Not default. |
| `--plan` | Plan only: intake, route, reuse survey, write/present the plan, then stop before edits. |
| `--execute` | Execute only: resolve the ticket id, read an existing `.claude/plans/<TICKET-ID>.md`, verify it still matches the code, then execute. |

Accept at most one phase flag among `--triage`, `--plan`, and `--execute`. If more than one is passed, stop and ask the operator to choose one. `--grill` may combine with the default flow or `--plan`; ignore it with `--triage` and `--execute` after saying why.

## Invocation boundary

- **Operator-invoked.** Never self-trigger on a bare ticket mention — a tracker link, a ticket id, a pasted issue, or an implementation request do **not** invoke this skill. Handle those per the repo's rules docs unless `/ticket` is explicit.
- **One public ticket command:** intake, triage, planning, and execution are modes of `/ticket`, not separate public skills.
- **One internal forward chain:** intake → route → plan → execute. Flags may stop after triage or planning, or start from an existing plan, but the operator still uses `/ticket` as the main entrypoint.
- **Never auto-invoke `/goal-review`** or any reviewer subagent. The handoff suggests `/goal-review`; the operator runs it.
- **Never commit.**
- **Never make `--grill` implicit.** Some operators want speed; `grill-me` is opt-in.

## Phases

### 1. Intake + route

- Resolve the ticket per `references/issue-tracker-detection.md`: an explicit id passed as an argument wins; otherwise scan the active MCP tracker tools (`get_issue` / `search_issue`), then fall back to the branch-name regex, then to an operator-provided description. Never hardcode a specific tracker MCP.
- Read the title and body **verbatim** — do not paraphrase away detail. If the ticket references a product brief or mockup, resolve it through the repo's rules docs; never guess a machine-specific path. If no tracker and no description is available, ask the operator for a short description before routing.
- Classify the scope:

    | Signal | Path |
    |---|---|
    | Known pattern, no ambiguity, diff describable in one sentence | **one-shot** |
    | Real implementation, coherent well-defined goal | **standard** |
    | Genuinely mixes unrelated concerns / too vague for criteria | **split** (exceptional) |

    Route on **pertinence, not file count.** Ten files of mechanical rename is one-shot; one file of novel state logic warrants a plan.

- **split** is the escape hatch, not routine — keep the bar high. Use it only when the ticket genuinely mixes unrelated concerns, never for a ticket that is merely large but coherent (that is a normal `standard` plan). When warranted, decompose locally into one sub-plan file per piece (Phase 2); present the decomposition at the Phase 3 pause; on approval, execute each sub-plan in dependency order in this same session. Never create tracker issues — the sub-tickets live only as repo plan files.
- If `--triage` was passed, stop here. Print the selected path, the short reason, and the recommended next command:
  - **one-shot / standard / split, continue in this session:** `/turkit:ticket <TICKET-ID>`
  - **plan-only first:** `/turkit:ticket --plan <TICKET-ID>`
  Do not write a plan or edit files in triage mode.

### 2. Plan (reuse survey)

- **Load project rules** before planning. Read `.turkit.yaml → rules.docs`; if absent, fall back to `CLAUDE.md` / `AGENTS.md` / `docs/conventions/*.md`. These set ownership, boundaries, and conventions the plan's quality contract must encode.
- **Reuse survey.** Fan out (degradable — see `## Orchestration & platform`) over the workspace to find reusable modules / components / helpers / schemas **before inventing new ones**. Cross-check the relevant contract or boundary if the ticket touches an API or shared surface. Synthesize the findings into the plan's `Reuse` / `Quality contract` sections.
- Produce the plan from `references/plan-template.md` — do not inline a template, point to the matching section:
    - **standard** → write `.claude/plans/<TICKET-ID>.md` using the **Full plan** section.
    - **one-shot** → keep an inline mini-plan using the **One-shot mini-plan** section; no plan file.
    - **split** → write one sub-plan file per piece, `.claude/plans/<TICKET-ID>-1.md`, `<TICKET-ID>-2.md`, …, using the **Split sub-plan** section, with `Depends on` set so the execution order is unambiguous.

### 3. ⏸ Plan approval — the only human checkpoint

- Print the plan (the full plan, the inline mini-plan, or the split decomposition) and **stop for operator validation before any edit.** This is the cheapest moment to catch a scope misunderstanding.
- If `--grill` was passed, invoke `grill-me` on the plan before asking for approval. If no Skill tool is available, follow `grill-me`'s `SKILL.md` directly in this session. The grill is part of the approval checkpoint, not a separate implementation step.
- If `--plan` was passed, stop after the plan/grill checkpoint and print the next command:
  ```text
  /turkit:ticket --execute <TICKET-ID>
  ```
  Do not execute even if the operator says the plan looks good in the same turn.
- In default and `--grill` modes: on approval, proceed to execute. On amendment, revise the plan and re-present. Do not start editing until the plan is approved.

### 4. Execute

- If `--execute` was passed, start here: read `.claude/plans/<TICKET-ID>.md`; if it is missing, stop and tell the operator to run `/turkit:ticket --plan <TICKET-ID>` first.
- **Verify the environment first.** Resolve the workspace policy from `.turkit.yaml → workflow.workspace`:
    - `worktree_required`, or the operator explicitly asked for isolation → bootstrap a worktree following `references/worktree-bootstrap.md` **literally** (create-if-absent → enter → `pwd` / `git rev-parse --show-toplevel` / `git branch --show-current` verification with stop-on-mismatch → env copy → init). Do not reorder or skip a step.
    - Missing or `feature_branch` → work in the current tree on a feature branch; skip the worktree procedure.
- **Implement criterion by criterion.** For each acceptance criterion: read the relevant files, make the change, verify it typechecks via the project's `check` command (resolved per `references/build-tool-detection.md`), then mark the criterion `[x]` in the plan file (or track it inline for a one-shot).
- Full project conventions apply at write time — honor the rules loaded in Phase 2 (ownership / boundaries / comment hygiene). When a guardrail or hook blocks a change, **fix the underlying type or logic — never bypass it** by commenting it out, masking the pattern, or adding a disable directive.
- For **split**, execute each sub-plan in dependency order, in this same session.
- Execution stays in the main session. **Never commit.**

### 5. Verify + handoff

- **Self-check the diff** against the plan's quality contract: every acceptance criterion maps to a concrete change, no scope creep, no half-implementation. Quick pass on touched files for reuse (no duplicated helper/component/schema), ownership (helpers/types/constants in the planned module, not opportunistically inside entry points or render files), boundaries (no new cross-layer import or hidden public surface), and comment hygiene.
- **Run the project gate** from the active working-tree root (the worktree root if one was bootstrapped). Resolve `check` / `lint` / `fmt` per `references/build-tool-detection.md`. Run a **React gate only when** React files were changed **and** a gate is configured — `.turkit.yaml → commands.react_review`, or the `turkit-react` pack when installed. Never hardcode a specific React tool; if no gate is configured, skip it. Fix root causes or report them; do not bypass a guardrail to make a check pass.
- **Emit the handoff** from `references/handoff-format.md` — fill every field. It **suggests** `/goal-review` (`--diff` before commit, `--branch` before PR) and the commit, prefixed "do NOT run these yourself", and never runs them.

## Orchestration & platform

When the **Workflow** tool is available, encode the Phase 2 reuse survey as a Workflow `pipeline` / `parallel`: fan out one reader per shared package (or workspace area) plus the target feature, then synthesize their findings into the plan's `Reuse` / `Quality contract`. When the Workflow tool is not available but subagents are, run the same fan-out as parallel `Agent` / `Task` calls in a single message. When neither is available, run the reads sequentially in this session. The behavior is identical; only the mechanism differs — never require a remote orchestrator or any platform-only capability for correctness; it only makes the same survey faster.

**Execution (Phase 4) is never parallelized.** Implementation files are interdependent; they are written sequentially in the main session regardless of which orchestration tier is available.

## Anti-patterns

- Routing without reading the ticket end-to-end — scope estimates become guesses.
- Splitting a ticket that is merely large but coherent — split only for genuinely unrelated concerns; a big coherent ticket is a normal `standard` plan.
- Freelancing past a `standard` route into execution without the Phase 3 plan-approval pause — the pause protects against ambiguous scope; it is not a suggestion.
- Inlining a plan template instead of pointing at `references/plan-template.md` — the brick is the single source of truth.
- Hardcoding a specific tracker MCP, build command, or React tool — resolve via the contracts (`issue-tracker-detection.md`, `build-tool-detection.md`) and `.turkit.yaml`.
- Auto-invoking `/goal-review` or any reviewer subagent — review is always operator-gated.
- Running `grill-me` by default — it is useful friction only when explicitly requested with `--grill`.
- Treating `--plan` as permission to continue into edits — `--plan` always stops before implementation.
- Bypassing a guardrail or hook by commenting it out or masking the pattern with a disable directive — fix the underlying type/logic instead.
- Editing files under the original repo root when a worktree was bootstrapped — the diff lands on the wrong working copy and silently disappears from source control on the feature branch.
- Committing inside this skill — commits are operator-gated.

Respond in the conversation's language by default.
