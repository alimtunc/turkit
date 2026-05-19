---
name: test-instructions
description: Emit a copy-pasteable manual-test checklist after an issue is implemented. Sectioned (automated / live / edge cases / résumé), commands are runnable as-is.
---

# Test Instructions

Emit a checklist the operator can copy-paste to verify the work.

## Process

1. **Identify the worktree.** Absolute path via `git rev-parse --show-toplevel`.
2. **Skim the diff.** `git diff --stat <base>` (base resolved via `docs/contracts/build-tool-detection.md#base_branch`) to know which areas were touched. No deep file reads.
3. **Identify the ticket** via `docs/contracts/issue-tracker-detection.md`. Skip if none.
4. **Pick test commands** from `.turkit.yaml → commands.test` / `commands.check`, or the project's build-tool defaults.
5. **Emit the block below.** No prose around it.

## Output template

````
Test Instructions — <TICKET-ID> <short title>

Worktree:
```bash
cd <absolute-worktree-path>
```

### 1. Automated
```bash
<test/check commands, copy-pasteable, no placeholders>
```

### 2. Live (omit if no runtime to exercise)
```bash
<server start command with env vars if needed>
```
Then:
- <UI step or curl one-liner> → <expected result>

### 3. Edge cases
- [ ] <happy path — one line>
- [ ] <critical edge case>
- [ ] <likely adjacent regression>

### Résumé
<2–3 sentences: what changed, expected behaviour, what to pay attention to during the test>
````

## Rules

- **Commands must run as-is.** No `<placeholder>` except secrets the operator must fill.
- **Max ~3 items** in *Edge cases*. Happy path + 1–2 critical edges. If more, you're over-testing.
- **Omit "Live"** if there's no runtime to exercise (pure refactor, types-only change, docs).
- No "Prerequisites" section, no "Expected result" subsections — fold into the line.
- Respond in the conversation's language by default. `Résumé` stays in the conversation's language too.
