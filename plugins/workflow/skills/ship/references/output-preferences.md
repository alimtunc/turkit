# Output Preferences Contract

Skills that emit operator-facing prose MAY read `.turkit.yaml -> output`.
All fields are optional and must degrade cleanly when absent.

## `.turkit.yaml` shape

```yaml
output:
  style: compact # compact | standard | full
  language: auto # auto | fr | en
  technical_terms: keep-english # keep-english | translate-when-natural
```

## Resolution order

1. An explicit language/style request in the current operator message wins.
2. `.turkit.yaml -> output.*`
3. The current conversation language.
4. English fallback.

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
