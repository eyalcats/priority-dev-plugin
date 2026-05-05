# VSCode Priority Bridge — Advanced Patterns

> **Note:** Basic tool descriptions and the development workflow are embedded in the MCP server (loaded automatically). This file covers advanced patterns, WebSDK operation details, and capture mechanics.

> **Setup:** If the bridge isn't installed yet, run `claude plugin marketplace add eyalcats/priority-dev-plugin && claude plugin install priority-dev`. See `SKILL.md` > Installation for details.

## Intent → tool

Reverse index from "I need to do X" to the bridge tool that does it. If the action you need is in the left column, the right column shows the tool — and the manual-delegation phrase you must NOT emit. The standing rule (`SKILL.md` § "Standing rules: Tool autonomy") forbids manual delegation when one of these tools applies.

| If you want to… | Use this — NOT this |
|---|---|
| Read the active editor buffer | `get_current_file` — not "please paste the code" |
| Open a Priority file in the editor | `open_priority_file` — not "please open ENTITY in VSCode" |
| Write SQLI to a step | `write_to_editor` — not "please paste this into VSCode" |
| Reload from server | `refresh_editor` — not "please refresh manually" |
| Run an ad-hoc SQLI query | `run_inline_sqli` (mode=`sqli`) — not "please run this in WINDBI" |
| Run a DBI block | `run_inline_sqli` (mode=`dbi`) — not "save to a `.pq` and run `priority.executeDbi`" |
| Compile a form | `websdk_form_action` compound `compile` op — not "please run prepareForm in WINDBI" |
| Compile a procedure | `run_windbi_command priority.prepareProc` — not "please compile manually" |
| Read compile errors | `run_inline_sqli` against `PREPERRMSGS` (authoritative; see `compile-debugging.md`) — not "please check the WINDBI panel" |
| Read form / column / trigger metadata | `websdk_form_action` on EFORM (subforms FCLMN / FTRIG / FLINK), or SQLI against `FORMCLMNS` / `FORMTRIG` / `FORMCLTRIGTEXT` — not "please show me the definition" |
| Inspect table structure | `run_inline_sqli` on `COLUMNS WHERE TNAME='X' FORMAT;` — not "please tell me the columns" (avoid `priority.displayTableColumns` — see `common-mistakes.md` § Debugging) |
| Search code across forms | `run_inline_sqli` on `CODEREF` / `FORMTRIGTEXT` / `FORMCLTRIGTEXT` — not "please grep for me" |
| Find a form's internal ID | `run_inline_sqli` on `EXEC` — not "please look it up" |
| Generate an upgrade shell | `generate_shell` MCP tool — not "please build the .sh by hand" |
| Update a form row (data) | `websdk_form_action` `fieldUpdate` / `saveRow` — not "please update it in the UI" |
| Run a procedure / interface | `websdk_form_action` `procStart` (or `EXECUTE INTERFACE` via `run_inline_sqli`) — not "please run it from the menu" |

The carved-out exceptions where manual delegation IS correct (VSIX install, browser-only auth, null `get_current_file`, explicit user request) are listed in `SKILL.md` § "Standing rules: Tool autonomy".

## Architecture

```
Claude Code (terminal)          VSCode (Priority extension)
     |                                |
     | MCP tools via HTTP             | priorityfs:// virtual files
     v                                v
priority-claude-bridge          Priority Dev Tools Extension
(MCP on configured port)        (PrioritySoftware.priority-vscode)
     |                                |
     +---------- VSCode APIs ---------+
                    |
            Priority Server
            (OData / SQLI)
```

The bridge runs inside the VSCode extension host as an HTTP server. It uses:
- **WebSDK** (`websdk_form_action`) for ALL form operations — CRUD, metadata, triggers, shell generation
- **Direct WCF calls** for query/inspect commands (displayTableColumns, runSqliFile, executeDbi)
- `vscode.workspace.applyEdit()` for writing code (`write_to_editor`)
- OData is NOT needed — WebSDK handles everything including filter, subform navigation, and direct activations

### Direct WCF Output Capture

Commands like `displayTableColumns`, `selectAllRowsFromTable`, and `runSqliFile` now return results directly via WCF instead of rendering in the WINDBI webview panel. The bridge translates param-based commands into SQL queries and runs them via `CmdSqli`.

