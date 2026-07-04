---
name: visual-map
description: Use when the operator wants a durable visual HTML map of a repo, app, feature, workflow, architecture, package interaction, dependency graph, database schema, ERD, call path, typical execution trace, or architecture impact from a diff. Trigger on visual map, architecture page, workflow diagram, boxes-in-boxes, treemap, package arrows, database map, ERD, schema map, feature path, call chain, app map, dependency map, runtime trace, execution trace, startup trace, or docs/ai HTML. For interactive diff walkthroughs or file-by-file diff review, recommend Codiff instead of this skill.
disable-model-invocation: true
allowed-tools: Bash(command -v graphify:*), Bash(graphify:*), Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Bash(mkdir:*), Bash(test:*), Bash(rg:*), Read, Grep, Glob, Write, Edit, MultiEdit
---

# Visual Map

Generate a durable standalone HTML architecture artifact under `docs/ai/`.

This skill is not a diff walkthrough tool. Use Codiff for interactive diff review and file-by-file walkthroughs. Use Visual Map when the operator needs to understand structure, relations, data flow, package boundaries, database entities, or the architectural impact of a change.

## Modes

| Flag | Meaning |
|---|---|
| `--repo` | Map the whole project at a high level. |
| `--feature <name>` | Map one feature, ticket, module, or capability. |
| `--flow <name>` | Map one user/system workflow as a trace. |
| `--entry <symbol|file|command>` | Start a call path from this entry point. |
| `--trace [command|name]` | Map a typical execution trace from command/script/entrypoint to files, functions, DB/API, and output. Do not execute it. |
| `--packages` | Emphasize package/module interactions and dependency arrows. |
| `--db`, `--database` | Emphasize database entities, relationships, and feature-touched tables. |
| `--diff` | Use the current diff only to choose/highlight architectural impact. Do not render a diff walkthrough. |
| `--output <path>` | Write to this HTML path. |
| `--update <path>` | Update an existing visual-map HTML page. |

If no flag is provided, infer the scope from the prompt. If the operator asks for “diff review”, “walkthrough”, “file-by-file diff”, or “what changed in this patch”, recommend Codiff first. If they still want Visual Map, use `--diff` as architecture impact.

## Workflow

1. **Resolve scope and output.**
   - Resolve repo root with `git rev-parse --show-toplevel`.
   - Default output: `docs/ai/<slug>-visual-map.html`.
   - Create `docs/ai/` if needed.
   - If updating an existing page, preserve useful anchors only when they still match the current model.

2. **Load context.**
   - Read `references/output-preferences.md` and apply language/style.
   - Read `.turkit.yaml` if present, then only relevant `rules.docs`.
   - Inspect manifests, package/workspace files, entry points, route/API files, domain/contracts, boundary configs, database schema/model/migration files, and only the diff metadata needed to identify changed architectural areas.
   - For `--trace`, inspect package scripts, task runner files, framework config, CLI entrypoints, routes, server bootstrap files, workers, and adapters. Resolve the likely path; do not run the command.
   - Prefer real symbols/functions/files over package-level guesses.

3. **Use graph data when available.**
   - Detect graphify with `command -v graphify`.
   - Refresh/query it for the requested scope when available.
   - Use graphify for imports, reverse imports, symbols, tests, package edges, and related files.
   - Fall back to Git and `rg` without blocking when graphify is unavailable.
   - Git remains authoritative for changed-file status when `--diff` is used.

4. **Build the model before writing HTML.**
   Include:
   - subject: what this repo/feature/workflow does;
   - topology: repo/app/package/module/file groups with responsibilities;
   - package interactions: package -> package edges, edge type, direction, representative file/symbol;
   - database model: entities/tables grouped by domain, primary keys, foreign keys, important fields, relationships, cardinality when proven, source files;
   - typical execution trace: command/script -> entry file -> bootstrap/router/server -> functions/modules -> DB/API/filesystem/event/output;
   - feature path: entry -> route/function -> module/service -> state/event/API/DB -> output;
   - external systems: APIs, queues, CLIs, filesystems, auth providers, storage, observability;
   - boundaries: allowed/forbidden imports, ownership, contracts, and inferred boundaries;
   - key files: 5-12 files max, each with why to open it;
   - unknowns: anything not proven by code/docs.

5. **When `--trace` is used.**
   - Identify the start point: explicit trace name, package script, command, route, file, symbol, or inferred default dev/start path.
   - Show the resolved chain: command -> script -> entrypoint -> bootstrap -> router/server/worker -> domain modules -> DB/API/filesystem/events -> output.
   - For each node, include file, symbol/function when known, what it does, what it calls next, and what data/state moves through it.
   - Mark unresolved links as inferred or unknown.
   - Never execute the command; this is a static trace from code/config.

