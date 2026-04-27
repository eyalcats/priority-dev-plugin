# Delete an entity (form, report, procedure, menu, trigger, field, direct activation)

**Triggers:** delete form, drop form, remove form, delete report, delete procedure, delete menu, delete trigger, drop trigger, delete column, delete field, drop column, remove column, delete activation, remove direct activation, delete entity, cleanup scratch entity

**No built-in `DELFORM` / `DELPROG` generator exists** for entity definitions (as of 2026-04-25 — only data-cleanup procs like `DELPRIVATEFORM` for UI personalisation). Deletion is **always** raw DBI on metadata tables, so:

1. Form-metadata tables don't fire business triggers — raw DELETE is technically safe.
2. The project rule "Form interface > raw UPDATE/INSERT" still applies — **explicit per-deletion user approval is mandatory**, even on scratch entities.
3. **Show row counts up-front** so the user sees blast radius before approving.

> **Placeholders in the SQL below:** `<NAME>`, `<FID>`, `<RID>`, `<PID>`, `<IID>`, `<MENUID>`, `<ITEMID>`, `<COL>`, `<TID>`, `<TNAME>`, `<ACTIVATION>`, `<FORM>`, `<KEPT>` are literal placeholders — substitute them before running. Do NOT paste these blocks unchanged; SQLI will reject `<…>` as a parse error.

---

## Before (every kind)

1. Resolve the EXEC id and TYPE:
   ```sql
   SELECT EXEC, ENAME, TYPE, TITLE FROM EXEC WHERE ENAME = '<NAME>' FORMAT;
   ```
   - `TYPE` codes: `F`=Form, `R`=Report, `P`=Procedure, `M`=Menu, `I`=Interface, `T`=Table.
   - 0 rows = nothing to delete; tell the user, do not guess.
   - System entities (`TYPE='F'` and ENAME = `INVOICES`/`ORDERS`/etc., or any entity whose `MODULENAME` is not `פיתוח פרטי` / "Internal Development") are off-limits without an explicit "yes, the system one" from the user.

2. Scan inbound references — anything that points at the target by id will break if you delete:
   ```sql
   /* Form referenced as a sub-level of another form */
   SELECT FATFORM, SONFORM, POS FROM FORMLINKS
   WHERE FATFORM = <ID> OR SONFORM = <ID> FORMAT;

   /* Direct activations attached to forms (form-id == EXEC.TABLE on activation rows) */
   SELECT EXEC, ENAME, TITLE, TYPE FROM EXEC WHERE TABLE = <ID> FORMAT;

   /* Menus that surface this entity */
   SELECT MENU.EXEC, EXEC.ENAME FROM MENU, EXEC
   WHERE MENU.EXEC = <ID> AND MENU.EXEC = EXEC.EXEC FORMAT;

   /* Procedures whose steps reference the target (best-effort; CODEREF availability varies per tenant
      — probe first with `run_windbi_command priority.displayTableColumns CODEREF`; empty result = table
      absent in this tenant, skip this query) */
   SELECT EXEC, STEP FROM CODEREF WHERE TEXT LIKE '%<NAME>%' FORMAT;
   ```
   If anything comes back, decide: stop (the entity is in use), or include those references in the cascade.

3. Show the user a **row-count table** for every cascade table you intend to touch (per-kind queries below), then ask for approval. Only proceed after explicit "yes / approved / delete it".

---

## Kind-by-kind cascades

### Form (`TYPE='F'`)

```sql
/* Counts first */
SELECT COUNT(*) FROM FORMCLMNS      WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMCLMNSA     WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMCLMNSTEXT  WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMTRIG       WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMTRIGTEXT   WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMCLTRIG     WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMCLTRIGTEXT WHERE FORM = <FID> FORMAT;
SELECT COUNT(*) FROM FORMLINKS      WHERE FATFORM = <FID> OR SONFORM = <FID> FORMAT;
SELECT COUNT(*) FROM EXEC           WHERE TABLE = <FID> FORMAT;  /* direct activations */

/* Cascade — order matters: child rows before parents */
DELETE FROM FORMCLMNSTEXT  WHERE FORM = <FID>;
DELETE FROM FORMCLMNSA     WHERE FORM = <FID>;
DELETE FROM FORMCLTRIGTEXT WHERE FORM = <FID>;
DELETE FROM FORMCLTRIG     WHERE FORM = <FID>;
DELETE FROM FORMTRIGTEXT   WHERE FORM = <FID>;
DELETE FROM FORMTRIG       WHERE FORM = <FID>;
DELETE FROM FORMCLMNS      WHERE FORM = <FID>;
DELETE FROM FORMLINKS      WHERE FATFORM = <FID> OR SONFORM = <FID>;
DELETE FROM EXEC           WHERE TABLE = <FID>;   /* direct activations */
DELETE FROM EXEC           WHERE EXEC  = <FID>;   /* the form itself */
```