### WebSDK Form Operations (websdk_form_action)

Form columns, joins, and read-only imported columns are managed via WebSDK on EFORM:

```
# Add a base table column with join:
filter EFORM(ENAME, "FORM_NAME") → getRows → setActiveRow(1)
  → startSubForm(FCLMN) → newRow
  → fieldUpdate(NAME, "COL") → fieldUpdate(CNAME, "COL")
  → fieldUpdate(TNAME, "BASE_TABLE") → fieldUpdate(POS, "70")
  → fieldUpdate(JTNAME, "JOIN_TABLE") → fieldUpdate(JCNAME, "JOIN_COL")
  → saveRow

# Add an imported read-only column:
  → newRow → fieldUpdate(NAME, "COL") → fieldUpdate(CNAME, "COL")
  → fieldUpdate(TNAME, "JOIN_TABLE") → fieldUpdate(POS, "80")
  → fieldUpdate(READONLY, "R") → saveRow
```

After adding columns, compile the form via WebSDK compound `compile` operation.

### WebSDK Discovery: Subform Navigation on Form Columns

To discover sub-entities on a form column (expressions, column triggers, etc.), navigate subforms via WebSDK:

```
filter EFORM(ENAME, "FORMNAME") → getRows → setActiveRow(1)
  → startSubForm(FCLMN) → filter(NAME, "COL") → getRows → setActiveRow(1)
  → startSubForm(FCLMNA) → getRows    # expression/condition
  → endSubForm
  → startSubForm(FORMCLTRIG) → getRows  # column-level triggers
```

Sub-entities accessible via subform navigation:
- **FCLMNA** — Form Column Extension (expression/condition text)
- **FORMCLTRIG** — Column-level triggers (POST-FIELD, CHECK-FIELD, etc.)
- **FCLMNHELP** — Help topic
- **FCLMNINTER** — Column interfaces

**Setting a column expression** (critical for subform parent-child linking):
```
filter EFORM(ENAME, "SUBFORM") → getRows → setActiveRow(1)
  → startSubForm(FCLMN) → filter(NAME, "KLINE") → getRows → setActiveRow(1)
  → startSubForm(FCLMNA) → newRow → fieldUpdate(EXPR, ":$$.KLINE") → saveRow
```

**Writing multi-line expressions** (EXPR is max 56 chars; continuation goes in FCLMNTEXT):
```
# After navigating to FCLMNA and setting EXPR:
  → startSubForm(FCLMNTEXT) → newRow → fieldUpdate(TEXT, "continuation line") → saveRow
```

**Creating a column-level trigger** (e.g., POST-FIELD on TEXT column):
```
filter EFORM(ENAME, "FORM") → getRows → setActiveRow(1)
  → startSubForm(FCLMN) → filter(NAME, "TEXT") → getRows → setActiveRow(1)
  → startSubForm(FORMCLTRIG) → newRow → fieldUpdate(TRIG, "11") → saveRow
```
For trigger code, use `write_to_editor` instead of navigating FORMCLTRIGTEXT — it handles full multiline content.

**Tip:** Always compare a working reference form's subforms before building a new form — differences are often in sub-entities you didn't know existed.

---

## Command Behavior Reference

| Category | Commands | Active Editor | Input Dialog | Output Capture Rate |
|----------|----------|:------------:|:------------:|:-------------------:|
| Dump | dumpForm, dumpProcedure, dumpReport, dumpLoad, dumpTable, dumpFormCursor | Yes | Yes (entity name) | 30-50% (webview) |
| Search | findStringInAllForms, findStringInSingleForm | No / Yes | Yes (search string) | 80-90% |
| Display | displayTableColumns, displayTableColumnsWithPrecision, displayFormColumns, displayTableKeys | Yes | Yes (entity name) | 80-90% |
| Query | selectAllRowsFromTable | Yes | Yes (table name) | 70-80% |
| Explain | explainSqliCode, explainSqliCodeWithExec | Yes | No | 90%+ (return value) |
| Optimize | optimizeSql, optimizeForm, optimizeReport | Yes | Yes (some) | 60-70% |
| **Compile** | **compile_form** (preferred) | No | No | **95%+ (WCF CmdSqliOpt)** |
| Compile (fallback) | prepareForm, prepareProc | Yes | No | 10-20% (errors not captured) |
| **Execute (preferred)** | **`run_inline_sqli` mode="sqli"/"dbi"** | No | No | **95%+ (direct WCF)** |
| Execute (legacy) | runSqliFile, executeDbi, createSqliFile, executeSqliInAllCompanies | Yes (most) | Yes (some) | 40-80% |
| Scaffold | createFormTrigger, deleteFormTrigger, createFormColumnTrigger, deleteFormColumnTrigger, createProcedureStep, deleteProcedureStep | Yes | Yes (trigger/step) | 40-50% |
| Utility | searchInExplorer, refreshExplorer, showLogs, showFileLogs | No | Yes (some) | N/A |

