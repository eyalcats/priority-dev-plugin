# Add a column with a join (foreign key)

**Triggers:** add a column with a join, add a foreign key column, add column from another table, add lookup column, add fk column, import a column from another table

**Before:**
- Verify the form name via `websdk_form_action` on EFORM with `filter ENAME=<form>` (form name != table name). If 0 rows, ask the user.
- Verify the foreign (join) table exists via `run_windbi_command priority.displayTableColumns` with `entityName=<JOIN_TABLE>`, and confirm the key column name on that table.
- Identify the local FK column on the base table (the one whose value matches `JOIN_TABLE.<key>`).
- Pick `POS` slots for both the base column and the imported column; for custom columns on system forms set `IDCOLUMNE >= 6`.

**Calls:**
1. `websdk_form_action` on EFORM — add the **base table** column with the join, then the **imported** column:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FCLMN"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"NAME","value":"<BASE_COL>"},
     {"op":"fieldUpdate","field":"CNAME","value":"<BASE_COL>"},
     {"op":"fieldUpdate","field":"TNAME","value":"<BASE_TABLE>"},
     {"op":"fieldUpdate","field":"POS","value":"70"},
     {"op":"fieldUpdate","field":"JTNAME","value":"<JOIN_TABLE>"},
     {"op":"fieldUpdate","field":"JCNAME","value":"<JOIN_KEY_COL>"},
     {"op":"saveRow"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"NAME","value":"<DISPLAY_COL>"},
     {"op":"fieldUpdate","field":"CNAME","value":"<DISPLAY_COL>"},
     {"op":"fieldUpdate","field":"TNAME","value":"<JOIN_TABLE>"},
     {"op":"fieldUpdate","field":"POS","value":"80"},
     {"op":"fieldUpdate","field":"READONLY","value":"R"},
     {"op":"saveRow"}
   ]}
   ```
   Join info (`JTNAME`, `JCNAME`) goes on the **base-table column row** — NOT on the imported column row. Imported rows leave `JTNAME`/`JCNAME` empty and use `TNAME=<JOIN_TABLE>`.
2. Compile: `{"operations":[{"op":"compile","entity":"<FORM>"}]}`.

**After:**
- Read FORMPREPERRS authoritatively — `EFORM filter ENAME=<form> -> startSubForm FORMPREPERRS -> getRows`. Any non-empty `PREPERRMSGS` = failure. Do NOT trust compound `status: "ok"` alone.
- `getRows` on FCLMN (filter NAME=<BASE_COL>) — verify `IDJOINE` displays as a **1-char picker token** (e.g. `"6"`, `"0?"`, `"!"`), NOT the raw FORMCLMNS.IDJOIN integer like `"10"`. `IDJOINE` is the EFORM-layer CHAR(1) alias; the underlying `FORMCLMNS.IDJOIN` (INT(2)) is opaque — do not copy it back into `fieldUpdate(IDJOINE, ...)` (see `common-mistakes.md` § "Setting `IDJOINE` to a multi-digit value via `fieldUpdate`").
- A type-mismatch error (`עמודת החיבור אינה מטיפוס זהה` / "join column type mismatch") means JTNAME/JCNAME landed on the imported row instead of the base row — fix the placement.

**See also:**
- `references/websdk-cookbook.md` § "Add a column with a join (foreign key)"
- `references/forms.md` § "How to Define a Join (Step by Step)"
- `references/common-mistakes.md` § "Setting `IDJOINE` to a multi-digit value via `fieldUpdate`"
- `recipes/read-compile-errors.md`
