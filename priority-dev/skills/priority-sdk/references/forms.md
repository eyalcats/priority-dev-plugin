# Forms Reference

> Covers form creation, columns, joins, sub-level forms, conditions, actions, text forms, and SQL variables in forms. For triggers, error messages, MAILMSG, INCLUDEs, and form preparation, see `references/triggers.md`.

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
- [9. Managing forms and columns via WebSDK](#9-managing-forms-and-columns-via-websdk)

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

### Forms That Modify the USERS Table

Any form whose triggers contain `INSERT INTO USERS` or `UPDATE USERS` statements is **automatically designated as read-only** for all users except members of the system administrator group (tabula users). Priority enforces this at compile time — no manual read-only flag is needed and the restriction cannot be overridden for non-admin users.

**Implication:** Adding a trigger that writes to USERS on a previously writeable custom form causes that form to become read-only for ordinary users after the next compile. Test after every trigger change that touches the USERS table.

*(seen in: handbook:Forms@page-21)*

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

Use the `CREDITBAL` system constant to control whether debit or credit balances appear in parentheses. By default, debit balances appear in parentheses. To enable credit-balance-in-parentheses mode globally (applies to both forms and reports):

```sql
INSERT INTO SYSCONST (NAME, VALUE) VALUES ('CREDITBAL', 1);
```

After inserting this row, credit balances appear in parentheses instead of debit balances.

*(seen in: handbook:Forms@page-83)*

### Boolean Columns

A Boolean column must be:
- CHAR type
- Width of 1
- `FCLMN.BOOLEAN='Y'` — the web client reads this flag to render a checkbox. Without it, the column renders as a plain single-character text input.

When flagged: table value = `Y`. When blank: table value = `\0`.

When managing columns via WebSDK, set `BOOLEAN` alongside the other FCLMN fields on `saveRow` — omitting it produces a text input despite CHAR(1).

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

> **Anti-pattern: colliding IDJOIN with an existing base-form join causes row-multiplication.**
> If a private-dev imported column (`IDCOLUMN >= 5`) reuses the same `(IDJOIN, COLUMN)` pair as an already-present base-form row, Priority's compiler emits a defective join graph that cartesian-multiplies the form — symptom: filter on a single record returns N copies. Fix: use `IDJOIN >= 6` *and* `IDCOLUMN >= 6` for any custom instance of a column the base form already joins on. See `docs/solutions/database-issues/priority-form-row-duplication-astr-chain-2026-04-20.md`.

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

#### Exception: Updatable Imported Column

When an imported column must be **editable in the form** (the user can update it and have the change persist in the source table), the setup differs from a standard read-only imported column:

1. Do **NOT** specify a column name (`CNAME`) or table name (`TNAME`) on the FCLMN row.
2. Do **NOT** specify a join column or join table on the FCLMN row.
3. Instead, define the join in the **Form Column Extension** (FCLMNA) sub-level, the same way you record a calculated column.
4. Leave the Read-only/Mandatory column **blank** (not `R`) so the column is editable.

This is analogous to the calculated column pattern: the FCLMNA expression field defines the join target rather than a stored expression. The standard read-only rule (mark imported columns `R`) does **not** apply to this exception case.

**Example:** The `STARTDATE` column in the Service Calls form (`DOCUMENTS_Q`).

*(seen in: handbook:Forms@page-86)*

#### Outer Joins

Outer joins allow unmatched rows between base and join tables. Add a question mark (`?`) to:
- **Column ID** (e.g., `0?`) -- if the null record is in the table from which the form column is derived
- **Join ID** (e.g., `0?`) -- if the null record is in the join table

Outer-joined tables are accessed **after** regular join tables.

**Hard limit: maximum 10 outer joins per form** (marked with `?`). This total counts both existing standard outer joins and any added by custom development. Exceeding 10 will prevent the form from compiling. Always check how many standard outer joins the base form already has before adding custom ones.

*(seen in: handbook:Forms@page-21)*

**Chained outer joins:** When an outer-joined table is itself joined to a further table (a chain), the `?` mark must appear in **each** join ID along the chain, not only on the initial outer join. Omitting the `?` from a downstream join ID in the chain will cause unmatched rows to be silently dropped.

Example: FNCITEMS to FNCITEMSB (outer join, `?` on join ID) to COSTCENTERS (also needs `?` on its join ID because FNCITEMSB is outer).

*(seen in: handbook:Forms@page-87)*

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
- **Caution:** Enabling auto-refresh **disables the `TIMEOUT` system constant** for that form. Use sparingly — each refresh cycle accesses the server. If your form relies on TIMEOUT-based session logic, do not enable auto-refresh on that form.

*(seen in: handbook:Forms@page-96)*

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

### Dynamic Access (ZOOM1 pattern)

To vary the target form based on record data.

**Canonical reference form: `LOGFILE`** (shipped Priority inventory audit-trail form). Read its PRE-FORM trigger and its `ZOOM1` column's `FCLMNA.EXPR + FCLMNTEXT` continuation before designing a new dynamic zoom — it is the known-working template. Related examples that use the same pattern: `WTASKDOCS`, `DLVTRACKITEMS`.

**Three parts, all required:**

**1. Hidden `ZOOM1` form column**
- `NAME=ZOOM1`, `EXPRESSION=Y`, `HIDEBOOL=Y`, type INT (width 13)
- `FCLMNA.EXPR` is a **ternary that returns the target form's `EXEC` id per row**. Uses the `0 + :VAR` idiom to reference form-scoped variables initialized in PRE-FORM:

    (SOURCE.TYPE = 'O' ? 0 + :ORDEXEC :
     (SOURCE.TYPE = 'C' ? 0 + :CPROFEXEC :
      (SOURCE.TYPE = 'I' ? 0 + :AINVEXEC :
       (SOURCE.TYPE = 'D' ? 0 + :DOCDEXEC : 0))))

- Expressions longer than 56 chars must be split: first chunk on `FCLMNA.EXPR`, remaining chunks as ordered rows on the `FCLMNTEXT` sub-subform (table `FORMCLMNSTEXT`). Priority concatenates them at compile time.

**2. PRE-FORM trigger on the source form** initializes the form variables via `SELECT EXEC INTO :VAR FROM EXEC WHERE ENAME = '<form>' AND TYPE = 'F';` — one line per target form:

    SELECT EXEC INTO :CPROFEXEC FROM EXEC WHERE ENAME = 'CPROF'       AND TYPE = 'F';
    SELECT EXEC INTO :ORDEXEC   FROM EXEC WHERE ENAME = 'ORDERS'      AND TYPE = 'F';
    SELECT EXEC INTO :AINVEXEC  FROM EXEC WHERE ENAME = 'AINVOICES'   AND TYPE = 'F';
    SELECT EXEC INTO :DOCDEXEC  FROM EXEC WHERE ENAME = 'DOCUMENTS_D' AND TYPE = 'F';

For target families that vary by sub-type (`DOCUMENTS_*`, `*INVOICES`), reference `DOCTYPES.EXEC` / `IVTYPES.EXEC` directly in the ternary via a joined-table path — this is the pattern LOGFILE uses for its document and invoice branches.

**3. Displayed source column** carrying the visible doc-number value:
- `FCLMNA.EXPR` = a simple reference or conditional returning the display string (e.g., `SOURCE.DOCNO`)
- `FCLMNA.ENAME = "ZOOM1"` — the magic string that tells Priority "resolve the target form via the ZOOM1 column's computed value"
- `FCLMN.TRIGGERS = Y` (match LOGFILE/WTASKDOCS; the flag gates the clickable zoom handler in Web client in some builds)

**ZOOMCOLUMNS — when to add rows, and when NOT to:**

- `ZOOMCOLUMNS` (`NAME`, `TONAME`, `POS`) is **global by column NAME** — no form scoping. A row applies to every form whose column is named `<NAME>`.
- **If each target form's primary match column is its table's primary sort column** (`FCLMN.ORD > 0`, typically ORD=2 with ASCENDING=D — e.g. ORDERS.ORDNAME, CPROF.CPROFNUM, INVOICES.IVNUM, DOCUMENTS.DOCNO), **leave ZOOMCOLUMNS empty for your source column**. Priority falls back to the target form's primary ORD column automatically, which is the correct landing for these targets. Adding TONAMEs creates cross-target conflicts because the imported-column graph makes most TONAMEs match on most targets.
- **Add ZOOMCOLUMNS rows only when the fallback doesn't land on the right column** (unusual — e.g., your source column name doesn't match any target column and the target's primary ORD column isn't what you want).
- Priority's tie-break when multiple TONAMEs match a target is **pure POS ascending — NOT base-over-import**. If you must add rows and have shared-name imports (ORDNAME imported on almost every sales-adjacent form), expect the lowest-POS entry to win across all targets that import it.

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

