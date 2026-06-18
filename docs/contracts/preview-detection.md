# Preview Detection Contract

Skills that test deployed PR previews MUST resolve the preview URL and visual mode through this contract instead of hardcoding a host, domain, tracker, stack, or deployment platform.

## Configuration

All keys are optional:

```yaml
preview:
  # URL template for a deployed PR preview. Supports {pr_number}.
  url_template: "pr-{pr_number}.beta.example.com"
  # Optional selector or text that indicates the preview is ready.
  wait_for: ""
  # Visual analysis mode: auto, claude, gemini, or off.
  vision: auto
```

If a configured URL has no `http://` or `https://` scheme, treat it as `https://<value>`.

## Resolution Order

1. **Explicit URL from operator** — if the operator passed or pasted a URL, use it and skip template resolution.

2. **`.turkit.yaml → preview.url_template`** — if present:
   - If the template contains `{pr_number}`, resolve the PR number first.
   - Substitute `{pr_number}` literally.
   - Normalize the scheme as described above.

3. **No template** — do not assume a host. Ask the operator for a preview URL. If the operator wants to skip preview testing, return `FAIL` with a finding explaining that no preview URL was available.

## PR Number Resolution

Resolve `{pr_number}` in this order:

1. **Explicit operator argument** — a passed PR/MR number wins.
2. **Current branch PR via host CLI**:
   - GitHub CLI when available: `gh pr view --json number --jq .number`
   - GitLab CLI when available: `glab mr view --output json` and read the merge request IID/number if present.
3. **Branch-name fallback** — extract only an unambiguous `pr-<digits>` / `pr_<digits>` segment from the current branch name.
4. **Unresolved** — ask the operator for the PR number or full URL. Do not guess.

## Readiness

`.turkit.yaml → preview.wait_for` is optional. If set, treat it as:

- a selector when the active browser/Playwright tool can wait on selectors;
- otherwise text to look for in the rendered page;
- otherwise a human-readable readiness note to report before testing.

If unset, wait for the page's normal load-ready signal when the host browser tool supports it.

## Vision Mode

`.turkit.yaml → preview.vision` accepts:

- `auto` — use an available host-native vision/screenshot analysis path if present; otherwise continue without visual analysis.
- `claude` — use Claude vision only if available; otherwise report visual analysis skipped.
- `gemini` — use Gemini vision only if available; otherwise report visual analysis skipped.
- `off` — do not run visual analysis.

Missing vision support is not a test failure by itself. It is a residual risk unless visual verification was essential to the operator's requested scenario.

## Output Contract

Preview-testing skills MUST end with a machine-readable JSON object:

```json
{
  "status": "PASS",
  "findings": []
}
```

Allowed `status` values are `PASS` and `FAIL`.

Each finding should include:

```json
{
  "severity": "P0|P1|P2",
  "title": "Short finding",
  "evidence": "URL, step, screenshot observation, or console/network detail",
  "suggested_fix": "Concrete next action"
}
```

Use `FAIL` for functional blockers, broken required flows, console/runtime errors that affect the scenario, visual regressions that block the requested behavior, or when the preview test was skipped because no URL/browser automation path was available after fallback.
