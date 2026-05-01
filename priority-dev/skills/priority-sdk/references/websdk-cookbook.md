# WebSDK Cookbook — Tested Patterns

> Copy-paste-ready operation chains for `websdk_form_action`. Verified against a live Priority server. Last updated 2026-04-12.

## What Works vs What Doesn't

| Operation | Works? | Notes |
|-----------|--------|-------|
| `filter` → `setActiveRow` → `startSubForm` | **Yes** | Subform opens correctly |
| `fieldUpdate` → `saveRow` on subforms | **Yes** | Works on EFORM subforms including HIDEBOOL |
| `newRow` → `fieldUpdate` → `saveRow` | **Yes** | Creating new rows in subforms works |
| `getRows` on root form | **Yes** | Returns row data (must filter first) |
| `getRows` on business subforms | **Yes** | Works on regular subforms (e.g., UPGNOTES, ORDERITEMS) with `getRows(1)` |
| `getRows` on EFORM subforms (FCLMN) | **No** | EFORM's FCLMN subform returns `{}` — use SQLI on FORMCLMNS instead |
| `deleteRow` on subforms | **Yes** | Works after filter + setActiveRow |
| `compile` (compound) | **Yes** | Returns status directly |

**Rule of thumb:**
- **Single record read/write:** WebSDK — `filter` first, then `getRows(1)` or `fieldUpdate`/`saveRow`
- **Multi-record reads with subforms:** OData with `$expand` (one call vs N×open/read/close SDK round-trips)
- **EFORM metadata reads (columns, triggers):** SQLI on system tables (FORMCLMNS, FORMTRIG, FORMCLTRIGTEXT) — EFORM's FCLMN subform returns `{}` via getRows
- **EFORM metadata writes (add column, set expression, hide):** WebSDK works — fieldUpdate + saveRow persists

### VSIX installation note

Do NOT use `code --install-extension` — it opens a new VSCode window. Instead, install from within VSCode: `Ctrl+Shift+P` → "Extensions: Install from VSIX..." → select file → Reload Window.

---

## Operation Property Reference

Each operation in the `operations` array requires `op` plus operation-specific properties. The bridge reads these exact property names — using the wrong name silently passes `undefined`.

| op | Required properties | Optional |
|----|-------------------|----------|
| `filter` | `field`, `value` | `operator` (default `=`; supports `LIKE`, `>=`, `<=`, `!=`) |
| `clearFilter` | *(none)* | |
| `getRows` | | `fromRow` (1-based starting position, default 1). Also accepts legacy `count` as alias. |
| `setActiveRow` | `row` (1-based) | |
| `newRow` | *(none)* | |
| `fieldUpdate` | `field`, `value` | |
| `saveRow` | *(none)* | |
| `deleteRow` | *(none)* | |
| `undoRow` | *(none)* | |
| `startSubForm` | `name` | |
| `endSubForm` | *(none)* | |
| `activateStart` | `name`, `type` | |
| `search` | `field`, `value` | |
| `warningConfirm` | *(none)* | |
| `infoMsgConfirm` | *(none)* | |

### Trigger messages are surfaced on op results

`newRow`, `fieldUpdate`, `saveRow`, and `deleteRow` capture WRNMSG / PRINT / ERRMSG fired by form and column triggers. Inspect each op's result:

- `result.status === 'warning'` + `result.warning` → a WRNMSG fired (auto-confirmed, chain continues). Read it to understand why the form is objecting before the next op runs.
- `result.info` → a PRINT / ENTMESSAGE fired (auto-confirmed). Useful for diagnostic output from POST-INSERT / POST-UPDATE.
- `result.status === 'error'` + `result.error` → an ERRMSG blocked the op. Do not continue the chain blindly — read the text and adjust.

When an insert/update/delete misbehaves, scan the results array for these fields *before* assuming the change landed — the trigger message usually explains the missing prerequisite or validation failure.

### Critical: `startSubForm` uses `name`, not `subform`

```json
{"op": "startSubForm", "name": "FCLMN"}
```

Wrong (silently fails with "Can't find Sub Form: undefined"):
```json
{"op": "startSubForm", "subform": "FCLMN"}
```

### Critical: `filter` uses `field`, not `name`

```json
{"op": "filter", "field": "ENAME", "value": "MY_PROC"}
```

Wrong — filter silently matches nothing (the bridge passes `op.field === undefined` to `setSearchFilter`), and the next `getRows` returns `{}` even when the record exists:
```json
{"op": "filter", "name": "ENAME", "value": "MY_PROC"}
```

This is the single most common cause of "I can see the record in the Priority UI / `SELECT FROM EXEC`, but the bridge can't find it." Do not conclude the bridge is pointed at a different tenant until you've confirmed the `filter` op uses `field`.

### Subform names: no `_SUBFORM` suffix

WebSDK uses bare subform names. The `_SUBFORM` suffix is an OData URL convention — do not use it with `startSubForm`.

| Correct (WebSDK) | Wrong (OData convention) |
|-------------------|--------------------------|
| `FCLMN` | `FCLMN_SUBFORM` |
| `FCLMNA` | `FCLMNA_SUBFORM` |
| `FLINK` | `FLINK_SUBFORM` |
| `FTRIG` | `FTRIG_SUBFORM` |
| `UPGNOTES` | `UPGNOTES_SUBFORM` |
| `FORMCLTRIG` | `FORMCLTRIG_SUBFORM` |
| `FCLMNTEXT` | `FCLMNTEXT_SUBFORM` |

---

## Known bridge behaviors

Internal details of how the VSCode bridge implements WebSDK calls. These are failure modes of the bridge itself, not of the Priority WebSDK — treat them as the current contract.

### `filter` primitive — `setSearchFilter` + `QueryValues`

The bridge's `filter` primitive calls `setSearchFilter` with the `QueryValues` format. `setSearch` does not exist in the WebSDK.

```js
{
  or: 0,
  ignorecase: 1,
  QueryValues: [
    { field, fromval, toval: '', op: '=', sort: 0, isdesc: 0 }
  ]
}
```