### Input Dialog Handling

The bridge auto-fills input dialogs using a clipboard-paste mechanism:
1. Copies the `entityName` parameter to the system clipboard
2. Waits 600ms for the dialog to appear
3. Pastes via Ctrl+V and presses Enter

This runs in parallel with the command execution. The mechanism is timing-dependent — if the dialog appears slower than 600ms (due to system load), the paste may miss the dialog. If the dialog is not answered within 20 seconds, the bridge closes the quick-open palette and returns a `COMMAND_TIMEOUT` error.

Always provide the `entityName` parameter for commands that show input dialogs to give the auto-fill mechanism the best chance of succeeding.

### Output Capture Mechanism

The bridge uses a 4-tier fallback strategy to capture command output:

1. **Command return value** — fastest and most reliable; used by `explainSqliCode` and compile commands
2. **Output document event listener** — listens for 8 seconds for new documents matching `windbi` or `priority` in the URI
3. **Final poll** — after a 1-second delay, checks all open output documents
4. **Log signal extraction** — pattern-matches the extension log for error, success, or compile keywords

The capture rate varies by command category (see table above). Dump commands have the lowest capture rate because their output renders in a webview panel.

### Known Limitations

- **Webview output not capturable**: The WINDBI results panel is a VSCode webview (HTML), not an output channel. Its content cannot be read programmatically by the bridge. The user must check the panel visually.
- **Input dialog timing**: The 600ms clipboard-paste delay is a best-effort heuristic. Under heavy system load or slow environments, dialogs may not be filled correctly.
- **Command timeout (20s)**: Commands that show an unanswered input dialog will timeout after 20 seconds. The bridge closes any open quick-pick and returns `COMMAND_TIMEOUT`.
- **Output capture timeout (8s)**: The document event listener gives up after 8 seconds. Commands that take longer to produce output may report no output even on success.

### Tool Selection Guide

**Use WebSDK (`websdk_form_action`) for all form operations.** It supports filter, subform navigation, direct activations, and all CRUD. Use `write_to_editor` for code. Use `run_inline_sqli` for DBI, SQLI, and table/form/proc inspection via SQLI on system tables (FORMCLMNS, CODEREF, COLUMNS, EXEC, etc.) — zero logged failures over a week of real usage. Reserve `run_windbi_command` for genuinely UI-bound operations: `prepareForm`/`prepareProc` as a compile fallback with explicit `entityName`, and report compile (no WebSDK equivalent). See `common-mistakes.md` § "Reaching for `run_windbi_command` dump/search commands for inspection" for the full anti-pattern breakdown.

#### Form Metadata — Use WebSDK on EFORM

All form metadata operations work via WebSDK with `filter` + subform navigation:

| Operation | WebSDK Approach |
|-----------|----------------|
| Create form | `newRow → fieldUpdate(ENAME, TITLE, TNAME, EDES) → saveRow` on EFORM |
| Add column | `filter EFORM → startSubForm(FCLMN) → newRow → fieldUpdate(NAME) → saveRow` |
| Set column expression | `FCLMN → setActiveRow → startSubForm(FCLMNA) → newRow → fieldUpdate(EXPR) → saveRow` |
| Add subform link | `filter EFORM → startSubForm(FLINK) → newRow → fieldUpdate(ENAME) → saveRow` |
| Create trigger | `filter EFORM → startSubForm(FTRIG) → newRow → fieldUpdate(TRIGNAME) → saveRow` |
| Read trigger code | `FTRIG → setActiveRow → startSubForm(FTRIGTEXT) → getRows(1)` |
| Add direct activation | `filter EFORM → startSubForm(FORMEXEC) → newRow → fieldUpdate(ETYPE, RUN) → saveRow` |
| Write trigger code | Use `write_to_editor(entityType="FORM", entityName, stepName, content)` |

