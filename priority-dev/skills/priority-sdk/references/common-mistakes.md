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
- **Right:** Use the bridge's `prepareForm` status + a post-compile `getRows` on the form itself.
- **See:** `triggers.md` § "FORMPREPERRS accumulates stale errors".

### Relying on `runSqliFile` / `executeDbi` with a specific `entityName`
- **Wrong:** These run the currently active VSCode editor tab regardless; `entityName` is logging only. Stale content may run if VSCode hasn't reloaded.
- **Right:** Use `run_inline_sqli` — direct WCF, no active-editor dependency.
- **See:** `websdk-cookbook.md` § "Known bridge behaviors" → "`runSqliFile` / `executeDbi` active-editor".
