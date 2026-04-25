# Copy / duplicate an entity (form, report, procedure, interface)

**Triggers:** copy form, duplicate form, copy report, duplicate report, copy procedure, duplicate procedure, copy interface, duplicate interface, copy entity, duplicate <X>, clone procedure, clone form

**Before:**
- Verify SOURCE name exists and matches the right kind — query the relevant generator (`EFORM` / `EREP` / `EPROG` / `EINTER`) via `websdk_form_action filter ENAME=<source>`, or use SQLI on EXEC (`SELECT ENAME, TYPE FROM EXEC WHERE ENAME='<source>'`). Form name is NOT the table name.
- Pick TARGET — ≤ 20 chars, leading letter, alnum + underscore. Custom entities require a 4-letter prefix (e.g., `ACME_*`, `ZZZ_*`).
- Confirm TARGET does not already exist (same query, expect 0 rows). System forms are off-limits — never copy `ORDERS`, `AINVOICES`, `EFORM`, etc. Only `ASSETREP` (report-generator) is whitelisted, see `reports.md`.

**Calls:**
1. Single `websdk_form_action` compound — no `form` parameter; the bridge drives `priority.procStart('COPYPROG'|'COPYREP'|'COPYFORM'|'COPYINTER', 'P')` and supplies BOTH source and target as fields of the SAME `inputFields` step:
   ```json
   {"operations":[
     {"op":"copyEntity",
      "kind":"proc",
      "source":"<SOURCE>",
      "target":"<TARGET>"}]}
   ```
   `kind` ∈ `proc` / `report` / `form` / `interface` → `COPYPROG` / `COPYREP` / `COPYFORM` / `COPYINTER`. Calling `inputFields` twice (source first, target second) puts the proc into "current procedure no longer active" — see `common-mistakes.md` § "Driving COPY* manually…in two separate inputFields calls". The compound exists precisely to avoid this trap; do not hand-roll.

**After:**
- Result `status: "ok"` AND `data.trace` ends with a `message` step of `messagetype='information'` (Hebrew "העתקת הפרוצדורה הסתיימה בהצלחה" or English "Copy completed successfully") followed by `type='end'`. A trailing `messagetype='error'` means the copy did not land — read the message text and fix.
- `filter ENAME=<TARGET>` on the relevant generator returns 1 row.
- Apply post-copy tweaks COPY* programs do NOT carry:
  - **COPYPROG** — re-link to menus / forms / other procedures; set the output title (not copied).
  - **COPYREP** — re-link to menus.
  - **COPYFORM** — for `ASSETREP`-style generator copies, edit the PRE-FORM trigger's prefix variable AND every `LIKE '<prefix>%'` expression to your new prefix (forms.md / reports.md).
  - **COPYINTER** — review GENERALLOAD column mappings; the load target carries over but field mappings often need editing.

**Fallback (only if the compound errors):** see `procedures.md` § "Copying existing entities" for the manual `procStart` + single `inputFields` pattern, or run `WINPROC -P COPYPROG` from the server shell.

**See also:**
- `references/procedures.md` § "Copying existing entities (COPYPROG / COPYREP / COPYFORM / COPYINTER)" + § "The subtle inputFields gotcha"
- `references/common-mistakes.md` § "Hand-rebuilding a procedure / report / form / interface instead of using COPY*" + § "Driving COPY* manually by sending source and target in two separate inputFields calls"
- `bridge/src/websdk/compounds.ts` → `generateCopyEntityScript` (kind→COPY* mapping at line 812-822)
