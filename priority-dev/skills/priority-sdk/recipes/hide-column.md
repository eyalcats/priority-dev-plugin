# Hide a column on a form

**Triggers:** hide a column, hide a field, hide column on <form>, set column hidden, make a field invisible, unhide a column

**Before:**
- Verify the form name via `websdk_form_action` on EFORM with `filter ENAME=<form>` (form name != table name). If 0 rows, ask the user.
- Confirm the column exists: `EFORM filter ENAME=<form> -> getRows -> setActiveRow 1 -> startSubForm FCLMN -> filter NAME=<col> -> getRows`. Expect 1 row.
- Use `HIDEBOOL=Y` to hide — NOT `POS=0`. The web client reads `HIDEBOOL` (mapped to `FORMCLMNS.HIDE='H'`) to detect hidden columns.

**Calls:**
1. `websdk_form_action` on EFORM, single compound:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMN"},
     {"op":"filter","field":"NAME","value":"<COL>"},
     {"op":"setActiveRow","row":1},
     {"op":"fieldUpdate","field":"HIDEBOOL","value":"Y"},
     {"op":"saveRow"}
   ]}
   ```
   To unhide: set `"value": ""`. To bulk-hide many columns in one shot, use the SQLI fallback: `UPDATE FORMCLMNS SET HIDE='H' WHERE FORM = (SELECT EXEC FROM EXEC WHERE ENAME='<FORM>') AND NAME IN ('COL1','COL2');`.
2. Recompile: `{"operations":[{"op":"compile","entity":"<FORM>"}]}`.

**After:**
- Read FORMPREPERRS authoritatively — `EFORM filter ENAME=<form> -> startSubForm FORMPREPERRS -> getRows`. Any non-empty `PREPERRMSGS` = failure. Do NOT trust compound `status: "ok"` alone.
- `getRows` on FCLMN (filter NAME=<COL>) confirms `HIDEBOOL='Y'` (or `HIDE='H'` via raw SQLI).

**See also:**
- `references/websdk-cookbook.md` § "Hide a column"
- `references/forms.md` § "Hidden Columns"
- `recipes/read-compile-errors.md`
