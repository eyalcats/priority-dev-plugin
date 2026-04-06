/**********************************************************************
 * PRIORITY FORM TRIGGER EXAMPLES
 * Organized by trigger type with explanations.
 * Source: Priority SDK Reference Documentation
 **********************************************************************/


/*=====================================================================
 * CHECK-FIELD EXAMPLES
 * Verification checks on a column value. Only triggered when user
 * inserts or updates the value (not when simply moving through it).
 * If CHECK-FIELD fails, corresponding POST-FIELDs are NOT activated.
 *=====================================================================*/

/* --- Example 1: Restrict column to specific values --- */
/* CHECK-FIELD on TYPE column: only allow O, R, or P */
ERRMSG 4 WHERE :$.TYPE NOT IN ('O','R','P');
/* Message 4: "Specify P (part), R (raw material) or O (other)." */

/* --- Example 2: Warning on negative quantity --- */
/* CHECK-FIELD on QUANT column: warn but allow negative values */
WRNMSG 105 WHERE :$.@ < 0;
/* Message 105: "The designated quantity is a negative number!" */
/* Note: :$.@ refers to the current column value (wildcard) */

/* --- Example 3: Built-in CHECK-FIELD pattern --- */
/* Validates that a customer exists in the CUSTOMERS table */
#line 1 ORDERS/CUSTNAME/CHECK-FIELD
GOTO 1 WHERE :ORDERS.CUSTNAME = '';
SELECT 'X'
FROM CUSTOMERS
WHERE CUSTNAME = :ORDERS.CUSTNAME;
SELECT 192 INTO :SCREENMSG
FROM DUMMY WHERE :RETVAL = 0;
LABEL 1;

/* --- Example 4: CHECK-FIELD with NOT EXISTS and parameters --- */
/* Warns if vendor does not supply the selected part */
WRNMSG 140 WHERE NOT EXISTS
(SELECT 'X' FROM PARTPARAM WHERE PART =
(SELECT PART FROM PART WHERE PARTNAME = :$.@)
AND NSFLAG = 'Y')
AND NOT EXISTS
(SELECT 'X' FROM SUPPART, PART WHERE SUPPART.SUP = :$$.SUP
AND SUPPART.VALIDFLAG = 'Y'
AND SUPPART.PART = PART.PART AND PART.PARTNAME = :$.@);
/* Message 140: "Vendor <P1> does not supply this part." */
/* :PAR1 is set before WRNMSG to display the vendor name */

/* --- Example 5: BPM status form - only one initial status allowed --- */
/* CHECK-FIELD on INITSTATFLAG */
ERRMSG 1 WHERE :$.@ = 'Y' AND EXISTS
(SELECT 'X' FROM XXXX_MYDOCSTATS
WHERE INITSTATFLAG = 'Y' AND MYDOCSTAT <> :$.MYDOCSTAT);

/* --- Example 6: Word template validation --- */
/* CHECK-FIELD on AWORD column - verify template exists */
ERRMSG 501 WHERE :$.@ <> 0 AND NOT EXISTS
(SELECT * FROM TRIGMSG WHERE EXEC = :PRIV_EXEC
AND NUM = :$.@ AND NUM < 0);


/*=====================================================================
 * POST-FIELD EXAMPLES
 * Operations after the column value passes CHECK-FIELD verification.
 * Useful for auto-filling related values.
 *=====================================================================*/

/* --- Example 1: Auto-fill date when opening a new purchase order --- */
/* POST-FIELD for SUPNAME in PORDERS form */
:$.CURDATE = SQL.DATE8;