**Important WebSDK notes:**
- `getRows(fromRow)` — parameter is starting row position (1-based), NOT a count.
- For `filter` internals and the compound-tool ordering requirement, see `websdk-cookbook.md` § "Known bridge behaviors".
- `clearFilter` clears the active filter.
- FORMEXEC: set `ETYPE` first ("P"/"F"/"R"), then `RUN` (entity name).
- FTRIG: field name is `TRIGNAME` (not `NAME`).
- Form-level trigger text (FTRIGTEXT) — use `write_to_editor`.
- **Column-level trigger code** — `write_to_editor` returns `TRIGGER_NOT_FOUND`; WebSDK `newRow` on `FORMCLTRIGTEXT` silently appends. Use the DBI `DELETE + INSERT` recipe in `forms.md` § "Column trigger code — use DBI, not WebSDK `newRow`".

#### TRIG value mapping (FORMCLTRIG / FORMCLTRIGTEXT)

Reference for raw SQL against the column-trigger tables:

| TRIG | Trigger type |
|------|--------------|
| -1 | CHOOSE-FIELD |
| -2 | SEARCH-DES-FIELD |
| -3 | SEARCH-NAME-FIELD |
| -5 | SEARCH-ALL-FIELD |
| 10 | CHECK-FIELD |
| 11 | POST-FIELD |
| 12 | (tooltip / help text) |

`FORMCLTRIGTEXT.NAME` is the **column name** (e.g., `FTIP_FCOUNTRY`), not the trigger name. Primary key is `(FORM, NAME, TRIG, TEXTLINE)`.

#### Code Writing — Use write_to_editor

Always use `write_to_editor` for trigger and procedure code. It writes full multiline content in one call:
```
write_to_editor(entityType="FORM", entityName="MYFORM", stepName="PRE-INSERT", content="full SQLI code")
```

**Procedure steps without VSCode open (OData fallback):**
`write_to_editor` falls back to the Priority OData API when no matching
`priorityfs://` file is open in VSCode. For PROC entities, `stepName` must
be `<PROGRAMS.POS>_SQLI` where POS is the value in the `PROGRAMS.POS`
column (5, 10, 15, 20, … — these are Priority-assigned positions, NOT
sequential 1, 2, 3):

```js
write_to_editor({
  entityType: "PROC",
  entityName: "TGML_INITSERIES",
  stepName: "10_SQLI",     // POS=10 in PROGRAMS table, not "step 10"
  content: "/* full SQLI code here */"
})
```

To find a step's POS value:
```sql
SELECT ENAME, POS FROM PROGRAMS
WHERE EXEC = (SELECT EXEC FROM EXEC WHERE ENAME = 'TGML_INITSERIES' AND TYPE = 'P')
FORMAT;
```

Verified 2026-05-02: wrote TGML_INITSERIES step at POS=10 via OData while the
VSCode Environments Explorer showed the procedure as missing (stale cache). The
write and subsequent compile both succeeded.

*(seen in: session-2026-05-02-tgml-phase1)*

#### Compilation — Use WebSDK compile compound

```json
{"operations": [{"op": "compile", "entity": "MYFORM"}]}
```
Returns `status: 'ok'` on success. Check WINDBI panel if you need to see the compile report.

**One entity per compile call — second entity is silently skipped:**
The `compile` op processes only the first entity in the `operations` array.
If you include two `{"op": "compile", "entity": "X"}` ops in a single
`websdk_form_action` call, only the first entity is compiled; the second is
silently skipped with no error or warning.

To compile multiple entities, issue separate calls:
```json
{"operations": [{"op": "compile", "entity": "FORM_A"}]}
{"operations": [{"op": "compile", "entity": "FORM_B"}]}
```

