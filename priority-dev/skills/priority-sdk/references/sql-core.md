# Priority SQL Dialect Reference

Complete reference for the Priority SQL dialect, including system functions, variables, flow control, SQL extensions, execution statements, LINK/UNLINK, return values, and all scalar expressions.

---

## Table of Contents

- [System Functions](#system-functions)
- [Variables](#variables)
  - [Variable Types](#variable-types)
  - [System Variables](#system-variables)
  - [Reserved Words for KEYSTROKES](#reserved-words-for-keystrokes)
- [Flow Control](#flow-control)
  - [Commands](#commands)
  - [Syntax](#syntax)
  - [Cursor with Sub-routine Example](#cursor-with-sub-routine-example)
- [SQL Extensions](#sql-extensions)
  - [Output Formats for SELECT](#output-formats-for-select)
  - [Extended LIKE Patterns](#extended-like-patterns)
  - [Outer Join](#outer-join)
  - [OFFSET and FETCH](#offset-and-fetch)
  - [UPSERT](#upsert)
- [Execution Statements](#execution-statements)
  - [ENV](#env)
  - [EXECUTE](#execute)
- [LINK and UNLINK](#link-and-unlink)
  - [Syntax](#link-syntax)
  - [Behavior](#behavior)
  - [Multiple Links](#multiple-links)
  - [Error Handling](#error-handling)
  - [LINK ALL](#link-all)
- [Return Values](#return-values)
- [Scalar Expressions](#scalar-expressions)
  - [Conditional Expression](#conditional-expression)
  - [Mathematical Expressions](#mathematical-expressions)
  - [Comparison Functions](#comparison-functions)
  - [Numeric Conversion Functions](#numeric-conversion-functions)
  - [String Functions](#string-functions)
  - [Files and Messages](#files-and-messages)
  - [Date Functions](#date-functions)
  - [ATOD and DTOA](#atod-and-dtoa)

---

## System Functions

All system functions use the `SQL.` prefix.

| Function | Type | Description |
|----------|------|-------------|
| `SQL.ENV` | CHAR | Current Priority company |
| `SQL.USER` | INT | Internal number of the current user |
| `SQL.GROUP` | INT | Internal user number of the group representative (privilege inheritance) |
| `SQL.DATE` | DATE | Current date and time |
| `SQL.DATEUTC` | DATE | Current date and time in UTC |
| `SQL.DATE8` | DATE | Current date without time |
| `SQL.TIME` | TIME | Current time |
| `SQL.DAY` | DAY | Current weekday |
| `SQL.LINE` | INT | Line number during retrieval (consecutive numbering) |
| `SQL.TMPFILE` | CHAR | Full path to a temporary file name |
| `SQL.LANGUAGE` | CHAR | Language code of the current user |
| `SQL.ENVLANG` | CHAR | Language defined for the current company |
| `SQL.WEBID` | INT | Identification variable for Priority Lite |
| `SQL.CLIENTID` | CHAR | Identification variable for Priority Lite |
| `SQL.GUID` | CHAR | Random 32-character string (OS UUID function) |
| `SQL.PRETTY` | CHAR | External Access ID in Priority Connect (lowercase for current company, uppercase for other) |
| `SQL.CLOUDURL` | CHAR | Address for Priority Cloud-hosted environment |
| `SQL.REGNAME` | CHAR | System's registration name |
| `SQL.HOSTING` | INT | 1 if hosted in Priority Cloud, 0 otherwise |
| `SQL.ORACLE` | INT | 1 for Oracle database, 2 for SQL Server |

**Examples:**

```sql
/* Numbered list of parts */
SELECT SQL.LINE, PARTNAME FROM PART FORMAT;

/* Check if in cloud */
SELECT SQL.HOSTING FROM DUMMY FORMAT;

/* External Access ID behavior */
SELECT SQL.PRETTY FROM DUMMY FORMAT;
/* In Demo Company (with ID prettydemo): returns prettydemo */
/* In Example Company (no ID): returns PRETTYDEMO */
```

---

## Variables

All variables use the `:` (colon) prefix. Limited to 120 characters.

### Variable Types

| Type | Description |
|------|-------------|
| Form column variables | Content of a given column in a given form (e.g., `:ORDERS.ORDNAME`) |
| Parameter variables | Content of a given parameter in a procedure step |
| User-defined variables | Declared in context |
| System variables | Built-in system variables |

SQL defines the variable type according to context. Variables inherit the type of any other variable or constant in the expression:

```sql
/* :totprice inherits REAL from QUANT and PRICE */
SELECT :ORDERITEMS.QUANT * :ORDERITEMS.PRICE INTO :totprice FROM DUMMY;
/* Or using assignment syntax: */
:totprice = :ORDERITEMS.QUANT * :ORDERITEMS.PRICE;
```

**Default type is CHAR.** Force a specific type without context using the following prefixes:

| Desired Type | Prefix/Initialization |
|-------------|----------------------|
| REAL | `0.0 +` or `:j = 0.0;` |
| INT, DATE, TIME, DAY | `0 +` |
| Single CHAR (width 1) | `'\0' +` or `:SINCHAR = '\0';` |
| REAL with high precision | `:CONV = 0E-9;` |

```sql
/* Force REAL type for undefined variable :j */
SELECT 0.0 + :j FROM DUMMY FORMAT;

/* Initialize high-precision REAL */
:CONV = 0E-9;
```

### System Variables

| Variable | Type | Description |
|----------|------|-------------|
| `:RETVAL` | INT | Return value of the previous query |
| `:SCRLINE` | INT | Current form line (triggers only) |
| `:PAR1`, `:PAR2`, `:PAR3` | CHAR | Parameters for error/warning messages (max 64 chars each) |
| `:PAR4` | CHAR | Value of first argument in CHOOSE- triggers (not supported in web interface) |
| `:FORM_INTERFACE` | INT | 1 = form records filled by form load interface |
| `:FORM_INTERFACE_NAME` | CHAR | Name of the form interface when `:FORM_INTERFACE` = 1; empty if via REST API |
| `:PREFORMQUERY` | INT | Set to 1 in PRE-FORM to run trigger after each query |
| `:ACTIVATEREFRESH` | INT | Set to 1 in PRE-FORM to refresh records after Direct Activation |
| `:ACTIVATE_POST_FORM` | CHAR(1) | Set to `Y` in PRE-FORM to activate POST-FORM trigger on exit even without changes |
| `:KEYSTROKES` | CHAR | String of reserved words imitating keyboard actions (PRE-FORM only) |
| `:HEBREWFILTER` | INT | 0 = Hebrew text appears backwards; 1 = correct order. **Warning:** Reorders entire output line including non-Hebrew characters. Do not use when building structured text files (JSON, XML) — it will corrupt the structure. |
| `:HTMLACTION` | CHAR | Used in Priority Lite procedures |
| `:HTMLVALUE` | CHAR | Used in Priority Lite procedures |
| `:HTMLFIELD` | CHAR | Used in Priority Lite procedures |
| `:_IPHONE` | INT | 1 = mobile device; 0 = PC/iPad |
| `:NOHTMLDESIGN` | INT | 1 = reports produced in non-HTML format |
| `:HTMLMAXROWS` | INT | Limits number of results in processed reports/Priority Lite |
| `:_CHANGECOUNT` | INT | Number of revised fields in current form record (visible fields only) |
| `:PRINTFORMAT` | INT | Print format chosen by user (stored in EXTMSG table) |
| `:SENDOPTION` | CHAR | User's selection in Print/Send Options dialog |
| `:ISSENDPDF` | INT | 1 = create PDF instead of HTML |
| `:WANTSEDOCUMENT` | INT | User's selection for digitally signed emails |
| `:EDOCUMENT` | INT | 1 = sent e-documents synced with Priority as customer task |
| `:GROUPPAGEBREAK` | INT | 1 = page break for first Group By set in processed reports |
| `:FIRSTLINESFILL` | INT | Auto-set to 1 entering sub-level; 0 after user query |
| `:SQL.NET` | INT | 0 = Windows interface; 1 = web interface |
| `:EXTERNAL.VARNAME` | CHAR | Variables from WINACTIV command (always CHAR type) |
| `:WEBSDK_APP_ID` | CHAR | Application ID for Web SDK per-application license |
| `:WEBSDK_APP_NAME` | CHAR | Application name from Web SDK login |
| `:FROMTTS` | INT | 1 = running via Tabula Task Scheduler; 0 otherwise |
| `:NETDEFS_WCFURL` | CHAR | WCF URL of application server (procedures only) |
| `:NETDEFS_SERVERURL` | CHAR | Server URL of application server (procedures only) |
| `:NETDEFS_MARKETGATEURL` | CHAR | Marketgate URL (procedures only) |
| `:NETDEFS_SESSIONDIRECTORY` | CHAR | Session data location (procedures only) |
| `:NETDEFS_SYSTEMIMAGES` | CHAR | Image storage location (procedures only) |
| `:NETDEFS_SYSTEMMAIL` | CHAR | Mail file storage location (procedures only) |
| `:NETDEFS_TMPDIRECTORY` | CHAR | Temp file storage location (procedures only) |
| `:NETDEFS_TMPURL` | CHAR | TMPURL of application server (procedures only) |
| `:NETDEFS_NETTABINI` | CHAR | Location of tabula.ini file (procedures only) |

<!-- ADDED START -->
### Common Issues and Solutions

**Reliability of `:SQL.NET` in Nested Contexts**
The `:SQL.NET` variable may return `0` (Windows interface) even when running in a Web/REST API environment if it is accessed within a sub-procedure or a procedure triggered via `ACTIVATE`/`ACTIVATF` from a form trigger. 
*   **Impact:** This can cause validation failures in logic that depends on detecting the Web interface (e.g., credit card clearing or UI-specific flows).
*   **Workaround:** Avoid relying on `:SQL.NET` for critical logic inside nested procedures. For specific cases like credit card processing (`ISRACARDSALE`), call the underlying program logic directly with required parameters instead of using the standard procedure wrapper.

**Field Tracking with `:_CHANGECOUNT`**
The `:_CHANGECOUNT` variable tracks the number of modified fields in the current record, but its behavior depends on column visibility:
*   It **includes** columns open for update and base table columns exposed as read-only.
*   It **excludes** hidden columns.
```sql
/* Example: Check if any visible fields were modified before proceeding */
SELECT 'No changes made' FROM DUMMY WHERE :_CHANGECOUNT = 0;
```

**Identifying the Current Execution Context**
There is currently no native system variable that returns the name of the currently running procedure (the execution context). 
*   **Workaround:** Developers often query the `EXEC` table, though this is not fully dynamic.
```sql
/* Current approach to find procedure details */
SELECT EXEC, DES FROM EXEC WHERE ENAME = 'MY_PROC_NAME' FORMAT;
```
<!-- ADDED END -->
### Reserved Words for KEYSTROKES

Use `:KEYSTROKES` only in **PRE-FORM triggers**.

| Keyword | Action |
|---------|--------|
| `{Activate}N` | Run the form's Nth Action |
| `{Exit}` | Execute the query |
| `{Key Right}`, `{Key Left}`, `{Key Up}`, `{Key Down}` | Navigation keys |
| `{Page Up}`, `{Page Down}` | Page navigation |
| `{Sub-level}N` | Open the form's Nth sub-level form |
| `{Table/Line View}` | Toggle between multi-record and full-record display |

**Examples:**

```sql
/* Retrieve all form records */
KEYSTROKES = *{Exit};

/* Move right one column, enter date, execute query */
KEYSTROKES = {Key Right} 01/01/06 {Exit};
```

<!-- ADDED START -->
### Common Issues and Solutions

**Web Interface Compatibility**
*   **Problem:** KEYSTROKES commands (such as navigation keys, `{Sub-level}`, or `{Default Form}`) do not function in the Priority Web/Cloud interface, even if they work in the Windows Client.
*   **Solution:** The Web interface only supports the specific command to retrieve all records (`*{Exit}`). For other automation needs in the Web interface, avoid cursor-based navigation; instead, use **Form Interfaces** triggered by `POST-INSERT` or `POST-UPDATE` to handle data entry and record creation automatically.
*   **Code:**
```sql
/* The only KEYSTROKES command supported in Web/Cloud */
:KEYSTROKES = '*{Exit}';
```

**Automatically Querying Records on Form Load**
*   **Problem:** You need a form (e.g., a custom error log or message form) to automatically display all records as soon as it is opened.
*   **Solution:** Use the `{Query}` keyword followed by a wildcard and the `{Exit}` command in a `PRE-FORM` trigger.
*   **Code:**
```sql
/* Initiates a search for all records and executes it immediately */
:KEYSTROKES = '{Query}*{Exit}';
```
<!-- ADDED END -->
## Flow Control

### Commands

| Command | Description |
|---------|-------------|
| `GOTO` | Jump forward to a label when successful |
| `LOOP` | Jump backward to a label when successful |
| `LABEL` | Mark a position for GOTO/LOOP |
| `SLEEP` | Pause for N seconds |
| `GOSUB` | Jump to a sub-routine (IDs 1-999999) |
| `SUB` | Beginning of a sub-routine |
| `RETURN` | End of sub-routine, continues after GOSUB |
| `END` | Discontinue execution |
| `ERRMSG` | Cause failure and print error message |
| `WRNMSG` | Print warning message |
| `REFRESH` | Refresh screen with updated values (form triggers only) |
| `MAILMSG` | Send internal/external mail message |

> **Constructs that do NOT exist in Priority SQLI — each produces a parse error:**
>
> | Standard SQL / PL-SQL construct | Priority SQLI equivalent |
> |---------------------------------|--------------------------|
> | `WHILE cond LOOP ... END LOOP` | `LABEL N; ... LOOP N WHERE cond;` |
> | `IF cond THEN ... END IF` | `GOTO skip WHERE NOT cond; ... LABEL skip;` |
> | `IF/ELSIF/ELSE` | Nested GOTO/LABEL chains or ternary `(cond ? a : b)` |
> | `FOR i IN 1..N LOOP` | DECLARE cursor over a generated range + FETCH loop |
>
> The ternary expression `(condition ? value_if_true : value_if_false)` is the
> only inline conditional. All branching beyond that uses GOTO/LOOP/LABEL with
> optional WHERE clauses.
>
> *(verified: WHILE and IF each produce a parse error; LABEL/LOOP construct works correctly)*

### Syntax

```sql
GOTO label_number [ WHERE condition ];

LOOP label_number [ WHERE condition ];

LABEL label_number;

SLEEP number_of_seconds;

GOSUB sub_number [ WHERE condition ];

SUB sub_number;

RETURN;

END [ WHERE condition ];

ERRMSG msg_number [ WHERE condition ];

WRNMSG msg_number [ WHERE condition ];

REFRESH 1;

MAILMSG msg_number TO { USER | GROUP | EMAIL } 'recipient'
  [ DATA 'attachment_filename' ] [ WHERE condition ];
```

**MAILMSG notes:**
- Subject and content come from the specified message number.
- The file in `DATA` is included as an attachment.
- To send HTML-based email: use an empty message number and specify an HTML file in `DATA`.
- The HTML attachment must be Unicode-compliant on Unicode installations.
- If `:_REPLYTOEMAIL` is set, it overrides the default reply-to address (only when external mail is set up without Outlook).

**WRNMSG note:** In step queries, WRNMSG does not necessarily delay procedure execution in the web interface. Use the `CONTINUE` basic command for guaranteed interruption.

### Cursor with Sub-routine Example

```sql
DECLARE C CURSOR FOR ...
OPEN C;
GOTO 9 WHERE :RETVAL = 0; /* Open failed; no record meets condition */
LABEL 1;
FETCH C INTO ...
GOTO 8 WHERE :RETVAL = 0; /* No more fetched records */
/* Database manipulations with fetched fields;
   usually updates of some sort */
GOSUB 100 WHERE ...;
LOOP 1;
LABEL 8;
CLOSE C;
LABEL 9;
END;

SUB 100;
/* More database manipulations with fetched fields */
RETURN;
```

**Sub-routine notes:**
- `SUB` marks the beginning; `RETURN` marks the end.
- Sub-routines execute only when called by the matching `GOSUB`.
- `GOSUB 1` calls `SUB 1`, `GOSUB 2` calls `SUB 2`, etc.
- Define sub-routines at the beginning or end of the text.
- ID range: 1 to 999,999.

---

## SQL Extensions

### Output Formats for SELECT

Add an output format command at the end of a SELECT statement to produce output.

| Format | Description |
|--------|-------------|
| `FORMAT` | Column headings and data |
| `TABS` | Tab-separated data with column titles at start of each record, line feed at end |
| `DATA` | File structure info (as `#` comments) plus data; for exporting to external databases |
| `ASCII` | Data only, no headings, no spaces between columns |
| `SQLSERVER` | Same as TABS but without column titles |
| `ORACLE` | File for sqlldr (Oracle SQL Loader) |
| `UNICODE` | Output in UTF-16 format (for special characters) |
| `ADDTO` | Append data to end of file instead of replacing |

**Syntax:**
```sql
SELECT ... [ { FORMAT | TABS | DATA | ASCII | SQLSERVER | ORACLE } [UNICODE]
  [ ADDTO ] [ 'filename' ] ];
```

If a filename is specified (in single quotes), output goes to file; otherwise to standard output.

**Note:** To suppress titles with TABS, initialize `:NOTABSTITLE = 1` before executing.

**Filename can be an expression:**
```sql
SELECT * FROM PART
WHERE PART > 0
FORMAT STRCAT('/tmp/', 'part.sav');
```

<!-- ADDED START -->
### Common Issues and Solutions

**Truncated Column Headers in TABS Format**
When using the `TABS` format with column aliases (`AS`), be aware that the system may impose a character limit on headers. In some versions, headers are truncated after 21 characters.
```sql
/* The header 'ReceiverContactPhoneNumber' may be truncated */
SELECT SHIPTO.PHONENUM AS 'ReceiverContactPhoneNumber'
FROM SHIPTO
TABS 'output.txt';
```

**Appending Data to CSV/Delimited Files**
To append query results to an existing file (such as a CSV) instead of overwriting it, use the `ADDTO` keyword before the file path.
```sql
SELECT * FROM MY_TABLE
TABS ADDTO 'C:\TEMP\RESULT.CSV';
```

**Encoding Variations (UTF-8 vs. ANSI)**
By default, simple SQL queries may export in different encodings (UTF-8 vs. ANSI) depending on the complexity of the query or the presence of filters. If specific encoding is required for special characters, ensure the `UNICODE` keyword is explicitly used to force UTF-16 output.
<!-- ADDED END -->
### Extended LIKE Patterns

In addition to standard `_` (single char) and `%` (unlimited chars):

| Pattern | Description |
|---------|-------------|
| `\| A-D \|%` | Any character in range A-D followed by anything |
| `\| \^A-D \|%` | Any character NOT in range A-D followed by anything |
| `\` (backslash) | Escape to match literal special characters (e.g., `A\%` matches `A%`) |

**Important:** LIKE expressions must appear on a single line.

**Correct:**
```sql
WHERE (PARTNAME LIKE '%' OR PART.PARTDES LIKE '%'
OR EPARTDES LIKE '%')
```

**Incorrect:**
```sql
WHERE (PARTNAME LIKE '%' OR PART.PARTDES
LIKE '%' OR EPARTDES LIKE
'%')
```

### Outer Join

Represent an outer join with `?` after the table ID:

```sql
SELECT ... FROM FNCITEMS, FNCITEMSB ?
WHERE FNCITEMSB.FNCTRANS = FNCITEMS.FNCTRANS
AND FNCITEMSB.KLINE = FNCITEMS.KLINE;
```

An outer join preserves unmatched rows. If no join record exists, a null record is retrieved and the query succeeds.

### OFFSET and FETCH

Use for paging results. Requires `ORDER BY`.

**OFFSET only:**
```sql
:FR = 100;
SELECT ORD, ORDNAME FROM ORDERS WHERE CURDATE > 01/01/19
ORDER BY 1
OFFSET :FR
FORMAT;
```
Returns results starting from row 101.

**OFFSET with FETCH:**
```sql
:FR = 100;
:MAX = 75;
SELECT ORD, ORDNAME FROM ORDERS WHERE CURDATE > 01/01/19
ORDER BY 1
OFFSET :FR FETCH NEXT :MAX ROWS ONLY
FORMAT;
```
Returns max 75 rows starting from row 101.

### UPSERT

Available from version 25.1. Combines UPDATE with a fallback INSERT. If UPDATE fails (no matching record), INSERT executes.

**Syntax:**
```sql
UPSERT table_name
SET column1 = value1,
column2 = value2
WHERE condition;
```

**Example:**
```sql
UPSERT LASTS
SET NAME = 'FOO',
VALUE = 123
WHERE NAME = 'FOO'
;
```

This is equivalent to:
```sql
UPDATE LASTS
SET VALUE = 123
WHERE NAME = 'FOO'
;
GOTO 1 WHERE :RETVAL > 0;
INSERT INTO LASTS(NAME, VALUE)
VALUES('FOO', 123)
;
LABEL 1;
```

**Important:** The UPSERT SET must include values for both UPDATE and INSERT (the WHERE column must also appear in SET).

**Unique Key Concerns:** UPSERT always includes a change to the unique key (for the INSERT fallback). Always use the unique key in the WHERE clause to avoid inconsistent results.

**Problematic example (avoid):**
```sql
UPSERT LASTS
SET NAME = 'FOO',
VALUE = 123;
/* No WHERE clause -- could update wrong record or insert duplicate */
```

**Best use case:** Semaphore values (LASTS table, custom constants) -- values expected to exist but need generation on first run.

---

## Execution Statements

### ENV

Change the current Priority company:

```sql
ENV company;
```

Where `company` is a string or variable (the value from the Company column of the Companies form).

**Web interface limitation:** When used in a procedure, opening a form from within the procedure still opens in the original company.

### EXECUTE

Execute a specified program with parameters. Mainly used in form triggers and SQLI steps.

```sql
EXECUTE [BACKGROUND] program [ parameter, ... ];
```

- `program` and each parameter can be a string or variable.
- Separate parameters with commas; enclose strings in apostrophes.
- Execution occurs in the present company.
- `BACKGROUND` runs the program in the background.

---

## LINK and UNLINK

### Purpose

The LINK mechanism creates a temporary copy of a database table for:
- A parameter comprised of a batch of records
- A work area for data manipulation prior to report output
- Form load interfaces

### Link Syntax

```sql
LINK table_name1 [ ID ] [ TO filename1 ];
{ database manipulations }
UNLINK [AND REMOVE] table_name1 [ID];
```

### Behavior

- `LINK` ties a table to a temporary file with identical structure (all columns and keys).
- If the linked file does not exist, it is created; if it exists, the linkage is executed.
- The linked file is initially **empty**.
- All subsequent operations on the table execute on the temporary file until `UNLINK`.
- `UNLINK` stores the temporary file and undoes the link.
- `UNLINK AND REMOVE` deletes the linked file when unlinking (important for loops).

### Multiple Links

Linking the same table twice before UNLINK returns -1. Use different suffixes:

```sql
LINK ORDERS A ...;
LINK ORDERS B ...;

/* Now you can: */
INSERT INTO ORDERS A
SELECT * FROM ORDERS B
WHERE ...;
```

### Error Handling

**If LINK fails and an INSERT/UPDATE targets the "linked" table, the operation executes on the real table.**

Always check with ERRMSG or GOTO:

**Method 1: ERRMSG**
```sql
SELECT SQL.TMPFILE INTO :TMPFILE;
LINK ORDERS TO :TMPFILE;
ERRMSG 1 WHERE :RETVAL <= 0;
/* database manipulation on temporary ORDERS table */
UNLINK ORDERS;
```

**Method 2: GOTO**
```sql
SELECT SQL.TMPFILE INTO :TMPFILE;
LINK ORDERS TO :TMPFILE;
GOTO 99 WHERE :RETVAL <= 0;
/* database manipulation on temporary ORDERS table */
UNLINK ORDERS;
LABEL 99;
```

### LINK ALL

Shorthand for linking a table and inserting all records from the original:

```sql
SELECT SQL.TMPFILE INTO :TMPFILE;
LINK ALL ORDERS TO :TMPFILE;
GOTO 99 WHERE :RETVAL <= 0;
/* database manipulation on temporary ORDERS table */
UNLINK ORDERS;
LABEL 99;
```

**Equivalent to:**
```sql
SELECT SQL.TMPFILE INTO :TMPFILE;
LINK ORDERS TO :TMPFILE;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG
WHERE ORIG.ORD <> 0;
/* database manipulation on temporary ORDERS table */
UNLINK ORDERS;
LABEL 99;
```

Use sparingly -- rarely is the entire table population needed. Being specific improves performance.

---

## Return Values

| Command | Return Values | Failure When |
|---------|--------------|--------------|
| `DECLARE` | 1 (success) | Never fails |
| `OPEN` | Number of records; 0 on failure | Too many open cursors (>100) including recursive opens; no selected records |
| `CLOSE` | 1 on success; 0 on failure | Cursor is not open |
| `FETCH` | 1 if fetched; 0 if end of cursor | Cursor not open; no more records |
| `SELECT` | Number of selected records; 0 on failure | No record met WHERE condition |
| `SELECT ... INTO` | 1 on success; 0 on failure | No record met WHERE condition |
| `INSERT ... SELECT` | Number of inserted records; -1 if no record meets WHERE | No record met WHERE; selected records but none inserted (unique key constraint or insufficient privileges) |
| `INSERT VALUES` | 1 on success; 0 on failure | Failed to insert |
| `UPDATE ... WHERE CURRENT OF` | 1 on success; 0 on failure | Cursor not open; no more records; record exists but not updated |
| `UPDATE` | Number of updated records; 0 on failure; -1 if no record meets WHERE | No record met WHERE; selected records but none updated (unique key constraint or insufficient privileges) |
| `DELETE ... WHERE CURRENT OF` | 1 on success; 0 on failure | Cursor not open; no more records; record exists but not deleted |
| `DELETE` | Number of deleted records; 0 on failure; -1 if no record meets WHERE | No record met WHERE; selected records but none deleted (unique key constraint or insufficient privileges) |
| `RUN` | Returns what the query returns | -- |
| `ENV` | 1 on success; 0 on failure | -- |
| `EXECUTE` | PID of child process | -- |
| `LINK` | 2 if new file created; 1 if linked to existing file; 0 on failure; -1 if duplicate link to same table name | -- |
| `UNLINK` | 1 on success; 0 on failure | -- |
| `GOTO` | -- | No such label found forwards |
| `LOOP` | -- | No such label found backwards |
| `LABEL` | -- | Never fails |
| `END` | -- | Never fails |

---

## Scalar Expressions

### Conditional Expression

Syntax (following C language `? :` notation):

```
( expression ? expression_if_true : expression_if_false )
```

**Example:** Calculated column warning that order is overdue:
```sql
( SQL.DATE8 > ORDERITEMS.DUEDATE AND ORDERITEMS.BALANCE > 0 ? '*' : ' ' )
```

### Mathematical Expressions

#### ROUND(m)
Round a real number to the nearest integer; result treated as **integer**.
```sql
SELECT ROUND(1.45) FROM DUMMY FORMAT; /* 1 */
```

#### ROUNDR(m)
Round a real number to the nearest integer; result treated as **real number**.
```sql
SELECT ROUNDR(1.45) FROM DUMMY FORMAT; /* 1.000000 */
```

#### EXP(m, n)
Exponentiation where both m and n must be **integers** (type INT).
```sql
SELECT EXP(3,2) FROM DUMMY FORMAT; /* 9 */
SELECT EXP(2,3) FROM DUMMY FORMAT; /* 8 */
```

#### POW(m, n)
Exponentiation where m and n must be **real** numbers (type REAL).
```sql
SELECT POW(3.1,-2.4) FROM DUMMY FORMAT; /* 0.066181 */
```

#### SQRT(m)
Square root rounded to nearest integer (m is integer).
```sql
SELECT SQRT(10) FROM DUMMY FORMAT; /* 3 */
```

#### SQRTR(m)
Square root of a real number.
```sql
SELECT SQRTR(10.0) FROM DUMMY FORMAT; /* 3.162278 */
```

#### ABS(m)
Absolute value of an integer.
```sql
SELECT ABS(-5) FROM DUMMY FORMAT; /* 5 */
```

#### ABSR(m)
Absolute value of a real number.
```sql
SELECT ABSR(-5.3) FROM DUMMY FORMAT; /* 5.300000 */
```

#### n MOD m
Modular arithmetic.
```sql
SELECT 10 MOD 4 FROM DUMMY FORMAT; /* 2 */
```

MOD can also retrieve time from DATE 14:
```sql
SELECT 17/05/09 12:25 MOD 24:00 FROM DUMMY FORMAT; /* 12:25 */
```

### Comparison Functions

#### MINOP(m, n)
Return the minimum of two numbers.
```sql
SELECT MINOP(1.5,2) FROM DUMMY FORMAT; /* 1.500000 */
```

#### MAXOP(m, n)
Return the maximum of two numbers.
```sql
SELECT MAXOP(1.5,2) FROM DUMMY FORMAT; /* 2.000000 */
```

### Numeric Conversion Functions

#### REALQUANT(m)
Convert a shifted integer to a real number. The decimal point moves by the `DECIMAL` system constant (usually 3).
```sql
:ORDERITEMS.TQUANT = 1000;
SELECT REALQUANT(:ORDERITEMS.TQUANT) FROM DUMMY FORMAT;
/* 1.000000 assuming Decimal constant = 3 */
```

#### INTQUANT(m)
Convert a real number to a shifted integer.
```sql
SELECT INTQUANT(1.0) FROM DUMMY FORMAT;
/* 1000 assuming Decimal constant = 3 */
```

#### ITOH(m)
Convert an integer to a hexadecimal string.
```sql
SELECT ITOH(10) FROM DUMMY FORMAT; /* a */
```

#### HTOI(STRING 'M')
Convert a hexadecimal string to an integer.
```sql
SELECT HTOI('2f4') FROM DUMMY FORMAT; /* 756 */
```

### String Functions

#### Conversions

##### ITOA(m, n)
Convert an integer to a string with n characters (leading zeroes added). If n is omitted or less than needed, minimum width is used.
```sql
SELECT ITOA(35,4) FROM DUMMY FORMAT; /* '0035' */
SELECT ITOA(35) FROM DUMMY FORMAT;   /* '35' */
```

##### ATOI(string)
Convert a string to an integer (max 10 characters).
```sql
SELECT ATOI('35') FROM DUMMY FORMAT; /* 35 */
```

##### ATOR(string)
Convert a string to a real number (max 14 characters).
```sql
SELECT ATOR('109012.99') FROM DUMMY FORMAT; /* 109012.990000 */
```

##### RTOA(m, n, USECOMMA)
Convert a real number to a string with n decimal places. `USECOMMA` adds thousands separator based on current language.
```sql
SELECT RTOA(150654.665,2,USECOMMA) FROM DUMMY FORMAT;
/* '150.654,67' assuming decimal format 1.234,56 */

SELECT RTOA(150654.665,2) FROM DUMMY FORMAT;
/* '150654.67' assuming decimal format 1,234.56 */

SELECT RTOA(3.665432,2) FROM DUMMY FORMAT; /* '3.67' */
```

#### String Information

##### STRLEN(string)
Return string length (integer).
```sql
SELECT STRLEN('Priority') FROM DUMMY FORMAT; /* 8 */
```

> **Functions that do NOT exist in Priority SQLI — use these equivalents instead:**
>
> | Function developers expect | Priority SQLI equivalent |
> |---------------------------|--------------------------|
> | `LENGTH(string)` | `STRLEN(string)` |
> | `ASCII(char)` | No direct equivalent — use integer math or `DTOA` for display |
> | `CHARINDEX(sub, str)` | `STRINDEX(str, sub, 1)` |
> | `ISNULL(x, y)` | `(x = '' ? y : x)` for CHAR; `(x = 0 ? y : x)` for INT |
>
> Note: `DAYOFWEEK(date)` is documented separately in the Date Functions section.
> On Hebrew installs, `DTOA(date, 'day')` returns the Hebrew weekday abbreviation
> letter (e.g., 'א' for Sunday). Prefer integer day-of-week arithmetic via `DAY()`
> to avoid RTL source-code issues.
>
> *(verified: LENGTH and ASCII each produce a parse error; STRLEN and STRINDEX work correctly)*

##### ISALPHA(string)
Test if a string begins with a letter and contains only letters, digits, and underscores. Returns 1 or 0.
```sql
SELECT ISALPHA('Priority_21') FROM DUMMY FORMAT; /* 1 */
SELECT ISALPHA('21Priority') FROM DUMMY FORMAT; /* 0 */
```

##### ISPREFIX(string1, string2)
Test if string1 is a prefix of string2. Returns 1 or 0.
```sql
SELECT ISPREFIX('HEEE','HEEE_ORDERS') FROM DUMMY FORMAT; /* 1 */
SELECT ISPREFIX('HEEWE','HEEE_ORDERS') FROM DUMMY FORMAT; /* 0 */
```

##### ISNUMERIC(string)
Test if a string contains only digits. Returns 1 or 0.
```sql
SELECT ISNUMERIC('07666') FROM DUMMY FORMAT; /* 1 */
SELECT ISNUMERIC('14.5') FROM DUMMY FORMAT;  /* 0 */
```

##### ISFLOAT(string)
Test if a string is a real number. Returns 1 or 0.
```sql
SELECT ISFLOAT('14.5') FROM DUMMY FORMAT; /* 1 */
```

##### STRINDEX(full_string, search_string, index)
Return the position of search_string in full_string, starting from index. Returns 0 if not found. Use -1 for reverse search.
```sql
:STR = 'hello world this is my string';
:SUBSTR = 'is';

:INDEX = 1;
SELECT STRINDEX(:STR, :SUBSTR, :INDEX) FROM DUMMY FORMAT; /* 15 */

:INDEX = -1;
SELECT STRINDEX(:STR, :SUBSTR, :INDEX) FROM DUMMY FORMAT; /* 18 */
```

Usage in queries:
```sql
:FDT = BEGINOFYEAR(SQL.DATE);
SELECT CUSTNAME, CUSTDES, CREATEDDATE
FROM CUSTOMERS
WHERE CREATEDDATE > :FDT
AND STRINDEX(CUSTNAME, '073', 1) > 0
FORMAT;
```

#### String Manipulation

##### STRCAT(string1, string2, ...)
Concatenate strings. Result limited to 127 characters.
```sql
SELECT STRCAT('abc','ba') FROM DUMMY FORMAT; /* 'abcba' */
```

##### STRIND(string, m, n)
From position m, retrieve n characters (fixed values).
```sql
SELECT STRIND('Priority',3,2) FROM DUMMY FORMAT; /* 'io' */
```

##### SUBSTR(string, m, n)
From position m, retrieve n characters (variables or fixed values).
```sql
:STR = 'Priority';
:I = 3;
:T = 2;
SELECT SUBSTR(:STR, :I, :T) FROM DUMMY FORMAT; /* 'io' */
SELECT SUBSTR('Priority',3,2) FROM DUMMY FORMAT; /* 'io' */
```

##### RSTRIND(string, m, n)
Same as STRIND, but read right to left.
```sql
SELECT RSTRIND('Priority',3,2) FROM DUMMY FORMAT; /* 'ri' */
```

**Note:** STRIND and RSTRIND behave differently with variables in SELECT from real tables. **Always use SUBSTR and RSUBSTR instead.**

##### RSUBSTR(string, m, n)
Same as SUBSTR, but read right to left.
```sql
:STR = 'Priority';
:I = 3;
:T = 2;
SELECT RSUBSTR(:STR, :I, :T) FROM DUMMY FORMAT; /* 'ri' */
SELECT RSUBSTR('Priority',3,2) FROM DUMMY FORMAT; /* 'ri' */
```

##### STRPREFIX(string, n)
Retrieve the first n characters (n is fixed value).
```sql
SELECT STRPREFIX('Priority',2) FROM DUMMY FORMAT; /* 'Pr' */
```

##### STRPIECE(string, delimiter, m, n)
For a string split by delimiter, retrieve n parts starting from part m. Delimiter must be a single fixed character.
```sql
SELECT STRPIECE('a/b.c.d/e.f','.',2,1) FROM DUMMY FORMAT;  /* 'c' */
SELECT STRPIECE('a/b.c.d/e.f','/',2,1) FROM DUMMY FORMAT;  /* 'b.c.d' */
SELECT STRPIECE('a/b.c.d/e.f','.',1,3) FROM DUMMY FORMAT;  /* 'a/b.c.d/e' */
SELECT STRPIECE('a/b.c.d/e.f','/',1,3) FROM DUMMY FORMAT;  /* 'a/b.c.d/e.f' */
```

##### TOUPPER(string)
Convert to uppercase.
```sql
:LOW = 'marianne';
SELECT TOUPPER(:LOW) FROM DUMMY FORMAT; /* MARIANNE */
```

##### TOLOWER(string)
Convert to lowercase.
```sql
:UPPER = 'MARIANNE';
SELECT TOLOWER(:UPPER) FROM DUMMY FORMAT; /* marianne */
```

### Files and Messages

#### ENTMESSAGE(entity_name, entity_type, message_number)
Return the message text for a given entity. Must run against the DUMMY table. Store in a variable first if needed in other queries.

```sql
SELECT ENTMESSAGE('ORDERS','F',3) FROM DUMMY FORMAT;
/* You cannot revise the number of an itemized order. */

/* Better practice - assign to variable */
:MSG = ENTMESSAGE('ORDERS','F',3);

/* In procedures, use '$' as alias for current procedure */
:MSG = ENTMESSAGE('$','P',3);
/* equivalent to: */
:MSG = ENTMESSAGE('COPYORDER','P',3);
```

**Note:** For forms, always specify the full form name.

#### SYSPATH(folder_type, path_output_type)
Return the path for a system folder.

| Folder Type | Description |
|------------|-------------|
| `BIN` | Binaries |
| `PREP` | Prep folder |
| `LOAD` | Load folder |
| `MAIL` | Mail folder |
| `SYS` | System folder |
| `TMP` | Temp folder |
| `SYNC` | Sync folder (public cloud only) |
| `IMAGE` | Image folder |

| Path Output Type | Description |
|-----------------|-------------|
| 1 | Relative path |
| 0 | Absolute path |

```sql
SELECT SYSPATH('MAIL', 1) FROM DUMMY; /* ../../system/mail */
SELECT SYSPATH('MAIL', 0) FROM DUMMY; /* P:/system/mail/ */
```

**Note:** In Windows, the TMP folder location can change between users.

#### NEWATTACH('filename', ['extension']) (22.0+)
Create a valid file location in the system/mail folder and return it. Handles filename conflicts by adding a number suffix. Filename is converted to lowercase.

In version 22.1+, the function also creates the folder on the server.

```sql
:z = NEWATTACH('LOGFILe', '.zip');
SELECT :z FROM DUMMY FORMAT;
/* ../../system/mail/202202/1t2tymq0/logfile.m */

SELECT NEWATTACH('LOGFILe', '.zip') FROM DUMMY FORMAT;
SELECT NEWATTACH('C:\TMP\LOGFILe', '.zip') FROM DUMMY FORMAT;
SELECT NEWATTACH('C:\TMP\LOGFILe.zip') FROM CUSTOMERS WHERE CUST = 0 FORMAT;
```

**Note:** The extension parameter should include the dot (e.g., `'.zip'` not `'zip'`). If filename and extension are a single string, use `STRPIECE` with `.` delimiter to split.

### Date Functions

Dates, times, and days are stored as integers. Dates display in American (MMDDYY) or European (DDMMYY) format depending on the language setting.

> **Date arithmetic — use `+24:00` to advance by one day, not `+1`.**
> The internal unit is one minute, so adding `1` advances by one minute, not one day.
>
> ```sql
> /* WRONG — :D advances by 1 minute, not 1 day */
> :D = :D + 1;
> /* CORRECT — advances by exactly 1 day */
> :D = :D + 24:00;
> /* Multi-day steps */
> :D = :D + 72:00;   /* +3 days */
> :D = :D + 168:00;  /* +7 days (1 week) */
> ```
>
> This applies in date-stepping loops, expiry calculations, and any arithmetic
> on DATE-type variables or columns. The `MOD 24:00` pattern (Mathematical
> Expressions section) extracts the time component from a DATE14 value.
>
> *(verified: `01/05/26 + 1` = `01/05/26 00:01`; `01/05/26 + 24:00` = `02/05/26`)*

#### Date Parsing

##### DAY(date)
Return the number of the weekday (Sun=1, Mon=2, ...).
```sql
SELECT DAY(03/22/06) FROM DUMMY FORMAT; /* 4 */
```
Use the `DAYS` table (English) or `LANGDAYS` table (other languages) to get weekday names.

> **Note:** `DAYOFWEEK(date)` does NOT exist in Priority SQLI and produces a parse error. Use `DAY(date)` instead (returns Sun=1 ... Sat=7).

##### MDAY(date)
Return the day number in the month.
```sql
SELECT MDAY(03/22/06) FROM DUMMY FORMAT; /* 22 */
```

##### WEEK(date)
Return an integer: last digits of year + week number (2 digits).
```sql
SELECT WEEK(03/22/06) FROM DUMMY FORMAT; /* 612 */
```

##### WEEK6(date)
Return an integer: 4-digit year + week number (2 digits).
```sql
SELECT WEEK6(03/22/06) FROM DUMMY FORMAT; /* 200612 */
```

##### MWEEK(week)
Given a YYWW value, return the month number.
```sql
SELECT MWEEK(0612) FROM DUMMY FORMAT; /* 3 */
```

##### MONTH(date)
Return the month number in the year.
```sql
SELECT MONTH(03/22/06) FROM DUMMY FORMAT; /* 3 */
```

##### QUARTER(date)
Return a string: quarter + four-digit year.
```sql
SELECT QUARTER(09/22/06) FROM DUMMY FORMAT; /* 3Q-2006 */
```

##### YEAR(date)
Return the four-digit year as an integer.
```sql
SELECT YEAR(03/22/06) FROM DUMMY FORMAT; /* 2006 */
```

##### TIMELOCAL(date)
Return the number of seconds from January 1, 1970 to the specified date.
```sql
SELECT TIMELOCAL(05/04/06) FROM DUMMY FORMAT; /* 1146693600 */
```

##### CTIME(int)
Return the date corresponding to seconds since January 1, 1970 02:00.
```sql
SELECT CTIME(1146693600) FROM DUMMY FORMAT;
/* Thu May 04 01:00:00 2006 */
```

#### Calculated Dates

##### BEGINOFWEEK(date in YYWW format)
```sql
SELECT BEGINOFWEEK(2220) FROM DUMMY FORMAT; /* 15/05/22 */
```

##### BEGINOFMONTH(date)
Return the first day of the month.
```sql
SELECT BEGINOFMONTH(05/04/06) FROM DUMMY FORMAT; /* 05/01/06 */
```

##### BEGINOFQUARTER(date)
Return the first day of the quarter.
```sql
SELECT BEGINOFQUARTER(05/04/06) FROM DUMMY FORMAT; /* 04/01/06 */
```

##### BEGINOFHALF(date)
Return the first day of the half-year period.
```sql
SELECT BEGINOFHALF(10/22/06) FROM DUMMY FORMAT; /* 07/01/06 */
```

##### BEGINOFYEAR(date)
Return the first day of the year.
```sql
SELECT BEGINOFYEAR(10/22/06) FROM DUMMY FORMAT; /* 01/01/06 */
```

##### ENDOFMONTH(date)
Return the last day of the month.
```sql
SELECT ENDOFMONTH(04/22/06) FROM DUMMY FORMAT; /* 04/30/06 */
```

##### ENDOFQUARTER(date)
Return the last day of the quarter.
```sql
SELECT ENDOFQUARTER(03/22/06) FROM DUMMY FORMAT; /* 03/31/06 */
```

##### ENDOFHALF(date)
Return the last day of the half-year.
```sql
SELECT ENDOFHALF(03/22/06) FROM DUMMY FORMAT; /* 06/30/06 */
```

##### ENDOFYEAR(date)
Return the last day of the year.
```sql
SELECT ENDOFYEAR(03/22/06) FROM DUMMY FORMAT; /* 12/31/06 */
```

### ATOD and DTOA

#### ATOD(date, pattern)
Convert dates, times, and days from strings into internal numbers. Mainly used to import external data.

#### DTOA(date, pattern)
Convert dates, times, and days from internal numbers to ASCII strings. Mainly used to display data.

#### Pattern Components

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `MMM` or `mmm` | Abbreviated month name (3 letters) | Jan |
| `MMMM` or `mmmm` | Full month name | January |
| `MONTH` | Abbreviated month + last 2 digits of year | Jun-06 |
| `MM` | Month number (2 digits) | 01 |
| `DD` | Day in month (2 digits) | 15 |
| `YY` | Last 2 digits of year | 06 |
| `YYYY` | All 4 digits of year | 2006 |
| `day` | Weekday abbreviation | Mon |
| `hh:mm` | Hours and minutes | 12:05 |
| `XX/XX/XX` | Date with 2-digit year (American or European based on language) | 06/01/06 |
| `XX/XX/XXXX` | Date with 4-digit year (American or European based on language) | 06/01/2006 |
| `FULLDATE` | Abbreviated month, date, 4-digit year | Jun 01,2006 |
| `WW` | Week in the year (2 digits) (23.0+) | 03 |

**Notes:**
- Add punctuation (dashes, slashes, commas) and spaces between pattern components as needed.
- `WW` is similar to the `WEEK` function, but `WEEK` returns both year and week (e.g., 0603).

#### ATOD Examples (String to Date)

```sql
SELECT ATOD('06/21/06','MM/DD/YY') FROM DUMMY FORMAT;
/* 06/21/06 (June 21, 2006, American format) */

SELECT ATOD('06/21/2006','MM/DD/YYYY') FROM DUMMY FORMAT;
/* 06/21/06 (June 21, 2006, American format) */

SELECT ATOD('062106','MMDDYY') FROM DUMMY FORMAT;
/* 06/21/06 (June 21, 2006, American format) */

SELECT ATOD('311006','DDMMYY') FROM DUMMY FORMAT;
/* 31/10/06 (October 31, 2006, European format) */

SELECT ATOD('31102006','DDMMYYYY') FROM DUMMY FORMAT;
/* 31/10/06 (October 31, 2006, European format) */
```

#### DTOA Examples (Date to String)

```sql
:DATE = 06/01/06; /* June 1, 2006 */

SELECT DTOA(:DATE,'MMMM') FROM DUMMY FORMAT;       /* June */
SELECT DTOA(:DATE,'MMM') FROM DUMMY FORMAT;         /* Jun */
SELECT DTOA(:DATE,'MM') FROM DUMMY FORMAT;          /* 06 */
SELECT DTOA(:DATE,'MONTH') FROM DUMMY FORMAT;       /* Jun-06 */
SELECT DTOA(:DATE,'day') FROM DUMMY FORMAT;         /* Thu */

SELECT DTOA(06/01/06,'XX/XX/XX') FROM DUMMY FORMAT;
/* 06/01/06 (American) or 01/06/06 (European) */

SELECT DTOA(:DATE,'FULLDATE') AS 'FULLDATE' FROM DUMMY FORMAT;
/* Jun 01,2006 */

:DATE = 06/01/06 12:33;

SELECT DTOA(:DATE,'MM/DD/YY hh:mm,day') FROM DUMMY FORMAT;
/* 06/01/06 12:33,Thu */

SELECT DTOA(:DATE,'MMM-YY') FROM DUMMY FORMAT;        /* Jun-06 */
SELECT DTOA(:DATE,'MMMM-YYYY') FROM DUMMY FORMAT;     /* June-2006 */

SELECT DTOA(:DATE, 'The current date is MM-DD-YY, and the time is hh:mm.')
FROM DUMMY FORMAT;
```

---

## HEBCONV (Hebrew Text Conversion)

The `HEBCONV` utility (`TABULA_HEBCONVERT` / `hebutils` CLR assembly) was used to convert between visual and logical Hebrew text when querying Priority directly via SQL/ODBC.

### Deprecation Notice

**HEBCONV is deprecated and unsupported on SQL Server 2017 and above.** The CLR assembly fails due to security architecture changes in newer SQL Server versions.

- **Error:** The `hebutils` assembly fails to load with CLR security errors.
- **Workaround (not recommended):** Disable CLR strict security:
  ```sql
  EXEC sp_configure 'clr strict security', 0; RECONFIGURE;
  ```
  This is a security risk and not a long-term solution.
- **Recommended alternative:** Migrate to the **REST API** or **Web SDK**, which handle encoding and text direction automatically.
- **For BI integrations:** Replace direct SQL queries using HEBCONV with REST API calls that return properly encoded text. There is no replacement `convert` command for visual-to-logical Hebrew conversion in SQL 2017+.