/* --- Example 2: Built-in POST-FIELD fill pattern --- */
/* After CUSTNAME is validated, fill in all customer-related fields */
#line 1 ORDERS/CUSTNAME/POST-FIELD
SELECT CUSTDES, CUST, CUST, CURRENCY, LINKDATE, PAY, SHIPTYPE, MCUST,
NSFLAG, PAYCUST, SECONDLANGTEXT, VATFLAG
INTO :ORDERS.CUSTDES, :ORDERS.CUST, :ORDERS.CUSTA, :ORDERS.CUSTCURRENCY,
:ORDERS.CUSTLINKDATE, :ORDERS.CUSTPAY, :ORDERS.CUSTSHIPTYPE, :ORDERS.MCUST,
:ORDERS.NSFLAG, :ORDERS.PAYCUST, :ORDERS.SECONDLANGTEXT, :ORDERS.VATFLAG
FROM CUSTOMERS
WHERE CUSTNAME = :ORDERS.CUSTNAME;

/* --- Example 3: Calculated price using wildcards --- */
/* POST-FIELD in ORDERITEMS form using $ and $$ wildcards */
:$.QPRICE = REALQUANT(:$.TQUANT)
* :$.PRICE * (100.0 - :$.PERCENT) / 100.0
* (:$$.CURRENCY = -1 ? :$.IEXCHANGE : 1.0);
/* :$ = current form, :$$ = upper-level form */

/* --- Example 4: BPM status change with mail notification --- */
/* POST-INSERT/POST-UPDATE trigger for status changes */
GOTO 51 WHERE :$.MYDOCSTAT = :$1.MYDOCSTAT;
:doc = :$.MYDOC;
:status = :$.MYDOCSTAT;
:statustype = 'PRIV_MYBPM';
#INCLUDE STATUSAUTOMAIL/SendStatusMail
LABEL 51;
/* :$1.MYDOCSTAT is the previous (stored) value */


/*=====================================================================
 * CHOOSE-FIELD / SEARCH-FIELD EXAMPLES
 * Short list or searchable list for user selection.
 *=====================================================================*/

/* --- Example 1: Standard SQL query Choose --- */
/* CHOOSE-FIELD for PARTNAME in PORDERITEMS */
/* Shows distinct parts supplied by the current vendor */
SELECT DISTINCT PARTDES, PARTNAME
FROM PART WHERE PART =
(SELECT PART FROM SUPPART WHERE SUP = :$$.SUP AND VALIDFLAG = 'Y')
AND PART <> 0
ORDER BY 1;
/* First arg = description shown to user */
/* Second arg = value inserted into the column */

/* --- Example 2: Constant values from messages --- */
/* CHOOSE-FIELD using predefined message range */
MESSAGE BETWEEN 100 AND 102;
/* Messages must be structured as: Value, Description */

/* --- Example 3: Choose with NO SORT --- */
/* Preserves query order instead of alphabetical sorting */
/* NO SORT */
SELECT STATDES, ITOA(MYDOCSTAT) FROM XXXX_MYDOCSTATS
ORDER BY SORT;
/* Use ITOA to convert numbers to CHAR for Choose lists */

/* --- Example 4: Choose with AND STOP --- */
/* Stops on first successful query in a union choose */
SELECT /* AND STOP */ PARTDES, PARTNAME
FROM PART WHERE PARTNAME = :$.PARTNAME;

/* --- Example 5: Word template CHOOSE-FIELD --- */
/* CHOOSE-FIELD for AWORD column - list available templates */
SELECT MESSAGE, ITOA(NUM) FROM TRIGMSG
WHERE EXEC = :PRIV_EXEC
AND NUM < 0
ORDER BY 2;


/*=====================================================================
 * PRE-INSERT / POST-INSERT EXAMPLES
 * PRE-INSERT: Checks before a new record is inserted.
 * POST-INSERT: Operations after successful insertion.
 *=====================================================================*/

/* --- PRE-INSERT Example 1: Verify GL account is attached --- */
WRNMSG 1 WHERE :$.ACCOUNT = 0;

/* --- PRE-INSERT Example 2: Prevent manual changes (BPM) --- */
/* Only allow changes through form interface */
ERRMSG 17 WHERE :FORM_INTERFACE <> 1;

