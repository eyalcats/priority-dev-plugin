---
description: One-shot bootstrap scan of the official Priority SDK PDF against the priority-sdk skill. Surfaces missing topics, contradictions, and version-tagged features. Stages findings into _pending.yaml for /review-pending.
argument-hint: (no arguments)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
---

# /handbook-scan

Orchestrates a handbook gap-scan run: pre-flight on the source files → chunk the `.txt` by chapter → spawn parallel handbook-scout agents (one per chapter) → invoke gap-curator → present report → user approves → atomic commits to `main`.

No arguments. One-shot bootstrap.

## Step 0 — Pre-flight

Confirm both source files exist:

```bash
PDF="/c/Users/eyal.katz/OneDrive - Priority Software LTD/Projects/PrioritySDK-PrivateDev/Docs/PrioritySDK.pdf"
TXT="/c/Users/eyal.katz/OneDrive - Priority Software LTD/Projects/PrioritySDK-PrivateDev/Docs/PrioritySDK.txt"
ls "$PDF" "$TXT"
```

If either is missing, STOP and print:
```
/handbook-scan — required source file not found.
  PDF: <path>
  TXT: <path>
Re-extract the .txt from the PDF, or update the paths in plugin/commands/handbook-scan.md.
```

Compare mtimes:

```bash
PDF_MTIME=$(stat -c %Y "$PDF" 2>/dev/null || stat -f %m "$PDF")
TXT_MTIME=$(stat -c %Y "$TXT" 2>/dev/null || stat -f %m "$TXT")
if [ "$PDF_MTIME" -gt "$TXT_MTIME" ]; then echo "WARN: PDF is newer than TXT (PDF=$PDF_MTIME, TXT=$TXT_MTIME)"; fi
```

If the warn line prints, ask the user:
```
PrioritySDK.pdf is newer than PrioritySDK.txt — the .txt may be stale.
  Proceed with stale .txt, or abort to re-extract first?
  Reply: "proceed" or "abort".
```

If the user replies "abort", stop. If "proceed", continue.

## Step 1 — Confirm clean working tree on `main`

```bash
cd "/c/Users/eyal.katz/OneDrive - Priority Software LTD/Projects/priority-dev"
git status --porcelain
```

If non-empty, STOP and ask the user to commit or stash first.

```bash
git checkout main
git pull --ff-only
```

## Step 2 — Build the chapter chunk plan

Locate chapter headings in the `.txt`:

```bash
grep -nE "^(Tables|Forms|Form Triggers|Procedures|Reports|Documents|Interfaces|Optimization|Dashboards|Click2Sign|WSCLIENT|Web SDK|Cloud|Release Notes and Change Log)$" "$TXT"
```

Filter noise: when two matches for the same chapter name are within 300 lines of each other, take the later one (catches TOC entries vs real chapter starts). Build the chunk plan as an array of `{chapter, startLine, endLine, pageStart, pageEnd}`.

For `endLine`: the line just before the next chapter heading (or end-of-file for the last chapter).

For `pageStart` / `pageEnd`: grep `^Priority SDK\s+Page N` in the slice and take the smallest/largest `N`:

```bash
grep -nE "^Priority SDK[[:space:]]+Page [0-9]+" "$TXT" | awk -F: 'BEGIN{first=99999;last=0} { match($0, /Page ([0-9]+)/, a); n=a[1]+0; if($1>=START && $1<=END) { if(n<first) first=n; if(n>last) last=n } } END { print first, last }' START=<startLine> END=<endLine>
```

If any chunk exceeds 2,500 lines, sub-split on the next-strongest internal heading (next `^[A-Z][a-zA-Z ]+$` line near the median). Add the sub-split as a separate plan entry.

If the chunk plan is empty (zero chapter headings matched), STOP and print the raw grep output for the user to inspect — the .txt may be malformed.

## Step 3 — Spawn handbook-scout agents in parallel

