---
name: Priority SDK
description: >-
  This skill should be used when the user asks to "write Priority code",
  "create a form trigger", "write a procedure", "create an interface",
  "debug Priority code", "write a step query", "create a report",
  "use WSCLIENT", "parse XML in Priority", "use SFTP in Priority",
  "generate a document", "use WINHTML", "write DBI syntax",
  "create a table in Priority", "load data with INTERFACE",
  "use DBLOAD", "write Priority SQL", "create a BPM",
  "write a dashboard procedure", "use WebSDK", "manage form columns",
  "add form column via WebSDK", "write column trigger code",
  "create a subform", "write an expression column",
  "set up a foreign-key picker", "websdk_form_action",
  or mentions Priority ERP development, form triggers, SQLI,
  Priority procedures, or Priority SDK.
  Provides comprehensive reference for the Priority ERP SDK including
  SQL dialect, forms, triggers, reports, procedures, interfaces,
  documents, web services, WebSDK operations, and debugging tools.
---

# Priority SDK Development Guide

Reference skill for writing, debugging, and maintaining code in the Priority ERP system. Covers the full SDK: SQL dialect, forms, triggers, reports, procedures, interfaces, documents, integrations, and debugging.

For installation instructions, see `references/installation.md`.

## Standing rules

### Tool autonomy: never delegate work the bridge can do

If a Priority operation can be performed via `websdk_form_action`, `run_inline_sqli`, `run_windbi_command`, `open_priority_file`, `write_to_editor`, or `refresh_editor` — perform it. Do **not** ask the user to "open a file in VSCode", "run a command in WINDBI", "execute this DBI", "compile this form", "save the file", "check the WINDBI panel", or "paste the code back to me". The bridge exists so you can do these autonomously.

If a tool fails: diagnose the bridge or pick an alternative tool. Do not fall back to manual delegation. See `references/vscode-bridge-examples.md` § "Intent → tool" for the reverse index.

**Allowed exceptions** — manual delegation IS correct here:

- VSIX install / VSCode reload — admin actions outside the bridge's scope. On Windows, do **not** invoke the `code` CLI from shell (it spawns a new VSCode instance and disrupts the running bridge). Ask the user to install via VSCode's command palette.
- Browser-only auth flows (e.g., FileSmile download on cloud Priority servers).
- `get_current_file` returns `null` — ask the user to open the target file before any work proceeds.
- The user has explicitly asked to do the step themselves.

## Core Concepts

Priority uses a proprietary SQL dialect (SQLI) that extends standard SQL with custom functions, variables, flow control, and execution commands. All development happens through generators accessible via `System Management > Generators`.

### Entity Types

| Entity | Generator Path | Purpose |
|--------|---------------|---------|
| Tables | `System Management > Generators > Tables` | Database schema |
| Forms | `System Management > Generators > Forms` | Data entry and display |
| Reports | `System Management > Generators > Reports` | Data display and export |
| Procedures | `System Management > Generators > Procedures` | Business logic and automation |
| Interfaces | `System Management > Database Interface > Form Load (EDI)` | Data import/export |

### Naming Convention

All custom entities must start with a **four-letter prefix** (e.g., `ACME_ORDERS`). This applies to tables, forms, columns, triggers, variables, procedures, reports, and interfaces. Maximum 20 characters, alphanumeric and underscore only, must begin with a letter.

### Critical Rules

- **Verify entity names before designing or coding.** When the user mentions a form/table, resolve the name via `websdk_form_action` on EFORM (`filter ENAME`) or `displayTableColumns`. Form name ≠ table name (e.g., `ACCOUNTS_PAYABLE` form → `ACCOUNTS` table). If a name does not resolve, ask the user — never propose a plausible-sounding alternative.
- **Entity names must be <= 20 characters** — alphanumeric and underscore only, must begin with a letter. Violations cause silent failures.
- **Never INSERT/UPDATE data in standard tables directly. Use form interfaces (INTERFACE program with GENERALLOAD or dynamic `-form`)** — raw SQL bypasses form and column triggers, integrity checks, and privilege rules, causing silent business-logic breakage. Direct SQL `UPDATE`/`INSERT` is acceptable ONLY for small, targeted changes that do not affect triggered business logic, and ONLY after proposing it to the user and receiving explicit approval.
- Every LINK/UNLINK operation must be followed by a success check.
- Use `ENTMESSAGE` for non-ASCII text in code (e.g., Hebrew messages).
- Custom form messages must use numbers > 500.
- Custom report/form column numbers must be >= 500.
- LABELs in code must use numbers with at least 4 digits.
- Join IDs and column IDs in custom forms must be > 5.
- Assign module "Internal Development" to all custom entities.

