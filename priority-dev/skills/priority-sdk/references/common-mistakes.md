# Common mistakes — Priority dev anti-pattern catalog

Flat catalog of anti-patterns that past sessions have wasted time on. Each entry names the symptom, the wrong approach, the right approach, and points at the canonical reference. Use as a quick "why isn't X working" lookup before retrying a pattern.

## Form / column management

### Using CHOOSE-FIELD for "after user picked" logic
- **Wrong:** CHOOSE-FIELD returns a SELECT list for the picker; it fires when the column opens, not when the user commits.
- **Right:** POST-FIELD — runs after the user commits a value.
- **See:** `triggers.md` § POST-FIELD.

### `startSubForm("<name>_SUBFORM")` or `startSubForm({subform: "..."})`
- **Wrong:** WebSDK subform names do not have `_SUBFORM` suffix; the property name is `name`, not `subform`.
- **Right:** `startSubForm({op: "startSubForm", name: "FCLMN"})`.
- **See:** `websdk-cookbook.md` § "Critical: `startSubForm` uses `name`".

### `getRows` on an EFORM subform without `setActiveRow(1)` first
- **Wrong:** Returns `{}`.
- **Right:** `setActiveRow(1)` before `getRows`; or query `FORMCLMNS` / `FORMTRIG` directly via SQLI for metadata reads.
- **See:** `forms.md` § "Managing forms and columns via WebSDK" → "Reading columns".

### Hiding a column via `POS=0`
- **Wrong:** Text forms in the web client use `HIDEBOOL`, not `POS`.
- **Right:** `HIDEBOOL='Y'`.
- **See:** `forms.md` § "Hidden Columns".

### Believing raw EFORM `newRow` always fails
- **Wrong:** Older docs claimed this universally — the claim was specific to system-table forms.
- **Right:** Raw `newRow` works for flat forms on custom-prefix tables (`SOF_`, `ASTR_`). FCLMN auto-seeds from TNAME. UI-only path remains needed for forms over system tables.
- **See:** `forms.md` § "Creating a root form on a custom-prefix table".

### Attaching CHOOSE-FIELD to get a foreign-key picker
- **Wrong:** A plain INT column with no join has no picker UI, regardless of any CHOOSE-FIELD trigger attached.
- **Right:** Hide the INT code + add a visible imported CHAR display column; the picker comes from the join metadata.
- **See:** `forms.md` § "Foreign-Key Pickers: the join IS the picker".

### Claiming imported columns fail at `IDCOLUMNE > 0`
- **Wrong:** Older docs claimed this categorically — misdiagnosis.
- **Right:** Imported columns work at `IDCOLUMNE > 0` when the base column carries matching `JTNAME`/`JCNAME` at the same `IDJOINE` value.
- **See:** `forms.md` § "Private Development on System Forms".

### Setting `IDCOLUMNE = 6` on a column added to a custom-table form
- **Symptom:** Form compiles fine; new column appears in the UI; user types any value (e.g., `1`) and gets `ערך '1' לא קיים בעמודה '<col>' בטבלת '<form-title>'` ("value '1' does not exist in column …"). Looks like a foreign-key validation error even though no join was configured.
- **Root cause:** `IDCOLUMNE = 6` on a custom-table form (`SOF_*`, `ASTR_*`, etc.) tells Priority "this is an imported-column instance" — but with no `JTNAME`/`JCNAME` to import from, the validator points at the column's own table and rejects every value as "not found in the lookup". The `IDCOLUMNE >= 6` rule in older recipes is for **custom columns on SYSTEM forms** (over `INVOICES`, `DOCUMENTS`, etc.), not for columns on custom-table forms.
- **Wrong:** Default to `IDCOLUMNE = 6` for any custom column. Adding a CHOOSE-FIELD trigger to "fix" the lookup. Adding an empty `JTNAME` to silence the validator.
- **Right:** Match the form's existing convention. Read FCLMN on the parent form first — if every other column has `IDCOLUMNE = 0`, yours must too.
  - **Custom-table form** (form `TNAME` starts with `SOF_`, `ASTR_`, etc.) → `IDCOLUMNE = 0`.
  - **System-table form** (form `TNAME` is `INVOICES`, `DOCUMENTS`, `ORDERS`, etc.) → `IDCOLUMNE >= 6`.
- **Fix on an already-saved column:** `EFORM filter ENAME=<form> → setActiveRow → startSubForm FCLMN → filter NAME=<col> → setActiveRow → fieldUpdate(IDCOLUMNE, "0") → saveRow → compile`.
- **See:** `recipes/add-column.md`, `websdk-cookbook.md` § "Add a column to a form", verified 2026-04-25 on `SOF_CUSTSIGN.REMARKS`.

### Writing a scalar subquery in `FCLMNA.EXPR`
- **Wrong:** Parser rejects `SELECT` in an expression with `parse error at or near symbol SELECT`.
- **Right:** Use a real join (imported column from joined table) or a POST-UPDATE trigger that assigns the computed value.
- **See:** `forms.md` § "Managing forms and columns via WebSDK" → "Setting a column expression".

### Using `||` for string concatenation in `FCLMNA.EXPR`
- **Wrong:** `SOMETABLE.COL || ''` fails to compile — `||` is boolean OR in Priority expressions, not concat.
- **Right:** Use ternary (`cond ? a : b`) with implicit concat inside branches, or `STRCAT` in a trigger.
- **See:** `forms.md` § "Managing forms and columns via WebSDK".

### FCLMN `saveRow` fails with "ערך לא קיים בקובץ" when creating a truly new column NAME
- **Symptom:** WebSDK flow `startSubForm(FCLMN) → newRow → fieldUpdate(NAME, '<NEW_NAME>') → ... → saveRow` fails with `ערך לא קיים בקובץ` ("value does not exist in file"). Happens specifically when `<NEW_NAME>` is not present in the form's base table AND not in any joined table — a truly-new scratch/expression column (e.g., a reset target referenced by an `#INCLUDE` trigger from a donor form).
- **Root cause:** WebSDK's FCLMN validator checks NAME against the form's scope (base-table columns ∪ joined-table columns ∪ existing form columns). A name that exists nowhere fails validation regardless of how you set `CNAME`/`TNAME`/`EXPRESSION`.
- **Wrong:** Trying variations of `CNAME=DUMMY`, `TNAME=DUMMY`, `IDCOLUMNE=6`, etc. — the validator won't accept the NAME.
- **Right:** Fall back to direct DBI INSERT into `FORMCLMNS` (and `FORMCLMNSA` for the expression body). This is the permitted bypass for metadata tables that don't fire business triggers. See `forms.md` § "Fallback: direct DBI INSERT when WebSDK `newRow` rejects the column name" for the recipe.

