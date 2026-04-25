# Add a form-level trigger

**Triggers:** add a form trigger, add form-level trigger, add PRE-INSERT, add POST-INSERT, add PRE-FORM, add POST-FORM, add PRE-UPDATE, add POST-UPDATE, add PRE-DELETE, add POST-DELETE, attach trigger to form

**Before:**
- Verify form exists: `websdk_form_action` on EFORM with `filter ENAME=<form>` (form name != table name).
- Pick trigger NAME using the convention `<PREFIX>_<TYPE>` (e.g. `ACME_PRE_INSERT`). The 4-letter prefix matches your custom-entity prefix.
- Confirm the trigger TYPE: `PRE-FORM`, `POST-FORM`, `PRE-INSERT`, `POST-INSERT`, `PRE-UPDATE`, `POST-UPDATE`, `PRE-DELETE`, `POST-DELETE`.
- Custom message numbers used by ERRMSG / WRNMSG / MAILMSG must be > 500 (system range is reserved).
- LABELs inside trigger SQLI must be >= 4 digits (e.g. `LABEL 9000;`, not `LABEL 10;`).
- If the trigger references custom columns, verify they already exist via `startSubForm FCLMN` + `getRows` on the form, otherwise compile fails with "column does not exist".

**Calls:**
1. Create the slot on EFORM:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows"},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FTRIG"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"TRIGNAME","value":"<PREFIX>_<TYPE>"},
     {"op":"fieldUpdate","field":"TYPE","value":"<PRE-INSERT|POST-INSERT|...>"},
     {"op":"saveRow"}
   ]}
   ```
   The slot field is `TRIGNAME` (not `NAME`). Always `getRows` between `filter` and `setActiveRow` or writes land on EFORM's own meta-form.
2. Write the SQLI body (FULL step content, not a diff):
   ```
   write_to_editor(
     entityType = "FORM",
     entityName = "<FORM>",
     stepName   = "<PREFIX>_<TYPE>",
     content    = "<full SQLI text including LINK, SELECT, ERRMSG, etc.>"
   )
   ```
3. Compile the form:
   ```json
   {"operations":[{"op":"compile","entity":"<FORM>"}]}
   ```
   Or `run_windbi_command priority.prepareForm` (requires the form file open in VSCode).

**After:**
- Authoritative compile-status check: SQLI on PREPERRMSGS — `SELECT FORMNAME, TRIGNAME, MESSAGE, LINE FROM PREPERRMSGS WHERE FORMNAME = '<FORM>' OR MAINFORM = '<FORM>' FORMAT;`. Zero rows = clean.
- Cross-check via `getRows` on the form itself: opens cleanly = ready; "המסך לא מוכן" = compile not actually clean.
- `getRows` on FTRIG confirms the slot is present with the expected TRIGNAME and TYPE.
- If the trigger uses ERRMSG/WRNMSG numbers, verify the MESSAGES rows exist (or add them).
- Do NOT trust the compound `compile` op's "ok" status alone — it has been observed to lie while PREPERRMSGS still had errors.

**See also:** `references/triggers.md` (trigger types, ERRMSG/WRNMSG, INCLUDEs, naming), `references/websdk-cookbook.md` § "Create a form-level trigger" + § "Compile-status signals: PREPERRMSGS is authoritative", `recipes/read-compile-errors.md`, `recipes/compile-form.md`.