This affects post-DBI batch compilation (e.g., after `CHANGE TITLE TO` or
`CHANGE WIDTH TO` — see `references/tables-and-dbi.md` §DBI Syntax Reference
for the recompile requirement). Issue one compile call per dependent form.

*(seen in: session-2026-05-02-tgml-phase1)*

#### Shell Generation — Use WebSDK primitives on UPGRADES

Full autonomous workflow (no compound needed):

1. **Get max UPGNUM** and create revision:
```json
{"form": "UPGRADES", "operations": [
  {"op": "newRow"},
  {"op": "fieldUpdate", "field": "UPGNUM", "value": "MAX+1"},
  {"op": "fieldUpdate", "field": "REM", "value": "description"},
  {"op": "fieldUpdate", "field": "TYPE", "value": "O"},
  {"op": "fieldUpdate", "field": "USERLOGIN3", "value": "username"},
  {"op": "fieldUpdate", "field": "DOCUMENTED", "value": "N"},
  {"op": "fieldUpdate", "field": "TRANSLATED", "value": "N"},
  {"op": "saveRow"}
]}
```

2. **Add entries** via UPGNOTES subform:
```json
{"form": "UPGRADES", "operations": [
  {"op": "filter", "field": "UPGNUM", "value": "11148"},
  {"op": "setActiveRow", "row": 1},
  {"op": "startSubForm", "name": "UPGNOTES"},
  {"op": "newRow"},
  {"op": "fieldUpdate", "field": "UPGCODE", "value": "TAKESINGLEENT"},
  {"op": "fieldUpdate", "field": "ENAME", "value": "MYFORM"},
  {"op": "fieldUpdate", "field": "TYPE", "value": "F"},
  {"op": "saveRow"},
  {"op": "endSubForm"}
]}
```

UPGNOTES field names: `UPGCODE`, `ENAME`, `TYPE` (F/P/R/M — NOT "T" for tables), `TRIGNAME` (for TAKETRIG), `SONENAME`/`SONTYPE` (for TAKEFORMLINK, TAKEDIRECTACT). DBI entries leave TYPE empty.

3. **Run TAKEUPGRADE** via activateStart:
```json
{"form": "UPGRADES", "operations": [
  {"op": "filter", "field": "UPGNUM", "value": "11148"},
  {"op": "setActiveRow", "row": 1},
  {"op": "activateStart", "name": "TAKEUPGRADE", "type": "P"}
]}
```
Returns `downloadUrl` in the result data.

4. **Download shell** as .sh file:
```json
{"operations": [{"op": "downloadFile", "url": "https://server/netfiles/file.txt", "filename": "my_upgrade.sh"}]}
```
Downloads, converts UTF-16 to UTF-8, forces `.sh` extension, saves to temp directory.

5. **Edit existing UPGNOTESTEXT lines in place (e.g., fix DBI text or Hebrew titles):**
UPGNOTES rows contain text sub-lines in the UPGNOTESTEXT subform (TEXT column,
CHAR 68). To edit line-by-line without SQLI (required when text contains Hebrew
or multi-line content that `run_inline_sqli` SQLI UPDATE cannot handle):

```json
{"form": "UPGRADES", "operations": [
  {"op": "filter",        "field": "UPGNUM", "value": "20162202"},
  {"op": "getRows"},
  {"op": "setActiveRow",  "row": 1},
  {"op": "startSubForm",  "name": "UPGNOTES"},
  {"op": "setActiveRow",  "row": 1},
  {"op": "startSubForm",  "name": "UPGNOTESTEXT"},
  {"op": "setActiveRow",  "row": 2},
  {"op": "fieldUpdate",   "field": "TEXT",
                          "value": "FOR TABLE TGML_PATHCFG CHANGE TITLE TO 'נתיב CSV';"},
  {"op": "saveRow"}
]}
```

Key notes:
- `setActiveRow(N)` on UPGNOTES: N = row index (position in the list), NOT the ORD value. Filter on ORD is unreliable; navigate by row position.
- `setActiveRow(N)` on UPGNOTESTEXT: N = TEXTLINE value (1-based).
- Hebrew and other non-ASCII content: use JSON `\uXXXX` Unicode escapes in the `value` string — they round-trip cleanly through the WebSDK fieldUpdate path.
- Max 68 chars per UPGNOTESTEXT.TEXT line (CHAR 68).
- This is the only reliable path for Hebrew DBI titles: `UPDATE … SET TEXT = 'Hebrew'` via `run_inline_sqli` fails with "parse error at or near symbol" — see `references/common-mistakes.md` §Hebrew literals in SQLI.

