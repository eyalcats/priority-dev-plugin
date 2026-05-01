# Deployment via upgrade shells

> Canonical guide for moving Priority entities between servers via the UPGRADES revision mechanism. For legacy background (revision lifecycle, INSTITLE translation, Language Dictionaries, troubleshooting matrices), see `debugging.md` § "Revisions and Customizations".

Priority ships code between servers via revisions on the UPGRADES form. Each revision's notes (UPGNOTES) list entities to capture; TAKEUPGRADE builds a shell file; DOWNLOADUPG delivers the shell; INSTITLE applies it on the target.

This file answers the questions that matter most during automated shell generation:
- Which UPGCODE do I use for a given change?
- How do I get a DBI change onto a system table into the shell?
- What rules must hold before TAKEUPGRADE will actually produce output?

## Choosing the right UPGCODE

**Use the most specific UPGCODE per change. `TAKESINGLEENT` is only for brand-new entities.**

| Change | UPGCODE | Notes |
|---|---|---|
| Trigger changed | `TAKETRIG` | `trigger` field = trigger name |
| Column added/changed | `TAKEFORMCOL` | `trigger` field = column name |
| Subform link added/changed | `TAKEFORMLINK` | `sonEntity`, `sonType` |
| Procedure step changed | `TAKEPROCSTEP` | `pos` = step position |
| Report column changed | `TAKEREPCOL` | `trigger` field = column name |
| Direct activation added | `TAKEDIRECTACT` | Auto-adds companion `TAKESINGLEENT` for `sonEntity` |
| Procedure message added/changed | `TAKEPROCMSG` | |
| Trigger message added/changed | `TAKETRIGMSG` | |
| Entity title/attributes only | `TAKEENTHEADER` | |
| Schema change (CREATE TABLE, column adds) | `DBI` | Write DBI in UPGNOTESTEXT — see below |
| Brand-new custom entity (form/proc/report) | `TAKESINGLEENT` | Only valid use |

Deletions follow the mirror pattern: `DELTRIG`, `DELFORMCOL`, `DELFORMLINK`, `DELDIRECTACT`, `DELPROCSTEP`, `DELREPCOL`, `DELPROCMSG`, `DELTRIGMSG`.

### Why specificity matters

`TAKESINGLEENT` on a system form captures ALL its columns and triggers — including references to system table columns that may not exist on the client's Priority version. This causes `Missing column X in table Y` failures at INSTITLE time.

For system-form changes, always use `TAKEFORMCOL` / `TAKETRIG` / `TAKEFORMLINK` per-change.

## Order of UPGNOTES entries

DBI entries first (`ORD=1`), then entity captures (`TAKEFORMCOL`, `TAKETRIG`, etc.). The generator respects the ORD column when building the shell, and DBI blocks must run before BRING blocks reference the new columns.

## DBI in UPGNOTES for system-table columns

Custom columns on system tables (added via `run_inline_sqli(mode="dbi")` or ad-hoc DBI) **bypass Priority's change tracking**. `TAKEUPGRADE` does not auto-generate DBI for them. The shell ships without the schema change, and INSTITLE fails on the target with "Unresolved identifier" referencing the missing column.

Fix: manually add a `DBI` entry to UPGNOTES with `BOUND='Y'`, `ORD=1`. Populate the `UPGNOTESTEXT` subform on that DBI row with the DBI body:

```
FOR TABLE <tablename>
INSERT <colname> (<TYPE>, <WIDTH>, '<ASCII title>');
```

Rules:
- **No `EXEC` prefix** — the shell wraps it in `DBI << \EOF … EOF` automatically. An `EXEC` line causes a parse error.
- **ASCII titles only** — Hebrew in UPGNOTESTEXT may cause encoding failures. Set the Hebrew title via a follow-up `TAKEFORMCOL` or `FCLMN.COLTITLE` update.
- **68-char max line width** — standard Priority SQLI rule; applies inside UPGNOTESTEXT too.

After adding the entry, clear `PREPARED='N'` on the revision before re-running TAKEUPGRADE — DOWNLOADUPG serves a cached shell otherwise.

## TAKEUPGRADE silent completion

TAKEUPGRADE can complete with no shell generated and no error. Known causes:

- `TRANSLATED='Y'` on the revision. Set `TRANSLATED='N'` before running TAKEUPGRADE.
- `UPGNUM=0` on the revision. Invalid; the `generate_shell` tool skips these automatically. If forcing it manually, renumber first.

Verify by checking the `system/upgrades/` directory for the expected `<UPGNUM>.sh` file.

## TAKEDIRECTACT auto-companion

When adding a direct activation, `generate_shell` auto-adds a companion `TAKESINGLEENT` for the activated entity (`sonEntity`). Without this, INSTITLE on the target fails with "Error linking" because the entity definition is missing from the shell.

If building UPGNOTES manually (not via `generate_shell`), add both rows.

### INSTITLE skips existing forms' EXEC entries

INSTITLE skips direct-activation (`EXEC`) entries for forms that already exist on the target. New direct activations added to a form that the target already has will silently fail to install. Workaround: add the `EXEC` rows manually via DBI on the target, or via the FORMEXEC subform after installation.

