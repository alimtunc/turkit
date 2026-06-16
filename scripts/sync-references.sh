#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel)}"
fail=0

# Resolve a reference filename to its canonical source. Two canonical roots, with
# no filename overlap between them (rubric/template names vs. contract names):
#   plugins/<plugin>/references/<name>  — shared rubrics/templates, per plugin
#   docs/contracts/<name>               — repo-wide detection contracts
# Prints the path of the first that exists, or nothing.
canonical_src() {
  local plugin_dir="$1" name="$2"
  if [ -f "$plugin_dir/references/$name" ]; then
    printf '%s' "$plugin_dir/references/$name"
  elif [ -f "$ROOT/docs/contracts/$name" ]; then
    printf '%s' "$ROOT/docs/contracts/$name"
  fi
}

# 1. Vendor references into each skill's own references/ folder so per-skill
#    installs stay self-contained.
#    (a) ../../references/<file> — shared sibling rubrics/templates: copy the
#        canonical file in, then rewrite the prefix to references/.
#    (b) references/<contract>.md citing a docs/contracts/ file: vendor the
#        contract so the skill resolves it without the repo root.
while IFS= read -r -d '' skill_md; do
  skill_dir="$(dirname "$skill_md")"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    src="$(canonical_src "$plugin_dir" "$ref")"
    if [ -z "$src" ]; then
      echo "ERROR: $skill_md references references/$ref but no canonical source exists" >&2
      fail=1; continue
    fi
    mkdir -p "$skill_dir/references"
    cp "$src" "$skill_dir/references/$ref"
  done < <(grep -oE '\.\./\.\./references/[A-Za-z0-9._-]+' "$skill_md" \
            | sed -E 's:.*/::' | sort -u)

  sed -i.bak 's:\.\./\.\./references/:references/:g' "$skill_md"
  rm -f "$skill_md.bak"

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    [ -f "$ROOT/docs/contracts/$ref" ] || continue
    mkdir -p "$skill_dir/references"
    cp "$ROOT/docs/contracts/$ref" "$skill_dir/references/$ref"
  done < <(grep -oE 'references/[A-Za-z0-9._-]+\.md' "$skill_md" \
            | sed -E 's:.*/::' | sort -u)
done < <(find "$ROOT"/plugins -path '*/skills/*/SKILL.md' -print0)

# 2. Refresh every colocated copy that has a canonical source, so edits to the
#    canonical rubric/template/contract propagate. (react-review's rubric has no
#    canonical under either root, so it is its own source and is left untouched.)
while IFS= read -r -d '' colocated; do
  skill_dir="$(cd "$(dirname "$colocated")/.." && pwd)"
  plugin_dir="$(cd "$skill_dir/../.." && pwd)"
  src="$(canonical_src "$plugin_dir" "$(basename "$colocated")")"
  [ -n "$src" ] && cp "$src" "$colocated"
done < <(find "$ROOT"/plugins -path '*/skills/*/references/*.md' -print0)

[ "$fail" -eq 0 ] || { echo "sync-references: failed" >&2; exit 1; }
echo "sync-references: done"
