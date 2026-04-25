# Add a subform link

**Triggers:** add a subform link, link a subform, attach subform to parent, add subform to <form>, wire FLINK, link child form

**Before:**
- Verify the parent form name via `websdk_form_action` on EFORM with `filter ENAME=<PARENT>` (form name != table name; do not guess).
- Verify the child subform exists the same way (`filter ENAME=<CHILD>` on EFORM).
- Identify the join key columns on parent and child (Priority binds parent->child by column-name convention; FLINK does not expose parent-key / child-key fields).
- Decide display position (`APOS`, lower = higher).

**Calls:**
1. EFORM -> `filter ENAME=<PARENT>` -> `getRows` -> `setActiveRow row=1`.
2. `startSubForm name=FLINK` on the parent EFORM row.
3. `newRow`, then `fieldUpdate` for `FNAME=<CHILD>`, `TITLE=<title shown in parent>`, `APOS=<int>`, `MODULENAME=<module>`. Note: the field is `FNAME` (not `ENAME`).
4. `saveRow`.
5. Compile the parent: compound `{op: "compile", entity: "<PARENT>"}` on EFORM, or `run_windbi_command priority.prepareForm` with `entityName=<PARENT>`.

**After:**
- Read FORMPREPERRS for `<PARENT>` via `websdk_form_action` on EFORM -> `filter ENAME=<PARENT>` -> `startSubForm FORMPREPERRS` -> `getRows`. Any non-empty `PREPERRMSGS` row = failure; do not trust an "ok" compound status alone.
- `getRows FLINK` on the parent confirms the new row.
- Optional smoke check: `startForm <PARENT>` then `getRows` on the new subform name.

**See also:**
- `references/forms.md` "Linking Upper-level and Sub-level Forms"
- `references/websdk-cookbook.md` "Add a subform link (generic, minimal)" and "Create a subform + link it to a parent"
- `recipes/create-subform.md`, `recipes/read-compile-errors.md`
