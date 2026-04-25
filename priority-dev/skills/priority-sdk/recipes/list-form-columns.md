# List a form's columns

**Triggers:** list a form's columns, show me the columns of <form>, what columns does <form> have, dump form columns, read form columns, list fields on <form>

**Before:**
- Verify the form name via `websdk_form_action` on EFORM with `filter ENAME=<form>`. Form name is NOT the table name — confirm before querying. If 0 rows, ask the user; do NOT propose a plausible alternative.

**Calls:**

Two paths, pick whichever fits the caller's needs.

1. **WebSDK (live form data, supports follow-up writes):**
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMN"},
     {"op":"getRows","fromRow":1}
   ]}
   ```
   The mandatory `getRows` after `filter` (cookbook line 396) prevents the silent EXEC=9061 scoping failure. Returns FCLMN rows with NAME, CNAME, TNAME, POS, HIDEBOOL, READONLY, IDJOIN, etc.

2. **SQLI metadata (richer, joinable, includes table name):**
   ```sql
   SELECT FCLMN.NAME, FCLMN.REALNAME, FCLMN.TYPE,
     FORM.MAINTABLE
   FROM FCLMN, FORM
   WHERE FCLMN.FORM = FORM.FORM
   AND FORM.ENAME = '<FORM>'
   ORDER BY FCLMN.POS
   FORMAT;
   ```
   Run via `run_inline_sqli` (mode=sqli, default). Lines stay ≤ 68 chars.

**After:**
- The result is the full column list; verify the form has been compiled at least once (no FORMPREPERRS rows) via `EFORM filter ENAME=<form> -> startSubForm FORMPREPERRS -> getRows`. Or `run_windbi_command priority.displayTableColumns entityName=<table>` to confirm the underlying table columns.
- If WebSDK returns `{}` and SQLI returns rows: known empty-getRows quirk on EFORM subforms (cookbook 343); trust the SQLI output.

**See also:**
- `references/websdk-cookbook.md` § "Read all columns of a form" + § "SQLI Metadata Queries — Query form columns"
- `references/websdk-cookbook.md` § "EFORM field aliases" (alias mapping for FCLMN)
