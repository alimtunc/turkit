---
description: Summarize the conversation for handing off to another LLM. Pass `ship` to also commit + push + open a PR.
argument-hint: "[ship]"
---

Invoke the `handoff` skill. If the argument `ship` (or any value starting with `ship`) was passed, run handoff in `ship` mode: skip the local commit / Linear-close steps inside handoff and chain the `ship` skill after the summary so commit + push + PR + ticket-close happen as one shot.

Argument received: $ARGUMENTS
