# Add a column with an expression (computed column)

**Triggers:** add a column with an expression, add a calculated column, add a formula column, add a computed column, add an expression column, set a column expression

**Before:**
- Verify the form name via `websdk_form_action` on EFORM with `filter ENAME=<form>` (form name != table name). If 0 rows, ask the user.
- Confirm the base table (the column lives on FCLMN of the form, not on a foreign table).
- Pick a free `POS` slot. For private dev on system forms, plan `IDCOLUMNE >= 6`.
- `FCLMNA.EXPR` is **scalar-only** — scalar subqueries like `(SELECT … WHERE …)` fail with `parse error at or near symbol SELECT`. Use the foreign-table lookup form `<TABLE> WHERE <key> = :$.<local_fk>` (no SELECT, no FROM) for joined lookups, or fall back to a real join + imported column, or a POST-UPDATE trigger for runtime logic (`forms.md:1012`).
- `FCLMNA.COND` (conditional column visibility) is **NOT reachable via WebSDK** — flag any conditional-visibility request and route to a POST-FIELD trigger that sets `:$.TARGETCOL.SHOW`, or a direct DBI UPDATE on FORMCLMNSA with explicit user approval (`forms.md` § "FCLMNA.COND (conditional visibility) is NOT reachable via WebSDK").
- Expression columns: when adding a brand-new column (not editing an existing one), set `EXPRESSION='Y'` BEFORE `WIDTH` — Priority validates WIDTH against the row's current state and rejects it on non-expression rows.

**Calls:**
1. `websdk_form_action` on EFORM — add the column row first (FCLMN), then attach the expression (FCLMNA):
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMN"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"NAME","value":"<COL>"},
     {"op":"fieldUpdate","field":"EXPRESSION","value":"Y"},
     {"op":"fieldUpdate","field":"TYPE","value":"<INT|CHAR|RCHAR|DATE|REAL>"},
     {"op":"fieldUpdate","field":"WIDTH","value":"<n>"},
     {"op":"fieldUpdate","field":"POS","value":"<POS>"},
     {"op":"saveRow"},
     {"op":"filter","field":"NAME","value":"<COL>"},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMNA"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"EXPR","value":"<scalar expression — max 56 chars>"},
     {"op":"saveRow"}
   ]}
   ```
2. For expressions longer than ~56 chars, continue via FCLMNTEXT: `FCLMNA -> setActiveRow -> startSubForm FCLMNTEXT -> newRow -> fieldUpdate(TEXT, "<continuation>") -> saveRow`.
3. For a computed-display (read-only display of the formula) set `READONLY=M` on the FCLMN row.
4. Compile: `{"operations":[{"op":"compile","entity":"<FORM>"}]}`.

**After:**
- Read FORMPREPERRS authoritatively — `EFORM filter ENAME=<form> -> startSubForm FORMPREPERRS -> getRows`. Any non-empty `PREPERRMSGS` = failure. Never trust compound `status: "ok"` alone.
- `getRows` on FCLMN (filter NAME=<COL>) and FCLMNA confirms EXPR persisted.
- If the expression references columns from another instance (`IDCOLUMNE > 0`), `:$.COLUMN` only sees the same instance — use `TABLE.COLUMN` to reference system columns or joined-table columns.

**See also:**
- `references/websdk-cookbook.md` § "Set a column expression"
- `references/forms.md` § "Setting a column expression" + § "FCLMNA.EXPR for foreign-table lookups"
- `references/forms.md` § "FCLMNA.COND (conditional visibility) is NOT reachable via WebSDK"
- `recipes/read-compile-errors.md`
