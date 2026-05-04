# Interfaces & Loading Reference

## Table of Contents

- [Form Interfaces Overview](#form-interfaces-overview)
  - [Advantages of Form Interfaces](#advantages-of-form-interfaces)
  - [Sources and Targets](#sources-and-targets)
  - [Important Notes](#important-notes)
- [General Definitions](#general-definitions)
  - [Interface Name](#interface-name)
  - [Module](#module)
  - [Load Parameters](#load-parameters)
- [Load Table Pattern (GENERALLOAD)](#load-table-pattern-generalload)
  - [Mapping the Interface](#mapping-the-interface)
  - [Linking Form Columns to Table Columns](#linking-form-columns-to-table-columns)
  - [Default Values](#default-values)
  - [Code Implementation](#code-implementation)
  - [Adding Line Items to Existing Documents](#adding-line-items-to-existing-documents)
  - [Creating a Custom Load Table](#creating-a-custom-load-table)
- [File Import/Export](#file-importexport)
  - [Plain Text Files (Fixed Position and TSV)](#plain-text-files-fixed-position-and-tsv)
  - [Outgoing Interface Definitions (Export)](#outgoing-interface-definitions-export)
- [XML Import/Export](#xml-importexport)
  - [Parsing XML Files](#parsing-xml-files)
  - [XML Tags Structure](#xml-tags-structure)
  - [Tag Types](#tag-types)
  - [XML Tag Example](#xml-tag-example)
  - [Repeating Tags Example](#repeating-tags-example)
  - [Mapping Form Data to XML Tags](#mapping-form-data-to-xml-tags)
- [JSON Import/Export](#json-importexport)
  - [Tags for Interface Form (v25.1+)](#tags-for-interface-form-v251)
  - [JSON Export Structure](#json-export-structure)
- [Form Load Execution](#form-load-execution)
  - [Ways to Execute](#ways-to-execute)
  - [Complete Syntax](#complete-syntax)
  - [Complete Parameter Reference](#complete-parameter-reference)
  - [Export-Only Parameters](#export-only-parameters)
- [Form Load Code Examples](#form-load-code-examples)
- [Error Handling](#error-handling)
  - [ERRMSGS Table](#errmsgs-table)
  - [Displaying Errors](#displaying-errors)
  - [Reloading Failed Records](#reloading-failed-records)
  - [The STACK_ERR Table](#the-stack_err-table)
- [Deleting Records via Interface](#deleting-records-via-interface)
- [Dynamic Interfaces](#dynamic-interfaces)
  - [Special Parameters](#special-parameters)
  - [Dynamic Export Example](#dynamic-export-example)
  - [Dynamic Import Example](#dynamic-import-example)
  - [Dynamic Delete Example](#dynamic-delete-example)
- [Table Loads (DBLOAD)](#table-loads-dbload)
  - [Defining the Load File](#defining-the-load-file)
  - [Defining the Load](#defining-the-load)
  - [Executing Table Loads](#executing-table-loads)
  - [DBLOAD Syntax and Parameters](#dbload-syntax-and-parameters)
  - [Viewing Load Messages](#viewing-load-messages)
  - [Converting Excel to Tab-Delimited File](#converting-excel-to-tab-delimited-file)
- [Combining Table Loads with Form Loads](#combining-table-loads-with-form-loads)
- [Duplicating Documents with Interface](#duplicating-documents-with-interface)
- [Finding Interfaces](#finding-interfaces)
- [Executing a Form Load from a Trigger or Step Query](#executing-a-form-load-from-a-trigger-or-step-query)

---

## Form Interfaces Overview

Priority provides two interface tools:

1. **Form Load (INTERFACE program)** -- Import data directly into a Priority form (from an external text, XML/JSON file, or an internal load table) and export form data to a file or table.
2. **Table Load (DBLOAD program)** -- Import data into an interim table from a tab-delimited text file. Record and execute SQL statements (a load query) during the load.

Use these tools together: load data into an interim table with DBLOAD, then load from that table into the target form with INTERFACE.

**Critical Rule:** Never insert records directly into Priority tables. Always use form interfaces (INTERFACE program) to ensure integrity checks and form triggers execute.

### Advantages of Form Interfaces

- **Data Integrity** -- Simulates manual data entry; subjects data to field and form triggers; fails on errors. Choose whether to fail on warnings and business rules.
- **Multiple Forms** -- Perform actions on a parent form and its subforms in one process.
- **Feedback** -- Reports which lines loaded successfully and which failed. Successful lines return the key(s) of created/updated records; errors are stored in the database automatically.

### Sources and Targets

Map a form interface between one or more forms/columns and a load table or file. Supported sources/targets:

- **Database load table** -- Standard `GENERALLOAD` table, or custom load tables
- **Files:**
  - XML
  - JSON
  - Tab-separated files (TSV)
  - Fixed-width files

### Important Notes

- Think carefully before running an interface from a form trigger. If the interface can cause that same trigger to fire again, an infinite loop may result.
- Interfaces generate an error when trying to update documents assigned to inactive users.
- Do not change an existing form load or table load, but reuse existing load tables, interim tables, and load procedures.

---

## General Definitions

Record form interfaces in the **Form Load Designer** form and its sub-levels:
`System Management > Database Interface > Form Load (EDI)`

### Interface Name

- Use only alphanumeric values and the underline sign (no spaces).
- Begin with a letter.
- Do not use reserved words.
- Prefix custom interfaces with a common four-letter prefix (e.g., `XXXX_LOADFNC`).

### Module

Assign new form interfaces the "Internal Development" module so they work regardless of which Priority modules are purchased.

### Load Parameters

Set parameters affecting the form interface (some can also be set during execution):

| Parameter | Description |
|-----------|-------------|
| **Do Not Skip Lines** | When checked, INTERFACE continues loading records of the current record type after an error. When unchecked, stops insertion of current record type on error. |
| **Ignore Warnings** | When checked, warning messages are ignored. When unchecked, warnings are treated as errors. |
| **HTML Text** | When checked, HTML text definitions (fonts, sizes, colors) transfer intact with the text. Use when exporting to an application that supports HTML tags. |

---

## Load Table Pattern (GENERALLOAD)

Use load tables when working with interfaces based on events in Priority itself (e.g., a procedure that opens a customer shipment based on a sales order). Import data into new or existing records, or export data from existing records to a load table, manipulate it, and reimport as new records (document copying pattern).

The default `GENERALLOAD` table suffices for most use cases. Create custom tables or add columns to `GENERALLOAD` when needed.

Specify the load table in the Form Load (EDI) form, in the **Load Table** column.

**Tip:** Before mapping the interface, manually perform the operations in the actual form. Note the order of field entry and mandatory fields.

### Mapping the Interface

**GENERALLOAD column naming — no "F" prefix (silent NULL failure):**
GENERALLOAD column names are `LINE`, `RECORDTYPE`, `INT1`–`INTn`, `REAL1`–`REALn`,
`DATE1`–`DATEn`, `CHAR1`–`CHAR25`, `TEXT1`–`TEXT18`, `LOADED`, `KEY1`–`KEY4`.
There is **no `F` prefix** — `FDATE1`, `FCHAR1`, `FINT1`, `FREAL1` do not exist.

Some generated specifications and documentation incorrectly use the `F`-prefix
notation (a confusion with SQLI form-column variable syntax `:$.FDATE1`).
SQLI compilation is lenient: `INSERT INTO GENERALLOAD (FDATE1) VALUES (…)` does
NOT produce a compile error — the column is silently ignored and receives NULL
at runtime, breaking the interface load with no visible error.

Verify column names with:
```sql
SELECT COLUMNNAME FROM COLUMNS
WHERE TABLENAME = 'GENERALLOAD' FORMAT;
```

*(seen in: session-2026-05-02-tgml-phase1)*

**GENERALLOAD column widths — always use TEXT* for multi-char values:**

| Column family | Width | Notes |
|---------------|-------|-------|
| `CHAR1`–`CHAR25` | **1** | Single character only — use for Y/N flags or 1-char codes |
| `TEXT1` | 56 | |
| `TEXT2`, `TEXT3` | 68 | Maximum width in the family |
| `TEXT4`, `TEXT6` | 48 | |
| `TEXT5`, `TEXT10` | 30 | |
| `TEXT7` | 100 | Longest TEXT column |
| `TEXT8`, `TEXT9` | 80 | |
| `TEXT11`–`TEXT13`, `TEXT17`, `TEXT18` | 20 | |
| `TEXT14`, `TEXT15` | 24 | |
| `INT1`–`INTn` | 8 (integer) | |
| `REAL1`–`REALn` | 8 (decimal) | |
| `DATE1`–`DATEn` | 8 (date/datetime) | |

**Rule:** use a `TEXT*` column (not `CHAR*`) whenever the source value is more
than one character. `CHAR1` mapped to a 2-char source value silently truncates
to 1 char at load time. Width mismatches between source GENERALLOAD columns and
target form columns also cause INTERCLMNS `saveRow` to hang silently — see
§INTERCLMNS saveRow width-mismatch hang in the EDI internals section below.

*(seen in: session-2026-05-02-tgml-phase1)*

In the **Forms for Import** sublevel, record:
- The form(s) with which to interface
- The **Code (Record Type)** associated with each form

Assign each level in the form tree its own unique record type.

Example:

| Form | Title | Record Type |
|------|-------|-------------|
| ORDERS | Sales Orders | 1 |
| ORDERITEMS | Order Items | 2 |

**Tip:** After recording a form, run the **List of Sub-level Forms** report (from Actions) to view all sub-levels (one level down only).

**Replace Form Data** column: Flag this to overwrite existing records in sub-levels. Leave blank to add new records to existing ones.
- Use primarily for text forms.
- Based on the assumption existing records will be deleted successfully.
- Do not use if the form has a PRE-DELETE trigger.

### Linking Form Columns to Table Columns

Use the sub-level **Link Form Cols to Intrm Tbl Cols** to indicate:
- Which form columns map to which load table columns
- The order of column insertion

Notes:
- The Choose list only includes updatable columns, but INTERFACE can also insert values into hidden columns (use with caution).
- To update existing records, map a hidden column (like `ORDI`) as the first in insertion order, but use visible columns (like `PARTNAME`) for lookups rather than hidden autounique columns (like `PART`).

**Insert Null Values** column: Flag this to have INTERFACE treat empty strings and zero values as true values.

Example: Flag this column to load `ORDERITEMS` records with a unit price of 0. Otherwise, INTERFACE ignores the 0 and inserts the default unit price via the form trigger.

### Default Values

Use the **Default Value for Column** subform to assign a default value loaded into the form column when the load table column is empty. When exporting, if the form column is empty, the default value is exported.

### Code Implementation

Create a linked, empty copy of the GENERALLOAD table:

```sql
/* Create a linked, empty copy of the GENERALLOAD table */
SELECT SQL.TMPFILE INTO :DEMO_GEN FROM DUMMY;
LINK GENERALLOAD TO :DEMO_GEN;
GENMSG 1 WHERE :RETVAL <= 0; /* Generic system error message */
```

Interface structure for this example:

| Form | Title | Record Type |
|------|-------|-------------|
| ORDERS | Sales Orders | 1 |
| ORDERITEMS | Order Items | 2 |

Insert the parent record (Sales Orders -- only customer code needed, mapped to TEXT2):

```sql
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT2)
SELECT 1, '1', CUSTOMERS.CUSTNAME
FROM CUSTOMERS
WHERE CUSTDES = 'Demo Customer';
```

Insert child records (Order Items -- 4 mandatory fields):

```sql
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT2,
INT1, REAL1, DATE1)
SELECT SQL.LINE + 1, '2', PART.PARTNAME,
INTQUANT(1.0), PART.LASTPRICE, SQL.DATE + (24:00 * 10)
FROM PART
WHERE PARTNAME LIKE 'DEMO%';
/* The TQUANT quantity field is a shifted integer, so we
use INTQUANT with a real number to convert the quantity
based on the system's decimal precision settings */
```

**Tip:** Use `SQL.LINE` to auto-increment LINE values when inserting multiple lines.

**RECORDTYPE is mandatory — omitting it causes a silent empty-row failure:**
Every `INSERT INTO GENERALLOAD` row must include a `RECORDTYPE` value matching
the `TYPE` field on the corresponding `INTERFORMS` row. Omitting `RECORDTYPE`
(or leaving it as an empty string) does NOT cause a compile error or an
`EXECUTE INTERFACE` abort. Instead:
- The row is silently inserted as `RECORDTYPE = ' '`.
- The interface executes and returns success at the SQLI level.
- ERRMSGS receives: `"Line 1 - Record type ' ' is not defined in the 'Forms for Loading' screen"`.
- All data for that row is silently discarded.

This is a silent data-loss failure. Always include `RECORDTYPE = '<type>'` in every INSERT:

```sql
-- WRONG — compiles, executes, silently discards data:
INSERT INTO GENERALLOAD(LINE, TEXT2) SELECT SQL.LINE, CUSTNAME FROM CUSTOMERS;

-- RIGHT:
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT2)
SELECT SQL.LINE, '1', CUSTNAME FROM CUSTOMERS;
```

**Diagnostic:** after `EXECUTE INTERFACE`, check ERRMSGS with:
```sql
SELECT MESSAGE FROM ERRMSGS WHERE USER = SQL.USER AND TYPE = 'i' FORMAT;
```

*(seen in: session-2026-05-02-tgml-phase1 — confirmed by eval-investigator, 2026-05-02)*

Resulting GENERALLOAD table:

| LINE | RECORDTYPE | TEXT2 | INT1 | REAL1 | DATE1 |
|------|-----------|-------|------|-------|-------|
| 1 | '1' | 'DEMOCUST' | | | |
| 2 | '2' | 'DEMO01' | 1000 | 25.00 | 03/15/23 |
| 3 | '2' | 'DEMO02' | 1000 | 35.00 | 03/15/23 |

Execute the interface:

```sql
EXECUTE INTERFACE 'DEMO_NEWORDER',
SQL.TMPFILE, '-L', :DEMO_GEN;
```

After successful execution, LOADED and KEY columns are updated:

| LINE | RECORDTYPE | LOADED | KEY1 |
|------|-----------|--------|------|
| 1 | '1' | Y | '120' |
| 2 | '2' | Y | '701' |
| 3 | '2' | Y | '702' |

- `LOADED` = `Y` for successfully loaded lines.
- `KEY1` (and `KEY2`/`KEY3` etc.) are filled with the highest priority (autounique or unique) key of the line in the base table.

Retrieve keys (keys are stored as strings):

```sql
SELECT ORDERS.ORDNAME FROM ORDERS, GENERALLOAD
WHERE ORDERS.ORD = ATOI(GENERALLOAD.KEY1)
AND GENERALLOAD.RECORDTYPE = '1'
AND GENERALLOAD.LOADED = 'Y';
```

Clean up:

```sql
UNLINK GENERALLOAD;
```

### Adding Line Items to Existing Documents

When an interface adds line items to a document, new items are inserted first by default (receive smaller line numbers than existing records).

To change the position of new records (e.g., add after the first existing line):

1. Define the interface so that existing lines are retrieved (e.g., link `INT1` column in the load table to the `KLINE` or `ORDI` column).
2. Add a column to the load table to hold the internal ID of the first line (`KLINE` or `ORDI`).
3. In the load table, insert the record of the new line after the record that retrieves the first line.

### Creating a Custom Load Table

Include these required columns in a custom load table:

| Column Name | Type | Width | Title |
|-------------|------|-------|-------|
| LINE | INT | 8 | Ln |
| RECORDTYPE | CHAR | 3 | Record Type |
| LOADED | CHAR | 1 | Loaded? |
| KEY1 | CHAR | 20 | Key 1 |
| KEY2 | CHAR | 20 | Key 2 |
| KEY3 | CHAR | 20 | Key 3 |

- Make the `LINE` column the unique key of the table.
- See predefined `GENERALLOAD_T` for an example with an extra `TITLE` column for storing messages added to error messages.
- The Form Load Designer warns if there are not enough key columns; add more as needed.

---

## File Import/Export

Map form interfaces to 4 file types:
- **Fixed-width files** -- Mapping based on character position
- **Tab-separated values (TSV)** -- Mapping based on column position
- **XML files** -- Mapping based on tags
- **JSON files** -- Mapping based on fields/properties

Priority imports from ASCII or Unicode (UTF-16) files and automatically recognizes the format. Exported data is saved in Unicode (UTF-16) unless otherwise specified.

### Plain Text Files (Fixed Position and TSV)

#### Defining the File

In the Form Load Designer form, specify:
- **File name** -- If stored in `system/load`, provide just the filename; otherwise provide a relative or full path.
- **Record size**
- **File type**

**Sub-directory?** column: Flag to search in the sub-folder of the current company within `system/load`. Only relevant when the File Name field does not contain `/` or `\`.

#### Forms in the Load

Use **Forms to be Loaded** sub-level to specify participating forms (root form and sub-levels). Assign each a unique record type matching the record type in the file.

#### Link Form Columns to Fields in File

Use **Position of Form Columns in File** sub-level:
- For TSV: identify data by column number.
- For fixed-width: indicate first and last character positions.
- Specify order of insertion.

**Insert Null Values**: Flag to treat empty strings and zero values as true values.

**Digits After Decimal**: For REAL values (or shifted integers) without a decimal point, indicate the number of digits after decimal.

#### Position of Record Type in File

Use **Position of Record Type in File** form to indicate where the record type is located:
- TSV: column number
- Fixed-width: first and last character positions

#### Default Values

Use **Default Value for Column** sub-level for default values when file position is empty.

### Outgoing Interface Definitions (Export)

Use **Outgoing Interface Definitions** form (sub-level of Position of Form Columns in File):

| Setting | Description |
|---------|-------------|
| **Align** | Left or right alignment for columns in file; useful for numbers |
| **Date Format** | SQL date formats such as `MMDDYY` or `MM/DD/YY` |
| **Padding w/Zeroes** | Pad number columns with zeroes |

**Tip:** To convert CSV to TSV, use a filter to convert commas to tabs (only works if the file contains no regular tabs).

**Tip:** To create a new form load based on an existing one, run the **File Definitions for Form Load** report by Action from the Form Load Designer form.

---

## XML Import/Export

### Parsing XML Files

Accepted encodings: UTF-8, Unicode, UTF-16.

#### Web Interface Steps

1. In Form Load Designer, record a default **File Name** (e.g., `example.xml`).
2. Run **Import XML/JSON Interfc Template** Action and upload the template file.
3. Run **Prepare Tags by File Defs** Action -- the structure is analyzed and transferred to the **Tags for Interface** sub-level form.

#### Windows Interface Steps

1. Save the file in the `system\load\company` directory (where company = `SQL.ENV`).
2. In Form Load Designer, record the file location in **File Name**.
3. Run **Prepare Tags by File Defs** Action.

### XML Tags Structure

> **Version note (23.0+):** The path-based XML tag syntax described below (`/root/element` and `/root/element>attribute`) was introduced in **Priority version 23.0**. Earlier versions used a different tag-mapping mechanism.

XML tag definitions use a path-like syntax to specify node locations:

```
/root/element
```

Maps to:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element></element>
</root>
```

For attributes:
```
/root/element>attribute
```

Maps to:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element attribute="[data goes here]"></element>
</root>
```

### Tag Types

| Type | Description |
|------|-------------|
| (blank) | Normal tag |
| `C` | Constant value -- always taken from Tags for Interface form, not from the database table |
| `E` | Structural tag -- marks the end of a tag group |
| `R` | Structural tag -- marks the end of a repeating tag group |

### XML Tag Example

Tags definition:
```
mainTag/valueTag
mainTag/groupL1/groupL2f/data1
mainTag/groupL1/groupL2f/data2
mainTag/groupL1/groupL2f          - type E
mainTag/groupL1/groupL2s/data1
mainTag/groupL1/groupL2s/data2
mainTag/groupL1/groupL2s          - type E
mainTag/groupL1                   - type R
```

Output (from Sales Orders form):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<mainTag>
    <valueTag>SO24000726</valueTag>
    <groupL1>
        <groupL2f>
            <data1>000</data1>
            <data2>2000.00</data2>
        </groupL2f>
        <groupL2s>
            <data1>000</data1>
            <data2>2000.00</data2>
        </groupL2s>
    </groupL1>
    <groupL1>
        <groupL2f>
            <data1>000-12</data1>
            <data2>1000.00</data2>
        </groupL2f>
        <groupL2s>
            <data1>000-12</data1>
            <data2>1000.00</data2>
        </groupL2s>
    </groupL1>
</mainTag>
```

### Repeating Tags Example

Tag definition:
```
/Order/OrderItems/OrderItem   type R
```

Result:
```xml
<Order>
    <OrderItems>
        <OrderItem>
            <part>001</part>
        </OrderItem>
        <OrderItem>
            <part>002</part>
        </OrderItem>
    </OrderItems>
</Order>
```

### Mapping Form Data to XML Tags

Navigate to **Forms to be Loaded** > **Position of Column in File** > **Tag Definitions** sub-level:
- Link each form column to the appropriate tag.
- For date tags, define the **Date Format** (e.g., `MMDDYY`, `MM/DD/YY`).
- Select **Without Empty Tags** to skip tags when there is no data.
- To have an always-empty tag, map it to a column and set as constant (`C`) with empty value.
- When using data from multiple forms in one tag group, maintain export order (first table data first, then second, etc.).

---

## JSON Import/Export

### Encoding

Incoming JSON files must use **UTF-16** encoding.

### Tags for Interface Form (v25.1+)

Starting with version 25.1, JSON exports follow the structure of the parsed file (same as XML exports).

The **Tags for Interface** form shows all properties from the parsed file. Delete, add, or revise properties as needed.

Key points:
1. For parsed properties, data from the first record appears in the **Value** column. Set type `C` to use a constant value for all records.
2. A repeating property (type `R`) outputs as a JSON array `[]`. If the parsed file only contains one instance, record the `R` type manually.
3. Use the **Attribute** column to override the output property name (e.g., rename `currency` to `currencyCode`).
4. Map JSON properties to forms via **Forms to be Loaded** > **Position of Column in File** > **Tag Definitions**.

**Note:** Decimal data in JSON files must always use a decimal point as the separator, regardless of the system locale setting.

### JSON Export Structure

#### v25.1 and Later

Follows the parsed file structure with support for renaming and nesting.

#### Prior to v25.1

No renaming or nesting; follows form structure:

```json
{
    "ORDERS": [
        { "ORDNAME": "SO2400021", "CUSTNAME": "John Doe" },
        { "ORDNAME": "SO2400022", "CUSTNAME": "Jane Doe" }
    ]
}
```

---

## Form Load Execution

### Ways to Execute

1. **From menu**: Run **Load Data** program from the Form Load (EDI) menu. Choose: Load, Reload, or Upload (export).
2. **From SQLI step or form trigger**: Use `EXECUTE INTERFACE` syntax.
3. **As interface step (type I)** in a procedure: Set parameters in the Procedure Parameters form.
4. **As INTERFACE program step** in a procedure: First parameter = form load name.
5. **Windows only**: Export from within a form via **XML File** command in Mail menu.

### Complete Syntax

```sql
EXECUTE INTERFACE 'interface_name', ['msgfile'], ['-L', 'link_file'],
['-i', 'Data_File'], ['-stackerr', 'stackerr_file'],
['-w'], ['-ns'], ['-nl'], ['-nv'],
['-noskip'],['-enforcebpm'], ['-t'], ['-W'], ['-m'],
['-o' | '-ou' | '-ou8' [, '-f', 'output_file']], ['-debug', 'debug_file'],
['-repeat'],['-l', 'table_name1', 'link_file1'], '-v';
```

**Missing comma between interface name and message-file path is a compile-time parse error:**
`EXECUTE INTERFACE 'NAME' SQL.TMPFILE` (no comma after the name) fails at compile time:
```
parse error at or near symbol SQL.TMPFILE
```
The comma is mandatory. Generated specs and AI-produced code frequently omit it.
Correct forms:
```sql
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE;                        -- minimal
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE, '-L', :DEMO_GEN;       -- with link file
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE, '-L', :TMP, '-nl';     -- with flags
```
When a compile error points to the EXECUTE INTERFACE line, check for the missing
comma first — it is the single most common source of INTERFACE parse errors in
generated code.

*(seen in: session-2026-05-02-tgml-phase1 — confirmed by eval-investigator, 2026-05-02)*

### Complete Parameter Reference

#### General Parameters

| Parameter | Description |
|-----------|-------------|
| `'interface_name'` | The Load Name used to identify the form load in the Form Load Designer |
| `'msgfile'` | File where error messages are recorded. Display results to the user (e.g., "5 out of 6 records were loaded.") |
| `'-L', 'link_file'` | Use a linked file of the load table. `-L` tells the program to use a linked file; `link_file` is the file used to link the load table |
| `'-i', 'data_file'` | Load data from a specified source file (plain text, XML, or JSON). If omitted, the program looks in `SYSTEM/LOAD` folder |
| `'-stackerr', 'stackerr_file'` | Send error messages to a linked file of `STACK_ERR` table instead of `ERRMSGS` table. The INTERFACEERR report will not retrieve values when using this option |
| `'-w'` | Ignore warning messages (equivalent to Ignore Warnings column in Form Load Designer) |
| `'-ns'` | Disable the progress bar displayed during load execution |
| `'-nl'` | Do not display line number in error report messages |
| `'-nv'` | Hide column name and value in error messages from CHECK-FIELD trigger errors |
| `'-noskip'` | Continue loading records of current record type after error (equivalent to Do Not Skip Lines column) |
| `'-enforcebpm'` | Apply Business Rules Generator rules and run BPM mechanism during load. Without this flag: mail is sent, but all business rules/BPM rules are bypassed and defined paths are ignored. **Note:** Data Generator rules are NOT affected by this flag — they are activated elsewhere in the code (after POST-FIELD) regardless of whether `-enforcebpm` is specified. *(handbook §Interfaces p210)* |
| `'-t'` | Indicate file has tab separators (when no file type defined in Form Load Designer). Use when file type is unknown in advance |
| `'-W'` | Display warning messages in Load Errors report even if form load is defined to ignore warnings |
| `'-m'` | Break up error messages into several lines |
| `'-debug', 'debug_file'` | Debug mode -- write all operations executed by the form load into the specified file |
| `'-repeat'` | Reload option -- reload lines not successfully loaded in a previous run (LOADED column != 'Y') |
| `'-v'` | Check structure of input file. Generate error if value type is incompatible with expected type for that position |

### Export-Only Parameters

| Parameter | Description |
|-----------|-------------|
| `'-o'` | Export to file using **ASCII** encoding. When loading to table, insert records in defined load table. Often used with `-f` |
| `'-ou'` | Export to file using **Unicode (UTF-16)** encoding. Often used with `-f` |
| `'-ou8'` | Export to file using **Unicode (UTF-8)** encoding. Often used with `-f` |
| `'-f', 'output_file'` | Write output to a different file than recorded in Form Load Designer. Necessary when a sample file (for XML tags) is recorded in the designer |
| `'-l', 'table_name', 'link_file'` | Export data to a linked copy of the load table. `-L` must also be provided with a linked table containing records from the base table of the first form in the load |

#### `-nv` Example

Without `-nv`: `"Line X - Customer Number C000981: Specified item not in database."`
With `-nv`: `"Line X - Specified item not in database."`

---

## Form Load Code Examples

### Execute Interface from File Specified in Form Load Designer

```sql
EXECUTE INTERFACE 'interface', '';
```

### Execute Interface from File Specified in Code

```sql
/* Run the interface on a file imported in a procedure step to parameter FIL */
EXECUTE INTERFACE 'interface', '-i', :$.FIL, '';
```

### Run Interface Based on Load Table

```sql
SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
LINK GENERALLOAD ORD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO GENERALLOAD ORD(LINE,RECORDTYPE,TEXT2)
SELECT SQL.LINE, '1', CPROFNUM
FROM CPROF
WHERE PDATE = SQL.DATE8;

EXECUTE INTERFACE 'OPENORDBYCPROF', '' , '-L', :G1;

LABEL 99;
UNLINK GENERALLOAD ORD;
```

### Export Data to a Load Table

```sql
SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :O1 FROM DUMMY;

LINK ORDERS TO :O1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG
WHERE CURDATE = '03/22/23';

EXECUTE INTERFACE 'DUMPORD', '', '-o', '-L', :O1,
'-l', 'GENERALLOAD', :G1;

LINK GENERALLOAD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;

LABEL 99;
UNLINK ORDERS;
UNLINK GENERALLOAD;
```

### Export Data to an XML File in UTF-8 Encoding

```sql
SELECT SQL.TMPFILE INTO :O1 FROM DUMMY;
:OUTFILE = STRCAT(SYSPATH('TMP', 0), 'Orders.xml');

LINK ORDERS TO :O1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG
WHERE CURDATE = '03/22/23';

/* the interface is defined as using XML files */
EXECUTE INTERFACE 'DUMPORDXML', '', '-ou8'
'-L', :O1, '-f', :OUTFILE;

LABEL 99;
UNLINK ORDERS;
```

---

## Error Handling

### ERRMSGS Table

When the INTERFACE program encounters errors, they are stored in the `ERRMSGS` table:

| Column | Description |
|--------|-------------|
| LINE | Line number |
| TYPE | Error type (`i` for INTERFACE errors) |
| MESSAGE | Error message text |
| USER | User who ran the interface |

Unique key: `USER, TYPE, LINE` -- each user sees only their own messages.

### Displaying Errors

Use any of the following methods:

1. **Reference the errors report** -- Use `{INTERFACEERR.R}` in an error message. The entity title appears with a clickable link to the report.

2. **Include INTERFACEERR report as a procedure step** -- Use GOTO to skip if no errors.

3. **Link errors report to the same menu** as the procedure running the load.

4. **Use ASCII parameter in procedure**:
```sql
SELECT MESSAGE FROM ERRMSGS
WHERE TYPE = 'i' AND USER = SQL.USER
ASCII :$.MSG;
```
Then pass MSG to a PRINT procedure step.

5. **Single error message**:
```sql
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE TYPE = 'i' AND USER = SQL.USER AND LINE = 1;
```
Then use ERRMSG to display the message.

### Reloading Failed Records

Use the **Reload** option or `-repeat` parameter. The INTERFACE program runs only on records where `LOADED` column is not `Y`.

Example: If loading an order with items and one item fails (e.g., Part Number not found), fix the load table (define the part or fix the number) and re-execute with `-repeat`. The item is inserted into the already-opened order.

### The STACK_ERR Table

For complex scenarios, the standard `ERRMSGS` table has limitations:
- Multiple interfaces overwrite earlier errors.
- Error messages lack context (e.g., which order had the issue).
- Duplicate errors may fail to store (unique key constraint: `USER, TYPE, MESSAGE`).

The `-stackerr` option resolves these issues by inserting errors into the `STACK_ERR` table:
- Original `LINE` value from the load table is stored in `INTDATA1` column.
- Error message is stored in `MESSAGE` column.
- Each interface can use a different linked file, preserving all messages.

#### STACK_ERR Example -- Multiple Interfaces

```sql
SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :G2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :S1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :S2 FROM DUMMY;

LINK GENERALLOAD ORD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;
LINK GENERALLOAD DOC TO :G2;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO GENERALLOAD ORD(LINE,RECORDTYPE,TEXT2)
SELECT SQL.LINE, '1', CPROFNUM
FROM CPROF
WHERE PDATE = SQL.DATE8;

EXECUTE INTERFACE 'OPENORDBYCPROF', SQL.TMPFILE,
'-L', :G1, '-stackerr', :S1;

INSERT INTO GENERALLOAD DOC(LINE,RECORDTYPE,TEXT1)
SELECT SQL.LINE, '1', ORDNAME
FROM ORDERS, GENERALLOAD ORD
WHERE ORD.LOADED = 'Y'
AND ORDERS.ORD = ATOI(ORD.KEY1);

UNLINK GENERALLOAD ORD;

EXECUTE INTERFACE 'OPENDOC', SQL.TMPFILE,
'-L', :G2, '-stackerr', :S2;

UNLINK GENERALLOAD DOC;

LINK STACK_ERR S1 TO :S1;
GOTO 99 WHERE :RETVAL <= 0;
SELECT * FROM STACK_ERR S1 FORMAT;
UNLINK STACK_ERR S1;

LINK STACK_ERR S2 TO :S2;
GOTO 99 WHERE :RETVAL <= 0;
SELECT * FROM STACK_ERR S2 FORMAT;
UNLINK STACK_ERR S2;

LABEL 99;
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **System Crash on Empty Load Tables:**
    Executing an interface when the loading table (e.g., `GENERALLOAD`) is empty can cause the procedure to crash or generate a system DUMP file. Always verify that records exist before calling `EXECUTE INTERFACE`.
    ```sql
    /* Recommended check before execution */
    SELECT COUNT(*) INTO :COUNT FROM GENERALLOAD ORD;
    GOTO 99 WHERE :COUNT = 0;
    EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE, '-L', :G1;
    ```

*   **Inactive User Blocks:**
    Interfaces updating existing documents (e.g., Purchase Requisitions) may fail if the document is currently assigned to an inactive user. To resolve this, either reactivate the user or reassign the document to an active user before running the interface.

*   **Custom Error Messages:**
    If you encounter the error "ישנם שגיאות במסכי הטעינה" (There are errors in the loading forms) and it does not appear in the standard `ERRMSGS` report, this typically indicates a failure in private customizations or that the target forms have not been properly prepared/compiled in the current environment. Ensure all related forms are prepared via the **Prepare Forms** utility.
<!-- ADDED END -->
## Deleting Records via Interface

Use the same interface definition for both inserting/updating records and deleting them. The only difference is the record type definition.

**To delete records:** Record `@` before the number value assigned to the record type.

Example: Record type `@2` deletes records of type `2`.

**Important:** Do not flag the **Replace Form Data** column in Forms to be Loaded when using delete -- this causes the form load to fail.

Example: See the `POST-FORM2` trigger in the `ORDERITEMS` form which deletes irrelevant lines.

---

## Dynamic Interfaces

Starting with version 21.0, create dynamic interfaces from within the code itself without predefining them in the interface generator. These use the file structure in XML or JSON to determine load order. Export data to these formats with export fields specified in code.

### Special Parameters

```sql
EXECUTE INTERFACE 'FORMNAME', 'msgfile', '-form',
['-L', 'link_file'], ['-stackerr', 'stackerr_file'],
['-w'], ['-ns'], ['-nl'], ['-nv'], ['-noskip'], ['-ignorewrn'],
['-enforcebpm'], ['-t'], ['-J'], ['-W'], ['-m'],
['-o' | '-ou'], ['-f', 'output_file'], ['-debug', 'debug_file'],
['-repeat'],
['-l', 'table_name1', 'link_file1' [, ...'-l', 'table_name10', 'link_file10']],
['-select', 'FIELDNAME'],
['-expand', 'SUBLEVELFORM'],
['-delete'], '-v';
```

| Parameter | Description |
|-----------|-------------|
| `'FORMNAME'` | Name of the form for which to run the interface |
| `'-form'` | Indicate this is a dynamic interface |
| `'-ignorewrn'` | Ignore warnings in a dynamic interface (similar to `-w`) |
| `'-J'` | Export/import using JSON file. When omitted, use XML |
| `'-select', 'FIELDNAME'` | Specify which fields to export. Separate multiple fields with commas: `'-select', 'CUSTNAME', 'CUSTDES'` |
| `'-expand', 'SUBLEVELFORM'` | Select sub-level forms to export data from. After expand, use `-select` for sub-level fields. Use separate `-expand` for each sub-level |
| `'-delete'` | Indicate this dynamic interface can delete records |

**Note:** `EXECUTE` is limited to a maximum of 100 arguments.

### Dynamic Export Example

```sql
SELECT SQL.TMPFILE INTO :TMPFILE FROM DUMMY;
LINK ORDERS TO :TMPFILE;
GOTO 1 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG WHERE ORDNAME IN ('SO2000001364','SO2000001365');

EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-select', 'ORDNAME', 'CUSTNAME',
'-ou', '-L', :TMPFILE, '-f', STRCAT(SYSPATH('TMP', 1), 'O2.txt'), '-J',
'-expand', 'ORDERITEMS', '-select', 'PRICE', 'PARTNAME',
'-expand', 'ORDERITEMSTEXT';

UNLINK ORDERS;
LABEL 1;
```

This exports two specific orders to a JSON file (`-J`) with only selected fields (`-select`), including data from ORDERITEMS and ORDERITEMSTEXT sub-levels (`-expand`).

### Export All Fields (XML)

If `-select` is omitted, all form fields are exported. Only fields with values are exported:

```sql
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-ou', '-L', :TMPFILE, '-f', STRCAT(SYSPATH('TMP', 1), 'testxml.xml'),
'-expand', 'ORDERITEMS';
```

### Dynamic Import Example

The import file must follow the Priority hierarchy (form > sub-level > sub-sub-level).

Example XML file (`in1.txt`):
```xml
<?xml version="1.0" encoding="utf-8"?>
<FORM>
    <ORDERS>
        <CUSTNAME>84841</CUSTNAME>
        <ORDERITEMS>
            <PARTNAME>000</PARTNAME>
            <DUEDATE>07/11/20</DUEDATE>
        </ORDERITEMS>
        <ORDERITEMS>
            <PARTNAME>002</PARTNAME>
            <DUEDATE>07/11/20</DUEDATE>
        </ORDERITEMS>
    </ORDERS>
    <ORDERS>
        <CUSTNAME>84841</CUSTNAME>
        <ORDERITEMS>
            <PARTNAME>000</PARTNAME>
            <DUEDATE>08/11/20</DUEDATE>
        </ORDERITEMS>
        <ORDERITEMS>
            <PARTNAME>002</PARTNAME>
            <DUEDATE>08/11/20</DUEDATE>
        </ORDERITEMS>
    </ORDERS>
</FORM>
```

Load command:

```sql
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-i', '-f', STRCAT(SYSPATH('TMP', 1), 'in1.txt'),
'-ignorewrn', '-noskip';
```

**Tip:** Use `-ignorewrn` and `-noskip` if data is not loading as expected. While developing in WINDBI, retrieve errors with:

```sql
SELECT * FROM ERRMSGS WHERE USER = SQL.USER AND TYPE = 'i' FORMAT;
```

### Dynamic Delete Example

Use the `-delete` option. The file must specify keys of records to delete.

JSON example:
```json
{
    "ORDERS": [
        {
            "ORDNAME": "SO0000001",
            "ORDERITEMS": [
                { "KLINE": 1 },
                { "KLINE": 3 }
            ]
        },
        {
            "ORDNAME": "SO0000002",
            "ORDERITEMS": [
                { "KLINE": 1 },
                { "KLINE": 2 }
            ]
        }
    ]
}
```

---

## Table Loads (DBLOAD)

Table loads import data from tab-delimited text files into an interim table. Execute additional processing via SQL statements (a load query) during execution. View and revise results in a form, then transfer to a Priority form using INTERFACE.

A table load is characterized by:
- A unique load file name
- A specified table or load query
- Input fields defined as variables
- Parameters affecting the load

Record definitions in: **Characteristics for Download** form and sub-levels
(`System Management > Database Interface > Table Load (Interfaces)`)

### Load Table Architecture and RECORDTYPE Convention

Custom load tables use a `RECORDTYPE CHAR(3)` column to tag each flat-file row with its semantic type. Standard column set:

| Column | Type | Purpose |
|--------|------|---------|
| `LINE` | INT | File line number (auto-assigned by load) |
| `RECORDTYPE` | CHAR 3 | Record type tag — drives post-load dispatch |
| `LOADED` | CHAR 1 | Boolean processed flag (`'Y'` when successfully transferred) |
| `KLINE` | INT | Key used when linking text rows to parent records |

Typical RECORDTYPE values (example from LOADORDERS):

| Value | Meaning |
|-------|---------|
| `'1'` | Header record (one per document) |
| `'2'` | Line item (multiple per header) |
| `'3'` | Text / remark attached to a line item |
| `'4'` | Text / remark attached to the header |

Post-load SQLI steps iterate over the staging table and use RECORDTYPE to dispatch different processing logic per record type. Ternary dispatch example:

```sql
/* header='1' -> text type '4', line item='2' -> type '3' */
SELECT (:REC = '1' ? '4' : '3') INTO :RECTEXT FROM DUMMY;
INSERT INTO PROCTABLETEXT (KLINE, TEXT)
  SELECT SQL.LINE, TEXT FROM LOADORDERS
  WHERE RECORDTYPE = :RECTEXT AND LINE > :LINE
  AND LINE < :NEXTLINE AND TEXT <> '';
```

RECORDTYPE dispatch is the architectural core of flat-file imports. The `LINE`/`RECORDTYPE`/`LOADED`/`KLINE` column set appears consistently in all custom load table definitions.

*(seen in: LOADORDERS)*

### Defining the Load File

Use ASCII or Unicode encoding for load files. Store them in `system\load` directory or sub-directories. Match the file name to the name defined in the Characteristics for Download form.

> **Encoding note:** DBLOAD can **import** from ASCII or Unicode (UTF-16) files and auto-detects the format. However, data **exported** by DBLOAD is saved in **ASCII** format by default — unlike the INTERFACE program, which exports in Unicode (UTF-16) by default. Specify otherwise explicitly if Unicode output is required for downstream consumers.

*(seen in: handbook:Interfaces@page-219)*

Naming restrictions:
- Up to 20 characters
- Alphanumeric and underline only (no spaces)
- Must begin with a letter
- No reserved words
- Prefix custom loads with a four-letter prefix (e.g., `XXXX_LOADFNC2`)

Columns:
- **Sub-directory**: Flag if file is in company sub-directory.
- **Tab Separator**: Flag if data is tab-separated.
- **Description of Data**: Brief description.

### Defining the Load

#### Automatic Load Query

1. Designate the table name in the **Table for Auto Load** column.
2. Define the input file in the **Input Record Fields** sub-level.
3. Record each table column name in the **Variable** column with type and position.

The automatic query inserts all data from the input file into table columns. The input file must contain all unique key columns (autounique key is auto-assigned if no value is provided).

#### Manual Load Query

1. Define input file variables in the **Input Record Fields** sub-level (variable name, type, position).
2. Record SQL statements in the **Load Query** sub-level.

The load query executes for each line of the input file. Include:
- `ERRMSG` commands -- causes input line load to fail; written to ERRMSGS table
- `WRNMSG` commands -- written to ERRMSGS table but does not fail the line
- Message parameters `:PAR1`, `:PAR2`, `:PAR3`

Record messages in the **Error & Warning Messages** form. SQL statements are stored in `LOADTEXT` table; messages in `LOADMSG` table.

**Tips:**
- Run **Check Syntax** program (Action from Characteristics for Download) to check SQL before activation.
- Track changes to load queries via prepared version revisions.

### Executing Table Loads

Execute table loads using any of these methods:

1. **From menu**: Run **Download a File** program from the Table Load (Interfaces) menu.
2. **From SQLI step**: Use `EXECUTE DBLOAD` syntax.
3. **As load step (type L)** in a procedure: First parameter = file name.

### DBLOAD Syntax and Parameters

```sql
EXECUTE DBLOAD '-L', 'loadname', ['-i', 'input_file'], ['-I'],
['-T', 'table', 'linkfile'], ['-g', 'debug_file'], ['-ns'],
['-N'], ['-E', 'unloaded_file'], ['-M'], ['-C'], ['-B'],
['-U'], ['-u'], ['-v'], ['msgfile'];
```

| Parameter | Description |
|-----------|-------------|
| `'loadname'` | The File Name used to identify the table load in Characteristics for Download (also the load file name) |
| `'-I'` (uppercase i) | Input data from the `file.in` file in `system\load` directory |
| `'-i', 'input_file'` | Specify a different input file |
| `'-T', 'table', 'linkfile'` | Load data to a linked copy of the designated table |
| `'-g', 'debug_file'` | Create debug file showing each query and its execution |
| `'-ns'` | Disable progress bar |
| `'-N'` | Do not clear ERRMSGS table; append new messages instead |
| `'-E', 'unloaded_file'` | Create file of all lines that failed to load. Store in `system\load` unless path specified. Can serve as input for re-execution |
| `'-M'` | Rename input file to `file.bak` |
| `'-C'` | Remove commas from numbers that appear in strings |
| `'-B'` | Remove text enclosed in square brackets |
| `'-U'` | Ignore data in USERS column (inserts with USER = 0) |
| `'-u'` | Specify current user when inserting messages into ERRMSGS (otherwise USER = 0) |
| `'-v'` | Check input file structure; error if value type is incompatible with expected type |
| `'msgfile'` | File for messages. Store in activation directory unless path specified. Contains: count of loaded lines, or fatal error explanation |

### Viewing Load Messages

Messages from DBLOAD appear in the **Download Messages** report (DBLOADERRS). Stored in ERRMSGS table with:
- `TYPE` = `L`
- `USER` = `0` (or `SQL.USER` if `-u` option used)

Previous execution messages are deleted unless the `-N` option is used.

### Converting Excel to Tab-Delimited File

Use the `EXL2TXT` command:

```sql
EXECUTE WINAPP 'p:\bin.95', '-w', 'EXL2TXT.exe', :F, :T;
/* where p: represents the full path to bin.95 */
```

- Output file uses UTF-16 encoding.
- Only the first sheet in an Excel file is converted.

---

<!-- ADDED START -->
### Common Issues and Solutions

**Empty or Corrupted Output Files**
If the conversion results in an empty or corrupted text file (especially after a version upgrade), ensure you are using the correct executable name `EXL2TXT.exe`. Additionally, verify that your `bin.95` folder is updated to the latest minor version, as fixes for file encoding and conversion logic are frequently released in system updates.

**Conversion of CSV Files**
The `EXL2TXT` utility is specifically designed for Excel (.xls/.xlsx) files. There is no direct `CSV2TXT` equivalent for converting CSV files to tab-delimited text via `WINAPP`. For CSV data, it is recommended to handle the file directly by defining the appropriate load format in the `DBLOAD` utility or by using the `FILTER` program.

**Syntax Example**
When calling the utility without a hardcoded path (assuming the environment path is set), use the following syntax:
```sql
EXECUTE WINAPP '', '-w', 'EXL2TXT', :FROMFILE, :TOFILE;
```
<!-- ADDED END -->
## Combining Table Loads with Form Loads

Follow this common pattern:

1. Create a **DBLOAD** that loads data into an interim table.
2. Display data via a **form** based on the interim table -- users check and fix records.
3. Optionally create a **procedure** to manipulate data (run by Action from the form).
4. Run a **procedure** that executes the INTERFACE program to load into the target form.
5. Flag successfully loaded records; fix and reload failed records with `-repeat`.

Example: The `LOADDOCUMENTS_C` procedure (Load Counts into Interim Table) loads a file into the `LOADDOCUMENTS_C` form (Interim Table - Inventory Counts). Then, the `LOADDOCUMENTS_C2` procedure (Load Counts from Interim Table) opens an Inventory Count document in the `DOCUMENTS_C` form using the INTERFACE program.

---

## Duplicating Documents with Interface

### Example: Copying a Sales Order for Another Customer

Copy order items, unit price, discount, ordered quantity, order item remarks, and order remarks to a new sales order for a different customer.

#### Interface Definition (Form Load Designer)

| Form Name | Title | Code (Record Type) |
|-----------|-------|--------------------|
| ORDERS | Sales Orders | 1 |
| ORDERSTEXT | Sales Orders - Remarks | 2 |
| ORDERITEMS | Order Items | 3 |
| ORDERITEMSTEXT | Order Items - Remarks | 4 |

**ORDERS form mapping:**

| Load Table Column | Form Column Name | Order |
|-------------------|-----------------|-------|
| TEXT1 | CUSTNAME | 1 |
| TEXT2 | DETAILS | 2 |

**ORDERSTEXT form mapping:**

| Load Table Column | Form Column Name | Order |
|-------------------|-----------------|-------|
| TEXT | TEXT | 1 |

**ORDERITEMS form mapping:**

| Load Table Column | Form Column Name | Order |
|-------------------|-----------------|-------|
| TEXT1 | PARTNAME | 1 |
| REAL1 | PRICE | 2 |
| REAL2 | PERCENT | 3 |
| INT1 | TQUANT | 4 |

**ORDERITEMSTEXT form mapping:**

| Load Table Column | Form Column Name | Order |
|-------------------|-----------------|-------|
| TEXT | TEXT | 1 |

#### Procedure Definition

Create a procedure with 2 input parameters:
- First: customer for the new order
- Second: order to copy

**INPUT step parameters:**

| Parameter Name | Pos | Width | Input | Type | Column Name | Table Name |
|---------------|-----|-------|-------|------|-------------|------------|
| CST | 0 | 0 | I | LINE | CUSTNAME | CUSTOMERS |
| ORD | 5 | 0 | I | LINE | ORDNAME | ORDERS |

**SQLI step** (parameter: GEN, FILE type):

```sql
LINK CUSTOMERS TO :$.CST;
ERRMSG 1 WHERE :RETVAL <= 0;

:CUSTNAME = '';
SELECT CUSTNAME INTO :CUSTNAME
FROM CUSTOMERS
WHERE CUST <> 0;

UNLINK CUSTOMERS;
ERRMSG 2 WHERE :CUSTNAME = '';

/* Export the source order to GENERALLOAD linked table */
EXECUTE INTERFACE 'TEST_OPENSALESORD', SQL.TMPFILE,
'-o', '-L', :$.ORD, '-l', 'GENERALLOAD', :$.GEN;

LINK GENERALLOAD TO :$.GEN;
ERRMSG 1 WHERE :RETVAL <= 0;

/* Replace customer with the new customer */
UPDATE GENERALLOAD
SET TEXT1 = :CUSTNAME
WHERE LINE = 1;

UNLINK GENERALLOAD;

/* Import the modified data as a new order */
EXECUTE INTERFACE 'TEST_OPENSALESORD',:$.MSG,'-L',:$.GEN;

LINK GENERALLOAD TO :$.GEN;
ERRMSG 1 WHERE :RETVAL <= 0;

:ORD = 0;
SELECT ATOI(KEY1) INTO :ORD
FROM GENERALLOAD
WHERE LINE = 1
AND LOADED = 'Y';

UNLINK GENERALLOAD;
ERRMSG 3 WHERE :ORD = 0;

:ORDNAME = '';
SELECT ORDNAME INTO :ORDNAME
FROM ORDERS
WHERE ORD = :ORD;

/* Windows: Open the Sales Orders form.
In Priority Web, add the ORDERS form as a separate step
in the procedure */
EXECUTE BACKGROUND WINFORM 'ORDERS','',:ORDNAME, '','2';
```

The document duplication pattern:
1. **Export** the source document to a GENERALLOAD linked table.
2. **Modify** the data (change customer, remove unwanted data, etc.).
3. **Import** the modified data as a new record via the same interface.

---

## Finding Interfaces

### Interfaces for a Specific Form

Use the **Form Interfaces** (`FORMINTERFACES`) form, a sub-level of the Form Generator. Displays all interfaces the form participates in. Check this when revising a form in ways that impact the interface (e.g., adding a mandatory column).

### Interfaces for a Specific Form Column

Use the **Interfaces for Column** (`FCLMNINTER`) form, a sub-level of the Form Columns form (itself a sub-level of Form Generator). Check this when revising a form column (e.g., changing its width).

### Finding Existing INTERFACE and DBLOAD Programs

Use any of these methods:

1. Run the **Procedure Steps** (`PROGREP`) report (`System Management > Generators > Procedures > Procedure Reports`):
   - Type `I` for form loads
   - Type `L` for table loads

2. Run the same report for procedures that have the INTERFACE program as a step.

3. Use **SQL Development** (`WINDBI`) program:
   - From Queries menu, select **Find String**.
   - Search for `EXECUTE INTERFACE` or `EXECUTE DBLOAD`.

4. Search for interface components by retrieving `LOAD*` in the various generators (forms, procedures, menus).

### Exporting an Interface Definition to Another Server

Once a form load (interface) is complete and tested, you can export its definition for deployment to another server (e.g., from a test environment to production):

1. Navigate to the **Forms to be Loaded** sub-level form of the Form Load Designer.
2. Run the **Upload Interface** program from the **Actions** list.

This packages the interface definition for installation on the target server, similar to using revision shells for other entities.

*(seen in: handbook:Interfaces@page-211)*

---

## Executing a Form Load from a Trigger or Step Query

When using a variable for the interface name (e.g., `:MYINTERFACE = 'SOMEINTERFACE'`), the privileges program cannot identify the interface being executed. Users may not receive errors, but the form/procedure may not function correctly.

**Solution:** Reference each possible interface in a way that the privileges program can identify them, while ensuring they are not executed:
- Include each interface in a separate `EXECUTE` command within a `GOTO` that jumps to step 999.
- Or add interfaces as procedure steps after an `END` command.

Example: See the `BUF7` trigger in the `DOCPACK` form.

---

## Priority ODBC Driver

### Installation

The Priority ODBC Driver (`priodbc.zip`) is available from the official Priority SDK documentation page. Check the documentation for the latest download link.

### Text Encoding Issues

When querying Priority via ODBC, English text may appear garbled or reversed while Hebrew displays correctly. This is typically related to the SQL Server version and encoding settings. Verify the query encoding and SQL Server collation settings.

## EDI form-load internals

Static EDI interfaces defined in the Form Load Designer persist in several system tables. Understanding which table holds which metadata is essential when diagnosing broken interfaces or attempting programmatic modifications.

### Underlying tables

| Table | Purpose | Related form table |
|---|---|---|
| `EINTER` | Interface header (name, type, description) | EDI form |
| `INTERFORMS` | Columns and triggers for each form in the interface | Maps to FORMCLTRIG on the underlying form |
| `INTERCLMNSFILE` | Column-to-file-field mappings | Maps to FORMCLMNS on the underlying form |

When an interface is compiled, Priority materialises its configuration onto the underlying form's FORMCLTRIG / FORMCLMNS — reading those tables reveals the actual runtime wiring.

### ENAME field truncates at 20 characters

`EINTER.ENAME` (and related FK references) is CHAR(20). Interface names longer than 20 characters silently lose the tail on insert — subsequent `EXECUTE INTERFACE '<long name>'` calls fail with "interface not found" because the stored name is truncated. Keep interface names ≤ 20 characters.

### Raw-SQL INSERT recipe (dev/diagnostic only)

For diagnosing interface behavior on a development server, rows can be inserted into `INTERFORMS` / `INTERCLMNSFILE` directly via SQLI. This bypasses EDI form triggers and does not re-compile the interface — only useful for inspection or ad-hoc testing.

Per the project rule "form interface over raw UPDATE", production interface changes go through the EDI form, not raw INSERT.

### EDI interface creation via WebSDK is partially blocked

- **EINTER** (interface header) — works via WebSDK (`filter`, `newRow`, `fieldUpdate`, `saveRow`).
- **INTERFORMS** subform — works via WebSDK.
- **INTERCLMNSFILE** subform — the CHOOSE-FIELD popup for the column-mapping field cannot be confirmed programmatically. This subform must be edited through the Priority UI or bypassed.

### Workarounds for the INTERCLMNSFILE blocker

1. **Dynamic `-form` interfaces** — generate the interface at runtime with the `-form` flag. No EDI definition row needed; the interface definition is constructed inline from the load parameters. Preferred for runtime loads driven by a procedure.
2. **Raw SQLI on INTERCLMNSFILE** — only for static EDI setups where business triggers on INTERCLMNSFILE are not needed, and only with explicit user approval per the "form interface over raw UPDATE" rule.

See § "Dynamic Interfaces" above for the `-form` pattern.

---

## Verified Real-World Patterns

### Canonical EXECUTE INTERFACE pattern with ERRMSGS readback

A harvest of ~200 live `EXECUTE INTERFACE` call sites in FORMTRIGTEXT, FORMCLTRIGTEXT, and PROGRAMSTEXT shows a consistent shape (~80% of call sites). The skill previously documented STACKERR as the error readback method — production code uses ERRMSGS uniformly for single-interface flows.

```sql
SELECT SQL.TMPFILE INTO :TMP FROM DUMMY;
LINK GENERALLOAD TO :TMP;
GOTO 8888 WHERE :RETVAL <= 0;        /* LINK guard — abort if link fails */
/* ... INSERT INTO GENERALLOAD rows ... */
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE, '-L', :TMP;
SELECT MESSAGE INTO :MSG FROM ERRMSGS
 WHERE USER = SQL.USER AND TYPE = 'i';
GOTO 9999 WHERE :RETVAL <= 0;        /* :RETVAL = 0 means no error rows found */
:PAR1 = STRIND(:MSG, 1, 60);
:PAR2 = STRIND(:MSG, 61, 120);
WRNMSG 500;
LABEL 9999;
LABEL 8888;
UNLINK GENERALLOAD;
```

**Key facts distilled from the harvest:**

- Always read errors from `ERRMSGS WHERE USER = SQL.USER AND TYPE = 'i'` (not `STACK_ERR`).
- Always guard the LINK with `GOTO WHERE :RETVAL <= 0`.
- `GOTO 9999 WHERE :RETVAL <= 0` after the ERRMSGS SELECT: `:RETVAL = 0` means no error rows — safe to skip the warning.
- TLOAD and WLOAD call sites are structurally identical — no separate error-readback path.
- **Empty-batch guard is mandatory.** Running `EXECUTE INTERFACE` on an empty GENERALLOAD (zero INSERT rows) causes a DUMP. Add a `GOTO <label> WHERE :RETVAL <= 0` after the INSERT block before calling EXECUTE INTERFACE.
- Optional `KEY1`/`KEY2`/`KEY3`/`KEY4` readback from GENERALLOAD retrieves IDs of created entities after a successful run.
- Argument grammar: `EXECUTE INTERFACE 'NAME', <msgfile>, [flags...] '-L', <linkfile>`
- Common flags: `-L` (link file), `-nl` (no load), `-m` (message), `-o` (output only), `-w` (warnings as errors), `-enforcebpm`, `-debug`, `-i`.

`STACK_ERR` with `-stackerr` flag is the correct approach only when running **multiple interfaces in sequence** where each run might overwrite earlier errors — documented in § "The STACK_ERR Table" above.

*(seen in: ~200 EXECUTE INTERFACE call sites harvested from FORMTRIGTEXT, FORMCLTRIGTEXT, PROGRAMSTEXT — 2026-04-30)*

---

### EINTER vs LOAD generator forms — TYPE distinction and subform map

Two distinct generator forms create interface entities. Pick based on the interface kind:

| Generator form | EXEC.TYPE | Creates | Use for |
|---|---|---|---|
| `EINTER` (Form Load Designer) | `'I'` | INTERFACE program (TLOAD + WLOAD) | Importing/exporting form data |
| `LOAD` (Characteristics for Download) | `'L'` | DBLOAD program | Importing external flat files into a staging table |

**Important:** The same ENAME can have multiple EXEC rows with different TYPE values (e.g., `LOADCUST` has F + I + L + M + P rows). Always filter by `TYPE` when querying EXEC:

```sql
SELECT EXEC, ENAME, TYPE FROM EXEC WHERE ENAME = 'LOADCUST' FORMAT;
```

**Verified EINTER subforms (EXEC.TYPE = 'I'):**
- `INTERFORMS` → `INTERCLMNS` — column mappings; auto-routes to one of:
  - `INTERCLMNSFILE` — file-field column mappings
  - `INTERCLMNSFILEOUT` — output file-field mappings
  - `INTERCLMNSRECORDTYPE` — record-type scoped mappings
  - `INTERCLMNSDEFAULT` — default value assignments
- `INTERFXMLTAGS` — XML/JSON tag definitions

**Wrong subform names** (do not exist — verified): `INTERFACEFORMS`, `FORMINTERFACES`, `INTERFLD`, `INTRFCFRM`, `EINTERA`, `EINTER1`, `EINTERTAGS`, `FORMS`, `INTERFACE`.

**INTERCLMNS field semantics:**
- `NAME2` — source column name in the load table (e.g., `INT1`, `TEXT2`, `REAL1`)
- `FCNAME` — target form column name (the field receiving the value)
- `POS` — ordering within the record-type column set

*(seen in: TGML_PSERIESLOAD interface investigation + EINTER/LOAD harvest — 2026-04-30)*

### INTERCLMNS saveRow width-mismatch hang

When the source GENERALLOAD column (`NAME2`) has a greater width than the
target form column (`FCNAME`), `websdk_form_action saveRow` on INTERCLMNS
returns `"Child script returned no output"` with no informative error. The
WebSDK call aborts mid-way, leaving stale form state (use `undoRow` to
recover). The INTERCLMNS row is NOT committed.

This is a **silent failure** — no error message, no abort signal from EXECUTE
INTERFACE, no indication that the mapping was not saved.

**Fix before adding the INTERCLMNS row:**
1. Check the target column width:
   ```sql
   SELECT COLUMNNAME, COLWIDTH FROM COLUMNS
   WHERE TABLENAME = 'TGML_PRODSERIES' FORMAT;
   ```
2. If `target_width < source_width`, widen the target first:
   ```sql
   FOR TABLE TGML_PRODSERIES COLUMN DAYNAME CHANGE WIDTH TO 30;
   ```
3. Recompile any form that uses that table after the width change.
4. Retry the INTERCLMNS saveRow.

**Example:** `GENERALLOAD.TEXT5` (WIDTH=30) → `TGML_PRODSERIES.DAYNAME` (CHAR 4):
saveRow returns "Child script returned no output". After `CHANGE WIDTH TO 30`,
saveRow succeeds immediately.

Combined with the GENERALLOAD CHAR1=width-1 rule (see §Mapping the Interface
above): any mapping of a `CHAR*` source column to a multi-char target column
will also trigger this hang if the target was designed expecting a wider value.

*(seen in: session-2026-05-02-tgml-phase1)*
