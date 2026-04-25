# Compile Error Debugging — Priority Forms & Procedures

Diagnose and fix "Prepare Form" / "Prepare All Forms" errors. This reference focuses on the metadata-level root causes and the triage queries that surface them — it is the companion to `debugging.md` (which covers tracing/logging/revision flows).

Use this file when you see:

- `"<FORM>/<COLUMN>/EXPR", line 1: parse error at or near symbol ;`
- `משתנה <VAR>.$: בהפעלה <FORM>/<TRIGGER> אינו קיים כעמודה במסך` (variable not a form column)
- `במסך <FORM> אין עמודות מוצגות` (no displayed columns)
- `אין הודעה מספר N` (message N doesn't exist)
- `ערך קיים במסך 'X'` when trying to delete a form or trigger

---

## Reading compile error paths

Priority's compile errors encode location as a slash-separated path. The path element after the form name tells you which metadata table to query.

| Path shape | Source | Key tables |
|---|---|---|
| `FORM/COLUMN/EXPR` | Column expression body | `FORMCLMNSA`, `FORMCLMNSTEXT` |
| `FORM/COLUMN/COND` | Column condition body | `FORMCLMNSA` (filter by TYPE/DO) |
| `FORM/COLUMN/CHECK-FIELD` (etc.) | Column-level trigger | `FORMCLTRIG`, `FORMCLTRIGTEXT` |
| `FORM/TRIGGER` (no middle) | Form-level trigger | `FORMTRIG`, `FORMTRIGTEXT` |
| `FORM/ACTIVATION/STEP` | Direct activation proc step | `EXEC`+`TABLE=<form id>`, `PROG`, `PROGTEXT` |

The trailing element (`EXPR`, `POST-FIELD`, etc.) identifies **which text step** the parser was reading when it tripped. Two compile errors with the same path but different `line N` numbers refer to different lines of the same step text.

---

## Single-form compile vs batch "Prepare All Forms"

**Key divergence:** running `prepareForm` on one form often reports a DIFFERENT set of errors than Priority's bulk "Prepare All Forms" pass on the same form.

Observed cases:
- Bulk prepare surfaces `FORM/COLUMN/EXPR parse error at ;` on columns whose `FORMCLMNSA` row does not exist (no EXPR body to parse).
- Single-form prepare on the same form reports only an unrelated trigger error (e.g., a column-level POST-FIELD with an `#INCLUDE` to another form that references a column missing from the host form).

Hypotheses (not yet conclusively distinguished):
1. Bulk prepare processes forms in dependency order. Errors from an upstream form's compile may be **attributed to a downstream form** whose columns are touched during the upstream pass (e.g., imported columns resolving through a shared join).
2. Bulk prepare reads stale state from per-column compile artifacts on disk that individual `prepareForm` rewrites.
3. Bulk prepare uses a different batch-strictness level than single `prepareForm`.

**Practical rule:** if single-form compile is clean but bulk prepare reports an error on the same form, do not treat it as stale without evidence. Investigate the form's upstream dependencies (base-table joins, #INCLUDE targets, sub-level links, activation targets). See § "Chain-aware fix loop" below.

---

## Error class → root cause → triage query

### Class 1. Parse error at `;` on `<FORM>/<COL>/EXPR`

**Most common root cause:** `FCLMN.EXPRESSION='Y'` but the matching `FORMCLMNSA` row has empty `EXPR` (or missing). The parser reads an empty body, hits the implicit statement terminator `;` at line 1, errors.

**Triage query:**
```sql
SELECT C.NAME, C.EXPRESSION, A.EXPR
FROM   FORMCLMNS C
LEFT   OUTER FORMCLMNSA A ON (A.FORM = C.FORM AND A.NAME = C.NAME)
WHERE  C.FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
AND    C.EXPRESSION = 'Y'
AND    (A.EXPR = '' OR A.EXPR IS NULL)
FORMAT;
```

**Fix options (pick by intent):**
1. Column shouldn't be an expression → `FCLMN fieldUpdate EXPRESSION=''` + `saveRow`.
2. Column should be an expression but body was never filled → populate `FCLMNA.EXPR` via `EFORM → FCLMN → FCLMNA newRow/fieldUpdate/saveRow` (or for >56-char expressions via `FCLMNTEXT` continuation).

### Class 2. Variable `:$.COL` "not a form column"

**Message:** `משתנה COL.$: בהפעלה <FORM>/<TRIGGER> אינו קיים כעמודה במסך` (variable `.$.COL` in trigger is not a form column).

**Root cause:** the trigger body references `:$.COL`, but the form's FCLMN has no column named `COL`. Common sub-cases:

1. **Scratch/copy-paste code** — trigger was written for a different form and pasted here (e.g., `:$.ORD` on a form that doesn't have `ORD`).
2. **Column was removed** but the trigger was not updated.
3. **`#INCLUDE` from a donor form** pulls in code that references the donor's columns.

**Triage:**
```sql
/* Trigger body */
SELECT TEXTLINE, TEXTORD, TEXT FROM FORMTRIGTEXT
WHERE FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
AND TRIG = (SELECT TRIG FROM TRIGGERS WHERE TRIGNAME = '<TRIGGER>')
ORDER BY TEXTLINE, TEXTORD FORMAT;

/* Does the form actually have the referenced column? */
SELECT NAME FROM FORMCLMNS
WHERE FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
AND NAME = '<COL>' FORMAT;
```

**Fix options:**
1. Column is legitimately needed → add it to the form (`EFORM → FCLMN → newRow`).
2. Trigger is scratch → delete trigger text + header:
   ```sql
   DELETE FROM FORMTRIGTEXT WHERE FORM = <id> AND TRIG = <n>;
   DELETE FROM FORMTRIG     WHERE FORM = <id> AND TRIG = <n>;
   ```
3. Trigger uses the wrong `#INCLUDE` target → replace with a form-appropriate include, or inline the correct code.

### Class 3. `אין הודעה מספר N` (message N doesn't exist)

**Root cause:** trigger uses `ERRMSG N` / `WRNMSG N` where `N` isn't defined in `FORMMSG` / `FORMWRNMSG` for the form.

**SDK rule:** custom form messages must be numbered `>= 500`. Hitting `ERRMSG 1` / `ERRMSG 5` on a custom-prefix form almost always means scratch code.

**Triage:**
```sql
SELECT MSG, TEXT FROM FORMMSG
WHERE FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
FORMAT;
```

**Fix:** add the message to FORMMSG, OR fix the trigger to use an existing message number, OR delete the trigger if it's scratch.

### Class 4. `אין עמודות מוצגות` (no displayed columns)

**Root cause:** every FCLMN row for the form has `HIDE='H'` (aliased `HIDEBOOL='Y'`). Prepare-all-forms requires at least one visible column.

**Triage:**
```sql
SELECT NAME, POS, HIDE FROM FORMCLMNS
WHERE FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
ORDER BY POS FORMAT;
```

**Fix options (pick by intent):**
1. Form is a legitimate help/log/scaffolding form and should be ignored — no edit; the message is a prepare-all notice, not a blocker.
2. Form is scratch — cascade-delete (see § "Cascade-deleting a form" below).
3. Form needs a visible column — unhide one `FCLMN fieldUpdate HIDEBOOL=''`.

Beware: unhiding a column on a form with no proper base-table key column will surface a secondary error (`לא מופיעה עמודת מפתח ... מטבלת היסוד`). If that fires, the form has a structural problem, not just a visibility one.

### Class 5. Broken `#INCLUDE FORM/COL/STEP`

**Root cause:** a column-level trigger body is `#INCLUDE DONORFORM/COL/TRIGGER` and the donor's code references columns or variables that don't exist on the host form.

**Triage:**
```sql
SELECT C.NAME, T.TRIGNAME, TT.TEXT
FROM FORMCLTRIG C, TRIGGERS T, FORMCLTRIGTEXT TT
WHERE C.FORM = (SELECT EXEC FROM EXEC WHERE ENAME = '<FORM>' AND TYPE = 'F')
AND C.TRIG = T.TRIG
AND TT.FORM = C.FORM AND TT.NAME = C.NAME AND TT.TRIG = C.TRIG
AND TT.TEXT LIKE '#INCLUDE %'
ORDER BY C.NAME, T.TRIGNAME FORMAT;
```

For each suspect INCLUDE, read the donor's code and cross-check every `:$.X` / `:X` reference against the host form's FCLMN.

**Fix:** replace the INCLUDE with form-appropriate inline code, or update the donor to parametrize away the host-specific references.

---

## Chain-aware fix loop

Scratch triggers travel in packs. After fixing one compile error and recompiling, expect new errors to surface — either:

- **Secondary errors on the same form** (the first broken trigger was blocking compilation of others).
- **Downstream-form errors** (this form is imported or INCLUDEd elsewhere).

**Canonical loop:**

```
while true:
  compile(entity)                                   # WebSDK compile compound op
  errors = SELECT ... FROM PREPERRMSGS              # AUTHORITATIVE — see §"Reading compile state" below
               WHERE FORMNAME = <entity>
                  OR MAINFORM  = <entity>
  form_ok = websdk getRows(<entity>)                # cross-check: does the form open?
  if errors == [] AND form_ok == ok → stop          # truly clean
  if errors == previous_errors AND form_ok unchanged → stalled, report to user
  for each error in errors:
    classify → triage query → propose fix → (await approval) → apply fix
  continue
```

Count iterations. If more than ~5 passes don't converge, stop and ask the user — you're probably chasing a design issue, not a bug.

### Reading compile state — three signals, only one is authoritative

| Signal | What it tells you | Trust level |
|---|---|---|
| `PREPERRMSGS` table via SQLI | Current compile errors for the entity | **Authoritative** |
| `websdk_form_action compile` status | Whether the compile driver exited without crashing | Not a cleanliness signal — observed returning "התכנית הסתיימה בהצלחה" with 2 unresolved errors in `PREPERRMSGS` |
| `FORMPREPERRS` form via `getRows` | Session-filtered, stale across runs | Can return `{}` while errors exist |

**Always query `PREPERRMSGS` directly:**
```sql
SELECT FORMNAME, COLNAME, TRIGNAME, MESSAGE, SEVERITY, LINE
FROM   PREPERRMSGS
WHERE  FORMNAME = '<ENTITY>' OR MAINFORM = '<ENTITY>'
ORDER  BY LINE
FORMAT;
```

Zero rows here + the form opens via `getRows` = the entity is truly clean. Anything else = keep debugging.

*(Observed 2026-04-24 on SOF_INVDOCS: compile op reported success three consecutive times while PREPERRMSGS retained the same 2 SUPNAME/CUSTNAME parse errors and the form returned `המסך לא מוכן`. An automated chain that trusted only the compile op status would have declared clean and moved on.)*

---

## Cascade-deleting a form

When a form is confirmed scratch and should be deleted, `EFORM deleteRow` will fail with `ערך קיים במסך 'עמודות המסך'` because FCLMN rows block it. The cascade order:

```sql
/* Per-form-id = <FID> */
DELETE FROM FORMCLMNSTEXT WHERE FORM = <FID>;
DELETE FROM FORMCLMNSA    WHERE FORM = <FID>;
DELETE FROM FORMCLTRIGTEXT WHERE FORM = <FID>;
DELETE FROM FORMCLTRIG     WHERE FORM = <FID>;
DELETE FROM FORMTRIGTEXT   WHERE FORM = <FID>;
DELETE FROM FORMTRIG       WHERE FORM = <FID>;
DELETE FROM FORMCLMNS      WHERE FORM = <FID>;
/* FLINK / FSUB links */
DELETE FROM FORMLINKS      WHERE FORM = <FID>;
/* Direct activations on this form */
DELETE FROM EXEC           WHERE TABLE = <FID>;
/* The form itself */
DELETE FROM EXEC           WHERE EXEC = <FID>;
```

**Before running:** always confirm row counts per table up-front and show them to the user. Always confirm the form isn't referenced by any other form (FORMLINKS, #INCLUDE in FORMTRIGTEXT / FORMCLTRIGTEXT, join chains).

This is a direct SQL path permitted because form-metadata tables don't fire business triggers. Still requires explicit per-form user approval per the project's "Form interface > raw UPDATE/INSERT" rule.

---

## Inventory queries: find compile-poison across the system

Use these to find orphan states tenant-wide (useful for gap-scans):

```sql
/* Columns flagged as expressions with no FCLMNA row */
SELECT COUNT(*) FROM FORMCLMNS C
WHERE C.EXPRESSION = 'Y'
AND NOT EXISTS (SELECT 1 FROM FORMCLMNSA A
                WHERE A.FORM = C.FORM AND A.NAME = C.NAME)
FORMAT;

/* Columns with EXPRESSION=Y and empty EXPR body */
SELECT COUNT(*) FROM FORMCLMNSA A, FORMCLMNS C
WHERE A.FORM = C.FORM AND A.NAME = C.NAME
AND A.EXPR = '' AND C.EXPRESSION = 'Y' FORMAT;

/* Forms where every FCLMN row is hidden */
SELECT F.ENAME FROM EXEC F
WHERE F.TYPE = 'F'
AND NOT EXISTS (SELECT 1 FROM FORMCLMNS C
                WHERE C.FORM = F.EXEC AND (C.HIDE <> 'H' OR C.HIDE IS NULL))
AND EXISTS (SELECT 1 FROM FORMCLMNS C WHERE C.FORM = F.EXEC)
FORMAT;

/* Form-level triggers with body referencing :$.X for a column missing on the host form */
/* (Approximate — pattern-match on each line, then verify per-form.)       */
SELECT DISTINCT FORM, TRIG, TEXT FROM FORMTRIGTEXT
WHERE TEXT LIKE '%:$.%' AND TEXT LIKE '%ZTST_%'
ORDER BY FORM, TRIG FORMAT;
```

---

## Tooling: the `compile-doctor` agent

See `plugin/agents/compile-doctor.md`. Invoke via `/compile-doctor ENTITY [ENTITY...]` to automate the triage loop.

The agent classifies each FORMPREPERRS row against the classes above, proposes one fix per error with a paste-ready recipe, and (with per-fix approval) applies it and recompiles. It is chain-aware: after each fix, it recompiles and re-reads FORMPREPERRS before moving on.

---

## See also

- `debugging.md` — trace flags, logging, revisions, VSCode bridge
- `common-mistakes.md` — `FORMPREPERRS stale`, `TAKEUPGRADE silent completion`, `MSG numbering`
- `websdk-cookbook.md` — `compile` compound op, `FORMPREPERRS getRows` cautions
- `forms.md` — form preparation, sub-level EXPR columns
- `triggers.md` — trigger types, `FORMPREPERRS accumulates stale errors` (§ 12)
