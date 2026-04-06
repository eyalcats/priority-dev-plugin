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
  "write a dashboard procedure", or mentions Priority ERP development,
  form triggers, SQLI, Priority procedures, or Priority SDK.
  Provides comprehensive reference for the Priority ERP SDK including
  SQL dialect, forms, triggers, reports, procedures, interfaces,
  documents, web services, and debugging tools.
version: 1.0.0
---

# Priority SDK Development Guide

Reference skill for writing, debugging, and maintaining code in the Priority ERP system. Covers the full SDK: SQL dialect, forms, triggers, reports, procedures, interfaces, documents, integrations, and debugging.

## Installation

### Prerequisites

- **VSCode** with the [Priority Dev Tools extension](https://marketplace.visualstudio.com/items?itemName=PrioritySoftware.priority-vscode) installed and at least one environment configured
- **Claude Code** CLI installed

### Install the Plugin

```bash
git clone https://github.com/eyalcats/priority-dev-plugin.git
claude plugin add ./priority-dev-plugin
```

That's it. On first session start, the plugin will:
1. Auto-install the Priority Claude Bridge VSCode extension (if not already installed)
2. Configure the MCP connection to the bridge
3. Check for credentials — if the Priority Dev Tools extension has an environment configured, no additional setup is needed

### Verify

1. Reload VSCode (`Ctrl+Shift+P` > `Developer: Reload Window`)
2. Open a Priority file from the Environments Explorer
3. Start Claude Code and ask: `List the Priority bridge tools available`

### Manual Credential Setup (only if Priority Dev Tools extension is not installed)

Add to VSCode settings (`Ctrl+,`):
```json
{
  "priorityClaudeBridge.serverUrl": "https://your-server",
  "priorityClaudeBridge.company": "your-company",
  "priorityClaudeBridge.username": "your-user",
  "priorityClaudeBridge.password": "your-password",
  "priorityClaudeBridge.tabulaini": "tabula.ini"
}
```

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

- Never INSERT/UPDATE data in standard tables directly. Use interfaces (INTERFACE program).
- Every LINK/UNLINK operation must be followed by a success check.
- Use `ENTMESSAGE` for non-ASCII text in code (e.g., Hebrew messages).
- Custom form messages must use numbers > 500.
- Custom report/form column numbers must be >= 500.
- LABELs in code must use numbers with at least 4 digits.
- Join IDs and column IDs in custom forms must be > 5.
- Assign module "Internal Development" to all custom entities.

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

Trigger naming: `prefix_TRIGGERTYPE` for form-level, or use the column name for column-level triggers.

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
| **`references/forms-and-triggers.md`** | Form creation, all column types, all trigger types with examples, ERRMSG/WRNMSG, MAILMSG, INCLUDE/buffers |
| **`references/reports.md`** | Report creation, columns, sorting/grouping, calculated columns, CSS styling, report types |
| **`references/procedures.md`** | Procedure steps, parameters, user input methods, step queries, flow control, PRINT messages |
| **`references/documents.md`** | Document generation, WINHTML program (direct/quick syntax), all parameters, print formats |
| **`references/interfaces.md`** | Form loads (INTERFACE), table loads (DBLOAD), GENERALLOAD, XML/JSON, dynamic interfaces, STACKERR, ODBC Driver |

### Advanced Topics

| File | Contents |
|------|----------|
| **`references/advanced-programming.md`** | WSCLIENT (REST/OAuth2), XMLPARSE, JSONPARSE, SFTPCLNT, FILTER, WINAPP, WINRUN, Dynamic SQL, Semaphores, Click2Sign |
| **`references/debugging.md`** | Debug flags (-trc), optimization, logging, revisions, VSCode extension, HEAVYQUERY, **Claude Code MCP integration** |
| **`references/vscode-bridge-examples.md`** | VSCode bridge tool usage examples: get_current_file, write_to_editor, refresh_editor, run_windbi_command (38 commands), common workflows (read→edit→compile, inspect, scaffold, search, ad-hoc queries) |
| **`references/web-cloud-dashboards.md`** | Priority Web differences, Cloud (system/sync), Dashboards/Priority Lite, BPM creation, Web SDK (CORS, connection, reports, search, procedures, encoding, performance) |

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
Read `references/forms-and-triggers.md` > CHECK-FIELD section, then see `examples/trigger-examples.sql`.

### Create a new form with triggers
Read `references/forms-and-triggers.md` for form setup, then trigger creation. Use `examples/trigger-examples.sql` for patterns.

### Write a procedure with user input
Read `references/procedures.md` > User Input section, then see `examples/procedure-examples.sql`.

### Generate a document (PDF/print)
Read `references/documents.md` > WINHTML section, then see `examples/procedure-examples.sql` for WINHTML patterns.

### Load data via interface
Read `references/interfaces.md` > Load Table Pattern and Form Load Execution sections, then see `examples/interface-examples.sql`.

### Call a REST API
Read `references/advanced-programming.md` > WSCLIENT section, then see `examples/webservice-examples.sql`.

### Parse XML or JSON response
Read `references/advanced-programming.md` > XML/JSON Parsing sections, then see `examples/webservice-examples.sql`.

### Debug a form or procedure
Read `references/debugging.md` > Debug Tools section for the `-trc` flag syntax.

### Create a table with DBI
Read `references/tables-and-dbi.md` > DBI Syntax section, then see `examples/sql-patterns.sql`.

### Transfer files via SFTP
Read `references/advanced-programming.md` > SFTP section, then see `examples/webservice-examples.sql`.

### Connect via Web SDK (JavaScript)
Read `references/web-cloud-dashboards.md` > Web SDK Common Issues section, then see `examples/websdk-examples.js`.

### Read, write, and compile code via Claude Code MCP
Read `references/vscode-bridge-examples.md` for tool usage examples and common workflows. For architecture and troubleshooting, see `references/debugging.md` > Claude Code MCP Integration.

### Scaffold new triggers or procedure steps via Claude Code
Read `references/vscode-bridge-examples.md` > Scaffolding New Code section — uses `run_windbi_command` with `createFormTrigger`, `createProcedureStep`, etc.

### Inspect entity structure (dump, table columns) via Claude Code
Read `references/vscode-bridge-examples.md` > Inspecting Entities section — uses `run_windbi_command` with `dumpForm`, `displayTableColumns`, etc.

## Search Patterns

To find specific content in reference files, search for these patterns:

| Topic | Search Pattern | File |
|-------|---------------|------|
| System variables | `SQL.` or `:$` | `references/sql-core.md` |
| Date functions | `ATOD\|DTOA\|DAYS\|ADDDATE` | `references/sql-core.md` |
| String functions | `STRCAT\|SUBSTR\|STRIND\|ITOA` | `references/sql-core.md` |
| Trigger types | `CHECK-FIELD\|POST-FIELD\|PRE-INSERT` | `references/forms-and-triggers.md` |
| ERRMSG/WRNMSG | `ERRMSG\|WRNMSG` | `references/forms-and-triggers.md` |
| MAILMSG | `MAILMSG` | `references/forms-and-triggers.md` |
| WINHTML | `WINHTML\|-d\|-dQ` | `references/documents.md` |
| Interface params | `EXECUTE INTERFACE` | `references/interfaces.md` |
| GENERALLOAD | `GENERALLOAD` | `references/interfaces.md` |
| WSCLIENT | `WSCLIENT` | `references/advanced-programming.md` |
| JSON body for WSCLIENT | `JSON.*body\|ASCII.*BODYFILE\|STRCAT.*JSON` | `references/advanced-programming.md`, `examples/webservice-examples.sql` |
| XMLPARSE | `XMLPARSE\|JSONPARSE` | `references/advanced-programming.md` |
| SFTPCLNT | `SFTPCLNT` | `references/advanced-programming.md` |
| Debug | `-trc\|DEBUGSQL\|HEAVYQUERY` | `references/debugging.md` |
| Dashboard | `WINHTMLH\|HTMLCURSOR` | `references/web-cloud-dashboards.md` |
| Web SDK | `CORS\|Connection\|PAT\|reportOptions\|getRows\|displayURL` | `references/web-cloud-dashboards.md` |
| HEBCONV | `HEBCONV\|CLR\|hebutils` | `references/sql-core.md` |
| ODBC | `ODBC\|priodbc` | `references/interfaces.md` |
| VSCode bridge | `get_current_file\|write_to_editor\|run_windbi_command` | `references/vscode-bridge-examples.md` |
| MCP tools | `priority-dev\|priority-gateway\|bridge` | `references/debugging.md`, `references/vscode-bridge-examples.md` |
| Scaffold | `createFormTrigger\|createProcedureStep` | `references/vscode-bridge-examples.md` |
