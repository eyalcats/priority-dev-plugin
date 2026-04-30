# Fix-loop discipline — shared rules for write-mode agents

Both `compile-doctor` and `optimizer-fix` apply a fix, recompile, then verify. They follow the same discipline. This file is the single source of truth.

## Hard rules

1. **Per-fix approval required.** Unless the input envelope explicitly carries `"apply": "auto"` (reserved for orchestrator/test-harness use), every fix must be presented to the user as a planned diff and applied only after explicit approval.
2. **Recompile after every fix.** Form: `compile` op via `websdk_form_action`. Procedure: `priority.prepareProc` via `run_windbi_command`. Mandatory — never skip.
3. **Stop when stalled.** If a fix has been applied and the verifying check (FORMPREPERRS for compile-doctor, the originating rule for optimizer-fix) still fires, return `status: stalled`. Never retry the same recipe with variations.
4. **Cite row counts before any DELETE.** Always run a `SELECT COUNT(*)` against every table the DELETE will touch; print the counts to the user before issuing the DELETE.
5. **Metadata-table DELETEs only.** Allowed targets: `FORMCLMNS`, `FORMCLMNSA`, `FORMCLMNSTEXT`, `FORMTRIG`, `FORMTRIGTEXT`, `FORMCLTRIG`, `FORMCLTRIGTEXT`, `FORMLINKS`, and `EXEC` rows for scratch entities. Never DELETE from business tables (`INVOICES`, `ORDERS`, `CUSTOMERS`, etc.).
6. **Form-metadata edits via WebSDK first.** Raw SQL on `FORMCLMNS`/`FORMCLMNSA`/etc. is allowed only when WebSDK hits `ערך קיים` or is incapable. Document the reason inline.
7. **Never fabricate a fix for an issue you can't reproduce.** If the verifying check produces a different signal than the input describes, surface the divergence honestly — do not guess.

## Peel-or-cascade decision

When `deleteRow` via WebSDK fails with `ערך קיים במסך 'X'`:

- **Peel** (preferred): navigate into the blocking subform (FORMEXEC → FLINK → FTRIG → FCLMN → EFORM), delete child rows, back out, retry parent delete.
- **Cascade** (when peel is slow or the subform is unreachable via WebSDK): use `run_inline_sqli mode=sqli` with `DELETE FROM <metadata table>` and the required `WHERE FORM = ...` clauses. Cite row counts first. Only on form-metadata tables; never on business tables.

## Verification step

The verifying check is agent-specific:

- `compile-doctor`: re-read `FORMPREPERRS` after recompile; the original error must be absent.
- `optimizer-fix`: re-run the **single rule** that produced the finding being fixed; the finding must no longer fire.

In both cases, one verification per fix. If the check still fires, return `status: stalled` and stop.
