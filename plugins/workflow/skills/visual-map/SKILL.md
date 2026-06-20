---
name: visual-map
description: Use when the operator wants a visual HTML map of a repo, app, feature, workflow, architecture, package interaction, database schema, call path, or diff for human onboarding and understanding. Trigger on visual map, architecture page, workflow diagram, boxes-in-boxes, treemap, package arrows, database map, ERD, schema map, feature path, call chain, app map, or docs/ai HTML.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(pwd:*), Bash(mkdir:*), Bash(test:*), Bash(rg:*), Read, Grep, Glob, Write, Edit, MultiEdit
---

# Visual Map

Generate a standalone HTML page that explains a repo, app, feature, workflow, architecture, or diff visually for a human reader.

## Intent

This is not a generic node graph. Build a guided visual document with linked views:

- a treemap-like nested box map for ownership and structure;
- a package interaction map showing which packages call/import/emit/read/write each other;
- a database map when schemas/models/migrations are discoverable;
- a directional feature path showing exactly what calls what, what each step calls next, and where state/data moves.

## Arguments

Parse these optional flags:

| Flag | Meaning |
|---|---|
| `--repo` | Map the whole project at a high level. |
| `--feature <name>` | Map one feature, ticket, module, or capability. |
| `--flow <name>` | Map one user/system workflow as a trace. |
| `--entry <symbol|file|command>` | Start the feature path from this entry point. |
| `--packages` | Emphasize package-to-package arrows and call order. |
| `--db`, `--database` | Emphasize database entities, relationships, and feature-touched tables in a visual ERD canvas. |
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
   - Inspect only what explains the scope: manifests, package/workspace files, entry points, route/API files, domain/contracts, boundary configs, database schema/model/migration files, and the current diff when `--diff`.
   - For `--feature`, `--flow`, `--entry`, or `--diff`, trace the concrete call path with `rg`, imports, route handlers, commands, event names, API clients, and state writes. Prefer real symbols/functions/files over package-level guesses.
   - For `--db` or when schema files are obvious, inspect common project-agnostic DB sources: SQL migrations, ORM schemas/models, generated schema files, and migration folders. Do not assume one ORM or framework.

3. **Build the model before writing HTML.**
   Produce an internal outline with:
   - Subject: what this repo/feature/workflow does.
   - Treemap model: repo/app/package/module/file groups, each with responsibility and role.
   - Package interactions: package -> package edges, edge type, direction, call order when known, and representative file/symbol proving the link.
   - Database model: entities/tables grouped by domain/category, primary keys, foreign keys, important domain fields, relationships, cardinality, and source files proving each link.
   - Feature path: entry -> call -> call -> state/event/API -> output.
   - For each path node: file, symbol/route/command, what it calls next, important data/state, and whether the edge is proven or inferred.
   - For feature scopes, touched database entities and whether the feature reads, writes, creates, updates, deletes, or subscribes to each one.
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

2. **Topology Treemap**
   - Use nested rectangles like a treemap: repo/app -> package/layer -> module -> important file/symbol.
   - Size boxes by relevance to the requested scope, not fake metrics. If using a metric, label it explicitly (`files`, `changed files`, `commits`, etc.).
   - Each box has a short responsibility, not a file dump.
   - Use color by role: `app`, `frontend`, `backend`, `shared`, `data`, `external`, `tooling`.
   - Highlight the boxes that are on the feature path with a shared accent class.

3. **Package Interaction Map**
   - Show packages as larger nodes with arrows between them.
   - Each arrow must have a label describing how they are linked: `imports`, `calls HTTP`, `opens SSE`, `emits event`, `reads DB`, `writes DB`, `runs command`, `uses adapter`, `renders`, or `inferred`.
   - For feature/flow scopes, number the arrows in the order they happen (`1`, `2`, `3`) so the reader sees the package call sequence.
   - For repo scopes, group arrows by direction/layer rather than drawing every import. Show only the meaningful package-level links.
   - Each package node should list 1-4 key responsibilities and 1-3 representative files/symbols.
   - If one package both calls and is called by another package, draw two explicit arrows or label the bidirectional relation.