In the **Form Column Extension** (`FCLMNA` subform) of the parent-link column (KLINE), set the expression to reference the parent form's key:

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
- **`FCLMNA.EXPR`** is the critical setting — it enables both parent-child data linking AND HTML editor rendering
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

## 9. Managing forms and columns via WebSDK

All form metadata changes flow through `websdk_form_action` on EFORM with filter + subform navigation. Never use raw table `INSERT`/`UPDATE` on FORMCLMNS, FORMCLMNSA, FTRIG, etc. — raw SQL bypasses EFORM's own validation and leaves the form uncompilable.

For the operation property reference, subform-name rules, and filter semantics, see `websdk-cookbook.md`. This section focuses on the recipes specific to columns, expressions, and subforms.

### Reading columns

```
filter(ENAME, "FORMNAME") → getRows → setActiveRow(1) → startSubForm(FCLMN) → setActiveRow(1) → getRows
```

`getRows` on an EFORM subform returns `{}` before `setActiveRow(1)`. Always activate before reading.

For bulk metadata (all columns across many forms), prefer SQLI on `FORMCLMNS` directly — `getRows` via WebSDK on EFORM subforms is optimised for single-row flows.

### Adding a column

```
filter EFORM (ENAME, "FORMNAME")
  → getRows → setActiveRow(1)
  → startSubForm(FCLMN)
  → newRow
  → fieldUpdate(NAME, "COLNAME")
  → fieldUpdate(CNAME, "COLNAME")
  → fieldUpdate(TNAME, "TABLENAME")
  → fieldUpdate(POS, "500")
  → fieldUpdate(HIDEBOOL, "N")
  → fieldUpdate(IDCOLUMNE, "6")   // for private dev on system forms
  → saveRow
```

