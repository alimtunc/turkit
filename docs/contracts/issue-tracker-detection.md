# Issue Tracker Detection Contract

Skills in `turkit` that interact with issue trackers (fetch an issue, update its status) MUST follow this detection/fallback strategy instead of hardcoding a specific MCP.

## Detection order

1. **MCP tool scan.** Inspect the active MCP tool list. Match tool names against these patterns (case-insensitive, substring):
   - Fetch issue: contains `get_issue`, `issue_get`, or `search_issue`.
   - Update issue: contains `save_issue`, `update_issue`, or `issue_update`.
   - List statuses: contains `list_issue_statuses`, `list_statuses`, or `issue_states`.

   If matches are found, prefer them in this order: Linear > Jira > GitHub Issues > any other. (Documented for reproducibility; skills do not need to implement this priority if only one match exists.)

2. **Branch-name fallback.** If no MCP matches, extract the ticket ID from the current branch name using this regex: `^([a-z]+)-(\d+)(?:-.*)?$` (case-insensitive). Examples:
   - `sup-80-launch-queue` → `SUP-80`
   - `PROJ-123-add-login` → `PROJ-123`
   - `main`, `feat/xyz` → no ticket

3. **No ticket.** If neither the MCP nor the branch name yields a ticket, the skill operates without one. It must state this explicitly to the operator and proceed (or abort, depending on the skill).

## Status update behavior

- If an MCP tool is available: call it to update the status (e.g., "In Progress", "Done").
- If only a branch-name ticket is known: skip status updates silently. Do not error.
- Skills MUST NOT invent a status value. Use exactly the values the tracker exposes (fetched via list-statuses if needed).

## Configuration

No configuration required. Detection is automatic. The operator can pre-empt detection by explicitly passing a ticket ID as an argument to the skill.

## Known-compatible MCPs (updated as tested)

- Linear MCP (Jesse's `@linear/mcp-server` and similar) — tested ✅
- Others — untested, may work if they match the name patterns.
