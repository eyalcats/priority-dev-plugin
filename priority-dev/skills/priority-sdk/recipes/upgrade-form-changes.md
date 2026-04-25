# Upgrade form changes (deploy via UPGRADES)

**Triggers:** upgrade form changes, deploy form changes, generate UPGNOTES, TAKEFORMCOL, TAKETRIG, push form to other server, ship a form change, build upgrade shell, take upgrade

**Before:**
- Identify the target UPGRADES revision (oldest unprepared on the dev server). Confirm `UPGNUM > 0` (UPGNUM=0 is invalid; `generate_shell` skips silently).
- Set `TRANSLATED='N'` on the revision before TAKEUPGRADE — otherwise it completes with no output and no error.
- Choose the most-specific UPGCODE per change. **Do NOT default to TAKESINGLEENT.** TAKESINGLEENT on a system form captures every column and trigger, including references to system-table columns the client may not have, and INSTITLE fails with "Missing column X in table Y".

  | Change | UPGCODE | Key fields |
  |---|---|---|
  | Column added/changed | `TAKEFORMCOL` | ENT=<form>, SONENTITY=<col name> |
  | Trigger added/changed | `TAKETRIG` | ENT=<form>, SONENTITY=<trigger name> |
  | Subform link added/changed | `TAKEFORMLINK` | ENT=<parent>, SONENTITY=<child form> |
  | Procedure step changed | `TAKEPROCSTEP` | ENT=<proc>, POS=<step pos> |
  | Report column changed | `TAKEREPCOL` | ENT=<report>, SONENTITY=<col name> |
  | Direct activation added | `TAKEDIRECTACT` | auto-adds companion `TAKESINGLEENT` for the activated proc — without it INSTITLE fails "Error linking" |
  | Schema change (column add on system table) | `DBI` | manual UPGNOTESTEXT, see below |
  | Brand-new custom entity | `TAKESINGLEENT` | only valid use |

  Deletions mirror: `DELFORMCOL`, `DELTRIG`, `DELFORMLINK`, `DELDIRECTACT`, `DELPROCSTEP`, `DELREPCOL`.
- For custom columns added to system tables via `run_inline_sqli(mode=dbi)`: Priority's change tracking does NOT see them, so TAKEUPGRADE will not auto-emit DBI. Add a manual `DBI` UPGNOTES entry (see Calls step 2). UPGNOTES order matters — DBI entries first (`ORD=1`), then TAKEFORMCOL/TAKETRIG.

**Calls:**
1. Stage entity captures via `websdk_form_action` on UPGRADES → filter to the revision → `startSubForm UPGNOTES` → one `newRow` per change:
   ```json
   {"form":"UPGRADES","operations":[
     {"op":"filter","field":"UPGNUM","value":"<N>"},
     {"op":"startSubForm","form":"UPGNOTES"},
     {"op":"newRow"},
     {"op":"fieldUpdate","field":"UPGCODE","value":"TAKEFORMCOL"},
     {"op":"fieldUpdate","field":"ENT","value":"<form>"},
     {"op":"fieldUpdate","field":"SONENTITY","value":"<col name>"},
     {"op":"fieldUpdate","field":"BOUND","value":"Y"},
     {"op":"fieldUpdate","field":"ORD","value":"<n>"},
     {"op":"saveRow"}]}
   ```
   UPGNOTES exposes UPGCODE (string), not UPGTYPE (numeric). Repeat per change. For TAKEDIRECTACT, the `generate_shell` compound auto-adds the companion TAKESINGLEENT for the activated entity — if hand-building UPGNOTES, add both rows.
2. For custom columns on system tables — add a DBI row (BOUND=Y, ORD=1, ahead of all TAKE* entries), then drop into its `UPGNOTESTEXT` subform and write the body — NO `EXEC` prefix, ASCII titles only, 68-char line limit:
   ```
   FOR TABLE <tablename>
   INSERT <colname> (<TYPE>, <WIDTH>, '<ASCII title>');
   ```
3. Clear `PREPARED='N'` on the revision before re-running TAKEUPGRADE — DOWNLOADUPG serves a cached shell otherwise.
4. Run `TAKEUPGRADE` (no prompts; writes `<UPGNUM>.sh` to `system/upgrades/`) or `DOWNLOADUPG` (prompts for "Run INSTITLE?" and lang code). On Priority Cloud, FileSmile download requires browser auth — fetch the shell from the Priority UI, not via Node.js.

**After:**
- `getRows` on UPGNOTES shows every staged entry with the right UPGCODE, ORD, BOUND='Y'.
- Verify the `<UPGNUM>.sh` file exists in `system/upgrades/`. Open it: DBI blocks (`DBI << \EOF … EOF`) appear before BRING blocks (`BRING << \EOF … EOF`). `EXECUTE << \EOF` is not valid — if you see one, the shell was hand-built incorrectly.
- INSTITLE on the target succeeds with no "Missing column" or "Error linking" errors. Note: INSTITLE skips direct-activation (EXEC code 3) entries for forms that already exist on the target — for new direct activations on a pre-existing form, add the FORMEXEC rows manually post-install (or include the activated proc via TAKESINGLEENT, which TAKEDIRECTACT already does for you).

**See also:** `references/deployment.md` (full); project `CLAUDE.md` § "Shell generation (UPGRADES revisions)" — § "Choosing the Right UPGCODE", § "System form upgrades — use TAKEFORMCOL, not TAKESINGLEENT", § "Custom columns on system tables need manual DBI UPGNOTES entries"; `references/debugging.md` § "Revisions and Customizations".