Custom columns on system forms require `IDCOLUMNE > 5` (project rule; `IDCOLUMNE = 0` is reserved for system columns).

#### `fieldUpdate` ordering matters for expression columns

When creating an EXPRESSION column, set `EXPRESSION='Y'` **before** `WIDTH`. Priority validates WIDTH at `fieldUpdate` time and rejects it on non-expression/non-visible-imported rows:

```
Error: ניתן לקבוע/לשנות רוחב רק לעמודה חישובית או לעמודה מיובאת מוצגת בלבד
       (Width can only be set/changed for a calculated column or a visible imported column)
```

Correct order: `NAME → EXPRESSION=Y → TYPE → WIDTH → (other fields) → saveRow`.

#### Fallback: direct DBI INSERT when WebSDK `newRow` rejects the column name

WebSDK's FCLMN `newRow`+`saveRow` validates `NAME` against the base-table columns + all joined-table columns for the form. For a truly new scratch/expression column whose NAME exists in neither (e.g., a column imported from a donor form via `#INCLUDE` that the host never had), `saveRow` fails with `ערך לא קיים בקובץ` ("value does not exist in file") regardless of how you set `CNAME`/`TNAME`/`EXPRESSION`.

When WebSDK rejects a new NAME, a direct `INSERT INTO FORMCLMNS` succeeds — the underlying table accepts the row and compile treats it as a valid column:

