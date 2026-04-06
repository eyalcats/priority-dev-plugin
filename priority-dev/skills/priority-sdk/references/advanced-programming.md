# Advanced Programming Reference

## Table of Contents

- [Run Procedure/Report from SQLI](#run-procedurereport-from-sqli)
  - [Commands Overview](#commands-overview)
  - [Execute a Procedure](#execute-a-procedure)
  - [Execute a Procedure with Linked Table](#execute-a-procedure-with-linked-table)
  - [Execute a Procedure with External Variables](#execute-a-procedure-with-external-variables)
  - [Execute a Report](#execute-a-report)
  - [Run a Report and Send by E-mail](#run-a-report-and-send-by-e-mail)
  - [Redirect Report to Tab-Delimited File](#redirect-report-to-tab-delimited-file)
  - [Redirect Report to Excel](#redirect-report-to-excel)
- [Financial Documents](#financial-documents)
  - [Initial Procedures (PREENAME Column)](#initial-procedures-preename-column)
  - [Follow-up Procedures (CONTENAME Column)](#follow-up-procedures-contename-column)
- [Open Form Record from Procedure](#open-form-record-from-procedure)
- [Click2Sign](#click2sign)
- [Encrypting Data](#encrypting-data)
- [Dynamic SQL](#dynamic-sql)
- [Semaphores](#semaphores)
  - [Basic Semaphore Pattern (LASTS Table)](#basic-semaphore-pattern-lasts-table)
  - [Time-Based Semaphore (Custom Table)](#time-based-semaphore-custom-table)
- [External Programs](#external-programs)
  - [File Management Utilities](#file-management-utilities)
  - [WINAPP - Run External Applications](#winapp---run-external-applications)
  - [WINRUN - Execute Priority from External Application](#winrun---execute-priority-from-external-application-windows-only)
  - [Miscellaneous Utilities](#miscellaneous-utilities)
- [FILELIST - Browse Folder Contents](#filelist---browse-folder-contents)
- [FILTER Program - Text File Manipulation](#filter-program---text-file-manipulation)
  - [Basic Character Replacement](#basic-character-replacement)
  - [String Replacement](#string-replacement)
  - [Replace with File Contents](#replace-with-file-contents)
  - [FILTER Parameters](#filter-parameters)
  - [Encoding Filters](#encoding-filters)
  - [File Formatting](#file-formatting)
  - [Base64](#base64)
- [WSCLIENT - Webservice Interaction](#wsclient---webservice-interaction)
  - [Syntax](#syntax)
  - [Parameter Reference](#parameter-reference)
  - [URL Longer Than 127 Characters](#url-longer-than-127-characters)
  - [Authenticate with OAuth2](#authenticate-with-oauth2)
  - [Building JSON Request Bodies](#building-json-request-bodies)
- [XML and JSON Parsing](#xml-and-json-parsing)
  - [XMLPARSE - Parse XML Files](#xmlparse---parse-xml-files)
  - [INSTAG - Insert Data into an XML Tag](#instag---insert-data-into-an-xml-tag)
  - [JSONPARSE - Parse JSON](#jsonparse---parse-json)
  - [Convert Files from Base64](#convert-files-from-base64)
- [SFTP with SFTPCLNT](#sftp-with-sftpclnt)
  - [Definitions for SFTP](#definitions-for-sftp)
  - [Upload/Download](#uploaddownload)
  - [List Folder Contents](#list-folder-contents)
- [Word Templates for Specific Records](#word-templates-for-specific-records)
- [Business Rules Generator](#business-rules-generator)
- [Get Data from Client INI File](#get-data-from-client-ini-file)
- [Print Attachments from a Procedure](#print-attachments-from-a-procedure)
- [Activate Priority from External Application](#activate-priority-from-external-application)

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

## Click2Sign

Add digital signature capability to documents (v20.1+).

**Requirements:**
- Priority version 20.1+
- Word template document printout
- Single signature (one signature tag in Word template)
- APP016 license

**Form requirements:**
- Form managed with BPM flow chart
- Uppermost level form contains a customer or vendor

**Implementation:**

Add to the SQLI stage directly after the first HTMLCURSOR stage:
```sql
:IVC = document identifier;
:TYPEC = flowchart type;
#INCLUDE func/click2sign
```

See the WWWSHOWCPROF program for a full example.

---

## Encrypting Data

Use the CRPTUTIL program:

```sql
EXECUTE CRPTUTIL [MODE], -1, [TABLE];
```

| Parameter | Description |
|---|---|
| MODE | `2` = encrypt, `3` = decrypt |
| `-1` | Encryption method (AES-256) |
| TABLE | Table to encrypt (linked file) |

The encryption key is unique per Priority installation; encrypted data cannot be transferred and decrypted in another installation.

**Important:** Running "Reset Priority Connect Data" regenerates the encryption key, making previously encrypted data unrecoverable.

**Complete example:**
```sql
SELECT SQL.TMPFILE INTO :TST_STK FROM DUMMY;
LINK STACK_ERR TST_CRPSTK TO :TST_STK;
GOTO 9 WHERE :RETVAL <= 0;

:TST_CRPTMODE = 2; /* Encrypt */
:TST_STRING1 = 'First very long confidential string 1 in var string1';
:TST_STRING2 = 'Second very long confidential string 1 in var string1';

DELETE FROM STACK_ERR TST_CRPSTK;
INSERT INTO STACK_ERR TST_CRPSTK (LINE, MESSAGE) VALUES(1, :TST_STRING1);
INSERT INTO STACK_ERR TST_CRPSTK (LINE, MESSAGE) VALUES(2, :TST_STRING2);

EXECUTE CRPTUTIL :TST_CRPTMODE, -1, :TST_STK;
SELECT LINE, MESSAGE, INTDATA1
FROM STACK_ERR TST_CRPSTK WHERE LINE > 0 FORMAT;

:TST_CRPTMODE = 3; /* Decrypt */
EXECUTE CRPTUTIL :TST_CRPTMODE, -1, :TST_STK;
SELECT INTDATA1, LINE, MESSAGE
FROM STACK_ERR TST_CRPSTK WHERE LINE > 0 FORMAT;

LABEL 9;
UNLINK STACK_ERR TST_CRPSTK;
```

**Note:** For long strings, encrypted data may overflow into the INTDATA1 field.

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

## External Programs

### File Management Utilities

| Operation | Syntax |
|---|---|
| Copy a file | `EXECUTE COPYFILE :source, :destination;` |
| Download from Internet | `EXECUTE COPYFILE '-i', :url, :tofile, timeout, [:msgfile];` |
| Move a file | `EXECUTE MOVEFILE :f1, :f2;` |
| Delete a file | `EXECUTE DELWINDOW 'f', :f1;` |
| Create a folder | `EXECUTE MAKEDIR :dir;` |
| Get file date | `EXECUTE GETDATE 'path/file_name', :$.STK;` |
| Get file size | `EXECUTE GETSIZE 'path/file_name', :$.STK;` |

**GETDATE example:**
```sql
LINK STACK TO :$.STK;
ERRMSG 1 WHERE :RETVAL <= 0;
EXECUTE GETDATE 'path/file_name', :$.STK;
:FILEDATE = 0;
SELECT ELEMENT INTO :FILEDATE FROM STACK WHERE ELEMENT > 0;
UNLINK STACK;
```

**GETSIZE example:**
```sql
LINK STACK TO :$.STK;
ERRMSG 500 WHERE :RETVAL <= 0;
EXECUTE GETSIZE 'path/file_name', :$.STK;
:FILESIZE = 0;
SELECT ELEMENT INTO :FILESIZE FROM STACK WHERE ELEMENT > 0;
UNLINK STACK;
```

**Note:** When using COPYFILE to the MAIL or SYNC system folders (v22.1+), folders are created automatically in lowercase.

<!-- ADDED START -->
### Common Issues and Solutions

**Access Denied (Error Code 5)**
*   **Problem:** Utilities like `COPYFILE` or `MOVEFILE` fail with "Error: unknown error code: 5" or "Access is denied."
*   **Solution:** This is typically a Windows OS permission issue. Ensure that the Priority service user (or the user running the process) has full Read/Write permissions for both the source and destination directories. In test environments, verify that file paths are updated to point to valid test folders rather than production paths.

**DELWINDOW Deleting Parent Folders**
*   **Problem:** In version 23.0, using `DELWINDOW 'f'` to delete the last remaining file in a folder incorrectly deletes the entire parent folder as well.
*   **Solution:** This was a regression in the system BIN files. Update to version 23.0.27 or higher to resolve this behavior.
*   **Example:**
```sql
/* In affected versions, deleting 1.txt might remove the 'hana' folder */
:OLD_PATH = '..\..\system\mail\hana\1.txt';
EXECUTE DELWINDOW 'f', :OLD_PATH;
```

**Directory-Level Operations Support**
*   **Problem:** `MOVEFILE` and `COPYFILE` utilities may fail when attempting to move or copy entire folders instead of individual files after upgrading to version 23.0.
*   **Solution:** This was identified as a regression. Ensure your system binaries are updated (version 22.1 and higher) to restore support for directory-level operations.
*   **Example:**
```sql
/* Moving an entire directory */
EXECUTE MOVEFILE 'C:\TEMP\source_folder' , 'C:\TEMP\dest_folder';
```
<!-- ADDED END -->
### WINAPP - Run External Applications

```sql
EXECUTE WINAPP 'path', ['-w'], 'program', [parameters];
```

- Path: full path to the external program (web interface: must be in BIN.95 folder)
- `-w`: wait for the program to complete before returning
- Program name with or without .exe suffix

**Examples:**
```sql
/* Run MS-Word */
EXECUTE WINAPP 'C:\Program Files\Microsoft Office\Office', 'WINWORD.EXE';

/* Open tabula.ini in Notepad and wait */
EXECUTE WINAPP 'C:\Windows', '-w', 'notepad', 'tabula.ini';
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Web Interface Execution Environment
In the Web interface, `WINAPP` executes on the **server side** (IIS server), not on the local client machine. 
*   **Location:** Executables must be stored in the `bin.95` directory on the server.
*   **Path Parameter:** To avoid hardcoding paths or issues with UNC paths (where `SYSPATH` might return a network address), leave the first parameter empty (`''`). This defaults to the local `bin.95` folder on the server.
*   **Permissions:** The OS user running the "Priority App Service" or IIS App Pool must have sufficient permissions to access the executable and any network paths the program interacts with.

```sql
/* Recommended syntax for Web Interface (executable in bin.95) */
EXECUTE WINAPP '', '-w', 'CheckApp.exe';
```

#### File Access in Web Environment
Because the application runs on the server, any file parameters (input/output files) must refer to paths accessible by the server's file system, not the user's local `C:\` drive. If you need to process a local file, it must first be uploaded to the server.

#### Running Local Client Applications from Web
`WINAPP` cannot trigger local applications (like a `.bat` file or `ftp.exe`) on a user's computer when using the Web interface. 
*   **Solution:** For client-side interaction, develop a local Web Service on the client machine and communicate with it using the `WSCLIENT` command instead of `WINAPP`.

#### Limitations of WINACTIV and ACTIVATE in Web
Commands like `WINACTIV` or `ACTIVATE` (often used to trigger reports or other procedures with UI) are generally not supported within form triggers in the Web interface. If a procedure calls an external executable that requires user interaction, it will fail in the Web environment as there is no desktop session to display the interface.

#### Using EXL2TXT Utility
When using the `EXL2TXT.exe` utility via `WINAPP` to convert files for `DBLOAD`:
*   Ensure the utility is in the server's `bin.95` folder.
*   Ensure the source Excel file and target Text file paths are server-accessible paths.

```sql
/* Example: Converting Excel to Text on the server */
EXECUTE WINAPP '', '-w', 'EXL2TXT.exe', 'C:\temp\data.xls', 'C:\temp\data.txt';
```
<!-- ADDED END -->
### WINRUN - Execute Priority from External Application (Windows Only)

```
x:\priority\bin.95\winrun "" username password
x:\priority\system\prep company -nbg -err errfile command arguments
```

**Parameters:**
- `-nbg`: run in foreground
- `-err errfile`: send preliminary error messages to file

**Examples:**
```
/* Open Sales Orders form */
p:\priority\bin.95\winrun "" tabula XYZabc1 p:\priority\system\prep demo
WINFORM ORDERS

/* Run a procedure */
d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
WINACTIV -P BACKFLUSH_ONNEW

/* Run an interface */
d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
INTERFACE LOADORDERS d:\priority\tmp\messages.txt
```

<!-- ADDED START -->
### Common Issues and Solutions

**Web Interface Compatibility**
*   **Problem:** Attempting to execute `WINRUN` or `WINACTIV` from a client machine that only uses the Priority Web interface.
*   **Solution:** `WINRUN` is a legacy Windows-only utility and is not compatible with the Web interface environment. For web-based environments, use the Web SDK (REST API), the Task Scheduler (TTS), or execute logic via server-side procedures.
*   **Example:**
    ```cmd
    C:\priority\bin.95\winrun "" username password C:\priority\system\prep demo WINACTIV -P PROCEDURE_NAME
    ```

**Priority Zoom Limitations**
*   **Problem:** External applications or websites failing to trigger interfaces via `winrun.exe` after version updates in Priority Zoom.
*   **Solution:** Priority Zoom has specific development limitations regarding direct command-line execution from web services. It is recommended to use standard API modules or file-based interfaces (Excel/Load tables) rather than calling `winrun.exe` directly from an external web process.
*   **Example:**
    ```cmd
    c:\zoom\bin.95\winrun.exe "" username password c:\zoom\system\prep company c:\zoom\bin.95\INTERFAC.EXE INTERFACE_NAME C:\path\to\file.TXT -stackerr ERR_LOG -W -enforcebpm
    ```

**Inconsistent Data in HTML Generation**
*   **Problem:** Missing fields (e.g., "To" address) when generating documents via `WINHTML` through a `WINRUN` command line.
*   **Solution:** Ensure the `-nbg` (no background) flag is used to ensure the process has sufficient resources and focus to render the HTML. If data is still missing inconsistently, verify that the environment paths and permissions for the output directory are correctly mapped for the user executing the command.
*   **Example:**
    ```cmd
    "C:\Priority\bin.95\winrun" "" "username" "password" "\\server\priority\system\prep" company -nbg WINHTML -d WWWSHOWDOC_D "" "" -v 1234567 -s "" -o C:\output\path\doc.html
    ```
<!-- ADDED END -->
### Miscellaneous Utilities

**SHELLEX** (Windows client only):
```sql
:file = 'c:\test.doc';
EXECUTE SHELLEX :file;       /* Opens with default application */

:file = 'www.google.com';
EXECUTE SHELLEX :file;       /* Opens default browser */

:file = 'c:\temp';
EXECUTE SHELLEX :file;       /* Opens folder in Explorer */
```

**PRANDOM** (random value):
```sql
EXECUTE PRANDOM :file, :outtype;
/* 'Y' = hexadecimal, anything else = decimal */
```

---

<!-- ADDED START -->
### Common Issues and Solutions

**COPYFILE Parameter Requirements**
Starting from Priority 24.0, the `msgfile` parameter in the `COPYFILE` command is mandatory. If omitted, the command will fail to execute.
```sql
/* Correct syntax for version 24.0+ */
EXECUTE COPYFILE '-i', :url, :tofile, timeout, :msgfile;
```

**Client-Side vs. Server-Side Execution (EXL2TXT)**
The `EXL2TXT.exe` utility is a Windows-only client-side tool. It cannot be executed via the Web interface or directly on the server via `WINAPP` in a web environment. For web-based Excel processing, use built-in Form Load Excel import capabilities.
```sql
/* Works in Windows Client ONLY */
EXECUTE WINAPP 'C:\priority\bin.95', '-w', 'EXL2TXT.exe', :input_xls, :output_txt;
```

**Verifying DELWINDOW Success**
The `DELWINDOW` command does not return a success or failure status. To verify if a file was successfully deleted, use the `FileSizeDate` function from the `FUNC` table immediately after execution to check if the file still exists.

**PDF Manipulation Limitations**
Priority does not have built-in SDK methods for programmatically editing, merging, or overlaying text (such as Part IDs) onto existing external PDF files. Such operations require third-party tools or external scripts.

**Encoding and Hebrew Text (Hebconvert)**
The `Hebconvert` component is deprecated and not supported on SQL Server 2017 and above. To avoid "gibberish" or reversed Hebrew text when extracting data for external BI tools (like Qlik), it is recommended to use the REST API, which handles modern encoding standards correctly.

**Automating HTML Attachments**
To programmatically attach an HTML report to a form (e.g., `MAILBOX`):
1. Generate the report using `WINHTML` or `ACTIVATE` and save it to a file.
2. Use a Form Load (interface) to load that file path into the `EXTFILENAME` sub-level of the target form.

**Troubleshooting PRNTORIG**
If `PRNTORIG` sends a blank page, verify the file pathing. Ensure the path is accessible to the service user (especially when running via Task Scheduler) and consider using UNC paths for network accessibility.
<!-- ADDED END -->
## FILELIST - Browse Folder Contents

```sql
EXECUTE FILELIST :DIR, :ST6, :MSG ['-f' | '-R'];
```

**Flags:**
- Default: results in STACK6 table
- `-f`: results in STACK_ERR table (includes file size)
- `-R`: recursive search, STACK_ERR table, lists files including sub-folder paths

**STACK6 columns:**

| Column | Data |
|---|---|
| NAME | File name |
| TYPE | F (file), D (directory), L (pagination info) |
| NUM | Timestamp (as integer) |

**STACK_ERR columns:**

| Column | Data |
|---|---|
| MESSAGE | File name |
| CHARDATA | F (file), D (directory), L (pagination info) |
| INTDATA1 | Timestamp (as integer) |
| INTDATA2 | File size in bytes |

**Complete example:**
```sql
:DIR = STRCAT(SYSPATH('SYNC', 1), 'tmpDir');
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
EXECUTE FILELIST :DIR, :ST6, :MSG;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
DECLARE NEWFILES CURSOR FOR
SELECT TOLOWER(NAME)
FROM STACK6
WHERE TOLOWER(NAME) LIKE 'loadorder*';
OPEN NEWFILES;
GOTO 90 WHERE :RETVAL <= 0;
:FILENAME = '';
:TOFILENAME = STRCAT(SYSPATH('LOAD', 1), 'Example.load');
LABEL 10;
FETCH NEWFILES INTO :FILENAME;
GOTO 85 WHERE :RETVAL <= 0;
:PATH = STRCAT(:DIR, '/', :FILENAME);
/* Option 1: copy then DBLOAD */
EXECUTE COPYFILE :PATH, :TOFILENAME;
EXECUTE DBLOAD '-L', 'Example.load';
/* Option 2: DBLOAD with -i */
EXECUTE DBLOAD '-L', 'Example.load', '-i', :PATH;
LOOP 10;
LABEL 85;
CLOSE NEWFILES;
LABEL 90;
UNLINK STACK6;
LABEL 99;
```

**FILELIST on Public Cloud (AWS):** Limited to 1000 files per call. A record with type `L` indicates pagination: value `1` = all results retrieved, value `0` = more results available (UNLINK AND REMOVE, then rerun).

---

<!-- ADDED START -->
### Common Issues and Solutions

**Using the -f Flag for File Metadata**
To retrieve file sizes and timestamps, use the `-f` flag. Ensure the flag is written in lowercase. When using this flag, you must link to the `STACK_ERR` table instead of `STACK6`.
```sql
SELECT SQL.TMPFILE, SQL.TMPFILE INTO :ERR, :MSG FROM DUMMY;
EXECUTE FILELIST :DIR, :ERR, :MSG '-f';
LINK STACK_ERR TO :ERR;
```

**Performance on Large Directories**
Scanning directories with a very high volume of files (e.g., 60,000+ files) on network drives can result in significant performance degradation. It is recommended to archive or move files to keep directory counts at a manageable level for optimal OS-level response times.

**System Crashes and Invalid Dates**
In versions prior to 23.0, files with invalid OS modified dates (e.g., years such as 1692) could cause a system crash (dmp file). Ensure your Priority BIN version is 23.0 or higher to benefit from built-in protection against invalid file metadata.

**Accessing Remote Paths (UNC)**
The command supports UNC paths for accessing remote servers. Ensure the service user running Priority has the necessary Windows permissions to access the target network share.
```sql
:DIR = '\\ServerName\SharedFolder\Path';
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
EXECUTE FILELIST :DIR, :ST6, :MSG;
```
<!-- ADDED END -->
## FILTER Program - Text File Manipulation

### Basic Character Replacement

```sql
EXECUTE FILTER 'Fromchar', 'Tochar', 'Targetchar', :INPUT, :OUTPUT;
```

Formula: `new character = original character + (Targetchar - Fromchar)`

**Convert uppercase to lowercase:**
```sql
EXECUTE FILTER 'A', 'Z', 'a', :INPUT, :OUTPUT;
```

**Convert tabs to commas:**
```sql
EXECUTE FILTER '09', '09', ',', :INPUT, :OUTPUT;
```

### String Replacement

```sql
EXECUTE FILTER '-replace', 'OldString', 'NewString', :INPUT, :OUTPUT;
```

Multiple replacements:
```sql
EXECUTE FILTER '-replace', 'Old1', 'New1', 'Old2', 'New2', :INPUT, :OUTPUT;
```

### Replace with File Contents

```sql
EXECUTE FILTER '-replacef', '[string]', :FILESTR, :INPUT, :OUTPUT;
```

Useful for inserting strings longer than the 127-character variable limit.

### FILTER Parameters

| Parameter | Description |
|---|---|
| `-r` | Reverse order of characters in file |
| Input, Output | Input and output file paths |
| `-M`, `Msgfile` | Record error messages to file |

<!-- ADDED START -->
### Common Issues and Solutions

*   **Input File Existence Requirement**
    Since 2018 (version 18.0+), the `FILTER` program throws a hard error if the specified input file does not exist. Developers must verify the file's existence before execution to avoid process failure.
    ```sql
    /* Ensure :TEV_TMPFILEPATH exists before execution */
    EXECUTE FILTER '9', '9' ,'44', :TEV_TMPFILEPATH, :TEV_FILEPATH ;
    ```

*   **Removing Newline Characters**
    When attempting to strip newline characters from a file, the `-replace` parameter may not behave as expected with standard escape sequences like `\n`. Instead, use the dedicated `-delnl` parameter.
    ```sql
    /* Recommended way to delete newline characters */
    EXECUTE FILTER '-delnl', :INPUT, :OUTPUT ;
    ```

*   **Buffer Limits and Truncation**
    In certain versions, the `FILTER` program may truncate output files at 5121 characters when processing single-line input files due to internal buffer limits. If you encounter unexpected truncation on long single lines, contact support to verify if your version includes the fix for task EP-23960.
    ```sql
    /* Example of a call that may trigger buffer limits on long lines */
    EXECUTE FILTER '123', '123', '124', 'input.txt' , 'output.txt' ;
    ```
<!-- ADDED END -->
### Encoding Filters

| Filter | Description |
|---|---|
| `-unicode2ascii` | Unicode to ASCII |
| `-ascii2unicode` | ASCII to Unicode |
| `-unicode2utf8` | UTF-16 to UTF-8 |
| `-utf82unicode` | UTF-8 to UTF-16 |
| `-ofx2xml` | OFX to XML (for XMLPARSE) |

<!-- ADDED START -->
### Common Issues and Solutions

#### Encoding Sequence for String Manipulation
When performing string replacements (such as escaping `&` or `>`) on files intended for Unicode output, executing filters on an existing Unicode file may yield incorrect results.
*   **Solution:** Generate the initial file in standard ASCII/ANSI format, perform all necessary string manipulations and replacements, and apply the `-ascii2unicode` filter as the final step in the process.

#### Legacy HEBCONV Utility and SQL Server Compatibility
The legacy `HEBCONV` component, used for handling bidirectional Hebrew text and character set conversions (e.g., to ASCII Code 862), faces compatibility issues with modern environments.
*   **Solution:** For SQL Server 2016, the component requires `clr strict security` to be disabled to function. However, for SQL Server 2017 and above, this component is being phased out. It is recommended to migrate to the REST API for data retrieval or use the `FILTER` program with the appropriate encoding flags for file-based conversions.
*   **Code Example (SQL Server 2016):**
```sql
EXEC sp_configure 'clr strict security', 0; RECONFIGURE;
```

#### Exporting to UTF-8 via Interface
Users may find that exporting data via `EXECUTE INTERFACE` results in ANSI encoding even when UTF-8 is expected after system upgrades.
*   **Solution:** Use the `FILTER` program explicitly with the `-ascii2unicode` or `-unicode2utf8` flags to ensure the output file matches the required encoding specification.
*   **Code Example:**
```sql
/* Example of calling an interface and then applying a filter */
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE, 'ou8', '-f', :inFile;
```
<!-- ADDED END -->
### File Formatting

| Filter | Description |
|---|---|
| `-addcr` | Add `\r` (carriage return) to each line |
| `-trim` | Trim blank spaces at start/end of each line, remove CR |
| `-delnl` | Delete last empty line in file |

### Base64

**Encode to base64:**
```sql
EXECUTE FILTER '-base64', :INPUT, :OUTPUT, SQL.TMPFILE;
```

**Decode from base64:**
```sql
EXECUTE FILTER '-unbase64', :INPUT, :OUTPUT, SQL.TMPFILE;
```

Input file for `-unbase64` must be in Unicode format.

**Example:**
```sql
:_PDF = STRCAT(SYSPATH('TMP', 1), 'f.pdf');
:_PDF_B = STRCAT(SYSPATH('TMP', 1), 'f_base64.pdf');
:_PDF2 = STRCAT(SYSPATH('TMP', 1), 'f_new.pdf');
EXECUTE FILTER '-base64', :_PDF, :_PDF_B, SQL.TMPFILE;
EXECUTE FILTER '-unbase64', :_PDF_B, :_PDF2, SQL.TMPFILE;
```

**Replace string with base64 of file:**
```sql
EXECUTE FILTER '-replacestrbase64', :INPUT, :OUTPUT,
  '[stringToReplace]', :fileToConvert, SQL.TMPFILE;
```

Useful for inserting base64 data into JSON requests.

---

<!-- ADDED START -->
### Common Issues and Solutions

**Input File Encoding for Decoding**
When using the `-unbase64` filter to convert a string back into a file (e.g., PDF), the input file containing the Base64 string must be in **Unicode** format, not UTF-8. If the file is generated via a `SELECT` statement in Priority, ensure you use the `ASCII UNICODE` suffix.

```sql
/* Correct way to generate an input file for -unbase64 */
SELECT 'YmFzZTY0IGNvbnZlcnRpb24gdGVzdA==' 
FROM DUMMY 
ASCII UNICODE :FROMFILE;

EXECUTE FILTER '-unbase64', :FROMFILE, :TOFILE, SQL.TMPFILE;
```

**Inserting Base64 into XML/JSON**
To include a file as a Base64 string within an XML or JSON structure, first use the `-base64` filter to create a temporary text file. You can then use the `INSTAG` command or the `-replacestrbase64` filter to inject the content into your final request template.

**Version Requirements**
The `-base64` and `-unbase64` filters were officially introduced in the February 2022 release. Ensure your system version is up to date if these flags are not recognized.
<!-- ADDED END -->
## WSCLIENT - Webservice Interaction

### Syntax

```sql
EXECUTE WSCLIENT :endpoint_url, :inFile, :outFile
  [, '-msg', :msgFile]
  [[, '-head2', :oneHeader] | [, '-head', :headerFile]]
  [, '-usr', :wsUser [, '-pwd', :wsUserPwd] [, '-domain', :userDomain]]
  [, '-tlscert', "certData", "pem password"]
  [, '-tag'|'-val', :tagName]
  [, '-action', :soapAction]
  [, '-timeout', :msec]
  [, '-content', :contentType]
  [, '-method', :method]
  [, '-headout', headers_response_outfile]
  [, '-authname', :tokenCode]
  [, '-urlfile', urlfile];
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **GET Requests and Input Files:**
    When performing a `GET` request, the command may fail if a file path is passed as the second parameter (`:inFile`). Since `GET` requests typically do not have a request body, pass an empty string (`''`) as the input file parameter.
    ```sql
    :URL = 'https://api.example.com/odata/Customers';
    EXECUTE WSCLIENT :URL, '', :OUTJSON, '-method', 'GET';
    ```

*   **Binary/PDF File Corruption:**
    In older versions of Priority, binary files (such as PDFs) downloaded via `WSCLIENT` might arrive corrupted even if the same request works in external tools like Postman. This was a known issue in the executable (bin) and was resolved in version 22.1.85. If you encounter file corruption, ensure your environment is updated to at least this version.

*   **Cloud Environment Connectivity:**
    In Priority Cloud environments, outgoing requests via `WSCLIENT` are generally restricted to port 443. If you receive network or port blockage errors, verify that the destination service is listening on port 443 and that the specific destination URL has been whitelisted in the cloud firewall.

*   **Silent Failures or Environment Issues:**
    If `WSCLIENT` fails to send data without generating entries in the `ERRMSGS` table, it often indicates an outdated `bin` folder or a server-side environment issue. Testing the request against a third-party request inspector (like Pipedream or Webhook.site) can help determine if the issue lies within the Priority utility or the destination server.

*   **Missing Response Files in Older Versions:**
    In specific older versions (e.g., 18.5), the command might fail to generate the response file (`.RSP`) despite the same code working in newer versions. This typically requires a technical investigation into version-specific bugs or an upgrade to a more stable release.
<!-- ADDED END -->
### Parameter Reference

| Parameter | Description |
|---|---|
| `:endpoint_url` | URL of the web service (max 127 chars) |
| `:inFile` | File sent to the web service (Unicode; converted if different encoding specified) |
| `:outFile` | File where response is stored |
| `-msg`, `:msgFile` | File for error messages |
| `-head2`, `:oneHeader` | Single header (can specify multiple instances) |
| `-head`, `:headerFile` | Header file (each header must end with newline) |
| `-usr`, `:wsUser` | Username for authentication |
| `-pwd`, `:wsUserPwd` | Password for authentication |
| `-domain`, `:userDomain` | Domain for authentication |
| `-tlscert`, `certData`, `pem password` | Client-side certificate (PEM format) |
| `-tag` / `-val`, `:tagName` | Extract XML tag from response (`-val` = contents only) |
| `-action`, `:soapAction` | SOAP action |
| `-timeout`, `:msec` | Timeout in milliseconds |
| `-content`, `:contentType` | Content type (e.g., `application/json`) |
| `-method`, `:method` | HTTP method (default POST; can be GET, PATCH, etc.) |
| `-headout`, `outfile` | Store response headers in a file |
| `-authname`, `:tokenCode` | OAuth2 token code |
| `-urlfile`, `urlfile` | URL file for URLs > 127 chars (set endpoint_url to '') |

**Notes:**
- Error messages are also written to ERRMSGS with type `w` under SQL.USER.
- Use XMLPARSE to read XML/JSON responses.
- Requests/responses are written to server log at DEBUG level.
- Content-type for XML must match encoding in XML header.

<!-- ADDED START -->
### Common Issues and Solutions

**Handling Long Headers (e.g., API Tokens > 1000 characters)**
Priority `CHAR` variables have length restrictions that may prevent passing long Bearer tokens directly via `-head2`.
*   **Solution:** Save the long token/header string into an ASCII file using a table and the `SELECT TO ASCII` command. Then, use the `-head` parameter to reference this file.

**Extracting Data from Response Headers**
Sometimes required data (like a session token) is returned in the HTTP response header rather than the body.
*   **Solution:** Use the `-headout` parameter followed by a filename. This saves the response headers to a file which can then be parsed using standard Priority file-reading commands.

**HTTP 415 or Communication Errors after Upgrades**
Upgrading Priority versions may change default header behaviors. If a web service suddenly returns "Unsupported Media Type," it may require an explicit content type.
*   **Solution:** Explicitly define the `Content-Type` using the `-content` parameter.
*   **Example:**
    ```sql
    EXECUTE WSCLIENT :URL, :INFILE, :OUTFILE, '-content', 'text/xml';
    ```

**"Premature end of file" Errors with XML**
When `-content` is set to `text/xml`, the system performs stricter validation on the XML structure.
*   **Solution:** Ensure the input file includes a proper XML declaration (e.g., `<?xml version="1.0" encoding="UTF-8" ?>`). If the receiving server allows it, you may also try omitting the `-content` parameter to bypass strict local validation.
*   **Example:**
    ```sql
    EXECUTE WSCLIENT :URL, :INFILE, :OUTFILE, '-msg', :MSGS, '-content', 'text/xml; charset=utf-8';
    ```

**Timeout Limitations**
While the `-timeout` parameter accepts large values (in milliseconds), the connection may still drop if external factors (load balancers, firewalls, or the destination server's own timeout settings) are set to a lower threshold than the `WSCLIENT` parameter.
<!-- ADDED END -->
### URL Longer Than 127 Characters

```sql
EXECUTE WSCLIENT '', :INFILE, :OUTFILE,
  '-urlfile', :urlfile;
```

### Authenticate with OAuth2

1. Open the **OAuth2 Definitions** form in Priority.
2. Record Token Code and Token Description (use custom prefix, e.g., `DEMO_TOKEN`).
3. Register with the web service provider to obtain: ClientID, Client Secret (+ Client Secret 2 if needed), Token URL, OAuth2 URL.
4. Fill in Redirect URL:
   - **Automatic Redirect:** Run "Update Redirect URL" action. Requires Priority Application Server.
   - **OOB Redirect:** Use provider-supplied parameters (e.g., `urn:ietf:wg:oauth:2.0:oob`).
5. Fill in Scope (end with `offline_access`).

**Version 22.1+ options:**
- Additional Parameters for URL
- Encrypted Tokens (auto-encrypt received tokens)
- By User (users see only their own tokens)
- Multi-company (token persists between companies)

**Getting the Token:**
1. In OAuth2 Data subform, record Entity ID and Description.
2. Run "Get New Token" action.
3. Login in browser when prompted.
4. For Automatic Redirect, tokens are obtained automatically.
5. For OOB Redirect, copy the string from the browser and paste into Priority.
6. Refresh tokens via "Refresh Token" action.

Use `-authname` with the token code in WSCLIENT calls.

### Building JSON Request Bodies

When constructing JSON files to send as WSCLIENT request bodies, follow these rules:

#### Use `ASCII` format (not `TABS UNICODE`)

- `ASCII` = data only, no headings — correct for JSON files
- `TABS UNICODE` adds column titles to each record, polluting the JSON. Even with `:NOTABSTITLE = 1`, headers may still appear for STRCAT expressions
- `SQLSERVER` is documented as "TABS without titles" but may still produce headers in some contexts

```sql
/* CORRECT - plain ASCII, no headers */
SELECT STRCAT('{"key":"', :VALUE, '"}')
FROM DUMMY ASCII :BODYFILE;

/* WRONG - TABS UNICODE adds column headers */
SELECT STRCAT('{"key":"', :VALUE, '"}')
FROM DUMMY TABS UNICODE :BODYFILE;
```

#### Use `"` directly — no placeholder replacement needed

Double quotes `"` are valid inside single-quoted strings in Priority SQL. Write JSON with `"` directly instead of using `!` placeholders with FILTER replacement:

```sql
/* CORRECT - direct double quotes */
SELECT STRCAT('{"name":"', :NAME, '"}')
FROM DUMMY ASCII :BODYFILE;

/* UNNECESSARY - placeholder replacement */
SELECT STRCAT('{!name!:!', :NAME, '!}')
FROM DUMMY ASCII :BODYFILE;
EXECUTE FILTER '-replace', '!', '"', :BODYFILE, :BODYFILE2;
```

#### Respect the 127-character STRCAT limit

STRCAT results are limited to 127 characters. For longer JSON:
- Split into multiple variables: `:STR1`, `:STR2`, then `STRCAT(:STR1, :STR2)`
- Or use multiple `SELECT ... ASCII ADDTO` statements

```sql
/* Chain variables for longer JSON */
:STR1 = STRCAT('{"field1":"', :VAL1, '","field2":"', :VAL2, '",');
:JSON = STRCAT(:STR1, '"field3":"', :VAL3, '"}');
SELECT :JSON FROM DUMMY ASCII :BODYFILE;
```

#### Never mix `ASCII` and `ASCII UNICODE` in the same file

Mixing encodings in a single file (one SELECT with `ASCII`, another with `ASCII UNICODE ADDTO`) produces garbled output. Use the same format for all writes to a file.

#### `:HEBREWFILTER` breaks JSON structure

Setting `:HEBREWFILTER = 1` reorders the entire output line using the bidirectional text algorithm, including JSON syntax characters (`{`, `"`, `:`). This produces invalid JSON. Do not use `:HEBREWFILTER` when building JSON files.

Hebrew text in Priority is stored in visual (reversed) order. Handle the reversal on the receiving side, not in the Priority output.

#### `ASCII ADDTO` inserts newlines between SELECTs

Each `SELECT ... ASCII ADDTO` writes on a new line. The resulting file will have newlines between JSON fragments. Most APIs accept multiline JSON, but if the API is strict about single-line JSON, build the entire body in one SELECT or use FILTER to strip newlines.

#### File path recommendations

Use `system/tmp/` with user-specific filenames for debuggable temp files:

```sql
:BODYFILE =
STRCAT('../../system/tmp/',
ITOA(SQL.USER), '-body.txt');
```

Use `NEWATTACH` for production files that don't need manual inspection (files are auto-cleaned but **not** visible in `system/tmp/`):

```sql
:BODYFILE = NEWATTACH('body.txt');
```

**Important:** `NEWATTACH` files are stored in Priority's internal attachment directory, not in `system/tmp/`. During development, use explicit `system/tmp/` paths so you can inspect the files. Switch to `NEWATTACH` for production.

#### 68-character line length limit

The Priority VSCode extension enforces a 68-character maximum line length for SQLI code. Break long lines at commas or operators:

```sql
/* WRONG — line too long, VSCode will warn */
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE, '-msg', :WSMSG, '-method', 'POST', '-content', 'application/json';

/* CORRECT — break at parameter boundaries */
EXECUTE WSCLIENT :URL,
:BODYFILE, :RESPONSE,
'-msg', :WSMSG,
'-method', 'POST',
'-content', 'application/json';
```

String literals containing URLs may exceed 68 chars — this is acceptable and the extension will allow it.

#### No string concatenation operator

Priority SQLI has no `||` or `+` operator for string concatenation. Use `STRCAT()` function only:

```sql
/* WRONG — || does not exist in SQLI */
:FULLNAME = :FIRST || ' ' || :LAST;

/* CORRECT */
:FULLNAME = STRCAT(:FIRST, ' ', :LAST);
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Downloading Files from External URLs
In Priority Cloud environments, using `COPYFILE` to download files from external URLs often fails due to security restrictions or firewall blocks (especially for non-HTTPS links). 
**Solution:** Use `WSCLIENT` with the `GET` method to download the file to a temporary location first.
```sql
/* Example: Downloading a PDF via WSCLIENT */
:URL = 'https://external-service.com/file.pdf';
:TMP_FILE = NEWATTACH('download.pdf');
:EMPTY_IN = NEWATTACH('empty.txt'); /* WSCLIENT requires an input file */

EXECUTE WSCLIENT :URL, :EMPTY_IN, :TMP_FILE, '-method', 'GET';
```

#### Cloud Security and Whitelisting
When calling third-party APIs (e.g., Payment Gateways, SharePoint, or Cloud Storage) from a Priority Cloud environment, outbound requests may be blocked by default.
**Solution:** You must provide the Fully Qualified Domain Names (FQDN) or specific IP ranges of the external service to Priority Support to have them whitelisted in the cloud firewall.

#### Interacting with Cloud Storage (SharePoint, etc.)
Priority does not have a native "out-of-the-box" configuration for syncing with cloud storage providers like SharePoint.
**Solution:** Use `WSCLIENT` to interact with the provider's REST API. This typically requires setting up OAuth2 authentication (as described in the Authenticate with OAuth2 section) and using the `-authname` parameter to pass the token.
#### EXECUTE WRITE is NOT a Valid Command

`EXECUTE WRITE` does not exist in Priority SQLI. Do not use it for logging.
For debugging WSCLIENT calls, use the `-trc` flag which creates a trace file,
or log to a custom table (like the PIKY_APIFILES pattern below).

#### Recommended WSCLIENT POST Pattern (Clean)

```sql
/* Use NEWATTACH for all temp files */
:URL = 'https://api.example.com/endpoint';
:BODYFILE = NEWATTACH('body.txt');
:RESPONSE = NEWATTACH('resp.txt');
:WSMSG = NEWATTACH('wsmsg.txt');

/* Build JSON into a variable, then write with ASCII */
:PAR1 = STRCAT('{',
'"field1":"', :VAL1, '",',
'"field2":"', :VAL2, '"',
'}');
SELECT :PAR1 FROM DUMMY ASCII :BODYFILE;

/* Send POST with trace for debugging */
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE,
'-msg', :WSMSG, '-method', 'POST',
'-content', 'application/json', '-trc';

/* Check for errors */
:PAR1 = '';
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE USER = SQL.USER AND TYPE = 'w';
```

**Key points:**
- Use `NEWATTACH` instead of `STRCAT('../../system/tmp/', ITOA(SQL.USER), ...)` for temp files
- Use `ASCII` output (not `TABS UNICODE` + `FILTER` to replace quote placeholders)
- Double quotes `"` work directly inside single-quoted SQLI strings: `'"field":"value"'`
- Build complex JSON into a variable first with `STRCAT`, then `SELECT :VAR FROM DUMMY ASCII :FILE`
- Use `-trc` flag for debugging — creates a trace file with full request/response details
- Check `ERRMSGS` after WSCLIENT for error messages
- For batch API calls, log requests/responses to a custom table (see PIKY_APIFILES pattern in examples)

<!-- ADDED END -->
## XML and JSON Parsing

### XMLPARSE - Parse XML Files

```sql
EXECUTE XMLPARSE :XMLFILE, :LINKFILE, 0, :MSGFILE, ['-all'];
```

| Parameter | Description |
|---|---|
| `:XMLFILE` | XML file to parse |
| `:LINKFILE` | Linked INTERFXMLTAGS file for parsed data |
| `0` | Required syntax |
| `:MSGFILE` | Linked file for errors |
| `'-all'` | Parse all instances (omit for first instance only) |

**Note:** Starting with v23.1, XMLPARSE reads up to 45,000 characters per XML tag.

**Example:**
```sql
SELECT SQL.TMPFILE INTO :OUTXMLTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :OUTXMLTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTXMLTAB1;
GOTO 500 WHERE :RETVAL <= 0;
LINK INTERFXMLTAGS I2 TO :OUTXMLTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD',1), 'example.xml');

EXECUTE XMLPARSE :FILE, :OUTXMLTAB1, 0, :MSG;
EXECUTE XMLPARSE :FILE, :OUTXMLTAB2, 0, :MSG, '-all';

SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I1 WHERE LINE <> 0 FORMAT;
SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I2 WHERE LINE <> 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
UNLINK INTERFXMLTAGS I2;
```

### INSTAG - Insert Data into an XML Tag

```sql
EXECUTE INSTAG 'path_to_xml_file', 'path_to_data_file', 'tag_name';
```

**Variables version:**
```sql
:XMLFILE = 'path_to_xml_file';
:DATAFILE = 'path_to_data_file';
:XMLTAG = 'tag_name';
EXECUTE INSTAG :XMLFILE, :DATAFILE, :XMLTAG;
```

**Common use case -- inserting base64 image into XML:**
```sql
:IN_JPG = STRCAT(SYSPATH('TMP', 0), 'my_jpg.jpg');
:IN_JPGBASE = STRCAT(SYSPATH('TMP', 0), 'my_jpg.base');
EXECUTE FILTER '-base64', :IN_JPG, :IN_JPGBASE;
:IN_XML = STRCAT(SYSPATH('TMP', 0), 'file.xml');
:IN_TAG = 'attach';
EXECUTE INSTAG :IN_XML, :IN_JPGBASE, :IN_TAG;
```

**Note:** If multiple tags share the same name, contents are inserted into the first tag found.

### JSONPARSE - Parse JSON

Add `'Y'` to the end of the XMLPARSE command:

```sql
SELECT SQL.TMPFILE INTO :OUTJSONTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :OUTJSONTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTJSONTAB1;
GOTO 500 WHERE :RETVAL <= 0;
LINK INTERFXMLTAGS I2 TO :OUTJSONTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD',1), 'example.json');

EXECUTE XMLPARSE :FILE, :OUTJSONTAB1, 0, :MSG, '', 'Y';
EXECUTE XMLPARSE :FILE, :OUTJSONTAB2, 0, :MSG, '-all', 'Y';

SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I1 WHERE LINE > 0 FORMAT;
SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I2 WHERE LINE > 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
UNLINK INTERFXMLTAGS I2;
```

### Convert Files from Base64

Complete example for converting a base64-encoded PDF from a JSON response:

```sql
SELECT SQL.TMPFILE INTO :JSON1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :JSON1;
GOTO 500 WHERE :RETVAL <= 0;

/* Parse JSON response */
EXECUTE XMLPARSE :RESPONSE, :JSON1, 0, :MSG, '', 'Y';

SELECT SQL.TMPFILE INTO :PDFBASE64TMP FROM DUMMY;
SELECT SQL.TMPFILE INTO :PDFFILETMP FROM DUMMY;
SELECT SQL.TMPFILE INTO :FILTERTMP FROM DUMMY;

/* Dump base64 contents to file */
SELECT VALUE
FROM INTERFXMLTAGS I1
WHERE LINE > 0
AND TAG = 'pdf'
ASCII UNICODE :PDFBASE64TMP;
UNLINK INTERFXMLTAGS I1;

/* Prepare for base64 conversion */
SELECT '#' FROM DUMMY ASCII UNICODE ADDTO :PDFBASE64TMP;
EXECUTE FILTER '-delnl', :PDFBASE64TMP, :FILTERTMP;
EXECUTE FILTER '-filter', '#', '#', '010', :FILTERTMP, :PDFBASE64TMP;

/* Convert from base64 */
EXECUTE FILTER '-unbase64', :PDFBASE64TMP, :PDFFILETMP, SQL.TMPFILE;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
```

---

## SFTP with SFTPCLNT

Available starting with v23.1 (BIN95 version 9). Backports for v22.1 and v23.0.

### Definitions for SFTP

Set up in **Definitions for SFTP** form (System Management > System Maintenance > Internet Definitions > Definitions for SFTP):

| Field | Description |
|---|---|
| Code | Identifying code (used as CONFIGID) |
| SFTP Folder Desc | Short description |
| Path | Server URL starting with `sftp://` and ending with port (e.g., `sftp://20.0.0.195:22`) |
| User | Username |
| Password | Password |

**Note:** Only username/password authentication is supported.

### Upload/Download

```sql
EXECUTE SFTPCLNT 'CONFIGID', '-u' | '-d', 'SOURCEFILE',
  'DESTINATIONFILE', ['-msg', MSGFILE], ['-timeout', milliseconds];
```

| Parameter | Description |
|---|---|
| CONFIGID | Code from Definitions for SFTP |
| `-u` / `-d` | Upload or download |
| SOURCEFILE | File to upload from Priority, or download from SFTP |
| DESTINATIONFILE | Target file name (cannot create folders on SFTP during upload) |
| `-msg` | Error messages file |
| `-timeout` | Connection timeout in milliseconds |

**Upload example:**
```sql
SELECT SQL.TMPFILE INTO :SOURCE FROM DUMMY;
SELECT 'THIS IS A TEST' FROM DUMMY ASCII :SOURCE;
:DEST = 'destinationTest.txt';
EXECUTE SFTPCLNT 'ch1', '-u', :SOURCE, :DEST;
```

**Download example:**
```sql
:SRC = 'TestFolder/GrabTest.txt';
:TRGT = STRCAT(SYSPATH('LOAD', 1), 'GrabTarget.txt');
EXECUTE SFTPCLNT 'ch1', '-d', :SRC, :TRGT;
```

### List Folder Contents

```sql
EXECUTE SFTPCLNT 'CONFIGID', '-l', 'DIR', 'TABLEFILE',
  ['-msg', MSGFILE], ['-timeout', milliseconds];
```

**Example:**
```sql
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
EXECUTE SFTPCLNT 'vg1', '-l', 'pub/example', :ST6;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
SELECT NAME, TYPE, 01/01/88 + NUM FROM STACK6 WHERE NAME <> '' FORMAT;
UNLINK STACK6;
LABEL 99;
```

**Sample output:**
```
NAME                                T NUM
----------------------------------- - -------------
KeyGenerator.png                    F  02/10/23 12:45
KeyGeneratorSmall.png               F  12/10/23 08:15
ResumableTransfer.png               F  02/10/23 10:13
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

<!-- ADDED START -->

### Common Issues and Solutions

*   **Rules Failing on Custom Fields:** If a business rule (such as a status change block) fails to trigger on a custom checkbox or field, first verify if the field was modified manually by checking the **Record Change Log** sub-level. Ensure that the custom logic or field properties do not conflict with standard form behavior.
*   **Delayed or Non-Triggering Email Rules:** When a rule is set to send an email based on a "Value changed to" condition (e.g., a price deviation flag), the rule may fail to trigger if it is dependent on other flags being checked simultaneously. Verify the logic sequence and test whether the issue persists on standard fields versus private/custom fields to isolate the cause.
*   **Rules Missing from Business Rules Report After Upgrade:** If business rules on custom forms disappear from the **Business Rules Report** following a version upgrade (e.g., moving to version 23.0), ensure the custom form adheres to all development standards, including proper sorting and structure. Additionally, check for manual database schema modifications—such as manually added columns or altered field widths—that may prevent the report from correctly fetching rule metadata.

<!-- ADDED END -->
## Get Data from Client INI File

The TABINI program retrieves information from the user's `.ini` file (Windows only):

```sql
EXECUTE TABINI 'section', 'key', :linkfile;
```

- First parameter: INI section (e.g., `'Environment'`)
- Second parameter: key name (e.g., `'Tabula Host'`)
- Third parameter: LINK file of GENERALLOAD; data is in LINE=1, TEXT column
- Empty strings for both parameters returns the INI file name itself

**Example:**
```sql
SELECT SQL.TMPFILE INTO :A FROM DUMMY;
EXECUTE TABINI 'Environment', 'Tabula Host', :A;
LINK GENERALLOAD TO :A;
SELECT TEXT FROM GENERALLOAD WHERE LINE = 1 FORMAT;
UNLINK GENERALLOAD;
```

---

## Print Attachments from a Procedure

Use the PREXFILE program:

```sql
EXECUTE PREXFILE ['-d'], 'description1', 'description2', :linkfile;
```

| Parameter | Description |
|---|---|
| `-d` | Send directly to default printer (omit to choose printer) |
| `description1`, `description2` | Cover page text (empty strings = no cover page) |
| `:linkfile` | Linked STACK24 table with SORT_LINE and TEXT1 (file path) |

**Example:**
```sql
SELECT SQL.TMPFILE INTO :STK FROM DUMMY;
LINK ORDERS TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
LINK STACK24 TO :STK;
ERRMSG 1 WHERE :RETVAL <= 0;
INSERT INTO STACK24(SORT_LINE, TEXT1)
SELECT EXTFILES.EXTFILENUM, EXTFILES.EXTFILENAME
FROM EXTFILES, ORDERS
WHERE EXTFILES.IV = ORDERS.ORD
AND EXTFILES.TYPE = 'O'
AND EXTFILES.EXTFILENUM > 0
AND ORDERS.ORD <> 0;
UNLINK STACK24;
UNLINK ORDERS;

/* To default printer with cover page: */
EXECUTE PREXFILE '-d', 'description 1', 'description 2', :STK;

/* Choose printer with cover page: */
EXECUTE PREXFILE 'description 1', 'description 2', :STK;

/* To default printer without cover page: */
EXECUTE PREXFILE '-d', '', '', :STK;
```

<!-- ADDED START -->
### Common Issues and Solutions

**Truncated File Paths**
The `TEXT1` column in the `STACK24` table is natively limited to 68 characters. If the file path in the attachment field exceeds this length (up to 80 characters), the path will be truncated and the print will fail.
*   **Solution:** Use the **Column Generator** (*System Management > Generators > Tables > Column Generator > Change Column Width*) to manually increase the width of the `TEXT1` column in the `STACK24` table to accommodate full file paths.

**Printing Attachments via WINHTML**
The `WINHTML` command, often used for printing documents like Delivery Notes or Invoices, does not support the automatic printing of linked attachments.
*   **Solution:** To print attachments programmatically, you must use the `EXECUTE PREXFILE` command as shown in the examples above.

**Attachments from Custom Forms**
When using commands like `HTMLEXTFILES` to handle attachments in procedures, files from private (custom) forms may occasionally fail to be identified, particularly after version upgrades (e.g., to version 23.1).
*   **Solution:** Ensure the "Include Attachments" flag is correctly set. If the issue persists, generate a procedure DUMP file (TRC) to verify if the system is correctly mapping the custom form's attachment table.
<!-- ADDED END -->
## Activate Priority from External Application

### Open a Record from Hyperlink

```
priority:priform\@FORMNAME:DOCUMENTNUM:COMPANY:TABINIFILE:LANG
```

| Parameter | Description |
|---|---|
| FORMNAME | Entity name (for non-forms, add type suffix: `.P` for procedure, `.R` for report) |
| DOCUMENTNUM | Value of key column (leave blank to just open form) |
| COMPANY | Priority company name |
| TABINIFILE | Name of tabula.ini file |
| LANG | Language ID |

<!-- ADDED START -->
### Common Issues and Solutions

**Authentication Limitations**
The system does not support passing credentials (username and password) directly via URL parameters for the web client. If a user clicks a hyperlink and is not already authenticated in an active session, they will be prompted to log in manually before the record or entity is displayed.

**Opening Specific Records via Web SDK**
When using the Web SDK to open a form filtered to a specific record (similar to the `WINRUN` functionality in the Windows interface), use the `formStartEx` method with the `zoomValue` parameter.
```javascript
// Example: Opening a specific project in the DOCUMENTS_P form
await PrioritySdk.formStartEx(
    'DOCUMENTS_p', 
    this.onShowMessge, 
    null, 
    PRIORITY_LOGIN_CONFIG.profile.company, 
    1,
    { zoomValue: projectNumber, hiddenFields: [] }
);
```

**Hyperlinks in Scheduled Tasks (TTS)**
Hyperlinks generated within reports (e.g., using `WINACTIV`) are currently only active when the report is run manually by a user. If the report is generated and sent via the Task Scheduler (TTS), the hyperlinks will be rendered as plain text and will not be clickable.
<!-- ADDED END -->
### Open from Command Prompt (Windows Only)

```
x:\priority\priform.exe priform\@FORMNAME:DOCUMENTNUM:COMPANY:TABINIFILE:LANG
```