## Quick Recipes (routine tasks)

For everyday Priority changes, read the matching recipe in `recipes/` and run it end-to-end. Each recipe is self-contained (preconditions, calls, post-verify). For tasks not in this list, fall back to the topical `references/*.md`.

| Task phrasing                                                  | Recipe                                |
|----------------------------------------------------------------|---------------------------------------|
| add a column / add a field                                     | recipes/add-column.md                 |
| add a column with a join / foreign key                         | recipes/add-column-with-join.md       |
| add a column with an expression / formula / computed           | recipes/add-column-with-expression.md |
| hide a column / hide a field                                   | recipes/hide-column.md                |
| add a subform link / link a subform                            | recipes/add-subform-link.md           |
| create a subform                                               | recipes/create-subform.md             |
| create a text subform                                          | recipes/create-text-subform.md        |
| add a form trigger / form-level trigger                        | recipes/add-form-trigger.md           |
| add a column trigger / POST-FIELD / CHECK-FIELD on a column    | recipes/add-column-trigger.md         |
| add a direct activation                                        | recipes/add-direct-activation.md      |
| compile a form                                                 | recipes/compile-form.md               |
| read compile errors                                            | recipes/read-compile-errors.md        |
| create a custom table                                          | recipes/create-table.md               |
| create a root form                                             | recipes/create-root-form.md           |
| list a form's columns                                          | recipes/list-form-columns.md          |
| find a form's ID                                               | recipes/find-form-id.md               |
| create a procedure                                             | recipes/create-procedure.md           |
| add a procedure step                                           | recipes/add-procedure-step.md         |
| run an interface                                               | recipes/run-interface.md              |
| copy / duplicate entity (form, report, procedure, interface)   | recipes/copy-entity.md                |
| delete entity (form / report / procedure / menu / trigger / field / direct activation) | recipes/delete-entity.md |
| upgrade form changes (deploy via UPGRADES)                     | recipes/upgrade-form-changes.md       |

## Development Workflow

### Writing Form Triggers

Form triggers are the primary way to add business logic. The execution order:

1. **PRE-FORM** - Runs once when form loads
2. **CHECK-FIELD** - Validates field value on exit
3. **POST-FIELD** - Executes after field value is confirmed
4. **CHOOSE-FIELD** - Provides selection list for a field
5. **SEARCH-FIELD** - Provides search functionality
6. **PRE-INSERT** - Before new record is saved
7. **POST-INSERT** - After new record is saved
8. **PRE-UPDATE** - Before record update is saved
9. **POST-UPDATE** - After record update is saved
10. **PRE-DELETE** - Before record deletion
11. **POST-DELETE** - After record deletion
12. **POST-FORM** - Runs when form closes

Trigger naming: Form-level triggers use `prefix_TRIGGERTYPE` (e.g., `ACME_POST-INSERT`). Column-level triggers are declared against the column name — the trigger type (CHECK-FIELD, POST-FIELD, etc.) is specified separately, not embedded in the name.

### Writing Procedures

Procedure steps execute sequentially. Key step types:

| Type | Command | Purpose |
|------|---------|---------|
| Query | SQLI code | Execute SQL logic |
| Report | Report name | Generate output |
| Form | Form name | Open form for input |
| Message | PRINT/PRINTERR | Display messages |
| Input | PAR parameter | Collect user input |

### Writing Interfaces

To load data into Priority:
1. Populate the `GENERALLOAD` table with data
2. Execute the INTERFACE program with the interface name
3. Check STACKERR for errors

