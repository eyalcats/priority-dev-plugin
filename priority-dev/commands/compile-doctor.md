---
description: Diagnose and fix Priority compile errors. Spawns compile-doctor subagents (one per entity in parallel), aggregates their diagnosis, and awaits your per-fix approval before applying changes.
argument-hint: ENTITY1 [ENTITY2 ENTITY3 ...]
allowed-tools:
  - Bash
  - Read
  - mcp__priority-dev__websdk_form_action
  - mcp__priority-dev__run_inline_sqli
  - Agent
---

# /compile-doctor

Orchestrates a compile-triage run: parallel compile-doctor Scouts (one per entity) → aggregate diagnosis report → you approve fixes conversationally → Scouts re-engage to apply approved fixes and recompile.

Nothing auto-commits. Nothing auto-applies unless you say so.

## Input

Space-separated entity names from the user: `$ARGUMENTS`.

If empty: stop and print `/compile-doctor ENTITY1 [ENTITY2 ...] — needs at least one entity name`.

## Step 1 — Validate every entity name

For each argument, resolve via `run_inline_sqli`:

```sql
SELECT ENAME, TYPE FROM EXEC WHERE ENAME = '<entity>' FORMAT;
```

If zero rows for any entity, STOP and report the unresolved names. Do not proceed.

## Step 2 — Spawn Scouts in parallel (dry-run)

For each validated entity, invoke `compile-doctor` in dry-run mode:

```
Agent(
  subagent_type: "compile-doctor",
  description: "Diagnose <ENTITY>",
  prompt: <JSON blob below>
)
```

Prompt JSON (one per entity):
```json
{
  "mode": "compile-doctor",
  "entity": "<ENTITY>",
  "apply": false,
  "maxIterations": 1,
  "notes": "<optional — pass through any context the user gave>"
}
```

Make all Agent calls **in a single message** with multiple tool uses so they run concurrently. Wait for all Scouts to return.

## Step 3 — Aggregate and print the report

Combine each Scout's `{status, entity, errors, batchDivergenceNote}` into a unified table. For each error, show:

| # | Entity | Error path | Class | Root cause | Proposed fix | Blast radius | Reversible |
|---|---|---|---|---|---|---|---|

Then print the batch-divergence footnote (if any): if a Scout reported that the invoker-provided errors couldn't be reproduced in single compile, show that separately so the user knows the automated loop cannot auto-fix batch-only errors.

## Step 4 — Await per-fix approval

Print:

```
---
Approval:
  Reply with a comma-separated list of error numbers to approve, e.g.:
    "approve 1 2 5"           — apply those fixes
    "approve all"             — apply every proposed fix
    "approve all except 3"    — apply all but the listed ids
    "skip"                    — do nothing; exit cleanly

  Fixes with blastRadius == "system-wide" or reversibility == "irreversible-without-backup"
  will be flagged in the table — consider carefully before approving.
```

Wait for the user's response. Parse into `approved_error_ids`.

## Step 5 — Apply approved fixes

For each entity with at least one approved error, spawn `compile-doctor` again with `apply: true` and a scoped list of the approved error ids. The agent applies each fix (per-entity), recompiles after each, and loops until clean or stalled.

Parallelism: spawn one agent per entity, one message. Do NOT spawn multiple agents for the same entity.

## Step 6 — Report to user

Print exactly:

```
Compile-doctor run complete.
  Entities: <list>
  Fixed:     <N> errors cleared
  Stalled:   <M> entities still have errors after max iterations
  Abandoned: <K> errors the user skipped

Next steps:
  - Re-run "Prepare all forms" in Priority if the user sees batch-only errors
  - git diff     (no files edited; all changes went straight to Priority via bridge)
  - /compile-doctor <STILL_BROKEN_ENTITY>   to continue triage
```

Unlike `/gap-scan`, this command does NOT commit to git — all changes land in Priority metadata via the bridge. The skill-improvement loop (`/review-pending`) can capture learnings after the run.

## Failure modes

- Any entity unresolved in Step 1 → abort, list them, exit.
- Bridge unreachable → Scouts will fail fast; tell user to check VSCode + priority-claude-bridge.
- Scout returns `status: "not-found"` → skip that entity in aggregation; note in final report.
- Scout returns `status: "stalled"` → surface it, ask the user how to proceed (typically: inspect the form by hand).
- User approval parse fails → ask again with a clearer prompt.
- A Scout reports batch-divergence (user-reported errors can't be reproduced in single compile) → do NOT attempt to auto-fix; surface the divergence and ask the user to re-run Priority's Prepare All Forms to confirm the errors are still present with the current metadata state.

## Related

- Agent: `plugin/agents/compile-doctor.md`
- Reference: `plugin/skills/priority-sdk/references/compile-debugging.md`