/* --- PRE-INSERT Example 3: Combined PRE-INSERT-UPDATE --- */
/* Single trigger for both insert and update */
ERRMSG 2 WHERE :$.INITSTATFLAG = 'Y' AND :$.CHANGEFLAG <> 'Y';

/* --- POST-INSERT Example 1: Insert into related table (BPM) --- */
/* After inserting a status, also insert into DOCSTATUSES */
INSERT INTO DOCSTATUSES(TYPE,ORIGSTATUSID)
VALUES(:$.STATUSTYPE, :$.MYDOCSTAT);

UPDATE DOCSTATUSES SET STATDES = :$.STATDES,
ESTATDES = :$.ESTATDES,
SORT = :$.SORT, COLOR = :$.VCOLOR, INACTIVE = :$.INACTIVE,
DOCOPENED = :$.DOCOPENED
WHERE TYPE = :$.STATUSTYPE AND ORIGSTATUSID = :$.MYDOCSTAT;


/*=====================================================================
 * PRE-UPDATE / POST-UPDATE EXAMPLES
 * PRE-UPDATE: Checks before a record is updated.
 * POST-UPDATE: Operations after successful update.
 *=====================================================================*/

/* --- PRE-UPDATE Example: Same as PRE-INSERT often --- */
WRNMSG 1 WHERE :$.ACCOUNT = 0;

/* --- POST-UPDATE Example 1: Update Missing Components --- */
/* POST-FORM trigger in kit items sub-level */
UPDATE SERIAL SET KITFLAG = 'Y' WHERE SERIAL = :$$.SERIAL
AND EXISTS
(SELECT 'X' FROM KITITEMS WHERE SERIAL = :$$.DOC AND TBALANCE > 0
AND KITFLAG = 'Y');
GOTO 1 WHERE :RETVAL > 0;

/* --- POST-UPDATE Example 2: BPM status synchronization --- */
/* Same as POST-INSERT for BPM status forms */
UPDATE DOCSTATUSES SET STATDES = :$.STATDES,
ESTATDES = :$.ESTATDES,
SORT = :$.SORT, COLOR = :$.VCOLOR, INACTIVE = :$.INACTIVE,
DOCOPENED = :$.DOCOPENED
WHERE TYPE = :$.STATUSTYPE AND ORIGSTATUSID = :$.MYDOCSTAT;


/*=====================================================================
 * PRE-DELETE / POST-DELETE EXAMPLES
 * PRE-DELETE: Checks before a record is deleted.
 * POST-DELETE: Operations after successful deletion.
 *=====================================================================*/

/* --- PRE-DELETE Example 1: Warn about deleting bonus items --- */
WRNMSG 334 WHERE :$.BONUSFLAG IN ('Y','F');

/* --- PRE-DELETE Example 2: Built-in delete check --- */
/* Prevents deleting an order that has order items */
#line 1 ORDERS/DELETE
SELECT ENTMESSAGE('ORDERITEMS','F',0) INTO :PROGPARAM FROM DUMMY;
SELECT 94 INTO :PROGMSG
FROM ORDERITEMS WHERE (:$1.ORD <> 0 AND ORD = :$1.ORD);

/* --- POST-DELETE Example 1: Delete from related table --- */
DELETE FROM ORDERITEMSA WHERE ORDI = :$.ORDI;

/* --- POST-DELETE Example 2: Clean up BPM statuses --- */
DELETE FROM DOCSTATUSES WHERE TYPE = :$.STATUSTYPE
AND ORIGSTATUSID = :$.MYDOCSTAT;

/* --- POST-DELETE Example 3: Clean up ToDo list --- */
DELETE FROM TODOLIST WHERE TYPE = 'PRIV_MYBPM' AND IV = :$.MYDOC;


/*=====================================================================
 * PRE-FORM / POST-FORM EXAMPLES
 * PRE-FORM: Always activated before the form opens.
 * POST-FORM: Activated when exiting if user made changes.
 *=====================================================================*/

