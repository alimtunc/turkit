# Build Tool Detection Contract

Skills that need to run project commands (`check`, `lint`, `fmt`, `test`, `build`) MUST resolve them via this order:

1. **`.turkit.yaml`** at the repo root, `commands:` section — explicit user override. If present, use it verbatim for any command it defines; fall through only for commands it does not define.

2. **`Justfile`** — run `just <cmd>` if the Justfile defines `<cmd>`.

3. **`Makefile`** — run `make <cmd>` if the Makefile defines `<cmd>`.

4. **`package.json` scripts** — if `scripts.<cmd>` exists, run with the detected package manager:
   - `pnpm-lock.yaml` present → `pnpm <cmd>`
   - `bun.lockb` present → `bun run <cmd>`
   - `yarn.lock` present → `yarn <cmd>`
   - default → `npm run <cmd>`

5. **Ecosystem defaults** — try the canonical command:
   - `Cargo.toml` → `cargo check` / `cargo fmt` / `cargo clippy` / `cargo test` / `cargo build`
   - `pyproject.toml` (poetry) → `poetry run <cmd>` with sensible defaults (`pytest`, `black .`, `ruff`)
   - `pyproject.toml` (uv) → `uv run <cmd>`
   - `go.mod` → `go test ./...`, `go vet ./...`, `gofmt -w .`
   - `mix.exs` → `mix <cmd>`

6. **Nothing resolved.** Ask the operator once: "I couldn't resolve a `<cmd>` command for this project. What should I run? (Answer gets suggested as `.turkit.yaml` entry.)"

## `.turkit.yaml` shape

```yaml
commands:
  check: just check
  lint: just lint
  fmt: just fmt
  test: cargo test --workspace
  build: just build
base_branch: main   # optional; defaults to detection via `git symbolic-ref refs/remotes/origin/HEAD`
workflow:
  # optional; defaults to feature_branch
  workspace: feature_branch # or worktree_required
  worktree_dir: .worktrees
  branch_template: "{ticket_id_lower}-{slug}"
  init:
    - cp .env.example .env
    - pnpm install
rules:
  docs:
    - CLAUDE.md
    - AGENTS.md
    - docs/conventions/*.md
```

All fields optional. Skills should tolerate a missing file.

Stack-specific plugins MAY add optional commands under `commands:` without changing the core contract. Example:

```yaml
commands:
  react_review: pnpm react-review
```

Core workflow skills ignore unknown command keys. Stack plugins own their own resolution order and fallbacks.

## `workflow`

Workflow-aware skills MAY read `.turkit.yaml → workflow`:

- `workspace`
  - `feature_branch` (default): create/use a normal feature branch.
  - `worktree_required`: create/use a git worktree before editing.
- `worktree_dir`: relative directory for worktrees. Defaults to `.worktrees`.
- `branch_template`: branch slug template. Supported placeholders:
  `{ticket_id}`, `{ticket_id_lower}`, `{slug}`.
- `init`: literal shell commands to run after branch/worktree setup. Commands
  must be copy-pasteable and repo-relative from the active working directory.
  Prefer package-manager directory flags (for example `pnpm --dir ui install`)
  over `cd ui && ...` so command allowlists can match the executable reliably.

## `rules`

Workflow skills MAY read `.turkit.yaml → rules.docs` to find project-specific
instructions. If absent, use repo defaults when present: `CLAUDE.md`,
`AGENTS.md`, and `docs/conventions/*.md`.

## `base_branch`

Skills that compare against a base branch (reviews, PR generation) MUST resolve it via:

1. `.turkit.yaml` → `base_branch`
2. `git symbolic-ref refs/remotes/origin/HEAD` (strips `refs/remotes/origin/` prefix)
3. Fallback: `main`
