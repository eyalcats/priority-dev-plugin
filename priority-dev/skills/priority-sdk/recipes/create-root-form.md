# Create a root form on a custom table

**Triggers:** create a form, create a root form, new form on <table>, make a form for <table>, build a form, scaffold a root form

**Before:**
- Verify the base table exists: `run_windbi_command priority.displayTableColumns entityName=<TABLE>`. If it does not exist, create it first via `recipes/create-table.md`.
- Confirm the form NAME is free: `websdk_form_action` on EFORM with `filter ENAME=<NEW_FORM>` returns 0 rows.
- Pick a 4-letter prefix (e.g. `SOF_`, `ASTR_`); NAME must be ≤ 20 chars, alnum+underscore, leading letter. By convention NAME often matches the table name but it can differ.
- Module = `'פיתוח פרטי'` (Internal Development) — `MODULENAME` field, NOT `DNAME`. `EDES` (entity group) = the prefix without the underscore (e.g. `'SOF'`).
- **Critical:** raw EFORM `newRow` does NOT auto-compile (cookbook line 586). After `saveRow`, the form exists in metadata but is unusable until you explicitly compile. Any WebSDK attempt to open it returns `המסך לא מוכן`.
- Raw `newRow` is NOT safe for forms over **system** tables (DOCUMENTS, INVOICES, ACCOUNTS) — those still need the UI Form Generator. This recipe covers custom-prefix tables only.

**Calls:**
1. `websdk_form_action` on EFORM, single compound:
   ```json
   {"form":"EFORM","operations":[
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"ENAME","value":"<NEW_FORM>"},
     {"op":"fieldUpdate","field":"TITLE","value":"<Hebrew or ASCII title>"},
     {"op":"fieldUpdate","field":"TNAME","value":"<TABLE>"},
     {"op":"fieldUpdate","field":"EDES","value":"<PREFIX>"},
     {"op":"fieldUpdate","field":"MODULENAME","value":"פיתוח פרטי"},
     {"op":"saveRow"}
   ]}
   ```
   On `saveRow` with `TNAME` set, Priority **auto-seeds FCLMN** with every column at POS 10/20/30...
2. Tweak seeded columns as needed (set `COLTITLE`, `HIDEBOOL=Y`, `BOOLEAN=Y`, etc.) per `recipes/add-column.md`. Add custom columns the same way.
3. **Compile explicitly** — raw `newRow` does NOT compile. Run `run_windbi_command priority.prepareForm entityName=<NEW_FORM>`, or compound `{"operations":[{"op":"compile","entity":"<NEW_FORM>"}]}` on EFORM.

**After:**
- Read FORMPREPERRS for the new form: `EFORM filter ENAME=<NEW_FORM> -> startSubForm FORMPREPERRS -> getRows`. Any non-empty `PREPERRMSGS` row = compile failure (do NOT trust the compound's `status: "ok"` alone — see `recipes/read-compile-errors.md`).
- Smoke check: `startForm <NEW_FORM>` then `getRows`. Form opens cleanly = ready. `המסך לא מוכן` = compile is not actually clean, even if the op said success.
- `getRows` on FCLMN to confirm the auto-seeded columns are present.

**See also:**
- `references/forms.md` § "Creating a root form on a custom-prefix table"
- `references/websdk-cookbook.md` § "Create a new root form on a custom table"
- `recipes/add-column.md`, `recipes/read-compile-errors.md`, `recipes/compile-form.md`