The compound tool requires `getRows` between `filter` and `setActiveRow` so the SDK materialises the row count. Without it, writes land on the wrong parent (EFORM's own meta-form). Use primitives (`filter` → `getRows` → `setActiveRow` → `startSubForm` …), not the compound `createTrigger`.

### `runSqliFile` / `executeDbi` run the active editor tab

Both operations run whichever file is active in the VSCode editor, regardless of the `entityName` argument. `entityName` is logging only. If the bridge writes a `.pq` file via `Write` or `Edit`, VSCode may not reload from disk and the stale content runs.

Prefer `run_inline_sqli` (direct WCF, no active-editor dependency) for all SQLI and DBI snippets.

### `newRow` on FORMCLTRIGTEXT (and other deeply nested subforms) silently appends

`newRow` on FORMCLTRIGTEXT does not replace existing rows — it appends. Rewriting a column trigger via repeated `newRow` produces duplicate lines that Priority concatenates at runtime and silently skips as broken SQL. `getRows` on FORMCLTRIGTEXT often returns `{}` even when rows exist.

For rewrites, use DBI `DELETE + INSERT` via `run_inline_sqli(mode="dbi")`. See the text-subform recipe (Call 5) for the canonical pattern.

### `FCLMNA.EXPR` is scalar-only

`FCLMNA.EXPR` does not accept scalar subqueries. `(SELECT … WHERE …)` fails with `parse error at or near symbol SELECT`. Use a real join (imported column from joined table) or a POST-UPDATE trigger that assigns the computed value.

### FORMPREPERRS — overwrites per compile, but state persists across sessions

FORMPREPERRS exists and can be read via WebSDK. Each compile **overwrites/refills** it with that compile's errors (it auto-shows errors from the last compile — see line ~710 below) — it does NOT additively accumulate within one session. However, entries **persist across sessions** until something rewrites them, so a `getRows` from a fresh session can return stale entries from a prior compile attempt that referenced different line numbers or variable names. Either way: "Could not read ERRMSGS" reports the same way whether the current compile succeeded or failed. Authoritative signal is the bridge's `prepareForm` status + a `getRows` on the form itself, not FORMPREPERRS content. See the detailed pitfall section below.

---

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `startSubForm` with `subform` property | "Can't find Sub Form: undefined" | Use `name` property |
| `startSubForm("FCLMN_SUBFORM")` | "Can't find Sub Form" | Drop the `_SUBFORM` suffix |
| `getRows` on subform without `setActiveRow` first | TypeError: Cannot read 'data' of undefined | Always `setActiveRow(1)` before `getRows` on subforms |
| `getRows` with `fromRow: 0` | TypeError crash on subforms | Always use `fromRow: 1` (1-based). Old `count` param was actually passed as `fromRow` — `count: 200` meant "start from row 200", not "get 200 rows" |
| `getRows` on EFORM's FCLMN subform | Returns `{}` — EFORM metadata subforms don't return data via getRows | **Use SQLI on FORMCLMNS instead** (see SQLI Metadata Queries below) |
| `filter(ENAME)` on FORMPREPERRS | "Invalid filter" | FORMPREPERRS has no ENAME column — just use `getRows` with no filter (shows last compile's errors) |
| Querying table `FORMCOLUMNS` or `FORMCOL` | "not a legal table name" | The real table is `FORMCLMNS` |
| Using `HIDEBOOL` in raw SQLI on `FORMCLMNS` | "Unresolved identifier" | Context-dependent: in raw SQLI use the physical column `HIDE`; in WebSDK `fieldUpdate` use the EFORM-view alias `HIDEBOOL`. Both are correct in their own surface — see "EFORM alias → real table/column mapping" |
| Using `IDCOLUMNE` in raw SQLI on `FORMCLMNS` | "Unresolved identifier" | Context-dependent: physical `IDCOLUMN` for SQLI, EFORM alias `IDCOLUMNE` for WebSDK `fieldUpdate`. Same pattern: alias for the form layer, real name for the table layer |
| `getRows` without `fromRow` on root form | Returns 0 rows | Always `filter` before `getRows` on root forms. `getRows(1)` is default after fix. |
| `filter` without later `setActiveRow(1)` | Subform operations fail | Always `setActiveRow(1)` after `filter` before navigating |
| `fieldUpdate(IDJOINE, "10")` or higher | `סמן מספר מ-0 עד 9 ובנוסף אפשרי ? או !` | IDJOINE accepts ONLY 0–9 (plus `?` and `!`). Old memory claim of "0–99" was wrong. Re-use numbers across different JTNAMEs if needed — IDJOINE only disambiguates when the same target table appears multiple times |
| `fieldUpdate(JTNAME, "USERSLOGIN")` | `ערך 'USERSLOGIN' לא קיים בעמודה 'טבלת חיתוך'` | Not every plausible table name is a valid JTNAME on every server. Use `EFORM filter(TITLE, "user%", LIKE)` to discover real names, or skip the join and stamp the column from `SQL.USER` in a trigger |
| `fieldUpdate(SUM, "U")` | `Can't find column: SUM` | `SUM` is a FCLMN metadata field not exposed via WebSDK. For autounique, use a PRE-INSERT trigger: `SELECT NVL(MAX(KLINE),0)+1 INTO :$.KLINE FROM <table>;` |

---

## Reading WebSDK errors as step-by-step guidance

Priority's Hebrew error messages follow a strict schema — read them literally, they tell you exactly what's blocking and how to unblock:

| Hebrew message | Translation | What to do |
|---|---|---|
| `ערך קיים במסך 'X'` | "Value exists in form 'X'" | That subform contains rows blocking the current op. Open the subform on the parent EFORM row and deleteRow the blockers (do NOT guess table names for SQL DELETE) |
| `ערך 'Y' לא קיים בעמודה 'Z'` | "Value Y doesn't exist in column Z" | The lookup value you wrote isn't in the dictionary. Use a valid value or remove the reference |
| `סמן מספר מ-0 עד 9 ובנוסף אפשרי ? או !` | "Mark number 0-9, also ? or ! allowed" | The numeric field is constrained to 0–9 |
| `משתנה :$.X בהפעלה Y/ACTION אינו קיים כעמודה במסך` | ":$.X doesn't exist as a column in the form, during Y/ACTION activation" | Some activation references column X which doesn't exist on the form. Either add X, or remove the reference (often in orphan FTRIG/FTRIGTEXT from an abandoned compile) |
| `המסך לא מוכן. להכנת מסך, הפעל את "הכנת מסכים"` | "Form not prepared" | Run `priority.prepareForm` on this form name before any read/write |

### Hebrew subform aliases (what "form X" in the error maps to)

| Hebrew | WebSDK subform | Owns |
|---|---|---|
| עמודות המסך | `FCLMN` | form column metadata |
| מסכי בן | `FLINK` | subform links |
| הפעלות המסך | `FORMEXEC` | direct activations (buttons) |
| הפעלות / טריגרים | `FTRIG` | form-level triggers |
| טקסט הפעלה | `FTRIGTEXT` | trigger body lines |

### Cleanly deleting a form via WebSDK (peel order)

`EFORM deleteRow` refuses while child rows exist. Clear each blocker in order. Each failed delete's Hebrew error tells you which subform comes next:

1. `FORMEXEC` — remove any direct activations on this form
2. `FLINK` — remove subform links in both directions (FATFORM = this form AND SONFORM = this form)
3. `FTRIG` — remove form-level triggers (cascades to FTRIGTEXT automatically)
4. `FCLMN` — remove columns (cascades to FCLMNA/FCLMNTEXT/FORMCLTRIG)
5. `EFORM` → `deleteRow` on the root form row

If listing via `getRows` returns `{}` (known EFORM-subform bridge quirk), either iterate by filtering on discriminator values you know (e.g., `filter(FNAME, "...")` on FLINK) or delegate to the Priority UI — one "Delete Form" click handles the whole cascade, including parts WebSDK can't enumerate (especially orphan FTRIGTEXT from abandoned compiles).

---

## Searching and Filtering

### `filter` vs `search` — two different operations

| Operation | WebSDK method | Purpose | Returns |
|-----------|--------------|---------|---------|
| `filter` | `setSearchFilter()` | Filter **rows** in the form (like SQL WHERE) | Nothing — rows are filtered, then use `getRows` |
| `search` | `choose()` | Open a field's **dropdown/picker** (lookup values) | Option list: `{ retval, string1, string3 }` |

**Do not confuse them.** `filter` narrows down which records appear in the form. `search` gets the list of valid values for a specific field (like clicking the magnifying glass).

### Searching entities by name (LIKE filter)

To find entities by partial name, use `operator: "LIKE"` with `%` wildcards:

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "%ORDER%", "operator": "LIKE"},
    {"op": "getRows"}
  ]
}
```

This finds all forms whose ENAME contains "ORDER" (e.g., ORDERS, ORDERITEMS, PORDERS).

### Filter operators

The `filter` op supports these operators via the `operator` property:

| Operator | Meaning | Example value |
|----------|---------|---------------|
| `=` | Exact match (default) | `"ORDERS"` |
| `LIKE` | Pattern match | `"%ORDER%"` (contains), `"ORDER%"` (starts with) |
| `>=` | Greater than or equal | `"A"` |
| `<=` | Less than or equal | `"Z"` |
| `!=` | Not equal | `"DELETED"` |

### Clearing stale filter state

When re-filtering a form that was already filtered, use `clearFilter` first:

```json
{
  "form": "ORDERS",
  "operations": [
    {"op": "clearFilter"},
    {"op": "filter", "field": "ORDNAME", "value": "SO26000001"},
    {"op": "getRows"}
  ]
}
```

### Entity discovery (forms, procedures, reports, tables)

When you know a Hebrew or English title fragment, partial ENAME, or just a few words from the title — do not guess and do not run repeated probes. Use one of these tested recipes (verified against `lp1378/demo` 2026-04-23).

The canonical entity registry is the **`EXEC`** table — holds `ENAME`, `TITLE`, `TYPE` for all 12,868 entities (forms, procedures, reports, tables, subforms, system types). Filterable directly via SQLI.

**By title fragment (forms only, WebSDK):**

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "TITLE", "value": "%קבלות%", "operator": "LIKE"},
    {"op": "getRows"}
  ]
}
```