/* --- PRE-FORM Example 1: Reset variable --- */
:MYVAR = 0;

/* --- PRE-FORM Example 2: Retrieve and display all records --- */
:KEYSTROKES = '*{Exit}';

/* --- PRE-FORM Example 3: Refresh records after an Action --- */
:ACTIVATEQUERY = 1;

/* --- PRE-FORM Example 4: Activate PRE-FORM after every query --- */
:PREFORMQUERY = 1;

/* --- PRE-FORM Example 5: Deactivate data privileges --- */
:$.NOCLMNPRIV.T = 1;

/* --- PRE-FORM Example 6: Deactivate data privileges for table --- */
:$.NOTBLPRIV.T = 'AGENTS';
/* With join ID: */
:$.NOTBLPRIV.T = 'AGENTS.5';

/* --- PRE-FORM Example 7: BPM statuses form initialization --- */
:statustype = 'PRIV_MYBPM';
:KEYSTROKES = '*{Exit}';

/* --- PRE-FORM Example 8: Change column title dynamically --- */
/* Requires: form without default design, T in One-to-many column */
:MYFORM.TEST.TITLE = 'New Title';

/* --- PRE-FORM Example 9: Hide column dynamically --- */
:MYFORM.TEST.TITLE = '';

/* --- PRE-FORM Example 10: Text form control --- */
:$.READONLY.T = 1;    /* Make text form read-only */
:$.NOEDITOR.T = 1;    /* Prevent non-HTML text editor */
:$.NOHTML.T = 1;      /* Create plain text form */

/* --- POST-FORM Example 1: Verify initial status exists (BPM) --- */
ERRMSG 4 WHERE NOT EXISTS
(SELECT 'X' FROM XXXX_MYDOCSTATS WHERE INITSTATFLAG = 'Y');


/*=====================================================================
 * ERRMSG / WRNMSG MESSAGE EXAMPLES
 * ERRMSG halts trigger execution; WRNMSG continues execution.
 *=====================================================================*/

/* --- Basic ERRMSG with condition --- */
ERRMSG 4 WHERE :$.TYPE NOT IN ('O','R','P');
/* Message 4 must be defined in Error & Warning Messages form */
/* Message numbers for custom messages must be > 500 */

/* --- WRNMSG with condition --- */
WRNMSG 105 WHERE :$.@ < 0;

/* --- Messages with parameters <P1>, <P2>, <P3> --- */
/* Message text: "Vendor <P1> does not supply this part." */
/* Set :PAR1 before calling WRNMSG/ERRMSG: */
:PAR1 = :$$.SUPNAME;
WRNMSG 140 WHERE ...;

/* --- Type conversion for parameters (CHAR type required) --- */
:PAR1 = DTOA(:$.CURDATE, 'MM/DD/YY');   /* Date to string */
:PAR2 = ITOA(:$.QUANT);                  /* Integer to string */
:PAR3 = RTOA(:$.PRICE, 2);               /* Real to string */

/* --- GENMSG: General error callable from any entity --- */
GENMSG 501 WHERE :RETVAL <= 0;
/* Messages defined in: Compiled Programs > GENMSG > Program Messages */

/* --- Display file content as error message --- */
/* Use special message number 1000000 */
SELECT SQL.TMPFILE INTO :MESSAGEFILE FROM DUMMY;
SELECT 'Sample message' FROM DUMMY ASCII UNICODE :MESSAGEFILE;
ERRMSG 1000000;
/* This message number should NOT appear in Error & Warning Messages form */

/* --- Require password reentry (Web Only) --- */
WRNMSG 1000001;
/* Results in :PWD_RETVAL:
   1 = Username changed, no password check
   2 = Username unchanged, password correct
   3 = Username unchanged, password incorrect
   4 = User pressed Cancel */