```sql
/* Basic interface execution pattern */
EXECUTE INTERFACE 'INTERFACE_NAME' SQL.TMPFILE;
```

### Common SQL Patterns

**Variables:** `:$.COL` for form columns, `:PAR1`-`:PAR8` for parameters, `SQL.` prefix for system variables.

**Flow control:** `GOTO`, `LABEL`, `IF...THEN...ELSE`, `WHILE...LOOP...END`.

**Error messages:**
```sql
ERRMSG 1 WHERE :$.FIELD = '';    /* Block save with error */
WRNMSG 1 WHERE :$.FIELD = '';    /* Warn but allow save */
```

## Reference Files

### Core Language

| File | Contents |
|------|----------|
| **`references/sql-core.md`** | SQL functions, variables, flow control, scalar expressions (strings, dates, numbers), ATOD/DTOA, LINK/UNLINK, return values |
| **`references/tables-and-dbi.md`** | Table creation, column types, keys, DBI syntax, naming rules, dev environment setup |

### Entity Development

| File | Contents |
|------|----------|
| **`references/forms.md`** | Form creation, all column types, joins, sub-level forms, conditions, text forms, SQL variables |
| **`references/triggers.md`** | All trigger types with examples, ERRMSG/WRNMSG, MAILMSG, INCLUDE/buffers, form preparation |
| **`references/reports.md`** | Report creation, columns, sorting/grouping, calculated columns, CSS styling, report types, user report generators (copy-ASSETREP-and-RUNCUSTREP pattern) |
| **`references/procedures.md`** | Procedure steps, parameters, user input methods, step queries, flow control, PRINT messages, direct activations (`:$.PAR`, LINK/UNLINK/INSERT) |
| **`references/documents.md`** | Document generation, WINHTML program (direct/quick syntax), all parameters, print formats |
| **`references/interfaces.md`** | Form loads (INTERFACE), table loads (DBLOAD), GENERALLOAD, XML/JSON, dynamic interfaces, STACKERR, ODBC Driver, EDI form-load internals (INTERFORMS → FORMCLTRIG, INTERCLMNSFILE → FORMCLMNS) |
| **`references/deployment.md`** | Upgrade shells: UPGCODE decision (TAKETRIG/TAKEFORMCOL/TAKEPROCSTEP/etc.), TAKEUPGRADE / DOWNLOADUPG / INSTITLE, DBI in UPGNOTES for system-table columns, programmatic revision via WebSDK |
| **`references/common-mistakes.md`** | Flat "symptom → wrong approach → right approach → see" catalog of anti-patterns historically made by the LLM; use as fast "why isn't X working" lookup |

### Advanced Topics

| File | Contents |
|------|----------|
| **`references/integrations.md`** | WSCLIENT (REST/OAuth2/SOAP 25.1+), XMLPARSE, JSONPARSE, SFTPCLNT, WINAPP, WINRUN, SHELLEX, Activate Priority from External Application |
| **`references/file-operations.md`** | COPYFILE/MOVEFILE/DELWINDOW/MAKEDIR/GETDATE/GETSIZE, FILELIST, FILTER (text replace + encoding + base64), CRPTUTIL encryption, PREXFILE (print attachments), Click2Sign, TABINI (client INI) |
| **`references/advanced-sqli.md`** | Run procedure/report from SQLI (WINACTIV/ACTIVATE/ACTIVATF), Financial Documents hooks (PREENAME/CONTENAME), Open Form Record from Procedure, Dynamic SQL, Semaphores, Word Templates for Specific Records, Business Rules Generator |
| **`references/debugging.md`** | Debug flags (-trc), optimization, logging, revisions, VSCode extension, HEAVYQUERY, **Claude Code MCP integration** |
| **`references/compile-debugging.md`** | FORMPREPERRS triage: error-path decoding (`FORM/COL/EXPR`, `FORM/TRIGGER`), root-cause classes (orphan-expression, missing-column-ref, missing-message, no-visible-columns, broken-include), triage queries, chain-aware fix loop, cascade-delete recipes. Pair with the `compile-doctor` agent and `/compile-doctor` command. |
| **`references/vscode-bridge-examples.md`** | VSCode bridge tool usage examples: get_current_file, write_to_editor, refresh_editor, run_windbi_command (38 commands), common workflows (read→edit→compile, inspect, scaffold, search, ad-hoc queries) |
| **`references/websdk-cookbook.md`** | **WebSDK tested patterns**: operation property reference (including `filter` with `operator` for LIKE/>=/<= searches), `filter` vs `search` distinction, common mistakes, copy-paste recipes (read/hide/add columns, expressions, triggers, compile), SQLI metadata queries (FORMCLMNS, FORMTRIG, FORMCLTRIGTEXT), EFORM alias→real table mapping |
| **`references/web-cloud-dashboards.md`** | Priority Web differences, Cloud (system/sync), Dashboards/Priority Lite, BPM creation, Web SDK (CORS, connection, reports, search, procedures, encoding, performance) |