6. **When `--diff` is used.**
   - Use `git status --short`, `git diff --name-status --find-renames`, and `git diff --numstat --find-renames`.
   - Highlight changed modules inside the topology, package map, database map, and feature path.
   - Add an “Architecture Impact” section with changed folders/modules and probable impact.
   - Do not include a full patch explorer.
   - Do not produce file-by-file walkthrough prose; point to Codiff for that.

7. **Write the HTML.**
   Use one self-contained file: inline CSS, no external JS/CSS/assets, no CDN. Write only the target HTML file.

8. **Report.**
   Print the output path, scope, graph/index status, and key unknowns.

## Required Page Shape

1. **Header**
   - title: `<Project or feature> — visual map`;
   - one sentence explaining why the page exists;
   - nav links to the sections below;
   - scope metadata: mode, source evidence, graph index status, generated time.

2. **Topology Treemap**
   - Nested rectangles: repo/app -> package/layer -> module -> important file/symbol.
   - Size boxes by relevance to the requested scope, not fake metrics.
   - Color by role: `app`, `frontend`, `backend`, `shared`, `data`, `external`, `tooling`.
   - If `--diff`, highlight changed boxes but do not turn this into a diff review.

3. **Package Interaction Map**
   - Show meaningful package/module nodes with arrows.
   - Label edges: `imports`, `calls HTTP`, `opens SSE`, `emits event`, `reads DB`, `writes DB`, `runs command`, `uses adapter`, `renders`, or `inferred`.
   - For feature/flow scopes, number arrows in execution order when known.
   - Do not draw every import; draw relations that explain the architecture.

4. **Database Map**
   - Include when `--db`/`--database` is passed or schema/model/migration sources are discoverable.
   - Use table cards grouped by domain/category/schema.
   - Show primary keys, foreign keys, key domain fields, and relationship lines.
   - Use solid lines for proven foreign keys and dashed lines for inferred usage-based links.
   - Mark inferred relationships explicitly; do not invent cardinality.
   - Keep this visual and readable; avoid one huge horizontal canvas.

5. **Typical Execution Trace**
   - Include when `--trace` is requested.
   - Show `command/script -> entrypoint -> bootstrap -> router/server/worker -> function/module -> DB/API/filesystem/event -> output`.
   - Each node includes file, symbol/function/route/command, what happens, calls next, and data/state passed forward.
   - Each edge includes `runs`, `loads`, `imports`, `calls`, `routes`, `reads`, `writes`, `emits`, `subscribes`, `renders`, `returns`, or `inferred`.
   - Include branch points for important conditions, fallback/error paths, async jobs, and background workers.

6. **Directional Feature Path**
   - Show entry -> function/route -> service/module -> state/event/API/DB -> output.
   - Each node includes file, symbol/route/command, what happens, and data/state passed forward.
   - Each edge includes `calls`, `imports`, `emits`, `writes`, `reads`, `subscribes`, `renders`, `returns`, or `inferred`.

7. **External Systems**
   - List external services, CLIs, queues, storage, auth, network calls, generated artifacts, and runtime assumptions.

8. **Boundaries**
   - Show what can call/import what, what is forbidden, and why.
   - If no config proves it, label the boundary as inferred.

9. **Architecture Impact**
   - Include when `--diff` is used.
   - Summarize changed modules/folders and their architectural impact.
   - Link to Codiff for detailed diff walkthrough instead of duplicating it.

10. **Mental Model**
   - 3-5 bullets the reader should keep in mind.

11. **Key Files**
   - 5-12 links max, each with one-line role and why to open it.

12. **Risks / Unknowns**
   - What the map does not prove.
   - What to reread before changing the area.

## Visual Rules

- Make the page useful at 1200px desktop and readable on mobile.
- Use boxes inside boxes for hierarchy.
- Use package arrows for relations, not vague prose.
- Use database-designer table cards and readable connectors for DB maps.
- Prefer CSS grid/flex layouts over fixed-width absolute-position canvases.
- Keep technical terms in English when `technical_terms: keep-english`.
- Do not use Mermaid as the primary view. Mermaid can be a secondary export for DB only.
- Do not list every file or draw every import.
- Do not execute runtime commands while building a trace; infer from code/config only.
- Do not include secrets, `.env` values, tokens, private URLs, or long source snippets.
- Do not claim runtime behavior that was not visible in code/docs/diff; mark uncertain items as inferred.

## Codiff Boundary

If the operator wants:

- an interactive diff viewer;
- a narrative walkthrough of the diff;
- file-by-file explanation of changed hunks;
- inline review comments;
- a review UX similar to a mini app;

recommend Codiff. Visual Map should complement it with architecture, dependency, package, database, and workflow context.
