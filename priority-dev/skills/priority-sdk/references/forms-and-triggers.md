# Forms and Triggers Reference

## Table of Contents

- [1. Form Creation](#1-form-creation)
  - [Form Name](#form-name)
  - [Form Title](#form-title)
  - [Base Table](#base-table)
  - [Application](#application)
  - [Module](#module)
  - [Query Forms](#query-forms)
  - [Blocking Record Deletion](#blocking-record-deletion)
  - [Blocking Multi-Company Form Definition](#blocking-multi-company-form-definition)
  - [Form Capacities](#form-capacities)
- [2. Form Columns](#2-form-columns)
  - [Column Names and Titles](#column-names-and-titles)
  - [Order of Column Display](#order-of-column-display)
  - [Hidden Columns](#hidden-columns)
  - [Mandatory Columns](#mandatory-columns)
  - [Read-only Columns](#read-only-columns)
  - [Balance Columns](#balance-columns-special-read-only)
  - [Boolean Columns](#boolean-columns)
  - [Keyword Columns](#keyword-columns)
  - [Sorting Data](#sorting-data)
  - [Imported Data (Join Columns)](#imported-data-join-columns)
  - [Join Column Rules](#join-column-rules)
  - [Calculated Columns](#calculated-columns)
  - [Custom Columns: Data Authorization](#custom-columns-data-authorization)
  - [Split Reconciliation Forms](#split-reconciliation-forms)
  - [MDM Features](#mdm-features)
- [3. Sub-level Forms](#3-sub-level-forms)
  - [Relationships](#relationships)
  - [Linking Upper-level and Sub-level Forms](#linking-upper-level-and-sub-level-forms)
  - [Creating a Form Tree](#creating-a-form-tree)
  - [Linking to a Menu](#linking-to-a-menu)
- [4. Conditions of Record Display and Insertion](#4-conditions-of-record-display-and-insertion)
  - [Query Condition](#query-condition-record-display)
  - [Assign Condition](#assign-condition-record-display-and-insertion)
- [5. Actions and Form Refresh](#5-actions-and-form-refresh)
- [6. Accessing Related Forms](#6-accessing-related-forms)
  - [Target Form](#target-form)
  - [Dynamic Access](#dynamic-access)
- [7. Text Forms](#7-text-forms)
- [8. SQL Variables in Forms](#8-sql-variables-in-forms)
  - [Form Column Variables](#form-column-variables)
  - [Wildcards](#wildcards)
  - [User-defined Variables](#user-defined-variables)
  - [Global Variables in Forms](#global-variables-in-forms)
  - [The DUMMY Table](#the-dummy-table)
  - [Text Form Variables](#text-form-variables)
- [9. Built-in Triggers](#9-built-in-triggers)
  - [Field Triggers (Built-in)](#field-triggers-built-in)
  - [Insert Triggers (Built-in)](#insert-triggers-built-in)
  - [Update Triggers (Built-in)](#update-triggers-built-in)
  - [Delete Triggers (Built-in)](#delete-triggers-built-in)
- [10. Custom Triggers -- Complete Reference](#10-custom-triggers----complete-reference)
  - [Types of Triggers](#types-of-triggers)
  - [Where to Define Triggers](#where-to-define-triggers)
  - [Order of Trigger Execution](#order-of-trigger-execution)
  - [Trigger Naming Conventions](#trigger-naming-conventions)
  - [CHECK-FIELD](#check-field)
  - [POST-FIELD](#post-field)
  - [CHOOSE-FIELD](#choose-field)
  - [SEARCH-FIELD](#search-field)
  - [SEARCH-ALL-FIELD](#search-all-field)
  - [PRE-INSERT](#pre-insert)
  - [POST-INSERT](#post-insert)
  - [PRE-UPDATE](#pre-update)
  - [POST-UPDATE](#post-update)
  - [PRE-DELETE](#pre-delete)
  - [POST-DELETE](#post-delete)
  - [PRE-FORM](#pre-form)
  - [POST-FORM](#post-form)
- [11. Error and Warning Messages](#11-error-and-warning-messages)
  - [ERRMSG and WRNMSG](#errmsg-and-wrnmsg)
  - [Specifying Message Content](#specifying-message-content)
  - [Entity References in Messages](#entity-references-in-messages)
  - [Message Parameters](#message-parameters)
  - [General Error Messages (GENMSG)](#general-error-messages-genmsg)
  - [Displaying File Content as Message](#displaying-file-content-as-message)
  - [Require Password Reentry](#require-password-reentry-web-only)
  - [Link to Document in Messages](#link-to-document-in-messages)
- [12. MAILMSG -- Sending Email](#12-mailmsg----sending-email)
  - [Syntax](#syntax)
  - [Controlling Line Breaks](#controlling-line-breaks)
  - [Updating History of Statuses](#updating-history-of-statuses)
  - [Sending a Link to a Document](#sending-a-link-to-a-document)
- [13. Changing Column Titles Dynamically](#13-changing-column-titles-dynamically)
- [14. INCLUDE Command and Buffers](#14-include-command-and-buffers)
  - [The #INCLUDE Command](#the-include-command)
  - [Using Buffers](#using-buffers)
  - [Naming Buffers](#naming-buffers)
  - [Nesting INCLUDE Commands](#nesting-include-commands)
  - [Wildcards in INCLUDEs](#wildcards-in-includes)
  - [Error and Warning Messages with INCLUDEs](#error-and-warning-messages-with-includes)
  - [Checking Trigger Usage](#checking-trigger-usage)
- [15. Trigger Errors](#15-trigger-errors)
- [16. Form Preparation](#16-form-preparation)
- [17. Help Messages](#17-help-messages)
- [18. Default Designs for Forms](#18-default-designs-for-forms)

---

## 1. Form Creation

Construct and modify forms in the **Form Generator** form and its sub-levels (`System Management > Generators > Forms`). Forms serve three purposes:

- Insert records into the database
- Retrieve records from the database
- Allow updating of retrieved records

All three functions can be served simultaneously by the same form. Read-only query forms are also constructed in the same manner.

Forms are windows into specific database tables. Each form is derived from a single **base table** and can also display data from **join tables** (imported data that can be displayed but not modified in the form).

### Form Name

The form name is a short system identifier used in SQL variables in form triggers.

**Naming rules** (also apply to form column names):
- Only alphanumeric values (upper/lowercase letters, digits) and underscore allowed (no spaces)
- Must begin with a letter
- Cannot use reserved words (see `System Management > Dictionaries > Reserved Words`)
- New forms must begin with a **common four-letter prefix** (e.g., `ACME_ORDERS`)

**Best practice:** Assign the form the same name as its base table.

**Important:** Because SQL variables are based on the form name, any name change must be accompanied by changes in the appropriate SQL statements.

### Form Title

The title appears in menus and at the top of the form on screen. Changes in form titles do **not** affect triggers.

### Base Table

Each form is derived from a single base table. The form:
- Displays data stored in the base table
- Updates the base table when records are added, deleted, or revised

When creating a new form, also create a new base table for it.

### Application

Each form is assigned an application code to classify forms by data type (e.g., `FNC` for Financials). When creating a new form, specify a code word that aids retrieval. The application code can be used to define target forms.

### Module

Each form belongs to a Priority module. When creating a new form, specify **"Internal Development"** so the form is usable regardless of which modules have been purchased.

### Query Forms

A query form does not permit adding, modifying, or deleting records -- it displays information only.

- Do **not** flag columns as read-only in a query form
- Make unique key columns updateable for user convenience

**Tip:** To create a form where records cannot be inserted or updated but deletions are allowed, assign read-only status to all columns.

### Blocking Record Deletion

To restrict a form to inserts and updates only (no deletions), use the appropriate setting in the Form Generator.

### Blocking Multi-Company Form Definition

To prevent users from defining a form as multi-company, specify `x` in the One-to-many column.

### Form Capacities

| Property | Maximum |
|---|---|
| Form columns | 600 |
| Actions | 100 |
| Sub-level forms | 100 |
| Drilldown (zoom) depth | 10 forms |
| Auto-refresh of upper-level forms | Up to 10 form levels above current |
| Sort columns | 10 |
| Tables participating in form | 78 |
| Simultaneous form preparations | 25,000 |

<!-- ADDED START -->
### Common Issues and Solutions

*   **Hard Limits on Columns and Filters:**
    The system enforces a strict limit of 600 columns per form and 78 tables/filters (cuts) participating in a form. These are technical architectural limits and cannot be increased via configuration. If a form exceeds these requirements, it is recommended to optimize the form design by splitting functionality into sub-levels or using dedicated search forms.

*   **Form Stuck in Single-Record View:**
    If a form is stuck in "Record" (Single) view and will not switch to "Tabular" view (F4), check the form definition in the **Form Generator (F6)**. Ensure the **Display Mode** (אופן הצגה) is set to **'T'** (Tabular) rather than **'L'** (List/Record).

*   **Version Compatibility:**
    The form capacity limits (such as the 78-table join limit) remain consistent across Priority versions 21 through 23. No new restrictions have been introduced in these versions, but existing technical ceilings remain in place.
<!-- ADDED END -->
## 2. Form Columns

Record form column attributes in the **Form Columns** sub-level of the Form Generator.

### Column Names and Titles

**Naming rules** (same as form names):
- Only alphanumeric values and underscore (no spaces)
- Must begin with a letter
- Cannot use reserved words
- New columns must begin with the four-letter prefix
- Maximum 600 columns per form

The column name can be identical to the table column name. However, two different form columns derived from the same table column must have different names.

**Example:** In `DOCUMENTS_T`, both `WARHSNAME` (sending warehouse) and `TOWARHSNAME` (receiving warehouse) are derived from `WAREHOUSES.WARHSNAME`.

The column title appears as a heading in the form. It is inherited from the table column but can be revised. When a form has a default design, the title from the default design is displayed instead.

### Order of Column Display

Column display order is determined by the **Pos** (position) integer. Lower integers appear first. Integers need not be consecutive.

**Notes:**
- Positions have no effect on screen-painted forms
- Users can apply Organize Fields to customize column display

### Hidden Columns

Not all columns need to be displayed. Hide:
- Autounique key internal numbers
- Internal numbers used for data import from other tables
- Columns used for linking sub-level to upper-level forms
- Columns used for internal sorting

**Tip:** Assign hidden columns the same high position integer (e.g., 99).

### Mandatory Columns

Mandatory columns must be filled in before the user can leave the line. Built-in triggers enforce this.

- Columns in the base table's unique key are always required regardless of the mandatory flag
- When using form load interfaces, all mandatory columns must be filled in or the INTERFACE program will fail
- The Privilege Explorer can make columns mandatory for specific users

### Read-only Columns

Columns whose values are determined automatically (by triggers) should generally be read-only.

**Notes:**
- To make the entire form read-only, make it a query form
- The Privilege Explorer can make updateable columns read-only for specific users

### Balance Columns (Special Read-only)

For financial balance display, distinguish between credit and debit:
- **B** in Read/Mandatory/Bal column: Balance column (INT or REAL) -- value is added to cumulative balance
- **A** in Read/Mandatory/Bal column: Cumulative balance column -- record type (INT or REAL) in Form Column Extension, expression = `0` or `0.0`
- **C** in Read/Mandatory/Bal column: Opening balance column

Use the `CREDITBAL` system constant to control whether debit or credit balances appear in parentheses.

### Boolean Columns

A Boolean column must be:
- CHAR type
- Width of 1

When flagged: table value = `Y`. When blank: table value = `\0`.

### Keyword Columns

Special functionality is activated by keywords in column names:

#### Attachment Columns (`EXTFILENAME`)
- CHAR type column with `EXTFILENAME` in the name (e.g., `PRIV_EXTFILENAME`)
- Displays a paper clip icon for file attachment
- Files are uploaded to `system/mail` folder on the server

#### URL Columns (`HOSTNAME`)
- Column name must contain `HOSTNAME` (e.g., `PRIV_HOSTNAME`)
- Displays a globe icon to open a browser window

#### Email Columns (`EMAIL`)
- Column name must contain `EMAIL` (e.g., `PRIV_EMAIL`)
- Displays an envelope icon for sending email

#### Address/Map Columns (`ADDRESSMAP`)
- Column named `ADDRESSMAP` (or `XXXX_ADDRESSMAP`)
- Enables opening Google Maps from the form
- Requires a Google Maps API key
- Cannot be added to standard forms

#### Special Date Columns (`BIRTHDATE`)
- Column name must contain `BIRTHDATE`
- Forces display of the date `01/01/1988` (which is normally stored as `0` and not displayed)

### Sorting Data

Assign sort priorities to one or more columns to control default record order:
- Lower integer = higher sort priority
- Sort types: ascending (default), descending, alphanumeric ascending, alphanumeric descending
- String data (CHAR) sorts alphanumerically; numeric values (INT, REAL, DATE) sort by value

### Imported Data (Join Columns)

A form can display data from join tables in addition to its base table.

**To add an imported column:**
1. Specify a form column name with the prefix (e.g., `XXXX_CUSTNAME`)
2. The table name is usually filled in automatically
3. Assign a position
4. Flag as read-only or mandatory as needed

**General rule:** All imported columns except those in the join table's unique key should be read-only (values are filled in by built-in fill triggers).

### How to Define a Join (Step by Step)

When importing a column from another table (e.g., showing COUNTRYNAME from COUNTRIES):

1. **Base table column row** (e.g., COUNTRY from your table):
   - Set **Join Table** (טבלת חיבור) = the target table (e.g., COUNTRIES)
   - Set **Join Column** (עמודת חיבור) = the matching key column in the target table (e.g., COUNTRY)

2. **Imported column row** (e.g., COUNTRYNAME):
   - Set **Table Name** (שם טבלה) = the target table (e.g., COUNTRIES)
   - Leave **Join Table** and **Join Column** EMPTY
   - Mark as **Read-only**

**Common mistake:** Putting the join table/column on the imported row instead of the base table row causes "עמודת החיבור אינה מטיפוס זהה" (join column type mismatch) because Priority compares the imported column's type (e.g., CHAR) against the join column type (e.g., INT).

**Example — COUNTRY join in a custom airlines form:**

| # | Column | Table | Join Table | Join Column | Read-only |
|---|--------|-------|------------|-------------|-----------|
| 40 | COUNTRY | CL05_AIRLINES | COUNTRIES | COUNTRY | |
| 50 | COUNTRYNAME | COUNTRIES | *(empty)* | *(empty)* | Yes |

### Join Column Rules

Specify the join between tables explicitly via the **Join Column** and **Join Table**:

- Join columns must appear in the join table's unique (or autounique) key
- They must include **all** key columns
- **Foreign key columns must match the target table's column type AND width exactly.** A width mismatch (e.g., INT 11 vs INT 13) causes the same "join column type mismatch" error.

#### Multiple Joins

When imported form columns come from the same table column, use **Join ID** and **Column ID** to distinguish between joins.

**Example:** In `DOCUMENTS_T`, two warehouses both join to `WAREHOUSES.WARHS`:
- Sending warehouse: Join ID = 0, Column ID = 0
- Receiving warehouse: Join ID = 1, Column ID = 1

**Important:** When creating custom multiple joins, use join ID and column ID **greater than 5**.

#### Private Development on System Forms (IDCOLUMNE / IDJOINE)

When adding custom columns (SOF_ prefix) to system forms that import from system tables (INVOICES, DOCTYPES, DOCUMENTS — internal table ID < 5):

- **Cannot use TNAME/CNAME alone** — Priority rejects with "cannot add table with ID < 5"
- **Must set IDCOLUMNE** to a non-zero value (e.g., 6) to create a named join instance
- **Imported columns DO work with IDCOLUMNE > 0** *if* the base column carries the matching `JTNAME`/`JCNAME` at the same `IDJOINE` value. A prior debugging session concluded they "always return 0" — that was a misdiagnosis: the base column had no join defined, so there was nothing to ride on. With a real base-column join, imported columns at instance 6 populate correctly. Verified 2026-04-10 on CINVOICES.FTIP_COUNTRYNAME (IDCOLUMNE=6, IDJOINE=6) riding on CINVOICES.FTIP_FCOUNTRY (HIDEBOOL=Y, JTNAME=COUNTRIES, JCNAME=COUNTRY, IDJOINE=6).
- **Expression syntax** (when you need a computed value across instances): Use `TABLE.COLUMN` to reference any column regardless of IDCOLUMNE instance. Do NOT use `:$.COLUMN` — it scopes to the column's own IDCOLUMNE instance and won't find system columns (instance 0).
- **Form expressions are scalar-only.** The form column expression parser (`FCLMNA.EXPR` + `FCLMNTEXT` continuation) supports column refs, arithmetic, and string concatenation — NOT general SQL. Scalar subqueries like `(SELECT COUNTRYNAME FROM COUNTRIES WHERE COUNTRY = INVOICES.FTIP_FCOUNTRY)` fail to compile with `parse error at or near symbol SELECT`. If you need data from a foreign table, use a proper join (see the picker pattern below), not a subquery expression.
- **Subform expressions**: Subforms don't inherit parent form join context. Use `:$$.PARENT_COLUMN` to reference parent form expression columns.
- `READONLY="M"` (mandatory) conflicts with `HIDEBOOL="Y"` (hidden) — don't combine them

**Pattern — Adding a join and calculated columns on a system form:**

1. **Join column** (base table, establishes the join):

| Column | TNAME | CNAME | JTNAME | JCNAME | IDCOLUMNE | Notes |
|--------|-------|-------|--------|--------|-----------|-------|
| SOF_JOINKEY | BASETABLE | JOINKEY | JOINTABLE | JOINKEY | 6 | Establishes join, HIDEBOOL=Y |

2. **Expression columns** (reference joined data via TABLE.COLUMN):

| Column | EXPRESSION | WIDTH | IDCOLUMNE | Expression |
|--------|------------|-------|-----------|------------|
| SOF_JOINEDVAL | Y | 16 | 6 | `JOINTABLE.COLUMN` |
| SOF_CALC | Y | 16 | 6 | `BASETABLE.FIELD * JOINTABLE.COLUMN` |

3. **Subform expression** (references parent's expression column):

| Column | EXPRESSION | WIDTH | IDCOLUMNE | Expression |
|--------|------------|-------|-----------|------------|
| SOF_SUBCALC | Y | 16 | 6 | `SUBTABLE.FIELD * :$$.SOF_JOINEDVAL` |

#### Foreign-Key Pickers: the join IS the picker

**The search popup / dropdown on a foreign-key field comes from the JOIN, not from a CHOOSE-FIELD trigger.** Custom CHOOSE-FIELD triggers customize the query an existing picker runs — they do NOT create the UI affordance. A plain INT column with no join has no popup button in the web client, no matter what triggers you attach. This confuses new Priority developers repeatedly and wastes hours.

**The canonical pattern** (used by CUSTOMERS.COUNTRY, CINVOICES.TAXCODE, CINVOICES.DCODE, and every other foreign-key field in the system):

| Role | Example | TYPE | HIDEBOOL | TNAME | CNAME | JTNAME | JCNAME | IDCOLUMNE | IDJOINE |
|------|---------|------|----------|-------|-------|--------|--------|-----------|---------|
| **Base column** (ID storage) | `COUNTRY` | INT | **Y** | (base table) | `COUNTRY` | `COUNTRIES` | `COUNTRY` | 0 | 0 |
| **Display column** (user-facing, picker) | `COUNTRYNAME` | CHAR | (blank) | **`COUNTRIES`** | `COUNTRYNAME` | (blank) | (blank) | 0 | 0 |

The user interacts with the CHAR display column. Priority's web client shows a search popup because the column is imported from a joined table. On selection, Priority reverse-looks-up the foreign key by the name and fills the hidden INT base column via the join.

**IDJOINE instance selection:**
- **Form has no existing join to the foreign table** → use `IDJOINE = 0` on both rows (matches the CUSTOMERS.COUNTRY/COUNTRYNAME pattern exactly).
- **Form already has the foreign table joined via a different path** (e.g., CINVOICES already joins COUNTRIES transitively through CUSTOMERS) → use a new instance like `IDJOINE = 6`. The imported column's `IDCOLUMNE` MUST match the base column's `IDJOINE`.

**Triggers on hidden base columns.** POST-FIELD on the hidden INT column does NOT fire (user never interacts with it). Put POST-FIELD logic on the visible CHAR display column. Inside the trigger, `:$.THE_INT_COLUMN` still works because the join resolves the code before POST-FIELD runs.

**Do NOT:**
- Put a plain INT column visible and attach a custom CHOOSE-FIELD trigger. No UI affordance will render and the trigger will never fire. This is the single most common mistake on Priority forms.
- Try a scalar subquery as the display column's expression. Form expressions are scalar-only (see above).

#### Outer Joins

Outer joins allow unmatched rows between base and join tables. Add a question mark (`?`) to:
- **Column ID** (e.g., `0?`) -- if the null record is in the table from which the form column is derived
- **Join ID** (e.g., `0?`) -- if the null record is in the join table

Outer-joined tables are accessed **after** regular join tables.

### Calculated Columns

Calculated columns display data derived from other form columns. Values are **not stored** in any table -- they are filled in when the form row is exited.

**Steps to create a calculated column:**

1. Designate a unique column name in Form Columns
2. Specify position (Pos column)
3. Set `R` in Read-only/Mandatory if the value should not be revised (leave blank for updateable imported columns)
4. Set the column width (and decimal precision for REAL/shifted integer)
5. Specify a title in the Revised Title column
6. Enter the **Form Column Extension** sub-level form
7. Write the expression (SQL syntax) in Expression/Condition column (continue in sub-level if needed)
8. Set the column type (CHAR, INT, REAL, etc.) in Column Type

**Record-level condition:** Add a DUMMY column (name = `DUMMY`, table = `DUMMY`) with a condition preceded by `=1 AND`.

<!-- ADDED START -->
### Common Issues and Solutions

*   **Calculated Column Not Refreshing Automatically:**
    If a calculated column (such as a flag or status indicator) in a sub-form does not refresh when navigating to the record and requires a manual refresh (Ctrl+F11), check the SQL expression for the use of the `$` sign. Using the `$` prefix within the expression can affect how the value is cached or evaluated by the application server, potentially preventing real-time updates.

*   **Displaying Aggregated Data from Other Tables:**
    Calculated columns are the standard method for displaying real-time data from external tables that are not part of the form's base table. For example, to display the total inventory balance for a part within Sales Order lines, define a SQL expression in the **Form Column Extension** that selects the sum from the relevant inventory table based on the part number in the current row.

*   **Custom Date Formatting (e.g., Work Week/Year):**
    Standard date fields do not support non-standard formats like WW/YY (Work Week/Year) natively. To display dates in this format, create a calculated column with a SQL expression that converts the date value using SQL date-part functions to concatenate the week and year into a string.
<!-- ADDED END -->
### Custom Columns: Data Authorization

To apply data authorization to custom columns:

1. Enter `Data Privileges` form (`System Management > System Maintenance > Privileges > Data Privileges`)
2. Add a line specifying the custom Column, its Table, and the Main Column and Main Table it should be linked to

**Grant authorization to users:** Add lines to the `USERCLMNPRIV` table with:
- `USER` = username
- `COLUMNA` = the column name from `CLMNPRIV.MAINCOLUMN`
- `VALUE` = `*` for all data, or specific values on separate lines

### Split Reconciliation Forms

Special forms for financial reconciliations (`ACCRECONSP`, `BANKRECONSP`, `CREDITRECONSP`):
- Custom column names must begin with `FRST` or `SCND` prefix (e.g., `FRST_EXMP_MYNAME`)
- All custom columns must be read-only
- Create columns with both prefixes to show in both sides

### MDM Features

#### Supporting Transformation Interfaces (21.1+)

Add these private columns:
1. `XXXX_MYEMAIL` calculated column (CHAR type):
   ```sql
   (ENVIRONMENTA5.INTERNALID <> '' ?
   ENVIRONMENTA5.INTERNALID : SQL.ENV)
   ```
2. `XXXX_DNAME` column from `ENVIRONMENTA.DNAME` with join ID of 5, expression `SQL.ENV`
3. `EI_EMAIL` column from `CUSTOMERSA.MAILINTERCOMP` or `SUPPLIERSA.MAILINTERCOMP`

#### MDM-only Permissions (22.0+)

To limit forms/columns to MDM updates only:
1. Add a join to the `SEARCHDOCVERS` table
2. Add a form column named `FROMEDI` based on `SEARCHDOCVERS.FROMEDI`

---

## 3. Sub-level Forms

Forms are grouped into a tree-like configuration representing one-to-many or one-to-one relationships:
- **Root form** -- accessed directly from a menu (no upper-level)
- **Branches** -- sub-level forms, their sub-levels, etc.
- Any form can have **multiple sub-levels** on the same level

### Relationships

| Type | Description |
|---|---|
| One-to-many | Multiple records in sub-level linked to single record in upper-level (default) |
| One-to-one | Single record in sub-level linked to single record in upper-level |

To set one-to-one: specify `N` in the One-to-Many column of the Form Generator.

### Linking Upper-level and Sub-level Forms

Make the linkage through columns:
- If upper-level has an **autounique key**: link through that column
- Otherwise: link through each column of the **unique key**

**For updatable sub-levels:**
```
:formname.columnname
```
Example: `:ORDERS.ORD`

**For query sub-levels (read-only):**
```
=:formname.columnname
```
The `=` prefix allows users to delete records from the upper-level even when sub-level records exist.

Specify the condition in the **Expression/Condition** column of the Form Column Extension form.

**Wildcards:**
- `$$` = upper-level form name (e.g., `:$$.ORD`)
- `@` = current column name (e.g., `:$$.@`)

### Creating a Form Tree

Each sub-level form has a position integer that determines display order (lower = higher position). Use:
- **Sub-level Forms** form, or
- **Upper-level Forms** form (both are sub-levels of Form Generator)

### Linking to a Menu

Link the root form to a menu via the `MENU` table. Use:
- **Menu/Form Link** form (sub-level of Form Generator), or
- **Menu Items** form (sub-level of Menu Generator)

---

## 4. Conditions of Record Display and Insertion

### Query Condition (Record Display)

Restrict records from the base table that can be accessed. Begin the condition with a comparative operator (`<`, `>`, `<=`, `>=`, `<>`, `=`).

```sql
/* Example: Only show parts with positive balance */
>0
```

```sql
/* Example: Link query sub-level to upper-level */
=:WAREHOUSES.WARHS
```

The `=` operator allows deletion of upper-level records even when sub-level records exist (because it does not assign values to sub-level records).

### Assign Condition (Record Display and Insertion)

No comparative operator is used. This condition:
1. **Assigns a value** to the column in new records
2. **Restricts display** to records holding that value

**Sub-level linkage example:**
```
:ORDERS.ORD
```
This assigns the ORD value from ORDERS to new ORDERITEMS records and restricts display to items with that ORD value.

**Type distinction example:**
```
'D'
```
Written for the TYPE column of `DOCUMENTS_D` -- assigns type `D` to new records and only displays type `D` records.

---

## 5. Actions and Form Refresh

### Actions

Actions allow activating entities from within a form record:
- **Root form** -- loads the form and sub-levels
- **Report** -- runs the report
- **Procedure** -- runs the program or processes a report

Actions can run in **foreground** (user waits, form refreshes automatically) or **background** (user continues working).

### Form Refresh

To refresh a form periodically:
- Use the **Refresh Form** sub-level of Form Generator
- Specify seconds between refreshes
- Indicate whether to retrieve all records or only previously retrieved ones
- Refresh works per node (does not affect sub-levels)

**Other refresh methods:**
- `REFRESH` command in a trigger (do NOT use in POST-UPDATE/POST-INSERT triggers with BPM charts)
- `:ACTIVATEREFRESH = 1` in PRE-FORM trigger

---

## 6. Accessing Related Forms

### Target Form

When the user accesses an imported column, they can navigate to the target form. Requirements:
- Must be a **root form** (no upper-level)
- Base table must include the column the user originated from

**Automatic target:** When form name = base table name (default).

**Manual target designation (override priority, highest to lowest):**

| Type | How to Set | Scope |
|---|---|---|
| Specific target | Target Form Name in Form Column Extension | Single column |
| Application target | `Z` in Zoom/International column | Same application code |
| Main target | `M` in Zoom/International column | Entire application |
| Default target | Automatic (form name = table name) | Entire application |

**Disable access:** Specify the `NULL` form as target in Form Column Extension.

**Column name mismatch:** Enter both column names in the `ZOOMCOLUMNS` table (Source Column and Target Column).

### Dynamic Access

To vary the target form based on record data:
1. Define a hidden form column named `ZOOM1`
2. Specify `ZOOM1` as the target form in Form Column Extension
3. `ZOOM1` holds the internal number (EXEC) of the target form for each record
4. Initialize form variables in the PRE-FORM trigger

---

## 7. Text Forms

A text form is a one-column CHAR form for unlimited comments on a record.

**Automatic creation:** Run the **Create Text Form** program (`System Management > Generators > Forms`):
- Text form name = upper-level form name + `TEXT`
- Inherits the application code
- Title defaults to "Remarks"
- Only works for custom forms (with custom prefix)

### Text Form Variables

| Variable | Effect |
|---|---|
| `:$.READONLY.T = 1` | Makes text form read-only |
| `:$.NOEDITOR.T = 1` | Prevents opening text editor in non-HTML format |
| `:$.NOHTML.T = 1` | Creates a plain text form (default is HTML) |

### Removing HTML Tags

Use the `DELHTML` compiled program on a **linked copy** (never the original table):

```sql
:PART = 0;
SELECT PART INTO :PART FROM PART WHERE PARTNAME = '010';
SELECT SQL.TMPFILE INTO :TXT FROM DUMMY;
LINK PARTTEXT TO :TXT;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO PARTTEXT SELECT * FROM PARTTEXT ORIG
WHERE PART = :PART AND TEXT <> '';
UNLINK PARTTEXT;
/* text with HTML tags */
SELECT TEXT FROM PARTTEXT WHERE PART = :PART FORMAT;
EXECUTE DELHTML 'PARTTEXT', :TXT;
LINK PARTTEXT TO :TXT;
GOTO 99 WHERE :RETVAL <= 0;
/* same text without HTML tags */
SELECT TEXT FROM PARTTEXT WHERE PART = :PART FORMAT;
UNLINK PARTTEXT;
LABEL 99;
```

### Creating Text Subforms Manually

When the **Create Text Form** generator cannot be used (e.g., parent form has no custom prefix), create the text subform manually:

> **Text subforms are exempt from the "form generator UI required" rule.** For regular data-entry forms, creating a brand-new form via raw EFORM `newRow` fails `FORMPREP` with "אין מסך בשם זה" — you must use the Define Form generator. Text subforms (`EDES='LOG'`) do NOT have this restriction. You can create them entirely via WebSDK / OData and they compile clean on first try. This is because `EDES='LOG'` flags the form as a log/text form, which Priority initializes without the extra steps the Form Generator runs for normal forms. Verified 2026-04-10.


**1. Create the text table** (DBI):

The table needs 4 columns with a unique key on the parent link + line number:

```sql
CREATE TABLE prefix_PARENTTEXT
KLINE (INT, 13, 'Line (Key)')
TEXT (RCHAR, 68, 'Text')
TEXTLINE (INT, 8, 'Text Line')
TEXTORD (INT, 8, 'Text Sort')
UNIQUE (KLINE, TEXTLINE);
```

Replace `prefix_PARENT` with your entity name. KLINE links to the parent form's autounique key.

**2. Create the form** via EFORM (WebSDK or Form Generator UI):

| Property | Value | Notes |
|----------|-------|-------|
| ENAME | prefix_PARENTTEXT | Must have custom prefix |
| TNAME | The text table name | Can differ from ENAME |
| EDES | **LOG** | Required — controls HTML editor detection |
| TYPE | F | Form type |
| UPD | (blank) | Do NOT set to 'N' — blocks HTML editor |

**3. Add columns** with these exact flags:

| Column | Hidden | Expression | Triggers | ORD | Role |
|--------|--------|------------|----------|-----|------|
| KLINE | Y | Y | — | — | Parent key (autounique link) |
| TEXT | — | — | Y | — | Editable text content |
| TEXTLINE | Y | — | — | — | Line number |
| TEXTORD | Y | — | — | 1 | Sort order |

**4. Set the parent-link expression** (CRITICAL — this enables both CRUD and HTML rendering):

In the **Form Column Extension** (`FCLMNA_SUBFORM`) of the parent-link column (KLINE), set the expression to reference the parent form's key:

```
EXPR = :$$.KLINE
```

Via WebSDK:
```
filter EFORM(ENAME) → setActiveRow → startSubForm(FCLMN) → filter(NAME, "KLINE") → setActiveRow → startSubForm(FCLMNA) → newRow → fieldUpdate(EXPR, ":$$.KLINE") → saveRow
```

Replace `KLINE` with whatever the parent form's autounique column is called. Without this expression, `EXPRESSION=Y` alone does nothing — the subform won't link to the parent and won't render as HTML.

**5. Add triggers** (form-level and column-level):

Form-level triggers (adapt table/column names to your entity):
- **PRE-UPDATE**: `SELECT 0 + :SCRLINE INTO :$.TEXTORD FROM DUMMY ;`
- **POST-DELETE**: `UPDATE tablename SET TEXTORD = TEXTORD - 1 WHERE parentkey = :$$.parentkey AND TEXTORD >= :SCRLINE ;`
- **PRE-UPD-DEL-SCRLINE**: `SELECT TEXTORD INTO :SCRLINE FROM tablename WHERE parentkey = :$$.parentkey AND TEXTLINE = :$.TEXTLINE;`

Column-level POST-FIELD trigger on the TEXT column:
```sql
SELECT :SCRLINE INTO :$.TEXTORD FROM DUMMY ;
GOTO 1 WHERE :$.TEXTLINE > 0;
SELECT 1 INTO :$.TEXTLINE FROM DUMMY ;
SELECT MAX(TEXTLINE)+1 INTO :$.TEXTLINE
FROM tablename WHERE parentkey = :$$.parentkey;
UPDATE tablename SET TEXTORD = TEXTORD + 1 WHERE
parentkey = :$$.parentkey AND TEXTORD >= :SCRLINE ;
LABEL 1;
```

Always use `:$$.parentkey` (parent form reference), not `:$.parentkey` (current form).

**6. Link as subform** on the parent form via WebSDK (`startSubForm(FLINK) → newRow → fieldUpdate(ENAME) → saveRow`) or Form Generator UI.

**7. Compile** both the text form and the parent form.

**Key rules:**
- **`FCLMNA_SUBFORM.EXPR`** is the critical setting — it enables both parent-child data linking AND HTML editor rendering
- `EDES = 'LOG'` is required — controls text form detection by Priority's web client
- The Create Text Form generator (`TEXTFORM`) only works when the parent form has a custom prefix
- All trigger references to the parent key must use `:$$` (parent form), not `:$` (current form)
- Use `GOTO/LABEL` pattern in POST-FIELD trigger, not `END WHERE`

---

## 8. SQL Variables in Forms

### Form Column Variables

For each form column, Priority defines three variables:

| Variable | Description |
|---|---|
| `:FORMNAME.COLUMNNAME` | Current value on screen |
| `:FORMNAME1.COLUMNNAME` | Value stored in the table |
| `:FORMNAME.COLUMNNAME.TITLE` | The form column's title |

**Example:**
- `:ORDERITEMS.QUANT` -- ordered quantity currently displayed
- `:ORDERITEMS1.QUANT` -- ordered quantity stored in the database
- `:ORDERITEMS.QUANT.TITLE` -- title of the QUANT column

If updating an existing record and the line has not been exited, the screen value and table value may differ.

### Wildcards

| Wildcard | Meaning |
|---|---|
| `$` | Current form |
| `$$` | Upper-level form (one level up) |
| `$$$` | Two levels up |
| `@` | Current form column name |

**Example (ORDERITEMS form):**
```sql
:$.QPRICE = REALQUANT(:$.TQUANT)
* :$.PRICE * (100.0 - :$.PERCENT) / 100.0
* (:$$.CURRENCY = -1 ? :$.IEXCHANGE : 1.0);
```

**Example using previous value:**
```sql
GOTO 1 WHERE :$1.PARTNAME = '' OR :$.ORDI = 0;
GOTO 1 WHERE :$.@ = :$1.PARTNAME;
```

**Notes:**
- If `$$` refers to a non-existing form, Priority treats it as the current form
- `@` in a Row or Form trigger stands for the trigger name (e.g., POST-FORM)
- Wildcards are especially useful with `#INCLUDE` commands

### User-defined Variables

Define custom variables (e.g., `:CNT`):

```sql
:CNT = 0;
SELECT COUNT(*) INTO :CNT
FROM ORDSERIAL, SERIAL
WHERE ORDSERIAL.ORDI = :$.ORDI
AND ORDSERIAL.SERIAL = SERIAL.SERIAL
AND SERIAL.PEDATE > :$.DUEDATE
AND SERIAL.CLOSEDATE = 0;
```

**Naming rules:**
- In triggers for standard forms: use the four-letter prefix to distinguish from standard variables
- In triggers for custom forms: prefix is unnecessary
- Variable names limited to **50 characters** (including company prefix, two underlines, and period)

**Important:** User-defined variables have no automatic starting value -- set the value in a trigger:
```sql
SELECT 0 + :$.TQUANT, 0 + :$.QUANT INTO :TQUANT, :QUANT FROM DUMMY;
/* or simply: */
:TQUANT = :$.TQUANT;
:QUANT = :$.QUANT;
```

### Global Variables in Forms

In multi-company forms, user-defined variables automatically receive a company prefix (e.g., `:_comp1.SOMEVAR`).

To define a **global variable** (same value for all companies), add the `GLOBAL.` prefix:
```
:GLOBAL.SOMEVAR
```

This prevents the company-specific prefix from being added.

### The DUMMY Table

A single-record, single-column table used for variable assignments:
```sql
SELECT 0 + :$.TQUANT INTO :TQUANT FROM DUMMY;
```

`SELECT ... FROM DUMMY` does not actually access any table, making it very fast.

### Text Form Variables

| Variable | Effect |
|---|---|
| `:$.READONLY.T = 1` | Makes text form read-only based on upper-level status |
| `:$.NOEDITOR.T = 1` | Prevents non-HTML text editor |
| `:$.NOHTML.T = 1` | Creates plain text form |

---

## 9. Built-in Triggers

### Overview

Built-in triggers perform checks and update the database automatically. When a new record is entered and the line is exited:

1. Check that values are assigned to all unique key columns
2. If successful: exit line, insert record into base table, assign autounique key value (counter + 1)
3. If failed: error message, user cannot leave the line

### Field Triggers (Built-in)

When all unique key columns are filled in during insert mode:
- The entire record is automatically retrieved
- Automatic shift from insert mode to update mode

The built-in field triggers also:
- Verify imported data exists in join tables
- Fill in imported columns once all join table key columns are provided

**Example -- CHECK-FIELD (built-in):**
```sql
#line 1 ORDERS/CUSTNAME/CHECK-FIELD
GOTO 1 WHERE :ORDERS.CUSTNAME = '';
SELECT 'X'
FROM CUSTOMERS
WHERE CUSTNAME = :ORDERS.CUSTNAME;
SELECT 192 INTO :SCREENMSG
FROM DUMMY WHERE :RETVAL = 0;
LABEL 1;
```

**Example -- POST-FIELD (built-in) for fill:**
```sql
#line 1 ORDERS/CUSTNAME/POST-FIELD
SELECT CUSTDES, CUST, CUST, CURRENCY, LINKDATE, PAY, SHIPTYPE, MCUST,
NSFLAG, PAYCUST, SECONDLANGTEXT, VATFLAG
INTO :ORDERS.CUSTDES, :ORDERS.CUST, :ORDERS.CUSTA, :ORDERS.CUSTCURRENCY,
:ORDERS.CUSTLINKDATE, :ORDERS.CUSTPAY, :ORDERS.CUSTSHIPTYPE, :ORDERS.MCUST,
:ORDERS.NSFLAG, :ORDERS.PAYCUST, :ORDERS.SECONDLANGTEXT, :ORDERS.VATFLAG
FROM CUSTOMERS
WHERE CUSTNAME = :ORDERS.CUSTNAME;
```

### Insert Triggers (Built-in)

When a line is exited:
- Check all unique key columns have values
- Provide autounique key value (counter + 1)
- Insert the new record into the base table

### Update Triggers (Built-in)

In addition to insert trigger functions:
- Ensure no column linking forms has been updated
- Prevent changes to autounique key values

### Delete Triggers (Built-in)

Prevent violation of referential integrity:
- Do not allow deletion of records imported into other forms
- Check the column that links upper-level to sub-level forms

**Example:**
```sql
#line 1 ORDERS/DELETE
SELECT ENTMESSAGE('ORDERITEMS','F',0) INTO :PROGPARAM FROM DUMMY;
SELECT 94 INTO :PROGMSG
FROM ORDERITEMS WHERE (:$1.ORD <> 0 AND ORD = :$1.ORD);
```

**Important:** Built-in insert, update, and delete triggers only affect the form's **base table**. For other tables, write custom POST-INSERT, POST-UPDATE, and POST-DELETE triggers.

---

## 10. Custom Triggers -- Complete Reference

### Types of Triggers

| Trigger | Type | Description |
|---|---|---|
| CHECK-FIELD | Column | Verification checks on a column value |
| POST-FIELD | Column | Operations after column check succeeds |
| CHOOSE-FIELD | Column | Short list of values for user selection |
| SEARCH-FIELD | Column | Long searchable list for finding values |
| SEARCH-ALL-FIELD | Column | Multi-criteria search list |
| PRE-INSERT | Row | Checks before record insertion |
| POST-INSERT | Row | Operations after successful insertion |
| PRE-UPDATE | Row | Checks before record update |
| POST-UPDATE | Row | Operations after successful update |
| PRE-DELETE | Row | Checks before record deletion |
| POST-DELETE | Row | Operations after successful deletion |
| PRE-FORM | Form | Operations before form opens |
| POST-FORM | Form | Operations when form exits (if changes were made) |

### Where to Define Triggers

- **Column triggers** (CHECK-FIELD, POST-FIELD, CHOOSE-FIELD, SEARCH-FIELD): Form Column Triggers form and its sub-level Form Column Triggers - Text
- **Row triggers** (PRE-INSERT, POST-INSERT, etc.): Row & Form Triggers form and its sub-level Row & Form Triggers - Text
- **Form triggers** (PRE-FORM, POST-FORM): Row & Form Triggers form

### Order of Trigger Execution

1. CHECK-FIELD triggers precede POST-FIELD triggers
2. Built-in CHECK-FIELDs precede user-designed CHECK-FIELDs
3. Built-in POST-FIELDs precede user-designed POST-FIELDs
4. PRE- triggers precede their respective POST- triggers
5. Built-in triggers execute **after** PRE- triggers, **before** POST- triggers
6. Standard and custom triggers are **sorted alphabetically**

**Discontinuation rules:**
- Trigger execution stops when `END` or `ERRMSG` command succeeds
- Execution does **not** stop on `WRNMSG`
- If CHECK-FIELD fails, corresponding POST-FIELDs (built-in and user-designed) are **not** activated
- If PRE- trigger fails, the corresponding built-in trigger and POST- trigger are **not** activated

### Trigger Naming Conventions

Custom trigger names must:
- Contain only alphanumeric values, underscore (`_`), and hyphen (`-`)
- Begin with a letter
- Not include spaces
- Include a **four-letter prefix or suffix** for sorting purposes
- Include the required **key strings** separated by hyphens

**Required key strings:**

| Trigger Type | Required Key Strings |
|---|---|
| CHECK-FIELD | `CHECK` and `FIELD` |
| POST-FIELD | `POST` and `FIELD` |
| PRE-INSERT | `PRE` and `INSERT` |
| POST-INSERT | `POST` and `INSERT` |
| PRE-UPDATE | `PRE` and `UPDATE` |
| POST-UPDATE | `POST` and `UPDATE` |
| PRE-DELETE | `PRE` and `DELETE` |
| POST-DELETE | `POST` and `DELETE` |
| PRE-FORM | `PRE` and `FORM` |
| POST-FORM | `POST` and `FORM` |
| CHOOSE-FIELD | `CHOOSE` |

**Sorting control:** Choose the first letter of the prefix carefully. To run **after** a standard POST-INSERT trigger, name it `POST-INSERT_AXXX` or `ZXXX_POST-INSERT`.

**Combined triggers:** Combine key strings (e.g., `ARRH_POST-INSERT-UPDATE` runs for both insert and update). Combined triggers **cannot** contain cursors directly or via includes.

**SEARCH-FIELD exception:** Customized SEARCH-FIELD or SEARCH-ALL-FIELD triggers cannot be created. Only standard triggers are allowed.

<!-- ADDED START -->
### Common Issues and Solutions

- **Strict Naming in Cloud Environments:** In Priority Cloud environments, the system enforces strict naming conventions to ensure compatibility and security. Developers often encounter errors when using hyphens (`-`) as separators between the prefix and the trigger name. 
  - **Solution:** Use an underscore (`_`) instead of a hyphen to separate the four-letter prefix from the rest of the trigger name (e.g., `ACME_POST-INSERT` instead of `ACME-POST-INSERT`). This is a hard requirement in environments where the `DEVCENTER` constant is active and cannot be bypassed.

- **Prefix Length and Field Limits:** When defining triggers for fields with long names, the required prefix (4 characters plus an underscore) may cause the trigger name to exceed system character limits.
  - **Solution:** While reducing the prefix to 3 characters may bypass initial validation errors in some interfaces, it can prevent the trigger (especially search-related triggers) from activating correctly. Ensure the field name itself allows for the mandatory 4-character prefix and underscore.

- **Legacy Module Compatibility:** Legacy modules or automated code generators that use hyphens in trigger names will fail in modern Cloud installations.
  - **Solution:** All private modules and automated scripts must be updated to replace hyphenated prefixes with underscore separators to comply with current standard naming conventions.
<!-- ADDED END -->
### CHECK-FIELD

Perform verification checks on a column value. Only triggered when the user inserts or updates the value (not when simply moving through the column).

**Example 1 -- Restrict values:**
```sql
ERRMSG 4 WHERE :$.TYPE NOT IN ('O','R','P');
```
Message: "Specify P (part), R (raw material) or O (other)."

**Example 2 -- Warning on negative quantity:**
```sql
WRNMSG 105 WHERE :$.@ < 0;
```
Message: "The designated quantity is a negative number!"

### POST-FIELD

Perform operations after the column value passes verification. Useful for filling in values.

**Example -- Auto-fill date:**
```sql
/* POST-FIELD for SUPNAME in PORDERS form */
/* Inserts current date when opening a new purchase order */
:$.CURDATE = SQL.DATE8;
```

**Important:** When a POST-FIELD trigger changes another column's value, that column's POST-FIELD is activated but its CHECK-FIELD is **not**.

### CHOOSE-FIELD

Create a short list of values for user selection. Each column is restricted to 64 characters.

**Standard SQL query Choose:**
```sql
/* CHOOSE-FIELD for PARTNAME in PORDERITEMS */
SELECT DISTINCT PARTDES, PARTNAME
FROM PART WHERE PART =
(SELECT PART FROM SUPPART WHERE SUP = :$$.SUP AND VALIDFLAG = 'Y')
AND PART <> 0
ORDER BY 1;
```

**Rules:**
- First argument = description displayed to user
- Second argument = value inserted into the column
- Optional third argument = sort order
- Both arguments must be CHAR type (use `ITOA` to convert numbers)
- First argument is stored in `:PAR4` system variable for use by other triggers
- **The query MUST include a WHERE clause.** Save fails with `שאילתת CHOOSE חייבת לכלול תנאי WHERE`. For "all rows" use a tautology like `WHERE COUNTRY > 0`.
- **CHOOSE-FIELD does NOT create a picker UI.** It customizes the query an existing picker runs. A plain column with no join and no inherent picker will never invoke CHOOSE-FIELD regardless of the trigger code — see "Foreign-Key Pickers: the join IS the picker" above.

**Numeric sort fix:** Use `ITOA(m, 4)` to pad numbers with leading zeros for correct sort order.

**INT target column example** (both CHOOSE args must be CHAR, but the target column can be INT — Priority converts the returned CHAR back to INT via ATOI):

```sql
/* CHOOSE-FIELD on an INT country-code column */
SELECT COUNTRYNAME, ITOA(COUNTRY, 13)
FROM COUNTRIES WHERE COUNTRY > 0
ORDER BY 1;
```

**Constant values from messages:**
```sql
MESSAGE BETWEEN 100 AND 102;
```
Messages must be structured as: `Value, Description`

**Union Choose (multiple queries combined):**
Results are combined into a single list. Sort is determined by the first retrieved column.

To preserve query order instead of sorting:
```sql
/* NO SORT */
```

**Stop on first successful query:**
```sql
SELECT /* AND STOP */ ...
```

**Multiple Choose (MCHOOSE-FIELD):**
Allow selecting more than one value at a time.

**CHOOSE-FIELD for entire form:**
Define at the form level in Row & Form Triggers. This applies whenever the table column appears in any form (can be overridden by column-specific CHOOSE-FIELD triggers).

**Notes:**
- If the Choose list is empty or exceeds the `CHOOSEROWS` system constant, the SEARCH-FIELD trigger (if defined) is activated instead

### SEARCH-FIELD

Create a long searchable list for finding values:
- `SEARCH-NAME-FIELD` -- searches by number
- `SEARCH-DES-FIELD` -- searches by name/description
- `SEARCH-EDES-FIELD` -- searches by English name (non-English systems)

**Multiple Search:** Include `/* MULTI */` in the trigger to allow selecting multiple values.

**Restrictions:**
- Can only display table columns with width up to 59 characters
- Cannot create customized SEARCH-FIELD triggers (use standard triggers only)
- If user selects multiple values and a warning/error is generated, insertion stops

### SEARCH-ALL-FIELD

Create a multi-criteria search list. Users can search multiple attributes simultaneously.

**Shared across columns:** Use the `INCLUDES` comment to share the search list:
```sql
/* Example: SEARCH-ALL-FIELD in CUSTOMERS form */
/* Available in both Customer Number and Customer Name fields */
/* Comment: ORDERS.F > CDES */
```

**ORDER BY with regex:** All components (parentheses, periods, order priority numbers) must appear on a single line without interrupting spaces:
```sql
/* Correct: */
:ORDERBY > ((.*)PDES(.*)).3, (^(?!.*EPARTDES)(.*PARTDES)).3, EPARTDES.2

/* Incorrect (line break): */
:ORDERBY > ((.*)PDES(.*)).3, (^(?!.*EPARTDES)
(.*PARTDES)).3, EPARTDES.2
```

The system uses SEARCH-ALL-FIELD over regular SEARCH-FIELD by default (controlled by `SEARCHTYPE` system constant).

### PRE-INSERT

Perform verification checks before a new record is inserted.

**Example:**
```sql
/* Verify GL account is attached to cashier */
WRNMSG 1 WHERE :$.ACCOUNT = 0;
```

### POST-INSERT

Perform operations after a record is successfully inserted.

**Example:**
```sql
/* POST-INSERT in DOCUMENTS_Q inserts record into SERVCALLS table */
```

### PRE-UPDATE

Perform verification checks before a record is updated. Generally similar to PRE-INSERT.

**Example:**
```sql
/* Verify GL account is attached to cashier */
WRNMSG 1 WHERE :$.ACCOUNT = 0;
```

### POST-UPDATE

Perform operations after a record is successfully updated.

**Example:**
```sql
/* POST-UPDATE in DOCUMENTS_Q updates columns from SERVCALLS table */
```

### PRE-DELETE

Perform verification checks before a record is deleted.

**Example:**
```sql
/* Warn user about deleting bonus items */
WRNMSG 334 WHERE :$.BONUSFLAG IN ('Y','F');
```

### POST-DELETE

Perform operations after a record is successfully deleted.

**Example:**
```sql
/* Delete related record from ORDERITEMSA */
DELETE FROM ORDERITEMSA WHERE ORDI = :$.ORDI;
```

### PRE-FORM

Perform operations before the form opens. **Always activated** (unlike other triggers).

Applies to:
- All root forms
- Sub-level forms where Automatic Display is blank

**Common uses:**
```sql
/* Reset variable */
:MYVAR = 0;

/* Retrieve and display all records */
:KEYSTROKES = '\*{Exit}';

/* Refresh all records after an Action */
:ACTIVATEQUERY = 1;

/* Deactivate data privileges */
:$.NOCLMNPRIV.T = 1;

/* Deactivate data privileges for specific table */
:$.NOTBLPRIV.T = 'AGENTS';
/* With join ID: */
:$.NOTBLPRIV.T = 'AGENTS.5';

/* Activate PRE-FORM after every query */
:PREFORMQUERY = 1;
```

### POST-FORM

Perform operations when the form is exited, **provided** the user made at least one change.

**Example:**
```sql
/* Update Missing Components in upper-level form */
UPDATE SERIAL SET KITFLAG = 'Y' WHERE SERIAL = :$$.SERIAL
AND EXISTS
(SELECT 'X' FROM KITITEMS WHERE SERIAL = :$$.DOC AND TBALANCE > 0
AND KITFLAG = 'Y');
GOTO 1 WHERE :RETVAL > 0;
```

---

## 11. Error and Warning Messages

### ERRMSG and WRNMSG

Both generate a message when the condition is met:
- **ERRMSG**: Halts trigger execution
- **WRNMSG**: Trigger execution continues

**Syntax:**
```sql
ERRMSG number [ WHERE condition ];
WRNMSG number [ WHERE condition ];
```

**Example:**
```sql
ERRMSG 4 WHERE :$.TYPE NOT IN ('O','R','P');
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **Missing Message Definitions:**
    If a message number referenced in a trigger (e.g., `ERRMSG 501`) is deleted from the **Error/Warning Messages** form, the associated form will fail to load with a "Form needs preparation" error and will not compile.
    *   **Solution:** Ensure all referenced message numbers exist in the system. Custom messages should always use numbers greater than 500. Note that changes to these messages are system-wide and affect all companies.

*   **Visibility in Form Warning Messages Sub-level:**
    Users may wonder why certain custom warnings appear in the **Form Warning Messages** sub-level or the **Permission Explorer** while others do not.
    *   **Solution:** The system only logs and displays warning messages in these locations when they are triggered by row-level triggers: `PRE-INSERT`, `PRE-UPDATE`, and `PRE-DELETE`.

*   **Web Interface vs. Windows Client:**
    In some environments, `WRNMSG` commands may behave differently between the Windows Client and the Web interface (e.g., a warning appearing in one but not the other).
    *   **Solution:** This is often caused by a version mismatch between the server version and the system binaries. Ensure that the server and binary versions are synchronized to ensure consistent behavior of SDK commands across all interfaces.
<!-- ADDED END -->
### Specifying Message Content

Define messages in the **Error & Warning Messages** form (three interchangeable forms):
- `FORMMSG` -- sub-level of Form Generator
- `TRIGMSG` -- sub-level of Row & Form Triggers - Text
- `TRIGCLMSG` -- sub-level of Form Column Triggers - Text

**Rules:**
- New messages must have a number **greater than 500**
- The message number must match the number in the ERRMSG/WRNMSG command
- If a message continuation is needed, use the sub-level form

### Entity References in Messages

Reference Priority entities using: `{entity_name.F|R|P|M}`
- `F` = form, `R` = report, `P` = procedure, `M` = menu
- The entity's current title is displayed

**Example:**
```
The shipping address is identical to the customer's mailing address. See the {CUSTOMERS.F} form.
```

In error messages, the entity code is a clickable link. In warning messages, only the title appears.

### Message Parameters

Messages can include up to three parameters: `<P1>`, `<P2>`, `<P3>`.

Set values in the trigger via `:PAR1`, `:PAR2`, `:PAR3`:

```sql
/* CHECK-FIELD for PARTNAME in PORDERITEMS */
WRNMSG 140 WHERE NOT EXISTS
(SELECT 'X' FROM PARTPARAM WHERE PART =
(SELECT PART FROM PART WHERE PARTNAME = :$.@)
AND NSFLAG = 'Y')
AND NOT EXISTS
(SELECT 'X' FROM SUPPART, PART WHERE SUPPART.SUP = :$$.SUP
AND SUPPART.VALIDFLAG = 'Y'
AND SUPPART.PART = PART.PART AND PART.PARTNAME = :$.@);
```

Message 140: `Vendor <P1> does not supply this part.`

**Type conversion for parameters:**
- `:PAR1`, `:PAR2`, `:PAR3` are CHAR type
- Use `ITOA` for integers, `DTOA` for dates:
```sql
:PAR1 = DTOA(:$.CURDATE, 'MM/DD/YY');
```

### General Error Messages (GENMSG)

Create messages callable from any entity:
```sql
GENMSG number [ WHERE condition ];
```

Add messages via: `Compiled Programs form > GENMSG program > Program Messages` (number > 500).

### Displaying File Content as Message

Use `MESSAGEFILE` variable with message number `1000000`:
```sql
SELECT SQL.TMPFILE INTO :MESSAGEFILE FROM DUMMY;
SELECT 'Sample message' FROM DUMMY ASCII UNICODE :MESSAGEFILE;
ERRMSG 1000000;
```

This message number should **not** appear in the Error & Warning Messages form.

### Require Password Reentry (Web Only)

Use `WRNMSG` with message number `1000001`:
```sql
WRNMSG 1000001;
```

Results returned in `:PWD_RETVAL`:

| Value | Meaning |
|---|---|
| 1 | Username was changed, no password check performed |
| 2 | Username unchanged, password correct |
| 3 | Username unchanged, password incorrect |
| 4 | User pressed Cancel |

### Link to Document in Messages

Use format `<P1.FORMNAME.F>`:
```
Here is a link to order <P1.ORDERS.F>.
```

```sql
:PAR1 = 'SO1212888';
MAILMSG 1 TO USER :USER;
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **Hyperlinks in Warning Messages (WRNMSG):**
    Clickable hyperlinks (using the `<P1.FORMNAME.F>` syntax) are generally not supported in warning messages (`WRNMSG`) triggered within form triggers or `SQLI` steps of procedures. To ensure links are rendered correctly in procedures, use a dedicated **WRNMSG step** instead of an inline `SQLI` command. Note that clickable links are primarily supported in error messages and mail messages.

*   **HTML Rendering Issues (Version 24.1):**
    In version 24.1, messages containing both a dynamic parameter (e.g., `:PAR1`) and a document link may incorrectly display visible HTML tags. This is a known issue fixed in version 25.0. If an upgrade is not possible, test the message injection via a standard form shell script to bypass rendering bugs.

*   **Triggering Reports from Messages:**
    It is not possible to force a report to open or include a clickable link to a report within a form trigger message. Commands like `EXECUTE WINPROC` will fail to trigger a report popup in the web interface when called from a form trigger.
    ```sql
    /* This will not trigger a popup in the web interface via form triggers */
    EXECUTE WINPROC '-R', 'PRIT_ORDUSER ';
    ```
<!-- ADDED END -->
## 12. MAILMSG -- Sending Email

Mail messages are sent by internal or external mail to designated recipients, with optional attachments.

### Syntax

```sql
/* Send to internal user */
MAILMSG number TO USER :variable [ WHERE condition ];

/* Send to email address */
MAILMSG number TO EMAIL :email_variable [ WHERE condition ];

/* Send with attachment */
MAILMSG number TO EMAIL :email_variable DATA :file_variable [ WHERE condition ];
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **Customizing the Sender or Reply-To Address**
    To specify a different return address (e.g., a departmental email instead of the current user's address), use the `:_REPLYTOEMAIL` system variable. This functionality is supported when using server-side mail configurations (such as Office 365, Exchange, or Gmail). Note that this feature may not function when using a local Outlook client.
    
*   **Syntax Error in Documentation (DATA Keyword)**
    Ensure there is no comma after the `DATA` keyword when attaching a file. An extra comma will result in a syntax error.
    *Incorrect:* `MAILMSG 5 TO EMAIL 'demo@demo.com' DATA, :F;`
    *Correct:* `MAILMSG 5 TO EMAIL 'demo@demo.com' DATA :F;`

*   **Customizing Subject Lines**
    In procedures (including Priority Lite/HTML), the subject line is typically defined within the message template associated with the `number` argument. However, variables can be passed to the command to dynamically populate the message content and subject as defined in the message text setup.
<!-- ADDED END -->
### Examples

```sql
/* Send to internal user */
MAILMSG 9 TO USER :NEXTSIGN WHERE :NEXTSIGN <> 0
AND :NEXTSIGN <> SQL.USER;

/* Send to email address with attachment */
:EMAIL = 'johndoe@example.com';
:FILE = '..\tmp\msg.doc';
MAILMSG 5 TO EMAIL :EMAIL DATA :FILE;
```

**Tip:** Use Priority groups to define multiple recipients.

### Controlling Line Breaks

Include the following string in the message to enable HTML formatting:
```
<!--| priority:priform |-->
```

**Without HTML tags:**
```
Service Call request number: ILSC123456 was
updated by Customer.
Customer: CRR
Holding Company
Date&Time: 18/10/08 14:28
```

**With HTML tags (after the priform string):**
```
Service Call request number: <P1> was updated by Customer.<br><P2><br><P3>
```

Result:
```
Service Call request number: ILSC123456 was updated by Customer.
Customer: CRR Holding Company
Date&Time: 18/10/08 14:28
```

**Note:** Line break control does not support bi-directional languages (Hebrew, Arabic).

### Updating History of Statuses

Use MAILMSG to update the `DOCTODOLISTLOG` form:

```sql
:PAR1 = statustype;  /* document type */
:PAR2 = :iv;          /* autounique value of the record */
MAILMSG 1 TO USER -2;
```

**Example for Sales Orders:**
```sql
:PAR1 = 'O';      /* Type for ORDERS form */
:PAR2 = '15982';  /* Internal Document ID of Order A00098 */
MAILMSG 1 TO USER -2;
```

**Note:** This feature can only be used in a sub-level form, not in the root form.

### Sending a Link to a Document

Message definition: `Here is a link to order <P1.ORDERS.F>.`

```sql
:PAR1 = 'SO1212888';
MAILMSG 1 TO USER :USER;
```

---

## 13. Changing Column Titles Dynamically

Available for forms without a default design and with `T` in the One-to-many column.

**Set title in PRE-FORM trigger:**
```sql
:MYFORM.TEST.TITLE = 'New Title';
```

**Hide column dynamically:**
```sql
:MYFORM.TEST.TITLE = '';
```

<!-- ADDED START -->
### Common Issues and Solutions

**Finding Reference Examples**
*   **Problem:** Standard SDK examples (like `FRGROUPS_DET`) may be inaccessible if they belong to specific modules (e.g., Fashion) not included in your license.
*   **Solution:** For a reliable working example of dynamic column titles in a standard environment, refer to the **PRE-FORM** trigger of the **MATRIX** form.

**Dynamic Titles Across Different Companies**
*   **Problem:** Users need the same field to display different headers depending on the company logic or specific input from a procedure.
*   **Solution:** Use the `:FORM.COLUMN.TITLE` syntax in the **PRE-FORM** trigger to apply logic-based headers. While you can programmatically change the title for the same user across different companies, note that unique form *designs* (layouts) per company for the same user are not currently supported.

**Implementation Best Practices**
*   **Problem:** Attempting to update system tables directly to change column descriptions.
*   **Solution:** Direct updates to system tables for titles are not recommended. Always use the dynamic title variable assignment (`:FORM.COLUMN.TITLE = '...'`) within the form triggers to ensure system stability and compatibility with future updates.
<!-- ADDED END -->
## 14. INCLUDE Command and Buffers

### The #INCLUDE Command

Reuse triggers without rewriting:

```sql
/* Include a column trigger */
#INCLUDE form_name/form_column_name/trigger_name

/* Include a row/form trigger */
#INCLUDE form_name/trigger_name
```

**Example:**
```sql
/* CHECK-FIELD for TYPE column in LOGPART form */
#INCLUDE PART/TYPE/CHECK-FIELD
```

**Key points:**
- The entire contents of the included trigger are inherited
- Additional statements can be added before or after the `#INCLUDE`
- Changes to the included trigger affect all forms that include it (all must be re-prepared)
- No semicolon at the end of the `#INCLUDE` statement

### Using Buffers

Buffers share common SQL statements across multiple triggers.

**Example:**
```sql
/* Check CANCEL and FINAL status -- included in multiple form PRE-INSERT triggers */
#INCLUDE TRANSTRIG/BUF10
```

### Naming Buffers

- Numbered: `BUF1`, `BUF2`, ..., `BUF19` (pre-defined in List of Triggers)
- Named: descriptive names following the same rules as trigger names (no key strings allowed)
- Must be added to the **List of Triggers** form before use

### Nesting INCLUDE Commands

`#INCLUDE` can be nested: one trigger includes another, which includes a third, and so on.

**Example:** The `TRANSTRIG` form contains many buffers included by triggers in other forms.

### Wildcards in INCLUDEs

Wildcards (`$`, `$$`, `@`) have relative meaning depending on the form where the trigger is activated:
- `:$$.DOC` in Received Items = `:DOCUMENTS_P.DOC`
- `:$$.DOC` in Shipped Items = `:DOCUMENTS_D.DOC`

### Error and Warning Messages with INCLUDEs

Triggers inherit all SQL statements **and** their accompanying error/warning messages from included triggers. Message scope covers all triggers in the form.

### Checking Trigger Usage

View triggers that include the current trigger in the **Use of Trigger** sub-level form.

---

## 15. Trigger Errors

Form preparation fails on major trigger errors:
- SQL syntax errors
- Illegal or irresolvable variable types
- Syntax errors in `#INCLUDE` commands
- `#INCLUDE` commands referencing non-existent forms, columns, or triggers
- Form column variables referencing non-existent form/column combinations
- `ERRMSG` or `WRNMSG` commands referencing undefined message numbers

**Warnings** (preparation succeeds but should be fixed):
- Same local variable used for two distinct types (e.g., INT in one trigger, CHAR in another)

---

## 16. Form Preparation

### Preparing Forms

Prepare a form as an executable file before it can be accessed:

- **Automatic:** Triggered when opening an unprepared form
- **Manual (multiple forms):** Run `Form Preparation` program (`FORMPREP`) from `System Management > Generators > Forms`
- **Manual (single form):** Run `Prepare Form` by Action from the Form Generator

### Loading a Form

Use the `Load Form` program (`System Management > Generators > Forms`) or `Open Form` by Action from Form Generator.

**Restrictions:**
- An unprepared form cannot be loaded
- The form must not be linked to an upper-level (load the root form to access sub-levels)

### Repreparing Forms

If form preparation fails to replace the older version, use the `Reprepare Form` program by Action from the Form Generator.

**Help text changes** also require repreparing (remove existing preparation and re-execute).

<!-- ADDED START -->
### Common Issues and Solutions

*   **Customization Conflicts After Upgrades:**
    Errors during the "Prepare Forms, Reports and Procedures" (BIN) process after a version upgrade are often caused by private customizations or duplicates of standard forms. These custom entities must be manually updated to align with the new version's metadata before the preparation process can complete successfully.

*   **Synchronization Delays in Cloud Environments:**
    After adding new columns to a table (DBI) and preparing the associated form, you may encounter database errors when querying records in the web interface. In Priority Cloud environments, these errors are often due to caching or synchronization delays and typically resolve after a few minutes or a second preparation run.

*   **Broken Sub-level Dependencies:**
    Adding a sub-level form that references missing fields in the parent form can cause the preparation process to fail and leave the form in an "unprepared" state. If you are unable to delete the problematic sub-level via the UI, it may require manual removal of the metadata record followed by running preparation specifically for "unprepared" forms.

*   **Performance Issues from Non-Standard Customizations:**
    Using the Form Designer to add columns instead of the standard "Add Column" tool in the Form Generator can lead to severe performance degradation or record duplication (e.g., a single record appearing thousands of times). To resolve this, ensure all customizations follow SDK standards, restart the server services, and run a full "Form Preparation."

*   **Translation and UI Refresh:**
    If changes to "Translation of Form Column Titles" do not reflect in the UI after switching languages, the form must be reprepared to refresh the cached translation strings.

*   **Shared Code (#INCLUDE) Synchronization:**
    When a shared trigger (using `#INCLUDE`) is modified, the changes may appear in forms but not in procedures that include the same file. This often indicates an outdated system BIN version or a failure to recompile all dependent entities. Ensure the server's BIN folder is up to date and restart relevant services to force a full recompilation.

*   **Analyzing Preparation Error Reports:**
    If "Prepare Form" fails with an error report, the form will remain in an "unprepared" state and may be inaccessible. A developer must analyze the generated error report to identify specific metadata conflicts or syntax errors in triggers that are preventing the generation of the form's execution files.
<!-- ADDED END -->
## 17. Help Messages

**Maximum length:** 2000 characters for all help messages.

### Form Help

- **Entire form:** Help Text sub-level of Form Generator
- **Specific column:** Help Text sub-level of Form Columns
- Changes require **repreparing** the form (Reprepare Form program)

### Report Help

- **Entire report:** Help Text sub-level of Report Generator
- **Input column:** Help Text sub-level of Report Columns

### Procedure Help

- **Entire procedure:** Help Text sub-level of Procedure Generator
- **Parameter:** Help Text sub-level of Procedure Parameters
- Parameters of type `HELP` display content in the input window

### Referring to Entities in Help

Use `{entity_name.type}` where `F`=form, `R`=report, `P`=procedure:
```
See the {ORDERS.F} form for details.
```
The current title of the entity is displayed when help is accessed.

---

<!-- ADDED START -->
### Common Issues and Solutions

**Hyperlinks Displaying as Plain Text**
In version 21.1 and higher, entity references may occasionally fail to render as clickable links and appear as plain text. This is often caused by hidden characters or trailing spaces within the curly braces. To troubleshoot, verify the syntax against standard entities.
*   **Solution:** Ensure there are no hidden formatting characters within the tag. Test with a standard entity (e.g., `{PART.F}`) to determine if the issue is specific to a custom entity name.
*   **Example:**
    ```sql
    {SRII_DELSIMULPTREE.F}
    ```

**Version Compatibility and Rich Text (HTML)**
Help messages authored in version 21.1+ may utilize Rich Text/HTML tags that are not backward compatible with version 21.0 or earlier.
*   **Problem:** Help content appears corrupted or displays raw HTML tags in older versions of the software.
*   **Solution:** If the environment cannot be upgraded to 21.1, help text must be rewritten to exclude HTML tags, adhering to the plain-text standards of the 21.0 SDK.

**Syntax for Custom Help Messages**
When creating custom help for specific fields or forms, you can use the standard entity tagging system to create cross-references.
*   **Solution:** Use the `{ENTITY_NAME.TYPE}` syntax within the help text field to automatically generate a hyperlink to the target entity.
<!-- ADDED END -->
## 18. Default Designs for Forms

### Creating a Default Design

1. Open the form in Priority
2. Design using the **Organize Fields** utility (single-record view with tabs, and table view)
3. Open the form in Form Generator
4. Run **Set My Design as Default** from the Actions menu

### Notes

- Default designs replace screen-painting as the design method
- Existing screen-paintings take precedence over default designs
- Screen-painting files use internal form numbers:
  ```sql
  SELECT EXEC FROM EXEC
  WHERE ENAME = 'formname' AND TYPE = 'F' FORMAT;
  ```

### Distributing in a Revision

1. Open Version Revisions form, add a revision
2. Flag the `TAKEENTHEADER` step for inclusion
3. Enter `S` in the Designed Form field at upper level
4. Prepare the revision
