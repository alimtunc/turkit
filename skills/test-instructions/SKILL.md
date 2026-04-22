---
name: test-instructions
description: Emit a concise manual-test checklist after an issue is implemented. Short and scannable — the operator should be able to run through it in a few minutes.
---

# Test Instructions

Produce a **concise** manual-test checklist for the change, readable at a glance. No prose, no micro-steps.

## Steps

1. **Identify the worktree.** Absolute path via `git rev-parse --show-toplevel`.
2. **Analyze the changes.** Use `git diff --stat <base_branch>` for a high-level view. Base branch resolution: `docs/contracts/build-tool-detection.md#base_branch`. Don't read files in depth — the goal is to know which areas were touched.
3. **Identify the ticket** via `docs/contracts/issue-tracker-detection.md`. If none, proceed without.
4. **Write the checklist.** See rules below.
5. **Display** the result as plain text (no outer fenced block — only the `cd` command is fenced).

## Checklist rules

- **Max 6–8 items.** If you overflow, group or cut.
- **One line per item**, format: short action → expected result.
- **Markdown checkbox**: `- [ ] …`.
- **No sub-steps**, no implementation details (no network payload names, no internal variable names).
- **Cover only**: the happy path + 1–2 critical edge cases + likely regressions in adjacent areas.
- **User-facing language**, not technical ("create a template", not `PUT /template returns 200`).
- No separate "Prerequisites" or "Expected result" sections — everything fits on the checkbox line.
- Respond in the conversation's language by default.

## Output format

Plain text. Only the `cd` command is in a copy-able bash block.

Example output:

---

Test Instructions — <TICKET-ID> <short title>

Access the worktree:

```bash
cd <absolute-worktree-path>
```

- [ ] <item 1>
- [ ] <item 2>
- [ ] …
