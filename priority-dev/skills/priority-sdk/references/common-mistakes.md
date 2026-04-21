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

### Writing a scalar subquery in `FCLMNA.EXPR`
- **Wrong:** Parser rejects `SELECT` in an expression with `parse error at or near symbol SELECT`.
- **Right:** Use a real join (imported column from joined table) or a POST-UPDATE trigger that assigns the computed value.
- **See:** `forms.md` § "Managing forms and columns via WebSDK" → "Setting a column expression".

### Using `||` for string concatenation in `FCLMNA.EXPR`
- **Wrong:** `SOMETABLE.COL || ''` fails to compile — `||` is boolean OR in Priority expressions, not concat.
- **Right:** Use ternary (`cond ? a : b`) with implicit concat inside branches, or `STRCAT` in a trigger.
- **See:** `forms.md` § "Managing forms and columns via WebSDK".

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

### Trusting FORMPREPERRS as authoritative compile status
- **Wrong:** Entries accumulate across compile attempts; "Could not read ERRMSGS" reports the same whether current compile succeeded or failed.
- **Right:** Use the bridge's `prepareForm` status + a post-compile `getRows` on the form itself. **But:** when `prepareForm` *fails* with a compile error, `FORMPREPERRS` content IS authoritative for that failure — it names the form, column, and trigger/EXPR step precisely (e.g. `AINVOICEITEMS/ASTR_QPRICEN/EXPR` pointing at a dangling `$ASTR_EXCHANGE3`). Read it once immediately after a failing compile.
- **See:** `triggers.md` § "FORMPREPERRS accumulates stale errors", `forms.md` § "Sub-level EXPR column referencing a parent column".

### Form returns N duplicate rows per logical record
- **Symptom:** Parent form filter returns many copies of the same record (e.g., `IVNUM=T396` → 299 rows); base table has 1 row; a sibling form on the same base table returns 1 row correctly.
- **Wrong:** Chase the base table, joins, or trigger logic first.
- **Right:** Scan FORMCLMNS on the parent form AND every sub-level form for:
  1. Private-dev imported columns (`IDCOLUMN >= 5`, `JOIN > 0`, `EXPRESSION` blank) whose `(IDJOIN, COLUMN)` pair collides with an existing base-form join instance — private-dev imports must use `IDJOIN >= 6` (see `forms.md` § "Multiple Joins"). Collisions compile to a defective join graph that cartesian-multiplies.
  2. Sub-level EXPRESSION columns (`EXPRESSION=Y`) whose body references a parent-form column that was recently removed or renamed (dangling `:$$.<COL>`). Also check `FORMCLTRIGTEXT` for `:$<COL>` references.
- **Fix:** DELETE the offending FORMCLMNS rows on both parent and sub-level, then `priority.prepareForm` both. Confirm via `FORMPREPERRS` getRows.
- **See:** `docs/solutions/database-issues/priority-form-row-duplication-astr-chain-2026-04-20.md`, `forms.md` § "Multiple Joins".

### Relying on `runSqliFile` / `executeDbi` with a specific `entityName`
- **Wrong:** These run the currently active VSCode editor tab regardless; `entityName` is logging only. Stale content may run if VSCode hasn't reloaded.
- **Right:** Use `run_inline_sqli` — direct WCF, no active-editor dependency.
- **See:** `websdk-cookbook.md` § "Known bridge behaviors" → "`runSqliFile` / `executeDbi` active-editor".

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