For each chunk in the plan, invoke:

```
Agent(
  subagent_type: "researcher",
  description: "Handbook scout: <chapter>",
  prompt: <JSON envelope below>
)
```

JSON envelope per chunk:
```json
{
  "mode": "handbook-scout",
  "chapter": "<name>",
  "txtPath": "C:/Users/eyal.katz/OneDrive - Priority Software LTD/Projects/PrioritySDK-PrivateDev/Docs/PrioritySDK.txt",
  "startLine": <N>,
  "endLine": <N>,
  "pageStart": <N>,
  "pageEnd": <N>,
  "skillRoot": "plugin/skills/priority-sdk/",
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml",
  "isReleaseNotes": <true if chapter == "Release Notes and Change Log", else false>
}
```

Make all Agent calls **in a single message** with multiple tool uses so they run concurrently. Wait for all scouts to return.

If any scout returns an `errors` array with `read-failed`, note the failed chapter but continue with the rest. If a scout returns `truncated-at-30`, note it for the run summary.

## Step 4 — Invoke gap-curator (consolidate)

```
Agent(
  subagent_type: "curator",
  description: "Consolidate handbook-scan findings",
  prompt: <JSON envelope below>
)
```

JSON envelope:
```json
{
  "mode": "gap-curator",
  "trigger": "on-demand",
  "slug": "handbook-scan",
  "pendingPath": "plugin/skills/priority-sdk/_pending.yaml",
  "rejectedLogPath": "plugin/skills/priority-sdk/_rejected.log",
  "reportDir": "docs/solutions/harvests/",
  "skillRoot": "plugin/skills/priority-sdk/"
}
```

(Curator prefixes the report filename with `<date>` automatically — the slug should not duplicate it.)

Curator returns `{ reportPath, admitted, deferred, totals }` (and possibly `auto_rejected`, `requires_orphan_ack` — both expected to be empty/false for handbook scans since no eval team runs).

If `totals.admitted == 0`, print:
```
/handbook-scan complete — no new gaps found from the handbook.
  Scouts ran: <N> chapters
  Findings staged: <total>
  Findings deferred: <K>
```
and exit cleanly. Do not commit.

## Step 5 — Present report for approval

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

## Step 6 — Parse the approval

From the user's response, compute:
- `approved_ids` — list of candidate ids the user approved
- `rejected_ids` — list of candidate ids the user rejected (explicit skip OR "reject all")
- `rejection_reasons` — map of id → reason (ask the user one reason per rejected id if not provided)

Findings not in either list stay in `_pending.yaml`.

## Step 7 — Invoke gap-curator (apply)

```
Agent(
  subagent_type: "curator",
  description: "Apply approved handbook findings",
  prompt: <JSON envelope below>
)
```

JSON envelope:
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

## Step 8 — Report to user

Print exactly:
```
/handbook-scan complete.
  Chapters scanned: <N>
  Report:           <reportPath>
  Committed:        <N> findings on main (git log -<N>)
  Rejected:         <M> findings (logged to _rejected.log)
  Remaining queue:  <K>
Next: git log --oneline -<N>  to see the commits
      git revert <sha>         to undo one
```

## Failure modes

| Failure | Behaviour |
|---|---|
| `.txt` not found | Abort with the path message, exit |
| `.pdf` not found | Abort with the path message, exit |
| PDF newer than .txt | Warn + ask user to proceed/abort |
| Working tree dirty on main | Abort, ask user to commit or stash |
| Chapter chunk plan empty | Abort with raw grep output for inspection |
| Scout returns `read-failed` | Note in run summary, continue with remaining scouts |
| Scout returns `truncated-at-30` | Note in run summary, the chapter likely needs sub-splitting on next run |
| Curator returns 0 admitted | Print "no new gaps found" and exit cleanly (no commits) |
| User approval parse fails | Re-prompt with the clearer format above |
