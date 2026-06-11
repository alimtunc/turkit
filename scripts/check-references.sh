#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"

# (a) No skill may carry a shared-sibling reference link/span.
if grep -rn '\.\./\.\./references/' "$ROOT"/plugins/*/skills/*/SKILL.md; then
  echo "DRIFT: shared-sibling references found — run scripts/sync-references.sh" >&2
  exit 1
fi

# (b) Colocated copies must equal their canonical source.
status=0
while IFS= read -r -d '' colocated; do
  skill_dir="$(cd "$(dirname "$colocated")/.." && pwd)"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"
  src="$plugin_dir/references/$(basename "$colocated")"
  if [ -f "$src" ] && ! diff -q "$src" "$colocated" >/dev/null; then
    echo "DRIFT: $colocated differs from canonical $src" >&2
    status=1
  fi
done < <(find "$ROOT"/plugins -path '*/skills/*/references/*.md' -print0)

[ "$status" -eq 0 ] && echo "check-references: clean"
exit "$status"