### Setting FCLMN `WIDTH` before `EXPRESSION=Y` in a newRow chain
- **Symptom:** `fieldUpdate` on WIDTH returns `ניתן לקבוע/לשנות רוחב רק לעמודה חישובית או לעמודה מיובאת מוצגת בלבד` ("Width can only be set/changed for a calculated column or a visible imported column").
- **Root cause:** Priority validates WIDTH at fieldUpdate time against the row's current state. A fresh `newRow` has `EXPRESSION=''` and no physical column link — WIDTH is rejected.
- **Right:** Set `EXPRESSION='Y'` first, then `WIDTH`. Correct order: `NAME → EXPRESSION → TYPE → WIDTH → (other fields) → saveRow`.
- **See:** `forms.md` § "Adding a column" → "`fieldUpdate` ordering matters for expression columns".

### Setting `IDJOINE` to a multi-digit value via `fieldUpdate`
- **Symptom:** `fieldUpdate(IDJOINE, "10")` returns `סמן מספר מ-0 עד 9 ובנוסף אפשרי ? או !`.
- **Root cause:** `IDJOINE` (EFORM-layer alias) is `CHAR(1)`, accepting `0`–`9`, `?`, or `!` only. The underlying `FORMCLMNS.IDJOIN` is `INT(2)`, but the EFORM UI/WebSDK layer encodes join IDs as single characters.
- **Wrong:** Reading raw `FORMCLMNS.IDJOIN` values like `10` and copying them to `fieldUpdate(IDJOINE, ...)`.
- **Right:** Treat raw FORMCLMNS.IDJOIN integers as opaque. Set `IDJOINE` via EFORM WebSDK only with 1-char values. If you need a 2-digit raw value, inspect the live form's row in WebSDK to see what `IDJOINE` renders as (e.g., `"0?"`, `"6"`) and copy that string.
- **See:** `websdk-cookbook.md` § "Join metadata placement".

### Populating a stored base-table `ZOOM1` column via PRE-INSERT hardcodes
- **Wrong:** `:$.ZOOM1 = 22` in PRE-INSERT only runs on insert, drifts if TYPE is edited, and hardcodes EXEC ids that can differ per tenant.
- **Right:** Leave the base-table `ZOOM1` column unread. Use a ternary `FCLMNA.EXPR` on the hidden form `ZOOM1` column that dereferences PRE-FORM-initialized form variables (`0 + :ORDEXEC`, etc.). Initialize the variables via `SELECT EXEC INTO :VAR FROM EXEC WHERE ENAME = '<form>' AND TYPE = 'F'` in the PRE-FORM trigger.
- **See:** `forms.md` § "Dynamic Access (ZOOM1 pattern)" and the live `LOGFILE` form.

### Adding ZOOMCOLUMNS rows before checking if fallback works
- **Wrong:** Adding `SOURCE → TARGET` rows for each intended target often causes the lowest-POS TONAME to win on every target form that imports it (e.g., ORDNAME at POS=1 wins on AINVOICES, CPROF, DOCUMENTS_D because they all import it via joins).
- **Right:** If every target form's primary ORD column is the correct landing, delete all ZOOMCOLUMNS rows for your source — Priority's fallback picks each target's own primary ORD column. Only add rows when the fallback demonstrably goes to the wrong column and the mismatch is name-only.
- **See:** `forms.md` § "Dynamic Access (ZOOM1 pattern)" → "ZOOMCOLUMNS — when to add rows, and when NOT to".

### Debugging across tenants without verifying bridge connection
- **Wrong:** Applying fixes via `websdk_form_action` while the user tests on a different Priority tenant — symptoms look identical to "the fix didn't work", but it was applied to the wrong DB.
- **Right:** Read the trace line on every call: `[websdk] Logging in to url=... company=<X> tabulaini=... language=<N> user=<U>`. Cross-check with the user and confirm `priority.selectAllRowsFromTable` returns data matching what they see in their UI. Timestamp divergence (yesterday vs today) is a strong tenant-mismatch signal.
- **See:** `forms.md` § "Dynamic Access (ZOOM1 pattern)" → tenant-mismatch note.

### `fieldUpdate(IDJOINE, "10")` or higher
- **Wrong:** IDJOINE accepts only 0–9 (plus `?` and `!`). Older memory claim of 0–99 was wrong.
- **Right:** Re-use IDJOINE values across different JTNAMEs if needed — IDJOINE only disambiguates when the same target table appears multiple times.
- **See:** `websdk-cookbook.md` § "Common Mistakes" table.

### Omitting `FCLMN.BOOLEAN='Y'` on CHAR(1) checkbox columns
- **Wrong:** Column renders as a plain single-character text input.
- **Right:** Set `BOOLEAN='Y'` on the FCLMN row alongside the other fields on `saveRow`.
- **See:** `forms.md` § "Boolean Columns".

