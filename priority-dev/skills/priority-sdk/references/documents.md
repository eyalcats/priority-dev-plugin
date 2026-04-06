# Documents Reference

## Table of Contents

- [Introduction](#introduction)
- [Create the Input](#create-the-input)
- [Declare the Cursor (HTMLCURSOR)](#declare-the-cursor-htmlcursor)
- [Go Over the Records (SQLI Step)](#go-over-the-records-sqli-step)
- [Execute Reports for the Document](#execute-reports-for-the-document)
- [Display the Document (Final INPUT Step)](#display-the-document-final-input-step)
- [Define Print Options](#define-print-options)
- [Set Number of Copies](#set-number-of-copies)
- [Special Document Features](#special-document-features)
  - [Automatic Mail](#automatic-mail)
  - [Force Line Number Display](#force-line-number-display)
  - [Save a Certified Copy](#save-a-certified-copy)
- [WINHTML Program -- Output Documents](#winhtml-program----output-documents)
  - [Direct Mode Syntax](#direct-mode-syntax)
  - [Direct Mode Parameters](#direct-mode-parameters)
  - [Quick Mode Syntax](#quick-mode-syntax)
  - [Document Format](#document-format)
  - [Determine Available Print Formats](#determine-available-print-formats)
  - [WINHTML Code Examples](#winhtml-code-examples)
  - [Save a Certified Copy When Printing](#save-a-certified-copy-when-printing)
- [Letter Generator](#letter-generator)
  - [Letter Procedure Structure](#letter-procedure-structure)
  - [The LETTERSTACK Table](#the-letterstack-table)
  - [Additional Features](#additional-features)

---

## Introduction

A document procedure collects data from several reports and displays it in a browser. Each report creates a file; the last step combines all files into one displayed file.

Activate the document from a form (via Actions) or from a menu. Reports must handle **one record** from the base table at a time, identified by the autounique key.

## Create the Input

Name the linked file parameter for the main table **`PAR`**:
- If activated from a menu: define as input (`I` in Input column) with Column Name and Table Name
- If activated from a form only: Column Name and Table Name are still required, but the input flag is not needed
- Set parameter type to `FILE` or `NFILE` (version 23.0+; shows error if user provides no input)

## Declare the Cursor (HTMLCURSOR)

The `HTMLCURSOR` command creates the cursor over the records in the linked table:
- Write only the cursor query in this step
- Place the **autounique key** of the table as the first column in the query
- Retrieve additional columns for sort purposes
- The link to the table occurs in the background

Example (WWWSHOWORDER):
```sql
/* First column is ORD (autounique key) */
SELECT ORD, ORDNAME FROM ORDERS WHERE ORD <> 0 ORDER BY 2;
```

Note: In a non-English system with document value `E`, procedure parameters cannot be passed from before HTMLCURSOR to after. Workaround: write parameter values to a temporary table before HTMLCURSOR and read them later.

## Go Over the Records (SQLI Step)

The system automatically opens the cursor, runs the LOOP, and closes the cursor.

The first cursor parameter value is saved in **`:HTMLVALUE`** (CHAR type). Convert to integer using `ATOI`:

```sql
SELECT ORDNAME,ORD,ORDSTATUS,BRANCH
INTO :PAR1,:$.ORD,:STAT,:BRANCH
FROM ORDERS
WHERE ORD = ATOI(:HTMLVALUE)
AND ORD <> 0;
/* :$.ORD will be passed to the reports */
```

## Execute Reports for the Document

Each report receives at least two parameters:
1. The autounique key value of the current record
2. An **ASCII** parameter with `"OUTPUT"` in the Value column (this parameter reappears in the final INPUT step)

## Display the Document (Final INPUT Step)

The last step is the `INPUT` command. In Procedure Parameters, list all text file parameters sent to the reports.

The HTML page is viewed as a **matrix**. Position each text file in the **Proc. Parameter-HTML Design** form:
- Specify **row** and **column** for each parameter
- Row 1 = appears at the top of every page (e.g., company logo)
- Specify **Width %** for each report's share of the page

After designing, run the **Create HTML Page for Step** action. Rerun whenever the design is adjusted.

## Define Print Options

Name print formats in the **Print Formats** sub-level, then specify included reports in **Reports Included in Print Format**.

For attachment printing, include the `HTMLEXTFILES` command early in the procedure with a step query (no parameters needed).

## Set Number of Copies

Maintain copy count in a custom form column and use the DAYS table for looping:

```sql
/* In HTMLCURSOR step */
SELECT WTASKS.WTASK, WTASKS.WTASKNUM,
(:$.SRT = 1 ? WTASKS.WTASKNUM :(:$.SRT = 2 ? WAREHOUSES.WARHSNAME : ''))
FROM WTASKS, WAREHOUSES, DAYS
WHERE WTASKS.WTASK <> 0
AND WTASKS.WARHS = WAREHOUSES.WARHS
AND DAYS.DAYNUM BETWEEN 1 AND MAXOP(1, WAREHOUSES.PRIV_NUMCOPIES)
ORDER BY 3, 2;
```

Note: If the user also specifies copies at print time, the total is a product of both numbers. For documents with only one original (invoices), additional copies are still marked as copies.

## Special Document Features

### Automatic Mail

Include a report column with the title **`#MAIL`**. For external contacts, add a `#CUSTNAME` or `#SUPNAME` column with the customer/vendor number.

### Force Line Number Display

Include a report column titled **`{#LINE}`** -- it appears untitled, gets first column position, and cannot be hidden by users.

### Save a Certified Copy

- Include an `HTMLEXTFILES` step for attached files
- In the first INPUT step, set `:HTMLPRINTORIG = 1`
- In the SQLI step after HTMLCURSOR, set `:SAVECOPY = 1`

---

## WINHTML Program -- Output Documents

### Direct Mode Syntax

```
EXECUTE WINHTML '-d', 'document_name', 'table',
'linked_file', '-v', 'record_id', ['-trc', debug_file,] ['-s',]
['-e',]
['-edoc' | '-signpdf',] ['-format', format_num,]
['-lang', lang_num,] ['-AMAIL',]
['-o' |'-pdf' | '-wo' | '-wpdf',] ['output_file',]
```

### Direct Mode Parameters

| Parameter | Description |
|-----------|-------------|
| `-d` | Use Direct mode |
| `document_name` | Internal name (e.g., `WWWSHOWORDER`) |
| `table`, `linked_file` | Table and linked file for multiple records; use empty strings `'', ''` for single records |
| `-v` | Single record mode (skip HTMLCURSOR step for faster output) |
| `record_id` | Unique ID of the record (e.g., ORD = 100) |
| `-trc`, `debug_file` | Debug mode; output debugging info to file |
| `-s` | Suppress notification/progress window |
| `-e` | Use English version of document (non-English systems) |
| `-edoc` | Output as e-document |
| `-signpdf` | Output as digitally signed PDF (not equivalent to e-document) |
| `-o` | Output as system document (HTML) |
| `-pdf` | Output as PDF based on system document |
| `-wo` | Output based on Word template (DOCX) |
| `-wpdf` | Output as PDF based on Word template |
| `-format`, `format_num` | Specify print format number (single document only, with `-v`) |
| `-lang`, `lang_num` | Specify language of printout (use with `-format`) |
| `-AMAIL` | Automatically send to customer/vendor contact |

<!-- ADDED START -->
### Common Issues and Solutions

**Printing Multiple Copies**
The `WINHTML` command does not support a parameter for the number of copies (unlike the legacy `WINACTIV` command). To print multiple copies (e.g., an Original and a Copy), you must either execute the command twice or implement logic within the document procedure itself to handle multiple iterations.
```sql
/* Example: Executing twice to simulate multiple copies */
EXECUTE WINHTML '-dQ', 'ZTAD_WWWSHOWDOC_D', :ZTAD_DOC;
EXECUTE WINHTML '-dQ', 'ZTAD_WWWSHOWDOC_D', :ZTAD_DOC;
```

**Specifying Email Recipients with -AMAIL**
When using the `-AMAIL` parameter to automate document distribution, you can use additional undocumented flags to control the recipient list:
*   `-g`: Send to a predefined group of recipients.
*   `-u`: Send to a specific system user.
*   `-e`: Send to a specific email address.
```sql
/* Example: Sending an e-document to a group via AMAIL */
EXECUTE WINHTML '-d', 'WWWSHOWCIV', '', '', '-v', :IV, '-g', '-edoc', '-AMAIL', '-s';
```

**Dynamic Printer Selection**
`WINHTML` does not currently support a parameter to dynamically select a target printer (e.g., switching between A4 and A3 trays) via SQL. The system defaults to the printer defined for the user/procedure. To work around this, create duplicate printing procedures with different default printers assigned and use a `GOTO` step in your logic to route to the appropriate procedure.
<!-- ADDED END -->
### Quick Mode Syntax

```
EXECUTE WINHTML '-dQ' | '-dQe', 'document_name', 'record_id';
```

| Parameter | Description |
|-----------|-------------|
| `-dQ` | Quick mode |
| `-dQe` | Quick mode with English version of document |
| `document_name` | Internal name of the document |
| `record_id` | Unique ID of the record |

Quick mode assumptions:
- Default printer, single copy
- Format from the PRINTFORMAT table
- Single record only (cannot use linked table)
- `-v` (skip HTML cursor) and `-s` (silent) are in effect

Quick mode is the only mode that supports printing to a printer via browser.

<!-- ADDED START -->
### Common Issues and Solutions

**Printer Selection in Web Interface**
In the Priority web interface, Quick Mode (`-dQ`) is designed to use the browser's default printer settings. There is currently no parameter or SQLI syntax that triggers a manual printer selection pop-up or allows for programmatically switching the printer via `WINHTML`.
```sql
/* Prints to the default printer without selection dialog */
EXECUTE WINHTML '-dQ', 'WWWSHOWAIV', :IV;
```

**Sequential Printing in Procedures (Web vs. Windows)**
When executing `WINHTML -dQ` within a loop or a sequential procedure flow, the Web interface may only process the first print command, whereas the Windows client may process all of them. If multiple documents must be printed, consider consolidating them or verifying behavior within the specific web environment version.

**Inconsistent Execution in Custom Code**
If documents fail to print intermittently without an error message when using `-dQ`, ensure the `record_id` is correctly populated and the document name matches the internal name exactly. If the issue persists in private customizations, it often requires a review of the specific development logic rather than the standard `WINHTML` parameters.
```sql
/* Ensure :DOC is a valid, single record ID */
EXECUTE WINHTML '-dQ', 'WWWSHOWDOC_D', :DOC;
```
<!-- ADDED END -->
### Document Format

Set the format in one of two ways:

**Using `-format` parameter** (single document with `-v` only):
```sql
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-format', :HTMLFORMAT, '-o', :HTMLFILE;
```

**Using the PRINTFORMAT table** (always saves the last format used by a user for a document):
```sql
:EXEC = 0;
SELECT EXEC INTO :EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER';
:PRINTFORMAT = -5;
UPDATE PRINTFORMAT SET VALUE = :PRINTFORMAT
WHERE EXEC = :EXEC AND USER = SQL.USER;
```

For Word templates, multiply by -1:
```sql
:WORDFORMAT = -3;
UPDATE PRINTFORMAT SET VALUE = (:WORDFORMAT * -1)
WHERE EXEC = :EXEC AND USER = SQL.USER;
```

### Determine Available Print Formats

```sql
/* System document print formats */
SELECT * FROM EXTMSG WHERE EXEC = (
SELECT EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER')
AND NUM < 0 FORMAT;

/* Word templates */
SELECT * FROM TRIGMSG WHERE EXEC = (
SELECT EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER') FORMAT;
```

### WINHTML Code Examples

#### Output as HTML System Document (`-o`)

```sql
/* Single document */
:ORD = 100;
:HTMLFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.html');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-o', :HTMLFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS, '-o',
STRCAT(SYSPATH('TMP', 1), 'O.html');
```

#### Output as PDF Based on System Document (`-pdf`)

```sql
/* Single document */
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-pdf', :PDFFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS,
'-pdf', STRCAT(SYSPATH('TMP', 1), 'O.pdf');
```

#### Output as Word File (`-wo`)

```sql
/* Single document */
:ORD = 100;
:WORDFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.docx');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-wo', :WORDFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS, '-wo',
STRCAT(SYSPATH('TMP', 1), 'O.docx');
```

#### Output as PDF Based on Word Template (`-wpdf`)

```sql
/* Single document */
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-wpdf', :PDFFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS,
'-wpdf', STRCAT(SYSPATH('TMP', 1), 'O.pdf');
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **Web Interface Compatibility**: 
    When executing `WINHTML` with the `-wpdf` flag in the Web interface, the command may fail if data is passed via simple variables. To ensure compatibility across both Windows and Web interfaces, you must pass data via a linked table. Create a temporary file using `SQL.TMPFILE` and link it before executing the command.

*   **Forcing PDF Output**: 
    To prevent users from manually unchecking the "As PDF" option and editing the underlying Word document, use the `-wpdf` flag in a procedure. This programmatically forces the output to PDF format.
    ```sql
    /* Example: Forcing PDF output to a specific path */
    EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPFILE, 
    '-wpdf', '../../TEMP/O.pdf';
    ```

*   **Missing Fields in Output**: 
    If custom fields added to a Word template do not appear in the final PDF output despite being correctly mapped in the procedure, the Word template file may be corrupted. The recommended solution is to create a new, clean Word template from scratch and re-add the fields.
<!-- ADDED END -->
#### Print with `-format`

```sql
:ORD = 100;

/* HTML with specific format */
:HTMLFORMAT = -1;
:HTMLFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.html');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-format', :HTMLFORMAT, '-o', :HTMLFILE;

/* Word with specific format */
:WORDFORMAT = -3;
:WORDFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.docx');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-format', :WORDFORMAT, '-wo', :WORDFILE;
```

#### Quick Mode -- Print to Default Printer

```sql
:ORD = 100;
EXECUTE WINHTML '-dQ', 'WWWSHOWORDER', :ORD;
```

#### Digitally Signed PDF

```sql
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-signpdf', '-pdf', :PDFFILE;
```

#### E-Document (Digitally Signed)

```sql
/* Create e-document */
EXECUTE WINHTML '-d', 'WWWSHOWCIV', '', '', '-v', :IV, '-s',
'-edoc', '-pdf', :FILE2;

/* Create and auto-mail e-document */
EXECUTE WINHTML '-d', 'WWWSHOWCIV', '', '', '-v', :IV, '-g',
'-edoc', '-AMAIL', '-s';
/* Note: When using -AMAIL, do not specify path/filename */
```

#### Display Document in Browser (Version 22.0+)

Combine WINHTML with a URL step:

```sql
/* In an SQLI step with ASCII parameter ADD */
:DOC = 100;
:FILENAME = 'document.pdf';
:PATH = '';
/* Create path in system/mail folder */
SELECT NEWATTACH(:FILENAME) INTO :PATH FROM DUMMY;
EXECUTE WINHTML '-d', 'WWWSHOWORD', '', '', '-v', :DOC, '-pdf',
:PATH;
SELECT SQL.TMPFILE INTO :$.ADD FROM DUMMY;
SELECT :PATH FROM DUMMY
ASCII :$.ADD;
/* Then add a URL step with the ADD parameter */
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Migrating from Windows (WINACTIV) to Web (WINHTML)
When migrating procedures that generate documents from the Windows interface to the Web interface, `WINACTIV` must be replaced with `WINHTML`. Unlike `WINACTIV`, `WINHTML` runs on the server and requires data to be passed via linked tables.
**Solution:**
1. Use `SQL.TMPFILE` to create a temporary file.
2. Insert the required data into a table.
3. Use the `LINK` command to link that table.
4. Call `WINHTML` passing the linked table as a parameter.

```sql
/* Example of old Windows-only code to be replaced */
EXECUTE WINACTIV '-P', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS;
```

#### Inconsistent Failures in File Generation
If `WINHTML` works intermittently when generating files for email attachments, it is rarely a global system issue.
**Solution:** Review the custom development logic. Ensure that the file path generated (e.g., via `SYSPATH` or `NEWATTACH`) is valid and that the process has sufficient permissions to write to that directory at the moment of execution.

#### Unexpected Images or Signatures on Documents
If unauthorized or unexpected images (like a specific user's signature) appear on printed documents, the logic is likely not part of the standard document template.
**Solution:** Check the SQLI steps of the print procedure. Look for hardcoded file paths or dynamic logic that links image files to the document generation process based on user parameters or document types.
<!-- ADDED END -->
### Save a Certified Copy When Printing

Requirements:
- Include an `HTMLEXTFILES` step for attached files
- In the first INPUT step, set `:HTMLPRINTORIG = 1`
- In the SQLI step after HTMLCURSOR, set `:SAVECOPY = 1`

---

## Letter Generator

Design letters with dynamically populated data fields using the **Letter Generator** form. Assign a name and choose the procedure that creates the letter.

Sub-levels:
- **Remarks** -- design and edit letter content (including data fields)
- **Attachments** -- attach files to the letter

### Letter Procedure Structure

1. **INPUT** -- user input step
2. **HTMLCURSOR** -- declare cursor for records
3. **SQLI step** -- retrieve the record (via `:HTMLVALUE`) and insert values into the `LETTERSTACK` table
4. **Reports** at top of letter (e.g., company logo, document number)
5. **MAILMERGE step** -- populate fields in formatted text with corresponding values. Parameters:
   - Linked table receiving the processed text (fields replaced by values)
   - INT variable with the autounique value of the relevant record
   - CHAR variable with the column name containing the autounique value (e.g., `CUSTOMERS.CUST`)
6. **LETTERSTEXT report** -- receives:
   - Linked table from MAILMERGE step (processed text)
   - ASCII parameter with value `"OUTPUT"`
7. **Reports** at bottom of letter (e.g., user signature)
8. **INPUT** -- combine all text files into a single HTML file
9. **END** -- end the procedure
10. **Source report** -- list all data fields for the letter, based on LETTERSTACK table

### The LETTERSTACK Table

Unique key columns:

| Column | Content |
|--------|---------|
| `USER` | Current user name |
| `STATUSTYPE` | BPM system type for the document type (e.g., `5` for customer letters) |
| `KEY1` | Autounique value of the record (usually from `:HTMLVALUE`) |
| `KEY2` | Autounique value of a related record (e.g., customer's main contact) |

During the SQLI step, populate LETTERSTACK with values from the record and related records.

### Additional Features

- **Automatic Mail**: Include a column with revised title `#MAIL` in the source report
- **Attachments**: Include `HTMLEXTFILES` after `HTMLCURSOR` with a step query
- **BPM Integration**: Letters can be attached to BPM mail messages if the same document type is assigned
- **Multiple procedures**: Link a single letter to more than one procedure; users choose in Print/Send Options

When copying a letter procedure, delete the letters defined for the original (in Print Formats sub-level) and assign new ones.