**Verified 2026-04-25** on `SOF_CUSTSIGN2` (EXEC=84185): zero-side-effect form (no triggers, no expressions, no links) collapses to two statements — `DELETE FROM FORMCLMNS WHERE FORM = <FID>; DELETE FROM EXEC WHERE EXEC = <FID>;`. Run all eleven anyway for symmetry; counts of zero make them no-ops.

### Report (`TYPE='R'`)

Report metadata tables key on `EXEC = <RID>` (not `FORM`):
```sql
SELECT COUNT(*) FROM REPCLMNS    WHERE EXEC = <RID> FORMAT;
SELECT COUNT(*) FROM REPCLMNSA   WHERE EXEC = <RID> FORMAT;
/* If your tenant has REPCLMNSTEXT / REPCLTRIG / REPCLTRIGTEXT — same shape as the form variants, key by EXEC */

DELETE FROM REPCLMNSA WHERE EXEC = <RID>;
DELETE FROM REPCLMNS  WHERE EXEC = <RID>;
/* Plus any text/trigger child tables present in the tenant */
DELETE FROM EXEC      WHERE EXEC = <RID>;
```

If `displayTableColumns` returns empty for `REPCLTRIG` / `REPCLMNSTEXT` / `REPTRIG`, those tables don't exist in the tenant (the bridge collapses zero-row schema reads to an OK envelope) — skip them. Don't invent a DELETE on a table that isn't there.

### Procedure (`TYPE='P'`)

```sql
SELECT COUNT(*) FROM PROGRAMS WHERE EXEC = <PID> FORMAT;
/* PARAMS / step-text / direct-activation entries — counts vary by build; query before deleting */

DELETE FROM PROGRAMS WHERE EXEC = <PID>;
DELETE FROM EXEC     WHERE EXEC = <PID>;
```

If the procedure was a copy made via `COPYPROG`, no extra wiring carried over — clean cascade. If the procedure is wired into a menu, run the **Menu** cascade for the corresponding `MENU.EXEC = <PID>` row first.

### Menu (`TYPE='M'`)

`MENU` rows attach individual entities to a menu. To remove ONE entity from a menu, delete only the matching MENU row(s); to delete the menu itself, also delete the EXEC row.
```sql
/* Remove an item from a menu */
SELECT MENU.EXEC, EXEC.ENAME, EXEC.TITLE, MENU.POS FROM MENU, EXEC
WHERE MENU.EXEC = <MENUID> AND MENU.EXEC = EXEC.EXEC ORDER BY MENU.POS FORMAT;

DELETE FROM MENU WHERE EXEC = <ITEMID> AND EXECRUN = <MENUID>;

/* Delete the whole menu */
SELECT COUNT(*) FROM MENU WHERE EXECRUN = <MENUID> FORMAT;
DELETE FROM MENU WHERE EXECRUN = <MENUID>;
DELETE FROM EXEC WHERE EXEC    = <MENUID>;
```

### Interface (`TYPE='I'`)

```sql
/* Tenant-dependent table names — query schema first */
SELECT COUNT(*) FROM INTERFORMS    WHERE EXEC = <IID> FORMAT;
SELECT COUNT(*) FROM INTERCLMNSFILE WHERE EXEC = <IID> FORMAT;

DELETE FROM INTERCLMNSFILE WHERE EXEC = <IID>;
DELETE FROM INTERFORMS     WHERE EXEC = <IID>;
DELETE FROM EXEC           WHERE EXEC = <IID>;
```

### Table (`TYPE='T'`)

