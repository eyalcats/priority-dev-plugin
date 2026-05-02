---
description: Consolidate the pending skill-improvement queue into a gap-analysis report, present it for approval, and commit approved findings atomically. Auto-runs an eval pass against deferred candidates unless --no-eval is passed.
argument-hint: [--no-eval]
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

## Step 3.5 — Eval pass for deferred candidates

Skip this step entirely if the user passed `--no-eval`.

Partition the queue into admit-eligible and deferred candidates:

```bash
node -e "
const q = require('./plugin/hooks/scripts/lib/pending-queue');
const { partitionForEval, deriveSandboxPrefix } = q;
const queue = q.readQueue('plugin/skills/priority-sdk/_pending.yaml');
const { deferred } = partitionForEval(queue);
const tasks = deferred.map(c => ({ id: c.id, sandboxPrefix: deriveSandboxPrefix(c.id), pattern_signature: c.pattern_signature }));
process.stdout.write(JSON.stringify({ deferredCount: tasks.length, tasks, deferred }, null, 2));
" > .eval-pass-tasks.json
cat .eval-pass-tasks.json | head -5
```

If `deferredCount` is `0`, print `no deferred candidates; skipping eval pass` and continue to Step 4 with `verdicts: []`.

Otherwise, dispatch one `eval-investigator` agent per deferred candidate. Send all spawn calls in a SINGLE assistant message (multiple Agent tool-uses in one block) so they run in parallel.

For each `task` in `.eval-pass-tasks.json` `tasks` array, spawn:

```
Agent(
  subagent_type: "eval-investigator",
  description: "Eval candidate <pattern_signature truncated to 40 chars>",
  prompt: <input envelope JSON below>
)
```

Input envelope (one per investigator — substitute the candidate-specific fields):

```json
{
  "candidate": <full candidate object from .eval-pass-tasks.json `deferred` array>,
  "sandboxPrefix": "<from task.sandboxPrefix>",
  "skillRoot": "plugin/skills/priority-sdk/",
  "policy": {
    "allowSandboxWrites": true,
    "maxProbeSeconds": 90,
    "cleanupRequired": true,
    "demoServerOnly": true
  }
}
```

Each investigator returns a verdict envelope (fenced JSON block in its final message). Extract each envelope's JSON from the agent's response and assemble them into a single array. **Use the `Write` tool to materialize `.eval-pass-verdicts.json` with that array** — do not use shell echo (no env-var passing, no PowerShell-vs-Bash quoting traps).

Then validate by re-reading the file:

```bash
node -e "
const fs = require('node:fs');
const { validateVerdict } = require('./plugin/hooks/scripts/lib/pending-queue');
const verdicts = JSON.parse(fs.readFileSync('.eval-pass-verdicts.json', 'utf8'));
const reports = verdicts.map(v => ({ id: v.candidate_id, ...validateVerdict(v) }));
const valid = verdicts.filter((_, i) => reports[i].ok);
const invalid = reports.filter(r => !r.ok);
fs.writeFileSync('.eval-pass-verdicts.json', JSON.stringify(valid, null, 2));
process.stdout.write(JSON.stringify({ kept: valid.length, discarded: invalid.length, errors: invalid }, null, 2));
"
```

If the report's `discarded` count is non-zero, print the error list in-chat ("Discarded N malformed verdict envelope(s): …") so the user can see which candidates lost their eval evidence. Those candidates will fall through to the source-count gate (likely staying deferred).

Pass the contents of `.eval-pass-verdicts.json` to Step 4 in the curator's prompt JSON via the `verdicts` field.

### Cleanup (runs regardless of Step 4 outcome)

After Step 4 — whether the curator succeeded, partially-succeeded, or errored — delete the temp files unconditionally:

```bash
rm -f .eval-pass-tasks.json .eval-pass-verdicts.json
```

If you abort Step 4 due to an error, run the same cleanup before exiting `/review-pending`. Leaving these files in the repo root is forbidden — they would otherwise be picked up by the next `git status` and risk being accidentally committed.

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
  "skillRoot": "plugin/skills/priority-sdk/",
  "verdicts": <contents of .eval-pass-verdicts.json, or [] if --no-eval was passed or deferredCount was 0>
}
```

## Step 5 — Present for approval

Read the gap-analysis report and print it in-chat.

If the curator's manifest has `requires_orphan_ack: true`, print the ⚠ Orphans block FIRST and ask:

> "Sandbox orphans detected — the eval team could not delete these test entities:
> <list of orphans with their candidate ids>
> Acknowledge that you will manually clean these up? (yes/no)"

Wait for `yes`. If `no`, abort and tell the user to run cleanup manually before re-running `/review-pending`.

Then prompt for approval of admitted findings with the same affordances as `/gap-scan` Step 6: `approve all`, `reject all`, `approve 1 2 5; skip 3 4`, `approve all except 3`.

Auto-rejected findings (eval-disproven) do NOT require human approval — they are committed by the curator-apply step automatically. Just inform the user how many were auto-rejected.

## Step 6 — Invoke Curator in apply mode (same as /gap-scan Step 8)

## Step 7 — Report to user (same as /gap-scan Step 9)

## Failure modes

Same as /gap-scan Steps 6–9 failure modes.

### Eval pass failures

- All investigators return `inconclusive` → curator falls back to deterministic admission gate; report flags eval pass as failed; pipeline continues.
- One investigator times out (>90s) → that candidate stays deferred; other verdicts proceed normally.
- Investigator returns malformed verdict envelope → orchestrator discards, treats as missing verdict; logged in-chat.
- Bridge unreachable mid-eval → all in-flight investigators return `inconclusive`/`probe-design-failed`; eval pass is effectively a no-op.
- Demo-server check fails → all investigators return `inconclusive`/`probe-design-failed`; surface this prominently.
