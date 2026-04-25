# Compile a form

**Triggers:** compile form, prepare form, prepareForm, recompile, compile <form>, prepare <form>

**Before:**
- Confirm the form exists: `websdk_form_action` on EFORM with `filter ENAME=<FORM>`. If 0 rows, ask the user; do NOT propose a plausible alternative.
- If you just edited a column-level trigger via `FORMCLTRIGTEXT` or another non-EFORM table, no extra step is needed — `compile` re-reads the metadata fresh.

**Calls:**
1. `websdk_form_action` compound op (no `form` parameter — `compile` is form-agnostic):
   ```json
   {"operations":[{"op":"compile","entity":"<FORM>"}]}
   ```
2. Alternative: `run_windbi_command priority.prepareForm` with `entityName=<FORM>` (active file in VSCode must be the form). Use this when you want the WINDBI panel output, but be aware the panel renders in webview and is not capturable.

**After:**
- WARNING: the compound's `status: "ok"` (or "התכנית הסתיימה בהצלחה") **can lie**. Observed cases returned success while PREPERRMSGS retained real errors and the form failed to open. Never treat the compound status as a cleanliness signal.
- Authoritative verification: read `PREPERRMSGS` via `websdk_form_action` on FORMPREPERRS — `EFORM filter ENAME=<FORM> -> startSubForm FORMPREPERRS -> getRows`. Zero rows = clean.
- Cross-check: run `getRows` on the form itself. If it returns `המסך לא מוכן`, compile is NOT clean regardless of the op status.
- Trust `compile` only when BOTH PREPERRMSGS is empty AND the form opens cleanly via `getRows`.

**See also:**
- `recipes/read-compile-errors.md`
- `references/websdk-cookbook.md` § "Compile a form" and "Compile-status signals: PREPERRMSGS is authoritative, `compile` op status can lie"
- `references/compile-debugging.md` § "Reading compile state — three signals, only one is authoritative"
- `recipes/add-direct-activation.md`