**By non-contiguous words — AND together (SQLI on EXEC, the ONLY working path):**

WebSDK `filter` ops **REPLACE** each other — only the LAST applies. Verified twice in opposite order: `[%קבלות%, %סחורה%]` returned 19 rows containing only "סחורה"; `[%סחורה%, %קבלות%]` returned 23 rows containing only "קבלות". There is no AND-chain primitive in WebSDK. Use SQLI:

```sql
SELECT ENAME, TITLE, TYPE FROM EXEC
WHERE TITLE LIKE '%קבלות%' AND TITLE LIKE '%סחורה%'
ORDER BY TYPE, ENAME FORMAT;
```

Returns 6 rows when both words are present in any order, any position.

**By title fragment — all entity types (SQLI on EXEC):**

Returns forms, procedures, reports, tables, subforms in one call.

```sql
SELECT ENAME, TITLE, TYPE FROM EXEC
WHERE TITLE LIKE '%קבלות%' FORMAT;
```

`TYPE` values: `F` form, `P` procedure, `R` report, `S` subform, `T` table, plus system types A–M.

**By partial ENAME:**

```sql
SELECT ENAME, TITLE, TYPE FROM EXEC
WHERE ENAME LIKE '%DOC%' FORMAT;
```

SQLI `LIKE` on ENAME is case-sensitive — use uppercase. WebSDK `filter(ENAME, ..., LIKE)` is case-insensitive.

**Caveats:**

- `EFORM filter(DNAME, ..., LIKE)` returns "Invalid filter" — DNAME is not LIKE-able via the bridge. Use TITLE or query EXEC.
- `EFORM filter(TYPE, ..., =)` returns "Invalid filter" — filter by entity type via SQLI on EXEC.
- **WebSDK `filter` ops REPLACE each other** — only the LAST filter applies. There is no AND-chain primitive. For AND-of-LIKEs (non-contiguous words), use SQLI on EXEC.
- TITLE column is RCHAR(32) — long titles are truncated; very long-titled entities may not match a fragment from the truncated tail.
- For OR semantics across two patterns, use SQLI: `WHERE TITLE LIKE '%a%' OR TITLE LIKE '%b%'`.
- `ENGLISH` / `ENGLISH1` / `TABCLMNS` / `SYSTBL` / `SYS.TABLES` are NOT legal table names in Priority — do not query them.

### Using `search` to look up field values

The `search` op calls `choose()` on a field — returns the valid values the user can pick from:

```json
{
  "form": "ORDERS",
  "operations": [
    {"op": "newRow"},
    {"op": "search", "field": "CUSTNAME", "value": "ACM"}
  ]
}
```

Returns: `{ Search: { ChooseLine: [{ retval: "ACM001", string1: "Acme Corp", string3: "..." }, ...], next: 1 } }`

- `retval` = the value to use in `fieldUpdate`
- `string1` = display text (in procedures) or same as retval (in forms)
- `string3` = description (in forms — often the meaningful label)
- `next: 1` = more pages available (call `searchAction` to get them)

**Important:** `choose()` requires a **new row or active editable row** context. On readonly rows it fails. The Gateway pattern: `newRow()` first, then `choose()`.

---

## Recipes

### Read all columns of a form

**Use SQLI** — WebSDK `getRows` on EFORM subforms returns empty `{}`. Query `FORMCLMNS` directly via `run_inline_sqli`:

```sql
SELECT FC.NAME, FC.POS, FC.HIDE, FC.READONLY,
  FC.IDCOLUMN, FC.EXPRESSION
FROM FORMCLMNS FC
WHERE FC.FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
ORDER BY FC.POS
FORMAT;
```

Note: `HIDE` = "H" means hidden (EFORM shows this as `HIDEBOOL=Y`).

### Hide a column

**WebSDK** — `fieldUpdate(HIDEBOOL, "Y")` + `saveRow` persists correctly (verified 2026-04-12):

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "filter", "field": "NAME", "value": "COL_NAME"},
    {"op": "setActiveRow", "row": 1},
    {"op": "fieldUpdate", "field": "HIDEBOOL", "value": "Y"},
    {"op": "saveRow"}
  ]
}
```

To unhide: `"value": ""`. For bulk hide, repeat the filter+setActiveRow+fieldUpdate+saveRow block per column.

**Alternative (SQLI)** — useful for hiding multiple columns in one shot:

```sql
UPDATE FORMCLMNS SET HIDE = 'H'
WHERE FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
AND NAME IN ('COL1', 'COL2');
```

To unhide: `SET HIDE = ''`.

**Always recompile after hiding columns:**
```json
{"operations": [{"op": "compile", "entity": "MY_FORM"}]}
```

### Add a column to a form

**CRITICAL:** Always include `getRows` between `filter` and `setActiveRow`. Without it, `setActiveRow(1)` doesn't scope to the filtered set and `newRow` on the subform lands on EFORM's own meta-form (EXEC=9061) with no error — silent parent-scoping failure.

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "getRows", "fromRow": 1},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "NAME", "value": "COL_NAME"},
    {"op": "fieldUpdate", "field": "CNAME", "value": "COL_NAME"},
    {"op": "fieldUpdate", "field": "TNAME", "value": "TABLE_NAME"},
    {"op": "fieldUpdate", "field": "POS", "value": "100"},
    {"op": "saveRow"}
  ]
}
```

For hidden columns add `{"op": "fieldUpdate", "field": "HIDEBOOL", "value": "Y"}` before saveRow.

