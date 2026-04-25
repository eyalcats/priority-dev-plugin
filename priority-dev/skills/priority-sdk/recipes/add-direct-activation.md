# Add a direct activation to a form

**Triggers:** add direct activation, add activation, attach procedure to form, link procedure to form, FORMEXEC, add EXEC entry, run procedure from form, add a button to <form>

**Before:**
- Verify the parent form via `websdk_form_action` on EFORM with `filter ENAME=<FORM>`. If 0 rows, ask the user; do NOT propose a plausible alternative.
- Verify the activation target exists: a procedure (`EXEC TYPE='P'`), form (`TYPE='F'`), or report (`TYPE='R'`). Mismatch between `ETYPE` and the actual target type fails compile.
- Decide the deployment story: when shipping via `TAKEDIRECTACT` UPGCODE, the tooling auto-adds a companion `TAKESINGLEENT` for the activated procedure so INSTITLE on the target server can resolve the link (without it, INSTITLE skips EXEC entries on existing forms and INSTITLE fails with "Error linking").

**Calls:**
1. `websdk_form_action` on EFORM, single compound — uses `startSubForm FORMEXEC` on the parent row:
   ```json
   {"form":"EFORM","operations":[
     {"op":"filter","field":"ENAME","value":"<FORM>"},
     {"op":"getRows","fromRow":1},
     {"op":"setActiveRow","row":1},
     {"op":"startSubForm","name":"FORMEXEC"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"ETYPE","value":"P"},
     {"op":"fieldUpdate","field":"RUN","value":"<TARGET_PROC>"},
     {"op":"saveRow"}
   ]}
   ```
   Set `ETYPE` first ("P" for procedure, "F" for form, "R" for report), THEN `RUN` — fk validation reads `ETYPE` to scope the lookup.
2. The `getRows` between `filter` and `setActiveRow` is mandatory — without it, `newRow` may land on EFORM's meta-form silently.
3. Compile the parent form afterwards (see `recipes/compile-form.md`) — direct activations participate in the form's compile graph.

**After:**
- Re-read `FORMEXEC` on the parent (filter or scan rows) to confirm the new row exists with the expected `ETYPE`/`RUN`.
- Read PREPERRMSGS for the parent form — see `recipes/read-compile-errors.md`. A `RUN` value pointing at a non-existent or wrong-typed entity surfaces here.
- For deployment: pick `TAKEDIRECTACT` (NOT `TAKESINGLEENT`) on the UPGRADES row. The tooling auto-adds a `TAKESINGLEENT` for the activated procedure so the link resolves on the target.

**See also:**
- `references/websdk-cookbook.md` § "Add a direct activation"
- `recipes/compile-form.md`
- `recipes/read-compile-errors.md`
- `references/deployment.md` § UPGCODE choice (TAKEDIRECTACT auto-companion)
- Project `CLAUDE.md` § "Shell generation (UPGRADES revisions)"
