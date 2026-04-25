# Add a column-level trigger

**Triggers:** add a column trigger, add POST-FIELD on <column>, add CHECK-FIELD on <column>, add CHOOSE-FIELD on <column>, column-level trigger, field trigger, per-column trigger

**Before:**
- Verify form + column: EFORM `filter ENAME=<form>` -> `startSubForm FCLMN` -> `getRows` and confirm the column NAME and IDCOLUMN.
- Column-level trigger slots are NAMED by the column (CLNAME = column NAME). The trigger TYPE (`POST-FIELD`, `CHECK-FIELD`, `CHOOSE-FIELD`, `KEY-FIELD`, `CALC-FIELD`) is a separate field — there is no `_TYPE` suffix in the slot NAME.
- Custom message numbers used by ERRMSG / WRNMSG must be > 500. LABELs inside SQLI must be >= 4 digits.
- **CRITICAL — DO NOT use WebSDK `newRow` on FORMCLTRIGTEXT to write trigger code.** It silently APPENDS rows instead of replacing them, producing duplicate lines that Priority concatenates and silently skips as broken SQL. `getRows` on FORMCLTRIGTEXT also frequently returns `{}` even when rows exist. `write_to_editor` likewise returns `TRIGGER_NOT_FOUND` for column-level triggers. The only reliable way to write the trigger body is DBI `DELETE` + `INSERT` into FORMCLTRIGTEXT via `run_inline_sqli(mode="dbi")` (see Calls below). References: cookbook lines 128-132, forms.md § "Column trigger code — use DBI, not WebSDK newRow".
- Get the form's numeric IDFORM (FORM column on EFORM) — DBI insert needs it, not the ENAME.

**Calls:**
1. Create the column-trigger slot on EFORM:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows"},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLTRIG"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"CLNAME","value":"<COLUMN_NAME>"},
     {"op":"fieldUpdate","field":"TYPE","value":"<POST-FIELD|CHECK-FIELD|CHOOSE-FIELD|...>"},
     {"op":"saveRow"}
   ]}
   ```
2. Write the trigger body via DBI (NOT via `newRow` on FORMCLTRIGTEXT). Use `run_inline_sqli(mode="dbi")`:
   ```sql
   DELETE FROM FORMCLTRIGTEXT
     WHERE IDFORM = <IDFORM>
       AND IDCOLUMN = <IDCOLUMN>
       AND TRIGTYPE = '<TYPE>';
   INSERT INTO FORMCLTRIGTEXT (IDFORM, IDCOLUMN, TRIGTYPE, SEQ, TEXT)
   VALUES
     (<IDFORM>, <IDCOLUMN>, '<TYPE>', 1, '<line 1 of SQLI>'),
     (<IDFORM>, <IDCOLUMN>, '<TYPE>', 2, '<line 2 of SQLI>'),
     ...;
   ```
   Each row in FORMCLTRIGTEXT is one source line. Increment SEQ per line. Lines obey the 68-char Priority limit.
3. Compile: `{"operations":[{"op":"compile","entity":"<FORM>"}]}` (or `run_windbi_command priority.prepareForm`).

**After:**
- Authoritative check: SQLI on PREPERRMSGS — `SELECT FORMNAME, COLNAME, TRIGNAME, MESSAGE, LINE FROM PREPERRMSGS WHERE FORMNAME = '<FORM>' OR MAINFORM = '<FORM>' FORMAT;`. Zero rows = clean. Treat `FORMPREPERRS getRows` as stale — it can return `{}` while PREPERRMSGS still has real errors.
- Confirm slot: `getRows` on FCLTRIG (CLNAME + TYPE present).
- Confirm body landed: SQLI `SELECT SEQ, TEXT FROM FORMCLTRIGTEXT WHERE IDFORM=<IDFORM> AND IDCOLUMN=<IDCOLUMN> AND TRIGTYPE='<TYPE>' ORDER BY SEQ;` — line count matches what you inserted (no duplicates from prior `newRow` attempts).
- Live-test: edit a row in the form via WebSDK and verify the trigger fires (POST-FIELD message, CHECK-FIELD rejection, etc.).

**See also:** `references/forms.md` § "Column trigger code — use DBI, not WebSDK newRow", `references/triggers.md` (column-trigger types, CHECK/CHOOSE semantics), `references/websdk-cookbook.md` § "newRow on FORMCLTRIGTEXT silently appends" + § "Compile-status signals: PREPERRMSGS is authoritative", `references/common-mistakes.md` (FORMCLTRIGTEXT silent-append pitfall), `recipes/read-compile-errors.md`.