4. **Database Map**
   - Include this section when `--db`/`--database` is passed or when database schemas, models, migrations, or DB access modules are discoverable.
   - If no database source is found, keep the section short and say what was checked.
   - The primary view must be a database-designer canvas: light dotted/grid background, table cards placed on the canvas, connector lines between related tables, a compact legend, and an optional mini-map/overview when there are many tables.
   - Each table card should look like a schema object: table name header, rows for key columns, small badges/icons/text for primary key, foreign key, unique, nullable/non-nullable, and the column type.
   - Show relationships as visible SVG/CSS connectors anchored near the related table cards. Use solid lines for proven foreign keys and dashed lines for inferred or usage-based links.
   - Label relation connectors with the foreign key or operation name when readable, and show cardinality (`1-1`, `1-N`, `N-N`) only when the schema or code proves it.
   - Group entities/tables by domain/category or schema using visual lanes, section labels, or color accents; do not render them as one flat text dump.
   - Mark naming-based or usage-based relationships as `inferred`; do not invent foreign keys or cardinality.
   - Each entity/table box should include: role, primary key, foreign keys, and only the few domain fields needed to understand the area.
   - For feature/flow/diff scopes, highlight the tables/entities touched by the path and label the operation: `reads`, `writes`, `creates`, `updates`, `deletes`, or `subscribes`.
   - When useful, include a copyable Mermaid `erDiagram` block as a secondary export after the visual canvas, backed by the same proven relationships shown visually.

5. **Directional Feature Path**
   - Show the path as a left-to-right or top-to-bottom directed line: entry -> function/route -> service/module -> state/event/API -> output.
   - Use arrows between nodes. The reader must be able to follow the feature from start to finish without reading prose.
   - Each node contains: title, file, symbol/route/command, what happens, and the data/state passed forward.
   - Each edge contains a short label: `calls`, `imports`, `emits`, `writes`, `reads`, `subscribes`, `renders`, `returns`, or `inferred`.
   - For important nodes, include a small "calls next" list with 2-5 direct callees or downstream events. Do not expand every trivial helper.
   - Prefer one main happy path over many shallow branches.

6. **Boundaries**
   - Show what can call/import what, what is forbidden, and why.
   - If no boundary config exists, state the inferred boundary and mark it as inferred.

7. **Mental Model**
   - 3-5 bullets the reader should keep in mind.

8. **Key Files**
   - 5-12 links max.
   - Each file explains its role in one line.

9. **Risks / Unknowns**
   - What the map does not prove.
   - What to reread before changing this area.

## Visual Style

- Make the page useful at 1200px desktop and readable on mobile.
- Use boxes inside boxes for hierarchy; do not reduce the page to separate cards.
- Use a treemap-like area for topology, a package arrow map for package relations, a database-designer ERD canvas when relevant, and a separate directed path for the feature/workflow.
- A small inline SVG is allowed for arrows/edges when it makes the path clearer; keep the boxes themselves as semantic HTML.
- For database maps, prefer positioned HTML table cards plus inline SVG connectors over text-only Mermaid. The reader should understand table relationships visually before reading prose.
- Keep paragraphs short. Prefer labels + one-line explanations.
- Use file paths in `code` tags and links where possible.
- Keep technical terms in English when `technical_terms: keep-english`.
- Do not use Mermaid by default for the whole document. For database maps, Mermaid `erDiagram` is allowed as a secondary export; the page still needs a readable HTML/SVG view without external Mermaid runtime.

## HTML Guardrails

- Add `<html lang="...">` from the resolved output language when known.
- Add `<meta name="generator" content="turkit visual-map">`.
- Add `data-turkit-visual-map="true"` on `<body>`.
- Escape user/code text before embedding in HTML.
- Do not include secrets, `.env` values, tokens, private URLs, or long source snippets.
- Do not include database credentials, connection strings, seed PII, or sample production values.
- Do not claim runtime behavior that was not visible in code/docs/diff; mark uncertain items as inferred.
- Do not dump every column. Show only keys and fields that explain the relationship or feature.
- Do not make the database view a paragraph, plain list, or Mermaid-only block. It must have visible table boxes and relationship lines when at least two related tables are known.
- Do not list every file. A visual map is an onboarding artifact, not a code index.
- Do not draw every import. Draw the requested feature path plus the relevant fan-out/fan-in that explains it.
- Do not leave package relations as vague prose. Important package links must appear as visible arrows with labels.
- Do not modify application source files, project config, commits, branches, PRs, or tracker state.
