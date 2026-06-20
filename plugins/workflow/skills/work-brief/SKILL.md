---
name: work-brief
description: Use after an AI coding session or before commit, PR, handoff, or release when the operator wants a human-readable summary of what was done and why, with key files and current state, without a long audit.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Read, Grep, Glob
---

# Work Brief

Explain the work produced in this session so the operator can regain context and decide what to do next.

## Scope

- Default: summarize the current local diff; if no local diff exists, summarize the current branch versus the resolved base branch.
- If the operator passes a commit, branch, PR text, ticket id, or topic, use that as the target when possible.
- This is for the human operator, not another agent. Use `handoff` for a resumable agent-to-agent transfer.

## Steps

1. Inspect `git status --short`, current branch, recent commits, staged diff, unstaged diff, and untracked files.
2. If no local diff exists, resolve the base branch via `.turkit.yaml → base_branch`, remote HEAD, then `main`; compare base to current branch.
3. Read `references/output-preferences.md` and apply the configured output language/style.
4. Read only the files needed to explain the main behavior, important decisions, verification evidence, and current state.
5. Group the work into 2-4 meaningful pieces. Prefer product/domain boundaries over file types.
6. Link only the key files. Do not list every changed file.

## Output

Respond using the configured output language. Aim for one screen, roughly 25-45 lines. Use this shape:

```markdown
<ticket or subject> fait. Voilà l'essentiel :

## Quoi
<3-5 lines: what was built/changed, not a file list>

## Pourquoi
<2-4 lines: pain solved, goal, or tradeoff. If not visible, say so.>

## Les morceaux
1. <piece name>
   - <short explanation>
   - Fichiers: [path](path), [path](path)

2. <piece name>
   - <short explanation>
   - Fichiers: [path](path)

## Qualité
- Tests/checks: <commands and results, or "not run / not visible">
- Review: <done / not done / not visible>
- Risque: <one concrete remaining risk>

## État
- Branche: <branch>
- Commit/PR: <hash/URL or "not yet">
- Ticket: <id/status or "not detected">
- Next: <one logical next action>
```

For English conversations, translate the headings naturally (`What`, `Why`, `Pieces`, `Quality`, `State`).

## Guardrails

- Read-only: do not stage, commit, push, edit, create branches, update tickets, or create PRs.
- Do not output a long audit, full code tour, or file-by-file walkthrough.
- Do not claim tests/checks/reviews passed unless there is explicit evidence from the current session, logs, or repo state.
- Do not invent why a change was made. If intent is not visible, say "not obvious from the diff".
- Keep links to 3-8 important files max. If a file line matters and is known, link the line.
- If the work is too large for one screen, summarize the top pieces and end with `Open next: <file or command>`.

Apply `references/output-preferences.md` for operator-facing language/style.
