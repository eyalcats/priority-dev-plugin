# Read compile errors

**Triggers:** read compile errors, why did compile fail, FORMPREPERRS, PREPERRMSGS, prepare errors, show compile output, what broke

**Before:**
- FORMPREPERRS is the UI-facing form over the `PREPERRMSGS` table. It is **overwritten per compile** but **persists across sessions** — a fresh `getRows` can show stale entries from an earlier compile attempt on the same entity. Cross-check each entry against the current buffer before chasing it.
- Treat any non-empty `PREPERRMSGS` row set as **failure** — do NOT trust the compound `compile` op's `status: "ok"`; it has been observed returning success while PREPERRMSGS retained real, blocking errors.
- The `websdk_form_action FORMPREPERRS getRows` view is session-filtered and can return `{}` even when PREPERRMSGS itself has rows. The authoritative source is a direct SQLI query against `PREPERRMSGS`.

**Calls:**
1. Authoritative — direct SQLI:
   ```sql
   SELECT FORMNAME, COLNAME, TRIGNAME, MESSAGE, SEVERITY, LINE
   FROM   PREPERRMSGS
   WHERE  FORMNAME = '<FORM>' OR MAINFORM = '<FORM>'
   ORDER  BY LINE
   FORMAT;
   ```
   Run via `run_inline_sqli` (mode=`sqli`). Zero rows = clean.
2. UI-facing fallback when SQLI is unavailable — `websdk_form_action`:
   ```json
   {"form":"FORMPREPERRS","operations":[{"op":"getRows"}]}
   ```
   FORMPREPERRS has no filterable columns; it auto-shows last-compile errors. Treat `{}` here with skepticism — confirm via SQLI before declaring clean.
3. Cross-check the form opens: `{"form":"<FORM>","operations":[{"op":"getRows"}]}`. `המסך לא מוכן` = still broken regardless of what step 1/2 reported.

**After:**
- Classify each row by error path (`FORM/COLUMN/EXPR`, `FORM/TRIGGER`, etc.) — see `references/compile-debugging.md` § "Reading compile error paths" for the metadata table behind each shape.
- Apply one fix per error, recompile, re-read PREPERRMSGS. Scratch triggers travel in packs — expect new errors after each fix.
- Stop after ~5 non-converging passes and ask the user — likely a design issue, not a bug.

**See also:**
- `references/compile-debugging.md` (full error class catalog and triage queries)
- `references/websdk-cookbook.md` § "Compile-status signals: PREPERRMSGS is authoritative, `compile` op status can lie"
- `recipes/compile-form.md`
- `recipes/add-direct-activation.md`
