#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel)}"
fail=0

# 1. Migrate every ../../references/<file> usage — markdown links and bare code-spans
#    alike: copy the canonical file into the skill's own references/ folder, then
#    rewrite every ../../references/ prefix to references/.
while IFS= read -r -d '' skill_md; do
  skill_dir="$(dirname "$skill_md")"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    src="$plugin_dir/references/$ref"
    if [ ! -f "$src" ]; then
      echo "ERROR: $skill_md references references/$ref but canonical $src is missing" >&2
      fail=1; continue
    fi
    mkdir -p "$skill_dir/references"
    cp "$src" "$skill_dir/references/$ref"
  done < <(grep -oE '\.\./\.\./references/[A-Za-z0-9._-]+' "$skill_md" \
            | sed -E 's:.*/::' | sort -u)

  sed -i.bak 's:\.\./\.\./references/:references/:g' "$skill_md"
  rm -f "$skill_md.bak"
done < <(find "$ROOT"/plugins -path '*/skills/*/SKILL.md' -print0)

# 2. Refresh every colocated copy that has a canonical source, so edits to the
#    canonical rubric propagate. (react-review's rubric has no canonical under
#    plugins/<plugin>/references/, so it is its own source and is skipped.)
while IFS= read -r -d '' colocated; do
  skill_dir="$(cd "$(dirname "$colocated")/.." && pwd)"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"
  ref="$(basename "$colocated")"
  src="$plugin_dir/references/$ref"
  [ -f "$src" ] && cp "$src" "$colocated"
done < <(find "$ROOT"/plugins -path '*/skills/*/references/*.md' -print0)

[ "$fail" -eq 0 ] || { echo "sync-references: failed" >&2; exit 1; }
echo "sync-references: done"
