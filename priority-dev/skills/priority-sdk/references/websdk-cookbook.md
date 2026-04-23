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

### FORMPREPERRS accumulates stale errors

FORMPREPERRS exists and can be read via WebSDK, but entries accumulate across compile attempts. "Could not read ERRMSGS" reports the same way whether the current compile succeeded or failed. Authoritative signal is the bridge's `prepareForm` status + a `getRows` on the form itself, not FORMPREPERRS content. See the detailed pitfall at `FORMPREPERRS accumulates stale errors across compile attempts` below.

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

### ⚠ Pitfall: `FCLMNA.EXPR = ':$$.PARENTPK'` breaks the parent's compile (verified 2026-04-18)

An earlier version of this cookbook (and the old `reference_subform_creation_via_websdk.md` memory) prescribed putting `EXPRESSION=Y` on the subform's link column and a FCLMNA row with `EXPR=':$$.PARENTPK'`. **This is wrong.** When the PARENT form compiles, Priority flattens `:$$.PARENTPK` to `:$.PARENTPK` while resolving cross-form activations (the `<PARENT>/DELETE` activation) and then tries to resolve `PARENTPK` as a real column on the parent — which doesn't exist. Result:

```
:$.PARENTPK אינו קיים כעמודה במסך בהפעלה <PARENT>/DELETE
(":$.PARENTPK does not exist as a column in the form, during <PARENT>/DELETE activation")
```

The parent's compile fails, which in turn cascades because `ERRMSGS` can't be read by the bridge (see next section). If you already added the orphan FCLMNA row, delete it via raw SQLI before recompiling:

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

### ⚠ FORMPREPERRS accumulates stale errors across compile attempts

If you try to read errors directly via `websdk_form_action FORMPREPERRS getRows`, be aware that entries can be LEFT OVER from a previous compile — it is NOT freshly reset per call. Stale entries can show line numbers or variable names that don't match your current buffer (e.g. `parse error at line 4` when your line 4 has no syntactic issue, or `:$.SIGNUSER Incompatible data types` from an earlier failed compile).

**Authoritative signal sequence:**
1. Use the bridge's `status` field on `priority.prepareForm` response. `"compiled successfully"` = real success, ignore any FORMPREPERRS contents.
2. If the bridge reports ambiguous failure, test by opening the form via `getRows` — form opens = actually succeeded.
3. Only after confirming a real failure do you look at FORMPREPERRS. Cross-check each entry's line numbers and referenced variables against the CURRENT buffer. If they don't match, they're stale — don't chase them.

When the bridge's compound-op `FORMPREPERRS` fix is installed (patch in `bridge/src/websdk/compounds.ts` uses `FORMPREPERRS` form instead of broken `ERRMSGS` table lookup), this ambiguity goes away and the `status` + inline error text become definitive. Until then, belt-and-suspenders: trust the bridge's status, verify by opening the form.

### FCLMNA gap: conditional visibility (COND) not reachable via WebSDK

FCLMNA exposes only `EXPR` via WebSDK. The `COND` / `BIG` field that drives "show column X only when TYPE='C'" is **not accessible**. Workarounds:

- Accept all columns visible (fine for admin/config forms)
- POST-FIELD trigger that programmatically shows/hides columns
- Direct SQLI INSERT into the underlying FORMCLMNSA table (same bypass pattern as `FORMCLTRIGTEXT`)

### Join metadata placement

Join info (`JTNAME`, `JCNAME`, `IDJOINE`) goes on the **base-table FCLMN row**, NOT on the imported display column. Project rule: `IDJOINE` values in custom forms must be `> 5`. The underlying FORMCLMNS column is named `IDJOIN` (no trailing E — that's the EFORM alias) with width 2 — values up to 99 are accepted.

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