*(seen in: session-2026-05-02-tgml-phase1 — UPGNOTES Hebrew DBI title fix)*

#### Table Structure — DBI via run_windbi_command

| Operation | DBI Syntax |
|-----------|-----------|
| Create table | `CREATE TABLE name col1 (TYPE, WIDTH, 'Title') ... AUTOUNIQUE(col) UNIQUE(col);` |
| Add column | `FOR TABLE X INSERT col (type, width, 'title');` |

Execution (preferred): `run_inline_sqli({ sql: "<DBI code>", mode: "dbi" })` — no .pq file, no editor, direct WCF call. Returns output immediately.

Legacy path: write `.pq` file → open in VSCode → `run_windbi_command("priority.executeDbi")`.

#### Procedure Creation — DBI INSERT into EXEC

No WebSDK form exists for creating procedures. Use DBI via `run_inline_sqli`:
```js
run_inline_sqli({
  sql: "INSERT INTO EXEC (ENAME, TITLE, TYPE, EDES) VALUES ('CON_MYPROC', 'My Procedure', 'P', 'CON');",
  mode: "dbi"
})
```
Then add steps via `run_windbi_command("priority.createProcedureStep")` with the procedure file open in VSCode.

#### What to Avoid

| Avoid | Use Instead | Why |
|-------|-------------|-----|
| OData for form CRUD | WebSDK `websdk_form_action` | WebSDK supports filter, warnings, activations |
| OData for UPGRADES | WebSDK with filter | OData can't use MAX, LIKE, or run TAKEUPGRADE |
| `dumpForm` via WINDBI | WebSDK getRows on EFORM subforms | Webview output not capturable |
| Writing trigger code via FTRIGTEXT | `write_to_editor` | Handles full multiline content |
| `getRows(count)` with large count | `getRows(fromRow: 1)` | Parameter is fromRow not count |

### DBI vs SQLI: When to Use Which

| Operation | Engine | `run_inline_sqli` mode | Legacy MCP Command |
|-----------|--------|----------------------|--------------------|
| Data queries (SELECT, INSERT, UPDATE, DELETE) | SQLI | `mode: "sqli"` (default) | `priority.runSqliFile` |
| Schema changes (CREATE TABLE, column/key modifications) | DBI | `mode: "dbi"` | `priority.executeDbi` |

Running DBI as SQLI (or vice versa) produces parse errors — always pick the right engine. `run_inline_sqli` uses direct WCF and returns output immediately with no active editor required.

### DBI Execution

**Preferred:** `run_inline_sqli({ sql: "<dbi code>", mode: "dbi" })` — direct WCF `CmdDbi`, returns output.

**Legacy (only needed for interactive debugging or createSqliFile flows):**

1. The active editor must contain a `.pq` file with DBI content
2. Run `run_windbi_command("priority.executeDbi")` — shows an input dialog auto-filled via clipboard
3. Output renders in the WINDBI webview panel (not capturable)

> For the active-editor quirk that affects `runSqliFile` / `executeDbi`, see `websdk-cookbook.md` § "Known bridge behaviors" → "`runSqliFile` / `executeDbi` run the active editor tab". Short version: prefer `run_inline_sqli`.

### Shell Generation Notes

See `deployment.md` for the full upgrade-shell workflow (UPGCODE choice, UPGNOTES rules, DOWNLOADUPG vs TAKEUPGRADE). The few bridge-specific notes:

- **Download files** come as UTF-16LE from Priority. The `downloadFile` operation handles conversion and saves as `.sh`.
- **`generate_shell` MCP tool** auto-adds the `TAKEDIRECTACT` → `TAKESINGLEENT` companion pair, handles `TRANSLATED='N'`, and computes `UPGNUM = MAX+1`. Prefer it over manual UPGNOTES construction.

### write_to_editor caveats

#### Backslash double-escaping on round-trip