```sql
INSERT INTO FORMCLMNS (FORM, NAME, COLUMN, JOIN, IDCOLUMN, IDJOIN, POS, WIDTH, HIDE, EXPRESSION, TRIGGERS, TITLE)
VALUES (<FORM_ID>, '<NEW_NAME>', 0, 0, 0, 0, <POS>, <WIDTH>, 'Y', 'Y', '', '<Hebrew or ASCII title>');

INSERT INTO FORMCLMNSA (FORM, NAME, EXPR, TYPE, DO)
VALUES (<FORM_ID>, '<NEW_NAME>', '<scalar expression or 0>', '<INT|CHAR|RCHAR|DATE|REAL>', 0);

COMMIT;
```

Compile after — the column behaves as a regular hidden expression column.

**When this is the right move:**
- `#INCLUDE` brought in code referencing a scratch variable that should live on the host form as a reset target (e.g., DLVTRACKITEMS' OLINE reset on a form that doesn't have OLINE).
- You're porting a column shape from a donor form and the WebSDK validation chain is blocking the port.

**When it's NOT:** any column that should be backed by a real base-table column or join. Use the canonical WebSDK flow for those — the validation is catching a real setup error.

This is a permitted bypass of the "form interface > raw UPDATE/INSERT" rule specifically for metadata tables that don't fire business triggers. Still requires explicit user approval and should be followed by a compile to verify.

*(Observed 2026-04-24: SOF_INVDOCS needed a scratch `OLINE` column because a `#INCLUDE DLVTRACKITEMS/DOCCODE/POST-FIELD` referenced `:$.OLINE`. WebSDK newRow failed on every field-combination attempt; direct INSERT into FORMCLMNS + FORMCLMNSA + compile worked first try.)*

### Deleting a column

```
filter EFORM → startSubForm(FCLMN)
  → filter(NAME, "COLNAME")
  → getRows (confirm count > 0 before proceeding)
  → setActiveRow
  → deleteRow
```

### Setting a column expression

```
FCLMN → filter(NAME, "COLNAME") → setActiveRow
  → startSubForm(FCLMNA)
  → newRow
  → fieldUpdate(EXPR, "<expression>")
  → saveRow
```

For expressions longer than ~80 characters, continue via `FCLMNA → setActiveRow → startSubForm(FCLMNTEXT) → newRow → fieldUpdate(TEXT, "…") → saveRow`.

**Expression scalar-only:** `FCLMNA.EXPR` rejects scalar subqueries. `(SELECT … WHERE …)` fails with `parse error at or near symbol SELECT`. Use a real join (imported column) or a POST-UPDATE trigger.

**Cross-instance references:** when `IDCOLUMNE > 0`, `:$.COLUMN` only sees columns in the same instance. Use `TABLE.COLUMN` to reference system columns (instance 0) or joined-table columns.

### FCLMNA.COND (conditional visibility) is NOT reachable via WebSDK

`FCLMNA.COND` is the field that controls conditional column visibility in the UI. It is not exposed through any WebSDK op. Workarounds:

1. **POST-FIELD trigger** on the triggering column that sets `:$.TARGETCOL.SHOW = 0/1`.
2. **Direct SQLI** `UPDATE` on `FORMCLMNSA` — only for dev-server setup, not runtime logic, and only with explicit user approval per the "form interface over raw UPDATE" rule.

### Creating a root form on a custom-prefix table (raw EFORM `newRow`)

Raw `newRow` on EFORM works for flat forms whose base table uses a custom prefix (`SOF_`, `ASTR_`, etc.). FCLMN auto-seeds from TNAME and the form compiles clean.

```
filter EFORM (ENAME, <new form name>)  // confirm 0 matches
  → newRow
  → fieldUpdate(ENAME, "SOF_MYFORM")
  → fieldUpdate(TITLE, "My Form")
  → fieldUpdate(TNAME, "SOF_MYTABLE")
  → fieldUpdate(EDES, "SOF")
  → fieldUpdate(MODULENAME, "פיתוח פרטי")
  → saveRow
```

Raw `newRow` is NOT safe for forms over system tables — those still require the UI-driven "New form" path (the form generator fills in system-column metadata that raw WebSDK does not reproduce).

### Creating a subform and linking it to a parent

