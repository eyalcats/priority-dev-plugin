---
description: Run the form-harvest agent team against a space-separated form list. Produces a reviewable git branch with proposed skill edits and a findings index.
argument-hint: FORM1 FORM2 [FORM3 ...]
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - mcp__priority-dev__websdk_form_action
  - Agent
---

# /harvest-forms

Orchestrates a form-harvest run: parallel Scouts (researcher agent in Mode 3, one per form) → sequential Curator (novelty + >=3-form frequency gates) → commit to a harvest branch for your review.

## Input

Space-separated form names from the user: `$ARGUMENTS`.

If empty: stop and print `/harvest-forms FORM1 FORM2 [FORM3 ...] — needs at least one form name`.

## Step 1 — Validate every form name

For each argument, call `websdk_form_action` on EFORM with:

```json
{ "op": "filter", "field": "ENAME", "value": "<FORM>" }
```

Then `getRows`. If zero rows come back for any form, STOP and report the unresolved names. Do not proceed.

## Step 2 — Create harvest branch

Compute a slug: lowercase form list, joined by `-`, truncated to 60 chars.

Compute the date: `$(date +%Y-%m-%d)` via Bash.

Branch name: `harvest/<date>-<slug>`.

Run:
```bash
git status --porcelain
```

If there are uncommitted changes on `main`, STOP and ask the user to commit or stash first.

Then:
```bash
git checkout main
git pull --ff-only
git checkout -b harvest/<date>-<slug>
```

## Step 3 — Spawn Scouts in parallel

For each validated form, invoke:

```
Agent(
  subagent_type: "researcher",
  description: "Harvest <FORM>",
  prompt: <JSON blob below>
)
```

Prompt JSON for each Scout:
```json
{
  "mode": "harvest",
  "form": "<FORM>",
  "harvestBranch": "harvest/<date>-<slug>",
  "skillRoot": "plugin/skills/priority-sdk/"
}
```

Make all Scout Agent calls **in a single message** with multiple tool uses so they run concurrently (as per the Agent tool docs).

## Step 4 — Resolve prior index paths

Use `Glob` to find prior harvest indices:

```
Glob({ pattern: "docs/solutions/harvests/*.md" })
```

Exclude `docs/solutions/harvests/README.md` from the result. Pass the rest to Curator.

## Step 5 — Invoke Curator

```
Agent(
  subagent_type: "curator",
  description: "Curate harvest findings",
  prompt: <JSON blob below>
)
```

Curator prompt JSON:
```json
{
  "scoutPackets": [ /* all Scout return values */ ],
  "harvestBranch": "harvest/<date>-<slug>",
  "priorIndexPaths": [ /* from Step 4 */ ],
  "skillRoot": "plugin/skills/priority-sdk/"
}
```

Wait for Curator to return. It returns `{ accepted, rejected, editedFiles, indexPath }`.

## Step 6 — Commit the harvest branch

```bash
git status --porcelain
```

If any changes:
```bash
git add .
git commit -m "harvest: <date> — <form-list> — <accepted> accepted, <rejected> rejected"
```

If no changes (Curator accepted zero findings): commit an empty marker:
```bash
git commit --allow-empty -m "harvest: <date> — <form-list> — 0 accepted, <rejected> rejected (no edits)"
```

## Step 7 — Report to user

Print exactly:
```
Harvest complete.
  Branch: harvest/<date>-<slug>
  Index:  <indexPath>
  Accepted: <N> findings across <K> files
  Rejected: <M> candidates
Next: git checkout harvest/<date>-<slug> && cat <indexPath>
Then: git diff main -- plugin/skills/priority-sdk
```

## Failure modes

- Any form unresolved in Step 1 → abort, list them, exit.
- `git status` dirty in Step 2 → abort, ask user.
- Bridge unreachable (Scout returns MCP connection error) → abort, tell user to check VSCode + priority-claude-bridge.
- Scout returns an error after bridge was reachable → continue with remaining Scouts; note failed form in the commit message.
- Curator returns zero accepted with zero rejected → still commit the empty marker so the run is visible.