## Programmatic revision via WebSDK

When automating shell generation from a VSCode extension or agent:

- Open UPGRADES, find the oldest unprepared revision.
- Open UPGNOTES subform: `startSubForm('UPGNOTES', …)`.
- Insert rows: `newRow()` → `fieldUpdate('UPGCODE', 'TAKETRIG')` → `fieldUpdate('ENAME', …)` → `fieldUpdate('TYPE', …)` → `fieldUpdate('BOUND', 'Y')` → `saveRow(0)`.
- **UPGNOTES exposes UPGCODE (string)**, not UPGTYPE (numeric ID). Use the modification-code string directly.
- Subform `endCurrentForm()` may hang on certain forms. Use a timeout and close the parent if needed.
- Reopen UPGRADES fresh before `activateStart('TAKEUPGRADE', 'P', null)` — the form can be in a bad state after subform-close timeout.

## Shell file format

A prepared `.sh` has three block types:

1. `echo` — progress messages during install.
2. `DBI << \EOF … EOF` — schema changes (runs first).
3. `BRING << \EOF … EOF` — binary-coded entity definitions.

`EXECUTE << \EOF` is NOT valid; do not construct shells that use it.

### BRING binary codes

Each line in a BRING block starts with a numeric record-type code:

| Code | Meaning |
|---|---|
| 3 | Direct activation (Action) link |
| 7 | Procedure step definition |
| 9 | Procedure parameter definition |
| 17 | Entity definition header |
| 28 | SQLI code line |

## DOWNLOADUPG vs TAKEUPGRADE

Both prepare the shell file on the UPGRADES form:

- **TAKEUPGRADE** — no prompts; writes `<UPGNUM>.sh` to `system/upgrades/`.
- **DOWNLOADUPG** — adds two prompts:
  - "Run INSTITLE?" — if set, auto-runs INSTITLE after shell generation.
  - "Lang. Code" — target language for INSTITLE translation.

On Priority Cloud, FileSmile download requires browser auth — download shells from the Priority UI, not via Node.js. On local/on-prem servers, direct download via Node.js works.

## FORMEXEC subform for direct activations

Query or add direct activations via EFORM → FORMEXEC subform. Fields:

- `TABLE` — EXEC ID of the parent form (not a table name).
- `ENAME` — activated entity name.
- `TYPE` — `F` (form), `P` (procedure), `M` (menu).
- `TITLE` — display title of the activation.

## Direct SQL alternative (DELETE / INSERT into UPGNOTES)

When programmatic WebSDK is too slow for bulk UPGNOTES population, direct SQL on the UPGNOTES table works — but bypasses form triggers. Limit to dev-server revision building, and use WebSDK for single-row ad-hoc additions.

## Invalid revisions

- **`UPGNUM=0`** — invalid; the `generate_shell` tool skips automatically.
- **Revisions where `TRANSLATED='Y'` already** — TAKEUPGRADE silently no-ops.
- **Revisions with no UPGNOTES entries** — TAKEUPGRADE runs but produces an empty shell.

## Decommission recipe — custom form + table

When removing a custom form and its backing table, execute the following
steps in order. Each step removes a dependent that blocks the next:

1. **Remove EMENU rows**: Delete menu links via EFORM or direct SQL
   (`DELETE FROM EMENU WHERE EXEC = <form_exec> AND TYPE = 'F'`).
   Skipping this produces: `ערך קיים במסך 'מופעל מתפריט/מסך'` on EFORM deleteRow.

2. **Empty trigger code, then delete FTRIG rows**: For each trigger slot,
   call `write_to_editor(content='')` then `EFORM > FTRIG > deleteRow`.
   An empty FORMTRIGTEXT is required before the FTRIG slot can be deleted.
   Skipping this produces: `ערך קיים במסך 'הפעלות המסך - שאילתות SQL'`.

3. **Delete FORMMSG rows**: `EFORM > FORMMSG > deleteRow` for each custom
   message (NUM >= 500).

4. **Delete FCLMN rows**: `EFORM > FCLMN > setActiveRow(1) + deleteRow`
   in a loop until empty.
   Skipping this produces: `ערך קיים במסך 'עמודות המסך'`.

5. **Delete the EFORM row**: `EFORM > deleteRow` on the parent.

6. **DBI DROP TABLE**: `run_inline_sqli(mode="dbi", sql="DELETE TABLE <NAME>;")`.

The Hebrew error messages serve as diagnostic signals — each names the
blocking subform. Peel in reverse order.

*(seen in: TGML_CONST — verified 2026-04-30, 17 ops: 1 menu + 1 trigger +
1 message + 12 columns + 1 form + 1 DBI. Applicable to all 124+ custom forms
with triggers in this environment.)*

## Related references

- `debugging.md` § "Revisions and Customizations" — revision lifecycle, Language Dictionaries, INSTITLE behaviour, legacy troubleshooting matrices.
- `tables-and-dbi.md` § "DBI pitfalls" — DBI syntax rules that apply inside UPGNOTESTEXT.
- `forms.md` § "Managing forms and columns via WebSDK" — recipes for the form operations that generate the changes a revision later captures.
