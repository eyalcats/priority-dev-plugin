# Create a custom table

**Triggers:** create a table, new table, add a custom table, make a table, DBI create table, define a new table

**Before:**
- Pick a NAME with a 4-letter prefix (e.g. `SOF_ORDLOG`), max 20 chars, alphanumeric + underscore, must begin with a letter, no reserved words.
- Confirm the table does NOT already exist: `run_inline_sqli "SELECT TABLE FROM TABLES WHERE TNAME = '<NAME>' FORMAT;"` should return 0 rows. (Or `run_windbi_command priority.displayTableColumns` and expect "table not found".)
- Design columns up front: each one needs `(TYPE, WIDTH, 'TITLE')`. Titles are ASCII-only, ≤ 20 chars (Hebrew titles in DBI cause encoding issues — set them later via FCLMN COLTITLE).
- Decide keys: every table needs at least one `UNIQUE`. `AUTOUNIQUE` requires a paired `UNIQUE` key (standalone autounique is rejected). Always use type `0` for new application tables.
- Avoid reserved words like `REFRESH` as column names. `TIME` columns must be width ≥ 5. Foreign-key columns must match the target column's type AND width exactly.
- Strict 68-char line width — Priority DBI rejects longer lines. No `||` continuation operator; split across multiple physical lines.

**Calls:**
1. `run_inline_sqli` with `mode=dbi` and content like:
   ```sql
   CREATE TABLE SOF_ORDLOG 'Order Activity Log' 0
   ORDLOGID (INT, 13, 'Log ID')
   ORDNAME (CHAR, 20, 'Order Number')
   LOGDATE (DATE, 14, 'Logged At')
   LOGTEXT (CHAR, 80, 'Message')
   AUTOUNIQUE (ORDLOGID)
   UNIQUE (ORDNAME, LOGDATE);
   ```
   Use the Priority column form `COL (TYPE, WIDTH, 'Title')` — NOT SQL-standard `COL TYPE(WIDTH) NOT NULL`. Each line ≤ 68 chars.
2. To add columns later: `run_inline_sqli mode=dbi` with `FOR TABLE <NAME> INSERT <col> (<TYPE>, <WIDTH>, '<Title>');`.
3. To add an extra key: `FOR TABLE <NAME> INSERT { UNIQUE | NONUNIQUE } (col1, col2);`.

**After:**
- `run_windbi_command priority.displayTableColumns` with `entityName=<NAME>` confirms the schema. Or `priority.dumpTable` for the full DDL echo.
- Verify keys with the SQLI metadata join (cookbook 1042-1052): `SELECT KEYS.TYPE, KEYCOLS.CNAME FROM KEYS, KEYCOLS WHERE KEYS.TABLE = (SELECT TABLE FROM TABLES WHERE TNAME = '<NAME>') AND KEYS.KEY = KEYCOLS.KEY ORDER BY KEYS.PRIORITY, KEYCOLS.PRIORITY FORMAT;`.
- If the table will be deployed to other servers: custom tables need a `TAKESINGLEENT` UPGNOTES row; columns added later to system tables need a manual `UPGCODE='DBI'` UPGNOTES entry (Priority does NOT auto-track DBI-mode changes).

**See also:**
- `references/tables-and-dbi.md` § "DBI Syntax Reference" + § "DBI Pitfalls" + § "Naming Conventions"
- `references/tables-and-dbi.md` § "Custom columns on system tables — manual UPGNOTES DBI entry required"
- `recipes/upgrade-form-changes.md` (deployment)
