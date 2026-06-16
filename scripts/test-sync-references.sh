#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Fixture: one plugin, two shared references, one repo-wide contract, and one skill
# that uses all three — a shared ref as a markdown link, another as a bare code-span
# (the two forms turkit skills actually use), and a contract cited as references/<name>.
mkdir -p "$tmp/plugins/demo/references" "$tmp/plugins/demo/skills/foo" "$tmp/docs/contracts"
printf 'CANON v1\n' > "$tmp/plugins/demo/references/rub.md"
printf 'GUIDE v1\n' > "$tmp/plugins/demo/references/guide.md"
printf 'CONTRACT v1\n' > "$tmp/docs/contracts/det.md"
cat > "$tmp/plugins/demo/skills/foo/SKILL.md" <<'EOF'
---
name: foo
description: demo
---
See [rubric](../../references/rub.md) and again [rub](../../references/rub.md).
Follow `../../references/guide.md` literally.
Resolve detection per `references/det.md`.
EOF

"$here/sync-references.sh" "$tmp"

# Both shared-ref colocated copies exist with canonical content.
test -f "$tmp/plugins/demo/skills/foo/references/rub.md"
test -f "$tmp/plugins/demo/skills/foo/references/guide.md"
grep -q 'CANON v1' "$tmp/plugins/demo/skills/foo/references/rub.md"
grep -q 'GUIDE v1' "$tmp/plugins/demo/skills/foo/references/guide.md"
# The contract was vendored from docs/contracts into the skill's references/.
test -f "$tmp/plugins/demo/skills/foo/references/det.md"
grep -q 'CONTRACT v1' "$tmp/plugins/demo/skills/foo/references/det.md"
# Both shared-ref forms rewritten: link target and bare code-span.
grep -q '](references/rub.md)' "$tmp/plugins/demo/skills/foo/SKILL.md"
grep -q '`references/guide.md`' "$tmp/plugins/demo/skills/foo/SKILL.md"
if grep -q '\.\./\.\./references/' "$tmp/plugins/demo/skills/foo/SKILL.md"; then
  echo "FAIL: a shared-sibling reference was not rewritten" >&2; exit 1
fi

# Idempotent + propagates canonical edits (shared ref AND contract) on re-run.
printf 'CANON v2\n' > "$tmp/plugins/demo/references/rub.md"
printf 'CONTRACT v2\n' > "$tmp/docs/contracts/det.md"
"$here/sync-references.sh" "$tmp"
grep -q 'CANON v2' "$tmp/plugins/demo/skills/foo/references/rub.md"
grep -q 'CONTRACT v2' "$tmp/plugins/demo/skills/foo/references/det.md"
if grep -q '\.\./\.\./references/' "$tmp/plugins/demo/skills/foo/SKILL.md"; then
  echo "FAIL: a reference reverted on re-run" >&2; exit 1
fi

echo "PASS"
