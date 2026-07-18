# Branch-Level Review

Single source of truth for branch-level review, consumed by `pre-pr-review` and `goal-review --branch`.

## Branch-Level Checklist

### B1. Per-Commit Coherence

For each commit:

- **P1** subject accurately describes the change
- **P1** commit is self-contained and compiles conceptually without relying on the next commit
- **P0** debug prints or commented-out code introduced and not removed by a later commit
- **P1** subject violates documented project convention

### B2. Cross-Commit Drift

Flag:

- **P0** renamed symbols still referenced in later commits, docs, fixtures, or tests
- **P1** code added then deleted later without value; suggest squash
- **P0** tests added for behavior later changed so they no longer assert what they imply
- **P0** commits that pass individually but interact to break a contract
- **P1** fixup/revert commits that should be squashed or dropped

### B3. Branch Intent

Flag:

- **P1** branch changes do not match ticket/PR title/branch name
- **P1** public API surface added without an in-branch consumer
- **P0** added files never used anywhere in the branch
- **P0** added dependencies never imported/used
- **P1** rename/refactor/behavior change mixed in a way that harms reviewability

### B4. Verification

- Lint must run or be reported unavailable.
- If executable code changed and tests were not run, list that under Residual Risks.
- Recommend build/type-check when present; do not run tests/build beyond lint unless the operator asked or the project workflow requires it.

## Output Format

```markdown
## Branch summary

- Base: `<base>`
- Commits: N (`<oldest>..<newest>`)
- Files touched: N (Branch) / N (Local — only if dirty)
- Lines: +N / -N (Branch)  | +N / -N (Local — only if dirty)
- Local scope present: yes | no

## Per-Commit

- `<hash>` `<subject>`: OK | 1-line finding

## Cross-Commit

- [P0|P1] [Category] What | affected commits | suggested action

## Branch-Level

- Intent match: OK | comment
- API surface: OK | comment
- Dead files / dead deps: none | list
- Commit granularity: OK | comment

## Verdict

- Ready for PR | Needs N fixes before PR | Reconsider branch structure
- If `Local` scope present and non-empty, `Ready for PR` requires the operator to commit (or discard) the local diff. State this explicitly.
- If the branch touches auth, payments, schemas, or migrations: remind that this review covers structural cleanliness only — run the project's correctness/security tooling before shipping.
```
