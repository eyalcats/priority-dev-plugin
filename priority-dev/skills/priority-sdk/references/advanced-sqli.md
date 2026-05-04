# Advanced SQLI Constructs

Reference for SQLI constructs that go beyond day-to-day triggers/procedures: running procs/reports from SQLI, financial-document hooks, concurrency, dynamic SQL, Word-template binding, and Business Rules wiring.

## Table of Contents

- [Run Procedure/Report from SQLI](#run-procedurereport-from-sqli)
- [Financial Documents](#financial-documents)
- [Open Form Record from Procedure](#open-form-record-from-procedure)
- [Dynamic SQL](#dynamic-sql)
- [Semaphores](#semaphores)
- [Word Templates for Specific Records](#word-templates-for-specific-records)
- [Business Rules Generator](#business-rules-generator)

---

## Run Procedure/Report from SQLI

### Commands Overview

| Command | UI | Process | Use With |
|---|---|---|---|
| WINACTIV | Has user interface (progress bar, messages) | New process | Procedures and Reports. Not for web interface. |
| ACTIVATE | No user interface | New process (.exe) | Procedures only |
| ACTIVATF | No user interface | Same process (.dll) | Procedures only |

All three commands accept linked table parameters: Table Name and linked file.

### Execute a Procedure

```sql
GOTO 10099 WHERE :$.CPROFSTAT <> :SPECIALSTATUS;
SELECT SQL.TMPFILE INTO :FILE FROM DUMMY;
LINK CPROF TO :FILE;
GOTO 10099 WHERE :RETVAL <= 0;
INSERT INTO CPROF
SELECT * FROM CPROF O WHERE PROF = :$.PROF;
UNLINK CPROF;
EXECUTE ACTIVATF '-P', 'OPENORDBYCPROF', 'CPROF', :FILE;
LABEL 10099;
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **Web Interface Compatibility**: When migrating desktop-based SQLI commands, replace `WINACTIV` with `ACTIVATE` to ensure compatibility with the Priority Web interface.
    ```sql
    /* Use this for Web compatibility */
    EXECUTE ACTIVATE '-P', 'MY_PROC';
    ```

*   **Indirect Execution Limitations**: When a procedure is triggered via `EXECUTE ACTIVATF` from within another procedure, certain post-compiled steps (like specific SQLI steps following the main program) may be skipped. If a custom procedure works manually but fails when called indirectly, verify the execution framework logic.
    ```sql
    EXECUTE ACTIVATF '-P', 'PROC_NAME', 'LINK_TABLE', :FILE;
    ```

*   **Background Execution Context**: Procedures executed via the Tabula Task Scheduler (TTS) or the `BACKGROUND` parameter run in a non-interactive server context.
    *   **Printing**: Printing procedures (e.g., check printing) may fail to output to a physical printer if the scheduler context lacks the necessary printer permissions or UI session.
    *   **Email**: Commands initiated from the web interface run on the server. Client-side integrations (like local Outlook) will not work; use SMTP or Office 365 methods instead.
    ```sql
    EXECUTE BACKGROUND ACTIVATF ...
    ```

*   **"Activate: link failed" Errors**: This error often indicates a file system permission issue rather than a syntax error. Ensure the system has appropriate NT permissions on the `System/tmp/COMPUTERNAME` directory, as the procedure needs to write and read temporary link files.

*   **Standard Procedure Syntax**: When calling standard system procedures like `SENDMAIL`, ensure the parameters match the expected version-specific signature.
    ```sql
    /* Example: Executing SENDMAIL from SQLI */
    EXECUTE SENDMAIL 0 + :MAILBOX, :ERR, 4;
    ```

*   **Data Context Errors**: If a procedure adapted from one form to another returns "No data found to send," verify that all required linked tables and temporary files are correctly populated and that the data scope matches the target form's structure.
<!-- ADDED END -->
### Execute a Procedure with Linked Table

The linked table goes to the PAR variable of the procedure, allowing Form Actions without being in the form:

```sql
SELECT SQL.TMPFILE INTO :FILE FROM DUMMY;
LINK ORDERS TO :FILE;
GOTO 10099 WHERE :RETVAL <= 0;
INSERT INTO ORDERS
SELECT * FROM ORDERS O WHERE PROF = :$.PROF;
UNLINK ORDERS;
EXECUTE ACTIVATF '-P', 'OPENINVFORORDER', 'ORDERS', :FILE;
LABEL 10099;
```

### Execute a Procedure with External Variables

All variables are received as CHAR:

```sql
EXECUTE ACTIVATF '-P', 'DEMO_MYPROC', '-var:MODE', 'UPDATE', '-var:QUANT', '500';
```

Refer to them with `EXTERNAL` prefix (convert as needed):

```sql
:DEMO_QUANT = ATOI(:EXTERNAL.QUANT);
GOSUB 100 WHERE :EXTERNAL.MODE = 'UPDATE';
```

### Execute a Report

Reports can only be run by WINACTIV (not for web interface):

```sql
:F = '../../output.txt';
SELECT SQL.TMPFILE INTO :CST FROM DUMMY;
LINK CUSTOMERS TO :CST;
GOTO 299 WHERE :RETVAL <= 0;
INSERT INTO CUSTOMERS
SELECT * FROM CUSTOMERS O
WHERE CUSTNAME = '250';
UNLINK CUSTOMERS;
EXECUTE WINACTIV '-R', 'OPENORDIBYDOER', 'CUSTOMERS', :CST;
LABEL 299;
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Web Interface Compatibility
The `WINACTIV` command is restricted to the Windows client. For customizations intended to run in the Web interface (e.g., triggering a report after a status update or within a procedure), use `ACTIVATE` or `ACTIVATEF`.

#### Redirecting Report Output to a File
You can save a report directly to a file (such as an HTML or Excel format) using the `-o` flag. Note that formatting may vary between environments; ensure the report generator column titles and data types are correctly defined to avoid unformatted text or "garbage" rows in the output.

**Example: Saving a report to a file**
```sql
/* Using ACTIVATE for Web compatibility */
EXECUTE ACTIVATE '-R', 'ZMDV_SUPCERTIFICATE', 'GENERALLOAD', :$.GEN, '-o', :ZMDV_FILE;
```

#### Executing Reports from Procedures
It is possible to trigger a report automatically at the end of a private procedure. This is often used to generate a summary or a document (like a certificate or invoice) immediately after the procedure logic completes.

#### Data Integrity in Linked Tables
When running a report based on a linked temporary table (using `:CST`), ensure the table is populated with valid data before execution. Invalid data types or unexpected values in the linked table can result in extra rows or corrupted output in the generated report.
<!-- ADDED END -->
### Run a Report and Send by E-mail

```sql
SELECT SQL.TMPFILE INTO :TMP FROM DUMMY;
LINK ERRMSGS TO :TMP;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO ERRMSGS
SELECT * FROM ERRMSGS O
WHERE USER = SQL.USER AND TYPE = 'i';
GOTO 90 WHERE :RETVAL <= 0;

/* Send to a Priority mail recipient */
:MAILER = SQL.USER;
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-u', :MAILER;

/* Send to a Priority group */
:GROUPNAME = 'mailGroup';
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-g', :GROUPNAME;

/* Send to an external recipient */
:EMAIL = 'example@example.com';
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-e', :EMAIL;

LABEL 90;
UNLINK ERRMSGS;
LABEL 99;
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Mail Client Pop-up Blocking Scheduled Tasks (TTS)
**Problem:** When running a report via `WINACTIV` with the `-u` flag in a scheduled task, a mail client window may pop up, causing the process to hang or block.
**Solution:** This behavior is typically governed by the user's mail definitions in the **System Permissions for User** form. If the user is configured to use an external mail client (e.g., Outlook) rather than internal Priority mail, the UI will trigger. Ensure the user running the task is configured for internal/direct mail to avoid UI interaction.
**Code Example:**
```sql
/* Ensure the recipient/user is configured for direct mail to avoid UI pop-ups */
EXECUTE WINACTIV '-R', 'MY_REPORT', 'MY_TABLE', :TMP, '-u', :MANAGER_USER;
```

#### Limitations on Customizing Email Subjects
**Problem:** Developers often need to dynamically change the email subject line when sending reports via the `-g` (group) or `-u` (user) flags.
**Solution:** There is currently no built-in SDK flag for the `WINACTIV -R` command to dynamically override the email subject line. The subject is automatically generated based on the report name.

#### Compatibility Issues After Version Upgrades
**Problem:** Private procedures sending attachments via `WINACTIV` may fail after upgrading (e.g., from version 22 to 23).
**Solution:** Upgrades often include changes to Office 365/Outlook integration. If failures occur, verify the "Mail Type" configuration in the user's system permissions. Switching between "Outlook" and "Direct" (SMTP) integration often resolves issues caused by updated security protocols in newer versions.
<!-- ADDED END -->
### Redirect Report to Tab-Delimited File

Use ACTIVATF with `-x` flag:

```sql
:F = '../..output.txt';
SELECT SQL.TMPFILE INTO :CST FROM DUMMY;
LINK CUSTOMERS TO :CST;
GOTO 299 WHERE :RETVAL <= 0;
INSERT INTO CUSTOMERS
SELECT * FROM CUSTOMERS O WHERE CUSTNAME = '250';
UNLINK CUSTOMERS;
EXECUTE ACTIVATF '-x', :F, '-R', 'OPENORDIBYDOER', 'CUSTOMERS', :CST;
LABEL 299;
MAILMSG 5 TO EMAIL 'demo@demo.com' DATA :F;
```

### Redirect Report to Excel

```sql
EXECUTE WINACTIV '-P', 'ORGUNITS', '-X', '..\temp\cur';
```

Provide the Excel file name without a suffix.

---

## Financial Documents

Set in the IVTYPES (Financial Documents) form. These procedures do not receive input and do not display messages.

### Initial Procedures (PREENAME Column)

- Check data before finalization.
- Invoices to be finalized are in `STACK2USER` where `ELEMENT` = INVOICES.IV and `USER` = current user.
- Error messages: set message number in `STACK2USER.TYPE`. Parameters: 1=Customer/Vendor, 2=Invoice Date, 3=Invoice Number.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Handling Message Parameters:**
    The system automatically populates `PAR1` (Customer/Vendor), `PAR2` (Date), and `PAR3` (Invoice Number) for error messages triggered via `STACK2USER`. These slots are fixed by the SDK. If you need to display data related to sub-companies or custom logic, you must query the database within your procedure using the provided parameters to fetch the related data, as you cannot overwrite these predefined input slots.

*   **Procedure Definition for Batch Processing:**
    Initial procedures for financial documents must be defined without input or output parameters. If a procedure is defined with parameters, it may trigger correctly when closing a single document from a form but fail to execute during batch processing (e.g., "Close Bank Transfers" from the menu).

*   **Error Reporting via STACK2USER:**
    To prevent a document from being finalized, you must set the message number in the `STACK2USER.TYPE` field for the specific record. The system will then display the message and stop the finalization process for that document.
<!-- ADDED END -->
### Follow-up Procedures (CONTENAME Column)

- Run after finalization (regardless of success).
- Receive the same linked INVOICES file as the Finalize Invoice program (in the PAR variable).

**Example:**
```sql
LINK INVOICES TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
SELECT IV,IVNUM,TYPE,DEBIT FROM INVOICES FORMAT '../../iv.txt';
SELECT IV,IVNUM,TYPE,DEBIT FROM INVOICES ORIG
WHERE IV = (SELECT IV FROM INVOICES) FORMAT ADDTO '../../iv.txt';
UNLINK INVOICES;
```

---

## Open Form Record from Procedure

**Guidelines:**
1. Define an interface using GENERALLOAD to open the target form.
2. Create a procedure as an Action from the source form.
3. Run the interface, then open the form with the new record.

**Example (opening Customer Shipment from Sales Orders):**
```sql
LINK ORDERS TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
:ORDNAME = '';
SELECT ORDNAME INTO :ORDNAME FROM ORDERS WHERE ORD <> 0;
UNLINK ORDERS;
ERRMSG 2 WHERE :ORDNAME = '';

LINK GENERALLOAD TO :$.GEN;
ERRMSG 1 WHERE :RETVAL <= 0;
INSERT INTO GENERALLOAD(LINE,RECORDTYPE,TEXT1) VALUES(1,'1',:ORDNAME);
EXECUTE INTERFACE 'YUVV_OPENDOC_D', SQL.TMPFILE, '-L', :$.GEN;

:DOCNO = '';
SELECT DOCNO INTO :DOCNO FROM DOCUMENTS
WHERE TYPE = 'D'
AND DOC = (SELECT ATOI(KEY1) FROM GENERALLOAD
WHERE LINE = 1 AND LOADED = 'Y');
UNLINK GENERALLOAD;
ERRMSG 3 WHERE :DOCNO = '';
:$.DNO = :DOCNO;

GOTO 9 WHERE :SQL.NET = 1;
/* Windows client: open form */
EXECUTE WINFORM 'DOCUMENTS_D', '', :DOCNO, '', '2';
LABEL 9;
```

For web interface: add another procedure step with Entity Name = ORDERS, Type = F, parameter DNO (CHAR).

---

## Dynamic SQL

### EXECUTE SQLI

```sql
:FILENAME = '..\..\tmp\sqlfile.txt';
EXECUTE SQLI :FILENAME;
```

Run SQL commands from a file. Supports both static (pre-written) and dynamic code.

**Important:** INSERT/UPDATE/DELETE operations are ignored unless run by users in the `tabula` user group.

**Example:** See step 20 of the LOADMIGUSERS procedure.

---

## Semaphores

### Basic Semaphore Pattern (LASTS Table)

The LASTS table has columns: `NAME` (CHAR, key) and `VALUE` (INT).

```sql
GOTO 1 FROM LASTS WHERE NAME = 'SDK_SEMAPHORE';
INSERT INTO LASTS(NAME) VALUES('SDK_SEMAPHORE');
LABEL 1;
UPDATE LASTS
SET VALUE = 1
WHERE NAME = 'SDK_SEMAPHORE'
AND VALUE = 0;
GOTO 99 WHERE :RETVAL <= 0;
/* ... protected code ... */
UPDATE LASTS
SET VALUE = 0
WHERE NAME = 'SDK_SEMAPHORE';
LABEL 99;
```

Always create an unlock procedure:
```sql
UPDATE LASTS SET VALUE = 0 WHERE NAME = 'SDK_SEMAPHORE';
```

### Time-Based Semaphore (Custom Table)

Create a custom table:
```sql
CREATE TABLE SDK_SEMAPHORES 'Semaphores' 0
NAME(CHAR, 48, 'Semaphore Name')
USER(INT, 8, 'User(id)')
UDATE(DATE, 14, 'Date')
UNIQUE(NAME);
```

Allow execution after 24 hours:
```sql
GOTO 1 FROM SDK_SEMAPHORES WHERE NAME = 'SDK_SEMAPHORE';
INSERT INTO SDK_SEMAPHORES(NAME) VALUES('SDK_SEMAPHORE');
LABEL 1;
UPDATE SDK_SEMAPHORES
SET UDATE = SQL.DATE, USER = SQL.USER
WHERE NAME = 'SDK_SEMAPHORE'
AND UDATE <= SQL.DATE - 24:00;
GOTO 99 WHERE :RETVAL <= 0;
/* ... protected code ... */
UPDATE SDK_SEMAPHORES
SET UDATE = 0, USER = 0
WHERE NAME = 'SDK_SEMAPHORE';
LABEL 99;
```

---

## Word Templates for Specific Records

Add a form column of INT type with name containing `AWORD` (e.g., `PRIV_AWORD`) to map specific records to specific Word templates.

Word templates are stored as negative-numbered form messages in the TRIGMSG table.

**Key triggers:**

**CHECK-FIELD:**
```sql
ERRMSG 501 WHERE :$.@ <> 0 AND NOT EXISTS
(SELECT * FROM TRIGMSG WHERE EXEC = :PRIV_EXEC
AND NUM = :$.@ AND NUM < 0);
```

**CHOOSE-FIELD:**
```sql
SELECT MESSAGE, ITOA(NUM) FROM TRIGMSG
WHERE EXEC = :PRIV_EXEC
AND NUM < 0
ORDER BY 2;
```

### Full Column Setup

The TRIGMSG join must be an **outer join** (`?` suffix on the join ID) because Word templates can be deleted — without it the form row disappears when a template is removed.

| Form Column | Column | Table | Join | Notes |
|---|---|---|---|---|
| `PRIV_AWORD` | `PRIV_AWORD` | base table | 0 | INT; drives template selection |
| `PRIV_MESSAGE` | `MESSAGE` | TRIGMSG | outer (e.g. `5?`) | Mark read-only |
| `PRIV_EXEC` | `EXEC` | TRIGMSG | outer (e.g. `5?`) | Hide this column |

**PRE-FORM trigger** (assigned to the `PRIV_EXEC` column):
```sql
:PRIV_EXEC = 0;
SELECT EXEC INTO :PRIV_EXEC FROM EXEC WHERE ENAME = 'FORMNAME' AND TYPE = 'F';
```
Set Expression/Condition in Form Column Extension for `PRIV_EXEC` to `= :PRIV_EXEC` so the form's EXEC id is available for the CHECK-FIELD and CHOOSE-FIELD triggers.

**POST-FIELD trigger** on `PRIV_AWORD`:
```sql
:$.PRIV_EXEC = :PRIV_EXEC;
```

Without the outer join on TRIGMSG, deleting any Word template causes the affected form row to vanish from the grid entirely.

*(seen in: handbook:WSCLIENT@page-328)*

---

## Business Rules Generator

Custom form columns appear in the e-mail/SMS Choose list if they meet one of:

1. **Calculated column** with name containing `EMAIL` (e.g., `PRIV_ORDEMAIL`).
2. **Regular column** from specific tables:

| Table | Column |
|---|---|
| CUSTOMERS | CUSTNAME |
| SUPPLIERS | SUPNAME |
| AGENTS | AGENTNAME |
| USERSB | SNAME |
| PHONEBOOK | NAME |
| USERS | USERLOGIN |
| UGROUPS | GROUPNAME |

The Business Rules Generator uses the corresponding e-mail/phone from the table (e.g., CUSTOMERS.EMAIL, USERSB.CELLPHONE). For USERS, the message goes to the associated employee. For UGROUPS, it goes to all group members.

---

## GANTT Charts (Gantt / Calendar / Group Schedule)

Use the `GANTT` program to build interactive scheduling charts for resource scheduling (technicians, work orders, appointments). A GANTT procedure has two sections separated by an `END` step:

- **Section 1:** INPUT/SQLI steps that build the LINK file, followed by a GANTT activation step with 21 positional parameters.
- **Section 2:** Named SQLI query steps (all type `C`, execution order unimportant).

### Three Chart Types

| Type | X-axis | Y-axis |
|---|---|---|
| Gantt | Variable timeline | Employees/resources |
| Calendar | 24-hour timeline | Days (main) + employees (sub) |
| Group Schedule | 24-hour timeline | Employees (main) + days (sub) |

### GANTT Activation Parameters (positional, Section 1)

| # | Parameter |
|---|---|
| 1 | Procedure name (to retrieve Section 2 query steps) |
| 2 | From Date |
| 3 | To Date |
| 4 | LINK file (linked employee/resource table; USERGANTT skips LINK) |
| 5 | Linked table name |
| 6 | Interface name (against GENERALLOAD, record type 1) |
| 7 | Form for task details |
| 8 | Form for employee details |
| 9 | Permit revisions (0/1) |
| 10 | Permit additions (0/1) |
| 11 | Default display: 1=Gantt, 2=Calendar, 3=Group Schedule, 0=last used, 4=Cal or GS |
| 12 | Selected task identifier |
| 13 | Selected resource identifier |
| 14–17 | Null placeholders |
| 18 | OTHERID (available as `:OTHERID` in Section 2 queries) |
| 19 | OTHERID2 |
| 20 | Chart title |
| 21 | Multi-company flag (0/1) |

### Section 2 Named Query Steps

| Step Name | Returns / Purpose |
|---|---|
| `RESOURCE` | Employee list (id, name, login, sort); vars: FROMDATE, TODATE |
| `RESOURCE_DETAILS` | Employee details; var: RESOURCEID |
| `TASKS` | Task list (id, resource, desc, from, to, target value, color); vars: FROMDATE, TODATE |
| `TASK_DETAILS` | Task details; var: TASKID |
| `TASK_TEXT` | Task text (TEXT, ORD); var: TASKID |
| `TASK_INSERT` | Pre-fill form fields on new task; vars: RESOURCEID, TASKDATE, etc. |
| `TASK_EDIT` | Dialog input fields (list GENERALLOAD target cols in a note); various vars |
| `TASK_REFRESH` | Updated task display after edit (desc, target, from, to, color) |
| `WORKHOURS` | Office hours per day (day, from, to); var: RESOURCEID |
| `DAYSOFF` | Non-working days; var: CURDATE — returns 0 on holiday, fails on workday |
| `RESOURCE_WORKHOURS` | Per-employee work hours (from/to date+time); replaces WORKHOURS+DAYSOFF |
| `RELATIONS` | Task dependencies (predecessor, successor, color); manufacturing only |
| `RESOURCE_CHOOSE` | Employee choose list |

### GENERALLOAD Interface Fields (add/update task, record type 1)

`INT1`=task id, `INT2`=resource id, `INT3`=from hour, `INT4`=to hour, `INT5`=previous resource id, `DATE1`=from date (DATE8), `DATE2`=to date (DATE8), `DATE3`=from date+time (DATE14), `DATE4`=to date+time (DATE14).

### Reserved Messages

Messages 1–20 are reserved for GANTT display titles. Custom field-title messages must use numbers `> 20`. Use `AS '#N'` in query `SELECT` aliases to bind a returned field to message number N.

*(seen in: handbook:Form Triggers@page-275-285)*

<!-- ADDED START -->

### Common Issues and Solutions

*   **Rules Failing on Custom Fields:** If a business rule (such as a status change block) fails to trigger on a custom checkbox or field, first verify if the field was modified manually by checking the **Record Change Log** sub-level. Ensure that the custom logic or field properties do not conflict with standard form behavior.
*   **Delayed or Non-Triggering Email Rules:** When a rule is set to send an email based on a "Value changed to" condition (e.g., a price deviation flag), the rule may fail to trigger if it is dependent on other flags being checked simultaneously. Verify the logic sequence and test whether the issue persists on standard fields versus private/custom fields to isolate the cause.
*   **Rules Missing from Business Rules Report After Upgrade:** If business rules on custom forms disappear from the **Business Rules Report** following a version upgrade (e.g., moving to version 23.0), ensure the custom form adheres to all development standards, including proper sorting and structure. Additionally, check for manual database schema modifications—such as manually added columns or altered field widths—that may prevent the report from correctly fetching rule metadata.

<!-- ADDED END -->
