# Web, Cloud & Dashboards Reference

## Table of Contents

- [Programming for Priority Web](#programming-for-priority-web)
  - [Key Differences from Windows](#key-differences-from-windows)
  - [Save Debug Files on Web](#save-debug-files-on-web)
- [Priority Cloud](#priority-cloud)
  - [File Handling Restrictions](#file-handling-restrictions)
  - [system/sync Folder](#systemsync-folder)
- [Priority Lite and Dashboards](#priority-lite-and-dashboards)
  - [Structure of HTML Procedures](#structure-of-html-procedures)
  - [Display Reports](#display-reports)
  - [Retain Variable Values](#retain-variable-values)
  - [User Identification](#user-identification)
  - [Input Options](#input-options)
  - [Define a Base Page](#define-a-base-page)
  - [Dashboard Procedure Types](#dashboard-procedure-types)
  - [Create a Multi-Part Dashboard](#create-a-multi-part-dashboard)
- [Web SDK Common Issues](#web-sdk-common-issues)
  - [CORS Configuration](#cors-configuration)
  - [Connection and Licensing](#connection-and-licensing)
  - [Report Execution with Formats](#report-execution-with-formats)
  - [Search and Filtering](#search-and-filtering)
  - [Procedure Execution](#procedure-execution)
  - [Text Display and Encoding](#text-display-and-encoding)
  - [Performance and Latency](#performance-and-latency)
  - [Documentation](#documentation)
  - [Macros](#macros)
- [BPM (Business Process Management) Creation](#bpm-business-process-management-creation)
  - [Overview](#overview)
  - [Step 1: Create the Statuses Table](#step-1-create-the-statuses-table)
  - [Step 2: Create the Statuses Form](#step-2-create-the-statuses-form)
  - [Step 3: Modify the Document Form](#step-3-modify-the-document-form)
  - [Step 4: Enable Document Tracking (Optional)](#step-4-enable-document-tracking-optional)
  - [Step 5: Update the STATUSTYPES Table](#step-5-update-the-statustypes-table)
  - [Step 6: Create Interfaces](#step-6-create-interfaces)
  - [Step 7: Create BPM Chart Procedure](#step-7-create-bpm-chart-procedure)
  - [Step 8: Debug the BPM](#step-8-debug-the-bpm)
  - [Step 9: Insert Initial Status](#step-9-insert-initial-status)

---

## Programming for Priority Web

### Key Differences from Windows

- Attachments must be in `system/mail` folder for user interaction.
- Do not use EXECUTE for entities requiring user input (runs on server, not client).
- Use `WINHTML` instead of `WINACTIV` for documents.
- Do not use `EXECUTE WINFORM`; add as procedure step with Type F instead.
- Entities with 4-character Application value ending in `0` are not displayed in web.
- Use UPLOAD/DOWNLOAD steps for file transfers.

<!-- ADDED START -->
### Common Issues and Solutions

- **UI Feedback and Progress (DISPLAY Command):**
  The `DISPLAY` command, used to show progress or status updates during procedure execution, is only supported in the Windows interface. In the Web interface, users will not see these updates, which may lead them to believe a process has stalled. Ensure procedures are optimized for performance to avoid duplicate executions by impatient users.

- **Keyboard Automation (KEYSTROKES):**
  The `:KEYSTROKES` system variable is not supported in the Web interface. Automation logic that relies on simulating key presses (e.g., triggering an Exit action) will fail.
  *Example of unsupported code:*
  ```sql
  :KEYSTROKES = '%{Exit}';
  ```

- **Table Access and Syntax Sensitivity:**
  The Web interface can be more restrictive regarding SDK requirements and table references than the Windows client. For example, reports utilizing system tables like `CHANGES_LOG_TITLE` may fail to display data in Web if there are syntax inconsistencies that the Windows client otherwise ignores.

<!-- ADDED END -->
<!-- ADDED START -->
### Common Issues and Solutions

- **Unsupported Shell and Execution Commands**: Commands like `SHELLEX`, `WINACTIV`, and `WINAPP` do not function in the Web interface. 
    - **Solution**: To display HTML or PDF reports, use `WINHTML` with the `-o` or `-pdf` flags. To run procedures, add them as procedure steps rather than calling them via `EXECUTE`.
    - **Code Example**:
      ```sql
      /* Instead of SHELLEX or WINACTIV */
      EXECUTE WINHTML '-pdf', :REPORT_NAME, :ARG;
      ```

- **Keystrokes and Navigation**: The `KEYSTROKES` command (e.g., `{Zoom}` for drill-down) is not supported in the Web interface.
    - **Code Example**:
      ```sql
      /* This will fail in Web */
      :KEYSTROKES = STRCAT('{End}', :TEXTDATA, '{Exit}', '{End}', '{Zoom}');
      ```

- **Progress Bars and UI Feedback**: The `DISPLAY` command and standard progress bars do not update or appear during procedure execution in the Web interface. There is currently no web-compatible replacement for forcing progress bar updates.

- **Direct Activations (Form Actions)**: Reports run via Direct Activation from a form do not support "Export to Excel" in the Web interface, even if the option is available when run from a menu. Additionally, procedures triggered as Form Actions will fail if they rely on `WINACTIV`.

- **Cross-Environment Form Opening**: Opening a form in a different company/environment (using the `-c` flag) works in Windows but is limited in Web, where the form typically opens in the current environment regardless of parameters.

- **Local File System Access**: Browsers cannot access local file directories (e.g., `C:\temp`) due to security restrictions. `SHELLEX` calls to local paths will fail; use `DOWNLOAD` steps for file delivery.

- **WebSDK Authentication Failures**: Intermittent HTTP 400/403 errors when using Personal Access Tokens (PAT) can occur if the system caches a previous SSO login session. Ensure the latest system updates are applied to fix routing logic.
<!-- ADDED END -->
### Save Debug Files on Web

```sql
/* Create a valid file path */
:DEBUGFILE = NEWATTACH('MyDebug', '.txt');

/* Work with data */
:FILEPATH = STRCAT(SYSPATH('TMP', 1), 'MyDebug.txt');
SELECT DAYNUM, DAYNAME FROM DAYS TABS :FILEPATH;

/* Copy to attachment */
EXECUTE COPYFILE :FILEPATH, :DEBUGFILE;
```

Then access via a form with Attachments subform (e.g., Tasks/CUSTNOTESA).

<!-- ADDED START -->
### Common Issues and Solutions

*   **Generating Trace Files in Web/Cloud Environments**
    To debug forms or procedures in a Priority Cloud environment where you lack direct server access, use the `-trc` flag in the "Run Entity" command.
    **Solution:** Run the entity with the trace flag followed by a local path.
    ```sql
    CURRENCIES -trc c:/tmp/dbg.txt
    ```
    For Cloud environments, use the **FILESAPI** service (SFTP via port 22) to retrieve these generated files from the server.

*   **Error 500 in Web Interface (Custom Forms)**
    Custom forms may work in the Windows client but trigger an "Error 500" in the Web interface.
    **Solution:** Check the `server.log` and the Windows Event Viewer on the web server at the exact time of the crash. Additionally, run the "System Data for Service Call" procedure to gather environment-specific logs for analysis.

*   **Temporary File Accumulation**
    Files generated using `SYSPATH('TMP', 1)` or system-generated debug files accumulate in the `Pr_sql/TMP` folder.
    **Solution:** These files are temporary and can be safely deleted manually to free up disk space.

*   **Web Interface Connectivity and 403 Errors**
    Specific actions (like opening the F6 text editor) may fail with a 403 error due to local internet filtering or firewalls.
    **Solution:** Use a HAR file (via Browser DevTools) or a network trace to identify the specific URL or resource being blocked by the provider or firewall.
<!-- ADDED END -->
## Priority Cloud

### File Handling Restrictions

Additional restrictions over Priority Web:

1. Do not save files directly to `system/mail` or `system/sync`. Create in temp, then COPYFILE:
```sql
SELECT NEWATTACH('aaa1', 'txt') INTO :FOUT FROM DUMMY;
SELECT SQL.TMPFILE INTO :F FROM DUMMY;
SELECT * FROM DAYS WHERE DAYNUM BETWEEN 1 AND 4 TABS :F;
EXECUTE COPYFILE :F, :FOUT;
```

2. Many programs cannot interact directly with files in `system/mail` or `system/sync`. Copy to temp first:
```sql
:RAWFILE = STRCAT(SYSPATH('SYNC', 1), 'csv_240915.txt');
:RAWTMPFILE = STRCAT(SYSPATH('TMP', 1), 'csv_240915.txt');
:FILTEREDFILE = STRCAT(SYSPATH('TMP', 1), 'tsv_240915.txt');
EXECUTE COPYFILE :RAWFILE, :RAWTMPFILE;
EXECUTE FILTER ',', ',', '09', :RAWTMPFILE, :FILTEREDFILE;
EXECUTE DBLOAD '-L', 'EXAMPLE', '-i', :FILTEREDFILE;
```

**Exception:** WINHTML can save directly to `system/mail`.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Restricted Path Access (Cloud/Web):**
    In Cloud environments, direct access to local server drives (e.g., `C:\tmp\`) or mapped network drives is strictly prohibited. File operations are restricted to the `system/mail`, `system/sync`, and `TMP` directories. If you attempt to use `EXECUTE COPYFILE` or other file commands on paths outside these system-defined directories, the operation will fail. Always use the `SYSPATH` function to resolve valid environment paths.

*   **File Upload Naming Conventions:**
    When using a file explorer input (a `CHAR` field with the explorer flag) in the Web interface, the system automatically renames the uploaded file to a unique temporary name within the `TMP` folder for security and collision prevention. The original local path and filename selected by the user are not preserved or accessible via standard SDK methods once the file is uploaded to the server.

*   **Handling Non-Standard Characters in Paths:**
    When using `EXECUTE COPYFILE` in the Web interface, ensure that file paths do not rely on legacy Windows drive mapping. Additionally, be aware that special characters or specific language encodings (such as Hebrew) in file paths may cause failures if the path is not correctly resolved within the supported system directories.
<!-- ADDED END -->
<!-- ADDED START -->
### Common Issues and Solutions

*   **Hardcoded Relative Paths:** In Priority Cloud, you cannot assume folder locations using relative strings like `../../tmp/`. This often results in "Failure to open print file" or "Could not find a part of the path" errors. Always use the `sql.tmpfile` variable or the `SYSPATH` function to resolve valid system paths.
    ```sql
    /* INCORRECT: May fail in Cloud */
    :PDFFILE = STRCAT('../../tmp/', :_IVNUM, '.pdf');

    /* CORRECT: Environment-agnostic */
    :PDFFILE = STRCAT(SYSPATH('TMP', 1), :_IVNUM, '.pdf');
    ```

*   **Writing to Attachments via SQL FORMAT:** Attempting to write data directly to an existing attachment path in `system/mail` using the SQL `FORMAT` command is restricted in Cloud environments (Version 24+).
    ```sql
    /* This may trigger "Failure to open print file" in Cloud */
    SELECT '1' FROM DUMMY FORMAT '../../system/mail/24/6/b/p/rix44g/test.txt';
    ```
    **Solution:** Write to a temporary file first, then use `EXECUTE COPYFILE` to move the data to the target attachment path.

*   **Case Sensitivity and Network Paths:** Priority Cloud environments (often hosted on AWS/Linux backends) are case-sensitive. Ensure file names and paths use lowercase letters where required. Additionally, traditional network paths (e.g., `P:\scans\`) are inaccessible; use the FilesAPI or RestAPI for external file integrations.

*   **External Executables (.EXE):** External programs running in the Cloud environment often fail when using relative paths. Ensure the executable is programmed to accept absolute paths passed from Priority, and ensure any custom DLLs or binaries in `BIN95` are included in your installation revisions to prevent them from being deleted during environment updates.

*   **Accessing System Directories:** Direct access to `SYSTEM` or `MAIL` via WINDBI or external tools is restricted in Cloud. For file transfers, use the `system/sync` folder and the `SYSPATH('SYNC', 1)` function.
<!-- ADDED END -->
### system/sync Folder

- Available on public cloud installations.
- Accessible by SFTP for external file uploads.
- All files and folders must be lowercase.
- COPYFILE automatically converts names to lowercase and creates subdirectories as needed.

---

## Priority Lite and Dashboards

### Structure of HTML Procedures

Two essential differences from regular procedures:
- Reports can only be displayed in an INPUT step.
- The procedure stops at each INPUT step (generating an HTML page) and continues when the user clicks Go.

### Display Reports

1. Generate the report in a REPORT step.
2. Include an additional parameter of ASCII type with value `OUTPUT` (no quotes).
3. Use the same parameter in a later INPUT step without any value.

There is no limit to the number of reports in a single INPUT step.

### Retain Variable Values

Since the procedure stops and starts, link files and variables disappear at each interruption. To retain a variable:
1. Define it as a procedure parameter.
2. Include it as a parameter in the INPUT step.

Values are stored in a hidden section of the HTML page and returned when the procedure resumes.

### User Identification

| Internet Access Value | Meaning |
|---|---|
| Y | All (customers, vendors, internal users) |
| T | Walk-in customers (Storefront) |
| U | Internal users only |
| I | No privilege checks |

Use `SQL.WEBID` to identify the user. When logging in with e-mail, it receives `PHONEBOOK.PHONE`. For internal users logging in with username, it receives `USERS.USER * -1`.

### Input Options

#### Procedures as Input Screens

Load data into Priority via an interface using the form load utility:

```sql
LINK GENERALLOAD TO :$.LNK;
INSERT INTO GENERALLOAD (LINE,RECORDTYPE,...) VALUES(...);
EXECUTE INTERFACE 'MYINTERFACE', SQL.TMPFILE, '-L', :$.LNK;
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE USER = ATOI(RSTRIND(SQL.CLIENTID,1,9))
AND TYPE = 'i' AND LINE = 1;
ERRMSG1 WHERE EXISTS (SELECT 'X' FROM GENERALLOAD
WHERE LOADED <> 'Y' AND LINE > 0);
UNLINK GENERALLOAD;
```

#### Input Validation

Add an SQL check (step query) to the INPUT step. On ERRMSG (that does not fail), the same HTML page is re-displayed with the error message.

Use `:HTMLGOTO` to send the procedure back to an earlier step before re-displaying.

#### Add Explanatory Text

Use the standard `HTMLTEXT` report in a REPORT step before INPUT. Record text in the **Set Text for Internet Screens** form.

#### Input of Attachments

Use a CHAR parameter with `Y` in the Browse Button column of the Procedure Parameter Extension form.

### Define a Base Page

Run **Create HTML Pg for Step** (Action from Procedure Steps form). The file is saved as `PROCNAME-NN.htm` in `system\html`.

To insert document header as page title:
```html
<TITLE><!--| Priority Title |--></TITLE>
```

To insert a procedure message:
```html
<!--| Priority Message (WWWDOCUMENTS_Q 5) |-->
```

**Important:** Re-create the base page whenever you add a new report or input parameter.

### Dashboard Procedure Types

| Rep/Wizard/Dashboard Value | Type | Description |
|---|---|---|
| D | Basic Dashboard | Live data, single window, no internal procedures |
| d | Multi-part Dashboard (internal) | Web parts within a main Dashboard |
| p | Portlet | Live data on the home page |
| CRM | CRM Dashboard | Special basic Dashboard for CRM data |

### Create a Multi-Part Dashboard

1. Copy an existing procedure (e.g., `WWWDB_SERVICEMNGR`).
2. In the HTML pages, replace the procedure name in the `DashboardLoad()` call.
3. Attach desired internal procedures (value `d`).

---

## BPM (Business Process Management) Creation

### Overview

Create a BPM status system for a new document (e.g., `XXXX_MYDOC`) by following these steps in order:

1. Create the statuses table
2. Create the statuses form
3. Modify the document form
4. Enable document tracking (optional)
5. Update the STATUSTYPES table
6. Create necessary interfaces
7. Create the BPM chart procedure
8. Debug the BPM
9. Insert the initial status

**Notes:**
- BPM flow charts cannot be created for standard forms.
- A BPM can only be created for an upper-level form.
- The first two keys of the base table must be: (1) an autounique key, (2) a unique key of CHAR or INT type.

<!-- ADDED START -->
### Common Issues and Solutions

**Custom Logic in BPM Flow Chart Designer**
*   **Problem:** Attempting to trigger custom warning messages (e.g., `CHECK-FIELD`, `PRE-UPDATE`, or `POST-UPDATE`) directly within the BPM Flow Chart designer interface when a status property is selected.
*   **Solution:** It is not possible to embed or trigger custom code/messages within the BPM Flow Chart designer interface itself. Such logic must be handled via standard form triggers or procedures linked to the status change.

**Developing BPM for Standard Forms**
*   **Problem:** Developers often inquire about creating custom BPM flows for standard Priority forms (e.g., Equipment Cards) despite documentation restrictions.
*   **Solution:** While technically possible to develop a custom BPM for a standard form, it is strongly discouraged. If Priority Software releases a standard BPM for that form in a future version, it will create a conflict with your customization.

**Cross-Document Updates via BPM**
*   **Problem:** Updating fields in a parent or linked document (e.g., a Purchase Order) when a related document (e.g., a Purchase Invoice) transitions to a specific BPM status.
*   **Solution:** This logic should be implemented using BPM triggers or custom procedures. The BPM system can be configured to execute code upon entering a specific status, which can then perform updates on related tables using standard SQL or SDK commands.
<!-- ADDED END -->
### Step 1: Create the Statuses Table

Create table `XXXX_MYDOCSTATS` (type 0, small table) with columns:

| Column | Type | Width | Title |
|---|---|---|---|
| MYDOCSTAT | INT | 13 | Status (ID) |
| STATDES | CHAR | 12 | Status |
| SORT | INT | 3 | Display Order |
| INITSTATFLAG | CHAR | 1 | Initial Status |

**Keys:**
- AutoUnique: MYDOCSTAT
- Unique: STATDES

No need to add "Include in ToDo List" or "Inactive Status" flags -- these exist in the DOCSTATUSES table.

### Step 2: Create the Statuses Form

1. Create form `XXXX_MYDOCSTATS` based on `XXXX_MYDOCSTATS` table.
2. Define outer joins:
   - `XXXX_MYDOCSTATS.MYDOCSTAT = DOCSTATUSES.ORIGSTATUSID`
   - `DOCSTATUSES.COLOR = HTMLCOLORS.COLOR`
3. Add form columns: `STATDES`, `INITSTATFLAG`, plus all custom flags.
4. Add from DOCSTATUSES: `DOCOPENED`, `INACTIVE`, optionally `ESTATDES` (use Expression/Condition in Form Column Extension).
5. Add hidden columns: `DOCSTATUS`, `SORT`, `STATUSTYPE` (expression `'PRIV_MYBPM'`), `VCOLORNAME`.
6. Set sort priority 1 on STATDES.

**Required Form Triggers:**

**CHECK-FIELD on INITSTATFLAG:**
```sql
ERRMSG 1 WHERE :$.@ = 'Y' AND EXISTS
(SELECT 'X' FROM XXXX_MYDOCSTATS
WHERE INITSTATFLAG = 'Y' AND MYDOCSTAT <> :$.MYDOCSTAT);
```

**PRE-INSERT/PRE-UPDATE:**
```sql
ERRMSG 2 WHERE :$.INITSTATFLAG = 'Y' AND :$.CHANGEFLAG <> 'Y';
```

**POST-INSERT/POST-UPDATE:**
```sql
INSERT INTO DOCSTATUSES(TYPE,ORIGSTATUSID)
VALUES(:$.STATUSTYPE, :$.MYDOCSTAT);

UPDATE DOCSTATUSES SET STATDES = :$.STATDES,
ESTATDES = :$.ESTATDES,
SORT = :$.SORT, COLOR = :$.VCOLOR, INACTIVE = :$.INACTIVE,
DOCOPENED = :$.DOCOPENED
WHERE TYPE = :$.STATUSTYPE AND ORIGSTATUSID = :$.MYDOCSTAT;
```

**POST-DELETE:**
```sql
DELETE FROM DOCSTATUSES WHERE TYPE = :$.STATUSTYPE
AND ORIGSTATUSID = :$.MYDOCSTAT;
```

**PRE-FORM:**
```sql
:statustype = 'PRIV_MYBPM';
:KEYSTROKES = '*{Exit}';
```

**POST-FORM:**
```sql
ERRMSG 4 WHERE NOT EXISTS
(SELECT 'X' FROM XXXX_MYDOCSTATS WHERE INITSTATFLAG = 'Y');
```

**PRE-INS-UPD-DEL (prevent manual changes):**
```sql
ERRMSG 17 WHERE :FORM_INTERFACE <> 1;
```

### Step 3: Modify the Document Form

#### Add "Assigned to" Column

1. Add `OWNER` (INT, 13) to the MYDOC table.
2. Add form column joined: `MYDOC.OWNER = USERS.USER`
3. Add `OWNERLOGIN` from USERS.USERLOGIN, revised title "Assigned to", mandatory (Type M).
4. Add messages 400 (status change alert), 401 (time-based alert), 402 (document type description).

#### Add Status Column

1. Add `MYDOCSTAT` (INT, 13) to the MYDOC table.
2. Add form columns: MYDOCSTAT (joined), STATDES (mandatory), STATUSTYPE (calculated, expression `'PRIV_MYBPM'`).
3. Add POST-FIELD triggers for status handling and initial status assignment.
4. Add POST-INSERT/POST-UPDATE:
```sql
GOTO 51 WHERE :$.MYDOCSTAT = :$1.MYDOCSTAT;
:doc = :$.MYDOC;
:status = :$.MYDOCSTAT;
:statustype = 'PRIV_MYBPM';
#INCLUDE STATUSAUTOMAIL/SendStatusMail
LABEL 51;
```

#### Connect to ToDo List

1. Add hidden column `NSCUST` (MYDOC, MYDOC).
2. Add POST-FIELD triggers to copy values between MYDOC and NSCUST.
3. Link `DOCTODOLISTLOG` and `DOCTODOLIST` as sub-levels.
4. Insert into ZOOMCOLUMNS for form activation from ToDo List:
```sql
INSERT INTO ZOOMCOLUMNS(NAME, TONAME, POS)
VALUES('TODOREF', 'MYDOCNAME', X);
```
5. Add POST-DELETE trigger to clean TODOLIST:
```sql
DELETE FROM TODOLIST WHERE TYPE = 'PRIV_MYBPM' AND IV = :$.MYDOC;
```

### Step 4: Enable Document Tracking (Optional)

Add hidden columns to the form:
- `FOLLOWUPIV` (MYDOC, MYDOC) with outer join to FOLLOWUPLIST.
- `FOLLOWUPTYPE` (TYPE, FOLLOWUPLIST) -- Column Type CHAR.
- `FOLLOWUPUSER` (USER, FOLLOWUPLIST) -- Expression SQL.USER.

### Step 5: Update the STATUSTYPES Table

Find required values using SELECT queries, then insert:

```sql
INSERT INTO STATUSTYPES (TYPE, DOCEXEC, STATEXEC, PROCEXEC,
STATCNAME, DOCCNAME, DOCNOCNAME, OWNERCNAME, INITSTATCNAME,
DOCDATENAME, TEXTEXEC, TEXT2EXEC, LOGEXEC)
VALUES('PRIV_MYBPM', DOCEXEC, STATEXEC, PROCEXEC, 'MYDOCSTAT',
'MYDOC', 'MYDOCNAME', 'OWNERLOGIN', 'INITSTATFLAG',
'DOCDATENAME', TEXTEXEC, TEXT2EXEC, LOGEXEC);
```

### Step 6: Create Interfaces

#### BPM Interface

In Form Load Designer:
- Load Name: `BPMPRIV_MYBPM` (BPM + STATUSTYPE)
- Load Table: `GENERALLOAD`
- Record Size: `500`
- Forms to be Downloaded: `XXXX_MYDOCSTATS`, Code `1`

#### STATUSMAIL Interface

In Form Load Designer:
- Load Name: `STATUSMAILPRIV_MYBPM`
- Load Table: `GENERALLOAD`
- Record Size: `500`, flag Ignore Warnings
- Form: `XXXX_MYDOC`, Code `1`
- Column mapping: `INT1`=MYDOC(1), `TEXT1`=OWNERLOGIN(2), `TEXT2`=STATDES(3)

### Step 7: Create BPM Chart Procedure

Create procedure `XXXX_VISMYDOCSTATS`:

| Step | Entity Name | Type | Details |
|---|---|---|---|
| 5 | SQLI | C | Query: `#INCLUDE WEBCONST/NotFromJava` |
| 10 | BPM | C | Parameter: CHR, Pos 10, Width 20, Value PRIV_MYBPM, Type CHAR |
| 90 | END | B | |
| 91 | XXXX_MYDOCSTATS | F | |

### Step 8: Debug the BPM

```
BPM StatusType -g debugfile
```

**Example:**
```
BPM O -g ..\..\bpm_O.dbg
```

### Step 9: Insert Initial Status

```sql
:INITSTAT = 'Initial Stat';
:STATUSTYPE = 'PRIV_MYBPM';
INSERT INTO XXXX_MYDOCSTATS
(MYDOCSTAT,STATDES,INITSTATFLAG,CHANGEFLAG)
VALUES(-1,:INITSTAT,'Y','Y');
INSERT INTO DOCSTATUSES (ORIGSTATUSID,TYPE,STATDES, NEWDOCFLAG)
VALUES(-1, :STATUSTYPE, :INITSTAT,'Y');
```

---

## Web SDK Common Issues

Real-world issues and solutions discovered from Priority service calls related to the Web SDK.

### CORS Configuration

CORS (Cross-Origin Resource Sharing) errors occur when making Web SDK requests from a domain different from the Priority server.

- **Priority does not have a built-in CORS configuration UI.** CORS headers must be configured directly on the IIS web server hosting Priority.
- Install and configure the **IIS CORS Module** on the Priority application server.
- This is a standard web infrastructure task — consult your IT/System administrators or an IIS expert.
- The error typically appears as: `No 'Access-Control-Allow-Origin' header is present on the requested resource`.

### Connection and Licensing

- **Required module:** The API module must be purchased to use the Web SDK.
- **URL parameter:** Use the URL of your Priority web interface (e.g., `https://server/alias`). For private cloud, use the base path to the WCF service, not the public AWS URL.
- **tabulaini:** Use `tabula.ini` (or `tabMOB.ini` for mobile/PAT access in some environments).
- **profile (company):** The company name from the Companies form.
- **language:** Numeric code — `1` for Hebrew, `3` for English.
- **PAT Authentication:** Use the generated token as username and the literal string `"PAT"` (uppercase) as the password. Avoid special characters in passwords.
- **Password expiry:** Hardcoded credentials can break when passwords expire due to rotation policies (e.g., 180-day). Use Personal Access Tokens (PAT) to avoid this.
- **Cloud development:** You can develop private applications against Priority Cloud using a user with `tabula` (super-user/developer) permissions.
- **Custom fields not visible via API:** Refresh the Redis cache. From version 22.0+, users can run data initialization themselves.
- **Identity Management:** If an Identity Management module is installed, different connection handling may be required.
- **Priority Zoom:** Does not support the API module or SDK development — must upgrade to full Priority ERP.

### Report Execution with Formats

Running reports and document procedures via the Web SDK:

- **Selecting report format:** Use `proc.reportOptions(formatIndex, formatId)` to select a specific format. Example:
  ```javascript
  procedure = await procedure.proc.reportOptions(1, -101); // Select 'Basic' format
  ```
- **Getting document output URL:** Use `documentOptions` after procedure execution to retrieve the file URL.
- **All mandatory input fields required:** Even fields with defaults in the ERP must be provided in the `inputFields` step. Values must match the **display string** in the login language (e.g., `'לפי מספר ההזמנה'`), not the internal integer value.
  ```javascript
  var data = {EditFields: [
    {field: 1, op: 0, value: 'PO23000462'},
    {field: 2, op: 0, value: 'לפי מספר ההזמנה'}
  ]};
  ```
- **`displayURL` undefined:** If `displayURL` is undefined after running a document procedure (e.g., `WWWSHOWPORDER`), check that all mandatory input fields are provided with correct display-string values.
- **Ionic package:** The Priority Ionic React package is no longer maintained. Use React Native or another framework instead.

### Form Procedures List

- **Retrieving associated procedures:** There is currently no documented Web SDK method to retrieve the list of procedures associated with a specific form. This is a known gap in the SDK documentation.

### Search and Filtering

- **Case-sensitive search:** Web SDK search may be case-sensitive. Verify the `ignore case` parameter in your SDK call. Behavior may vary on private forms.
- **`getRows` returns undefined after filter:** If `getRows` returns `undefined` after applying `setSearchFilter`, verify the filter object structure and SDK version.
- **Extra/duplicate rows:** Discrepancies between Priority UI and SDK row counts may indicate configuration or licensing issues.
- **Long filter values:** Filtering by very long strings (e.g., long email addresses) may fail in older versions. Upgrade Priority to resolve.
- **`getFormRows` pagination error:** Starting from a high row offset (e.g., row 40) in certain forms like CUSTOMERS may trigger errors about parent form requirements. This is a known issue in older versions.

### Procedure Execution

- **Retrieving new record ID:** After running a procedure that creates a record (e.g., Delivery Note), use `formStart`/`activateStart` return values or `documentOptions` to get the output file URL.
  ```javascript
  const form = await priority.formStart('ORDERS', onError, onSuccess, '', 1);
  ```
- **HTTP 500 from `activateStart`:** Often resolved by updating the Priority `bin95` folder and reinstalling the application server.
- **"supported is not procedure step" error:** Non-standard error from external automation systems — verify the SDK/API call syntax and consult Priority support.
- **Date range filters fail:** Procedures using "Between" date filters may fail via SDK but work in desktop. Update `bin95` and the `priority-web-sdk` npm package.

### Text Display and Encoding

- **Reversed Hebrew text:** Text from text forms (e.g., PARTTEXT) may appear reversed (visual vs. logical Hebrew) in older versions (pre-23.1). Update BIN to latest or upgrade to 23.1+.
- **Corrupted text in procedures:** Custom procedures displaying messages with links may show reversed text. Try recreating the form/procedure or upgrade the environment.
- **HTML tags in messages:** Concatenated messages in PAR1 may render with unexpected HTML tags in older versions. Upgrade the environment to fix.
- **F6 text editor encoding:** Hebrew characters may appear garbled in the F6 code viewer — check system version and encoding settings.

### Performance and Latency

- **Slow `getRows` (10-12 seconds for few records):** If the Priority application itself is fast but SDK calls are slow, the bottleneck is likely in the WCF (IIS) layer. Use the "Work Rate Test" (בדיקת קצב עבודה) to diagnose, and have IT investigate IIS performance.

### Documentation

- **SDK documentation is centralized on GitHub** and always reflects the latest version. Version-specific features are marked with minimum version indicators.
- **No separate per-version SDK documents** since version 22.0+. The GitHub docs replace the old PDF/Xpert documentation.
- **REST API documentation** is included in the GitHub SDK docs.
- **No video/webinar materials** currently exist for the Web SDK.

### Macros

- **Triggering macros programmatically:** Macros can be triggered via Business Rules, BPM, or the REST API. For specific syntax on private triggers, consult Priority professional services.