### Setup

| File | Contents |
|------|----------|
| **`references/installation.md`** | Prerequisites, plugin install, credential setup, verification |

### Code Examples

| File | Contents |
|------|----------|
| **`examples/sql-patterns.sql`** | Variables, flow control, LINK/UNLINK, string/date functions, DBI, UPSERT |
| **`examples/trigger-examples.sql`** | All trigger types with working code examples |
| **`examples/procedure-examples.sql`** | Step queries, user input, PRINT, EXECUTE, WINHTML |
| **`examples/interface-examples.sql`** | GENERALLOAD population, INTERFACE execution, DBLOAD, dynamic interfaces |
| **`examples/webservice-examples.sql`** | WSCLIENT, XMLPARSE, JSONPARSE, SFTPCLNT, FILTER |
| **`examples/websdk-examples.js`** | Web SDK JavaScript: connection, PAT auth, forms, procedures, reports, search/filter |

## Quick Reference: Common Tasks

### Validate a field value
Read `references/triggers.md` > CHECK-FIELD section, then see `examples/trigger-examples.sql`.

### Create a new form with triggers
Read `references/forms.md` for form setup, then `references/triggers.md` for trigger creation. Use `examples/trigger-examples.sql` for patterns.

### Write a procedure with user input
Read `references/procedures.md` > User Input section, then see `examples/procedure-examples.sql`.

### Copy a procedure / report / form / interface
Do **not** rebuild the entity by hand. Use the `copyEntity` compound op on `websdk_form_action`:
```json
{"operations": [{"op": "copyEntity", "kind": "proc"|"report"|"form"|"interface", "source": "<SRC>", "target": "<TGT>"}]}
```
The compound maps `kind` to `COPYPROG` / `COPYREP` / `COPYFORM` / `COPYINTER` and drives `priority.procStart` + `inputFields` with both fields (source, target) in a single call — that's the only call shape that actually completes the copy. Read `references/procedures.md` > "Copying existing entities" for the gotcha and manual-invocation fallbacks (UI / `WINPROC -P`).

### Generate a document (PDF/print)
Read `references/documents.md` > WINHTML section, then see `examples/procedure-examples.sql` for WINHTML patterns.

### Load data via interface
Read `references/interfaces.md` > Load Table Pattern and Form Load Execution sections, then see `examples/interface-examples.sql`.

### Call a REST API
Read `references/integrations.md` > WSCLIENT section, then see `examples/webservice-examples.sql`.

### Parse XML or JSON response
Read `references/integrations.md` > XML/JSON Parsing sections, then see `examples/webservice-examples.sql`.

### Debug a form or procedure
Read `references/debugging.md` > Debug Tools section for the `-trc` flag syntax.

### Triage a compile error (`prepareForm` fails, or "Prepare All Forms" lists errors)
Read `references/compile-debugging.md`. It decodes the `FORM/COLUMN/STEP` error path, classifies the error by root cause, and gives a paste-ready triage query + fix recipe for each class. For automated triage, invoke `/compile-doctor ENTITY [ENTITY...]` — spawns `compile-doctor` subagents that diagnose and fix in a chain-aware loop.