/* --- Entity reference in message text --- */
/* Message: "See the {CUSTOMERS.F} form for details." */
/* {entity_name.F|R|P|M} - F=form, R=report, P=procedure, M=menu */

/* --- Link to document in message --- */
/* Message: "Here is a link to order <P1.ORDERS.F>." */
:PAR1 = 'SO1212888';


/*=====================================================================
 * MAILMSG EMAIL EXAMPLES
 * Send internal/external mail with optional attachments.
 *=====================================================================*/

/* --- Send to internal Priority user --- */
MAILMSG 9 TO USER :NEXTSIGN WHERE :NEXTSIGN <> 0
AND :NEXTSIGN <> SQL.USER;

/* --- Send to email address with attachment --- */
:EMAIL = 'johndoe@example.com';
:FILE = '..\tmp\msg.doc';
MAILMSG 5 TO EMAIL :EMAIL DATA :FILE;

/* --- Send link to document --- */
/* Message: "Here is a link to order <P1.ORDERS.F>." */
:PAR1 = 'SO1212888';
MAILMSG 1 TO USER :USER;

/* --- Update History of Statuses (DOCTODOLISTLOG) --- */
/* Must be used in a sub-level form, not root form */
:PAR1 = 'O';       /* Type for ORDERS form */
:PAR2 = '15982';   /* Internal Document ID */
MAILMSG 1 TO USER -2;

/* --- HTML line break control in messages --- */
/* Include this string in message to enable HTML formatting: */
/* <!--| priority:priform |--> */
/* Then use <br> for line breaks in message text: */
/* "Service Call <P1> was updated.<br><P2><br><P3>" */

/* --- Override reply-to address --- */
/* Set :_REPLYTOEMAIL before MAILMSG (external mail only) */
:_REPLYTOEMAIL = 'noreply@company.com';
MAILMSG 5 TO EMAIL :EMAIL;


/*=====================================================================
 * #INCLUDE AND BUFFER EXAMPLES
 * Reuse triggers across forms without rewriting.
 *=====================================================================*/

/* --- Include a column trigger from another form --- */
#INCLUDE PART/TYPE/CHECK-FIELD
/* Includes the entire CHECK-FIELD trigger for TYPE in PART form */

/* --- Include a row/form trigger --- */
#INCLUDE ORDERS/POST-INSERT_AXXX

/* --- Include a buffer (shared SQL statements) --- */
/* Buffers share common SQL across multiple triggers */
#INCLUDE TRANSTRIG/BUF10
/* BUF10 contains shared validation logic */

/* --- Additional statements before/after include --- */
/* You can add your own code around the included trigger */
:MYVAR = 0;
#INCLUDE PART/TYPE/CHECK-FIELD
ERRMSG 501 WHERE :MYVAR > 10;

/* --- Wildcards in includes for portability --- */
/* $  = current form */
/* $$ = upper-level form */
/* @  = current column name */
/* These resolve relative to the form where the trigger activates */
/* :$$.DOC in Received Items = :DOCUMENTS_P.DOC */
/* :$$.DOC in Shipped Items  = :DOCUMENTS_D.DOC */

/* --- BPM status mail include --- */
#INCLUDE STATUSAUTOMAIL/SendStatusMail

/* --- Click2Sign include --- */
:IVC = :$.MYDOC;
:TYPEC = 'PRIV_MYBPM';
#INCLUDE func/click2sign


/*=====================================================================
 * USER-DEFINED VARIABLES IN TRIGGERS
 * Best practices for declaring and using variables.
 *=====================================================================*/

/* --- Initialize variables (no automatic starting value) --- */
:CNT = 0;
SELECT COUNT(*) INTO :CNT
FROM ORDSERIAL, SERIAL
WHERE ORDSERIAL.ORDI = :$.ORDI
AND ORDSERIAL.SERIAL = SERIAL.SERIAL
AND SERIAL.PEDATE > :$.DUEDATE
AND SERIAL.CLOSEDATE = 0;

