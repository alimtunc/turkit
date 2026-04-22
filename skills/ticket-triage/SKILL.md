---
name: ticket-triage
description: Entry point for any ticket. Fetches the issue (if a tracker is available), evaluates scope, picks the path (one-shot / plan-then-execute / split-first), and emits a copy-pasteable prompt for the next step. Does not auto-chain.
---

# Ticket Triage

Route a ticket toward the right workflow. **Does not write code.** **Does not auto-invoke downstream skills.**

## Steps

1. **Resolve the ticket.**
   - Accept an explicit ticket ID as argument, **or**
   - Detect via `docs/contracts/issue-tracker-detection.md`.
   - If no tracker is available, ask the operator for the ticket ID or a short description of the work.

2. **Fetch issue context** if a tracker is available. Read title + body. If not, use the operator-provided description.

3. **Scope the work** and pick one of three paths. Use these heuristics:

   | Path | Signals |
   |---|---|
   | **one-shot** | < 1 hour. One well-understood change. Single file or tight cluster. Clear acceptance criteria. |
   | **plan-then-execute** | 1 hour – 1 day. Multiple files / modules. Some design decisions to make. Tests need thought. |
   | **split-first** | Multi-day. Cuts across unrelated subsystems. Mixes infra + product + tests. Multiple operator reviews needed. |

   If between two options, prefer the heavier one. Operator can downgrade.

4. **Emit a next-step prompt.** Produce exactly one copy-pasteable block, matching the chosen path:

   - **one-shot** → a prompt like: "Implement <TICKET-ID>: <one-line summary>. Acceptance criteria: <list>. Work on a worktree/branch, commit after manual verification."
   - **plan-then-execute** → a prompt like: "Run `/turkit:ticket-plan <TICKET-ID>`. Validate the plan, then run `/turkit:ticket-execute <TICKET-ID>`."
   - **split-first** → a prompt like: "Before implementing <TICKET-ID>, split it into N sub-tickets: <bullet list of proposed splits>. Update the tracker, then re-triage each sub-ticket."

5. **Stop.** Do not invoke any other skill. Do not write any file except the next-step prompt in the conversation.

## Output format

Always emit the next-step prompt in a fenced block so the operator can one-click copy.

Respond in the conversation's language by default.

## Guardrails

- Never begin implementation. Never open a worktree. Never edit code. Triage only.
- If the ticket body is missing or trivially short, ask the operator to flesh it out before choosing a path.
