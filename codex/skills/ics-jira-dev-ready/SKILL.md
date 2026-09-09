---
name: ics-jira-dev-ready
description: Find my assigned Dev Ready Jira tickets in the active QB sprint using Atlassian MCP, with clickable links and ordering by product priority or complexity. Use when choosing what to work on next or asking for my sprint queue.
---

# ICS Jira Dev Ready

Return a current, read-only work queue. Default to product priority; support easiest-first or hardest-first when requested. Listing or recommending work does not authorise ticket edits or starting implementation.

## Personal defaults

- Site: `https://coterieholdings.atlassian.net`
- Project: `QB`; board: `1`.
- Owner account from the user's board URL: `5aacdfe733719f2a5016620e`.
- Status: exactly `Dev Ready`.
- Board: `https://coterieholdings.atlassian.net/jira/software/projects/QB/boards/1`.

Apply explicit user overrides. The supplied website filter also included PR Review, Dev In Progress and To Do; those are outside this queue unless requested.

## Fetch the queue

1. Use Atlassian MCP. Resolve the site's cloudId once with `getAccessibleAtlassianResources` when not already known. Pass cloudId on every site-scoped call. Fetch `atlassianUserInfo` once: use `currentUser()` when it matches the owner above; otherwise use the explicit owner account and disclose the mismatch. Resolve an explicitly requested different assignee instead of silently substituting the connected account.
2. Discover the read operations for board configuration and active board sprints. With the current MCP these are `getJiraBoardConfig` and `listJiraBoardSprints`, called through `executeRead` with top-level cloudId and flat `inputs`. Discover operations before executing them in a new session; use the returned schemas.
3. Read board configuration for its saved filter, estimation field and rank field. List sprints with `boardId: 1`, `state: "active"`; follow offset pagination. Use all active sprint IDs on this board, naming each if there are several. Read their goals for current product-ordering guidance. Resolve these afresh on each invocation; never persist the current sprint ID in this skill. If there is no active sprint, report that and stop.
4. Call the primary `searchJiraIssuesUsingJql` tool with the resolved board filter and sprint IDs. This preserves board scope and lets Jira sort the results. Substitute actual values in this template:

   ```jql
   filter = <board-filter-id>
   AND project = QB
   AND assignee = currentUser()
   AND status = "Dev Ready"
   AND sprint IN (<active-sprint-ids>)
   ORDER BY priority DESC, Rank ASC
   ```

   Use `assignee = "<account-id>"` if needed. `openSprints()` alone is not board-specific. Keep the saved filter condition because a sprint can contain issues outside this board's filter. If board metadata is unavailable, report the limitation before using a project-scoped `sprint IN openSprints()` fallback; label that result as unverified against board 1.
5. Fetch summary, description, status, assignee, priority, issue type, labels, parent, issue links, sprint membership and the board's estimation/rank fields. Use `view: "evidence"` for custom fields, or explicit field IDs from live metadata; explicit `fields` limits what is returned. This MCP maps custom field values under `fields.customFields` by human label, often as `{id, value}`. A missing value means unestimated, including when a field object exists without `value`.
6. Follow `nextPageToken` until `isLast` is true and deduplicate by issue key. Count the collected results. If pagination fails, label the list partial. If no issues match, report the exact scope without widening status, assignee or sprint.

On a tool error, retry once with corrected input. If an operation is missing, discover again with different keywords. If MCP access remains unavailable, provide the reproducible JQL and state that live results could not be verified.

## Choose the order

**Product priority (default):** Apply explicit current sprint-goal or product ordering when it can be grounded in ticket fields/descriptions; state that rule. Otherwise use Jira priority descending, then board Rank ascending. Retain Jira's returned order for ties instead of alphabetically sorting priority labels. Read phase from labels or explicit scope; an absent phase is unknown. Board rank and Jira priority are ordering signals, not proof of a product owner's decision. Ticket descriptions define scope and acceptance criteria; comments are discussion only. Read linked Confluence specifications when needed to resolve a material prioritisation ambiguity.

**Complexity:** Default to easiest-first; reverse known estimates for hardest-first. Use the board's estimate as an effort proxy and label its unit (e.g. story points, not days). Tie-break using product order. Put unestimated tickets after estimated ones and retain their product order. Do not mix story points and time estimates on one numeric scale. If asked to estimate missing complexity, read descriptions/acceptance criteria and relevant dependencies, assign provisional Low/Medium/High with a short reason, and distinguish these judgements from recorded Jira estimates. Do not infer effort from priority or title alone.

**Both:** Show the product-ordered table once, then a short easiest-first sequence of ticket links with estimates. Keep the two ordering criteria visible rather than inventing a blended score.

For recommendations, flag explicit unresolved prerequisites and unclear acceptance criteria in the matching ticket's row. Check linked issue status before claiming a dependency is still open. Preserve link direction: “blocks” is not “is blocked by”. Read descriptions for whether a dependency actually prevents starting, or permits parallel work. Keep matching tickets in the list even when blocked or their description claims delivery; surface that inconsistency. Recommend a next ticket with enough scope to start, explaining any departure from product order.

## Return

Lead with the number of matches, sprint name(s), assignee and ordering rule. Use a compact table:

| Order | Ticket | Summary | Jira priority | Estimate / complexity | Reason / dependency |
|---|---|---|---|---|---|

Link every key as `[QB-123](https://coterieholdings.atlassian.net/browse/QB-123)`. Include a filtered Jira search link using `https://coterieholdings.atlassian.net/issues/?jql=` plus the URL-encoded exact JQL. This link reproduces the selected sprint; the next skill invocation resolves the then-active sprint. Explain when recommendation or complexity order differs from the link's Jira sort. Include the board link for board navigation. Finish with one concise next-ticket recommendation when requested or useful. Write in plain British English.

Example invocations:

- `$ics-jira-dev-ready` — my queue by product priority.
- `$ics-jira-dev-ready easiest first` — smallest recorded estimates first.
- `$ics-jira-dev-ready hardest first` — largest recorded estimates first.
- `$ics-jira-dev-ready show both orders` — product queue and easiest-first sequence.