**`IDCOLUMNE` value depends on the form's base table — not on the column's prefix.**
- **Custom-table form** (form's `TNAME` is `SOF_*`, `ASTR_*`, etc.): use `IDCOLUMNE = 0`. Matches what every other column on the form already has.
- **System-table form** (form's `TNAME` is `INVOICES`, `DOCUMENTS`, `ORDERS`, etc.): use `IDCOLUMNE >= 6`. `0` is reserved for system columns.
- Setting `IDCOLUMNE = 6` on a custom-table form with no join target compiles fine but breaks data entry: Priority treats the column as an "imported instance" and rejects every value with `ערך 'X' לא קיים בעמודה ...` ("value X does not exist in column"). Verified 2026-04-25 on `SOF_CUSTSIGN.REMARKS`.

**For CHAR(1) Y/N columns that should render as a checkbox in the web client**, add `{"op": "fieldUpdate", "field": "BOOLEAN", "value": "Y"}`. Without this, the column displays as a 1-character text input. Verified 2026-04-15.

Verify via direct SQL after save:
```sql
SELECT FORM, NAME, POS FROM FORMCLMNS WHERE NAME = 'COL_NAME';
```
`FORM` must equal the target form's EXEC id (e.g., `4351` for ACCOUNTS_PAYABLE), NOT `9061` (EFORM itself). If you see `9061`, the `getRows` step was missing.

### Add a column with a join (foreign key)

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "NAME", "value": "BASE_COL"},
    {"op": "fieldUpdate", "field": "CNAME", "value": "BASE_COL"},
    {"op": "fieldUpdate", "field": "TNAME", "value": "BASE_TABLE"},
    {"op": "fieldUpdate", "field": "POS", "value": "70"},
    {"op": "fieldUpdate", "field": "JTNAME", "value": "JOIN_TABLE"},
    {"op": "fieldUpdate", "field": "JCNAME", "value": "JOIN_COL"},
    {"op": "saveRow"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "NAME", "value": "DISPLAY_COL"},
    {"op": "fieldUpdate", "field": "CNAME", "value": "DISPLAY_COL"},
    {"op": "fieldUpdate", "field": "TNAME", "value": "JOIN_TABLE"},
    {"op": "fieldUpdate", "field": "POS", "value": "80"},
    {"op": "fieldUpdate", "field": "READONLY", "value": "R"},
    {"op": "saveRow"}
  ]
}
```

Join info (JTNAME, JCNAME) goes on the **base table column row**, not on the imported column row.

### Set a column expression

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "filter", "field": "NAME", "value": "COL_NAME"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMNA"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "EXPR", "value": ":$$.KLINE"},
    {"op": "saveRow"}
  ]
}
```

EXPR is max 56 chars. For longer expressions, add continuation via FCLMNTEXT:

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "filter", "field": "NAME", "value": "COL_NAME"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMNA"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMNTEXT"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "TEXT", "value": "continuation text here"},
    {"op": "saveRow"}
  ]
}
```

### Create a new root form on a custom table

**Confirmed 2026-04-17** — raw WebSDK root-form creation works for flat forms on existing custom (SOF_/ASTR_ prefix) tables. Older memory suggested the UI-only rule; it was too broad.

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "ENAME",      "value": "SOF_MYFORM"},
    {"op": "fieldUpdate", "field": "TITLE",      "value": "כותרת בעברית"},
    {"op": "fieldUpdate", "field": "TNAME",      "value": "SOF_MYTABLE"},
    {"op": "fieldUpdate", "field": "EDES",       "value": "SOF"},
    {"op": "fieldUpdate", "field": "MODULENAME", "value": "פיתוח פרטי"},
    {"op": "saveRow"}
  ]
}
```

**EFORM field aliases** (WebSDK view):
- `TITLE` — Hebrew title (NOT `ETITLE`)
- `MODULENAME` — Hebrew module (NOT `DNAME`). For SoftSolutions custom: `'פיתוח פרטי'`
- `EDES` — entity group. For SoftSolutions custom forms: `'SOF'`

**Auto-seed gift** — when `saveRow` commits an EFORM row with `TNAME` set, Priority **auto-populates FCLMN** with every column of the named table at POS 10/20/30... So for a simple table-form you don't add columns manually — just adjust the seeded ones (COLTITLE, HIDEBOOL, BOOLEAN, etc.).

Known failures where the UI Form Generator is still required:
- Forms on **system** tables (INVOICES, DOCUMENTS, ACCOUNTS) — extra runtime catalog setup needed
- Forms with special `FORMTYPE` (document headers)
- If FORMPREP returns `אין מסך בשם זה` despite a clean EFORM row, compare with a known-good form's FCLMN/FLINK/FTRIG rows side-by-side to find what differs

### Seed a singleton table's first row

When a singleton PRE-INSERT guard is in place, `newRow → saveRow` via
WebSDK will fail on row #1 (the guard rejects it as a "second row" —
see `references/triggers.md` § "Singleton-table PRE-INSERT guard"). Seed
row #1 via raw SQLI, then update content columns through the form:

**Step 1 — seed the identity column via SQLI (bypasses PRE-INSERT intentionally):**
```sql
INSERT INTO TGML_PATHCFG (DUMMY) VALUES (1);
```

This is the only legitimate use of raw INSERT for a singleton: we are
creating row #1, which by definition cannot satisfy a "no other row exists"
guard. PRE-INSERT is bypassed here on purpose.

**Step 2 — update content columns through the form (column triggers still fire):**
```json
[{"op":"filter","field":"DUMMY","value":"1"},
 {"op":"getRows"},
 {"op":"setActiveRow","row":1},
 {"op":"fieldUpdate","field":"BASEPATH","value":"\\\\srv\\share"},
 {"op":"saveRow"}]
```

WebSDK `fieldUpdate + saveRow` still fires POST-FIELD and CHECK-FIELD
on the content columns. This satisfies the "form interface > raw UPDATE"
project rule for columns that carry business meaning.

**Backslash paths**: pass via `fieldUpdate` (the bridge carries the literal
value). Raw SQLI INSERT requires backslash doubling in the string literal
(`'\\\\srv\\share'`); `fieldUpdate` does not.

*(seen in: TGML_PATHCFG singleton seed — verified 2026-05-01)*

### Create a subform + link it to a parent

Subform creation is a **four-step sequence**. FLINK has no parent-key / child-key fields — Priority binds parent↔child by column name convention + FLINK metadata, without any explicit expression on the subform's link column.

```text
/* 1. Create the subform on EFORM — same as root-form creation above */
EFORM → newRow
  ENAME=SOF_MYSUB, TITLE=…, TNAME=SOF_MYSUB, EDES=SOF, MODULENAME=פיתוח פרטי
saveRow
/* FCLMN auto-seeds all columns of SOF_MYSUB */

/* 2. Hide the parent-link column (the FK to the parent). Nothing else. */
EFORM → filter(ENAME, SOF_MYSUB) → setActiveRow(1)
startSubForm(FCLMN)
filter(NAME, PARENTKEY) → setActiveRow(1)
fieldUpdate(HIDEBOOL, Y)   /* may already be Y from auto-seed — idempotent */
saveRow
/* DO NOT set EXPRESSION=Y. DO NOT add any FCLMNA row. See pitfall below. */

/* 3. Wire FLINK on the PARENT form */
EFORM → filter(ENAME, SOF_PARENT) → setActiveRow(1)
startSubForm(FLINK)
newRow
fieldUpdate(FNAME,      SOF_MYSUB)
fieldUpdate(TITLE,      'title shown in parent')
fieldUpdate(APOS,       10)            /* display order */
fieldUpdate(MODULENAME, 'פיתוח פרטי')
saveRow

/* 4. Compile both — raw EFORM newRow does NOT auto-compile */
run_windbi_command  priority.prepareForm  SOF_MYSUB
run_windbi_command  priority.prepareForm  SOF_PARENT
```

**Key fact:** FLINK rows carry only `FNAME / TITLE / APOS / MODULENAME`. No parent-key / child-key columns are exposed. Priority still binds the two forms correctly — the mechanism lives in FLINK internals, not in anything we set.

### ⚠ Pitfall: `:$$.PARENTPK` written as a literal token in `FCLMNA.EXPR` (verified 2026-04-18, reframed 2026-04-25)