### Calling `createTrigger` compound or `filter` without a `getRows` before `setActiveRow`
- **Wrong:** Writes land on the wrong parent (EFORM's own meta-form). Compound tool silently fails.
- **Right:** Use primitives in order `filter` → `getRows` → `setActiveRow` → `startSubForm` → …
- **See:** `websdk-cookbook.md` § "Known bridge behaviors" → "filter primitive".

## Tables and DBI

### Using `ADD TABLE` in DBI
- **Wrong:** Not valid Priority DBI syntax.
- **Right:** `CREATE TABLE <name> <cols> UNIQUE(<key>);`.
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "CREATE TABLE vs ADD TABLE".

### SQL-standard column syntax in DBI
- **Wrong:** `MYCOL CHAR(1) NOT NULL` — parser rejects.
- **Right:** `MYCOL (CHAR, 1, 'Title')` — parentheses around the triple.
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "Column spec uses parentheses".

### Column named `REFRESH`
- **Wrong:** Reserved word; DBI rejects.
- **Right:** Rename (e.g., `DOREFRESH`).
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "`REFRESH` is reserved".

### `TIME` column width 4
- **Wrong:** Minimum width is 5; DBI fails.
- **Right:** Use 6.
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "`TIME` width minimum".

### `AUTOUNIQUE` standalone in CREATE TABLE
- **Wrong:** Requires a paired `UNIQUE` key; fails without one.
- **Right:** `AUTOUNIQUE (idcol) UNIQUE (displaycol)`, or use `UNIQUE (col)` + a PRE-INSERT trigger that computes `MAX(KLINE)+1`.
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "`AUTOUNIQUE` requires a paired `UNIQUE` key".

### DBI column title longer than 20 characters
- **Wrong:** `FOR TABLE INSERT` truncates or rejects silently.
- **Right:** Abbreviate in DBI; set the full title via `FCLMN.COLTITLE` after.
- **See:** `tables-and-dbi.md` § "DBI pitfalls" → "Column title hard cap at 20 characters".

### DBI block parse failure silently skips the entire block — all downstream steps fail with (1013)

**Symptom:** After installing an upgrade shell, you see a cascade of errors:
```
Line 2 : parse error AT OR NEAR SYMBOL ,
Line 1 : parse error AT OR NEAR SYMBOL INSERT
Error: Missing column TGML_COOHOMSKU in table PART (1013)
Error: Missing column TGML_SPECPUR in table PART (1013)
...N more (1013) errors...
Unrecoverable errors occurred — fix and rerun this upgrade
```

**Root cause:** When Priority's DBI parser encounters a parse error inside a shell `DBI << \EOF ... EOF` block, it skips the **entire block** — none of the columns in it are added to the table. Every subsequent revision step (TAKEFORMCOL, TAKETRIG, TAKESINGLEENT) that references those missing columns then fails with `(1013) Missing column` because the table columns were never created.

**The (1013) errors are a symptom, not the root cause.** Fix the DBI parse error first; the (1013) errors resolve automatically on re-run once the columns exist.

**Common DBI parse-error triggers inside shell `DBI << \EOF` blocks:**
- Hebrew column titles byte-rotated due to RTL BIN bug (see next entry)
- Line exceeding 68 characters (parser truncates mid-token)
- Missing `FOR TABLE <name>` header before `INSERT` lines
- Trailing comma on the last column definition before `UNIQUE`

*(seen in: da9b3f57-4ba7-49bd-9985-d6b0b06b7d72; sideways receipt: `SELECT COUNT(DISTINCT UPGRADE) FROM UPGNOTES WHERE UPGTYPE=10 AND UPGRADE IN (SELECT UPGRADE FROM UPGNOTES WHERE UPGTYPE=4)` → 2 additional revisions confirmed)*

### Hebrew titles in UPGNOTESTEXT DBI blocks cause RTL byte-rotation — use ASCII-only in `FOR TABLE … INSERT` lines

**Symptom:** The shell generated from a revision contains malformed DBI like:
```
/* BROKEN — Hebrew RTL byte-rotation shifts closing ) to the start of the next line */
,('שם עמודה בעברית' ,TGML_CSVSUB (CHAR, 60
```
This triggers a DBI parse error on the very next line, causing the entire DBI block to be skipped (see previous entry).

**Root cause:** On Priority installations running BIN versions prior to 24.0.37 (with `UPGTITLES=0`), Hebrew column titles stored in `UPGNOTESTEXT.TEXT` get byte-rotated when Priority generates the shell. The visual RTL display order of Hebrew characters causes the closing `)` and comma to shift to the beginning of the next line in the output stream.

**Fix:** Use **ASCII-only titles** in all `FOR TABLE … INSERT` column definitions written to `UPGNOTESTEXT`. Set Hebrew display titles separately via TAKEFORMCOL (not affected by this bug):
```sql
/* CORRECT — ASCII title in the DBI block, safe on all BIN versions */
TGML_CSVSUB  (CHAR, 60, 'CSV Sub-path'),
TGML_BOMSUB  (CHAR, 60, 'BOM Sub-path'),
TGML_HISTSUB (CHAR, 60, 'History Sub-path')
```
Form-column **display titles** (stored separately in TAKEFORMCOL revision steps) are NOT subject to this constraint and can use full Hebrew.

- **See:** `tables-and-dbi.md` § "DBI Syntax Reference".
*(seen in: da9b3f57-4ba7-49bd-9985-d6b0b06b7d72; eval-verified: 8b4e1c72-d035-4f9a-a761-2e8c0f3b5d91)*

## Triggers and SQLI

### Declaring variables with `:VAR = INTEGER;`
- **Wrong:** Not valid SQLI syntax.
- **Right:** `SELECT <expr> INTO :VAR FROM DUMMY;` implicitly declares.
- **See:** `sql-core.md`.

### Using variable name `:G1`
- **Wrong:** Collides with PREPALLKPI; unpredictable results.
- **Right:** Rename.
- **See:** `triggers.md` § "Known trigger quirks" → "SQLI trigger syntax gotchas".

### Rewriting a column trigger via WebSDK `newRow` on FORMCLTRIGTEXT
- **Wrong:** Silently appends; produces duplicate lines Priority parses as broken SQL at runtime.
- **Right:** DBI `DELETE FROM FORMCLTRIGTEXT WHERE …` + `INSERT` via `run_inline_sqli(mode="dbi")`.
- **See:** `forms.md` § "Column trigger code — use DBI" and `websdk-cookbook.md` § "Known bridge behaviors".

### Adding a column-level trigger to a system column
- **Wrong:** WebSDK/`write_to_editor` rejects; the insert on FORMCLTRIG fails.
- **Right:** Form-level POST-UPDATE guarded to be idempotent.
- **See:** `triggers.md` § "Known trigger quirks" → "Column-level triggers on system columns are blocked".

### Email validation with `STRIND`
- **Wrong:** `STRIND(:EMAIL, '@') > 0` has undefined behaviour on NULL on some server builds.
- **Right:** `:EMAIL LIKE '%@%.%'`.
- **See:** `triggers.md` § "SQLI trigger syntax gotchas".

### `PRANDOM` called inline
- **Wrong:** Fails; PRANDOM is not a function.
- **Right:** `EXECUTE` with a `.pq` file.
- **See:** `triggers.md` § "SQLI trigger syntax gotchas".

### Cursor inside a combined trigger (POST-UPD-INS etc.)
- **Wrong:** Cursor declarations fail silently or at compile in combined-event slots like `POST-UPD-INS` / `POST-INSUPD`.
- **Right:** Split into single-event triggers (POST-INSERT + POST-UPDATE, share logic via INCLUDE), or invoke a helper procedure from the combined slot.
- **See:** `triggers.md` § "Cursors cannot run in combined triggers" (SDK 23.1 release-notes gotcha).

### Hebrew (RTL) string literals in SQLI UPDATE/INSERT via run_inline_sqli

| Symptom | Cause | Fix |
|---------|-------|-----|
| `parse error at or near symbol <Hebrew char>` on `UPDATE`/`INSERT` via `run_inline_sqli` | Hebrew (RTL) string literals in the OData SQLI endpoint — the WCF SQLI parser rejects non-ASCII literals in UPDATE/INSERT statements | Use `websdk_form_action fieldUpdate` with the Hebrew value as a JSON string (the bridge handles encoding); or use `run_inline_sqli(mode='dbi')` which accepts Hebrew in `CHANGE TITLE TO` |
| `Unclosed string` on SQLI UPDATE with multi-line value | SQLI string literals do not support embedded newlines | Split into multiple single-line `fieldUpdate` calls; for UPGNOTESTEXT, write one TEXTLINE row per call (max 68 chars each) |

**Scope:** only the `run_inline_sqli(mode='sqli')` OData path is affected.
`run_inline_sqli(mode='dbi')` **does** accept Hebrew literals in `CHANGE TITLE TO 'Hebrew'`
— the DBI parser handles Unicode. The SQLI path does not.

**Workaround pattern (editing a text value containing Hebrew):**
```js
// Instead of: run_inline_sqli("UPDATE T SET COL = 'Hebrew text'")
// Use WebSDK fieldUpdate — pass the Hebrew string directly in the value:
websdk_form_action({
  form: "MY_FORM",
  operations: [
    { op: "filter", field: "KEY", value: "1" },
    { op: "getRows" },
    { op: "setActiveRow", row: 1 },
    { op: "fieldUpdate", field: "COL", value: "נתיב CSV" },
    { op: "saveRow" }
  ]
})
```

For UPGNOTESTEXT specifically, see `references/vscode-bridge-examples.md`
§Shell Generation step 5 for the 4-deep WebSDK navigation recipe.

*(seen in: session-2026-05-02-tgml-phase1 — UPGNOTESTEXT Hebrew DBI title fix)*

### Embedding Hebrew character literals directly in SQLI procedure or trigger code on Hebrew installs
- **Symptom:** Code looks correct in the editor but compiles wrong or produces incorrect results at runtime. Opening `PROGRAMSTEXT` or `FORMTRIGTEXT` for the saved step reveals the entire line has been stored reversed (RTL).
- **Root cause:** `PROGRAMSTEXT.TEXT` and `FORMTRIGTEXT.TEXT` are `CHAR(68)` columns. On a Hebrew Priority installation the database client renders these columns RTL, causing any line that contains a Hebrew character literal to be stored with its characters in reversed order. The reversed line is syntactically invalid SQLI.
  Example — intended source: `:SD = (:DN = 'א' ? 'A' : :SD);`
  Stored in PROGRAMSTEXT: `;(A' : :SD' ? 'א' = SD = (:DN:`
- **Wrong:** Writing Hebrew string constants inline: `':SD = (:DN = 'א' ...)'`.
- **Right:** Use runtime functions or message numbers instead of inline Hebrew literals:
  | Need | Safe alternative |
  |------|----------------|
  | Hebrew weekday letter | `DTOA(date, 'day')` at runtime |
  | Day-of-week comparison | `DAY(date)` integer (1=Sun … 7=Sat) |
  | Hebrew message text | `ENTMESSAGE(entity, type, num)` |
  | Any Hebrew string constant | Define in Procedure Messages / Form Messages; reference by number |
  Note: the `:HEBREWFILTER` variable controls display ordering only — it does NOT fix source-code storage reversal.
- **See:** `sql-core.md` § "String Functions". *(seen in: session-2026-05-02-tgml-phase1)*

## Deployment

### Using `TAKESINGLEENT` for any change
- **Wrong:** Captures the entire entity; on system forms, includes references to system columns that may not exist on the target. INSTITLE fails with "Missing column X in table Y".
- **Right:** Use the most specific UPGCODE: `TAKETRIG`, `TAKEFORMCOL`, `TAKEPROCSTEP`, `TAKEREPCOL`, `TAKEDIRECTACT`. `TAKESINGLEENT` only for brand-new entities.
- **See:** `deployment.md` § "Choosing the right UPGCODE".

### Forgetting `TRANSLATED='N'` on UPGRADES before TAKEUPGRADE
- **Wrong:** TAKEUPGRADE completes silently with no shell file generated.
- **Right:** Set `TRANSLATED='N'` on the revision before running.
- **See:** `deployment.md` § "TAKEUPGRADE silent completion".

### Custom columns on system tables without a manual UPGNOTES DBI entry
- **Wrong:** TAKEUPGRADE misses them (ad-hoc DBI bypasses change tracking); target server lacks the column; INSTITLE fails downstream.
- **Right:** Add a `UPGCODE='DBI'` entry to UPGNOTES with the `FOR TABLE … INSERT …` in UPGNOTESTEXT.
- **See:** `deployment.md` § "DBI in UPGNOTES for system-table columns".

### `EXEC` prefix in UPGNOTESTEXT
- **Wrong:** Parse error during TAKEUPGRADE.
- **Right:** No `EXEC` prefix — the shell wraps the DBI block automatically.
- **See:** `deployment.md` § "DBI in UPGNOTES for system-table columns".

### Hebrew titles in UPGNOTESTEXT
- **Wrong:** Encoding issues during shell generation.
- **Right:** ASCII titles in the DBI spec; set Hebrew title via a follow-up `TAKEFORMCOL` or `FCLMN.COLTITLE` update.
- **See:** `deployment.md` § "DBI in UPGNOTES for system-table columns".
- **Detail:** See "Hebrew titles in UPGNOTESTEXT DBI blocks cause RTL byte-rotation" in the Tables and DBI section above for the mechanism and code example.

### UPGRADES revision serves stale cached shell after content fix — clear PREPARED before re-running TAKEUPGRADE

**Symptom:** You fix a DBI error in `UPGNOTESTEXT`, re-run TAKEUPGRADE and DOWNLOADUPG, but the downloaded shell still contains the old broken content.

**Root cause:** Once a revision row has `PREPARED='Y'`, DOWNLOADUPG serves the cached shell. It does not regenerate until PREPARED is cleared.

The standing rule ("never prepare the same upgrade twice") applies when the shell has already been installed on a target server. When the generated shell is corrupt and has **never been installed**, resetting and re-preparing the same revision is safe.

**Fix:**
1. Fix the underlying UPGNOTESTEXT content (e.g., rewrite DBI column titles to ASCII-only).
2. Clear `PREPARED` and reset `TRANSLATED` on the UPGRADES row via WebSDK — use the form path, not a direct SQL `UPDATE`, because the UPGRADES form has save-time trigger logic that direct SQL bypasses:
   ```json
   [
     {"op": "fieldUpdate", "field": "PREPARED", "value": ""},
     {"op": "fieldUpdate", "field": "TRANSLATED", "value": "N"},
     {"op": "saveRow"}
   ]
   ```
3. Re-run `TAKEUPGRADE` then `DOWNLOADUPG` on the same revision row.

**Constraint:** If the shell was already partially or fully installed on any target server, create a new revision instead to avoid re-applying already-applied steps.

*(seen in: da9b3f57-4ba7-49bd-9985-d6b0b06b7d72; eval-verified: 1d9e5f83-a247-4c6b-b950-7f4a1b2e8c04)*

## Reports

### Relying on `#POS` when the source column has a condition
- **Wrong:** `#500` expands to the condition text, not the parameter value. Downstream columns receive garbage.
- **Right:** Reference the underlying column directly (e.g., `INVOICES.IV`).
- **See:** `reports.md` § "`#POS` references break when source column has a condition".

### Setting a parameter filter without `EXPRESSION='Y'` + `= 0+ :VAR`
- **Wrong:** Report returns all rows regardless of the parameter value.
- **Right:** REPCLMNSA condition `= 0+ :IV` with `EXPRESSION='Y'` on the filter column.
- **See:** `reports.md` § "Filter by parameter with `= 0+ :VAR`".

### Navigating REPCLMNS via `setActiveRow` by index
- **Wrong:** REPCLMNS row ordering is unreliable.
- **Right:** `filter(POS, "<pos>")` before `setActiveRow`.
- **See:** `reports.md` § "WebSDK REPCLMNS navigation".

## Interfaces

### Naming an EDI interface longer than 20 characters
- **Wrong:** ENAME truncates silently; `EXECUTE INTERFACE '<long name>'` fails with "interface not found".
- **Right:** Keep names ≤ 20 chars.
- **See:** `interfaces.md` § "EDI form-load internals" → "ENAME field truncates at 20 characters".

### Trying to set INTERCLMNSFILE mappings via WebSDK
- **Wrong:** The CHOOSE-FIELD popup for the column-mapping field cannot be confirmed programmatically.
- **Right:** Use dynamic `-form` interfaces, or raw SQLI on INTERCLMNSFILE with user approval.
- **See:** `interfaces.md` § "EDI interface creation via WebSDK is partially blocked".

### Using `EXECUTE INTERFACE` inside a direct-activation procedure (custom tables)
- **Wrong:** GENERALLOAD values drop silently; custom-table rows end up NULL.
- **Right:** Direct INSERT via the LINK pattern.
- **See:** `procedures.md` § "Direct activations" → "`EXECUTE INTERFACE` … loses GL values on custom tables".

## Debugging

### Reaching for `run_windbi_command` dump/search commands for inspection
- **Symptom:** Bridge log shows `SQLIController` errors like `Can't execute [Dump Form]. Cause: No form data` / `Dump Report. No report data` / `Expected an .pq file` / `No search string data`. Agent retries the same command varying `entityName`, or concludes the entity "doesn't exist". In one week of real usage these accounted for 188 errors: 36× `dumpForm`, 29× `dumpProcedure`, 22× `displayFormColumns`, 20× `findStringInAllForms`, 9× `runSqliFile`, 6× `executeDbi`, 6× `dumpReport` — against **zero** `run_inline_sqli` / `websdk_form_action` errors in the same window.
- **Root cause:** WINDBI commands are VSCode command-palette invocations. They target the **active editor buffer**, not the `entityName` parameter — `entityName` is a hint the bridge uses to clipboard-paste into the input dialog, not a selector. Additionally, dump commands render output to a VSCode webview panel (HTML), which the bridge cannot read programmatically. `vscode-bridge-examples.md` § "Command Behavior Reference" documents 30–50% capture rate for the dump category.
- **Wrong:** Default to `run_windbi_command("priority.dumpForm", entityName: "X")` / `dumpProcedure` / `dumpReport` / `displayFormColumns` / `displayTableColumns` / `findStringInAllForms` / `executeDbi` / `runSqliFile` to inspect or run things.
- **Right:** Use capturable, editor-independent paths:

  | Goal | Use | Don't use |
  |------|-----|-----------|
  | Run DBI | `run_inline_sqli(mode="dbi", sql=...)` — direct WCF, no file | `priority.executeDbi` |
  | Run ad-hoc SQLI | `run_inline_sqli(sql=...)` | `priority.runSqliFile` |
  | Inspect form columns | `websdk_form_action` on EFORM → FCLMN, or `SELECT … FROM FORMCLMNS WHERE FORM='X' FORMAT;` | `priority.displayFormColumns` / `priority.dumpForm` |
  | Inspect procedure steps | `websdk_form_action` on EPROG subforms, or `SELECT … FROM CODEREF …` | `priority.dumpProcedure` |
  | Inspect table schema | `SELECT … FROM COLUMNS WHERE TNAME='X' FORMAT;` | `priority.displayTableColumns` / `priority.dumpTable` |
  | Search code | `SELECT … FROM CODEREF WHERE TEXT LIKE '%x%' FORMAT;` | `priority.findStringInAllForms` |
  | Compile form/proc | `websdk_form_action` compound `compile` op | `priority.prepareForm` without entityName |

- **When WINDBI is actually needed:** `priority.prepareForm` / `prepareProc` with an explicit `entityName` is a last-resort compile fallback when the WebSDK compile op fails. Report compile (Prepare/הכנה) has no WebSDK equivalent — WINDBI is the only path per `feedback_use_websdk_for_all_ui_tasks.md`.
- **See:** `vscode-bridge-examples.md` § "Command Behavior Reference", `websdk-cookbook.md` § "SQLI metadata queries", § "Entity discovery", § "Operation Property Reference".

### Trusting FORMPREPERRS or `compile` op status as authoritative compile state
- **Wrong:** Treating `websdk compile` returning "התכנית הסתיימה בהצלחה" as a cleanliness signal. The op's success message means the compile driver exited cleanly — not that the produced form artifact is usable. FORMPREPERRS `getRows` is also not authoritative — it filters/session-scopes and can return `{}` while real errors exist.
- **Right:** Query `PREPERRMSGS` directly via SQLI for current compile state, AND `getRows` on the form to confirm it opens:
  ```sql
  SELECT FORMNAME, COLNAME, TRIGNAME, MESSAGE, LINE FROM PREPERRMSGS
  WHERE FORMNAME = '<X>' OR MAINFORM = '<X>' FORMAT;
  ```
  Zero rows + form opens = clean. Anything else = keep debugging, regardless of op status.
- **Observed:** 2026-04-24 on SOF_INVDOCS — compile op returned success 3× in a row while PREPERRMSGS had 2 persistent SUPNAME/CUSTNAME parse errors and the form returned `המסך לא מוכן` on every open. An automated loop trusting only the compile op would have declared victory and moved on.
- **When FORMPREPERRS content IS useful:** immediately after a `prepareForm` that returned a hard error — it names the form/column/trigger/EXPR step precisely (e.g. `AINVOICEITEMS/ASTR_QPRICEN/EXPR` pointing at a dangling `$ASTR_EXCHANGE3`). Still cross-check against PREPERRMSGS before acting.
- **See:** `compile-debugging.md` § "Reading compile state — three signals, only one is authoritative", `websdk-cookbook.md` § "Compile-status signals: PREPERRMSGS is authoritative".

### Treating single-form compile as ground truth for "Prepare All Forms" errors
- **Symptom:** User reports errors from Priority's "Prepare all forms" (e.g., `"SOF_INVDOCS/SUPNAME/EXPR", line 1: parse error at or near symbol ;`). You run `websdk compile SOF_INVDOCS` and see a completely different error (e.g., `DOCCODE/POST-FIELD :$.OLINE missing`). Agent then either (a) concludes the user's errors are "stale" and moves on, or (b) invents a fix for an error not in its own FORMPREPERRS.
- **Root cause:** Batch prepare-all processes forms in dependency order and may attribute errors to the wrong form, read stale per-column compile artifacts on disk, or use different strictness than single-form compile. The single-compile result is authoritative for THE FORM itself; it is NOT authoritative for the full batch picture.
- **Wrong:** Dismissing user-reported batch errors as stale without evidence. Inventing a fix for an error FORMPREPERRS doesn't confirm.
- **Right:** When batch errors don't reproduce in single compile, (1) state the divergence explicitly to the user, (2) don't auto-fix, (3) ask them to re-run Prepare All after any edits so you're reading the same batch state they are, (4) investigate upstream dependencies (join chains, `#INCLUDE` donors, sub-level links) that might be where the batch actually tripped.
- **See:** `compile-debugging.md` § "Single-form compile vs batch 'Prepare All Forms'".

### Clearing `FCLMN.TRIGGERS='Y'` to "fix" a compile error
- **Symptom:** Column has `TRIGGERS='Y'` but no matching row in `FORMCLTRIG`. Agent assumes this is the root cause of a parse error on the column and clears the flag.
- **Root cause:** `FCLMN.TRIGGERS='Y'` without `FORMCLTRIG` is extremely common — ~31,000 rows in a typical tenant. The flag can linger after a trigger was removed without meaning the column is broken.
- **Wrong:** Clearing `TRIGGERS=''` as a first-try fix for any compile error near the column.
- **Right:** Identify the error class first (`compile-debugging.md` § "Error class → root cause → triage query"). Parse errors at `;` on `FORM/COL/EXPR` are caused by `EXPRESSION='Y' + empty FCLMNA.EXPR`, not by orphan `TRIGGERS='Y'`. Only clear `TRIGGERS` when the invoker explicitly wants to disable the trigger surface on the column.
- **See:** `compile-debugging.md` § "Class 1. Parse error at `;` on `<FORM>/<COL>/EXPR`".

### Copy-pasting a trigger across forms without auditing `:$.<column>` references
- **Symptom:** A form has a form-level or column-level trigger whose body references columns that don't exist on the host form (e.g., `:$.ORD`, `:$.OLINE`, `:$.ZTST_ORDNAME`). Classic scratch/donor-form artifact. Error: `משתנה <VAR>.$: בהפעלה <FORM>/<TRIGGER> אינו קיים כעמודה במסך`.
- **Root cause:** Trigger was written for a donor form, copy-pasted to the host. Also appears via `#INCLUDE DONORFORM/COL/TRIGGER` where the donor references its own columns.
- **Wrong:** Trying to fix by adding the referenced column to the host form (masks a real design error) or inventing values for the missing variable.
- **Right:** Audit every `:$.X` in the copied body against `FORMCLMNS WHERE FORM = <host-id>`. If the column isn't on the host, either (1) delete the trigger if it's scratch (it often travels in packs — expect 2-3 more on the same form), or (2) rewrite the body to reference host columns. `#INCLUDE` from a donor form requires the donor to be parametric, not column-specific.
- **See:** `compile-debugging.md` § "Class 2. Variable `:$.COL` 'not a form column'", § "Class 5. Broken `#INCLUDE FORM/COL/STEP`".

### Using WebSDK `deleteRow` to remove a trigger with text under it
- **Symptom:** `EFORM → FTRIG setActiveRow → deleteRow` fails with `ערך קיים במסך 'הפעלות המסך - שאילתות SQL'` (record exists in 'Form Triggers — SQL Queries'). Agent then tries `startSubForm FSTEP` (not a real subform name) and gets `Can't find Sub Form`.
- **Root cause:** The trigger has `FORMTRIGTEXT` rows under it. The step subform name is not `FSTEP`; it's typically the text subform reachable only by peel navigation, and the peel may not always succeed via WebSDK.
- **Wrong:** Guessing subform names (`FSTEP`, `FTRIGTEXT`, `FORMTRIGSTEPS`). Giving up and telling the user to delete via the UI.
- **Right:** Cascade via SQLI on form-metadata tables. These tables don't fire business triggers, so raw DELETE is safe (project rule: "Form interface > raw UPDATE/INSERT" still applies — get explicit approval first, and show row counts before the DELETE):
  ```sql
  DELETE FROM FORMTRIGTEXT WHERE FORM = <FID> AND TRIG = <TID>;
  DELETE FROM FORMTRIG     WHERE FORM = <FID> AND TRIG = <TID>;
  ```
  For column triggers: substitute `FORMCLTRIGTEXT` / `FORMCLTRIG` and scope by `NAME` too. For full form deletion see `compile-debugging.md` § "Cascade-deleting a form".
- **See:** `compile-debugging.md` § "Peel-or-cascade decision", `websdk-cookbook.md` § "Known bridge behaviors".

### Form returns N duplicate rows per logical record
- **Symptom:** Parent form filter returns many copies of the same record (e.g., `IVNUM=T396` → 299 rows); base table has 1 row; a sibling form on the same base table returns 1 row correctly.
- **Wrong:** Chase the base table, joins, or trigger logic first.
- **Right:** Scan FORMCLMNS on the parent form AND every sub-level form for:
  1. Private-dev imported columns (`IDCOLUMN >= 5`, `JOIN > 0`, `EXPRESSION` blank) whose `(IDJOIN, COLUMN)` pair collides with an existing base-form join instance — private-dev imports must use `IDJOIN >= 6` (see `forms.md` § "Multiple Joins"). Collisions compile to a defective join graph that cartesian-multiplies.
  2. Sub-level EXPRESSION columns (`EXPRESSION=Y`) whose body references a parent-form column that was recently removed or renamed (dangling `:$$.<COL>`). Also check `FORMCLTRIGTEXT` for `:$<COL>` references.
- **Fix:** DELETE the offending FORMCLMNS rows on both parent and sub-level, then `priority.prepareForm` both. Confirm via `FORMPREPERRS` getRows.
- **See:** `docs/solutions/database-issues/priority-form-row-duplication-astr-chain-2026-04-20.md`, `forms.md` § "Multiple Joins".

### Relying on `runSqliFile` / `executeDbi` with a specific `entityName`
- **Wrong:** These run the currently active VSCode editor tab regardless; `entityName` is logging only. Stale content may run if VSCode hasn't reloaded. Fails outright with `Expected an .pq file` when the active editor isn't a .pq (bridge log shows this hitting 9×/6× per week).
- **Right:** Use `run_inline_sqli` (`mode="sqli"` or `mode="dbi"`) — direct WCF, no active-editor dependency, zero logged failures.
- **See:** `websdk-cookbook.md` § "Known bridge behaviors" → "`runSqliFile` / `executeDbi` active-editor". Part of the broader anti-pattern — see § "Reaching for `run_windbi_command` dump/search commands for inspection" above.

### `SELECT` via `run_inline_sqli` prints no rows ("Execution ok" with nothing)
- **Symptom:** `run_inline_sqli({ sql: "SELECT ENAME FROM EXEC WHERE ENAME = 'FOO'" })` returns success with zero visible rows — then the next agent retries the query 5 different ways, guessing the entity must not exist.
- **Wrong:** Assuming the row isn't there; varying syntax, adding LIKE, switching tables.
- **Right:** Always append `FORMAT;` (or `TABS;` / `DATA;`) to print rows. SQLI's `SELECT` without an output clause executes and discards. This is documented as a SQL extension in `sql-core.md` § "Output Formats for SELECT" but is a repeat offender in practice.
  ```sql
  SELECT ENAME, TITLE, TYPE FROM EXEC WHERE ENAME = 'FOO' FORMAT;
  ```
- **See:** `sql-core.md` § "Output Formats for SELECT".

### Hand-rebuilding a procedure / report / form / interface instead of using COPY*
- **Symptom:** User says "duplicate BOAZ_CALC_MANUFACTUR" → agent starts with `INSERT INTO EXEC (...) VALUES (...)` then tries to reconstruct steps / parameters / triggers one at a time. Iterates for dozens of tool calls and still misses targets and hidden metadata.
- **Wrong:** DIY reconstruction. Priority's copier carries metadata that FOREIGN KEY joins and trigger tables don't surface through introspection.
- **Right:** Invoke the matching built-in copier via the bridge's `copyEntity` compound op:
  ```json
  {"operations": [{"op": "copyEntity", "kind": "proc", "source": "<SOURCE>", "target": "<TARGET>"}]}
  ```
  `kind` = `"proc"` / `"report"` / `"form"` / `"interface"` → runs `COPYPROG` / `COPYREP` / `COPYFORM` / `COPYINTER`. No `form` parameter — the compound drives `priority.procStart` directly.
- **See:** `procedures.md` § "Copying existing entities (COPYPROG / COPYREP / COPYFORM / COPYINTER)".

### Driving COPY* manually by sending source and target in two separate inputFields calls
- **Symptom:** After `proc.proc.inputFields(1, { EditFields: [{field:1, value:'<SOURCE>'}]})` the proc returns `type='message'` ("הכנס שם לפרוצדורה החדשה" / "Enter new name"). Calling `continueProc` lands on `type='end'` with no copy made. Calling a second `inputFields` returns `type='message'` / messagetype='error' "הפרוצדורה הנוכחית אינה פעילה יותר" ("current procedure is no longer active").
- **Wrong:** Treating source and target as two sequential input steps.
- **Right:** Send **both** fields in a single `inputFields` call — COPY* procs define source as field 1 and target as field 2 within the same step:
  ```js
  proc = await proc.proc.inputFields(1, { EditFields: [
    { field: 1, op: 0, value: '<SOURCE>', op2: 0, value2: '' },
    { field: 2, op: 0, value: '<TARGET>', op2: 0, value2: '' },
  ]});
  ```
  The subsequent `message` (messagetype `information` = success) arrives after the copy has already landed server-side.
- **See:** `procedures.md` § "The subtle inputFields gotcha", `bridge/src/websdk/compounds.ts` → `generateCopyEntityScript`.

### Unfiltered `getRows` returns empty on a busy form (EPROG / EFORM / EREP / EINTER)
- **Symptom:** Even `{"form":"EPROG","operations":[{"op":"getRows","top":5}]}` with no filter returns `{}`. Since the form universally has rows (EPROG lists every procedure on the tenant), this is not a filter issue.
- **Wrong:** Trying more filter variants, mutating field/value, blaming the record's ENAME width, or chasing a hallucinated `activateByName` op.
- **Right:** This is a bridge **session or tenant** problem — one of:
  1. The bridge is authenticated to a different company than the user's UI. Read the trace line `[websdk] Logging in to url=... company=<X> tabulaini=... language=<N> user=<U>` and cross-check with the user. Compare timestamps of `priority.selectAllRowsFromTable` on a known table with what the user sees in their UI — a "stale" or "empty" result is a tenant-mismatch signal.
  2. The bridge login failed mid-session. Re-run any operation — the bridge re-authenticates on every child script call; if the stored credentials are wrong / expired / have no privileges, every op returns empty.
  3. The authenticated user has no privilege on that form. Ask the user to verify the bridge's username has access in their Priority client.
- **See:** `common-mistakes.md` § "Debugging across tenants without verifying bridge connection", memory `feedback_verify_bridge_tenant_before_debug.md`.

### Trusting a subagent summary that reports `Done (0 tool uses · N tokens)`
- **Symptom:** A subagent (`priority-dev:researcher` / `builder` / `verifier`) returns a confident success summary ("procedure copied successfully, EXEC ID 690, title ..."), but the tool-use count in its completion line is **0**. The main agent treats the summary as truth and reports success to the user — who then says "I don't see it."
- **Wrong:** Believing subagent text without checking it made any calls. A subagent that made zero tool calls cannot have created, modified, or verified anything — the summary is hallucinated structure.
- **Right:** If you see `Done (0 tool uses · ...)`, treat the subagent output as **unverified** and re-run the relevant verification step yourself — typically a direct `run_inline_sqli` against EXEC or a `websdk_form_action getRows` — before claiming success. Prefer direct bridge calls for operations that must land (copy / create / delete); subagents are fine for read-only research but still need ground-truth verification when a write was expected.

### `filter` op returns empty for a record that definitely exists in EXEC
- **Symptom:** `SELECT ENAME FROM EXEC WHERE ENAME = 'BOAZ_CALC_MANUFACTUR' FORMAT;` returns the row, but `websdk_form_action form:"EPROG", {"op":"filter", ...} + getRows` returns `{}`. Agent then iterates trying `activateByName` (hallucinated) and other invented ops, or concludes the bridge is pointed at the wrong tenant.
- **Root cause (almost always):** param-name typo. The `filter` op requires `field` — `{"op":"filter","field":"ENAME","value":"..."}`. Using `name` instead (`{"op":"filter","name":"ENAME","value":"..."}`) passes `op.field === undefined` to `setSearchFilter`, which silently matches nothing. This is the same class of bug as `startSubForm subform` vs `name`. The bridge does not validate unknown keys — it just reads the ones it expects.
- **Wrong:** Using `name` in a `filter` op. Invoking `activateByName` — not a real bridge op or priority-web-sdk method, any apparent "success" is a mislabeled `search`/`choose` call in a subagent summary.
- **Right:**
  1. Use `field` in `filter` ops — never `name`. Confirm via `websdk-cookbook.md` § "Operation Property Reference".
  2. If you must verify existence before navigating, run `SELECT ENAME, TITLE, TYPE FROM EXEC WHERE ENAME = '<name>' FORMAT;` — EXEC is the authoritative existence check across scopes.
  3. If `filter` with the correct `field` still returns empty, fall back to `{"op":"search","field":"ENAME","value":"..."}` — it maps to `currentForm().choose()`, a broader picker-style lookup that bypasses the form's client-side ACCEPT scoping (`filter` uses `setSearchFilter`, which respects it).
  4. For *copying* an entity, skip navigation entirely — use the `copyEntity` compound op, which drives `procStart` on COPYPROG/COPYREP/COPYFORM/COPYINTER directly and doesn't need the source to be visible on any generator form.
- **See:** `websdk-cookbook.md` § "Operation Property Reference" and § "`filter` vs `search` on generator forms", `procedures.md` § "Copying existing entities".

### Filtering EFORM by `DNAME` / `TYPE`, or chaining `filter` ops expecting AND
- **Symptom 1:** `{"op":"filter","field":"DNAME","value":"%קבלות%","operator":"LIKE"}` on EFORM returns `Invalid filter`. Same for `TYPE`.
- **Symptom 2:** Chaining two `filter` ops on EFORM (`filter TITLE %a%` + `filter TITLE %b%`) returns rows containing only `b` — the second filter REPLACED the first.
- **Wrong:** Trying more operators on `DNAME`/`TYPE`, or trusting that sequential `filter` ops AND together. Verified twice in opposite order on 2026-04-23: order matters because the LAST filter wins, not because they compose.
- **Right:**
  1. For partial title or name lookup on **forms**, use `EFORM filter(TITLE, "%fragment%", LIKE)` or `filter(ENAME, "%FRAG%", LIKE)` — both work as a single filter.
  2. For **non-contiguous words** (AND-of-LIKEs), or for **all entity types** in one call (forms + procs + reports + tables), use SQLI on `EXEC`:
     ```sql
     SELECT ENAME, TITLE, TYPE FROM EXEC
     WHERE TITLE LIKE '%w1%' AND TITLE LIKE '%w2%'
     ORDER BY TYPE, ENAME FORMAT;
     ```
  3. Do NOT query `ENGLISH`, `ENGLISH1`, `TABCLMNS`, `SYSTBL`, `SYS.TABLES` — none are legal table names in Priority. EXEC is the canonical entity registry.
- **See:** `websdk-cookbook.md` § "Entity discovery (forms, procedures, reports, tables)".

### Guessing the generator-form ENAME (e.g., `EPROC`, `EREPGEN`)
- **Symptom:** WebSDK `formStart` fails with `אין מסך בשם זה` (no such form).
- **Wrong:** Guessing from the entity type — `EPROC` for procedures, `EREPGEN` for reports, `EINTERFACE` for interfaces. None of these exist.
- **Right:** The canonical generator-form ENAMEs are:
  | Entity      | Generator form |
  |-------------|----------------|
  | Procedure   | `EPROG` (mislabeled as `EPROC` elsewhere) |
  | Report      | `EREP`  |
  | Form        | `EFORM` |
  | Interface   | `EINTER` |
  Verify at any time with `SELECT ENAME, TITLE FROM EXEC WHERE TYPE = 'F' AND TITLE LIKE '%מחולל%' FORMAT;`.
- **See:** `websdk-cookbook.md` § "Canonical generator-form names".