FLINK rows have no parent-key/child-key fields. The join lives on the subform's own `FCLMN.EXPRESSION=Y` + `FCLMNA.EXPR=':$$.PARENTPK'`.

1. Create the subform root (same pattern as "Creating a root form" above, using the child table).
2. Add a key column on the subform with `EXPRESSION='Y'` and `FCLMNA.EXPR=':$$.<parent primary key>'`.
3. On the parent form, `startSubForm(FLINK) → newRow → fieldUpdate(SUBFORMNAME, "<subform ENAME>") → saveRow`.
4. Compile the subform first, then the parent.

For the canonical 6-call text-subform recipe, see `websdk-cookbook.md` § "Recipe: Text Subform Creation".

### Column trigger code — use DBI, not WebSDK `newRow`

`write_to_editor` returns `TRIGGER_NOT_FOUND` for column-level triggers. WebSDK `newRow` on FORMCLTRIGTEXT silently appends (produces duplicate lines that Priority parses as broken SQL at runtime).

Correct workflow:

```sql
/* Run via run_inline_sqli(mode="dbi") */
DELETE FROM FORMCLTRIGTEXT
  WHERE IDFORM = :IDFORM
    AND IDCOLUMN = :IDCOLUMN
    AND TRIGTYPE = '<type>';

INSERT INTO FORMCLTRIGTEXT (IDFORM, IDCOLUMN, TRIGTYPE, SEQ, TEXT)
VALUES (:IDFORM, :IDCOLUMN, '<type>', 1, '<line 1>'), …;
```

See `websdk-cookbook.md` § "Known bridge behaviors" for why.

### `filter` primitive — always `getRows` before `setActiveRow`

