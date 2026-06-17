---
name: ticket-triage
description: Entry point for any ticket. Fetches the issue (if a tracker is available), evaluates scope, picks the path (one-shot / plan-then-execute / split-first), and dispatches the next skill in the same session. Only plan-then-execute requires a fresh session for execution.
---

# Ticket Triage

Route a ticket toward the right workflow **and dispatch it in the same session**.

- **one-shot** → triage writes a minimal plan then auto-invokes `ticket-execute` here and now.
- **plan-then-execute** → triage auto-invokes `ticket-plan` here and now. `ticket-plan` ends by printing a fresh-session prompt for `ticket-execute`. Operator runs that in a new session.
- **split-first** → triage writes a split proposal and stops. No implementation.

## Required output format — READ THIS FIRST

Triage is a dispatcher. Its output is **never** a summary of the work to come — it is either the output block of the dispatched skill (one-shot / plan-then-execute), or the strict split-first block.

### For `one-shot` and `plan-then-execute`

The last block the operator sees is the one emitted by `ticket-execute` (handoff) or `ticket-plan` (fresh-session prompt). **Triage adds nothing after it.** No recap, no "scope walkbacks resolved", no "architecture summary", no "ready for review". The triage report (step 4) is emitted before the dispatch; after that you let the dispatched skill have the last word.

### For `split-first`

The last message is **exactly** this block, and **nothing after it**:

````
✅ Split proposed — `.claude/plans/<TICKET-ID>-split.md`

Next action — create the sub-tickets in the tracker, then re-triage each with this prompt:

```
/turkit:ticket-triage <SUB-TICKET-ID>
```
````

No summary of the split in the chat — the file speaks for itself. One inner fence, one-click copy/paste.

### Observed anti-pattern (NEVER reproduce)

You just dispatched `ticket-plan` and you will be tempted to summarize the plan your sub-skill just wrote. Do not. Here is exactly the kind of post-dispatch output that has already broken this skill in production and must never come back:

> Plan written to .claude/plans/PROJ-42.md.
> Triage decision: plan-then-execute.
> Plan summary (10 ACs):
> - Append a second item to the existing settings section…
> - Build a new confirmation component…
> - …
> Key walkback decisions: …
> Risks flagged: …
> Ready for operator review. Next step is ticket-execute once you approve.

Four violations:
1. **Summarizes the plan** instead of pointing to the file `ticket-plan` just wrote.
2. **Proposes no copy/paste prompt** for the new session — `ticket-plan` is supposed to have done that, and appending this narrative behind it destroys its copy-pasteable block.
3. **Ends with a sentence** ("Ready for operator review…") instead of leaving the sub-skill's inner fence last.
4. **Proposes a condition** ("once you approve") instead of a direct, copy-pasteable action.

Your correct output after dispatch is exactly what the sub-skill emitted, full stop. You touch nothing after it.

## Steps

1. **Resolve the ticket.**
   - Accept an explicit ticket ID as argument, **or**
   - Detect via `references/issue-tracker-detection.md`.
   - If no tracker is available, ask the operator for the ticket ID or a short description of the work.

2. **Fetch issue context** if a tracker is available. Read title + body. If not, use the operator-provided description.

3. **Scope the work** and pick one of three paths. Use these heuristics:

   | Path | Signals |
   |---|---|
   | **one-shot** | < 1 hour. One well-understood change. Single file or tight cluster. Clear acceptance criteria. |
   | **plan-then-execute** | 1 hour – 1 day. Multiple files / modules. Some design decisions to make. Tests need thought. |
   | **split-first** | Multi-day. Cuts across unrelated subsystems. Mixes infra + product + tests. Multiple operator reviews needed. |

   If between two options, prefer the heavier one. Operator can downgrade.

4. **Emit the triage report** (block below), then dispatch.

   ```
   Ticket : <TICKET-ID> — <short title>
   Path   : <one-shot | plan-then-execute | split-first>
   Reason : <1–2 sentences>
   ```

5. **Dispatch** based on path. The fresh-session boundary lives **only** between `ticket-plan` and `ticket-execute`. Triage never asks the operator to start a new session for `ticket-plan` and never prints a copy-paste prompt for the next skill — it invokes it. (No Skill tool? Continue in this same session by following the next skill's `SKILL.md` directly — the chaining is identical, only the invocation mechanism differs.)

   - **one-shot** → write a minimal plan to `.claude/plans/<TICKET-ID>.md` (template below), then **invoke `ticket-execute` via the Skill tool (or follow its `SKILL.md`) in this same session**. Add nothing after the sub-skill returns — its handoff block is the last message.
   - **plan-then-execute** → **invoke `ticket-plan` via the Skill tool (or follow its `SKILL.md`) in this same session**. `ticket-plan` writes the plan AND emits the fresh-session prompt. Add nothing after it returns — its fence block is the last message. No plan summary, no AC recap, no "scope walkbacks resolved".
   - **split-first** → write the split proposal to `.claude/plans/<TICKET-ID>-split.md` (template below), then emit the split-first block defined at the top, then stop.

## One-shot minimal plan template

Use the `## One-shot mini-plan` section of `references/plan-template.md`. Write to `.claude/plans/<TICKET-ID>.md` before invoking `ticket-execute`.

## Split-first proposal template

Use the `## Split sub-plan` section of `references/plan-template.md`. Write to `.claude/plans/<TICKET-ID>-split.md`.

## Guardrails

- Never invoke any review skill (`pre-commit-review`, `pre-pr-review`, `ship`, `test-instructions`).
- Split-first never auto-invokes anything.
- **`one-shot` and `plan-then-execute` always auto-invoke the next skill in the same session.** Printing a copy-paste prompt like "`/turkit:ticket-plan PROJ-14`" instead of invoking the skill is a bug — it breaks the workflow by forcing an unnecessary session boundary on the operator.
- **After dispatching `ticket-plan` or `ticket-execute`, add nothing.** See the "Required output format" section at the top and the anti-pattern that follows it. The last inner fence of the conversation must be a clean one-click copy/paste, emitted by the sub-skill.
- If the ticket body is missing or trivially short, ask the operator to flesh it out before choosing a path.
- Respond in the conversation's language by default.
