# Debugging, Optimization & Revisions Reference

## Table of Contents

- [Debug Tools](#debug-tools)
  - [Debug a Form](#debug-a-form)
  - [Debug a Procedure](#debug-a-procedure)
  - [Debug a Priority Lite Procedure](#debug-a-priority-lite-procedure-windows-only)
  - [Debug an Interface (Form Load)](#debug-an-interface-form-load)
  - [Debug a Table Load (DBLOAD)](#debug-a-table-load-dbload)
  - [Debug a Simple Report](#debug-a-simple-report)
- [Optimization](#optimization)
  - [Table Access Methods](#table-access-methods)
- [Advanced Debugging (Database-Level Tracing)](#advanced-debugging-database-level-tracing)
- [Logging](#logging)
  - [Message Severity Levels](#message-severity-levels)
  - [Use in Procedures](#use-in-procedures)
  - [Tabula.ini Configuration](#tabulaini-configuration)
- [Revisions and Customizations](#revisions-and-customizations)
  - [Create Version Revisions](#create-version-revisions)
  - [Modification Codes](#modification-codes)
  - [TAKEWORDTMPL Details](#takewordtmpl-details)
  - [TAKEHELP Details](#takehelp-details)
  - [Tips for Working with Revisions](#tips-for-working-with-revisions)
  - [Shell File Format and Internals](#shell-file-format-and-internals)
  - [Track Changes to Queries](#track-changes-to-queries)
  - [Install the Revision](#install-the-revision)
  - [Language Dictionaries](#language-dictionaries)
- [VSCode Priority Dev Tools Extension](#vscode-priority-dev-tools-extension)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Setup](#setup)
  - [Use the Extension](#use-the-extension)
  - [Use WINDBI in VSCode](#use-windbi-in-vscode)
- [HEAVYQUERY Performance Monitoring](#heavyquery-performance-monitoring)
  - [Requirements](#requirements-1)
  - [Setup](#setup-1)
  - [Usage](#usage)
  - [Best Practices](#best-practices)
  - [Limitations](#limitations)

---

## Debug Tools

Priority provides debug mode for forms, procedures, interfaces, and reports. When executed in debug mode, SQL queries, server responses, variables, and more are recorded to a specified file.

**Important:** Debug commands do not work when the `DEBUGRESTRICTED` system constant is set to `1`. In freshly installed systems the default is `1`, so change it to `0` to use debugging tools.

### Debug a Form

**Web interface:**
```
FORM_NAME -trc debug_file
```

**Windows interface:**
```
WINFORM FORM_NAME -trc debug_file
```

**Examples:**
```
WINFORM ORDERS -trc ..\..\orders.dbg           /* Windows */
ORDERS -trc c:\tmp\orders.dbg                  /* Web interface */
```

**Note:** The older `-g` flag can be used instead of `-trc`, but `-trc` provides more information and is better organized for debugging.

### Debug a Procedure

**Windows interface:**
```
WINPROC -P PROCNAME -trc debug_file
```

**Web interface:**
```
PROCNAME.P -trc debug_file
```

**Examples:**
```
WINPROC -P WWWSHOWORDER -trc ..\..\wwwshoword.dbg    /* Windows */
WWWSHOWORDER.P -trc c:\tmp\wwwshoword.dbg             /* Web interface */
```

Run a procedure in debug mode from within the Procedure Generator via an Action.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Incomplete Debug Logs:**
    If debug files (using the `-trc` flag) show only parameters but omit the execution logic and code, it may indicate an issue with the system BIN files.
    **Solution:** Update the environment's BIN version to the latest release (e.g., version 25.0 or higher).

*   **Debugging Procedures in Task Scheduler (WINRUN):**
    Procedures that run correctly in the UI but fail or hang when executed via the Task Scheduler should be debugged using the trace flag within the command line string.
    **Solution:** Append the `-trc` flag to the `WINACTIV` call.
    **Example:**
    ```sql
    C:\Priority\bin.95\winrun "" username password C:\Priority\system\prep company WINACTIV -P PROCNAME -trc debug.txt
    ```

*   **Debugging Direct Form Actions:**
    If a procedure hangs when triggered as a direct action from a form but works via `WINPROC`, standard procedure debugging may not capture the freeze.
    **Solution:** Use the `SSDEBUG` command to perform a system-wide trace that captures all activity, including form-level triggers.

*   **Permission-Related Failures After Migration:**
    Custom procedures may fail for non-administrative users after a system upgrade or migration, often resulting in immediate termination or "Illegal option" errors.
    **Solution:** Ensure the system BIN is updated (specifically BIN 95 or later) and check the `server.log` in the Priority log directory for detailed permission errors.

*   **Debugging Revision Installations:**
    When troubleshooting a revision or shell installation script, you cannot easily run the standard installation shell in debug mode.
    **Solution:** Run the update through the **Revision Generator** (Form: `P0762000047`), which provides a built-in debug option.

*   **Cross-Pollination of Errors:**
    If a procedure triggers an error message belonging to a completely different, unrelated procedure, it often indicates a "leak" caused by copying report generator programs or incorrect security settings.
    **Solution:** Uncheck the "Secured" flag on the problematic procedure and use database-level tracing (TRC) combined with `WINPROC` dumps to identify the source of the conflict.
<!-- ADDED END -->
### Debug a Priority Lite Procedure (Windows Only)

```
WINHTMLH PROCNAME -trc debug_file
```

**Example:**
```
WINHTMLH WWWORDERS -trc ..\..\wwworders.dbg
```

### Debug an Interface (Form Load)

Include `-debug` and the debug file name as additional parameters:

```sql
EXECUTE INTERFACE LOADORDERS SQL.TMPFILE, '-debug', '..\..\tmp\dbg.txt';
```

### Debug a Table Load (DBLOAD)

Include `-g` and the debug file name:

```sql
EXECUTE DBLOAD '-L', 'loadname', '-g', 'debug_file';
```

### Debug a Simple Report

Use the SQL Development (WINDBI) program. From the Dump menu, select Report and record the internal name of the report. This outputs the full SQL query for the report.

Run a report in debug mode from within the Report Generator via an Action.

<!-- ADDED START -->

### Common Issues and Solutions

*   **Report Fails to Execute in Specific Modules (e.g., TAPI):**
    If a report (especially an automatic one) fails to trigger or respond within a specific module or interface, first test the report execution within the standard Windows interface. This helps isolate whether the issue lies within the report logic itself or the integration/trigger mechanism of the specific module.

*   **Data Missing for Specific Records or Families:**
    When a report fails to display expected data for certain parameters (such as a specific product family), verify the underlying logic filters. For example, reports often filter by status flags (e.g., "Production Finished"). If the source records (such as Work Orders) were updated or finished *after* the report was generated, they will not appear in the results.

*   **Report Fails on Large Datasets but Works for Single Records:**
    If a private or custom report works for a single record (e.g., one customer) but fails or throws an error when run for all records, investigate potential data inconsistencies or calculation overflows. System upgrades can sometimes expose legacy logic that cannot handle specific record values or nulls when processing bulk data.

<!-- ADDED END -->
## Optimization

After customizing any entity, check optimization using WINDBI (Optimization menu):

- **After adding form columns** -- check form optimization
- **After creating/customizing a report** -- check report optimization
- **For any SQL query** -- check query optimization (also available via Execute > + optimizer or + execution)

### Table Access Methods

| Access Method | Description |
|---|---|
| **Direct** | One specific record retrieved |
| **Skip** | Some records retrieved according to keys |
| **Sequential** | All records retrieved |

**Rules of thumb:**
- In form optimization, only the form's base table should have sequential access; all others should be direct.
- For sub-level forms, the base table should have skip access.
- Avoid sequential access to tables -- it usually means slow queries.

---

## Advanced Debugging (Database-Level Tracing)

Trace all queries sent to the database engine:

1. Set the trace directory from command line:
   - **SQL Server:** `SET SSDEBUG=C:\tmp`
   - **Oracle:** `SET ORADEBUG=C:\tmp`
2. Open Priority from the same command line.
3. All queries are written to trace files in the specified folder.

**Note:** Specify an existing folder.

<!-- ADDED START -->
### Common Issues and Solutions

**Tracing Errors in Sub-Interfaces and Triggers**
When a SQL error occurs within a sub-interface or a POST-INSERT trigger, standard tracing might miss the specific process ID (PID) responsible for the failure.
*   **Solution:** Use SQL Profiler filtered by **LoginName** rather than a specific PID. This ensures you capture queries from internal processes spawned by the main procedure. Cross-reference the `server.log` to match the failing PID with the Profiler results.
*   **Example:**
    ```sql
    /* Error occurring during this call may spawn a different PID */
    EXECUTE INTERFACE 'UPDATEFNCPART', SQL.TMPFILE, '-nl', '-L', :TMPBUF25;
    ```

**Handling Data Format Errors in SQL Subqueries**
SQL errors (such as conversion failures) can occur when using string manipulation functions like `STRIND` inside conditions, especially when the column contains inconsistent data formats.
*   **Solution:** Replace `STRIND` with `SUBSTR` for better compatibility or wrap the logic with an `ISNUMERIC` check. If the error is elusive, use SQL Profiler to view the exact values being passed to the database engine.
*   **Example:**
    ```sql
    /* Potential failure point: ATOD conversion of a substring */
    SELECT VALUE FROM USERGANTTLASTS 
    WHERE EXEC = (SELECT EXEC FROM EXEC WHERE ENAME = :ENAME AND TYPE ='P') 
    AND ATOD(STRIND(NAME,3,12),'YYYYMMDDhhmm') < SQL.DATE - 5 FORMAT;
    ```

**Performance Bottlenecks in Custom Triggers**
Significant slowness when opening forms (e.g., Invoices) is often caused by custom triggers calling complex logic like credit limit (`OBLIGO`) checks.
*   **Solution:** Use **Process Monitor (ProcMon)** with the `WINFORM.PDB` symbol file configured. This allows you to generate a process dump and stack trace to identify exactly which function call is hanging.

**Oracle-Based Shell Update Failures**
Shell update files (SHELL) may fail on Oracle systems without logging clear errors in `setup.log`.
*   **Solution:** Check for the generation of `.DUMP` files in the trace directory. These files, combined with the system version details, are required to analyze failures in update scripts that do not report standard SQL errors.
<!-- ADDED END -->
## Logging

### Message Severity Levels

| Severity Level | Value |
|---|---|
| JOURNAL_DEBUG | 1 |
| JOURNAL_TRACE | 2 |
| JOURNAL_INFO | 3 |
| JOURNAL_WARNING | 4 |
| JOURNAL_ERROR | 5 |
| JOURNAL_FATAL | 6 |

### Use in Procedures

```sql
EXECUTE JOURNALP 'level', 'message';
```

**Example:**
```sql
:MSG = "Statement failed to execute. Please help.";
:SEV = 4;
/* ... some SQL statements that may fail ... */
/* on failure: */
EXECUTE JOURNALP :SEV, :MSG;
```

### Tabula.ini Configuration

Define the `[Log]` section in `tabula.ini`:

```ini
[Log]
Server Path='path_to_server_log'
Server Level='minimum_level'
Client Path='path_to_client_log'
Client Level='minimum_level'
```

- Specifying `0` is equivalent to `5` (records levels 5 and 6 only).
- To record all severities, specify `1`.

**Disable buffering** (to see log writes immediately):
```ini
Server Buffered=0
```

---

<!-- ADDED START -->
### Common Issues and Solutions

**Logs Not Updating in Real-Time**
*   **Problem:** WSCLIENT requests, responses, or specific `JOURNALP` entries do not appear in the server log immediately, even when the log level is set to `1`.
*   **Solution:** Set `Server Buffered=0` in the `[Log]` section of `tabula.ini`. This disables write buffering and ensures entries are committed to the log file as they occur.

**License Errors in Server Logs (API/EDI)**
*   **Problem:** Automated interfaces (e.g., EDI or private developments) fail with license-related errors in the log, even if the API module is active.
*   **Solution:** Reinstall the Priority license on the server. This often occurs when a specific form or entity is not correctly authorized under the application context (e.g., `APPEDI`).
*   **Log Example:**
    ```text
    [ERROR][SERVERNAME][PID][INTERFAC.exe][licuser.q/TabulaLicenseAllowed]: entity AFORM.F is not allowed in ASAPI(APPEDI)
    ```

**Missing Task Opener or MDAC Errors**
*   **Problem:** Reports fail when sending via email, often accompanied by "Missing task opener name" errors and "deprecated MDAC" warnings in the server log.
*   **Solution:** Update the Priority BIN files and ensure the Microsoft OLEDB Driver for SQL Server (version 18.2 or higher) is installed. Modern versions of Priority require the OLEDB Provider to replace outdated MDAC components.
<!-- ADDED END -->
## Revisions and Customizations

### Create Version Revisions

1. Enter the **Version Revisions** form (System Management > Revisions). Fill in a description; a number is assigned automatically.
2. Enter the **Revision Steps** sub-level. Flag the modifications to include. The order determines the upgrade file sequence.
3. Run **Prepare Upgrade** by Action from the Version Revisions form. The shell file is saved as `NN.sh` in `system\upgrades`.

### Modification Codes

| Code | Description |
|---|---|
| DBI | Update of database (tables, columns, keys) |
| DELDIRECTACT | Deletion of an Action |
| DELFORMCOL | Deletion of a form column |
| DELFORMLINK | Deletion of form/sub-level link |
| DELMENULINK | Deletion of menu/item link |
| DELPACKENT | Deletion of entire system package |
| DELPACKEXEC | Deletion of package/entity link |
| DELPROCMSG | Deletion of a procedure message |
| DELPROCSTEP | Deletion of a procedure step |
| DELREPCOL | Deletion of a report column |
| DELTRIG | Deletion of a form trigger |
| DELTRIGMSG | Deletion of a trigger message |
| DELWORDTMPL | Deletion of a Word template |
| TAKEDIRECTACT | Link an Action to a form |
| TAKEENTHEADER | Revision to entity attributes (title, default design) |
| TAKEEXTMSG | Addition/revision of compiled program message |
| TAKEFORMCOL | Revision to a form column (title, sorting, joins) |
| TAKEFORMLINK | Linking of a form to its sub-level |
| TAKEMENULINK | Linkage of a menu item to its menu |
| TAKEOUTPUTTITLE | Addition/revision of report output title |
| TAKEPACKENT | Addition/revision of entire system package |
| TAKEPACKEXEC | Addition/revision of entity in relation to a package |
| TAKEPACKTITLE | Revision to system package title |
| TAKEPROCMSG | Addition/revision of a procedure message |
| TAKEPROCSTEP | Addition/revision of a procedure step |
| TAKEREPCOL | Revision to a report column |
| TAKESINGLEENT | Addition/revision of an entire entity |
| TAKETRIG | Addition/revision of a form trigger |
| TAKETRIGMSG | Addition/revision of a trigger message |
| TAKEWORDTMPL | Addition/revision of a Word template |
| TAKEHELP | Addition/revision of online help |

#### TAKEMENULINK — linking a custom menu under a system parent

To deploy a custom menu as a child of an existing system menu, add an UPGNOTES entry:

| Field | Value |
|-------|-------|
| UPGCODE | `TAKEMENULINK` |
| ENAME | `<PARENT_MENU>_MODULE` (see table below) |
| SONENAME | `<child menu name>` |
| SONTYPE | `M` |
| BOUND | `Y` |

**Common parent menu ENAME values:**

| System menu | ENAME to use |
|-------------|--------------|
| System Management | `SYSMAINTEN_MODULE` |
| System Data | `SYSDATA_MODULE` |

The canonical naming pattern is `<PARENT_MENU_NAME>_MODULE`. Using the plain parent
name (e.g., `SYSMAINTEN` without `_MODULE`) triggers the form's CHECK-FIELD trigger,
which loads the entire menu tree and causes a bridge timeout.

**Do NOT use `TAKEDIRECTACT` for menu-to-submenu links.** `TAKEDIRECTACT` is for
"a form has a direct activation calling a procedure" — a different concept — and will
fail or timeout when applied to menu linkage.

Example UPGNOTES sequence for a new menu under System Management:

```
ORD=1  UPGCODE=TAKESINGLEENT  ENAME=TGML_MYMENU  TYPE=M  BOUND=Y
ORD=2  UPGCODE=TAKEMENULINK   ENAME=SYSMAINTEN_MODULE  SONENAME=TGML_MYMENU  SONTYPE=M  BOUND=Y
```

The `TAKESINGLEENT` for the child menu must appear before the `TAKEMENULINK`.

*(verified: 28 live UPGNOTES rows with UPGTYPE=25 confirm `_MODULE` suffix on top-level system parents; SONTYPE varies M/F/P/R)*

### Choosing the Right UPGCODE (Decision Guide)

See `deployment.md` § "Choosing the right UPGCODE" for the canonical decision table and rationale. Summary: use the most specific UPGCODE per change (`TAKETRIG` for trigger changes, `TAKEFORMCOL` for column changes, etc.); `TAKESINGLEENT` only for brand-new entities.

### Programmatic Revision via WebSDK

When automating shell generation via the WebSDK (e.g., from a VSCode extension):

- Open UPGRADES form, find the oldest unprepared revision
- Open UPGNOTES subform via `startSubForm('UPGNOTES', ...)`
- Insert rows: `newRow()` → `fieldUpdate('UPGCODE', 'TAKETRIG')` → `fieldUpdate('ENAME', ...)` → `fieldUpdate('TYPE', ...)` → `fieldUpdate('BOUND', 'Y')` → `saveRow(0)`
- **Important:** The UPGNOTES form exposes **UPGCODE** (display text like "TAKETRIG"), not UPGTYPE (numeric ID). Use the modification code string directly.
- Subform `endCurrentForm()` may hang on certain forms. Use a timeout and close the parent form if needed (see websdk-examples.js).
- Reopen UPGRADES fresh before running `activateStart('TAKEUPGRADE', 'P', null)` — the form may be in a bad state after subform close timeout.

### Shell File Format and Internals

A prepared `.sh` file contains three types of blocks:

1. **`echo` lines** — progress messages displayed during installation
2. **`DBI << \EOF ... EOF`** — database definition blocks (CREATE TABLE, ALTER TABLE, etc.)
3. **`BRING << \EOF ... EOF`** — binary-coded entity definition blocks

#### BRING Binary Codes

Each line in a BRING block starts with a numeric code identifying the record type:

| Code | Meaning |
|------|---------|
| 3 | Direct activation (Action) link |
| 7 | Procedure step definition |
| 9 | Procedure parameter definition |
| 17 | Entity definition header |
| 28 | SQLI code line |

#### Direct Activations (EXEC table)

The `EXEC` table stores direct activations (Actions) linked to forms. Key columns:

- **TABLE** — the EXEC ID of the parent form (not a table name)
- **ENAME** — the activated entity name
- **TYPE** — entity type: `F` (form), `P` (procedure), `M` (menu)
- **TITLE** — display title of the activation

To query or add direct activations via WebSDK, use `startSubForm(FORMEXEC)` on EFORM after filtering to the parent form.

**Important:** `TAKEDIRECTACT` in a revision requires a companion `TAKESINGLEENT` for the activated entity (`sonEntity`). Without it, INSTITLE fails with "Error linking" because the target entity definition is missing from the shell.

#### UPGTYPES Table

The `UPGTYPES` table maps modification code strings (e.g., `TAKETRIG`, `TAKESINGLEENT`) to their numeric IDs used internally. Query it to translate between the display codes in UPGNOTES and internal IDs.

#### DOWNLOADUPG vs TAKEUPGRADE

Both procedures prepare the upgrade shell, but differ:

- **TAKEUPGRADE** — straightforward; prepares the shell file with no prompts
- **DOWNLOADUPG** — adds two input parameters:
  - "Run INSTITLE?" flag — when set, automatically runs INSTITLE on the output
  - "Lang. Code" — target language code for INSTITLE translation

#### INSTITLE Behavior

- INSTITLE translates entity titles and messages into the target language
- **INSTITLE skips EXEC entries for forms that already exist** in the target environment — new direct activations on existing forms will not be installed. Work around this by adding the EXEC rows manually via DBI or the FORMEXEC subform after installation.

### TAKEWORDTMPL Details

Fill in manually:
- Entity (Form or Procedure) for the Word template.
- Entity Type.
- Message number (negative number from TRIGMSG table).

Query to find template message numbers:
```sql
SELECT * FROM TRIGMSG
WHERE EXEC = (SELECT EXEC FROM EXEC
WHERE ENAME = 'WWWSHOWORDER' AND TYPE = 'P')
AND NUM < 0
FORMAT;
```

### TAKEHELP Details

- Entity and Entity Type are required.
- For forms, specify a specific column; if omitted, help for the entire form and all columns is taken.

### Tips for Working with Revisions

- Do not create a version revision until programming is finished.
- Complete modifications on an entity before linking to TAKESINGLEENT.
- Do not wait more than a working day; prepare upgrades at end of each day.
- Order matters: reports before procedures, interfaces before procedures, DBI before TAKEFORMCOL.
- Never prepare the same upgrade twice; create a new revision instead.
- **TAKESINGLEENT on system forms pulls ALL columns** — use TAKEFORMCOL for specific columns added to system forms to avoid "Missing column" errors on clients with different Priority versions.
- **Custom columns on system tables** added via manual DBI bypass change tracking — TAKEUPGRADE won't auto-generate DBI for them. Add a manual UPGCODE="DBI" entry to UPGNOTES with UPGNOTESTEXT containing the DBI (no `EXEC` prefix, ASCII titles). See "Adding Manual DBI to UPGNOTES" below.

### Adding Manual DBI to UPGNOTES (for untracked table changes)

When a custom column was added to a system table via manual DBI (not through the Table Generator), it won't be included in the upgrade shell automatically. To include it:

1. Open UPGRADES form, navigate to the revision
2. In UPGNOTES subform, add a new row: `UPGCODE=DBI`, `BOUND=Y`, `ORD=1`
3. Open UPGNOTESTEXT subform on that DBI row and write the DBI lines (one line per row, 68-char max):
   ```
   FOR TABLE <tablename>
   INSERT <colname> (<TYPE>, <WIDTH>, '<ASCII title>');
   ```
4. **No `EXEC` prefix** — the shell wraps it in `DBI << \EOF ... EOF` automatically
5. **Use ASCII titles** — Hebrew in UPGNOTESTEXT may cause encoding parse errors
6. Clear `PREPARED` on the revision, then re-run TAKEUPGRADE before DOWNLOADUPG

The DBI block runs before the BRING block in the shell, so the column exists by the time form definitions reference it.

<!-- ADDED START -->
### Common Issues and Solutions

- **Missing Modification Lines in Revision Steps:**
  When a new entity (form, report, etc.) is created, the system initially groups all initial definitions under a single `TAKESINGLEENT` record. Individual modification lines (such as `TAKEFORMCOL`) will only begin to appear in the Revision Steps sub-form after that initial `TAKESINGLEENT` record has been linked to a version revision.

- **Renaming Entities (Reports/Procedures):**
  Renaming an entity does not automatically update the revision script; the system may treat it as a new entity without history. To handle a rename correctly, manually add a `DELENT` command for the old entity name and a `TAKESINGLEENT` command for the new entity name within the revision script. Ensure all menu and form links are updated accordingly.

- **Protecting Custom Interfaces:**
  Custom electronic interfaces (linked via `TAKESINGLEENT`) must use a unique developer prefix. Failure to use a prefix may result in custom interfaces being overwritten or deleted during standard system upgrades.

- **Text Editor Errors After Upgrades:**
  If users encounter a "There are no values to choose" error when opening the Text Editor (F6) for triggers after an upgrade, it often indicates a configuration issue in the Development Center. Verify that the correct constants are defined and perform a "Reprepare Form" on the `EFORM` and `FTRIGTEXT` forms to refresh the display logic.
<!-- ADDED END -->
### Track Changes to Queries

Previous versions of triggers, SQLI steps, and load definitions are available in the **Previous Versions** sub-level form. Use **Track Changes** action to compare versions (additions in blue, deletions in red strikethrough).

**Note:** Only revisions created after Priority version 17.3 appear.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Identifying Entities in Revision Tracking:**
    When reviewing changes in the **Revision Tracking** screen, you may encounter internal entity names that do not match form titles. For example, the entity **ACCOUNTNAMES** refers to the "General Ledger Accounts" report, which is managed via the Report Generator.

*   **Retroactive Revision History:**
    The system does not provide a built-in utility or filter to retroactively populate the **Previous Versions** sub-level for code changes made before the tracking feature was enabled or before version 17.3. Records are only generated forward-looking during the "Prepare Revision" process.

*   **False Positive Revisions:**
    In some versions (notably version 22.0), opening the code editor (F6) and exiting with **ESC** without making any changes may still trigger an update to the digital signature and change log. Be aware that this may incorrectly mark code as modified in the version history even if the logic remains identical.
<!-- ADDED END -->
### Install the Revision

1. (Windows) Open Priority as administrator.
2. Run **System Management > Revisions > Install Upgrade**.
3. Browse to the shell file.

**Caution:** If the revision includes DBI steps, ensure all users exit the system first.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Corrupted Hebrew Text (RTL/LTR Issues):**
    After updating the Priority BIN version, revisions may produce corrupted files where Hebrew text in form columns or report titles appears reversed. This is typically a BIN-level bug related to string handling during compilation.
    **Solution:** Upgrade to a stable BIN version (e.g., 23.1.80 or higher). As a temporary workaround, you can adjust the system constant:
    ```sql
    UPDATE SYSCONST SET VALUE = 0 WHERE NAME = 'UPGTITLES';
    ```

*   **Missing Mandatory Commands:**
    Revisions for reports or forms may fail to install if the script is missing mandatory commands required by the installer logic.
    **Solution:** Ensure the revision script includes the `INSTITLE` command to allow the update process to complete successfully.

*   **Installation on Cloud Environments:**
    Users on Priority Cloud may not have direct RDP or server-level access to the 'upgrades' folder.
    **Solution:** Use the internal system procedure: **System Management > System Maintenance > Periodic Maintenance > Install Revision**. This must be executed by a user with administrator privileges (e.g., 'master').

*   **Concatenated File Failures:**
    Revisions containing multiple concatenated update files may fail in newer versions (v22.1+) even if they worked in older versions.
    **Solution:** This is often caused by character encoding mismatches between the different files in the sequence. Ensure all concatenated files use consistent encoding before compiling the shell.

*   **Truncated Revision Filenames:**
    In some versions, the "Updates Installed" report may truncate or alter the revision filename (e.g., displaying `..078` instead of `2078`) when run from the standard upgrades folder.
    **Solution:** Run the update from a local path (e.g., the Desktop) instead of the server's upgrades folder to ensure the filename is logged correctly in `setup.log`.
<!-- ADDED END -->
<!-- ADDED START -->
### Common Issues and Solutions

*   **Reversed Text in Messages or Shell Files**
    *   **Problem:** After a BIN update, Hebrew text in the "Create Version Revisions" process or the resulting `.sh` file appears reversed (right-to-left instead of left-to-right), and parameters within messages may fail to be identified.
    *   **Solution:** This is typically a bug in specific BIN versions. Ensure your system is updated to BIN version 24.0.37 or higher, where this issue was resolved.

*   **Installing Revisions in Cloud Environments**
    *   **Problem:** Users need to install private developments or custom revisions in a Priority Cloud environment.
    *   **Solution:** Custom developments are supported on Priority Cloud. Users with 'tabula' group permissions should use the **Run Version Update** (Execute Revision) program located under **System Management > System Maintenance > Periodic Maintenance**. If the web interface fails to process the file, contact support to manually execute the shell script on the cloud server.

*   **Revision Installs but Entities are Not Updated**
    *   **Problem:** The installation process appears to complete successfully, but the **Updated Entities** sub-level form is empty and the code/schema changes are not reflected in the system.
    *   **Solution:** Verify the `setup.log` and `server.log` for hidden errors. Ensure the update is executed directly from the server with administrative permissions and verify that the BIN version is compatible with the revision.

*   **Cross-Platform Compatibility (SQL Server to Oracle)**
    *   **Problem:** Uncertainty whether a revision (`.sh` file) developed on a SQL Server environment can be installed on an Oracle-based environment.
    *   **Solution:** Revisions are cross-platform compatible. A shell file built on SQL Server can be installed on Oracle provided the Priority version is the same and all entities, tables, and columns are standardly defined.

*   **Unresolved Identifier Errors After Installation**
    *   **Problem:** Custom procedures fail after a version upgrade or revision installation with "Unresolved identifier" errors.
    *   **Solution:** This usually indicates a missing table link or an outdated revision that does not account for schema changes in the new version. A developer must verify the table aliases and links.
    *   **Example Error:**
        ```sql
        ZUKW_WWWIV_5 report: "", line 13: COUNTRIES1.EEAFLAG Unresolved identifier
        "", line 13: COUNTRIES1.COUNTRYCODE Unresolved
        ```

*   **Transferring Developments Between Servers**
    *   **Problem:** Custom procedures or forms exist in Production but are missing from a newly established Test server.
    *   **Solution:** Use the standard Revision mechanism to package the developments from the source environment and install the resulting shell file on the target server to ensure all dependencies are maintained.
<!-- ADDED END -->
### Language Dictionaries

When installing customizations for non-English systems:

1. Set `UPGTITLES` constant to `0` before programming.
2. After each Prepare Upgrades, run in WINDBI:
   ```sql
   EXECUTE INSTITLE 'fromfile', 'tofile';
   ```
3. For different base language:
   ```sql
   EXECUTE INSTITLE '-l', 'langcode', 'fromfile', 'tofile';
   ```

**Example:**
```sql
EXECUTE INSTITLE '..\..\system\upgrades\34.sh',
'..\..\system\upgrades\34-inst.sh';
```

#### Modify DBI Operations for Other Languages

Replace hardcoded titles with dictionary references:

**New table:**
```sql
CREATE TABLE PRIV_NEWTABLE '[Ktitle : PRIV_NEWTABLE]' 1
COL1(CHAR,3,'[Column: PRIV_NEWTABLE/COL1]')
COL2(CHAR,32,'[Column: PRIV_NEWTABLE/COL2]')
UNIQUE(COL1);
```

**New column:**
```sql
FOR TABLE MYTABLE INSERT MYNEWCOL
(INT,13,'[Column: MYTABLE/MYNEWCOL]');
```

**Change table title:**
```sql
FOR TABLE MYTABLE CHANGE TITLE TO '[Ktitle : MYTABLE]';
```

**Change column title:**
```sql
FOR TABLE MYTABLE COLUMN MYCOL
CHANGE TITLE TO [Column: MYTABLE/MYCOL];
```

---

## VSCode Priority Dev Tools Extension

### Features

- Edit, create, delete form/field triggers
- Edit SQLI steps in procedures
- Syntax check for SQLI
- Code completion (table names, keywords, form fields, #INCLUDE)
- Code snippets for built-in Priority functions
- WINDBI (SQL Development)
- Navigation with breadcrumbs
- "Go to definition" for #INCLUDE and table definitions
- Form and Program preparation
- Code folding and vertical ruler

### Requirements

- Priority Application Server
- Active user in Priority Web
- APPVSCODE application license
- OData service URL
- Visual Studio Code installed

### Setup

1. Add your username to the APPVSCODE application (Personnel File > Applications for License > Users for Application).
2. Create an empty folder on your PC for intermediate WINDBI files.
3. Install the Priority Dev Tools extension.
4. Open the empty folder in VS Code.
5. Press F1, run "Priority: Open Environments Wizard..."
6. Click "Add environment with OData URL".
7. Fill in: Environment name, OData URL, Username, Password.

**Alternative authentication:** Use Personal Access Tokens from the REST Interface Access Tokens form. Enter token as Username and `PAT` as Password.

### Use the Extension

- Click the Priority icon in the Activity Bar to see the Environments Explorer.
- Expand environment to view tables, forms, programs.
- Select an object to open in editor; saving updates Priority.
- F1 for Prepare operations.
- F12 for "Go to definition" on #INCLUDE or table definitions.
- Alt+F12 to peek.
- Ctrl+Space for code completion.

### Use WINDBI in VSCode

- Right-click environment > "New SQLI" to open WINDBI.
- Select company in the Companies panel.
- Run SQLI: click "Run SQLI" button or press Alt+X.
- All WINDBI actions available via right-click on environment name.

<!-- ADDED START -->

### Common Issues and Solutions

#### "Failure to open input file" or "IO Exception: 720005"
This is the most common error when running queries or "Find String" searches. It is typically caused by permission issues or locked files.
*   **Permissions:** Ensure the user has full Read/Write/Modify permissions to the `C:\tmp` directory (or the temp directory defined in `tabula.ini`). A quick test is to try manually renaming the `file_in` file in that folder.
*   **File Locks:** The `file.err` or `file.in` files may be locked by a background `sqli.exe` process from a previous heavy query. Terminate any hanging `sqli` processes via Task Manager to release the files.
*   **Missing Utilities:** Ensure the `PRIORITY\SYSTEM\UTIL` folder exists on the server and contains the latest utility files (e.g., `instag.exe`, `tfgrep.exe`). If missing, download the `util.zip` from the official support portal.

#### Incorrect or "Accumulated" Query Results
If WINDBI shows results from a previous query regardless of what you run:
*   The output buffer file (`file.err`) is likely locked or corrupted.
*   **Solution:** Close WINDBI, delete `file.err` from the Priority directory, and ensure no background `sqli` processes are running before restarting.

#### Missing "Open" and "Save" in Web Interface
*   **Status:** The "Open" and "Save" options under the File menu are currently unavailable in the web-based SQLI editor. These features are exclusive to the Windows client/VSCode environment at this time.

#### Activating the Debugger in Web Environment
To enable and use the WINDBI debugger within the Priority Web interface, run the following command in the SQLI editor:
```sql
WINDBI.P
```

#### "This program must run in a Tabula data directory"
This error occurs when executing SQLI commands via the Web interface if the environment is misconfigured.
*   **Solution:** Verify that the `priority\system\util` directory is populated and that the web server process has sufficient permissions to create temporary input files in the system's TMP folders.

#### Missing Column Headers or Corrupted Characters
If query results display incorrect characters (e.g., '1' or 'L') or are missing headers in version 21.1:
*   **Solution:** Update the `BIN.95` folder to version 21.1.0.69 or higher to resolve display logging errors.

<!-- ADDED END -->
## Claude Code MCP Integration

### Prerequisites and Installation

Install the plugin (one-time):

```bash
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

**Requirements:**
- **VSCode** with the [Priority Dev Tools extension](https://marketplace.visualstudio.com/items?itemName=PrioritySoftware.priority-vscode) — the bridge reads server credentials from its configured environments
- **Claude Code** CLI — the plugin auto-installs the bridge extension and configures the MCP connection on first session start

No separate credential configuration is needed if the Priority Dev Tools extension already has an environment set up. See the main skill file (`SKILL.md` > Installation) for manual credential setup if needed.

### Overview

The integration uses the **priority-dev** MCP server (bridge running inside VSCode), a companion VSCode extension (`priority-claude-bridge`) that exposes tools for reading, writing, and inspecting Priority code directly through the editor.

For form operations (querying forms, running procedures, CRUD) use `websdk_form_action` from the priority-dev bridge. The **priority-gateway** MCP server is available separately but not required for core code development.

### Bridge Tools (priority-dev)

| Tool | Purpose |
|------|---------|
| `get_current_file` | Read the active Priority editor buffer — returns entityType, entityName, stepName, and full SQLI content. Falls back to `textDocuments` when terminal has focus. |
| `write_to_editor` | Write full SQLI content into an open editor buffer. The Priority extension auto-saves to the server. Always send the **complete** step content. |
| `refresh_editor` | Reload the open `priorityfs://` virtual file from the server (after external changes). |
| `run_windbi_command` | Execute any of 38 Priority WINDBI commands. Auto-focuses the Priority editor and auto-fills input dialogs with the `entityName` argument. Results render in the WINDBI webview panel. Compile errors are captured from the extension log. |

### Available WINDBI Commands via run_windbi_command

**Dump / Inspect:**

| Command | What it does |
|---------|-------------|
| `priority.dumpForm` | Full form dump (fields, keys, triggers, cursor) |
| `priority.dumpProcedure` | Full procedure dump (all steps with code) |
| `priority.dumpTable` | Table structure dump |
| `priority.dumpFormCursor` | Form cursor SQL |
| `priority.dumpReport` | Report dump |
| `priority.dumpLoad` | Interface/load dump |

**Display Metadata:**

| Command | What it does |
|---------|-------------|
| `priority.displayTableColumns` | Table columns |
| `priority.displayTableColumnsWithPrecision` | Table columns with precision |
| `priority.displayFormColumns` | Form columns |
| `priority.displayTableKeys` | Table keys |
| `priority.selectAllRowsFromTable` | SELECT * from a table |

**Search:**

| Command | What it does |
|---------|-------------|
| `priority.findStringInAllForms` | Search for text across all forms/procedures |
| `priority.findStringInSingleForm` | Search for text in one form |

**Explain / Optimize:**

| Command | What it does |
|---------|-------------|
| `priority.explainSqliCode` | Explain SQLI (no execution) |
| `priority.explainSqliCodeWithExec` | Explain SQLI with execution |
| `priority.optimizeSql` | SQL optimization |
| `priority.optimizeForm` | Form optimization |
| `priority.optimizeReport` | Report optimization |

**Compile:**

| Command | What it does |
|---------|-------------|
| `priority.prepareForm` | Compile/prepare form |
| `priority.prepareProc` | Compile/prepare procedure |

**Execute:**

> **Preferred:** `run_inline_sqli({ sql, mode: "sqli" | "dbi" })` — direct WCF call, no .pq file, no editor, returns output. Use this for all ad-hoc queries and schema changes. The WINDBI commands below are the legacy path and only needed for interactive workflows.

| Command | What it does |
|---------|-------------|
| `priority.runSqliFile` | Run SQLI file (requires .pq file active) — legacy, prefer `run_inline_sqli` |
| `priority.executeDbi` | Execute DBI — legacy, prefer `run_inline_sqli` with `mode:"dbi"` |
| `priority.createSqliFile` | Create a new temporary SQLI file |
| `priority.executeSqliInAllCompanies` | Run SQLI in all companies |

**Scaffold (Create / Delete Entities):**

| Command | What it does |
|---------|-------------|
| `priority.createFormTrigger` | Create a new form-level trigger |
| `priority.deleteFormTrigger` | Delete a form trigger |
| `priority.createFormColumnTrigger` | Create a column-level trigger |
| `priority.deleteFormColumnTrigger` | Delete a column trigger |
| `priority.createProcedureStep` | Create a new procedure step |
| `priority.deleteProcedureStep` | Delete a procedure step |

**Utility:**

| Command | What it does |
|---------|-------------|
| `priority.searchInExplorer` | Search the environments tree |
| `priority.refreshExplorer` | Refresh the environments tree |
| `priority.showLogs` | Show extension logs |
| `priority.showFileLogs` | Show file-specific logs |

### Typical Workflow

1. `get_current_file()` → read what's open in VSCode
2. Analyze the code, propose changes
3. `write_to_editor(entityType, entityName, stepName, content)` → write full step content
4. `run_windbi_command("priority.prepareProc")` → compile and check for errors
5. If compile error appears in log signals, fix and repeat

### Inspecting Entities

- `run_windbi_command("priority.dumpForm", entityName: "ORDERS")` → full form dump (check WINDBI panel)
- `run_windbi_command("priority.dumpProcedure", entityName: "ACCOUNTS2")` → full procedure dump
- `run_windbi_command("priority.displayTableColumns", entityName: "ORDERS")` → table structure
- `run_windbi_command("priority.findStringInAllForms", entityName: "OBLIGO")` → search across all code

### Scaffolding New Code

- `run_windbi_command("priority.createProcedureStep")` → add a new step to current procedure
- `run_windbi_command("priority.createFormTrigger")` → add a new trigger to current form
- After scaffolding, use `refresh_editor()` to reload, then `write_to_editor()` to add code

### Output Capture Behavior

WINDBI command results render in the **PRIORITY WINDBI webview panel** in VSCode — they cannot be captured programmatically. However:
- **Compile errors** are captured from the extension log (`captured_from: "extension_log"`)
- **Command status** (success/failure) is always reported
- **Command return values** are captured if the Priority extension returns them directly
- The user can visually check the WINDBI panel for dump/table/search results

### Command Behavior Quick Reference

| Category | Commands | Input Dialog | Capture Rate |
|----------|----------|:------------:|:------------:|
| Compile | prepareForm, prepareProc | No | 90%+ (log signals) |
| Explain | explainSqliCode, explainSqliCodeWithExec | No | 90%+ (return value) |
| Search / Display | findStringInAllForms, displayTableColumns, etc. | Yes | 80-90% |
| Dump | dumpForm, dumpProcedure, dumpTable, etc. | Yes | 30-50% (webview) |
| Scaffold | createFormTrigger, createProcedureStep, etc. | Yes | 40-50% |
| **Execute (preferred)** | **`run_inline_sqli` mode="sqli"/"dbi"** | No | **95%+ (direct WCF)** |
| Execute (legacy) | runSqliFile, executeDbi, createSqliFile | Yes (some) | 40-80% |

Commands with "Yes" in Input Dialog use a clipboard-paste auto-fill mechanism (600ms delay, 20s timeout). See `references/vscode-bridge-examples.md` for full details.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `get_current_file` returns `{content: null}` | No `priorityfs://` file open in VSCode | Open a Priority file from the Environments Explorer |
| `write_to_editor` returns `EDITOR_NOT_FOUND` | Target file not open in editor | Open the specific step/trigger file first |
| `write_to_editor` returns `saved: false` | Focus was stolen during save | File is modified in editor; press Ctrl+S manually |
| `run_windbi_command` returns `COMMAND_TIMEOUT` | Input dialog not answered in 20s | Ensure entityName is provided; the clipboard-paste auto-fill may have missed the dialog due to timing. Retry with a Priority file active in VSCode. |
| `run_windbi_command` output is null or log-only | WINDBI renders in webview (not capturable) | Check PRIORITY WINDBI panel visually; or use Gateway `dump-entity` tool for structured output |
| `run_windbi_command` returns `NO_PRIORITY_FILE_OPEN` | FORM/PROC command fired with no matching file loaded | Open the target form/procedure from the Environments Explorer sidebar, then retry. v1.6+ pre-checks this to avoid silent "No X data" failures. |
| `run_windbi_command` returns `MISSING_ENTITY_NAME` | TABLE/REPORT command called without entityName | Pass `entityName` for dumpTable / displayTableColumns / dumpReport etc. |
| `run_windbi_command` returns `MISSING_SEARCH_STRING` | findStringInAllForms called without input | Bridge cannot fill the input box non-interactively. Use `run_inline_sqli` to query CODEREF / form-dump tables directly. |
| `executeDbi` fails or times out | Requires active `.pq` file with DBI content | **Use `run_inline_sqli({ sql, mode: "dbi" })` instead** — no .pq file needed, direct WCF call. |
| priority-dev unreachable | Bridge extension not running | Reload VSCode; verify the bridge health endpoint responds |
| "No procedure data" in log (v1.5 and earlier) | Active editor was not a Priority file | Fixed in v1.6 — bridge now returns structured `NO_PRIORITY_FILE_OPEN` instead of silent failure. |

**Gateway alternatives for unreliable bridge commands:** When dump commands fail to capture output (webview limitation), use the WebSDK Gateway tools `dump-entity` and `read-code` instead — they return structured data directly.

See `references/vscode-bridge-examples.md` for detailed tool usage examples.

---

## HEAVYQUERY Performance Monitoring

Available starting with v24.1.

### Requirements

- **Cloud (AWS):** Enabled from v24.1
- **Local installations:** v25.0 (BIN 25.0.13+) or v24.1 (BIN 24.1.36+)

### Setup

1. Open **System Constants** form (System Management > System Maintenance > Constant Forms).
2. Locate the `HEAVYQUERY` constant.
3. Set the threshold in whole seconds (recommended: 3-5 seconds).

### Usage

Queries exceeding the threshold are recorded in **List of Queries in Process** (System Management > System Maintenance > Periodic Maintenance).

**Recorded information:**
- Query Duration (seconds)
- Process Duration (seconds; 0 if still running)
- Date and time
- Process Name and entity type
- User Name and Company Name
- Subform: query text and RETVAL

**Related form:** List of Recent Processes shows additional information (internal entity name). Starting with v25.0, includes input for procedures/reports.

### Best Practices

- Start with 3-5 seconds for initial rollout; adjust based on workload.
- Compare log times with user-reported issues.
- Prioritize queries that are both slow and frequent.
- Track issues over time to measure improvements.

### Notes

- Heavy queries from form searches (F11) may indicate missing table indexes.
- Records are automatically removed after at least one week.

### Limitations

- REST API activity is not currently captured by Heavy Query Monitoring.

---

## Diagnostic Techniques

### Diagnosing silent procedure body failures

When a procedure compiles without errors but produces no visible output or side effects, use these two complementary techniques to locate the failure line.

**Technique 1 — ERRMSG litmus (confirms body entry)**

Add as the very first line of the procedure step body:

```sql
ERRMSG 1 WHERE 1 = 1;
```

Run via the Priority web UI (not via bridge tools — `run_inline_sqli` suppresses ERRMSG output). If no error dialog appears, the body is not executing at all. Diagnose the procedure container itself (see `websdk-cookbook.md` § "Procedure creation gotchas").

**Technique 2 — Marker INSERT (pinpoints the failing line)**

Create a simple debug log table (one-time DBI):

```sql
/* DBI */
CREATE TABLE XXXX_DEBUGLOG 'Debug Log' 0
TAG  (CHAR,40,'Tag')
TS   (DATE,14,'Timestamp')
UNIQUE(TAG, TS);
```

Insert unique markers at suspected execution points in the procedure body:

```sql
INSERT INTO XXXX_DEBUGLOG(TAG,TS) VALUES('BODY_START', SQL.DATE);
/* ... some logic ... */
INSERT INTO XXXX_DEBUGLOG(TAG,TS) VALUES('AFTER_CURSOR_OPEN', SQL.DATE);
/* ... more logic ... */
INSERT INTO XXXX_DEBUGLOG(TAG,TS) VALUES('AFTER_LOOP', SQL.DATE);
```

After running, query the log:

```sql
SELECT TAG, DTOA(TS,'XX/XX/XX hh:mm') FROM XXXX_DEBUGLOG ORDER BY TS FORMAT;
```

The last marker present tells you exactly where execution stopped. Clean up after debugging: `DELETE FROM XXXX_DEBUGLOG WHERE TAG <> '';`

**Advantage over ERRMSG:** works even when ERRMSG is suppressed by the execution context, and pinpoints the exact failing line rather than just confirming body entry. Particularly valuable for long procedure bodies and nested cursor loops.

*(seen in: session-2026-05-02-tgml-phase1 — technique successfully traced a silent failure to line 7 of a 35-line procedure body, bypassing bridge tool unreliable output)*
