#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Fixture: one plugin, two shared references, one skill that uses both — once as a
# markdown link, once as a bare code-span (the two forms turkit skills actually use).
mkdir -p "$tmp/plugins/demo/references" "$tmp/plugins/demo/skills/foo"
printf 'CANON v1\n' > "$tmp/plugins/demo/references/rub.md"
printf 'GUIDE v1\n' > "$tmp/plugins/demo/references/guide.md"
cat > "$tmp/plugins/demo/skills/foo/SKILL.md" <<'EOF'
---
name: foo
description: demo
---
See [rubric](../../references/rub.md) and again [rub](../../references/rub.md).
Follow `../../references/guide.md` literally.
EOF

"$here/sync-references.sh" "$tmp"

# Both colocated copies exist with canonical content.
test -f "$tmp/plugins/demo/skills/foo/references/rub.md"
test -f "$tmp/plugins/demo/skills/foo/references/guide.md"
grep -q 'CANON v1' "$tmp/plugins/demo/skills/foo/references/rub.md"
grep -q 'GUIDE v1' "$tmp/plugins/demo/skills/foo/references/guide.md"
# Both forms rewritten: link target and bare code-span.
grep -q '](references/rub.md)' "$tmp/plugins/demo/skills/foo/SKILL.md"
grep -q '`references/guide.md`' "$tmp/plugins/demo/skills/foo/SKILL.md"
if grep -q '\.\./\.\./references/' "$tmp/plugins/demo/skills/foo/SKILL.md"; then
  echo "FAIL: a shared-sibling reference was not rewritten" >&2; exit 1
fi

# Idempotent + propagates canonical edits on re-run.
printf 'CANON v2\n' > "$tmp/plugins/demo/references/rub.md"
"$here/sync-references.sh" "$tmp"
grep -q 'CANON v2' "$tmp/plugins/demo/skills/foo/references/rub.md"
if grep -q '\.\./\.\./references/' "$tmp/plugins/demo/skills/foo/SKILL.md"; then
  echo "FAIL: a reference reverted on re-run" >&2; exit 1
fi

echo "PASS"