**The bug is taking a placeholder literally — not the `:$$` prefix.** `:$$.<col>` is the correct, required way to reference a parent-form column from a subform expression. Real-world examples in the live system: `:$$.SUP`, `:$$.KLINE`, `:$$.SERIAL`, `:$$.FNCTRANS`, `:$$.CURRENCY`, `:$$.CUST`, `:$$.DOC` (see `examples/trigger-examples.sql` lines 44, 88, 112, 183, 446–452, 483).

What broke: an earlier cookbook recipe wrote `:$$.PARENTPK` as if `PARENTPK` were a real column name, when it was meant as a *placeholder* for "your parent's actual primary-key column." Priority then flattens `:$$.PARENTPK` to `:$.PARENTPK` while resolving cross-form activations (the `<PARENT>/DELETE` activation) and tries to resolve `PARENTPK` as a real column on the parent — which doesn't exist:

```
:$.PARENTPK אינו קיים כעמודה במסך בהפעלה <PARENT>/DELETE
(":$.PARENTPK does not exist as a column in the form, during <PARENT>/DELETE activation")
```

**Right way:** substitute the parent's actual key column name. If the parent's primary key is `KLINE`, use `:$$.KLINE`. If it's `ORDNAME`, use `:$$.ORDNAME`. The `:$$.` prefix stays.

If you already added the orphan FCLMNA row from the broken recipe, delete it via raw SQLI before recompiling:

```sql
DELETE FROM FORMCLMNSA WHERE NAME = 'PARENTKEY' AND EXPR = ':$$.PARENTPK';
```

(Run in SQLI mode — `DELETE` is rejected in DBI mode.)

### ⚠ Raw EFORM `newRow` does NOT auto-compile (verified 2026-04-18)

After `newRow/saveRow` on EFORM, the form exists in metadata but is NOT prepared. Any WebSDK attempt to open it fails with `המסך לא מוכן. להכנת מסך, הפעל את "הכנת מסכים"` ("Form not prepared. To prepare, activate 'Form Preparation'."). You MUST explicitly run `run_windbi_command priority.prepareForm entityName=<FORM>`. This applies to root forms AND subforms, every time.

### ⚠ Bridge can't read compile errors when `ERRMSGS` itself isn't prepared

The bridge's `priority.prepareForm` surfaces errors by reading the session-scoped `ERRMSGS` form. If `ERRMSGS` hasn't been prepared on the server, the bridge returns a misleading:

```
Compile failed, could not read ERRMSGS: אין מסך בשם זה
```

This is ambiguous — it could be:
- **A real compile failure** with unreadable details, OR
- **A successful compile** whose reporting channel is broken.

**Distinguish** by running `getRows` on the target form afterward in a separate call:
- Form opens → compile actually succeeded; ignore the "failure" message.
- Form returns `המסך לא מוכן` → compile really failed; need to see the text another way.

### ⚠ Compile-status signals: PREPERRMSGS is authoritative, `compile` op status can lie

There are three places compile errors surface — each with different reliability:

| Source | Reliability | Notes |
|---|---|---|
| `PREPERRMSGS` table (SQLI) | **Authoritative** — reflects the server's current compile state | Query: `SELECT FORMNAME, COLNAME, TRIGNAME, MESSAGE, LINE FROM PREPERRMSGS WHERE FORMNAME = '<X>' OR MAINFORM = '<X>' FORMAT;` |
| `websdk_form_action FORMPREPERRS getRows` | **Stale** — filtered view, can return `{}` even when PREPERRMSGS has errors | UI-facing form; session/user scoped; do not treat `{}` as clean |
| `websdk_form_action compile` compound op | **Can lie** — returned "התכנית הסתיימה בהצלחה" in observed cases while PREPERRMSGS had 2 real errors and `getRows` on the form returned "המסך לא מוכן" | Treat as a hint only, not a confirmation |

**Triangulate — trust `compile` only when BOTH verifications pass:**
1. Run the compile compound op.
2. Query `PREPERRMSGS` via SQLI for rows where `FORMNAME = '<entity>' OR MAINFORM = '<entity>'`. Zero rows = clean.
3. Run `getRows` on the entity via WebSDK. Form opens cleanly = ready. `המסך לא מוכן` = still broken.

If any of (2) or (3) fails, the compile **is not clean** regardless of what the op status said.

*(Observed 2026-04-24 on SOF_INVDOCS: compile op returned success across 3 consecutive attempts while PREPERRMSGS retained the same 2 SUPNAME/CUSTNAME parse errors and the form never opened. The op's success message reflects only the compile driver completing without crashing — it does not reflect whether the produced form artifact is usable.)*

#### FORMPREPERRS staleness (separate pitfall)

Beyond the reliability question above, `FORMPREPERRS getRows` carries entries from the previous compile when nothing has rewritten them — the form is overwritten per compile, but state persists across sessions. So a fresh-session `getRows` can show line numbers or variable names that refer to earlier compile attempts on the same entity. Cross-check each entry against the current buffer before chasing it. Prefer `PREPERRMSGS` SQLI for both freshness and completeness.

When the bridge's compound-op `FORMPREPERRS` fix is installed (patch in `bridge/src/websdk/compounds.ts` uses `FORMPREPERRS` form instead of broken `ERRMSGS` table lookup), this ambiguity improves, but PREPERRMSGS remains the authoritative source.

### Known bridge behavior: session close auto-commits a half-built newRow

If a `newRow` chain is abandoned before `saveRow` — either because an
earlier op returned `status: 'error'` and the chain was aborted, or because
the session closed mid-array — **Priority commits the in-progress row with
whatever column values were set so far (defaulting unset columns to their
table defaults).** This bypasses any PRE-INSERT trigger, because the row
was not committed through the user-facing save path.

Symptom: a stub row appears in the table (e.g., `DUMMY=0` for an INT column
with no default) that should not exist.

Prevention: always append `{"op":"undoRow"}` as the error-branch escape
hatch in any chain that might abort after `newRow` but before `saveRow`.
Never close the session between `newRow` and `saveRow`.

```json
/* Safe chain skeleton */
[{"op":"newRow"},
 {"op":"fieldUpdate","field":"DUMMY","value":1},
 {"op":"fieldUpdate","field":"BASEPATH","value":"\\\\srv\\share"},
 {"op":"saveRow"}]
/* If any op returns error before saveRow, send: */
[{"op":"undoRow"}]
```

*(seen in: TGML_PATHCFG DUMMY=0 stub row — root-caused 2026-05-01;
earlier session had aborted after newRow + wrong fieldUpdate, and the
auto-flush produced a stub that PRE-INSERT never checked.)*

### FCLMNA gap: conditional visibility (COND) not reachable via WebSDK

FCLMNA exposes only `EXPR` via WebSDK. The `COND` / `BIG` field that drives "show column X only when TYPE='C'" is **not accessible**. Workarounds:

- Accept all columns visible (fine for admin/config forms)
- POST-FIELD trigger that programmatically shows/hides columns
- Direct SQLI INSERT into the underlying FORMCLMNSA table (same bypass pattern as `FORMCLTRIGTEXT`)

### Join metadata placement

Join info (`JTNAME`, `JCNAME`, `IDJOINE`) goes on the **base-table FCLMN row**, NOT on the imported display column. Project rule: `IDJOINE` values in custom forms must be `> 5`.

⚠ `IDJOINE` (the EFORM-layer alias) is **`CHAR(1)`**, accepting only `0`–`9`, `?`, or `!` — NOT multi-digit integers. Setting `IDJOINE="10"` via `fieldUpdate` fails with `סמן מספר מ-0 עד 9 ובנוסף אפשרי ? או !`.

The underlying `FORMCLMNS.IDJOIN` column (no trailing E) is `INT width=2` in the raw table schema — but the EFORM UI/WebSDK layer encodes join IDs as single characters. When you see multi-digit values like `10` in a `SELECT FORMCLMNS.IDJOIN` dump, those are integer codes in the raw table; treat them as opaque and only set `IDJOINE` through the EFORM view with 1-char values.

### Add a subform link (generic, minimal)

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "PARENT_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FLINK"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "FNAME", "value": "CHILD_FORM"},
    {"op": "saveRow"}
  ]
}
```

Note: the field is `FNAME` on FLINK (not `ENAME`).

### Create a form-level trigger

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FTRIG"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "TRIGNAME", "value": "PRE-INSERT"},
    {"op": "fieldUpdate", "field": "TYPE", "value": "PRE-INSERT"},
    {"op": "saveRow"}
  ]
}
```

