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
| Using `HIDEBOOL` in SQLI queries | "Unresolved identifier" | Real column is `HIDE` (HIDEBOOL is the EFORM view alias) |
| Using `IDCOLUMNE` in SQLI queries | "Unresolved identifier" | Real column is `IDCOLUMN` |
| `getRows` without `fromRow` on root form | Returns 0 rows | Always `filter` before `getRows` on root forms. `getRows(1)` is default after fix. |
| `filter` without later `setActiveRow(1)` | Subform operations fail | Always `setActiveRow(1)` after `filter` before navigating |

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

For private dev columns (SOF_ prefix) on system tables, add `{"op": "fieldUpdate", "field": "IDCOLUMNE", "value": "6"}`.

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

### Add a subform link

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
    {"op": "setActiveRow", "row": 1},
    {"op": "startSubForm", "name": "FTRIG"},
    {"op": "newRow"},
    {"op": "fieldUpdate", "field": "TRIGNAME", "value": "PRE-INSERT"},
    {"op": "saveRow"}
  ]
}
```

Field is `TRIGNAME` (not `NAME`). After creating the trigger declaration, write the code via `write_to_editor`.

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
