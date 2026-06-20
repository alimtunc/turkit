---
name: visual-map
description: Use when the operator wants a visual HTML map of a repo, app, feature, workflow, architecture, or diff for human onboarding and understanding. Trigger on visual map, architecture page, workflow diagram, boxes-in-boxes, app map, feature map, or docs/ai HTML.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Bash(mkdir:*), Bash(test:*), Bash(rg:*), Read, Grep, Glob, Write, Edit, MultiEdit
---

# Visual Map

Generate a standalone HTML page that explains a repo, app, feature, workflow, architecture, or diff visually for a human reader.

## Intent

This is not a node graph. Build a guided visual document: nested boxes for ownership, a vertical trace for the main workflow, boundaries/rules, key files, and what to open next.

## Arguments

Parse these optional flags:

| Flag | Meaning |
|---|---|
| `--repo` | Map the whole project at a high level. |
| `--feature <name>` | Map one feature, ticket, module, or capability. |
| `--flow <name>` | Map one user/system workflow as a trace. |
| `--diff` | Map the current branch/diff. |
| `--output <path>` | Write to this HTML path. |
| `--update <path>` | Update an existing visual-map HTML page. |

If no flag is provided, infer the scope from the operator prompt. If still unclear, use the current diff; if no diff exists, map the repo at a high level.

## Workflow

1. **Resolve scope and output.**
   - Resolve repo root with `git rev-parse --show-toplevel`.
   - Default output: `docs/ai/<slug>-visual-map.html`.
   - Create `docs/ai/` if needed.
   - If the output exists and contains `data-turkit-visual-map="true"`, update it. If it exists without that marker and `--update` was not passed, choose a new slug or ask before overwriting.

2. **Load context.**
   - Read `references/output-preferences.md` and apply configured language/style.
   - Read `.turkit.yaml` if present, then the listed `rules.docs` when relevant.
   - Inspect only what explains the scope: manifests, package/workspace files, entry points, route/API files, domain/contracts, boundary configs, and the current diff when `--diff`.

3. **Build the model before writing HTML.**
   Produce an internal outline with:
   - Subject: what this repo/feature/workflow does.
   - Box model: app/package/module groups and each responsibility.
   - Main trace: trigger -> boundary -> work -> state/event -> output.
   - Boundaries: allowed/forbidden imports, ownership, external systems, contracts.
   - Key files: 5-12 files max, each with why to open it.
   - Unknowns: anything not proven by code/docs.

4. **Write the HTML.**
   Use a single self-contained file: inline CSS, no external JS/CSS/assets, no CDN. Use accessible semantic HTML and stable anchors.
   Write only the target HTML file. Do not edit application source code while mapping.

5. **Report.**
   Print the output path, scope, key unknowns, and one suggested next command/file.

## Required Page Shape

The HTML page must include these sections, in this order:

1. **Header**
   - Title: `<Project or feature> — visual map`
   - One sentence: what the system does and why the page exists.
   - Nav links to the sections below.

2. **Map**
   - Nested boxes: product/app -> package/layer -> module/component.
   - Each box has a short responsibility, not a file dump.
   - Use color by role: `app`, `frontend`, `backend`, `shared`, `data`, `external`, `tooling`.

3. **Main Flow**
   - A vertical trace rail ("hockey stick" style): one numbered step per meaningful transition.
   - Each step contains: title, what happens, important data/state, key file(s).
   - Prefer one main happy path over many shallow branches.

4. **Boundaries**
   - Show what can call/import what, what is forbidden, and why.
   - If no boundary config exists, state the inferred boundary and mark it as inferred.

5. **Mental Model**
   - 3-5 bullets the reader should keep in mind.

6. **Key Files**
   - 5-12 links max.
   - Each file explains its role in one line.

7. **Risks / Unknowns**
   - What the map does not prove.
   - What to reread before changing this area.

## Visual Style

- Make the page useful at 1200px desktop and readable on mobile.
- Use boxes inside boxes for hierarchy; avoid canvas/SVG graph spaghetti.
- Use a vertical trace with dots/rail for workflow.
- Keep paragraphs short. Prefer labels + one-line explanations.
- Use file paths in `code` tags and links where possible.
- Keep technical terms in English when `technical_terms: keep-english`.
- Do not use Mermaid unless the operator explicitly asks.

## HTML Guardrails

- Add `<html lang="...">` from the resolved output language when known.
- Add `<meta name="generator" content="turkit visual-map">`.
- Add `data-turkit-visual-map="true"` on `<body>`.
- Escape user/code text before embedding in HTML.
- Do not include secrets, `.env` values, tokens, private URLs, or long source snippets.
- Do not claim runtime behavior that was not visible in code/docs/diff; mark uncertain items as inferred.
- Do not list every file. A visual map is an onboarding artifact, not a code index.
- Do not modify application source files, project config, commits, branches, PRs, or tracker state.
