# Add a procedure step

**Triggers:** add a procedure step, add SQLI step, add step to <proc>, new step on procedure, add INPUT step, add report step, add basic-command step

**Before:**
- Verify the procedure exists:
  `run_inline_sqli "SELECT ENAME FROM EXEC WHERE ENAME = '<PROC>' AND TYPE = 'P'"` (expect 1 row). If it doesn't, use `recipes/create-procedure.md` first.
- Pick the step `NAME` (entity name of the step) and `ORD` (execution order — sequential integers; reorder later by inserting a duplicate at the new ORD and deleting the original).
- Decide step `TYPE` (ETYPE):
  - `R` Report (after data processing) · `F` Form (input data) · `P` sub-procedure
  - `B` Basic command (INPUT, MESSAGE, CHOOSE, GOTO, END, PRINT, etc.)
  - `I` Form-load INTERFACE step · `L` Table-load DBLOAD step · `C` Compiled program / SQLI
- Decide command (for `B` / `C`): `INPUT`, `SQLI`, `CHOOSE`, `GOTO`, `MESSAGE`, `PRINT[CONT|ERR]`, `END`, etc. Suffix-`F` variants display when run as form Action.
- For SQLI steps that reference parameters, use `:$.PARAMNAME` (current procedure) or `:ProcName.PARAMNAME`. Cursor budget per proc: ≤ 100. Message buffer per SQLI step: ≤ 100 messages — use `GOTO` loop to flush more.

**Calls:**
1. Open the procedure on `EPROG` and drill into the steps subform:
   ```json
   {"operations":[
     {"op":"filter","form":"EPROG","field":"ENAME","value":"<PROC>"},
     {"op":"startSubForm","form":"EPROG","subForm":"PROGSTEPS"},
     {"op":"newRow","form":"PROGSTEPS"},
     {"op":"fieldUpdate","form":"PROGSTEPS","field":"NAME","value":"<STEPNAME>"},
     {"op":"fieldUpdate","form":"PROGSTEPS","field":"ETYPE","value":"<R|F|P|B|I|L|C>"},
     {"op":"fieldUpdate","form":"PROGSTEPS","field":"ORD","value":<n>},
     {"op":"fieldUpdate","form":"PROGSTEPS","field":"TITLE","value":"<title>"},
     {"op":"saveRow","form":"PROGSTEPS"}
   ]}
   ```
2. Add parameters via the `PROGPARAM` sub-level (each row: `NAME` ≤ 3 chars, `TYPE`, `POS`, `TITLE`, `EXPR`/`VALUE`, `HIDE` as needed). For CHOOSE: `POS=0` is the target var, `POS=10/20/...` are option labels with `EXPR=<int>`, `HIDE=I`.
3. **For SQLI / step-query content** (commands `SQLI`, `INPUT`, `HTMLCURSOR`, `HTMLEXTFILES`):
   ```
   open_priority_file (entityType=PROC, entityName=<PROC>, stepName=<STEPNAME>)
   write_to_editor entityType=PROC, entityName=<PROC>, stepName=<STEPNAME>, content=<full SQLI>
   ```
   `open_priority_file` is required first so the editor path is set — otherwise compile won't pick up the new buffer. Always send the **full** step content, never a partial diff.
4. Compile: `run_windbi_command priority.prepareProc` (with the proc file open in VSCode).

**After:**
- `getRows` on `PROGSTEPS` confirms the step is present at the expected ORD.
- Compile output empty / "OK" → step is good. Any error → fix and re-run `priority.prepareProc` (do NOT proceed past a compile error).
- Smoke-run via `procStart`: `{"operations":[{"op":"procStart","name":"<PROC>","type":"P"}]}` — trace shows the step executing in order.

**See also:** `references/procedures.md` § "Procedure Steps" + § "Procedure Step Queries" + § "Procedure Parameters", `recipes/create-procedure.md`, `recipes/run-interface.md` (for type-`I` steps).
