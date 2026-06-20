---
name: goal-loop
description: Use when the operator explicitly asks to iterate on a bounded objective until it is satisfied, such as a refactor, cleanup, documentation rewrite, non-ticket change, or ticket follow-up. Trigger on goal-loop, loop until done, iterate until clean, max rounds, or similar language. Do not self-trigger for ordinary implementation. Never commits.
allowed-tools: Skill, Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git ls-files:*), Bash(git rev-parse:*), Bash(pwd:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(just:*), Bash(make:*), Bash(cargo:*), Bash(poetry:*), Bash(uv:*), Bash(go:*), Bash(mix:*), Bash(npx:*), Read, Grep, Glob, Edit, MultiEdit, Write, Task
---

# Goal Loop

Operator-invoked objective loop. Turn a bounded goal into success criteria, execute small passes, verify, and loop only on remaining gaps. Stop cleanly when the goal is complete, blocked, or the loop budget is exhausted.

## Invocation Boundary

- Run only when the operator explicitly asks for `goal-loop` or equivalent loop/until-done behavior.
- Use for non-ticket objectives, refactors, cleanup, docs rewrites, or follow-up work after a ticket.
- Do not replace `/ticket` for ticket lifecycle planning, and do not replace `goal-review` for review-only cleanup of an existing diff.
- Never stage, commit, push, continue a git operation, or invoke `ship`.

## Arguments

Parse these optional flags before reading files:

| Flag | Meaning |
|---|---|
| `--from-plan <path>` | Use an existing plan as the goal source. |
| `--scope <path>` | Limit reads and edits to a path or package. |
| `--verify <command>` | Verification command to run after each round. |
| `--max-rounds <N>` | Loop budget. Default `3`; hard cap `5` unless the operator explicitly confirms after round 5. |

Everything else is the goal text.

## Goal Contract

Before editing, write a compact contract:

```markdown
Goal: <one sentence>
Scope: <files/packages allowed, or "current diff" / "ask required">
Success criteria:
- [ ] <criterion 1>
- [ ] <criterion 2>
Verification:
- <command or manual/static check>
Loop budget: <N> rounds
Stop conditions: complete | blocked | budget exhausted | human decision needed
```

If the goal, scope, success criteria, or verification cannot be stated concretely, stop and ask one clarifying question. Never start broad cleanup from a vague goal such as "clean the repo" without an explicit scope.

## Loop

For each round, up to the loop budget:

1. **Inspect.** Read the goal source, current `git status --short`, relevant project rules (`.turkit.yaml -> rules.docs`, else `CLAUDE.md` / `AGENTS.md` / `docs/conventions/*.md` when present), and only the files needed for the current round.
2. **Plan the round.** Pick the smallest set of edits that can satisfy the next unmet criteria. If a change would expand scope, stop and ask.
3. **Edit.** Apply changes in place. Keep edits focused on the contract. Do not batch unrelated cleanup.
4. **Verify.** Run `--verify` when provided. Otherwise resolve the project `check` / `lint` / `test` command per `references/build-tool-detection.md` and run the narrowest relevant gate. If no command is available, do a static self-check and mark verification as `unverified`.
5. **Score.** Mark each success criterion as `done`, `gap`, or `blocked`. Continue only for concrete gaps that can be safely fixed inside the scope.

Stop early when all criteria are `done` and verification passes. If the same verification failure survives two rounds, stop as `blocked` and report it instead of looping blindly.

## Orchestration & Platform

Use parallel subagents only for read-only investigation, such as surveying candidate files or checking whether a criterion is satisfied. The main agent applies all edits. If subagents or Workflow tools are unavailable, run the same inspection sequentially. Correctness must not depend on Claude-only orchestration.

## Output Format

Keep the final report short:

```markdown
## Goal Loop Result

Status: complete | partial | blocked | budget-exhausted
Rounds: <used>/<max>
Goal: <one sentence>

Criteria:
- [done|gap|blocked] <criterion>

Changes:
- <file> - <one-line change>

Verification:
- Ran: <commands or "static check only">
- Result: pass | fail | unverified

Remaining:
- <none or concrete follow-up>
```

## Guardrails

- Never continue a vague or whole-repo goal without explicit scope.
- Never broaden the goal mid-loop without asking.
- Never hide skipped verification or coverage caps.
- Never keep looping after a repeated failure with no new evidence.
- Never stage, commit, push, amend, rebase, reset, or rewrite history.
- Apply `references/output-preferences.md` for operator-facing language/style.
