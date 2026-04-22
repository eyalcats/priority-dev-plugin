# File Operations

Reference for Priority's file-manipulation utilities: copying/moving files, listing directories, text filtering and base64 conversions, encryption, printing attachments, and reading the client INI file.

## Table of Contents

- [File Management Utilities](#file-management-utilities)
- [Click2Sign](#click2sign)
- [Encrypting Data](#encrypting-data)
- [FILELIST - Browse Folder Contents](#filelist---browse-folder-contents)
- [FILTER Program - Text File Manipulation](#filter-program---text-file-manipulation)
- [Get Data from Client INI File](#get-data-from-client-ini-file)
- [Print Attachments from a Procedure](#print-attachments-from-a-procedure)

---

## File Management Utilities

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

---

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
