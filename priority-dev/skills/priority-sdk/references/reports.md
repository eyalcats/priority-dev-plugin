# Reports Reference

## Table of Contents

- [Introduction](#introduction)
- [Create a Report](#create-a-report)
- [Copy a Report](#copy-a-report)
- [Report Attributes](#report-attributes)
- [Report Columns](#report-columns)
  - [Column Attributes](#column-attributes)
  - [Add Report Columns](#add-report-columns)
  - [Column Numbers](#column-numbers)
  - [Join Columns](#join-columns)
  - [Hide Columns](#hide-columns)
  - [User Input Columns](#user-input-columns)
  - [Predefined Query Conditions](#predefined-query-conditions)
  - [Access a Related Form (Target Form)](#access-a-related-form-target-form)
  - [Special Report Columns](#special-report-columns)
- [Organize Report Data](#organize-report-data)
  - [Distinct Records](#distinct-records)
  - [Sorting](#sorting)
  - [Grouping](#grouping)
  - [Headers](#headers)
  - [Display of Grouped Records](#display-of-grouped-records)
  - [Group Functions](#group-functions)
  - [Column Functions (Col. Func.)](#column-functions-col-func)
  - [Additional Sub-totals](#additional-sub-totals)
- [Refine Report Data Display](#refine-report-data-display)
  - [Spacing Between Rows](#spacing-between-rows)
  - [Width, Decimal Precision, and Column Title](#width-decimal-precision-and-column-title)
  - [Date Displays](#date-displays)
  - [Non-display of Zero Values](#non-display-of-zero-values)
  - [Display HTML Text in Reports](#display-html-text-in-reports)
  - [HTML Design](#html-design)
  - [Design Reports Using CSS Classes](#design-reports-using-css-classes)
- [Calculated Report Columns](#calculated-report-columns)
  - [Create a Calculated Column](#create-a-calculated-column)
  - [Display Alternative Date Formats](#display-alternative-date-formats)
  - [Add a Condition for a Calculated Column](#add-a-condition-for-a-calculated-column)
  - [Add Conditions in a Group By Column (HAVING)](#add-conditions-in-a-group-by-column-having)
  - [Use a Complex Function](#use-a-complex-function)
- [Types of Reports](#types-of-reports)
  - [Tabular Reports](#tabular-reports)
  - [Multi-Company Reports](#multi-company-reports)
  - [Processed Reports](#processed-reports)
- [Run Reports](#run-reports)

---

## Introduction

Construct and modify reports in the **Report Generator** form and its sub-levels (`System Management > Generators > Reports`).

Reports selectively display data stored in the database, as well as simple calculations (e.g., sum totals) and complex calculations defined by SQL expressions. Most Priority reports are embedded in procedures (processed reports).

Create **standard** and **tabular** reports (tables). Reports tend to be more detailed; tabular reports show summarized information.

A report is characterized by:
- A unique name and title
- A set of report columns derived from one or more database tables
- Calculated columns (optional), whose values are determined by other columns

## Copy a Report

Use the **Copy Report** program to copy an existing report. It copies:
- All report columns and their attributes
- All expressions for calculated columns
- Any designated target forms
- The output title (if any)

It does **not** copy report tables, or links to procedures, menus, or forms.

Copy a report when you want to change the sorting or grouping of columns.

## Report Attributes

### Report Name

Follow these naming restrictions:
- Only alphanumeric values and underline sign (no spaces)
- Must begin with a letter
- Cannot use reserved words
- Prefix newly created reports with a common **four-letter prefix** (e.g., `XXXX_ORDERS`)

### Report Title

- Restrict to 32 characters
- Designate a longer title in the **Output Title** sub-level form
- Use to distinguish between the menu item and the report heading

### Application

Classify reports by data type (e.g., `FNC` for Financials). For new custom reports, specify a code word that aids in retrieval.

### Module

Determine which Priority packages include the report. For new custom reports, specify **"Internal Development"** to ensure availability regardless of purchased modules.

---

## Report Columns

### Column Attributes

Report columns inherit the **name**, **title**, **type**, **width**, and **decimal precision** from their source table columns. Modify all attributes except column name.

Define columns in the **Report Columns** sub-level of the Report Generator form.

### Add Report Columns

**Automatically:** Enter the **Report Tables** sub-level and specify all source tables. Columns are positioned in the order tables are specified.

**Manually:** In the Report Columns form, specify:
- **Pos** (column position) -- an integer determining display order
- **Column Name** -- the database column name
- **Table Name** -- the source table

Follow the same naming rules as report names (alphanumeric + underline, begins with letter, no reserved words, four-letter prefix for custom columns).

<!-- ADDED START -->
### Common Issues and Solutions

*   **Custom Fields in Standard Reports:** Custom development fields (private developments) are not automatically available in standard system report generators (e.g., Sales Order reports). Adding these fields typically requires custom development rather than simple configuration via the Report Generator.
*   **Columns Not Appearing in HTML Output:** If a newly added column does not appear in the HTML output of a copied system report, check the **Report Columns - Extension** sub-level. Clearing any existing values in this sub-form for that specific column (even if they appear empty) can resolve display issues.
*   **Report Hanging During Calculation:** Adding complex fields, such as status columns, to certain standard reports (e.g., Inventory Transfer) via the Report Generator may cause the report to hang. This indicates that the specific report structure cannot handle the join via the standard generator and requires a custom-developed report.
*   **Deleting Incorrectly Added Columns:** If columns are added to the wrong report, they must be deleted using **CTRL+Delete**. Note that if the column has any definitions in the **Extension** sub-form, those records must be deleted first before the main column entry can be removed.
*   **Adding Columns to Procedure-Generated Reports:** To add fields to a report generated by a custom procedure, you must locate the specific report entity associated with the relevant procedure step in the **Procedure Generator** and add the columns there following standard naming conventions.
<!-- ADDED END -->
### Column Numbers

Each column is identified by a unique **column number** assigned automatically. Use this number to reference the column in expressions.

For custom columns, manually assign a column number **>= 500** to prevent conflicts with future Priority releases.

### Join Columns

Link data from multiple tables using join columns to ensure correct record combinations are displayed. Specify both the **Join Column** and its **Join Table**.

Without join columns, the report displays all possible combinations (Cartesian product) of data from included tables.

For custom joins to standard reports, assign a **Join ID greater than 5**.

#### Multiple Joins

When two or more report columns join through the same table column, use **Column IDs** and **Join IDs** to distinguish between them.

For custom multiple joins, use a **Join ID and Column ID greater than 5**.

#### Outer Joins

Use an outer join to allow for unmatched rows between joined tables. Add a **question mark (?)** to the relevant Column ID or Join ID:
- `?` on Column ID -- null record expected in the column's source table
- `?` on Join ID -- null record expected in the join table

Outer-joined tables are accessed after regular join tables.

### Hide Columns

Flag the **Hide** column to prevent a column from displaying during output.

Hidden columns can still be used for sorting, joins, and expressions.

### User Input Columns

Flag the **Input** column to include a column in the parameter input screen. For Boolean (Y/N) checkbox input, also specify `B` in the **Don't Display 0 Val** column (CHAR column with width of 1 only).

### Predefined Query Conditions

Use the **Expression/Condition** column of the Report Column Extension form to set permanent query conditions:
- Write in SQL syntax
- Begin with a comparative operator (`<`, `>`, `<=`, `>=`, `<>`, `=`)
- Maximum length: 3000 characters
- Continue in the **Expression/Condition (cont.)** sub-level if needed

### Access a Related Form (Target Form)

Access target forms by pressing F6 twice from a report column. The target form must:
- Be a root form (no upper-level form)
- Have a base table that includes the originating column

Override the default target form by:
- Designating a **main target form** (type `M` in Zoom/International column)
- Designating an **application target form** (type `Z`)
- Specifying a form in the **Target Form Name** column of Report Column Extension

To disable automatic access, specify the `NULL` form as the target.

#### Dynamic Access

Vary the target form based on record data using the **Report Columns-HTML Design** sub-level, Link/Input tab:
- Link/Input Type = `P`
- Return Value Name (`:HTMLACTION`) = `_winform`
- Return Value Column# (`:HTMLVALUE`) = column number containing the ENAME of the target form
- Internal Link Column# = same as `:HTMLVALUE`

Note: The column with the ENAME of the target form must have a Sort value.

#### Access from a Non-Unique Key Column

Use the Report Columns-HTML Design sub-level, Link/Input tab:
- Link/Input Type = `P`
- Return Value Name (`:HTMLACTION`) = `_winform`
- Return Value Column# (`:HTMLVALUE`) = column number containing the key of the target form
- Internal Link Column# = leave empty
- Target Form (Choose) = the name of the target form

### Special Report Columns

#### Display an Address in Google Maps

In the Link/Input tab of Report Columns-HTML Design:
- Link/Input Type = `Q`
- Return Value Name (`:HTMLACTION`) = any value (do not leave empty)
- Return Value Column# (`:HTMLVALUE`) = column number with the address

#### Display QR Codes

In the Picture tab of Report Columns-HTML Design:
- Picture = `Q` (standard) or `q` (unicode text file encoding, version 22.0+)
- Set Width [pixels] and Height [pixels] to equal values (QR codes are square)
- Unicode file limit: 1663 characters

For unicode QR (`q`), set the column contents to the unicode text file to encode. State the file explicitly or as a variable from the printing program.

---

## Organize Report Data

### Distinct Records

Flag the **Distinct** column of the Report Generator form to prevent duplicate records.

### Sorting

Assign sort priorities to one or more columns in the Report Columns form. Sort types:
- Ascending (default)
- Descending
- Alphanumeric ascending
- Alphanumeric descending

Sort by a column that is not displayed in the output as needed.

**Do not change the sorting of a standard report** -- copy it instead.

### Grouping

Assign an integer in the **Group by** column of the Report Columns form:
- Set the first "Group by" column to `1`
- Assign all "Group by" columns from the same table the same integer (same set)
- Records are grouped by the set with the lowest integer first

From one group to another, identical values are not repeated.

Grouping affects the **collapse/expand** functionality of reports (+ and - symbols).

**Do not change the grouping of a standard report** -- copy it instead.

### Headers

Place "Group by" columns in report headers to save horizontal space:
- `H` in the Header column -- begin a new line in the header
- `h` in the Header column -- continue on the same line

Both the title and value appear in the header. To display value only, add a semicolon to the left of the revised column title (e.g., `;Customer Name`).

### Display of Grouped Records

- **Repeat values**: Specify `1` in the **Repeat Group (1)** column for the first "Group by" set
- **New page per group**: Specify `-1` in the **Skip Lines** column for the first "Group by" set
- **User-controlled page break**: Use `:GROUPPAGEBREAK` system variable in the procedure
- **Blank lines after group** (documents only): Specify an integer (up to 10) in Skip Lines

<!-- ADDED START -->
### Common Issues and Solutions

*   **Page Breaks Failing After Version Upgrades**: If group-based page breaks (Skip Lines = -1) stop functioning after a system upgrade, ensure that the BIN95 client files are updated to the latest minor version. Standard page break functionality relies on specific client-side rendering logic that may require synchronization with the server version.
*   **Collapse/Expand Functionality Not Working**: In reports with multiple grouping levels, the collapse/expand feature may fail if manual sorting is applied to columns.
    *   **Solution**: Remove values from the **Sort** column for the grouped fields. Sorting on these columns can interfere with the SQL SELECT structure required for hierarchical grouping. Ensure grouped columns are consistently defined in both the report headers and the grouping definitions.
*   **Intermittent Single Row per Page**: If a report intermittently displays only one record per page instead of grouping them:
    *   **Solution**: Verify that the grouping levels are defined on unique identifiers. If the "Group by" field contains inconsistent data or if the header/group configuration is misaligned, the report engine may trigger a page break for every record transition.
<!-- ADDED END -->
### Group Functions

Set in the **Group Func.** column of Report Columns:

| Value | Function |
|-------|----------|
| `S` | Totals for each group |
| `R` | Sub-totals for a portion of the group / Repeat previous string value |
| `T` | Totals for the entire report |
| `B` | Both group totals and report total |
| `A` | Cumulative balances within each group |
| `C` | Constant value added to the cumulative balance |
| `H` | Row totals (tabular reports only) |
| `s`, `t`, `b` | Complex total functions (with Col. Func = `F`) |

For complex total functions (`s`, `t`, `b`), designate `F` in the **Col. Func** column. The expression must reference a calculated column defined in Report Column Extension with Column Type of REAL.

### Column Functions (Col. Func.)

| Value | Operation |
|-------|-----------|
| `S` | Sum total |
| `A` | Average |
| `I` | Minimum value |
| `M` | Maximum value |
| `F` | Complex function (defined in Report Column Extension) |

When a column function is specified, only the result is displayed (values compressed into a single line).

Combine column and group functions as needed.

### Additional Sub-totals

- Add a hidden column with the title **`#ACCTOTAL`** to include sub-totals up to a specific point
- Add a hidden column entitled **`#TOTALSIGN`** to multiply report lines by its value when calculating totals (useful for displaying positive values while treating them as negative in totals)

---

## Refine Report Data Display

### Spacing Between Rows

Use a hidden column with the title **`#LINEHEIGHT`** (INT type) to add fixed space between all rows.

### Width, Decimal Precision, and Column Title

Report columns inherit width, decimal precision, and titles from source table columns. Revise these as follows:
- **Width**: Delete the inherited value and specify the desired width
- **Decimal Precision**: Modify in the Display Mode column (be careful with INT columns)
- **Title**: Override by specifying a new title in the **Revised Title** column

Note: A decimal precision of 0 for a REAL column rounds off to an integer in reports.

### Date Displays

Determine date formats using display mode and width:
- Day of the week alongside date: Display Mode = `1`, Width >= 12
- Time as well as date: Width between 14 and 19 depending on display mode
- Custom format: Use a calculated column with DTOA

### Non-display of Zero Values

Set in the **Don't Display 0 Val** column:

| Value | Behavior |
|-------|----------|
| (blank) | Display zero values (default) |
| `Y` | Leave column blank for zero values |
| `A` | Leave both columns and totals blank when zero |
| `B` | Boolean (Y/N) checkbox input (CHAR width=1 only) |

Force display of a column with all NULL values using a ternary expression:
```sql
(ORDERS.DETAILS <> '' ? ORDERS.DETAILS : '&nbsp')
/* '&nbsp' is a non-breaking space in HTML */
```

### Display HTML Text in Reports

Three types:
1. **Fixed component report** displaying only text (e.g., `WWWORD_4`)
2. **Fixed component** with "Group By" fields in first line and text in second line (e.g., `CUSTNOTESSUM`)
3. **Tabular component** with "Group By" fields and text under column title (e.g., `WWWORD_2X`), requiring:
   - A join of the DAYS table with expression `DAYS.DAYNUM BETWEEN 0 AND 1`
   - A real join of the text table when `DAYS.DAYNUM = 1`; join of zero record when `DAYS.DAYNUM = 0`
   - An expression field (width = 68) displaying title when `DAYNUM = 0` and text when `DAYNUM = 1`

### HTML Design

Use the **Report Columns-HTML Design** sub-level for individual columns:
- **Design tab**: Change font, font color, background color (directly or based on another column's value)
- **Location tab**: Divide page into cells, set row/column positions, column width %, title design, data display options, horizontal/vertical alignment
- **Picture tab**: Display pictures (static or dynamic with `D` in Picture column)

Use the **HTML Definitions** sub-level of Report Generator for the entire report:
- **Outside Border/Inside Border tabs**: Change border definitions and spacing
- **More Defs tab**: Define columns per page and whether report title is displayed

<!-- ADDED START -->
### Common Issues and Solutions

*   **Synchronization of Custom Columns**: When adding or deleting columns in a customized report, changes may not immediately reflect in the HTML design or output. 
    *   **Solution**: Always run **Form/Procedure Preparation** (Reprepare) after structural changes. If columns still do not appear in specific print formats, verify if those formats are "Private" or "Standard," as private formats may require manual adjustment in the HTML Design sub-level or the `REPPERSONALORDER` table to include the new fields.
*   **Identifying Active Body Sections**: In complex reports with multiple `BODY` sections defined in the procedure steps, it can be difficult to determine which section is active in the Report Designer.
    *   **Solution**: The SDK allows multiple visible body sections, but a print format typically utilizes one. If multiple exist, use trial and error (e.g., changing a background color) to identify the active section, and manually hide unused sections to avoid design confusion.
*   **Image Performance Degradation**: Reports containing dynamic product images (using the `D` flag in the Picture tab) may experience significant performance slowness, particularly in versions 22.1 and higher.
    *   **Solution**: This is a known performance regression in the core system's image handling. Minimize the number of images per page or ensure image file sizes are optimized while waiting for core system updates.
*   **POS Printer Integration**: Standard HTML reports may require additional configuration when targeting specialized hardware like POS (Point of Sale) printers for Over-the-Counter Invoices.
    *   **Solution**: While HTML reports are the standard tool, full integration with POS hardware often requires specific synchronization mechanisms or the Priority Retail module to handle specialized printer drivers and paper dimensions.
<!-- ADDED END -->
### Design Reports Using CSS Classes

Reports use predefined CSS classes in `system\html\style.htm`.

To customize, create a copy named **`style2.htm`** in the same directory. The system automatically includes both files in every HTML report header.

**Never modify the standard `style.htm` file.**

Apply CSS classes to:
- Entire report: Use the **Class** column in HTML Definitions
- Specific column: Use the **Class Definition Column** in Report Columns-HTML Design
- Specific font: Use the **Class** column in Font Definitions

#### Priority Cloud - Style File Upload/Download

```sql
/* Download existing style.htm */
:TMPFILE = STRCAT(SYSPATH('TMP', 1), 'style2.html');
:HTMLFILE = '../../system/html/style.htm';
:DLFILE = NEWATTACH('style2', 'htm');
EXECUTE COPYFILE :HTMLFILE, :TMPFILE;
EXECUTE COPYFILE :TMPFILE, :DLFILE;
SELECT :DLFILE FROM DUMMY FORMAT;

/* Upload edited style2.htm */
:TMPFILE = STRCAT(SYSPATH('TMP', 1), 'style2.html');
:HTMLFILE2 = '../../system/html/style2.htm';
:ULFILE = '../../system/mail/.../.../style2.htm';
/*use the file path of the uploaded file */
EXECUTE COPYFILE :ULFILE, :TMPFILE;
EXECUTE COPYFILE :TMPFILE, :HTMLFILE2;
```

---

## Calculated Report Columns

Calculated columns display data derived from other report columns. They are not stored in any database table. Reference other columns by their **column numbers**.

Example -- Days Late calculation:
```sql
0+ (SQL.DATE8 - (#5) > 0 ? (SQL.DATE8 - (#5))/24:00 : 0)
```
The `?` and `:` form an if-then-else expression.

### Create a Calculated Column

1. In Report Columns, specify the **Pos** (position)
2. Designate the **Width** (and decimal precision for REAL/shifted integers)
3. Specify the column title in the **Revised Title** column
4. Enter the **Report Column Extension** sub-level
5. Write the expression in **Expression/Condition** (SQL syntax; continue in sub-level if needed)
6. Designate the **Column Type** (CHAR, INT, REAL, etc.)

A check mark appears in the Expression/Condition column of Report Columns after exiting the extension form.

### Display Alternative Date Formats

Use the DTOA expression:
```sql
DTOA(table.column, 'pattern')
```

Example:
```sql
DTOA(ORDERS.CURDATE, 'MMM DD, YYYY')
/* Converts 07/12/06 to "Jul 12, 2006" */
/* Column Type = CHAR, Width = 12 */
```

### Add a Condition for a Calculated Column

Add a dummy column (`DUMMY.DUMMY`) and assign it the condition, preceded by `=1 AND` or `= DUMMY.DUMMY AND`:

```sql
= 1 AND (FNCITEMS.DEBIT1 <> 0.0 OR FNCITEMS.CREDIT1 <> 0.0)
```

### Add Conditions in a Group By Column (HAVING)

Filter groups (e.g., customers with more than N orders):

1. Add a dummy column (`DUMMY.DUMMY`)
2. Hide the column
3. Set Col. Func. (e.g., `S`)
4. Write the expression in Report Column Extension:

```sql
= 0 AND COUNT(*) > :MIN
```

This generates a SQL `HAVING` clause:
```sql
HAVING SUM(DUMMY.DUMMY) = 0
AND COUNT(*) > :MIN
AND (1 = 1)
```

### Use a Complex Function

For operations beyond simple sum/average/minimum/maximum:

1. Define the expression in Report Column Extension
2. Specify **Col. Func. = `F`**

Example (Avg Monthly Consumption):
```sql
(SUM(#56) / (#80))
/* #56 = Outgoing Transactions, #80 = months in period */
```

---

<!-- ADDED START -->
### Common Issues and Solutions

**Handling Special Characters (#)**
If you need to display a hash symbol (#) as text within a report column, you cannot include it directly in the expression as it triggers a form preparation error.
*   **Solution:** Initialize a procedure variable with the '#' character in the procedure logic and pass that variable to the report stage to display the symbol.

**Expression Length and Complexity Limits**
Very long or deeply nested conditional expressions (e.g., complex `CASE` or ternary logic) may exceed the system's character limit for a single report column expression.
*   **Solution:** Instead of a complex expression, move the logic into the procedure's SQL script. Use a `CURSOR` or a temporary pre-processed table to calculate the values before the report stage runs.

**Incorrect Totals for Calculated Columns**
Calculated columns (Col. Func. = `F`) often default to summing the results of the expression at the group/summary level, rather than re-evaluating the formula based on the summary totals.
*   **Solution:** To force the system to re-calculate the expression at the summary level (e.g., calculating a percentage of totals rather than a sum of percentages), ensure the **Group Function** (חישוב קבוצתי) is set correctly to re-evaluate the expression.
*   **Example (Percentage Growth):**
```sql
( #75 = 0.00 AND #70 = 0.00 ? 0.00 : (#75 = 0.00 ? (#70 < 0.00 ? -100.00 : 100.00) : ( ((#70/#75) - 1.00) * (#70 < 0 ? -100.00 : 100.00) )) )
```
<!-- ADDED END -->
## Types of Reports

### Tabular Reports

Specify `T` in the **Type** column of the Report Generator.

Assign columns in the **Graphic Display** field of Report Columns:
- `X` -- data displayed as tabular columns
- `O` -- non-displayed column used for ordering the X data
- `T` -- content displayed in the table cell

Each group appears in a separate row.

Options:
- **Vertical mode**: Specify `V` in the Table Display Mode column
- **Hide single-row group title**: Specify `h` in Table Display Mode

#### Totals in Tabular Reports

| Group Func. | Result |
|-------------|--------|
| `H` | Row totals |
| `S` | Sum totals per row and group |
| `T` | Column totals |
| `B` | Row totals, group totals, column totals, and grand total |

### Multi-Company Reports

Add these columns to display data from multiple companies:
- Displayed column: Column Name = `TITLE`, Table Name = `ENVIRONMENT`
- Hidden column: Column Name = `DNAME`, Table Name = `ENVIRONMENT`, with Expression/Condition = `= SQL.ENV`

The companies displayed are those selected by the user via **Define Multiple Companies** (File menu).

### Processed Reports

A processed report is a report whose data undergo processing prior to output. Embed a report in a procedure for complex data manipulation. Refer to the [Procedures Reference](procedures.md) for details on building processed report procedures.

---

## Run Reports

### From a Program

Use the **Run Report** program (Reports menu) or the **Run Report/Procedure** program (Action from Report Generator). This is useful during development.

### From a Menu

1. Enter the **Menu/Form Link** form (sub-level of Report Generator)
2. Specify the menu name and type `M`
3. Specify an integer for ordering within the menu

### As a Form Action

1. Enter the **Menu/Form Link** form (sub-level of Report Generator)
2. Specify the form name and type `F`
3. Specify an integer for ordering in the Actions list
4. Flag **Background Execution** if the report should run in the background

When activated from a form, input is restricted to the form record on which the cursor rests. Only columns from the form's base table serve as input.
