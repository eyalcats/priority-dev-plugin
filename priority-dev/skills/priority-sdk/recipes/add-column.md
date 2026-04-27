# Add a column to a form

**Triggers:** add a column, add a field, add column to <form>, add field to <form>, new column, new field, add a plain column

**Before:**
- Verify the form name via `websdk_form_action` on EFORM with `filter ENAME=<form>` (form name is NOT the same as the table name — e.g. `ACCOUNTS_PAYABLE` → `ACCOUNTS`). If 0 rows, ask the user; do NOT propose a plausible alternative.
- Confirm the base table behind the form (`MAINTABLE`/`TNAME` on EFORM, or `displayTableColumns <table>`).
- Pick a `POS` slot that does not collide with existing columns (read FCLMN first).
- Pick the right `IDCOLUMNE` based on the form's base table:
  - **Custom-table form** (`SOF_*`, `ASTR_*`, etc.): `IDCOLUMNE = 0`. Match what every other column on the form already uses. Setting `6` here makes Priority treat the column as an "imported instance" with no join target — saved values fail validation with `ערך 'X' לא קיים בעמודה ...` ("value X does not exist in column …") on data entry.
  - **System-table form** (`INVOICES`, `DOCUMENTS`, `ORDERS`, etc.): `IDCOLUMNE = 6` (or any value >= 6). System reserves `0`.

**Calls:**
1. `websdk_form_action` on EFORM, single compound:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMN"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"NAME","value":"<COL>"},
     {"op":"fieldUpdate","field":"CNAME","value":"<COL>"},
     {"op":"fieldUpdate","field":"TNAME","value":"<TABLE>"},
     {"op":"fieldUpdate","field":"POS","value":"<POS>"},
     {"op":"fieldUpdate","field":"IDCOLUMNE","value":"<0 for custom-table form, 6 for system-table form>"},
     {"op":"saveRow"}
   ]}
   ```
   The `getRows` between `filter` and `setActiveRow` is mandatory — without it, `newRow` lands on EFORM's meta-form (EXEC=9061) silently.
2. For a CHAR(1) Y/N field rendered as a checkbox in the web client, add `{"op":"fieldUpdate","field":"BOOLEAN","value":"Y"}` before `saveRow`.
3. Compile via the same compound: `{"operations":[{"op":"compile","entity":"<FORM>"}]}` (or `run_windbi_command priority.prepareForm`).

**After:**
- Authoritative compile signal: read FORMPREPERRS — `EFORM filter ENAME=<form> -> startSubForm FORMPREPERRS -> getRows`. Treat any non-empty `PREPERRMSGS` as failure. Do NOT trust the compound's `status: "ok"` alone.
- `getRows` on FCLMN (filter `NAME=<COL>`) confirms the new row landed.
- Verify `FORM` on the new FORMCLMNS row equals the target form's EXEC id (NOT 9061). If 9061, the `getRows` step was missing — re-run.

**See also:**
- `references/websdk-cookbook.md` § "Add a column to a form"
- `references/forms.md` § "Adding a column"
- `references/common-mistakes.md` § "Setting `IDJOINE` to a multi-digit value" (for FK columns, see `add-column-with-join.md`)
- `recipes/read-compile-errors.md`
