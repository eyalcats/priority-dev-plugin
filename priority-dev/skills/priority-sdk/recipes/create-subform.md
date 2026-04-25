# Create a subform

**Triggers:** create a subform, new subform, make a subform on <table>, add data subform, build a child form

**Before:**
- Verify the parent form name via `websdk_form_action` on EFORM with `filter ENAME=<PARENT>` (form name != table name; do not guess).
- Verify the backing table for the new subform exists (`run_windbi_command priority.displayTableColumns entityName=<TABLE>`). If the table is missing, create it first via `recipes/create-table.md`.
- Pick a form NAME with a 4-letter custom prefix (<= 20 chars, alnum + underscore).
- Confirm the parent's key column name (FK column the child shares with the parent) — Priority binds parent<->child by column-name convention.

**Calls:**
1. EFORM -> `newRow` -> `fieldUpdate` for `ENAME=<CHILD>`, `TNAME=<TABLE>`, `EDES=<3-letter prefix>`, `TITLE=<title>`, `MODULENAME=<module>` -> `saveRow`. FCLMN auto-seeds all columns of `<TABLE>`.
2. EFORM -> `filter ENAME=<CHILD>` -> `getRows` -> `setActiveRow row=1` -> `startSubForm FCLMN`. Hide the parent-link column: `filter NAME=<PARENTKEY>` -> `setActiveRow row=1` -> `fieldUpdate HIDEBOOL=Y` -> `saveRow`. DO NOT set `EXPRESSION=Y` and DO NOT add an FCLMNA row — Priority binds via FLINK metadata.
3. (Optional) Add additional columns or hide more columns per `recipes/add-column.md` / `recipes/hide-column.md`.
4. Compile the child: compound `{op: "compile", entity: "<CHILD>"}` on EFORM (raw EFORM `newRow` does NOT auto-compile).
5. Wire FLINK on the parent per `recipes/add-subform-link.md`, then compile the parent.

**After:**
- Read FORMPREPERRS for `<CHILD>` and `<PARENT>` via `websdk_form_action` on EFORM -> `filter ENAME=<form>` -> `startSubForm FORMPREPERRS` -> `getRows`. Any non-empty `PREPERRMSGS` = failure.
- `getRows FLINK` on the parent shows the new subform row.
- Smoke test: `startForm <PARENT>` then navigate the new subform.

**See also:**
- `references/websdk-cookbook.md` "Create a subform + link it to a parent"
- `references/forms.md` "Linking Upper-level and Sub-level Forms"
- `recipes/add-subform-link.md`, `recipes/create-text-subform.md`, `recipes/read-compile-errors.md`
