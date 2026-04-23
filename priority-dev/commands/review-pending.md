---
description: Consolidate the pending skill-improvement queue into a gap-analysis report, present it for approval, and commit approved findings atomically.
argument-hint: (no arguments)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Agent
---

# /review-pending

On-demand consolidation of `plugin/skills/priority-sdk/_pending.yaml`. Same shape as `/gap-scan` steps 5–9, without the Scout phase (the queue is already populated by prior gap-scans and/or the SessionEnd learning loop).

## Step 1 — Check the queue

```bash
grep -c "^  - id:" plugin/skills/priority-sdk/_pending.yaml || echo 0
```

If zero, print `queue empty; nothing to review` and exit.

## Step 2 — Ensure clean working tree on main

```bash
git status --porcelain
```

If dirty, STOP and ask the user to commit or stash first. Then:

```bash
git checkout main
git pull --ff-only
```

## Step 3 — Merge user-local queue (for cross-repo sessions)

If `~/.claude/priority-dev-pending.yaml` exists and has candidates, merge it into the project queue:

```bash
node -e "const q = require('./plugin/hooks/scripts/lib/pending-queue'); const n = q.mergeUserLocal('plugin/skills/priority-sdk/_pending.yaml', require('os').homedir() + '/.claude/priority-dev-pending.yaml'); console.log('merged ' + n + ' entries from user-local queue');"
```

## Step 4 — Invoke Curator in consolidate mode

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
  "trigger": "on-demand",
  "slug": "review-$(date -u +%Y-%m-%d)",
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml",
  "rejectedLogPath": "plugin/skills/priority-sdk/_rejected.log",
  "reportDir": "docs/solutions/harvests/",
  "skillRoot": "plugin/skills/priority-sdk/"
}
```

## Step 5 — Present for approval (same as /gap-scan Step 6)

Read the report, print in-chat, prompt for approval with the same affordances: `approve all`, `reject all`, `approve 1 2 5; skip 3 4`, `approve all except 3`.

## Step 6 — Invoke Curator in apply mode (same as /gap-scan Step 8)

## Step 7 — Report to user (same as /gap-scan Step 9)

## Failure modes

Same as /gap-scan Steps 6–9 failure modes.