Field is `TRIGNAME` (not `NAME`). After creating the trigger slot, **you must set TDATE before writing code** — see warning below.

**Critical: TDATE=01/01/88 sentinel makes triggers silently inert.** WebSDK `newRow` on FTRIG saves with `TDATE=01/01/88`. A trigger with this sentinel date never fires at runtime, even though `prepareForm` reports success. Always follow the `newRow`/`saveRow` with a TDATE update:

```json
{"form": "EFORM", "operations": [
  {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
  {"op": "getRows"},
  {"op": "setActiveRow", "row": 1},
  {"op": "startSubForm", "name": "FTRIG"},
  {"op": "filter", "field": "TRIGNAME", "value": "PRE-INSERT"},
  {"op": "getRows"},
  {"op": "setActiveRow", "row": 1},
  {"op": "fieldUpdate", "field": "TDATE", "value": "30/04/26"},
  {"op": "saveRow"}
]}
```

Format is `DD/MM/YY`. ISO dates fail with `badDateFormat`. After setting TDATE, write the code via `write_to_editor`.

*(seen in: TGML_CONST PRE-INSERT — verified 2026-04-29; column-level FORMCLTRIG rows are unaffected)*

### Add a direct activation

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FORMEXEC"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "ETYPE", "value": "P"},
    {"op": "fieldUpdate", "field": "RUN", "value": "MY_PROC"},
    {"op": "saveRow"}
  ]
}
```

Set `ETYPE` first ("P" for procedure, "F" for form, "R" for report), then `RUN`.

### Add a custom error/warning message (FORMMSG)

ERRMSG/WRNMSG numbers > 500 must exist in the form's FORMMSG subform before compile. Without the row, compile fails with `"דעה מספר <NUM> (מופיעה בהפעלה ...)"` — the form cannot be prepared.

**FORMMSG is a sub-level of EFORM (not a standalone form).** Opening it directly returns "form not prepared". Always navigate via EFORM.

```json
{"form": "EFORM", "operations": [
  {"op": "filter", "field": "ENAME", "value": "MY_FORM"},
  {"op": "getRows"},
  {"op": "setActiveRow", "row": 1},
  {"op": "startSubForm", "name": "FORMMSG"},
  {"op": "newRow"},
  {"op": "fieldUpdate", "field": "NUM", "value": "502"},
  {"op": "fieldUpdate", "field": "MESSAGE", "value": "Field must be one of A,B,C"},
  {"op": "saveRow"}
]}
```

- `NUM` ≥ 500 (system range 1–499 is reserved).
- Add each message number before compiling any trigger that references it.
- Wrong subform names (will silently fail): `FMSG`, `TRIGMSG`, `MESSAGES`, `FORMMESSAGES`.

*(seen in: TGML_STATIONS OPTIMLINK CHECK-FIELD ERRMSG 502 — verified 2026-04-30)*

### Add a column-level CHOOSE-FIELD trigger

CHOOSE-FIELD on a column provides a short pick-list when the user enters
the field. The navigation path is identical to CHECK-FIELD, only the
TRIGNAME differs.

**Declare the trigger slot:**
```json
[{"op":"filter","field":"ENAME","value":"<FORM>"},
 {"op":"getRows"},
 {"op":"setActiveRow","row":1},
 {"op":"startSubForm","name":"FCLMN"},
 {"op":"filter","field":"NAME","value":"<COL>"},
 {"op":"getRows"},
 {"op":"setActiveRow","row":1},
 {"op":"startSubForm","name":"FORMCLTRIG"},
 {"op":"newRow"},
 {"op":"fieldUpdate","field":"TRIGNAME","value":"CHOOSE-FIELD"},
 {"op":"saveRow"}]
```

**Write body lines (one newRow+fieldUpdate+saveRow per line):**
```json
[{"op":"startSubForm","name":"FORMCLTRIGTEXT"},
 {"op":"newRow"},
 {"op":"fieldUpdate","field":"TEXT","value":"SELECT VAL, CODE FROM MYTABLE WHERE CODE > 0"},
 {"op":"saveRow"}]
```

**Three caveats specific to CHOOSE-FIELD:**

(a) **Each FORMCLTRIGTEXT `saveRow` produces a non-blocking warning**
    `"שאילתת CHOOSE חייבת לכלול תנאי WHERE"` until the full body is
    in place and includes a WHERE clause. This is expected — ignore it
    during incremental writes. Do not add `warningConfirm` ops.

(b) **Column-level triggers do NOT need TDATE bumping.** The TDATE
    sentinel bug (`TDATE=01/01/88`) only affects form-level FTRIG rows.
    FORMCLTRIG saves with a real TDATE automatically. See
    `references/triggers.md` §7 for the full TDATE diagnosis.

(c) **Navigate to the correct column first.** Use `filter NAME + getRows
    + setActiveRow` on FCLMN before `startSubForm FORMCLTRIG`, otherwise
    the trigger slot lands on whichever column is currently active.

*(seen in: TGML_PATHCFG BASEPATH CHOOSE-FIELD — verified end-to-end
task 1.2, 2026-05-01)*

---

### Compile a form

```json
{
  "operations": [{"op": "compile", "entity": "MY_FORM"}]
}
```

No `form` parameter needed — `compile` is a compound operation. Returns `status: 'ok'` on success.

### Read compile errors after compile

FORMPREPERRS has no filterable columns — it auto-shows errors from the last compile. Just `getRows`:

```json
{
  "form": "FORMPREPERRS",
  "operations": [
    {"op": "getRows"}
  ]
}
```

### Find a form's internal ID

Several DBI/SQLI patterns (notably writing column-trigger code into `FORMCLTRIGTEXT`) need the form's numeric `EXEC` ID, not its name:

```sql
SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM' AND TYPE = 'F' FORMAT;
```

`TYPE` is `F` (form), `P` (procedure), `R` (report), or `T` (table). When inserting in bulk you can also embed the lookup as a subquery — see `### Query column-level triggers and their code` below for the pattern.

### `filter` vs `search` on generator forms

| Need | Op | Maps to | Scope |
|------|------|---------|-------|
| Narrow the current form to a known record for navigation | `filter` | `setSearchFilter(...)` | Client-side filter on the visible page — **respects** the form's ACCEPT / visibility conditions, so procs or forms outside your scope return empty. |
| Look up a record that may be outside your visibility scope (picker-style) | `search` | `choose(field, value)` | Broad lookup — can find records `filter` misses. |
| Confirm a record exists at all | neither — use SQLI on `EXEC` | `SELECT ENAME FROM EXEC WHERE ENAME = '<name>' FORMAT;` | Authoritative across scopes. |

