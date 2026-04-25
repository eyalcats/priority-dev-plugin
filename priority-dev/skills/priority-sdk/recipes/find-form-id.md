# Find a form's internal ID

**Triggers:** find a form's ID, what is the FORM number for <name>, get internal ID of <form>, look up form ID, EXEC ID of form, FORM column lookup

**Before:**
- Form NAME verified — confirm via `websdk_form_action` `filter ENAME=<form>` on EFORM, or fall back to a SQLI existence check on EXEC (works across visibility scopes — see `websdk-cookbook.md` § "filter vs search on generator forms").
- Decide which ID you need: most metadata tables (FCLMN, FORMPREPERRS) join on the integer `FORM` value from the FORM table; a few DBI patterns (notably writing to `FORMCLTRIGTEXT`) need the `EXEC` ID from the EXEC table with `TYPE='F'`.

**Calls:**
1. SQLI lookup (preferred — authoritative, ignores form-level visibility):
   ```sql
   SELECT FORM, ENAME FROM FORM WHERE ENAME = '<NAME>' FORMAT;
   ```
   For the EXEC ID variant (TYPE='F'):
   ```sql
   SELECT EXEC, ENAME FROM EXEC WHERE ENAME = '<NAME>' AND TYPE = 'F' FORMAT;
   ```
   Run via `run_inline_sqli`.
2. WebSDK alternative — `websdk_form_action`:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<NAME>"},
     {"op":"getRows","top":1}]}
   ```
   Read the `FORM` column on the returned row.

**After:**
- Result is the integer ID. Confirm exactly 1 row returned. Use the value to drive joins on FCLMN.FORM, FORMPREPERRS.FORM, FORMCLTRIGTEXT.FORM, etc.
- Empty result on the WebSDK path with a populated SQLI result indicates a generator-form visibility issue, not a missing entity — switch to SQLI on EXEC. See `websdk-cookbook.md` § "filter vs search on generator forms" and `common-mistakes.md` § "Unfiltered getRows returns empty…".

**See also:** `references/websdk-cookbook.md` § "Find a form's internal ID" + § "filter vs search on generator forms"; `references/common-mistakes.md` § "Unfiltered getRows returns empty on a busy form".
