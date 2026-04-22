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
```

All fields optional. Skills should tolerate a missing file.

## `base_branch`

Skills that compare against a base branch (reviews, PR generation) MUST resolve it via:

1. `.turkit.yaml` → `base_branch`
2. `git symbolic-ref refs/remotes/origin/HEAD` (strips `refs/remotes/origin/` prefix)
3. Fallback: `main`