**Rule:** treat the generator form as a *UI surface* for acting on records, not as a source-of-truth for whether they exist. `SELECT FROM EXEC` is the existence check. This avoids the failure mode where `filter` returns `{}` for a record that's definitely in EXEC — common on EPROG / EFORM / EREP / EINTER when the proc belongs to a prefix / module you don't own. See `common-mistakes.md` for the specific anti-pattern.

> **Note.** `activateByName` is **not** a real bridge op or priority-web-sdk method. If a previous session claimed it worked, that was likely a mislabeled `search` call in a subagent summary — ignore and use `search` / `SELECT FROM EXEC` per the table above.

### Canonical generator-form names

When opening a Priority generator form with `websdk_form_action`, use the exact ENAME — guessing by prefix (`EPROC`, `EREPGEN`, `EINTERFACE`) yields `אין מסך בשם זה` / "No such form" and wastes iterations.

| Entity you want to work on | Generator form ENAME | Notes |
|----------------------------|----------------------|-------|
| Procedures                 | `EPROG`              | **Not** `EPROC`. Title: מחולל פרוצדורות |
| Reports                    | `EREP`               | **Not** `EREPGEN`. Title: מחולל דו"חות |
| Forms                      | `EFORM`              | Title: מחולל מסכים |
| Interfaces                 | `EINTER`             | **Not** `EINTERFACE`. Title: מחולל ממשקים למסכים |
| Menus                      | `EMENU`              | Title: מחולל תפריטים |
| Documents                  | `EDOC`               | Title: מחולל מסמכים |

Live verification (no arguments needed; the filter pattern is stable across tenants):

```sql
SELECT ENAME, TITLE FROM EXEC
WHERE ENAME IN ('EPROG','EREP','EFORM','EINTER','EMENU','EDOC')
  AND TYPE = 'F'
ORDER BY ENAME FORMAT;
```

To copy an entity rather than open its generator, use the matching **COPY\*** program — not the generator form. See `procedures.md` § "Copying existing entities".

---

## Recipe: Text Subform Creation (canonical 6-call)

Build a custom-prefixed text/remarks subform on a parent form (parent must have a custom prefix). End-to-end in 6 tool calls with zero failed attempts.

**Inputs:**
- `<TEXTFORM>` — name of the new text form/table (e.g., `SOF_CUSTSIGNTEXT`). Must start with a 4-letter prefix.
- `<PARENT>` — parent form name (e.g., `SOF_CUSTSIGN`). Must have a custom prefix.
- `<PARENTKEY>` — parent's key column name (e.g., `KLINE`).

**Pre-flight (optional but recommended) — confirm the parent exists and exposes the key:**
```sql
SELECT EXEC, ENAME FROM EXEC WHERE ENAME = '<PARENT>' AND TYPE = 'F' FORMAT;
SELECT NAME FROM FORMCLMNS WHERE FORM = (SELECT EXEC FROM EXEC
 WHERE ENAME = '<PARENT>' AND TYPE = 'F') AND NAME = '<PARENTKEY>' FORMAT;
```

### Call 1 — DBI: create the text table

`run_inline_sqli` with `mode: "dbi"`:
```sql
CREATE TABLE <TEXTFORM> 'Remarks' 0
KLINE (INT,13,'Parent Key')
TEXT (RCHAR,68,'Text')
TEXTLINE (INT,8,'Line')
TEXTORD (INT,8,'Sort')
UNIQUE (KLINE, TEXTLINE);
```

**No `/` separators between columns** — DBI uses whitespace. `/` produces `parse error AT OR NEAR SYMBOL /`.

