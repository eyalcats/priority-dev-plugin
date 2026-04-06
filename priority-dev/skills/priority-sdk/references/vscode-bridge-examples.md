# VSCode Priority Bridge — Advanced Patterns

> **Note:** Basic tool descriptions and the development workflow are embedded in the MCP server (loaded automatically). This file covers advanced patterns, WebSDK operation details, and capture mechanics.

> **Setup:** If the bridge isn't installed yet, run `git clone https://github.com/eyalcats/priority-dev-plugin.git && claude plugin add ./priority-dev-plugin`. See `SKILL.md` > Installation for details.

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

Form columns, joins, and read-only imported columns can be created via OData POST:

```
POST https://$PRIORITY_SERVER/odata/Priority/tabula.ini/$PRIORITY_COMPANY/EFORM(ENAME='FORM_NAME',TYPE='F')/FCLMN_SUBFORM
Auth: Basic $PRIORITY_USER:$PRIORITY_PASS
Content-Type: application/json

# Base table column with join:
{"NAME":"COL","CNAME":"COL","TNAME":"BASE_TABLE","POS":70,"JTNAME":"JOIN_TABLE","JCNAME":"JOIN_COL","IDCOLUMNE":"0","IDJOINE":"0"}

# Imported read-only column:
{"NAME":"COL","CNAME":"COL","TNAME":"JOIN_TABLE","POS":80,"READONLY":"R","IDCOLUMNE":"0","IDJOINE":"0"}
```

After adding columns, compile the form (open a Priority file in VSCode, then run `prepareForm`).

### OData Discovery: $expand=* on Form Columns

To discover all sub-entities on a form column (expressions, column triggers, etc.), use `$expand=*`:

```
GET .../EFORM(ENAME='ORDERSTEXT',TYPE='F')/FCLMN_SUBFORM(NAME='ORD')?$expand=*
```

This reveals hidden sub-entities:
- **FCLMNA_SUBFORM** — Form Column Extension (expression/condition text, e.g., `{"EXPR":":$$.ORD"}`)
- **FORMCLTRIG_SUBFORM** — Column-level triggers (POST-FIELD, CHECK-FIELD, etc.)
- **FCLMNHELP_SUBFORM** — Help topic
- **FCLMNINTER_SUBFORM** — Column interfaces

**Setting a column expression** (critical for subform parent-child linking):
```
POST .../EFORM(ENAME='SUBFORM',TYPE='F')/FCLMN_SUBFORM(NAME='KLINE')/FCLMNA_SUBFORM
{"EXPR": ":$$.KLINE"}
```

**Creating a column-level trigger** (e.g., POST-FIELD on TEXT column):
```
POST .../EFORM(ENAME='FORM',TYPE='F')/FCLMN_SUBFORM(NAME='TEXT')/FORMCLTRIG_SUBFORM
{"TRIG": 11}

PATCH .../FCLMN_SUBFORM(NAME='TEXT')/FORMCLTRIG_SUBFORM(TRIG=11)/FORMCLTRIGTEXT_SUBFORM
{"TEXT": "SELECT :SCRLINE INTO :$.TEXTORD FROM DUMMY ;\n..."}
```

**Tip:** Always compare a working reference form using `$expand=*` before building a new form — differences are often in sub-entities you didn't know existed.

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
| Execute | runSqliFile, executeDbi, createSqliFile, executeSqliInAllCompanies | Yes (most) | Yes (some) | 40-80% |
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

**Use WebSDK (`websdk_form_action`) for all form operations.** It supports filter, subform navigation, direct activations, and all CRUD. Use `write_to_editor` for code. Use `run_windbi_command` for DBI and table inspection only.

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
- `getRows(fromRow)` — parameter is starting row position (1-based), NOT a count
- `filter` uses `setSearchFilter` — works on most forms including EFORM and UPGRADES
- `clearFilter` clears the active filter
- FORMEXEC: set `ETYPE` first ("P"/"F"/"R"), then `RUN` (entity name)
- FTRIG: field name is `TRIGNAME` (not `NAME`)
- Trigger code in FTRIGTEXT is stored one line per row (68-char RCHAR limit). For writing, use `write_to_editor` instead

#### Code Writing — Use write_to_editor

Always use `write_to_editor` for trigger and procedure code. It writes full multiline content in one call:
```
write_to_editor(entityType="FORM", entityName="MYFORM", stepName="PRE-INSERT", content="full SQLI code")
```

#### Compilation — Use WebSDK compile compound

```json
{"operations": [{"op": "compile", "entity": "MYFORM"}]}
```
Returns `status: 'ok'` on success. Check WINDBI panel if you need to see the compile report.

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

#### Table Structure — DBI via run_windbi_command

| Operation | DBI Syntax |
|-----------|-----------|
| Create table | `CREATE TABLE name col1 (TYPE, WIDTH, 'Title') ... AUTOUNIQUE(col) UNIQUE(col);` |
| Add column | `FOR TABLE X INSERT col (type, width, 'title');` |

Execution: write `.pq` file → open in VSCode → `run_windbi_command("priority.executeDbi")`

#### Procedure Creation — DBI INSERT into EXEC

No WebSDK form exists for creating procedures. Use DBI:
```sql
INSERT INTO EXEC (ENAME, TITLE, TYPE, EDES) VALUES ('CON_MYPROC', 'My Procedure', 'P', 'CON');
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

| Operation | Engine | VSCode Command | MCP Command |
|-----------|--------|---------------|-------------|
| Data queries (SELECT, INSERT, UPDATE, DELETE) | SQLI | Execute > Run SQLI | `priority.runSqliFile` |
| Schema changes (CREATE TABLE, column/key modifications) | DBI | Execute > Execute DBI | `priority.executeDbi` |

Both require the code to be in a `.pq` file open in VSCode. Running DBI as SQLI (or vice versa) will produce parse errors.

### DBI Execution

To execute DBI statements via `priority.executeDbi`:

1. The active editor must contain a `.pq` file with DBI content
2. The command shows an input dialog (auto-filled via clipboard mechanism)
3. Output goes to the WINDBI webview panel (not capturable)

**Recommended workflow:**
1. Create a temp SQLI file: `run_windbi_command("priority.createSqliFile")`
2. Write DBI content to the editor with `write_to_editor`
3. Run: `run_windbi_command("priority.executeDbi")`
4. Ask the user to check the WINDBI panel for results

### Shell Generation Notes

**TAKEDIRECTACT entries** require a companion TAKESINGLEENT for the `sonEntity` so the activated procedure exists on the target system. Always include both.

**TRANSLATED field** must be set to "N" on the UPGRADES revision for TAKEUPGRADE to run.

**UPGNUM** is not autounique — must be set manually to MAX(UPGNUM)+1 when creating a revision.

**Download files** come as UTF-16LE from Priority. The `downloadFile` operation handles conversion and saves as `.sh`.
