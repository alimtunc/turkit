#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"

# Resolve a reference filename to its canonical source (same roots/order as
# sync-references.sh): plugins/<plugin>/references/ then docs/contracts/.
canonical_src() {
  local plugin_dir="$1" name="$2"
  if [ -f "$plugin_dir/references/$name" ]; then
    printf '%s' "$plugin_dir/references/$name"
  elif [ -f "$ROOT/docs/contracts/$name" ]; then
    printf '%s' "$ROOT/docs/contracts/$name"
  fi
}

# (a) No skill may carry a shared-sibling reference link/span.
if grep -rn '\.\./\.\./references/' "$ROOT"/plugins/*/skills/*/SKILL.md; then
  echo "DRIFT: shared-sibling references found — run scripts/sync-references.sh" >&2
  exit 1
fi

# (b) No skill may cite a repo-root contract directly — contracts must be vendored
#     into the skill's references/ so per-skill installs resolve them. (The bare
#     glob `docs/contracts/*.md`, used by rules-refresh to scan a target repo, is
#     not a dependency and is excluded by requiring a literal filename char after
#     the slash.)
if grep -rnE 'docs/contracts/[A-Za-z0-9]' "$ROOT"/plugins/*/skills/*/SKILL.md "$ROOT"/plugins/*/skills/*/references/*.md; then
  echo "DRIFT: a skill cites repo-root docs/contracts/* directly — cite references/<contract>.md and run scripts/sync-references.sh" >&2
  exit 1
fi

# (c) Colocated copies must equal their canonical source (plugin refs or contracts).
status=0
while IFS= read -r -d '' colocated; do
  skill_dir="$(cd "$(dirname "$colocated")/.." && pwd)"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"
  src="$(canonical_src "$plugin_dir" "$(basename "$colocated")")"
  if [ -n "$src" ] && ! diff -q "$src" "$colocated" >/dev/null; then
    echo "DRIFT: $colocated differs from canonical $src" >&2
    status=1
  fi
done < <(find "$ROOT"/plugins -path '*/skills/*/references/*.md' -print0)

[ "$status" -eq 0 ] && echo "check-references: clean"
exit "$status"
