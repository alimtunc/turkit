---
name: preview-test
description: Use when the operator wants functional testing of a deployed PR preview, preview URL, branch preview, or review app before merge/release, especially when results should feed an auto-fix loop.
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(command -v:*), Bash(gh pr view:*), Bash(glab mr view:*), Read, Grep, Glob
---

# Preview Test

Functionally test a deployed PR preview without assuming the host, deployment platform, app stack, tracker, or domain.

## References

- [`references/preview-detection.md`](references/preview-detection.md) — URL, PR number, readiness, vision, and verdict contract.
- [`references/vcs-host-detection.md`](references/vcs-host-detection.md) — host CLI fallback pattern.

## Workflow

1. **Resolve inputs.**
   - Read `.turkit.yaml` if present.
   - Resolve the preview URL via `references/preview-detection.md`.
   - If the URL cannot be resolved, ask the operator for a URL or permission to skip. If skipped, output `status: "FAIL"` with a finding explaining that no preview URL was available.

2. **Resolve automation path.**
   - Prefer an available browser/Playwright MCP or host-native browser tool.
   - If no browser automation tool is available, ask the operator to provide manual observations or skip. Do not invent results.
   - Never require Claude-specific, Codex-specific, Cursor-specific, or Gemini-specific tooling for correctness.

3. **Open the preview.**
   - Navigate to the resolved URL.
   - Apply `preview.wait_for` per `references/preview-detection.md` when configured.
   - If the preview is not reachable or readiness never appears, return `FAIL` with evidence.

4. **Run the requested scenario.**
   - Use the operator's prompt, PR description, ticket text, or changed surface to identify the flow to test.
   - Exercise the smallest user-visible path that proves the feature works.
   - Capture relevant console/runtime/network errors if the browser tool exposes them.
   - Do not assume authentication, seed data, tenant, locale, or environment names. Ask when needed.

5. **Analyze visual state.**
   - Apply `preview.vision` per `references/preview-detection.md`.
   - If screenshot/vision is unavailable, continue with functional evidence and report the residual risk.
   - Treat visual issues as findings only when tied to the requested behavior or obvious broken UI.

6. **Return the structured verdict.**
   End the response with a JSON object matching the contract:

   ```json
   {
     "status": "PASS",
     "findings": []
   }
   ```

## Guardrails

- No hardcoded preview hostnames, domains, tenants, stacks, or package managers.
- No project-specific assumptions.
- Do not run local build/test commands unless the operator explicitly asks; this skill tests the deployed preview.
- Do not mark `PASS` if the preview could not be opened, the requested flow was not exercised, or required visual analysis was unavailable and essential.
- Use `FAIL` with a clear configuration/tooling finding when the operator chooses not to provide a URL or manual evidence.
- Respond in the conversation's language by default, but keep the final JSON keys in English.
