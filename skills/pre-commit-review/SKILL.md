---
name: pre-commit-review
description: Review the current unstaged + staged diff against clean-code principles (DRY, SOC, naming, error handling, complexity) and auto-fix low-risk issues before the operator commits. Language-agnostic.
---

# Pre-Commit Review

Review the **current diff** (unstaged + staged) and auto-fix low-risk issues before a commit.

## Scope

- Input: `git diff HEAD` (both staged and unstaged changes).
- Output: a short review report + files auto-fixed in-place for low-risk issues.
- Language-agnostic. No stack-specific idioms. Principles only.

## Steps

1. **Gather the diff.** `git diff HEAD --stat` then `git diff HEAD` for full content.

2. **Classify findings** into three buckets:
   - **Auto-fix**: rename a clearly-misleading variable, delete obviously-dead code introduced by this diff, extract a duplicated block used 3+ times within the diff, tighten a comment that lies.
   - **Flag, don't fix**: missing error handling, unclear abstraction, logic that looks wrong but might be intentional, tests missing.
   - **Style**: formatting inconsistencies the formatter will catch — ignore (trust the formatter).

3. **Check the diff against these principles** (in order of priority):
   1. **DRY** — duplicated logic within the diff. Extract if ≥ 3 copies.
   2. **SOC** — does each new unit have a single responsibility?
   3. **Naming** — do names describe intent, not implementation? No `data`, `util`, `handle`.
   4. **Error handling** — are error paths visible, or silenced? Flag silenced errors.
   5. **Complexity** — a function > ~40 lines or > 3 levels of nesting — consider splitting.
   6. **Dead code** — imports, variables, functions added but unused.
   7. **Comments** — do they explain *why*? Delete `// increments i`.
   8. **Hardcoded values** — magic numbers / strings that look environment-specific.

4. **Apply auto-fixes** in the actual files (not as a patch suggestion). After each fix, re-read the file to confirm.

5. **Report.** Produce the report in the format below.

## Report format

```
Pre-commit review — <N> files changed

AUTO-FIXED
- path/to/file.ext:L — <short description>
- …

FLAGGED (operator decides)
- path/to/file.ext:L — <what> | <why it matters> | <suggested direction>
- …

PASS
<anything notable that looked good, 1-3 bullets max>
```

Respond in the conversation's language by default.

## Guardrails

- Never delete code the operator wrote outside the current diff.
- Never reformat whole files — trust the formatter.
- Never change public interfaces (function signatures, exported types) in auto-fix mode — flag instead.
- If in doubt between auto-fix and flag → flag.
