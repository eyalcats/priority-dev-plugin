# Tables and DBI Reference

Complete reference for Priority table management, including naming conventions, development environment setup, table/column/key types, creating and modifying tables, and DBI syntax.

---

## Table of Contents

- [Naming Conventions and Rules](#naming-conventions-and-rules)
  - [Entity Naming Rules](#entity-naming-rules)
  - [Code Rules](#code-rules)
  - [Table Modification Rules](#table-modification-rules)
  - [Column Rules (Customization)](#column-rules-customization)
  - [Key Rules (Customization)](#key-rules-customization)
  - [Form Rules](#form-rules)
  - [Report Rules](#report-rules)
  - [Procedure Rules](#procedure-rules)
  - [Best Practices](#best-practices)
- [Development Environment Setup](#development-environment-setup)
  - [Development Process](#development-process)
  - [User Permissions](#user-permissions)
  - [Development Permissions for Non-tabula Users (22.1+)](#development-permissions-for-non-tabula-users-221)
  - [Expose the Table Generator](#expose-the-table-generator)
  - [Developing for Multiple Languages](#developing-for-multiple-languages)
  - [Util Folder (Windows Only)](#util-folder-windows-only)
- [Table Types](#table-types)
- [Column Types](#column-types)
  - [Decimal Precision](#decimal-precision)
  - [Column Rules](#column-rules)
- [Table Keys](#table-keys)
  - [Autounique Key](#autounique-key)
  - [Unique Keys](#unique-keys)
  - [Nonunique Key](#nonunique-key)
  - [Keys and Record Links](#keys-and-record-links)
  - [Key Rules (Full)](#key-rules-full)
- [Creating and Modifying Tables](#creating-and-modifying-tables)
  - [Table Generator Programs](#table-generator-programs)
  - [Programs for Columns](#programs-for-columns)
  - [Programs for Keys](#programs-for-keys)
- [DBI Syntax Reference](#dbi-syntax-reference)
  - [Syntax Conventions](#syntax-conventions)
  - [Tables](#tables)
  - [Columns](#columns)
  - [Keys](#keys)
  - [Key Columns](#key-columns)
  - [Example: Dump Table Output](#example-dump-table-output)

---

## Naming Conventions and Rules

### Entity Naming Rules

The following rules apply to internal names of **all** private entities (tables, forms, procedures, reports, triggers, functions, columns):

| Rule | Detail |
|------|--------|
| Max length | 20 characters |
| Allowed chars | Alphanumeric and underscore only (no spaces) |
| Must begin with | A letter |
| Reserved words | Cannot use reserved words (see `System Management > Dictionaries > Reserved Words`) |
| Prefix requirement | New custom entities must begin with a **four-letter prefix** (e.g., `XXXX_CUSTOMERS`) |
| Consistency | All entities created for the same customer share the same prefix |
| Sub-entities | New columns/triggers added to standard entities also use the four-letter prefix |
| Variables | Any variable added to code must start with the same four-letter prefix to avoid duplicating system variables |

### Code Rules

- **Never** INSERT or UPDATE data in standard tables directly. Use interfaces or form-based tools.
- Follow every LINK or UNLINK operation with a test to ensure the operation succeeded. A failed LINK can lead to overwriting data in the original table.
- Do not write non-ASCII characters directly in code. Use the `ENTMESSAGE` function for unicode text (e.g., Hebrew messages).

### Table Modification Rules

- Do not change standard table columns or any of the table's Unique (or Auto Unique) keys.
- Increasing the width of certain columns is allowed (consult Priority Software first).
- Adding nonunique table keys to a standard table is allowed (consult a DBA first).

<!-- ADDED START -->
### Common Issues and Solutions

*   **Core Field Width Limitations:**
    Modifying the width of core system fields (such as `PARTNAME`) across the entire system cannot be performed via private development or manual schema changes. These changes are managed by Priority Software as part of version releases. For example, the standard width for Part Number is scheduled for expansion to 30 characters in version 25.1.

*   **Table Row Width Limits:**
    When adding new columns to a table (e.g., `PARTSPEC`), you may encounter errors if the total row size exceeds system limits. The maximum row width for a table in Priority is 4096 characters. If you receive an error when adding columns, verify the cumulative character count of all existing and new fields.

*   **Schema Versioning and Field Availability:**
    Standard table schemas evolve between versions. For instance, the `ACTUALDELIVERYDATE` column in the `DOCUMENTS` table was introduced in version 20.1. Always verify the specific version of the environment when referencing standard columns that may have been introduced in recent updates.
<!-- ADDED END -->
<!-- ADDED START -->
### Common Issues and Solutions

- **Modifying Standard Column Widths:**
  While technically possible via DBI for some fields, it is strongly discouraged to expand central standard columns (e.g., `PARTNAME`, `MNFPARTNAME`, or `IVNUM`). Future system updates may revert these changes, leading to data truncation or loss. 
  *   **Solution:** Instead of modifying the standard field, create a new custom field (e.g., in an extension table like `PARTA`) to hold the longer value. If an expansion is absolutely required for a standard field, it must be handled via a formal private development request to ensure compatibility with future versions.

- **Modifying Protected System Tables:**
  Certain base tables (e.g., `USERSB`, `CURRENCIES`) are protected. Attempting to add custom columns or modify their structure directly will result in errors.
  *   **Solution:** Use the designated extension tables (e.g., `USERSA`) or create a new private extension table linked to the base table's unique key.

- **Installation-Wide Impact:**
  Any table modifications or private developments made in one company (e.g., a Demo or Test company) are installation-wide. Changes to the database schema (DBI) affect all companies within that environment.
  *   **Solution:** Always perform and test table modifications on a dedicated test server before applying them to a production environment.

- **Database Record Width Limits:**
  Even on modern databases like SQL Server or Oracle, there is a technical limit to the total width of all columns in a single table. 
  *   **Solution:** If a table has reached its maximum record width, do not attempt to add more columns. Instead, create an extension table (e.g., `MYTABLEA`) to store additional fields.

- **Version-Specific Schema Updates:**
  In some cases, specific standard tables (like `STACK6`) may require expansion for specific business needs. 
  *   **Solution:** These modifications are typically delivered via official "HO/EO" extension files or DBI executables provided by Priority Support to ensure the schema change is registered correctly in the system's metadata.

- **Errors After Custom Table Modification:**
  If a custom table is modified (e.g., expanding a field) and the associated form begins to crash or throw errors.
  *   **Solution:** Ensure that the form definition and any linked OPA/LINK expressions are updated to match the new column width or type. Consult the original developer to ensure the DBI and FRM files are synchronized.
<!-- ADDED END -->
### Column Rules (Customization)

- Specify decimal precision only for REAL or INT columns.
- Modifying a column affects **all** forms and reports where it appears.
- Do not delete a column that appears in a form, report, or procedure.
- Column type changes are limited to: INT to REAL and vice versa (development phase only).
- Keep CHAR columns at 120 characters width or less.
- Columns in SELECT of SEARCH triggers cannot exceed 59 characters.
- Do not add columns to system tables.

### Key Rules (Customization)

- Only one autounique key per table (single INT column, first priority, not in other keys).
- Every table must have at least one unique key.
- If an autounique key exists, it must be key #1; the unique key must be #2.
- If no autounique key, one unique key must have first priority.
- Column order in the key determines priority.
- Key columns must exist in the table.
- Adding a column to a key without specifying priority assigns it the last available priority.

### Form Rules

- Never use a standard base table to create a custom form. Create a custom table instead.
- Do not delete a standard column from a standard form.
- When creating multiple joins, use join ID and column ID **greater than 5**.
- Forms cannot have more than 10 outer joins total (including standard ones).
- Triggers added to forms must start with or end with a four-letter prefix.
- Form messages added must have a number **greater than 500**.
- Do not add standard forms as sub-level forms of other forms.
- When using LABELs in code, use numbers with **at least 4 digits** to prevent conflicts.

### Report Rules

- New columns added to standard reports must have Column Number **greater than 500**.
- New joins to standard reports must have Join ID **greater than 5**.
- Do not change sorting or grouping of standard reports; copy the report instead.
- Do not delete a standard column from a standard report.
- Always check report optimization after revising/creating reports.
- Conditions and expressions cannot exceed 3000 characters.

### Procedure Rules

- Do not revise a standard procedure; copy it and modify the copy.
- When copying a procedure that runs a program, do not change transferred parameters.
- Procedures with form interfaces must include the interface as a step after an END step.
- Avoid using a standard interface in a custom procedure (may break with future changes).

### Best Practices

- Write reusable code (functions, buffers).
- Write readable code (meaningful variable names, comments).
- Do not add multiple PRE/POST triggers for the same form column; use buffers instead.
- Include comments pointing to specification documents.
- Do not insert error/warning messages inside loops or cursors (causes hang waiting for input).

---

## Development Environment Setup

### Development Process

Maintain **three Priority installations**:

1. **Development environment** -- where customizations are developed
2. **Test environment** -- where tests are run
3. **Production server** -- the live system

**Workflow:** Create customizations in dev -> create upgrade file -> install in test -> verify -> install on production.

> **Warning:** Never customize directly on the production server.

- Revisions are maintained per user; each programmer must work under their own username.
- To execute DBI operations (anything affecting tables, columns, or keys), belong to the **tabula** privilege group and set the `PRIVUSERS` system constant to `1`.

### User Permissions

For most use cases, assign developer users to the **tabula** superuser group.

**Steps (perform as tabula user):**

1. Open `Users` form: `System Management > System Maintenance > Users > Users`
2. Retrieve the target user
3. Assign `tabula` as the privilege group leader
4. Open `System Constants` form
5. Ensure `PRIVUSERS` constant = `1`

### Development Permissions for Non-tabula Users (22.1+)

Create a new user group with:

**Privilege Explorer access** to menus under System Management:
- Generators
- Revisions
- Database Interfaces
- Dictionaries (optional, for multi-language)

**User Permissions** (in `System Management > System Maintenance > Users > User Permissions`):
- Authorized for SQL
- Customize Workspace
- Table Structure Mgmt

### Expose the Table Generator

On fresh installations, the Table Generator is not linked to the menu:

1. Open `Menu Generator`: `System Management > Generators > Menus > Menu Generator`
2. Retrieve the `Generators` menu
3. In Menu Items sub-level, add the `TABGEN` menu

### Developing for Multiple Languages

If users work in a language other than English:

1. Open `System Constants`: `System Management > System Maintenance > Constant Forms`
2. Change `UPGTITLES` constant to `0`
3. Titles will be inserted into a second file using the `INSTITLES` program

### Util Folder (Windows Only)

The Util folder enhances WINDBI with Queries and Dump menu tools:

1. Navigate to `priority/system` on the server
2. Download the zipped util folder
3. Extract to `priority/system/util`

<!-- ADDED START -->
### Common Issues and Solutions

*   **Broken Download Links:**
    If the link to `util.zip` in the documentation is broken or inaccessible, contact Priority Support to obtain the latest version of the utility folder required for the development environment.

*   **WINDBI Execution Errors (e.g., "Failure to Open Input File"):**
    Errors when running queries or "Select All" commands in the WINDBI development environment are often caused by missing files or permission issues.
    *   **Missing Files:** Ensure the `util` directory is correctly installed at the `priority/system/util` path on the server. If files are missing, re-extract the utility folder.
    *   **Temporary Directory Permissions:** WINDBI requires write permissions to the temporary directory. Verify that the user has full write permissions to `C:\tmp` (or the specific directory defined as `Tabula Tmp` in the `tabula.ini` file).

*   **Terminal Server Compatibility:**
    When running WINDBI on a Terminal Server, ensure the utility files are extracted to the central `priority/system/util` directory on the application server to prevent execution errors for remote users.
<!-- ADDED END -->
## Table Types

| Type Value | Description |
|-----------|-------------|
| 0 or 1 | Application table (data maintained separately per company) |
| 2 or 3 | System table (data common to all companies) |

**Always assign type `0` to new tables.**

New system tables cannot be created. Columns cannot be added to system tables.

---

## Column Types

| Col. Type | Description | Width | Form Col. Type |
|-----------|-------------|-------|----------------|
| CHAR | String of characters | > 1 | String |
| CHAR | Single character | = 1 | Character |
| REAL | Real number | any | Real |
| INT | Signed integer | any | Integer |
| DATE | Date (mm/dd/yy or dd/mm/yy) | 8 | Date |
| DATE | Date (mm/dd/yyyy or dd/mm/yyyy) | 10 | Date |
| DATE | Date & time (24-hour clock) | 14 | Date+Time |
| TIME | Time (24-hour clock) | 5 | hh:mm |
| TIME | Span (number of hours and minutes) | 6 | hhh:mm |
| DAY | Day of the week | 3 | Day |

**Important:** Distinguish between integers (INT type, e.g., QUANT, BALANCE) and strings of digits (CHAR type, e.g., ZIPCODE, ORDNAME, PHONE).

Column type changes are not permitted, **except**: during the development phase, convert INT to REAL and vice versa using the `Change Number Type` program.

### Decimal Precision

- Optional; used for real numbers and shifted integers.
- A **shifted integer** is stored as integer but displayed as real (e.g., `TQUANT` in `ORDERITEMS`).
- Use `REALQUANT` function to retrieve the actual value of shifted integers.
- Most columns have decimal precision of 2.
- Precision 0 on REAL = indefinite precision; otherwise, INSERT/UPDATE rounds to defined precision.
- For shifted integers, decimal precision must equal the `DECIMAL` system constant value (or 0 for regular integer).

### Column Rules

- Names: up to 20 characters, alphanumeric + underscore, must begin with letter.
- Cannot use reserved words (check `RESERVED` form).
- New columns on standard tables must have the four-letter prefix.
- Column titles: up to 20 characters (including spaces), enclosed in single quotes, e.g., `'Order Number'`.
- Keep CHAR columns at 80 characters width or less (wider columns display poorly in forms).
- **Foreign key columns must match the target table's column type AND width exactly.** Before defining a column that will join to another table (e.g., COUNTRY referencing COUNTRIES.COUNTRY), check the target column's width using Display Table Columns. A width mismatch (e.g., INT 11 vs INT 13) causes "join column type mismatch" errors in the form generator.
- Do not add columns to system tables.

---

## Table Keys

### Autounique Key

- Similar to IDENTITY (MSSQL) or SEQUENCE (Oracle).
- Automatically assigns a unique integer to each new record.
- Effective for joining tables in forms (value remains constant even if user-visible fields change).
- Include in tables with basic/reference data (customers, parts, warehouses) and tables with one-to-many relationships.

**Example:** The `CUST` autounique key assigns unique internal numbers to customers. The `ORDERS` table joins to `CUSTOMERS` via `CUST` rather than `CUSTNAME`.

### Unique Keys

- Ensure no duplicate records for the key column combination.
- Every table must have at least one unique key.
- **Danger zones when modifying:**
  - Adding a unique key (if columns lack values, duplicate nulls cause record deletion)
  - Deleting a column from a unique key (may create duplicate key values)
  - Reducing width of a key column (may truncate values into duplicates)

**Example:** Unique key on `FIRSTNAME` + `LASTNAME` -- deleting `LASTNAME` from the key can cause records like "Samuel Brown" and "Samuel Black" to collide.

### Nonunique Key

- Provides rapid access to data without uniqueness constraint.
- Include columns frequently used for retrieval with highly diversified data.
- The header of any key (consecutive columns from the first) is automatically treated as a nonunique key.

**Example:** For a key with ORD, PART, CURDATE -- both `ORD` alone and `ORD+PART` are treated as nonunique keys.

### Keys and Record Links

- If a table has autounique key + single unique key: record link is based on the unique key column.
- If a table has autounique key + multiple unique keys and autounique column is displayed: record link is based on the autounique column.

### Key Rules (Full)

| Rule | Detail |
|------|--------|
| Autounique limit | One per table |
| Autounique type | Single INT column, not in other keys, first priority |
| Minimum keys | At least one unique key required |
| Priority order | Autounique = key #1, then unique = key #2; or if no autounique, unique has first priority |
| Column assignment | Key columns must exist in the table |
| Default priority | Added column without specified priority gets last available priority |
| Priority changes | Changing one column's priority affects others |

---

## Creating and Modifying Tables

### Table Generator Programs

Access: `System Management > Generators > Tables`

Requirements: tabula privilege group + `PRIVUSERS` = 1.

**Run only one program at a time** to prevent temporary table overwrites.

#### Create a Table

1. Enter `Define Table` form -- record table name, type (1), title
2. Enter `Columns` sub-level -- for each column: name, type, width, title, decimal precision
3. Enter `Keys` sub-level -- record keys
4. For each key, enter `Key Columns` sub-level -- record columns
5. Exit all forms -- the table is created

#### Other Table Programs

- **Delete Table** -- cannot delete if any column appears in a form/report/procedure
- **Change Table Name** -- no effect on forms/reports (they use internal number), but revise SQL statements
- **Change Table Title**
- **Add Column to Table** -- run program, choose table, enter sub-level for column details
- **Delete Column from Table**

<!-- ADDED START -->
### Common Issues and Solutions

**Schema Sync Failures in MSSQL**
- **Problem:** A column was deleted via the Priority interface but remains visible in the MSSQL database, leading to functional discrepancies.
- **Solution:** Ensure the specific database is correctly registered in the `ENVIRONMENT` table of the `SYSTEM` database. Priority relies on this registry to synchronize schema changes across all managed environments.

**Blocked Column Deletion due to Dependencies**
- **Problem:** Attempting to delete a column fails with a message stating the table/column is linked to a report or other system object.
- **Solution:** The system prevents deletion to maintain integrity. You must first manually remove the column from all dependent forms, reports, and procedures before the "Delete Column from Table" program will execute successfully.

**Adding New Fields Beyond "Spare" Columns**
- **Problem:** A user needs to add a custom field but has exhausted all available "spare" fields in the table.
- **Solution:** Adding entirely new columns (rather than renaming existing spares) requires programmatic intervention. Use the **Table Generator** tools to define the new column and then run the "Add Column to Table" procedure to update the physical database schema.
<!-- ADDED END -->
### Programs for Columns

- **Change Column Name** -- no effect on forms/reports; revise SQL statements
- **Change Column Width** -- widths modified in existing forms/reports; use caution when reducing
- **Change Decimal Precision** -- only for: any REAL, regular INT (precision 0) to DECIMAL constant value, or shifted INT to precision 0
- **Change Number Type** -- INT to REAL and vice versa (development phase only); adjust type context in SQL queries
- **Change Column Title** -- affects all forms/reports except those with overridden titles

### Programs for Keys

- **Add Key to Table** -- specify table, key type (A/U/N), priority, then columns
- **Delete Key from Table**
- **Change Key Priority**
- **Change Autounique to Unique**
- **Change Unique to Nonunique** -- cannot change first unique key
- **Add Column to Key** -- specify desired priority to insert at that position
- **Delete Column from Key** -- lower priority columns move up
- **Change Column Priority**

---

## DBI Syntax Reference

The **Database Interpreter (DBI)** program is a database language for constructing and modifying database tables.

**Important — DBI and upgrade change tracking:**
DBI executed via `run_inline_sqli(mode=dbi)` or standalone `.pq` files bypasses Priority's change tracking system. Columns added this way to system tables will NOT be included automatically in upgrade shells by TAKEUPGRADE. To deploy them, you must manually add a UPGCODE="DBI" entry to the UPGNOTES subform in the UPGRADES form, with the DBI text in its UPGNOTESTEXT subform. See `references/debugging.md` → "Adding Manual DBI to UPGNOTES" for the full pattern. Columns added to custom tables (via TAKESINGLEENT on the form) are handled automatically.

### Syntax Conventions

- `[ ]` = optional
- `|` = choose one
- `{ }` = must choose one
- **Bold** = literal keywords; *italics* = replace with values
- All punctuation as-is (especially the semicolon at the end)
- `...` = multiple values allowed
- `/* comment */` = SQL comments

### Tables

**Create a table:**
```sql
CREATE TABLE table_name [type]
column_name1 (type, width, [ decimal_precision, ] 'title')
[ column_name2 (type, width, [ decimal_precision, ] 'title') ]
[ column_name3 ... ]
[ AUTOUNIQUE (column_name) ]
UNIQUE (column_name, ... )
[ UNIQUE ... ]
[ NONUNIQUE (column_name, ... ) ]
[ NONUNIQUE ... ];
```

**DBI Pitfalls — must read before writing CREATE TABLE**

These constraints cause silent parse errors or rejected DDL. Confirmed 2026-04-17 on live Priority DBI.

1. **Use the Priority column form `COL (TYPE, WIDTH, 'Title')` — NOT SQL-standard `COL TYPE(WIDTH) NOT NULL`.** Parens go around the whole `(type, width, 'title')` triple, not around the width. SQL-standard syntax is silently rejected with cryptic parse errors.

```sql
/* WRONG — SQL-standard syntax */
CREATE TABLE X (COL CHAR(1) NOT NULL) UNIQUE (COL);

/* CORRECT — Priority DBI */
CREATE TABLE X 0
COL (CHAR, 1, 'Title')
UNIQUE (COL);
```

2. **`TIME` width must be ≥ 5.** Width 4 is rejected with parse error. Use 5 (HH:MM, displayed as `hh:mm`) or 6 (HH:MM:SS where seconds are kept).

3. **Reserved words that cannot be column names:** `REFRESH`, likely others (any SQLI verb used in triggers). If the plan calls for a `REFRESH` column, rename to `DOREFRESH` or similar. Priority errors with "table must have at least one key" or parse error at the column line.

4. **`AUTOUNIQUE` requires a co-existing `UNIQUE` key.** Standalone `AUTOUNIQUE (col)` is rejected with "table must have at least one key of type U". Two correct patterns:
   - `AUTOUNIQUE (ID) UNIQUE (OTHER_COL)` — separate autounique + natural key
   - `UNIQUE (ID)` at DBI, plus `FCLMN SUM='U'` on the form column for auto-increment on INSERT (form-level autounique)

5. **DBI column titles: ≤ 20 chars, ASCII-only.** Hebrew titles in DBI may cause encoding issues during upgrade shells. Put Hebrew titles on the form column via `COLTITLE` (WebSDK), not in the DBI.

6. **`DELETE TABLE` can be blocked by form column dependencies.** If any form has FCLMN columns pointing at the table (via `TNAME` or `JTNAME`), `DELETE TABLE` fails. Remove the form columns first (or drop the form), then delete the table.

7. **`CmdDbi` via `run_inline_sqli mode=dbi` supports both `CREATE TABLE` and `DELETE TABLE`** — you don't need a `.pq` file. Some older memory claims otherwise; it's outdated.

**Delete a table:**
```sql
DELETE TABLE table_name;
```

**Change table name:**
```sql
FOR TABLE table_name
CHANGE NAME TO new_name;
```

**Change table title:**
```sql
FOR TABLE table_name CHANGE TITLE TO 'new_title';
```

### Columns

**Add a column to a table:**
```sql
FOR TABLE table_name
INSERT column_name (type, width, [ decimal_precision, ] 'title');
```

**Delete a column from a table:**
```sql
FOR TABLE table_name DELETE column_name;
```

**Change column name:**
```sql
FOR TABLE table_name COLUMN column_name
CHANGE NAME TO new_name;
```

**Change column width:**
```sql
FOR TABLE table_name COLUMN column_name CHANGE WIDTH TO integer;
```

**Change column title:**
```sql
FOR TABLE table_name COLUMN column_name CHANGE TITLE TO 'title';
```

**Change decimal precision:**
```sql
FOR TABLE table_name COLUMN column_name
CHANGE DECIMAL TO decimal_precision;
```

**Change number type (toggle INT/REAL):**
```sql
FOR TABLE table_name COLUMN column_name
CHANGE NUMBER TYPE;
```

**Change number type to REAL only:**
```sql
FOR TABLE table_name COLUMN column_name
CHANGE NUMBER TYPE TO REAL;
```

**Change number type to INT only:**
```sql
FOR TABLE table_name COLUMN column_name
CHANGE NUMBER TYPE TO INT;
```

### Keys

**Add a new key to a table:**
```sql
FOR TABLE table_name
INSERT { AUTOUNIQUE | UNIQUE | NONUNIQUE}
(column_name, ...)
[ WITH PRIORITY key_priority ];
```

**Delete a key from a table:**
```sql
FOR TABLE table_name
DELETE KEY {key_priority | (column_name 1, ... , column_name n) };
```

**Change key priority:**
```sql
FOR TABLE table_name
KEY { key_priority | (column_name 1, ... , column_name n) }
CHANGE PRIORITY TO new_key_priority;
```

**Change key type from autounique to unique:**
```sql
FOR TABLE table_name
CHANGE AUTOUNIQUE TO UNIQUE;
```

**Change key type from unique to nonunique:**
```sql
FOR TABLE table_name
KEY { key_priority | (column_name 1, ... , column_name n) }
CHANGE UNIQUE TO NONUNIQUE;
```

### Key Columns

**Add a new column to a key:**
```sql
FOR TABLE table_name
KEY { key_priority | (column_name 1, ... , column_name n) }
INSERT column_name
[ WITH PRIORITY column_priority ];
```

**Delete a column from a key:**
```sql
FOR TABLE table_name
KEY { key_priority | (column_name 1, ... , column_name n) }
DELETE column_name;
```

**Change column priority in a key:**
```sql
FOR TABLE table_name
KEY { key_priority | (column_name 1, ... , column_name n) }
COLUMN column_name
CHANGE PRIORITY TO new_column_priority;
```

### Example: Dump Table Output

Result of Dump Table for the `ORDSTATUS` table:

```sql
CREATE TABLE ORDSTATUS 'Possible Statuses for Orders' 0
ORDSTATUS (INT,13,'Order Status (ID)')
ORDSTATUSDES (CHAR,12,'Order Status')
INITSTATFLAG (CHAR,1,'Initial Status?')
CLOSED (CHAR,1,'Close Order?')
PAYED (CHAR,1,'Paid?')
SORT (INT,3,'Display Order')
OPENDOCFLAG (CHAR,1,'Allow Shipmt/ProjRep')
CHANGEFLAG (CHAR,1,'Allow Revisions?')
CLOSESTATFLAG (CHAR,1,'Closing Status?')
REOPENSTATFLAG (CHAR,1,'Reopening Status?')
INTERNETFLAG (CHAR,1,'Order from Internet?')
OPENASSEMBLY (CHAR,1,'Open Assembly Status')
CLOSEASSEMBLY (CHAR,1,'End Assembly Status')
PARTIALASSEMBLY (CHAR,1,'Partial Assm. Status')
ESTATUSDES (CHAR,16,'Status in Lang 2')
MANAGERREPOUT (CHAR,1,'Omit from Reports')
AUTOUNIQUE (ORDSTATUS)
UNIQUE (ORDSTATUSDES);

## DBI pitfalls

Behaviours that have cost past sessions hours of debugging. Treat as the current contract.

### Column spec uses parentheses, not SQL-standard syntax

Priority DBI columns use `COL (TYPE, WIDTH, 'title')` — parentheses wrap the whole triple. SQL-standard forms fail:

```
/* Wrong — fails parse */
MYCOL CHAR(1) NOT NULL,

/* Right */
MYCOL (CHAR, 1, 'My Column')
```

### `TIME` width minimum

`TIME` column width must be ≥ 5 (typically 6). Width 4 fails at DBI-parse time.

### `REFRESH` is reserved

`REFRESH` cannot be used as a column name — DBI rejects it. Rename (e.g., `DOREFRESH`, `REFRESHFLAG`).

### Column title hard cap at 20 characters

`FOR TABLE … INSERT` silently truncates or rejects titles longer than 20 characters. For longer titles, either abbreviate in the DBI spec or set the full title via a subsequent `FCLMN.COLTITLE` update.

### `AUTOUNIQUE` requires a paired `UNIQUE` key, or use trigger-based alternative

`AUTOUNIQUE` standalone in `CREATE TABLE` is invalid — it must appear alongside a `UNIQUE` key (typically `AUTOUNIQUE (col1) UNIQUE (col2);`).

Alternative: plain `UNIQUE (col)` + form-level `FCLMN SUM='U'` to get auto-increment behaviour. `FCLMN.SUM` is not exposed via WebSDK; set it via a PRE-INSERT trigger instead: `SELECT NVL(MAX(KLINE),0)+1 INTO :$.KLINE FROM <table>;`.

Adding `AUTOUNIQUE` via DBI on an existing populated table can corrupt existing rows. Only safe on fresh tables.

### `CREATE TABLE` vs `ADD TABLE`

Use `CREATE TABLE … UNIQUE(…);`. `ADD TABLE` is not valid Priority DBI syntax.

### Autonomous DBI workflow

For DBI execution, call `run_inline_sqli(mode="dbi")` directly. No `.pq` file needed. The active-editor quirk that affects `runSqliFile`/`executeDbi` (see `websdk-cookbook.md` § "Known bridge behaviors") does NOT affect `run_inline_sqli`.

### Custom columns on system tables — manual UPGNOTES DBI entry required

Columns added to system tables via `run_inline_sqli(mode="dbi")` bypass Priority's change tracking, so `TAKEUPGRADE` does not auto-generate DBI for them. See `deployment.md` § "DBI in UPGNOTES for system-table columns" for the upgrade-shell recipe.
```