Each round-trip through `write_to_editor` adds a layer of backslash escaping to the content stored in `PROGRAMSTEXT`. A SQLI body containing `'\'` (a single backslash) is stored as `'\\'` after one write, `'\\\\'` after two writes, etc.

This silently breaks any clause that relies on a literal backslash — most commonly `LIKE` patterns with an `ESCAPE` clause:

```sql
/* BREAKS after one write_to_editor round-trip: */
WHERE NAME LIKE 'TGML\_%' ESCAPE '\';
/* stored as: WHERE NAME LIKE 'TGML\\_%' ESCAPE '\\'; */
/* then:      WHERE NAME LIKE 'TGML\\\\_%' ESCAPE '\\\\'; */
```

The failure mode is invisible: `write_to_editor` reports success, VSCode renders the escape-decoded form (appears correct), but the actual `PROGRAMSTEXT.TEXT` bytes are wrong. Compile then fails with "Unclosed string" on the affected line.

Workarounds (in preference order):

```sql
/* (1) Drop ESCAPE if the data permits — most common solution */
WHERE NAME LIKE 'TGML_%';

/* (2) Use a non-backslash escape character */
WHERE NAME LIKE 'TGML#_%' ESCAPE '#';

/* (3) Use direct SQL UPDATE on PROGRAMSTEXT — only when the editor
       file is NOT open in VSCode anywhere */
UPDATE PROGRAMSTEXT SET TEXT = 'WHERE NAME LIKE ''TGML\_%'' ESCAPE ''\'''
  WHERE PROG = <step_prog> AND TEXTLINE = <line>;
```

Option 3 is a last resort — direct SQL is overridden by the editor buffer push on the next VSCode compile (see § "Direct SQL on PROGRAMSTEXT is overridden by the editor buffer" below, or `websdk-cookbook.md` § "Use `write_to_editor` (OData) for body text").

*(seen in: TGML-UPGNUM2-debug-session-2026-05-04 — TGML_INITSEED LIKE/ESCAPE clause)*

---

### Direct SQL on PROGRAMSTEXT is overridden by the editor buffer

**When a procedure step `.pq` file is open in VSCode**, the bridge pushes the editor buffer to `PROGRAMSTEXT` before every compile. This means:

- Direct SQL `UPDATE`/`INSERT`/`DELETE` on `PROGRAMSTEXT.TEXT` succeeds server-side (returns "Execution ok"), but the **next compile from VSCode reverts every change** back to the local buffer state.
- WebSDK PROGTEXT subform writes (`startSubForm('PROGTEXT')` → `newRow` → `fieldUpdate('TEXT', ...)` → `saveRow`) have the same flaw — the editor buffer is the source of truth when its session is active.
- The failure is invisible: agents report "fix applied + clean compile via WebSDK"; the user compiles from VSCode and sees the original error reappear. The loop repeats until `write_to_editor` is used.

**Canonical fix:** Use `write_to_editor` for any procedure step body change. It updates the editor buffer AND `PROGRAMSTEXT` atomically:

```js
write_to_editor({
  entityType: "PROC",
  entityName: "<PROCNAME>",
  stepName: "<POS>_SQLI",   /* e.g. "5_SQLI", "10_SQLI" */
  content: "<full body, all lines, newline-separated>"
})
```

`content` must be the **complete** step body — partial-line updates are not supported. Read the current body first via `get_current_file` or by querying `PROGRAMSTEXT WHERE PROG=<step_id>`, then send the full modified version.

**When direct SQL on PROGRAMSTEXT is acceptable:**
- The procedure file is NOT open in VSCode anywhere.
- You verify by querying `PROGRAMSTEXT` immediately after and confirming the change persists across a recompile.

**Note:** `websdk-cookbook.md` § "Use `write_to_editor` (OData) for body text" covers the related parser-cache staleness issue (direct SQL succeeds but WebSDK compile returns stale errors). That is a separate failure mode from this one — buffer-push override occurs specifically when the file IS open in VSCode, whereas cache staleness can occur even when the file is not open.

*(seen in: TGML-UPGNUM2-debug-session-2026-05-04 — TGML_INITSEED multiple direct-SQL fixes silently reverted by editor session)*
