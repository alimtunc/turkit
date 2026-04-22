---
name: pr-description
description: Generate a short, concise PR description in the conversation's language from the current branch's commits and diff versus the base branch.
disable-model-invocation: true
allowed-tools: Bash(git *)
---

# PR Description

Generate a tight PR description from the branch's commits and diff.

## Steps

1. **Resolve the base branch** via `docs/contracts/build-tool-detection.md#base_branch`.
2. **Gather inputs** with these read-only git commands:
   - `git log --oneline <base>..HEAD`
   - `git diff --stat <base>..HEAD`
   - `git log <base>..HEAD --format='%B' --no-merges` (full commit messages)
3. **Extract the ticket ID** via `docs/contracts/issue-tracker-detection.md`. If present, include it in the description header.
4. **Write the description** following the rules below.
5. **Output** in a single fenced markdown block (so the operator can one-click copy into `gh pr create --body`).

## Writing rules

- Respond in the conversation's language by default.
- **Short.** Aim for under 15 lines. Two sections max: Summary + Test plan.
- **Summary:** 1–3 bullet points describing *what changed* and *why*, functional language.
- **Test plan:** 2–5 bullets covering happy path + key edge cases. Reuse test-instructions output if present.
- **Ticket link** at the very top if a tracker ID is known: `Closes <TICKET-ID>`.
- **No file-by-file walkthrough.** The diff speaks for itself.
- **No "Co-Authored-By"** and no AI credit.

## Output format

```
```markdown
Closes <TICKET-ID>

## Summary

- <bullet>
- <bullet>

## Test plan

- [ ] <manual step>
- [ ] <manual step>
```
```