**Do not cascade-delete tables this way — drop them via DBI:**
```
FOR TABLE <TNAME>
DELETE TABLE;
```
…and only after confirming there are no rows in the table, no forms over it, no triggers referencing it, and (if it's a system table) no chance the user actually meant "remove a column", which is `FOR TABLE <T> DELETE <COL>;`.

---

## Sub-element deletes (more common than full-entity deletes)

### One form trigger (form-level)

```sql
/* Identify */
SELECT TRIG, TDATE FROM FORMTRIG WHERE FORM = <FID> FORMAT;

/* Cascade — text rows first */
DELETE FROM FORMTRIGTEXT WHERE FORM = <FID> AND TRIG = <TID>;
DELETE FROM FORMTRIG     WHERE FORM = <FID> AND TRIG = <TID>;
```

WebSDK `EFORM → FTRIG → setActiveRow → deleteRow` will fail on a trigger that has text under it — see `common-mistakes.md` § "Using WebSDK `deleteRow` to remove a trigger with text under it".

### One column trigger

```sql
DELETE FROM FORMCLTRIGTEXT WHERE FORM = <FID> AND NAME = '<COL>';
DELETE FROM FORMCLTRIG     WHERE FORM = <FID> AND NAME = '<COL>';

/* Optional: clear the orphan flag on the FCLMN row */
UPDATE FORMCLMNS SET TRIGGERS = '' WHERE FORM = <FID> AND NAME = '<COL>';
```
Do NOT clear `FCLMN.TRIGGERS=''` as a "fix" for a compile error you don't understand — see `common-mistakes.md` § "Clearing `FCLMN.TRIGGERS='Y'` to fix a compile error".

### One field (form column)

```sql
/* Cascade child metadata first */
DELETE FROM FORMCLMNSTEXT  WHERE FORM = <FID> AND NAME = '<COL>';
DELETE FROM FORMCLMNSA     WHERE FORM = <FID> AND NAME = '<COL>';
DELETE FROM FORMCLTRIGTEXT WHERE FORM = <FID> AND NAME = '<COL>';
DELETE FROM FORMCLTRIG     WHERE FORM = <FID> AND NAME = '<COL>';
DELETE FROM FORMCLMNS      WHERE FORM = <FID> AND NAME = '<COL>';
```

WebSDK alternative for a clean column row (no triggers, no expression):
```json
{"form":"EFORM","operations":[
  {"op":"filter","field":"ENAME","value":"<FORM>"},
  {"op":"getRows","fromRow":1},
  {"op":"setActiveRow","row":1},
  {"op":"startSubForm","name":"FCLMN"},
  {"op":"filter","field":"NAME","value":"<COL>"},
  {"op":"getRows","fromRow":1},
  {"op":"setActiveRow","row":1},
  {"op":"deleteRow"}
]}
```
If `deleteRow` returns `ערך קיים במסך 'X'`, peel `X` (the named subform) first or fall back to the SQL cascade.

### One direct activation on a form

WebSDK path (preferred — exercises the FORMEXEC subform and avoids leaking EXEC rows):
```json
{"form":"EFORM","operations":[
  {"op":"filter","field":"ENAME","value":"<FORM>"},
  {"op":"getRows","fromRow":1},
  {"op":"setActiveRow","row":1},
  {"op":"startSubForm","name":"FORMEXEC"},
  {"op":"filter","field":"ENAME","value":"<ACTIVATION>"},
  {"op":"getRows","fromRow":1},
  {"op":"setActiveRow","row":1},
  {"op":"deleteRow"}
]}
```
Raw fallback:
```sql
DELETE FROM EXEC WHERE TABLE = <FID> AND ENAME = '<ACTIVATION>';
```

### One menu item

```sql
DELETE FROM MENU WHERE EXEC = <ITEMID> AND EXECRUN = <MENUID>;
```

---

## After (every kind)

1. Verify the parent row is gone:
   ```sql
   SELECT EXEC, ENAME FROM EXEC WHERE ENAME = '<NAME>' FORMAT;   -- expect 0 rows
   ```
2. Verify the most-populated child table is gone (e.g., for a form: `FORMCLMNS WHERE FORM = <FID>` → 0 rows).
3. Verify any related entity you intentionally kept (e.g., the SOURCE form when deleting a copy) is still intact:
   ```sql
   SELECT EXEC, ENAME FROM EXEC WHERE ENAME = '<KEPT>' FORMAT;   -- expect 1 row
   ```
4. If the deleted form / report / procedure was wired into menus, also verify the menu now skips it (re-run the menu inventory query).

---

## When to refuse

- The entity isn't in `MODULENAME = 'פיתוח פרטי'` ("Internal Development") and the user hasn't explicitly said "yes, delete the system one".
- The entity is referenced by another form/report/procedure that the user wants to keep — propose fixing the references first.
- The user asked to delete a **table** (`TYPE='T'`) that has data in it, or that backs an active form — ask before dropping.

---

## See also

- `references/compile-debugging.md` § "Cascade-deleting a form" (original cascade order)
- `references/common-mistakes.md`:
  - § "Using WebSDK `deleteRow` to remove a trigger with text under it"
  - § "Clearing `FCLMN.TRIGGERS='Y'` to fix a compile error"
- `recipes/copy-entity.md` (the inverse — duplicate before delete to keep an undo)
- `recipes/upgrade-form-changes.md` (deletes propagated to other servers need their own UPGCODE — usually `TAKESINGLEENT` for a removed entity, or `TAKEFORMCOL`/`TAKETRIG` for a removed sub-element)
