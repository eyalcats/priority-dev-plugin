# Procedures Reference

## Table of Contents

- [Introduction](#introduction)
- [Copying existing entities (COPYPROG / COPYREP / COPYFORM / COPYINTER)](#copying-existing-entities-copyprog--copyrep--copyform--copyinter)
- [Procedure Attributes](#procedure-attributes)
- [Procedure Steps](#procedure-steps)
  - [Step Types](#step-types)
  - [Basic Commands](#basic-commands)
- [Procedure Parameters](#procedure-parameters)
  - [Parameter Name and Title](#parameter-name-and-title)
  - [Parameter Order](#parameter-order)
  - [Parameter Content Types](#parameter-content-types)
  - [Parameter Types](#parameter-types)
- [User Input in Procedures](#user-input-in-procedures)
  - [Input a New Value](#input-a-new-value)
  - [Choose Between Several Fixed Options](#choose-between-several-fixed-options)
  - [Choose Options from Radio Buttons (CHOOSE)](#choose-options-from-radio-buttons-choose)
  - [Retrieve Records Into a Linked File](#retrieve-records-into-a-linked-file)
  - [Input Text Into an HTML Screen](#input-text-into-an-html-screen)
  - [Other Input Options](#other-input-options)
  - [Write CHOOSE-FIELD / SEARCH-FIELD Triggers](#write-choose-field--search-field-triggers)
  - [Access a Related Form (Target Form for Parameters)](#access-a-related-form-target-form-for-parameters)
  - [Input During Action (PAR Parameter)](#input-during-action-par-parameter)
  - [Use a Form for Input](#use-a-form-for-input)
- [Procedure Step Queries](#procedure-step-queries)
  - [Error and Warning Messages](#error-and-warning-messages)
  - [Parameter Variables](#parameter-variables)
  - [Handle Heavy Processing](#handle-heavy-processing)
  - [Check SQL Syntax](#check-sql-syntax)
- [Procedure Flow Control](#procedure-flow-control)
  - [CONTINUE -- Continue or Halt](#continue----continue-or-halt)
  - [GOTO -- Jump to a Step](#goto----jump-to-a-step)
  - [Activate a User-Chosen Option](#activate-a-user-chosen-option)
- [Procedure Messages -- PRINT, PRINTCONT, PRINTERR](#procedure-messages----print-printcont-printerr)
  - [Print a Fixed Message](#print-a-fixed-message)
  - [Use MESSAGE and WRNMSG Alternatives](#use-message-and-wrnmsg-alternatives)
- [Processed Reports](#processed-reports)
  - [Report Step Parameters](#report-step-parameters)
  - [Change the Report Title at Runtime](#change-the-report-title-at-runtime)
  - [Define Dynamic Column Titles](#define-dynamic-column-titles)
  - [Define Dynamic Report Conditions](#define-dynamic-report-conditions)
- [Run Procedures](#run-procedures)

---

## Introduction

Procedures are a set of executable steps carried out in a predefined order. Common uses:
- Create **processed reports** (reports with data manipulation)
- Create **documents** (multi-report output displayed in browser)
- Create new documents via **form interface** (e.g., generating a sales order from another document)
- Run **SQLI** programs and internal programs for data manipulation

**Never insert records directly into tables.** Use form load interfaces instead.

A procedure is characterized by:
- A unique name
- A title
- Steps of execution
- Parameters

## Copying existing entities (COPYPROG / COPYREP / COPYFORM / COPYINTER)

**When the user says "copy", "duplicate", or "clone" a procedure / report / form / interface, invoke the matching Priority copier program. Do NOT rebuild the entity by hand with `INSERT INTO EXEC`, trigger-by-trigger SQL, or column-by-column WebSDK.** The copiers preserve metadata that manual reconstruction misses (step queries, parameters, triggers, message text, column joins).

The four copiers are standard Priority procedures, verifiable via SQLI:

```sql
SELECT ENAME, TITLE, TYPE FROM EXEC
WHERE ENAME IN ('COPYPROG','COPYREP','COPYFORM','COPYINTER') AND TYPE = 'P'
FORMAT;
```

| Program     | Copies          | Ships as | Related generator form |
|-------------|-----------------|----------|------------------------|
| `COPYPROG`  | Procedure       | TYPE='P' | `EPROG` (Procedure Generator — **not** `EPROC`) |
| `COPYREP`   | Report          | TYPE='P' | `EREP` (Report Generator) |
| `COPYFORM`  | Form            | TYPE='P' | `EFORM` (Form Generator) |
| `COPYINTER` | Interface       | TYPE='P' | `EINTER` (Interface Generator) |

> **System forms are off-limits.** Copying a standard (non-custom-prefix) form is **forbidden** — the only exception is the user-report-generator form (`ASSETREP` → your prefix) documented in `reports.md` § "Create Your Own Generator". Never copy `ORDERS`, `AINVOICES`, `EFORM`, etc. Do copy your own `XXXX_*` custom entities.

### What each copier carries over

- `COPYPROG` — all procedure steps, parameters, step queries, procedure messages, designated target forms. Does **not** copy the output title or links to menus / forms / other procedures.
- `COPYREP` — report columns (with revised titles / group-by / input flags), joins, conditions, optimization. Relink to menus after copying.
- `COPYFORM` — form columns, triggers, sub-level links, FCLMNA expressions. For generator-form copies (`ASSETREP` pattern), you still need to edit the PRE-FORM trigger's prefix variable and the `LIKE '<prefix>%'` expressions — see `reports.md`.
- `COPYINTER` — load-target, GENERALLOAD column mappings, INTERCLMNS rows.

### Invocation — three paths

The copiers are TYPE='P' with no parent form, so they are run top-level (not via `activateStart` on a generator form). Pick the path that matches the environment:

1. **WebSDK via the bridge (preferred for Claude Code).** Use the `copyEntity` compound op on `websdk_form_action` — no `form` parameter, the compound drives `priority.procStart` + `inputFields` internally:

   ```json
   {
     "operations": [
       {
         "op": "copyEntity",
         "kind": "proc",
         "source": "SOF_TEST",
         "target": "ZZZ_SOF_TEST_COPY"
       }
     ]
   }
   ```

   `kind` must be one of `"proc"` / `"report"` / `"form"` / `"interface"` — the compound maps them to `COPYPROG` / `COPYREP` / `COPYFORM` / `COPYINTER` respectively. Returns `{status: "ok"}` on success with the program name and full step trace in `data.trace`.

   Verified live against `SOF_TEST` → `ZZZ_SOF_TEST_COPY` on 2026-04-21 — trace: inputFields(both fields in one call) → message("העתקת הפרוצדורה הסתיימה בהצלחה" / "Copy completed successfully") → end.

2. **Priority UI (Windows / Web)** — use when the user is at the keyboard.
   - Windows client: **Tools → Run Entity (Advanced…)** → enter `COPYPROG` (or `COPYREP` / `COPYFORM` / `COPYINTER`).
   - Web client: **Run → Run Entity (Advanced…)** → same.
   - Priority prompts for **Source** and **Target** in a single dialog with two fields.

3. **Command line (server shell).**
   ```
   WINPROC -P COPYPROG
   WINPROC -P COPYREP
   WINPROC -P COPYFORM
   WINPROC -P COPYINTER
   ```

### The subtle inputFields gotcha

COPY* procs take **both** the source and target in a **single** `inputFields` step, as field 1 and field 2. Supplying only field 1 and then trying to continue (via `continueProc` or a second `inputFields` call) lands you with either a silent "proc finished, no copy made" state or "הפרוצדורה הנוכחית אינה פעילה יותר" ("current procedure is no longer active"). The canonical call shape the compound uses:

```js
let proc = await priority.procStart('COPYPROG', 'P');
// proc.type === 'inputFields' — supply BOTH fields in one call
proc = await proc.proc.inputFields(1, { EditFields: [
  { field: 1, op: 0, value: '<SOURCE>', op2: 0, value2: '' },
  { field: 2, op: 0, value: '<TARGET>', op2: 0, value2: '' },
]});
// proc.type === 'message' / messagetype === 'information' — success
// proc.type === 'end' on the next step
```

If you ever need to build a similar driver for a different input-step-only procedure, model it on `generateCopyEntityScript` / `generateCompileScript` in `bridge/src/websdk/compounds.ts`.

### Don't: symptoms of re-inventing the copier

If you find yourself running `INSERT INTO EXEC (ENAME, TITLE, TYPE, EDES) VALUES ...` followed by hand-rebuilding steps / parameters / triggers — stop. Use the `copyEntity` compound op (or the UI / `WINPROC -P`), then diff the copy for the custom tweaks you actually wanted. `common-mistakes.md` has a quick-lookup entry.

## Procedure Attributes

### Procedure Name

Follow the same restrictions as report names: alphanumeric + underline, begins with letter, no reserved words, four-letter prefix for custom procedures (e.g., `XXXX_WWWSHOWORDER`).

### Procedure Title

- Restrict to 32 characters
- Designate a longer title in the **Output Title** sub-level form
- For procedures running reports, specify the output title for the report instead (report title takes precedence)

### Procedure Type (Rep/Wizard/Dashboard)

| Value | Meaning |
|-------|---------|
| `R` | Procedure runs a report |
| `N` | Run a report but suppress the Print/Send Options dialog |
| `R` + HTML Document = `Y` | Create a document |

### Application and Module

Same as for reports. Specify **"Internal Development"** for custom procedures.

---

## Procedure Steps

Define steps in the **Procedure Steps** form (sub-level of Procedure Generator). Each step is an entity identified by name and type. Determine execution order with the **Step** column.

When modifying execution order, create an identical step with a different Step value and delete the old step.

### Step Types

| Type | Description |
|------|-------------|
| `R` | Report -- generate a report after data processing |
| `F` | Form -- use to input data |
| `P` | Procedure -- activate a sub-procedure |
| `B` | Basic command -- parameter input, message output, flow control |
| `I` | Form load interface -- load data into a Priority form |
| `L` | Table load file -- import external data |
| `C` | Compiled program -- manipulate data |

### Load Step (ETYPE = L)

A step with type `L` invokes a Load-table entity defined in **Characteristics for Download** (DBLOAD). Priority reads the file staged by a preceding UPLOAD step, parses it per the load table layout, and populates the staging table. The standard parameter for an L step is `MSG` (ASCII type, position 10), which receives load messages.

Example scaffold (LOADORDERS procedure, step POS=40):

```
Step entity name : LOADORDERS
Step type        : L
PROGPARAM        : NAME=MSG, TYPE=ASCII, POS=10
```

The entity name of the L step must match the load file name registered in **Characteristics for Download** -- typically identical to the staging table/form name. The L step is the counterpart to the `EXECUTE DBLOAD` form (see [Table Loads (DBLOAD)](#table-loads-dbload) in interfaces.md); using it as a procedure step is the standard approach for file-import wizards.

*(seen in: LOADORDERS)*

### Basic Commands

| Command | Description |
|---------|-------------|
| `BACKGROUND` | Cause the remainder of the procedure to run in the background |
| `CHOOSE` | Create a menu of exclusive radio button options (not displayed when run as Action) |
| `CHOOSEF` | Same as CHOOSE, but display when run as Action |
| `CONTINUE` | Pop-up with OK/Cancel; continue or halt the procedure (not displayed as Action) |
| `CONTINUEF` | Same as CONTINUE, but display when run as Action |
| `END` | End execution of the procedure; use with GOTO |
| `GOTO` | Jump to a designated procedure step |
| `HTMLCURSOR` | Declare the cursor for a document; create linked file from PAR parameter |
| `HTMLEXTFILES` | Include a flag allowing the user to print attachments with the document |
| `INPUT` | Input parameter values; create parameter input screen (not displayed as Action) |
| `INPUTF` | Same as INPUT, but display when run as Action |
| `MAILMERGE` | Use for Letter Generator document generation |
| `MESSAGE` | Display a procedure message on screen (not displayed as Action) |
| `MESSAGEF` | Same as MESSAGE, but display as Action |
| `PRINT` | Display file contents or a fixed string on screen (not displayed as Action) |
| `PRINTF` | Same as PRINT, but display when run as Action |
| `PRINTCONT` | Like PRINT, but offer Continue/Stop options (not displayed as Action) |
| `PRINTCONTF` | Same as PRINTCONT, but display when run as Action |
| `PRINTERR` | Display file contents as error and cause procedure failure; no effect if file is empty |
| `SHOWCOPY` | Create a certified copy of a document. Take two parameters: document ID and document type |
| `UPLOAD` | Upload a file to the server. Cannot be used with EXECUTE |
| `DOWNLOAD` | Download a file from the server. Cannot be used with EXECUTE |
| `URL` | Open a webpage from a web address stored in an ASCII file |
| `WRNMSG` | Like MESSAGE, but include a Cancel button (not displayed as Action) |
| `WRNMSGF` | Same as WRNMSG, but display when run as Action |

Note: Commands ending in `F` are displayed when the procedure runs as an Action from a form; their counterparts without `F` are not.

---

## Procedure Parameters

Define parameters in the **Procedure Parameters** form (sub-level of Procedure Steps). Parameters transfer arguments between procedures, programs, reports, and users.

### Parameter Name and Title

- Restrict the name to **up to 3 characters** (e.g., `DAY`, `MSG`, `AA`)
- Follow the same naming rules as procedures but no prefix is required
- The title is displayed to the user for input parameters, or stored as a brief message for PRINT/PRINTCONT/PRINTERR

### Parameter Order

Determine order by the **position** column (an integer). Not required for single-parameter steps or report steps.

### Parameter Content Types

| Content | Description |
|---------|-------------|
| **Constant/Variable** | Assign in the Value column; prefix variables with `:` and define them earlier in the procedure |
| **Text file** | Determine content by a program step; use for message files with PRINT/PRINTCONT/PRINTERR |
| **Linked file** | Copy of a database table with selected records; tie to a specific table and column via Table Name and Column Name |

### Parameter Types

| Type | Usage |
|------|-------|
| `CHAR`, `REAL`, `INT`, `UNSIGNED`, `DATE`, `TIME`, `DAY` | Constant value parameters |
| `ASCII` | Text file parameter |
| `TEXT` | Store text (HTML input screen) |
| `FILE` | Linked file -- group of records from the database |
| `NFILE` | Like FILE, but link table remains empty when user enters `*` or leaves field empty |
| `LINE` | Linked file -- single record from the database |
| `HELP` | Help message displayed as part of the input window |

---

## User Input in Procedures

### Input a New Value

Specify input with `I` (optional) or `M` (mandatory) in the **Input** column. The user sees an `=` sign in the first line of the parameter input screen.

**Pre-set values**: Specify in the Value column (e.g., `SQL.DATE8` for current date). To ensure the pre-set value always appears (not the user's last value), enter the **Procedure Parameter Extension** and specify `d` in the Type column.

**Boolean checkbox**: Specify `Y` in the Type column of Procedure Parameter Extension.

### Choose Between Several Fixed Options

1. Create a parameter of `INT` type
2. Record options in consecutive messages in the **Procedure Messages** form
3. In Procedure Parameter Extension, specify `C` in the Type column
4. Indicate the range in **From Message** and **To Message** columns

To use messages from a different procedure, designate its name in the **Entity Name** column.

### Choose Options from Radio Buttons (CHOOSE)

The first parameter stores the result of the user's choice; its title appears as the heading.

**Method 1: Parameter list**
- Define additional parameters with unique constant values (integers), titles, and positions
- The user's choice value is assigned to the first parameter

**Method 2: CHOOSE query**
Write in the **Step Query** sub-level of the CHOOSE/CHOOSEF step:
```sql
/* SQL query with three CHAR arguments in SELECT */
/* Arg 1, Arg 2: displayed next to radio button */
/* Arg 3: value assigned to the parameter */
/* Use '' for Arg 2 to display single value */
```

### Retrieve Records Into a Linked File

Specify **Column Name** and **Table Name**. The user can:
- Specify a search pattern
- Access a form to retrieve desired records
- Input data from a specific form record (when procedure runs as Action)

### Input Text Into an HTML Screen

Set parameter type to `TEXT`. The user enters unlimited lines in a text field, returned via `PROCTABLETEXT`:

```sql
LINK PROCTABLETEXT TO :$.TXT;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO GENERALLOAD (LINE,RECORDTYPE,TEXT)
SELECT 2+KLINE, '2',TEXT FROM PROCTABLETEXT WHERE KLINE > 0;
UNLINK PROCTABLETEXT;
```

### Other Input Options

In the **Procedure Parameter Extension** sub-level:
- **Browse Button = `Y`**: Open Windows Explorer for file selection (CHAR type parameter)
- **Browse Button = `S`**: Allow user to save a new file
- **Hide User Input**: Encode input (shows `++++++` marks, e.g., for passwords)

### Write CHOOSE-FIELD / SEARCH-FIELD Triggers

Use the **Field Triggers** form (sub-level of Procedure Parameters). Reference any input value in the same step via `:PROGPAR.ParameterName`.

### Access a Related Form (Target Form for Parameters)

For linked file parameters, override the default target form by specifying the form name in **Target Form Name** in Procedure Parameter Extension.

The target form must be a root form whose base table includes the originating column. Specify the `NULL` form to disable automatic access.

### Input During Action (PAR Parameter)

When a procedure runs as an Action from a form:
1. Place the `PAR` parameter in the **first position** of the procedure's **first step**
2. Set type to `FILE`
3. A linked file is created from the form's base table consisting of the current record

For additional user input, use `INPUTF` or `CHOOSEF` commands.

### Use a Form for Input

A form step (type `F`) loads a root form and all sub-levels. Use when the user needs to retrieve multiple records with complex queries.

---

## Procedure Step Queries

Record SQL statements in the **Step Query** form (sub-level of Procedure Steps). Supported for `INPUT`, `SQLI`, `HTMLCURSOR`, and `HTMLEXTFILES` commands.

Statements are executed **after** parameter input.

### Error and Warning Messages

Generate error/warning messages in step queries using `ERRMSG` and `WRNMSG` statements. Specify message content in the **Procedure Messages** form (sub-level of Step Query). Continue long messages in the **Procedure Messages (cont.)** sub-level.

Include parameters (`<P1>`, `<P2>`, `<P3>`) in messages with values defined via `:PAR1`, `:PAR2`, `:PAR3`. HTML formatting is supported: `<P1>{=html}`, `<P2>{=html}`, `<P3>{=html}`.

Reference Priority entities in messages: `{entity_name.{ F | R | P }}` (F=form, R=report, P=procedure).

Use the `MAILMSG` command in step queries as well. Note: In SQLI steps, messages are buffered (limit: 100 per step). To send more, use `GOTO` to create an internal loop between steps.

### Parameter Variables

Reference parameters in step queries using SQL variables:
```
:ProcedureName.ParameterName
```
Use the wildcard `$` for the current procedure:
```
:$.ParameterName
```

### Handle Heavy Processing

A single procedure can have up to **100 cursors** open simultaneously. Reuse the same cursor more than once, but declare it only once. If using a buffer with a cursor multiple times, write the declaration section in a separate buffer.

### Check SQL Syntax

Run the **Syntax Check** program by Action from the Procedure Generator form to check for syntax errors before activation.

### Batch Text Insertion via ADDIPHONETEXT

To bulk-insert rows into a text subform from a procedure step, use `PROCTABLETEXT` as a staging table and call `EXECUTE ADDIPHONETEXT`:

```sql
SELECT SQL.TMPFILE INTO :TXT FROM DUMMY;
LINK PROCTABLETEXT TO :TXT;
ERRMSG 1 WHERE :RETVAL <= 0;
INSERT INTO PROCTABLETEXT (KLINE, TEXT)
  SELECT SQL.LINE, <text_col> FROM <src_table> WHERE <condition>;
GOTO <skip_label> WHERE :RETVAL <= 0;
EXECUTE ADDIPHONETEXT :PARENTKEY, 0, '<TextFormName>', :TXT, 1, 0, 0;
DELETE FROM PROCTABLETEXT;
LABEL <skip_label>;
UNLINK PROCTABLETEXT;
```

`ADDIPHONETEXT` arguments: parent key (INT), `0`, text-form name (e.g., `'LOADORDERSTEXT'`), tmp file handle, `1`, `0`, `0`. `KLINE` in `PROCTABLETEXT` must equal the parent record's `LINE` value. The `DELETE FROM PROCTABLETEXT` before `UNLINK` clears the temp file. Omitting the LINK/UNLINK wrapper causes the insert to operate on the real system table.

*(seen in: LOADORDERS)*

---

## Procedure Flow Control

### CONTINUE -- Continue or Halt

Use the `CONTINUE` command (without parameters) to offer the user OK/Cancel options. This is useful before heavy data manipulation or far-reaching database changes.

### GOTO -- Jump to a Step

The `GOTO` command has a single parameter:
- **Type**: `INT`
- **Value**: The procedure step number to jump to

The value can be:
- A constant in the Value column
- Determined by an SQL statement
- Determined by the user's CHOOSE selection

### Activate a User-Chosen Option

Combine `CHOOSE` (or Choose input items), `GOTO`, and `END`:

1. The user selects an option with a value (e.g., 60)
2. The GOTO command uses the same parameter name (Value left blank, type = INT)
3. The procedure jumps to the step matching the chosen value
4. Execution continues until an `END` command

Include a Choose option that jumps to `END` to allow the user to cancel.

---

## Procedure Messages -- PRINT, PRINTCONT, PRINTERR

| Command | Behavior |
|---------|----------|
| `PRINT` | Display a message; procedure continues after user confirms |
| `PRINTCONT` | Display a message; user can continue or stop the procedure |
| `PRINTERR` | Display an error message and cause procedure failure |

All three commands display the contents of a file. If the file is empty or does not exist:
- `PRINT` and `PRINTCONT`: Procedure continues uninterrupted
- `PRINTERR`: Procedure continues (no error)

### Print a Fixed Message

Assign **CHAR type** to the parameter and specify the message in the **Title** column.

### Use MESSAGE and WRNMSG Alternatives

- `MESSAGE`: Display a message from the Procedure Messages form (message number stored in INT parameter)
- `WRNMSG`: Same, but the user can opt to halt execution

---

## Processed Reports

A processed report is a report whose data undergo processing prior to output. Specify `R` in the **Rep/Wizard/Dashboard** column of the Procedure Generator.

Typical procedure structure:
1. User input (parameter input screen or form)
2. Data manipulation (SQLI step)
3. Report step (type R) to display processed data

### Report Step Parameters

- One parameter per linked file (FILE type, Value = linked table name)
- Input parameters passed from the procedure to the report query
- No need to designate parameter position for a report step

<!-- ADDED START -->
### Common Issues and Solutions

- **Modifying Standard Print Procedures:**
  Standard printing procedures (e.g., Delivery Note or Price Quotation printing) cannot be redesigned or modified directly in the Procedure Generator. To add custom report steps or modify existing logic, you must create a copy of the standard procedure and apply changes to the duplicated version. Attempting to modify core logic may result in errors or restrictions directing you to the Document Designer.

- **Missing Private Developments After Upgrades:**
  Following system upgrades (e.g., to version 22.1), custom report formats or private developments in the "Print Formats" sub-level may occasionally become hidden or fail to execute. If reports are missing from the Procedure Generator sub-levels, verify the visibility settings and test the report execution with specific input data in a test environment to ensure compatibility with the new version's Document Designer logic.

- **Data Duplication in Print Formats:**
  If a report step produces duplicated data after an upgrade or modification, it is often due to a data filtering issue within the report query or the linked parameters. Ensure that the input parameters passed to the report step correctly filter the underlying table to a single record or the intended dataset.
<!-- ADDED END -->
### Change the Report Title at Runtime

In the SQLI step preceding the report, use:
```sql
:HTMLFNCTITLE = 'New Title';
```

### Define Dynamic Column Titles

In an SQLI step preceding the report:
```sql
:COLTITLES = 1;
SELECT ENTMESSAGE('$', 'P', 10)
INTO :title1 FROM DUMMY;
:REPCOLTITLE.30 = :title1;
```

### Define Dynamic Report Conditions

Add a local variable `REPCONDITION` (FILE type) in the SQLI step:
```sql
SELECT SQL.TMPFILE INTO :REPCONDITION FROM DUMMY;
/* Then write additional conditions to the file in ASCII format */
```

---

## Run Procedures

### From a Program

Use the **Run Procedure** program (Procedures menu) or the **Run Report/Procedure** program (Action from Procedure Generator). This is useful for testing.

### From a Menu

1. Enter the **Menu/Form Link** form (sub-level of Procedure Generator)
2. Specify the menu name and type `M`
3. Specify an integer for ordering

### As a Form Action

1. Enter the **Menu/Form Link** form
2. Specify the form name and type `F`
3. Specify an integer for ordering in the Actions list
4. Flag **Background Execution** for background execution

When run as Action, the form record on which the cursor rests is input into the `PAR` parameter.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Monitoring and Performance Tracking:**
    Procedures triggered as direct form actions may not update their completion times in the "Procedures in Progress" (`EXECQ`) system table. This is a known system limitation; while the procedure executes correctly, the monitoring screen may not accurately reflect the end time for processes initiated via direct activation compared to those run independently.

*   **UI Feedback and Progress Indicators:**
    In certain versions (notably v23.0), procedures defined as form actions with the "Confirm Execution" flag enabled may fail to display the standard loading spinner or progress indicator. If the procedure involves long-running logic, users may perceive the system as unresponsive.

*   **Processing Sub-form Data:**
    To perform actions on all child records (e.g., printing labels for all lines in a 'Warehouse Transfer' based on an action at the header level), the procedure must be designed to explicitly query the sub-form table using the parent record ID passed into the `PAR` parameter.
<!-- ADDED END -->
### Run a Sub-Procedure

Include a procedure as part of another via the **Procedure Link** form (sub-level of Procedure Generator). This is useful for reusing step sets across procedures.

## Direct activations

A direct activation is a procedure invoked as an Action from a form. The form's FORMEXEC subform holds the link; the target procedure runs against the form's current row.

For how to add a direct activation via the FORMEXEC subform and for the UPGCODE that deploys it (`TAKEDIRECTACT`), see `deployment.md` § "FORMEXEC subform for direct activations".

### The procedure receives `:$.PAR`, not `:$.COL`

A directly activated procedure gets the linked file reference via `:$.PAR`. It does **not** see the form's column values through `:$.COL` — direct activations run in a procedure context, not a form trigger context.

To read data from the form's current row, use the LINK pattern below.

### Canonical pattern — LINK + SELECT + UNLINK + INSERT

```sql
LINK CINVOICES TO :$.PAR;
SELECT IV, CUSTNAME, CURDATE
  INTO :IV, :CUSTNAME, :DATE
  FROM CINVOICES
  WHERE CINVOICES.IV = CINVOICES.IV;   /* LINK narrows to the activated row */
UNLINK CINVOICES;

INSERT INTO SOF_ACTIVITYLOG (IV, CUSTNAME, DATE, USER)
VALUES (:IV, :CUSTNAME, :DATE, SQL.USER);
```

Always check `SQL.RETVAL` (or use explicit `ERRMSG`/`WRNMSG`) after LINK and INSERT. LINK failures are silent otherwise.

### `EXECUTE INTERFACE` in a direct-activation context loses GL values on custom tables

When a directly activated procedure calls `EXECUTE INTERFACE '…', SQL.TMPFILE` targeting a custom (non-system) table, GENERALLOAD values populated before the EXECUTE can be silently dropped. The interface runs but the target custom table ends up with NULLs.

Workaround: use the direct `INSERT` pattern above instead of `EXECUTE INTERFACE` for custom-table targets inside direct activations. For system tables, `EXECUTE INTERFACE` continues to work as expected.

This is observed on custom tables specifically; system tables are unaffected. Verify against a live test before trusting it outside the observed case.
