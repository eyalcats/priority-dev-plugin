---
description: Run a gap scan against existing Priority entities. Surfaces patterns the skill doesn't document, stages them for approval, and commits approved findings atomically.
argument-hint: ENTITY1 ENTITY2 [ENTITY3 ...]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - mcp__priority-dev__websdk_form_action
  - mcp__priority-dev__run_inline_sqli
  - Agent
---

# /gap-scan

Orchestrates a gap-scan run: parallel Scouts (researcher agent in Mode 4 gap-scout, one per entity) → Curator (gap-curator mode) produces a gap-analysis report → you approve conversationally → approved findings commit atomically to `main`.

No review branch. Nothing auto-commits without your approval. Additive-only skill edits.

## Input

Space-separated entity names from the user: `$ARGUMENTS`.

If empty: stop and print `/gap-scan ENTITY1 ENTITY2 [...] — needs at least one entity name`.

## Step 1 — Validate every entity name

For each argument, resolve via `run_inline_sqli`:

```sql
SELECT ENAME, ETYPE FROM EXEC WHERE ENAME = '<entity>' FORMAT;
```

If zero rows for any entity, STOP and report the unresolved names. Do not proceed.

Store the `ETYPE` map for use in the report slug and summary.

## Step 2 — Ensure clean working tree on main

```bash
git status --porcelain
```

If there are uncommitted changes, STOP and ask the user to commit or stash first. Run only from `main`:

```bash
git checkout main
git pull --ff-only
```

## Step 3 — Spawn Scouts in parallel

For each validated entity, invoke:

```
Agent(
  subagent_type: "researcher",
  description: "Gap-scan <ENTITY>",
  prompt: <JSON blob below>
)
```

Prompt JSON:
```json
{
  "mode": "gap-scout",
  "entity": "<ENTITY>",
  "skillRoot": "plugin/skills/priority-sdk/",
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml"
}
```

Make all Scout Agent calls **in a single message** with multiple tool uses so they run concurrently. Wait for all Scouts to return.

## Step 4 — Compute the slug

```bash
slug=$(echo "$ARGUMENTS" | tr '[:upper:] ' '[:lower:]-' | cut -c1-60)
date=$(date -u +%Y-%m-%d)
```

## Step 5 — Invoke Curator in consolidate mode

```
Agent(
  subagent_type: "curator",
  description: "Consolidate pending queue",
  prompt: <JSON blob below>
)
```

Prompt JSON:
```json
{
  "mode": "gap-curator",
  "trigger": "bootstrap",
  "slug": "<slug>",
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml",
  "rejectedLogPath": "plugin/skills/priority-sdk/_rejected.log",
  "reportDir": "docs/solutions/harvests/",
  "skillRoot": "plugin/skills/priority-sdk/"
}
```

Curator returns `{ reportPath, admitted, deferred, totals }`.

## Step 6 — Present the report for approval

Read the report at `reportPath`. Print it in-chat verbatim. Then print:

```
---
Approval:
  Reply with:
    "approve all"                 — commit every admitted finding
    "reject all"                  — drop every admitted finding (log reasons)
    "approve 1 2 5; skip 3 4"     — selective (use the ids shown in the report)
    "approve all except 3"        — approve, excluding specific ids
  Rejected items need a brief reason. I'll ask for one per rejected id.
```

Wait for the user's response.

## Step 7 — Parse the approval

From the user's response, compute:
- `approved_ids` — list of candidate ids the user approved
- `rejected_ids` — list of candidate ids the user rejected (explicit skip OR "reject all")
- `rejection_reasons` — map of id → reason (ask the user one reason per rejected id if not provided)

Findings not in either list stay in `_pending.yaml` (no action; e.g., deferred ones the user didn't touch).

## Step 8 — Invoke Curator in apply mode

```
Agent(
  subagent_type: "curator",
  description: "Apply approved findings",
  prompt: <JSON blob below>
)
```

Prompt JSON:
```json
{
  "mode": "gap-curator-apply",
  "approved_ids": [...],
  "rejected_ids": [...],
  "rejection_reasons": { "<id>": "<reason>", ... },
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml",
  "rejectedLogPath": "plugin/skills/priority-sdk/_rejected.log"
}
```

Curator returns `{ committed, rejected, remaining_in_queue, reportPath }`.

## Step 9 — Report to user

Print exactly:
```
Gap-scan complete.
  Entities: <list>
  Report:   <reportPath>
  Committed: <N> findings on main (git log -<N>)
  Rejected:  <M> findings (logged to _rejected.log)
  Remaining in queue: <K>
Next: git log --oneline -<N>  to see the commits
      git revert <sha>         to undo one
```

## Failure modes

- Any entity unresolved in Step 1 → abort, list them, exit.
- Dirty working tree in Step 2 → abort, ask user.
- Bridge unreachable (Scout returns MCP error) → abort, tell user to check VSCode + priority-claude-bridge.
- Scout returns an error after bridge was reachable → continue with remaining Scouts; note failed entity in the report.
- Curator returns empty queue in Step 5 → print "queue empty; nothing to scan or consolidate" and exit cleanly.
- User approval parse fails → ask again with a clearer prompt.
