# Create a text subform

**Triggers:** create a text subform, add a text subform, free-text subform, multi-line text on <form>, remarks subform, log subform, HTML editor subform

**Before:**
- Verify the parent form name via `websdk_form_action` on EFORM with `filter ENAME=<PARENT>` (form name != table name; do not guess). The parent must have a custom 4-letter prefix.
- Identify the parent's key column `<PARENTKEY>` (e.g., `KLINE`). Always reference it as `:$$.<PARENTKEY>` (parent form, two `$`), never `:$.<PARENTKEY>`.
- Pick `<TEXTFORM>` name (4-letter custom prefix, e.g., `SOF_CUSTSIGNTEXT`).
- Ensure DBI permissions in the active environment (`run_inline_sqli mode=dbi`).

**Calls:** the canonical 6-call sequence — see `references/websdk-cookbook.md` "Recipe: Text Subform Creation (canonical 6-call)" lines 773-973.

1. **DBI: create the text table** via `run_inline_sqli mode=dbi`:
   `CREATE TABLE <TEXTFORM> 'Remarks' 0  KLINE (INT,13,'Parent Key')  TEXT (RCHAR,68,'Text')  TEXTLINE (INT,8,'Line')  TEXTORD (INT,8,'Sort')  UNIQUE (KLINE, TEXTLINE);`. Whitespace separates columns — never `/` (parse error).
2. **EFORM: create the form + configure all 4 columns + KLINE expression** in one compound. `newRow` with `ENAME=<TEXTFORM>`, `TNAME=<TEXTFORM>`, `EDES=LOG` (mandatory — flags as text/log form so the web client renders the HTML editor), `TITLE`, `MODULENAME='Internal Development'` -> `saveRow`. Then `filter ENAME=<TEXTFORM>` -> `getRows` -> `setActiveRow 1` -> `startSubForm FCLMN`. For each of the 4 auto-seeded columns, `clearFilter` -> `filter NAME=<col>` -> `getRows` -> `setActiveRow 1` -> update; never `newRow` them. KLINE: `HIDEBOOL=Y, EXPRESSION=Y` + FCLMNA `newRow` with `EXPR=':$$.<PARENTKEY>'`. TEXTLINE: `HIDEBOOL=Y`. TEXTORD: `HIDEBOOL=Y, ORD=1`.
3. **EFORM: add 3 form-level trigger slots + 1 column-level POST-FIELD slot** in one compound. `filter ENAME=<TEXTFORM>` -> `getRows` -> `setActiveRow 1` -> `startSubForm FTRIG`, then 3x `newRow` + `fieldUpdate TRIGNAME=<PRE-UPDATE | POST-DELETE | PRE-UPD-DEL-SCRLINE>` + `saveRow`. Then `endSubForm` -> `startSubForm FCLMN` -> `filter NAME=TEXT` -> `getRows` -> `setActiveRow 1` -> `startSubForm FORMCLTRIG` -> `newRow` + `fieldUpdate TRIGNAME=POST-FIELD` + `saveRow`.
4. **Three `write_to_editor` calls in parallel** (one assistant message), `entityType=FORM, entityName=<TEXTFORM>`, one per `stepName`: `PRE-UPDATE`, `POST-DELETE`, `PRE-UPD-DEL-SCRLINE`. Bodies in cookbook §Call 4. Always `:$$.<PARENTKEY>`.
5. **DBI: insert all 14 column-trigger lines** (POST-FIELD on TEXT, `TRIG=11`). First fetch the form ID: `SELECT EXEC FROM EXEC WHERE ENAME = '<TEXTFORM>' AND TYPE = 'F' FORMAT;` (Priority SQLI does not allow subqueries in `VALUES`). Then 14x `INSERT INTO FORMCLTRIGTEXT (FORM,NAME,TRIG,TEXTLINE,TEXTORD,TEXT) VALUES (<FORMID>,'TEXT',11,...)` per cookbook §Call 5. **Use DBI, not WebSDK `newRow` on FORMCLTRIGTEXT** — `newRow` silently appends duplicates and the trigger fires nothing at runtime.
6. **EFORM: compile text form + link as subform on parent + compile parent** in one compound: `{op: "compile", entity: "<TEXTFORM>"}` -> `filter ENAME=<PARENT>` -> `getRows` -> `setActiveRow 1` -> `startSubForm FLINK` -> `newRow` + `fieldUpdate FNAME=<TEXTFORM>` + `saveRow` -> `{op: "compile", entity: "<PARENT>"}`.

**After:**
- Read FORMPREPERRS for both `<TEXTFORM>` and `<PARENT>` via EFORM -> `filter ENAME=<form>` -> `startSubForm FORMPREPERRS` -> `getRows`. Any non-empty `PREPERRMSGS` = failure; do not trust the compound's `status: ok` alone.
- `getRows FLINK` on the parent shows the new text subform row.
- Live-test: open the parent, navigate to the new subform, type a line. POST-FIELD must auto-assign TEXTLINE and TEXTORD. If the trigger compiles but does nothing at runtime, you almost certainly used WebSDK `newRow` on FORMCLTRIGTEXT — re-do call 5 via DBI.
- HTML editor not rendering = `EDES != 'LOG'`; subform empty = missing FCLMNA `EXPR=':$$.<PARENTKEY>'` on KLINE.

**See also:**
- `references/websdk-cookbook.md` "Recipe: Text Subform Creation (canonical 6-call)" (lines 773-973) and "Common failures (avoid)" table
- `references/forms.md` "Linking Upper-level and Sub-level Forms"
- `recipes/add-subform-link.md`, `recipes/create-subform.md`, `recipes/read-compile-errors.md`
