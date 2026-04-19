# Triggers Reference

> Split from `forms-and-triggers.md` (2026-04-12) for targeted loading. Covers built-in triggers, custom trigger types, error/warning messages, MAILMSG, dynamic titles, INCLUDEs, form preparation, help messages, and default designs.

## Table of Contents

- [1. Built-in Triggers](#1-built-in-triggers)
  - [Field Triggers (Built-in)](#field-triggers-built-in)
  - [Insert Triggers (Built-in)](#insert-triggers-built-in)
  - [Update Triggers (Built-in)](#update-triggers-built-in)
  - [Delete Triggers (Built-in)](#delete-triggers-built-in)
- [2. Custom Triggers -- Complete Reference](#2-custom-triggers----complete-reference)
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
- [3. Error and Warning Messages](#3-error-and-warning-messages)
  - [ERRMSG and WRNMSG](#errmsg-and-wrnmsg)
  - [Specifying Message Content](#specifying-message-content)
  - [Entity References in Messages](#entity-references-in-messages)
  - [Message Parameters](#message-parameters)
  - [General Error Messages (GENMSG)](#general-error-messages-genmsg)
  - [Displaying File Content as Message](#displaying-file-content-as-message)
  - [Require Password Reentry](#require-password-reentry-web-only)
  - [Link to Document in Messages](#link-to-document-in-messages)
- [4. MAILMSG -- Sending Email](#4-mailmsg----sending-email)
  - [Syntax](#syntax)
  - [Controlling Line Breaks](#controlling-line-breaks)
  - [Updating History of Statuses](#updating-history-of-statuses)
  - [Sending a Link to a Document](#sending-a-link-to-a-document)
- [5. Changing Column Titles Dynamically](#5-changing-column-titles-dynamically)
- [6. INCLUDE Command and Buffers](#6-include-command-and-buffers)
  - [The #INCLUDE Command](#the-include-command)
  - [Using Buffers](#using-buffers)
  - [Naming Buffers](#naming-buffers)
  - [Nesting INCLUDE Commands](#nesting-include-commands)
  - [Wildcards in INCLUDEs](#wildcards-in-includes)
  - [Error and Warning Messages with INCLUDEs](#error-and-warning-messages-with-includes)
  - [Checking Trigger Usage](#checking-trigger-usage)
- [7. Trigger Errors](#7-trigger-errors)
- [8. Form Preparation](#8-form-preparation)
- [9. Help Messages](#9-help-messages)
- [10. Default Designs for Forms](#10-default-designs-for-forms)

---

## 1. Built-in Triggers

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

## 2. Custom Triggers -- Complete Reference

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

**Column-level triggers:** Use the column name as the trigger name. The trigger type (CHECK-FIELD, POST-FIELD, etc.) is specified separately in the trigger declaration, not embedded in the name.

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
- **CHOOSE-FIELD does NOT create a picker UI.** It customizes the query an existing picker runs. A plain column with no join and no inherent picker will never invoke CHOOSE-FIELD regardless of the trigger code — see `references/forms.md` > "Foreign-Key Pickers: the join IS the picker".

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

## 3. Error and Warning Messages

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
## 4. MAILMSG -- Sending Email

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

## 5. Changing Column Titles Dynamically

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
## 6. INCLUDE Command and Buffers

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

## 7. Trigger Errors

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

## 8. Form Preparation

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
## 9. Help Messages

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
## 10. Default Designs for Forms

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

## 11. Known trigger quirks

Behaviors that have burned past development sessions. Treat these as the current contract.

### Standard trigger slots exist implicitly on every form

Form-level slots (PRE-INSERT, POST-INSERT, CHECK-FIELD, etc.) do not need to be "created" before writing code. Call `write_to_editor` directly with the slot's SQLI content — the bridge creates the slot row if it does not yet exist.

### Column-level triggers on system columns are blocked

Cannot add a column-level trigger to a system column via WebSDK or `write_to_editor` — the system rejects the insert on FORMCLTRIG. Workaround: form-level POST-UPDATE trigger guarded to be idempotent, typically by checking the column's changed-flag variable or comparing OLD/NEW values via a PRE-UPDATE `SELECT … INTO` snapshot.

### SQLI trigger syntax gotchas

- **No inline `MOD` or `NVL` in expressions.** Use `SELECT` with these functions into a variable first.
- **Variable name `:G1` collides with PREPALLKPI.** Rename project-wide; do not reuse.
- **No conditional assignment with `WHERE`.** Use `IF … THEN … ELSE`; SQLI does not accept `LET :VAR = X WHERE …` syntax.
- **Email validation:** use `:EMAIL LIKE '%@%.%'`, not `STRIND(:EMAIL, '@') > 0`. `STRIND` on NULL is undefined behaviour on some server builds.
- **`PRANDOM`** requires an `EXECUTE` with a `.pq` file — cannot be called inline in a trigger.
- **Adding `AUTOUNIQUE` via DBI on an existing populated table can corrupt rows.** Only safe on fresh tables. For adding auto-increment to a populated table, use a PRE-INSERT trigger: `SELECT NVL(MAX(KLINE),0)+1 INTO :$.KLINE FROM <table>;`.

### Column trigger code — use DBI, not WebSDK `newRow`

`write_to_editor` returns `TRIGGER_NOT_FOUND` for column-level triggers, and WebSDK `newRow` on FORMCLTRIGTEXT silently appends. See `forms.md` § "Column trigger code — use DBI, not WebSDK `newRow`" for the DELETE+INSERT pattern.

### Reading WebSDK trigger messages

After a `saveRow` or `fieldUpdate`, inspect `result.warning`, `result.info`, `result.error`. These capture WRNMSG / PRINT / ERRMSG fired by triggers during the op.

Hebrew error `ערך קיים במסך 'X'` names the blocking subform — peel FORMEXEC → FLINK → FTRIG → FCLMN → EFORM to find the guard, rather than guessing SQL `DELETE`s to clear the "already exists" state.

### FORMPREPERRS accumulates stale errors

FORMPREPERRS is readable via WebSDK but entries accumulate across compile attempts. "Could not read ERRMSGS" reports the same whether the current compile succeeded or failed. Authoritative compile-success signal is the bridge's `prepareForm` status + a post-compile `getRows` on the form itself, not FORMPREPERRS content.