### Create a table with DBI
Read `references/tables-and-dbi.md` > DBI Syntax section, then see `examples/sql-patterns.sql`.

### Transfer files via SFTP
Read `references/integrations.md` > SFTP section, then see `examples/webservice-examples.sql`.

### Run external programs (WINAPP/WINRUN) or copy/move/delete files
Read `references/integrations.md` > External Program Invocation for WINAPP/WINRUN/SHELLEX, or `references/file-operations.md` > File Management Utilities for COPYFILE/MOVEFILE/DELWINDOW.

### Use semaphores, dynamic SQL, or run a procedure/report from SQLI
Read `references/advanced-sqli.md` — procs/reports via WINACTIV/ACTIVATE/ACTIVATF, Dynamic SQL, LASTS-table and time-based semaphores.

### Encrypt data, print attachments, or base64-encode a file
Read `references/file-operations.md` — CRPTUTIL for encryption, PREXFILE for attachments, FILTER > Base64 section.

### Connect via Web SDK (JavaScript)
Read `references/web-cloud-dashboards.md` > Web SDK Common Issues section, then see `examples/websdk-examples.js`.

### Read, write, and compile code via Claude Code MCP
Read `references/vscode-bridge-examples.md` for tool usage examples and common workflows. For architecture and troubleshooting, see `references/debugging.md` > Claude Code MCP Integration.

### Scaffold new triggers or procedure steps via Claude Code
Read `references/vscode-bridge-examples.md` > Scaffolding New Code section — uses `run_windbi_command` with `createFormTrigger`, `createProcedureStep`, etc.

### Inspect entity structure (dump, table columns) via Claude Code
Read `references/vscode-bridge-examples.md` > Inspecting Entities section — uses `run_windbi_command` with `dumpForm`, `displayTableColumns`, etc.

### Generate an upgrade shell / pick the right UPGCODE
Read `references/deployment.md` > "Choosing the right UPGCODE", then use the `generate_shell` MCP tool. For custom columns on system tables, see "DBI in UPGNOTES for system-table columns".

### Look up why something isn't working
Read `references/common-mistakes.md` — fast anti-pattern catalog with pointers to the canonical reference for each symptom.

## Search Patterns

To find specific content in reference files, search for these patterns:

| Topic | Search Pattern | File |
|-------|---------------|------|
| System variables | `SQL.` or `:$` | `references/sql-core.md` |
| Date functions | `ATOD\|DTOA\|DAYS\|ADDDATE` | `references/sql-core.md` |
| String functions | `STRCAT\|SUBSTR\|STRIND\|ITOA` | `references/sql-core.md` |
| Trigger types | `CHECK-FIELD\|POST-FIELD\|PRE-INSERT` | `references/triggers.md` |
| ERRMSG/WRNMSG | `ERRMSG\|WRNMSG` | `references/triggers.md` |
| MAILMSG | `MAILMSG` | `references/triggers.md` |
| WINHTML | `WINHTML\|-d\|-dQ` | `references/documents.md` |
| Interface params | `EXECUTE INTERFACE` | `references/interfaces.md` |
| GENERALLOAD | `GENERALLOAD` | `references/interfaces.md` |
| WSCLIENT | `WSCLIENT` | `references/integrations.md` |
| JSON body for WSCLIENT | `JSON.*body\|ASCII.*BODYFILE\|STRCAT.*JSON` | `references/integrations.md`, `examples/webservice-examples.sql` |
| XMLPARSE | `XMLPARSE\|JSONPARSE` | `references/integrations.md` |
| SFTPCLNT | `SFTPCLNT` | `references/integrations.md` |
| WINAPP / WINRUN / SHELLEX | `WINAPP\|WINRUN\|SHELLEX` | `references/integrations.md` |
| COPYFILE / MOVEFILE / FILELIST / FILTER | `COPYFILE\|MOVEFILE\|FILELIST\|EXECUTE FILTER` | `references/file-operations.md` |
| CRPTUTIL (encryption) | `CRPTUTIL` | `references/file-operations.md` |
| PREXFILE (print attachments) | `PREXFILE` | `references/file-operations.md` |
| Dynamic SQL / Semaphores | `EXECUTE SQLI\|LASTS` | `references/advanced-sqli.md` |
| Run proc/report from SQLI | `ACTIVATF\|WINACTIV\|ACTIVATE` | `references/advanced-sqli.md` |
| Debug | `-trc\|DEBUGSQL\|HEAVYQUERY` | `references/debugging.md` |
| Compile errors (FORMPREPERRS triage) | `parse error at or near symbol ;\|FORM/COL/EXPR\|orphan-expression\|missing-column-ref\|compile-doctor` | `references/compile-debugging.md` |
| Dashboard | `WINHTMLH\|HTMLCURSOR` | `references/web-cloud-dashboards.md` |
| Web SDK | `CORS\|Connection\|PAT\|reportOptions\|getRows\|displayURL` | `references/web-cloud-dashboards.md` |
| HEBCONV | `HEBCONV\|CLR\|hebutils` | `references/sql-core.md` |
| ODBC | `ODBC\|priodbc` | `references/interfaces.md` |
| VSCode bridge | `get_current_file\|write_to_editor\|run_windbi_command` | `references/vscode-bridge-examples.md` |
| WebSDK operations | `websdk_form_action\|startSubForm\|getRows\|fieldUpdate\|EFORM` | `references/websdk-cookbook.md` |
| WebSDK search/filter | `LIKE\|operator\|choose\|setSearchFilter\|clearFilter\|search` | `references/websdk-cookbook.md` |
| Form metadata tables | `FORMCLMNS\|FORMTRIG\|FORMCLTRIGTEXT\|HIDEBOOL\|HIDE` | `references/websdk-cookbook.md` |
| Text subform recipe (6-call) | `Text Subform Creation\|TEXTFORM\|EDES.*LOG\|FCLMNA.*EXPR` | `references/websdk-cookbook.md` |
| Find form internal ID | `Find a form's internal ID\|EXEC FROM EXEC` | `references/websdk-cookbook.md` |
| Copy entity (proc/report/form/interface) | `COPYPROG\|COPYREP\|COPYFORM\|COPYINTER\|WINPROC -P` | `references/procedures.md` |
| Generator-form ENAMEs | `EPROG\|EREP\|EFORM\|EINTER\|Canonical generator-form names` | `references/websdk-cookbook.md` |
| SELECT prints nothing | `Output Formats for SELECT\|FORMAT;\|Execution ok` | `references/sql-core.md`, `references/common-mistakes.md` |
| Unfiltered getRows empty / bridge sees nothing | `Unfiltered .getRows. returns empty\|session or tenant\|Logging in to url` | `references/common-mistakes.md`, memory `feedback_verify_bridge_tenant_before_debug.md` |
| Subagent hallucinated a result | `Done .0 tool uses\|subagent summary\|unverified` | `references/common-mistakes.md` |
| Upgrade shells / UPGCODE | `UPGCODE\|TAKESINGLEENT\|TAKETRIG\|TAKEFORMCOL\|UPGNOTES\|TAKEUPGRADE\|DOWNLOADUPG\|generate_shell` | `references/deployment.md` |
| Direct activations | `FORMEXEC\|:\$\.PAR\|direct activation\|LINK.*TO.*:\$\.PAR` | `references/procedures.md`, `references/deployment.md` |
| EDI internals | `INTERFORMS\|INTERCLMNSFILE\|EINTER\|INTERFACE.*-form` | `references/interfaces.md` |
| Known bridge behaviors | `QueryValues\|setSearchFilter\|runSqliFile\|FORMCLTRIGTEXT.*append\|FCLMNA.*scalar` | `references/websdk-cookbook.md` |
| Anti-patterns / why doesn't X work | `Wrong:\|Right:\|See:\|common mistake` | `references/common-mistakes.md` |
| MCP tools | `priority-dev\|priority-gateway\|bridge` | `references/debugging.md`, `references/vscode-bridge-examples.md` |
| Scaffold | `createFormTrigger\|createProcedureStep` | `references/vscode-bridge-examples.md` |