Without an intermediate `getRows`, writes after `filter` land on the wrong parent (EFORM's own meta-form). Use primitives explicitly; avoid the compound `createTrigger`, which has the same bug.

### FCLMNA.EXPR for foreign-table lookups: `<TABLE> WHERE <key> = :$.<local_fk>`

When an expression column pulls a display value from a joined foreign table, the `FCLMNA.EXPR` body uses a two-token shape that is NOT general SQL:

```
ACCOUNTS   WHERE ACCOUNT = :$.ACCOUNT
COUNTRIES  WHERE COUNTRY = :$.FCOUNTRY
TAXES      WHERE TAX     = :$.TAX
```

No `SELECT`. No `FROM`. The foreign-table name is the first token; the `WHERE` clause matches the foreign key column (left side) to the local form column holding the FK value (right side, via `:$.<col>`). The column being returned is whichever `CNAME` sits on the parent `FCLMN` row.

Common mistakes:
- Writing `SELECT COUNTRYNAME FROM COUNTRIES WHERE …` → parse error (`FCLMNA.EXPR` is scalar-only; no sub-SELECTs — see "scalar-only" notes elsewhere in this file).
- Putting both names as `:$.<name>` on each side — the left must be the literal foreign column name, not a variable reference.
- Expecting column names to match — they don't need to. In LOGPART, `FTIP_COUNTRYNAME` uses `COUNTRIES WHERE COUNTRY = :$.FCOUNTRY` (local column is `FCOUNTRY`, foreign key is `COUNTRY`).

Use this shape for any "display a column from a joined table" expression-column setup. The alternative — a real join through `JTNAME`/`JCNAME` on the base-column row plus an imported column — is still preferred when the picker UI is wanted (see "Foreign-Key Pickers: the join IS the picker"). The FCLMNA.EXPR shape is for columns that are expression-only (`EXPRESSION=Y`, no base-table storage).

*(seen in: LOGPART + ~40 more forms via `FORMCLMNSA.EXPR LIKE '% WHERE % =%' AND EXPR NOT LIKE '%SELECT%' AND EXPR NOT LIKE '%FROM%'`)*

⚠ **Verify before relying on this pattern** — on at least one tenant (`lp1378/demo`, 2026-04-24) the two-token `<TABLE> WHERE <key> = :$.<col>` shape **failed to compile** even when the RHS form variable was a valid form column. Observed errors: `parse error at or near symbol WHERE` (compiler doesn't recognize the shape) and `parse error at or near symbol ;` (when the body was being evaluated with an empty expansion). Inventory query on that tenant showed the pattern in use on the `F` template form only, and `F` itself didn't cleanly compile.

Diagnostic before using the pattern on a new tenant:
```sql
/* Is there any OTHER production form (not 'F') successfully using this shape? */
SELECT E.ENAME, A.NAME, A.EXPR
FROM   FORMCLMNSA A, FORMCLMNS FC, EXEC E
WHERE  A.FORM = FC.FORM AND A.NAME = FC.NAME
AND    A.FORM = E.EXEC AND E.TYPE = 'F'
AND    A.EXPR LIKE '% WHERE % = :$.%'
AND    A.EXPR NOT LIKE '%SELECT%'
AND    FC.EXPRESSION = 'Y'
AND    E.ENAME <> 'F'
FORMAT;

/* Cross-check: are those forms clean in PREPERRMSGS? */
SELECT FORMNAME, COUNT(*) FROM PREPERRMSGS GROUP BY FORMNAME FORMAT;
```

If the first query returns rows on forms that appear clean in the second query, the pattern works on the tenant. Otherwise, fall back to:
- a real table join (`JTNAME`/`JCNAME` on the base column + imported display column), or
- a direct `<TABLE>.<COLUMN>` scalar expression — only when the foreign table is already joined into the form's query plan via another imported column.

### Shared trigger libraries via `#INCLUDE func/<Name>`

Priority ships a `func` namespace (form with `ENAME = 'func'`) that holds reusable trigger bodies. Consumer forms seed input variables, pull the body via `#INCLUDE func/<Routine>`, then read output variables from the routine:

```sql
#INCLUDE func/Language
#INCLUDE func/DecimalPrecision
#INCLUDE func/CheckTax
#INCLUDE func/CheckRestricted
#INCLUDE func/LoadAppCond
```

No arguments, no return value — pure variable-passing contract. Check an existing consumer (e.g. ORDERS PRE-FORM) for the exact var names each routine expects.

Cross-form hygiene checks follow the same pattern but live on an authoritative form rather than the `func` library: `#INCLUDE ORDERS/BUF12 /* check NS customer */`, `#INCLUDE CPROF/BUF11 /* check cust<->plist */`, etc. The comment after the include names the concern — keep it when copying.

*(seen in: ~250 forms via `FORMTRIGTEXT LIKE '%#INCLUDE func/%'`; cross-form BUF<n> pattern in ORDERS, CPROF, CINVOICES, CUSTOMERS and ~40 more)*

### Hidden DUMMY/DUMMY/DUMMY scaffolding column

A `FCLMN` row with `NAME=DUMMY`, `CNAME=DUMMY`, `TNAME=DUMMY`, `TYPE=INT`, `HIDEBOOL=Y` (and usually `ORD=1`) is a scaffolding primitive for attaching conditional blocks or record-level conditions without disturbing the real base-table columns. The `DUMMY` "table" is Priority's single-row constant table — nothing is read or written, it just gives the form somewhere to hang an `FCLMNA.EXPR` or a condition clause.

*(seen in: LOGPART + ~40 more forms via `FORMCLMNS WHERE NAME='DUMMY' AND HIDE='Y'`)*

### Expression + READONLY=M for computed display columns

Custom forms routinely pair `EXPRESSION='Y'` with `READONLY='M'` (modify-only, not insert) to implement derived display columns that are computed by a CHOOSE/FIELD or POST-FIELD trigger on save but cannot be re-typed at insert time. `READONLY='R'` (forever read-only) is the alternative when the column is pure-display. Combining with `TRIGGERS='Y'` enables the trigger surface used to recompute the value.

Common mistake: pairing `READONLY='M'` with `HIDEBOOL='Y'` — they conflict, don't combine them.

*(seen in: LOGPART, SOF_FORMS, SOF_MANAGEPASS + 100 more forms via `FORMCLMNS WHERE EXPRESSION='Y' AND READONLY='M'`)*
