# Run an interface (EXECUTE INTERFACE)

**Triggers:** run an interface, EXECUTE INTERFACE, load data with INTERFACE, GENERALLOAD, dynamic -form interface, trigger-safe data load, import data into <form>, copy a document via interface

**Before:**
- **Project rule (CLAUDE.md):** Use form interfaces, **not** raw `UPDATE` / `INSERT`, for data changes that should fire triggers. INTERFACE simulates manual data entry — field/form triggers, integrity checks, and privilege rules all run. Raw SQL on a triggered form bypasses all of that. Reach for raw SQL only for small targeted changes that don't touch triggered logic, **and only with explicit user approval**.
- Decide which flavor:
  - **Static (GENERALLOAD with EDI)** — interface predefined in Form Load Designer, columns pre-mapped to GENERALLOAD slots. Use when the load is repeatable and reused.
  - **Dynamic (`-form` runtime)** — built inline at runtime against the form itself; no EDI definition row needed. Use when you'd otherwise have to define a one-off EDI, or when INTERCLMNSFILE blocks WebSDK creation of a static EDI.
- For static: confirm the interface exists — `run_inline_sqli "SELECT ENAME FROM EINTER WHERE ENAME = '<INTERFACE>'"`. `EINTER.ENAME` is CHAR(20), so names truncate silently past 20 chars.
- Identify error-message strategy: default `ERRMSGS` (per-user, type='i') or `-stackerr` linked file (preserves errors across multiple interfaces in one proc).
- **Never call `EXECUTE INTERFACE` against an empty load table** — it can crash the proc / dump. Guard with `SELECT COUNT(*) INTO :CNT FROM <load> ; GOTO 99 WHERE :CNT = 0;`.

**Calls:**
1. Static — load via GENERALLOAD:
   ```sql
   SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
   LINK GENERALLOAD TO :G1;
   GOTO 99 WHERE :RETVAL <= 0;

   INSERT INTO GENERALLOAD (LINE, RECORDTYPE, TEXT2, INT1, REAL1)
   SELECT SQL.LINE, '1', PARTNAME, INTQUANT(1.0), LASTPRICE
     FROM PART WHERE PARTNAME LIKE 'DEMO%';

   SELECT COUNT(*) INTO :CNT FROM GENERALLOAD;
   GOTO 99 WHERE :CNT = 0;

   EXECUTE INTERFACE '<INTERFACE>', :$.MSG, '-L', :G1;

   /* read keys / LOADED back from GENERALLOAD here */
   LABEL 99;
   UNLINK GENERALLOAD;
   ```
2. Dynamic (`-form`) — no EDI row needed; pick fields with `-select`, drill subforms with `-expand`:
   ```sql
   EXECUTE INTERFACE '<FORM>', :$.MSG, '-form',
     '-i', :$.INFILE, '-J',          /* -J = JSON; omit for XML */
     '-ignorewrn', '-noskip';

   /* or export */
   EXECUTE INTERFACE 'ORDERS', :$.MSG, '-form',
     '-select', 'ORDNAME', 'CUSTNAME',
     '-expand', 'ORDERITEMS', '-select', 'PRICE', 'PARTNAME',
     '-ou8', '-L', :TMPFILE, '-f', :OUTFILE;
   ```
3. Wire into a procedure step (`ETYPE='C'` SQLI step — see `recipes/add-procedure-step.md`), or as a step `ETYPE='I'` whose first parameter is the interface name.

**After:**
- Read the per-line outcome from the load table:
  ```sql
  SELECT LINE, LOADED, KEY1 FROM GENERALLOAD ORDER BY LINE FORMAT;
  ```
  Successful lines: `LOADED='Y'` and `KEY1` holds the autounique/unique key (string).
- Read errors:
  ```sql
  SELECT LINE, MESSAGE FROM ERRMSGS
   WHERE TYPE = 'i' AND USER = SQL.USER ORDER BY LINE FORMAT;
  ```
  (Or read the linked `STACK_ERR` file when `-stackerr` was used.) Read the `:$.MSG` ASCII parameter for the summary text the proc passes to PRINT.
- Verify rows landed in the **target form** via `websdk_form_action getRows` (e.g., `ORDERS` filter on the new ORDNAME from `KEY1` → `getRows` to confirm parent + subform records match expectations).
- Reload failed lines after fixing data with `'-repeat'` (only re-runs lines where `LOADED <> 'Y'`).

**See also:** `references/interfaces.md` § "Form Load Execution" + § "Error Handling" + § "Dynamic Interfaces", project `CLAUDE.md` § "Use form interfaces, not raw UPDATE/INSERT".
