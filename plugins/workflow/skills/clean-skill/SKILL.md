---
name: clean-skill
description: Use when removed or deprecated Turkit skills still appear after updating/reinstalling, or when the operator wants to audit skill install directories before deleting old Turkit-owned skills.
disable-model-invocation: true
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(find:*), Bash(test:*), Bash(rg:*), Bash(grep:*), Bash(diff:*), Bash(rm:*), Read, Grep, Glob
---

# Clean Skill

Audit installed skill/command folders for stale Turkit assets, then remove only confirmed Turkit-owned leftovers.

## Scope

Known stale Turkit assets:

| Name | Why stale |
|---|---|
| `grill-me` | Removed in Turkit v3.2.0; use Matt Pocock's standalone `grill-me` or `ticket --grill`. |
| `ticket-triage` | Folded into `ticket --triage`. |
| `ticket-plan` | Folded into `ticket --plan`. |
| `ticket-execute` | Folded into `ticket --execute`. |
| `shipoff` as a skill folder | Replaced by the thin `shipoff` command alias for `handoff ship`. |

Do not remove current Turkit skills, Matt Pocock skills, project skills, or plugin cache internals.

## Install Roots To Check

Check only roots that exist:

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.codex/skills`
- `.agents/skills`
- `.claude/skills`
- `.claude/commands`
- `.codex/skills`

If the operator names a path, check that path too, without recursing outside it.

## Workflow

1. **Audit.**
   - List candidate paths whose basename matches the stale names above.
   - For each skill folder, read `SKILL.md` when present.
   - For each command file, read the file.

2. **Classify.**
   Use this table:

   ```markdown
   | Path | Classification | Action | Why |
   |---|---|---|---|
   | <path> | safe-delete | delete / keep | <fingerprint> |
   ```

   Classifications:
   - `safe-delete`: name is stale and contents match old Turkit behavior.
   - `ambiguous`: name is stale but contents do not prove Turkit ownership.
   - `keep`: not stale, or belongs to another package such as Matt Pocock's `grill-me`.

3. **Ask before delete.**
   - Default mode is audit-only.
   - If safe-delete candidates exist, ask the operator to confirm exact paths.
   - Delete only paths shown in the table and explicitly confirmed.

4. **Delete narrowly.**
   - Use one explicit `rm -rf <path>` per confirmed stale directory.
   - Use `rm <path>` only for confirmed stale command files.
   - Never use globs with `rm`.
   - Never delete an entire install root.

5. **Verify.**
   - Re-run the candidate scan.
   - Report remaining stale, ambiguous, and kept items.
   - Recommend reinstall/update after cleanup:
     ```bash
     npx skills add alimtunc/turkit
     ```

## Turkit Fingerprints

Treat these as Turkit-owned stale fingerprints:

- `grill-me` with description mentioning "challenge a planned change, ticket, design, or AI-generated plan".
- `ticket-triage`, `ticket-plan`, or `ticket-execute` that references the old Turkit ticket chain.
- `shipoff` skill folder that delegates to handoff/ship as a standalone skill.

Matt Pocock's `grill-me` is not stale if its description says "A relentless interview to sharpen a plan or design" or references `/grilling`.

## Guardrails

- Never delete without explicit path-level confirmation.
- Never delete ambiguous candidates.
- Never delete current Turkit skills such as `ticket`, `goal-loop`, `resolve-conflict`, `work-brief`, `teachback-gate`, `handoff`, or `ship`.
- Never modify repository source code while cleaning an installed skills directory.
- Respond in the conversation's language by default.
