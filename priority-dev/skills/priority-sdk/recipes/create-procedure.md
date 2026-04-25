# Create a procedure

**Triggers:** create a procedure, new procedure, scaffold a procedure, make a proc <name>, add a procedure

**Before:**
- If duplicating an existing procedure, **stop here and use `recipes/copy-entity.md` (kind=proc)** instead — `COPYPROG` carries steps, parameters, step queries, and procedure messages that hand-rebuilding silently loses.
- Verify the target NAME does not already exist:
  `run_inline_sqli "SELECT ENAME FROM EXEC WHERE ENAME = '<NAME>' AND TYPE = 'P'"` (expect 0 rows).
- Pick NAME with a 4-letter custom prefix (e.g., `ACME_CALC_MFG`), ≤ 20 chars, alnum + underscore, leading letter, no reserved words.
- Decide TYPE / RS:
  - blank `RS` — plain program procedure
  - `RS='R'` — wraps a report (note: PROGFORMATS subform is then gated; print formats live in document designer)
  - `RS='N'` — runs a report but suppresses the Print/Send Options dialog
- Module = "Internal Development" so the proc is portable across Priority module licenses.
- The Procedure Generator form is **`EPROG`**, not EPROC.

**Calls:**
1. Create the procedure header on `EPROG`:
   ```json
   {"operations":[
     {"op":"newRow","form":"EPROG"},
     {"op":"fieldUpdate","form":"EPROG","field":"ENAME","value":"<NAME>"},
     {"op":"fieldUpdate","form":"EPROG","field":"TITLE","value":"<TITLE up to 32 chars>"},
     {"op":"fieldUpdate","form":"EPROG","field":"MODULE","value":"Internal Development"},
     {"op":"saveRow","form":"EPROG"}
   ]}
   ```
2. (Optional) set `RS` if the proc wraps a report; set `EDES`/output title via the Output Title sub-level form if the title needs to exceed 32 chars.
3. Add steps next — see `recipes/add-procedure-step.md`. Build order: parameters / INPUT step → SQLI / processing step(s) → terminal step (REPORT, PRINT, END).

**After:**
- Confirm header landed:
  `run_inline_sqli "SELECT ENAME, TITLE, RS FROM EXEC WHERE ENAME = '<NAME>' AND TYPE = 'P'"` (expect 1 row).
- Smoke-run via `procStart`:
  `{"operations":[{"op":"procStart","name":"<NAME>","type":"P"}]}` — for parameterless procs the trace ends in a `message` / `end` step. For procs with required input, supply via `inputFields`.
- If the proc has steps with errors, run `priority.syntaxCheck` (Action from EPROG) before activation.

**See also:** `references/procedures.md` § "Procedure Attributes" + § "Run Procedures", `recipes/copy-entity.md`, `recipes/add-procedure-step.md`.
