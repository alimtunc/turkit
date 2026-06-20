# Output Preferences Contract

Skills that emit operator-facing prose MAY read Turkit output preferences from
the resolved config. All fields are optional and must degrade cleanly when
absent.

## Config files

Resolve output preferences from:

1. Repo config: `.turkit.yaml` at the current repo root.
2. Global config: `~/.config/turkit/config.yaml`.
3. Legacy global fallback: `~/.turkit.yaml`.

If both global files exist, prefer `~/.config/turkit/config.yaml`. If the host
cannot read a global file, skip it without failing.

## Config shape

```yaml
output:
  style: compact # compact | standard | full
  language: auto # auto | fr | en
  technical_terms: keep-english # keep-english | translate-when-natural
```

## Resolution order

1. An explicit language/style request in the current operator message wins.
2. Repo `.turkit.yaml -> output.*`.
3. Global config `output.*`.
4. The current conversation language.
5. English fallback.

Merge repo and global values per key: global `output` is the base, and repo
`output` overrides only the keys it defines. Do not copy global preferences into
repo config unless the repo needs to override them.

Invalid values are ignored. Mention the ignored value only if it would affect the
current answer.

## `style`

- `compact` (default): short, scan-first output.
- `standard`: normal detail for plans, handoffs, and explanations.
- `full`: expanded detail when the operator explicitly wants depth.

Style does not weaken required verification or safety guardrails.

## `language`

- `auto` (default): answer in the current conversation language.
- `fr`: answer operator-facing prose in French.
- `en`: answer operator-facing prose in English.

Machine-readable contracts keep their required keys exactly as specified. JSON keys,
CLI flags, file paths, API names, identifiers, package names, commit hashes, and error
messages are never translated.

## `technical_terms`

- `keep-english` (default): keep common development terms in English when translating
  them would reduce clarity.
- `translate-when-natural`: translate common prose terms when natural, but still keep
  exact code/tool terms unchanged.

Examples of terms to keep in English by default: `branch`, `commit`, `diff`,
`worktree`, `PR`, `build`, `typecheck`, `lint`, `runtime`, `package`, `hook`,
`boundary`, `provider`, `endpoint`, `DTO`, `API`, `config`.

When `language: fr` and `technical_terms: keep-english`, use French connective prose
and headings, but keep technical nouns/code terms in English where that is clearer.