### Call 2 — EFORM: create form + configure all 4 columns + KLINE expression

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "ENAME", "value": "<TEXTFORM>"},
    {"op": "fieldUpdate", "field": "TNAME", "value": "<TEXTFORM>"},
    {"op": "fieldUpdate", "field": "EDES",  "value": "LOG"},
    {"op": "fieldUpdate", "field": "TITLE", "value": "Remarks"},
    {"op": "fieldUpdate", "field": "MODULENAME", "value": "Internal Development"},
    {"op": "saveRow"},

    {"op": "filter", "field": "ENAME", "value": "<TEXTFORM>"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FCLMN"},

    {"op": "filter", "field": "NAME", "value": "KLINE"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "fieldUpdate", "field": "HIDEBOOL",   "value": "Y"},
    {"op": "fieldUpdate", "field": "EXPRESSION", "value": "Y"},
    {"op": "saveRow"},
    {"op": "startSubForm", "name": "FCLMNA"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "EXPR", "value": ":$$.<PARENTKEY>"},
    {"op": "saveRow"},
    {"op": "endSubForm"},

    {"op": "clearFilter"},
    {"op": "filter", "field": "NAME", "value": "TEXTLINE"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "fieldUpdate", "field": "HIDEBOOL", "value": "Y"},
    {"op": "saveRow"},

    {"op": "clearFilter"},
    {"op": "filter", "field": "NAME", "value": "TEXTORD"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "fieldUpdate", "field": "HIDEBOOL", "value": "Y"},
    {"op": "fieldUpdate", "field": "ORD",      "value": "1"},
    {"op": "saveRow"}
  ]
}
```

`EDES = "LOG"` is mandatory — it flags the form as a log/text form so the web client renders the HTML editor. The 4 FCLMN rows already exist (auto-populated from the base table) — never `newRow` them, only update.

### Call 3 — EFORM: add 3 form-level trigger slots + 1 column-level POST-FIELD slot

```json
{
  "form": "EFORM",
  "operations": [
    {"op": "filter", "field": "ENAME", "value": "<TEXTFORM>"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FTRIG"},
    {"op": "newRow"}, {"op": "fieldUpdate", "field": "TRIGNAME", "value": "PRE-UPDATE"},          {"op": "saveRow"},
    {"op": "newRow"}, {"op": "fieldUpdate", "field": "TRIGNAME", "value": "POST-DELETE"},         {"op": "saveRow"},
    {"op": "newRow"}, {"op": "fieldUpdate", "field": "TRIGNAME", "value": "PRE-UPD-DEL-SCRLINE"}, {"op": "saveRow"},
    {"op": "endSubForm"},

    {"op": "startSubForm", "name": "FCLMN"},
    {"op": "filter", "field": "NAME", "value": "TEXT"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FORMCLTRIG"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "TRIGNAME", "value": "POST-FIELD"},
    {"op": "saveRow"}
  ]
}
```

### Call 4 — three `write_to_editor` calls **in parallel** (one assistant message)

Form-level trigger code. Always reference the parent key with `:$$.<PARENTKEY>` (parent form), never `:$.<PARENTKEY>`.

`PRE-UPDATE`:
```
SELECT 0 + :SCRLINE INTO :$.TEXTORD FROM DUMMY ;
```

`POST-DELETE`:
```
UPDATE <TEXTFORM>
 SET TEXTORD = TEXTORD - 1
 WHERE KLINE = :$$.<PARENTKEY>
 AND TEXTORD >= :SCRLINE ;
```

`PRE-UPD-DEL-SCRLINE`:
```
SELECT TEXTORD INTO :SCRLINE
 FROM <TEXTFORM>
 WHERE KLINE = :$$.<PARENTKEY>
 AND TEXTLINE = :$.TEXTLINE ;
```

### Call 5 — DBI: insert all 14 column-trigger lines (POST-FIELD on TEXT)

`FORMCLTRIGTEXT.TRIG = 11` for POST-FIELD. The form ID is the EXEC of `<TEXTFORM>` — easiest to fetch first then plug in (Priority SQLI does not support subqueries inside `VALUES`).

First call — get the ID:
```sql
SELECT EXEC FROM EXEC WHERE ENAME = '<TEXTFORM>' AND TYPE = 'F' FORMAT;
```

Then DBI (substitute `<FORMID>`):
```sql
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 1, 1,'SELECT :SCRLINE INTO :$.TEXTORD');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 2, 2,' FROM DUMMY ;');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 3, 3,'GOTO 1 WHERE :$.TEXTLINE > 0;');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 4, 4,'SELECT 1 INTO :$.TEXTLINE');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 5, 5,' FROM DUMMY ;');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 6, 6,'SELECT MAX(TEXTLINE)+1');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 7, 7,' INTO :$.TEXTLINE');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 8, 8,' FROM <TEXTFORM>');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11, 9, 9,' WHERE KLINE = :$$.<PARENTKEY>;');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,10,10,'UPDATE <TEXTFORM>');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,11,11,' SET TEXTORD = TEXTORD + 1');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,12,12,' WHERE KLINE = :$$.<PARENTKEY>');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,13,13,' AND TEXTORD >= :SCRLINE ;');
INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,14,14,'LABEL 1;');
```

DBI inserts persist immediately and are not subject to the `newRow`-on-FORMCLTRIGTEXT silent-append bug.

### Call 6 — EFORM: compile text form + link as subform on parent + compile parent

```json
{
  "operations": [
    {"op": "compile", "entity": "<TEXTFORM>"},

    {"op": "filter", "field": "ENAME", "value": "<PARENT>"},
    {"op": "getRows"},
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FLINK"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "FNAME", "value": "<TEXTFORM>"},
    {"op": "saveRow"},

    {"op": "compile", "entity": "<PARENT>"}
  ]
}
```

### Common failures (avoid)

| Symptom | Cause | Fix |
|---------|-------|-----|
| DBI `parse error AT OR NEAR SYMBOL /` | Used `/` between columns in `CREATE TABLE` | Whitespace only |
| `<table> Unresolved identifier` on `FORMS`, `FORMMAIN`, `SYSTABLES` | These tables don't exist | Use `EXEC`, `FORMCLMNS`, `FORMTRIG` (see "Key system tables") |
| `setActiveRow` writes land on wrong parent (EFORM EXEC=9061) | Missing `getRows` between `filter` and `setActiveRow` | Always `filter` → `getRows` → `setActiveRow` |
| Column trigger compiles but fires nothing at runtime | WebSDK `newRow` on `FORMCLTRIGTEXT` silently appended duplicate lines | Use DBI INSERT (Call 5 above) — never WebSDK newRow on FORMCLTRIGTEXT |
| HTML editor doesn't render in web client | `EDES` missing or wrong | Must be `LOG` |
| Subform shows empty / no parent linkage | Missing FCLMNA EXPR on KLINE | `:$$.<PARENTKEY>` (parent form ref, two `$`) |

### Why this works in 6 calls

- Call 2 walks all four columns in one EFORM session via repeated `clearFilter → filter → setActiveRow` cycles — saves 3 round-trips vs. one call per column.
- Call 5 uses DBI rather than WebSDK newRow, dodging the FORMCLTRIGTEXT append bug and inserting all 14 lines in one network hop.
- Call 6 chains compile + link + compile through the existing `compile` compound + EFORM primitives in one operations array.
- Pre-existing rows (FCLMN columns auto-populated by the base table) are updated in place — no `newRow` for the 4 base columns.

---

## SQLI Metadata Queries

When WebSDK subform navigation is unavailable or you need bulk data, query the system tables directly via `run_inline_sqli`.

### EFORM alias → real table/column mapping

| EFORM view field | Real table | Real column | Notes |
|------------------|-----------|-------------|-------|
| `ENAME` | `EXEC` | `ENAME` | Form/proc/table name |
| `HIDEBOOL` | `FORMCLMNS` | `HIDE` | "H" = hidden |
| `IDCOLUMNE` | `FORMCLMNS` | `IDCOLUMN` | Instance ID (6 = private dev) |
| `IDJOINE` | `FORMCLMNS` | `IDJOIN` | Join instance |
| `POS` | `FORMCLMNS` | `POS` | Column position |
| `READONLY` | `FORMCLMNS` | `READONLY` | "R" = read-only, "M" = mandatory |
| `NAME` | `FORMCLMNS` | `NAME` | Column name in form |
| `TNAME` | *(no direct column)* | join via `COLUMNS` | Table name requires join |
| `CNAME` | *(no direct column)* | join via `COLUMNS` | Physical column name requires join |
| `TRIGNAME` | `FORMTRIG` | `TRIG` | Trigger type (text, not ID) |

### Query form columns

```sql
SELECT FC.NAME, FC.POS, FC.HIDE, FC.READONLY,
  FC.IDCOLUMN, FC.IDJOIN, FC.EXPRESSION
FROM FORMCLMNS FC
WHERE FC.FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
ORDER BY FC.POS
FORMAT;
```

### Query form columns with table names

```sql
SELECT FC.NAME, C.CNAME, FC.POS, FC.HIDE,
  FC.READONLY, FC.JOIN, FC.IDCOLUMN
FROM FORMCLMNS FC, COLUMNS C
WHERE FC.FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
AND FC.COLUMN = C.COLUMN
ORDER BY FC.POS
FORMAT;
```

Note: `COLUMNS.TABLE` is an integer ID, not a table name string. To get the table name, you need an additional join or use WebSDK getRows on EFORM/FCLMN which returns `TNAME` directly.

### Query form-level triggers

```sql
SELECT FT.TRIG, FT.TDATE
FROM FORMTRIG FT
WHERE FT.FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
FORMAT;
```

### Query column-level triggers and their code

```sql
SELECT FCT.NAME, FCT.TRIG, FCT.TEXTLINE, FCT.TEXT
FROM FORMCLTRIGTEXT FCT
WHERE FCT.FORM = (
  SELECT EXEC FROM EXEC WHERE ENAME = 'MY_FORM')
ORDER BY FCT.NAME, FCT.TRIG, FCT.TEXTLINE
FORMAT;
```

### Key system tables

| Table | Contains | Key columns |
|-------|----------|-------------|
| `EXEC` | All entities (forms, procs, tables) | `EXEC` (ID), `ENAME`, `TYPE` |
| `FORMCLMNS` | Form column definitions | `FORM`, `COLUMN`, `NAME`, `POS`, `HIDE` |
| `COLUMNS` | Physical column registry | `COLUMN` (ID), `TABLE` (ID), `CNAME`, `TYPE`, `WIDTH` |
| `FORMTRIG` | Form-level trigger declarations | `FORM`, `TRIG` |
| `FORMTRIGTEXT` | Form-level trigger code | `FORM`, `TRIG`, `TEXTLINE`, `TEXT` |
| `FORMCLTRIG` | Column-level trigger declarations | `FORM`, `NAME`, `TRIG` |
| `FORMCLTRIGTEXT` | Column-level trigger code | `FORM`, `NAME`, `TRIG`, `TEXTLINE`, `TEXT` |

### Tables that DO NOT EXIST (common wrong guesses)

`FORMCOLUMNS`, `FORMCOL`, `FORMCOLUMN`, `SYSCOLUMNS`, `SYSTEMCOLUMN`, `SYSTABLES`, `TABLES`, `FORMLINK`, `SUBFORMS` — none of these are valid Priority table names.
