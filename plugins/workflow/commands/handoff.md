---
description: Summarize the conversation for handing off to another LLM (read-only by default). Pass `ship` to delegate commit + push + PR to the `ship` skill.
argument-hint: "[ship]"
---

Invoke the `handoff` skill. Default mode is a **read-only** summary — it never commits, pushes, removes worktrees, or updates tracker state. If the argument `ship` (or any value starting with `ship`) was passed, run handoff in `ship` mode: it delegates commit + push + PR + tracker update to the `ship` skill, then appends the PR pointer to the summary.

Argument received: $ARGUMENTS
