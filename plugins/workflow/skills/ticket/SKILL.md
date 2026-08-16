---
name: ticket
description: Use when the operator explicitly invokes `/ticket`, including sessions with an attached issue or requests for autonomous `--auto` execution. Do not self-trigger on a bare ticket id, tracker link, pasted issue, or implementation request. Never commits.
disable-model-invocation: true
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git checkout:*), Bash(git switch:*), Bash(git worktree:*), Bash(git diff:*), Bash(git ls-files:*), Bash(pwd:*), Bash(cp:*), Bash(mkdir:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write, Task
---

# Ticket

Single ticket entrypoint. The default flow keeps its plan-approval pause. `--auto` runs intake → route → plan → execute → verify in this session without routine plan approval. Focused flags expose smaller slices without forcing the operator into separate public skills.

## Modes

Parse flags before resolving the ticket:

| Flag | Behavior |
|---|---|
| none | Default full flow: plan, pause for approval, execute, verify, handoff. |
| `--auto` | Autonomous full flow: for a coherent ticket, present the plan for visibility, then execute and verify without routine approval. Pause only for a genuinely blocking ambiguity, missing authority, or product decision. |
| `--triage` | Route only: read the ticket, classify one-shot / standard, print the recommended next `/ticket` command, then stop. |
| `--grill` | Challenge the plan before manual approval or autonomous continuation. Not default. |
| `--fast` | Low-token run: compact output, no Workflow/Task fan-out, narrow reuse survey, same safety and verification gates. Approval behavior follows the manual or `--auto` flow. |
| `--plan` | Plan only: intake, route, reuse survey, write/present the plan, then stop before edits. |
| `--execute` | Execute only: resolve the explicit or attached ticket first, load `.claude/plans/<TICKET-ID>.md`, verify it still matches the source and code, then execute. |

Accept at most one phase flag among `--triage`, `--plan`, and `--execute`. If more than one is passed, stop and ask the operator to choose one. `--auto` is a full-flow modifier and cannot combine with a phase flag; if combined, stop and ask the operator to choose autonomous full flow or the focused phase. `--grill` may combine with the default flow, `--auto`, or `--plan`; ignore it with `--triage` and `--execute` after saying why. `--fast` may combine with the default flow, `--auto`, `--plan`, or `--execute`; ignore it with `--triage` after saying triage is already compact. Reject any other unknown flag instead of treating it as ticket input.

## Invocation boundary

- **Operator-invoked.** Never self-trigger on a bare ticket mention — a tracker link, a ticket id, a pasted issue, or an implementation request do **not** invoke this skill. Handle those per the repo's rules docs unless `/ticket` is explicit.
- **Attached context is input, not invocation.** An issue attached to the active agent session (for example by Otomat) becomes authoritative ticket input only after the operator invokes `/ticket`. The operator does not need to repeat its body or identifier.
- **One public ticket command:** intake, triage, planning, and execution are modes of `/ticket`, not separate public skills.
- **One internal forward chain:** intake → route → plan → execute. Flags may stop after triage or planning, or start from an existing plan, but the operator still uses `/ticket` as the main entrypoint.
- **Auto stays in this session.** `--auto` changes the approval behavior of this skill; it does not create dynamic Otomat steps, tracker sub-issues, or an external orchestration workflow.
- **Never auto-invoke `/goal-review`** or any reviewer subagent. The handoff suggests `/goal-review`; the operator runs it.
- **Never commit.**
- **Never make `--grill` implicit.** Some operators want speed; plan challenge is opt-in.
- **Auto is not extra authority.** It removes routine plan approval only. It never grants permission for destructive actions, credentials, external writes, product choices, commits, or review invocation.
- **Fast is not unsafe.** `--fast` reduces exploration and wording, but it never skips implementation criteria, verification, repository rules, or safety gates. In manual mode it still requires plan approval; with `--auto`, only the routine approval pause is omitted.

## Config

Read resolved Turkit config when present, but tolerate missing files.

- `workflow.token_budget`: resolve from repo `.turkit.yaml`, then global `~/.config/turkit/config.yaml` / `~/.turkit.yaml`, then default `normal`.
- `output`: resolve operator-facing style/language via `references/output-preferences.md`.
- `--fast` overrides `workflow.token_budget` to `low` for this run.
- For invalid values, fall back to the default and mention the ignored value once.

## Phases

### 1. Intake + route

- Resolve the ticket source in this exact order:
  1. An explicit ticket argument wins and overrides attached context.
  2. Otherwise, use the issue attached to the active agent session. Treat its title, body, identifier, and linked context as authoritative; do not replace it with an MCP or branch-derived ticket, and do not ask the operator to repeat the identifier.
  3. If neither is available, use `references/issue-tracker-detection.md`: scan active MCP tracker tools (`get_issue` / `search_issue`), then try the branch-name regex, then an operator-provided description. Never hardcode a specific tracker MCP.
- Read the title and body **verbatim** — do not paraphrase away detail. If the ticket references a product brief or mockup, resolve it through the repo's rules docs; never guess a machine-specific path. If no tracker and no description is available, ask the operator for a short description before routing.
- `--plan` and `--execute` require a stable ticket identifier for the canonical path. Use the identifier from the explicit argument or attached issue without asking the operator to repeat it. A `standard` full flow also requires one before Phase 2 because it writes the same canonical path. If the resolved source genuinely has no identifier when one is required, ask once before continuing.
- If `--execute` was passed, finish source resolution here, then jump to Phase 4. Do not classify or re-plan the ticket.
- Before classification, detect whether the ticket genuinely mixes unrelated scopes that cannot form one coherent implementation. If so, stop and recommend separate tickets. Do not generate sub-plans, create tracker issues, or execute any part of it, including under `--auto`.
- Classify the scope:

    | Signal | Path |
    |---|---|
    | Known pattern, no ambiguity, diff describable in one sentence | **one-shot** |
    | Real implementation, coherent well-defined goal | **standard** |

    Route on **pertinence, not file count.** Ten files of mechanical rename is one-shot; one file of novel state logic warrants a plan.

- Classification controls planning depth, not whether the ticket may execute. A large but coherent ticket is `standard` and remains eligible for same-session `--auto` execution.
- A vague requirement is either a reasonable implementation detail to resolve and record in the plan or a genuinely blocking ambiguity to ask about. Vagueness alone is not evidence of unrelated scope.
- If `--triage` was passed, stop here. Print the selected path, the short reason, and the recommended next command:
  - **one-shot / standard, manual continuation:** `/turkit:ticket [<TICKET-ID>]`
  - **one-shot / standard, autonomous continuation:** `/turkit:ticket --auto [<TICKET-ID>]`
  - **plan-only first:** `/turkit:ticket --plan [<TICKET-ID>]`
  Omit `<TICKET-ID>` when continuing from attached session context; include it for an explicit override or when no attachment is available.
  Do not write a plan or edit files in triage mode.

### 2. Plan (reuse survey)

- **Load project rules** before planning. Read `.turkit.yaml → rules.docs`; if absent, fall back to `CLAUDE.md` / `AGENTS.md` / `docs/conventions/*.md`. These set ownership, boundaries, and conventions the plan's quality contract must encode.
- **Reuse survey.** Fan out (degradable — see `## Orchestration & platform`) over the workspace to find reusable modules / components / helpers / schemas **before inventing new ones**. Cross-check the relevant contract or boundary if the ticket touches an API or shared surface. Synthesize the findings into the plan's `Reuse` / `Quality contract` sections.
  - If `workflow.token_budget` is `low`, do not fan out. Read only the ticket, configured rules docs, directly referenced files, and one targeted search over likely reusable names. Record `Reuse survey limited by token budget` in the plan if that materially narrows confidence.
  - If `workflow.token_budget` is `high`, broaden the reuse survey only when the ticket touches shared behavior, cross-module contracts, or unclear architecture. Do not spend extra budget on obvious one-shot edits.
- Produce the plan from `references/plan-template.md` — do not inline a template, point to the matching section:
    - **standard** → write `.claude/plans/<TICKET-ID>.md` using the **Full plan** section.
    - **one-shot with `--plan`** → write `.claude/plans/<TICKET-ID>.md` using the **One-shot mini-plan** section. Plan-only mode always persists this canonical file.
    - **one-shot in a same-session manual or `--auto` flow** → keep the mini-plan inline; no cross-session handoff is needed.
- When a plan file exists, it is the canonical execution record. Persist any `--grill` revisions to that file before presenting it or stopping.

### 3. Plan checkpoint

- Present the plan (the full plan or one-shot mini-plan) before any edit. If `output.style` is `compact`, print a scan-first plan summary plus the plan path when one exists; do not paste long plan bodies unless the operator asks.
- If `--grill` was passed, run the inline challenge checkpoint before manual approval or autonomous continuation:
  - Challenge the plan's main assumption, rejected alternative, highest-risk edge case, and verification signal.
  - Ask at most one concrete question only when the answer is genuinely blocking.
  - If no blocking question remains, include a compact `Challenge record` with: `Assumption`, `Rejected alternative`, `Main risk`, and `Verification`.
  The challenge is part of the plan checkpoint, not a separate implementation step.
- If `--plan` was passed, stop after the plan/grill checkpoint and print the next command:
  - Resolved source was the attached ticket: `/turkit:ticket --execute`
  - Resolved source was an explicit override or another fallback: `/turkit:ticket --execute <TICKET-ID>`
  Do not execute even if the operator says the plan looks good in the same turn.
- In manual default and manual `--grill` modes, **stop for operator validation before any edit**. On approval, proceed to execute. On amendment, revise and re-present the plan. Do not start editing until the plan is approved.
- With `--auto`, the plan is an execution record, not an approval request. Continue to Phase 4 in the same turn unless one of these conditions prevents safe progress:
  - a genuinely blocking ambiguity whose alternatives materially change product behavior or acceptance criteria;
  - missing authority for an action outside the operator's granted scope;
  - a product decision that cannot be derived from the ticket, linked context, repository rules, or existing behavior.
- Do not pause in `--auto` for routine implementation choices, plan size, file count, or a coherent `standard` classification. Choose reasonable reversible implementation details, record them in the plan, and continue.

### 4. Execute

- If `--execute` was passed, the ticket must already be resolved in Phase 1. Load `.claude/plans/<TICKET-ID>.md` for that resolved identifier; never infer a plan filename before resolving the explicit or attached source. If it is missing, stop and tell the operator to run `/turkit:ticket --plan` when the resolved source was attached, or `/turkit:ticket --plan <TICKET-ID>` for an explicit override or another fallback.
- For a focused `--execute` session, load the project rules using the Phase 2 resolution order before validating or editing. Then verify the canonical plan still matches the resolved ticket title/body and the current code. If either the resolved ticket or plan mixes unrelated scopes, stop and recommend separate tickets. If the plan is otherwise stale, stop and report the mismatch instead of silently re-planning.
- **Verify the environment first.** Resolve the workspace policy from `.turkit.yaml → workflow.workspace`:
    - `worktree_required`, or the operator explicitly asked for isolation → bootstrap a worktree following `references/worktree-bootstrap.md` **literally** (create-if-absent → enter → `pwd` / `git rev-parse --show-toplevel` / `git branch --show-current` verification with stop-on-mismatch → env copy → init). Do not reorder or skip a step.
    - Missing or `feature_branch` → work in the current tree on a feature branch; skip the worktree procedure.
- **Implement criterion by criterion.** For each acceptance criterion: read the relevant files, make the change, verify it typechecks via the project's `check` command (resolved per `references/build-tool-detection.md`), then mark the criterion `[x]` in the plan file (or track it inline for a one-shot).
- Full project conventions apply at write time — honor the rules loaded in Phase 2 (ownership / boundaries / comment hygiene). When a guardrail or hook blocks a change, **fix the underlying type or logic — never bypass it** by commenting it out, masking the pattern, or adding a disable directive.
- Execution stays in the main session. **Never commit.**

### 5. Verify + handoff

- **Self-check the diff** against the plan's quality contract: every acceptance criterion maps to a concrete change, no scope creep, no half-implementation. Quick pass on touched files for reuse (no duplicated helper/component/schema), ownership (helpers/types/constants in the planned module, not opportunistically inside entry points or render files), boundaries (no new cross-layer import or hidden public surface), and comment hygiene.
- **Run the project gate** from the active working-tree root (the worktree root if one was bootstrapped). Resolve `check` / `lint` / `fmt` per `references/build-tool-detection.md`. Run a **React gate only when** React files were changed **and** a gate is configured — `.turkit.yaml → commands.react_review`, or the `turkit-react` pack when installed. Never hardcode a specific React tool; if no gate is configured, skip it. Fix root causes or report them; do not bypass a guardrail to make a check pass.
- **Emit the handoff** from `references/handoff-format.md` — fill every field. It **suggests** `/goal-review` (`--diff` before commit, `--branch` before PR) and the commit, prefixed "do NOT run these yourself", and never runs them. If `output.style` is `compact`, keep each filled field to the shortest accurate form; do not add narrative after the handoff.

## Orchestration & platform

When the **Workflow** tool is available and `workflow.token_budget` is not `low`, encode the Phase 2 reuse survey as a Workflow `pipeline` / `parallel`: fan out one reader per shared package (or workspace area) plus the target feature, then synthesize their findings into the plan's `Reuse` / `Quality contract`. When the Workflow tool is not available but subagents are and `workflow.token_budget` is not `low`, run the same fan-out as parallel `Agent` / `Task` calls in a single message. When neither is available, or when token budget is `low`, run the reads sequentially in this session. The behavior is identical; only the mechanism differs — never require a remote orchestrator or any platform-only capability for correctness; it only makes the same survey faster.

**Execution (Phase 4) is never parallelized.** Implementation files are interdependent; they are written sequentially in the main session regardless of which orchestration tier is available.

## Anti-patterns

- Routing without reading the ticket end-to-end — scope estimates become guesses.
- Looking up an MCP or branch ticket when the session already has attached issue context and no explicit override — attached context is authoritative.
- Requiring the operator to copy an attached ticket body or provide its identifier again.
- Treating a large coherent ticket as unrelated scope — it is a normal `standard` plan.
- Decomposing or partially executing a ticket with genuinely unrelated scopes — stop and recommend separate tickets.
- Keeping a one-shot `--plan` inline — plan-only mode must write the canonical `.claude/plans/<TICKET-ID>.md` consumed by `--execute`.
- Starting `--execute` from a filename or branch guess before resolving the explicit or attached ticket source.
- Skipping manual plan approval without `--auto`, or pausing `--auto` for routine plan approval — each mode has a distinct checkpoint contract.
- Treating classification as an execution gate — it selects plan depth; it does not prevent a large coherent ticket from running.
- Inlining a plan template instead of pointing at `references/plan-template.md` — the brick is the single source of truth.
- Hardcoding a specific tracker MCP, build command, or React tool — resolve via the contracts (`issue-tracker-detection.md`, `build-tool-detection.md`) and `.turkit.yaml`.
- Auto-invoking `/goal-review` or any reviewer subagent — review is always operator-gated.
- Running the challenge checkpoint by default — it is useful friction only when explicitly requested with `--grill`.
- Treating `--auto`, `--fast`, or `workflow.token_budget: low` as permission to skip the plan, safety checks, or verification — autonomy changes routine approval only; token budget changes breadth and verbosity only.
- Treating `--plan` as permission to continue into edits — `--plan` always stops before implementation.
- Bypassing a guardrail or hook by commenting it out or masking the pattern with a disable directive — fix the underlying type/logic instead.
- Editing files under the original repo root when a worktree was bootstrapped — the diff lands on the wrong working copy and silently disappears from source control on the feature branch.
- Committing inside this skill — commits are operator-gated.

Apply `references/output-preferences.md` for operator-facing language/style.