/* --- Copy form values to local variables --- */
SELECT 0 + :$.TQUANT, 0 + :$.QUANT INTO :TQUANT, :QUANT FROM DUMMY;
/* Or simply: */
:TQUANT = :$.TQUANT;
:QUANT = :$.QUANT;

/* --- Global variables (same value across companies) --- */
/* Prevents company-specific prefix from being added */
:GLOBAL.SOMEVAR = 'shared_value';

/* --- Detecting previous value vs current value --- */
GOTO 1 WHERE :$1.PARTNAME = '' OR :$.ORDI = 0;
GOTO 1 WHERE :$.@ = :$1.PARTNAME;
/* :$.PARTNAME  = current screen value */
/* :$1.PARTNAME = value stored in the database */

/* --- Detecting form interface vs manual entry --- */
GOTO 1 WHERE :FORM_INTERFACE = 1;
/* :FORM_INTERFACE = 1 when records filled by form load interface */
/* :FORM_INTERFACE_NAME = name of the interface, empty if REST API */

/* --- Detecting number of changed fields --- */
GOTO 1 WHERE :_CHANGECOUNT = 0;
/* :_CHANGECOUNT = number of revised visible fields in current record */


/*=====================================================================
 * REAL-WORLD PATTERNS FROM SERVICE CALLS
 * Patterns discovered from Priority SDK service call analysis.
 *=====================================================================*/

/* --- Validate against parent form using :$$. (Ref: SCI25092074) --- */
/* Block record split if reconciliation exists in parent */
ERRMSG 2 WHERE EXISTS
(SELECT 'X' FROM FNCITEMSA
 WHERE CFNCTRANS = :$$.FNCTRANS
 AND CKLINE = :$$.KLINE);
/* :$$. references the upper-level form's columns */

/* --- Multiple ERRMSG with NOT IN for ShipEngine (Ref: SCI24095858) --- */
/* Validate unit descriptions for shipping integration */
ERRMSG 11 WHERE :$.SHIPSTATION = 'Y'
AND :$.UNITDES NOT IN ('pound','ounce','gram','kilogram');
ERRMSG 13 WHERE :$.LSHIPSTATION = 'Y'
AND :$.UNITDES NOT IN ('inch','centimeter');

/* --- Conditional budget assignment with ternary (Ref: SCI25008425) --- */
/* POST-FIELD: preserve manual budget if set, otherwise use account budget */
:$.BUDGET = (:$.BUDGET <> 0 AND :ACCNAMEFLAG = 0
  ? :$.BUDGET
  : :ACCBUDGET);

/* --- Detect API vs UI context (Ref: SCI24051075) --- */
/* In PRE-INSERT: skip UI-only logic when called via REST API or interface */
GOTO 1 WHERE :FORM_INTERFACE = 1;
GOTO 1 WHERE :FORM_INTERFACE_NAME <> '';
/* :FORM_INTERFACE = 1 when loaded via interface or API */
/* :FORM_INTERFACE_NAME = interface name (empty string = REST API) */
/* Use this to skip KEYSTROKES, MAILMSG, or other UI-only actions */

/* --- Block manual changes (allow only interface) (Ref: BPM pattern) --- */
/* PRE-INS-UPD-DEL trigger: prevent users from editing statuses directly */
ERRMSG 17 WHERE :FORM_INTERFACE <> 1;

/* --- MAILMSG with data file attachment (Ref: SCI24108245) --- */
/* Send email from a trigger with attached data file */
:MED_EMAIL = '';
SELECT EMAIL INTO :MED_EMAIL FROM PHONEBOOK
WHERE PHONE = :$$.CUST;
:TMPOUT = NEWATTACH('report', '.html');
/* ... generate report content to :TMPOUT ... */
MAILMSG 2002 TO EMAIL :MED_EMAIL DATA :TMPOUT;
