/**********************************************************************
 * PRIORITY SQL COMMON PATTERNS
 * Variables, flow control, LINK/UNLINK, string functions,
 * date functions, DBI syntax, SELECT formats, UPSERT.
 * Source: Priority SDK Reference Documentation
 **********************************************************************/


/*=====================================================================
 * VARIABLE DECLARATIONS AND USAGE
 * All variables use the : (colon) prefix. Max 120 characters.
 *=====================================================================*/

/* --- Default type is CHAR. To force a specific type: --- */
:j = 0.0;              /* REAL */
:k = 0;                /* INT (also DATE, TIME, DAY) */
:SINCHAR = '\0';       /* Single CHAR (width 1) */
:CONV = 0E-9;          /* REAL with high precision */

/* --- Type inheritance from expressions --- */
/* :totprice inherits REAL from QUANT and PRICE */
SELECT :ORDERITEMS.QUANT * :ORDERITEMS.PRICE INTO :totprice FROM DUMMY;
/* Or using assignment syntax: */
:totprice = :ORDERITEMS.QUANT * :ORDERITEMS.PRICE;

/* --- Force REAL type for undefined variable --- */
SELECT 0.0 + :j FROM DUMMY FORMAT;

/* --- System variables --- */
:RETVAL       /* Return value of previous query */
:SCRLINE      /* Current form line (triggers only) */
:PAR1         /* Message parameter 1 (CHAR, max 64 chars) */
:PAR2         /* Message parameter 2 */
:PAR3         /* Message parameter 3 */
SQL.USER      /* Internal number of the current user */
SQL.DATE      /* Current date and time */
SQL.DATE8     /* Current date without time */
SQL.TMPFILE   /* Full path to a temporary file name */
SQL.ENV       /* Current Priority company */
SQL.LINE      /* Line number during retrieval */
SQL.GUID      /* Random 32-character string (UUID) */
SQL.HOSTING   /* 1 if hosted in Priority Cloud */

/* --- Form column variables (three forms) --- */
:FORMNAME.COLUMNNAME          /* Current value on screen */
:FORMNAME1.COLUMNNAME         /* Value stored in the table */
:FORMNAME.COLUMNNAME.TITLE    /* Column's title */

/* --- Form wildcards --- */
:$              /* Current form */
:$$             /* Upper-level form (one level up) */
:$$$            /* Two levels up */
:@              /* Current column name */


/*=====================================================================
 * FLOW CONTROL (GOTO, LABEL, LOOP, GOSUB, END)
 * Control execution flow in triggers and step queries.
 *=====================================================================*/

/* --- GOTO: Jump forward to a label --- */
GOTO 99 WHERE :RETVAL <= 0;
/* ... code executed only if :RETVAL > 0 ... */
LABEL 99;

/* --- LOOP: Jump backward to a label --- */
LABEL 1;
FETCH C INTO :VAR;
GOTO 8 WHERE :RETVAL = 0;
/* ... process data ... */
LOOP 1;
LABEL 8;

/* --- END: Stop execution --- */
END WHERE :RETVAL <= 0;

/* --- SLEEP: Pause for N seconds --- */
SLEEP 5;

/* --- GOSUB / SUB / RETURN: Sub-routines --- */
DECLARE C CURSOR FOR
SELECT ORD, ORDNAME FROM ORDERS WHERE CURDATE > SQL.DATE8 - 30;
OPEN C;
GOTO 9 WHERE :RETVAL = 0;
LABEL 1;
FETCH C INTO :ORD, :ORDNAME;
GOTO 8 WHERE :RETVAL = 0;
/* Main processing */
GOSUB 100 WHERE :ORD > 0;
LOOP 1;
LABEL 8;
CLOSE C;
LABEL 9;
END;

SUB 100;
/* Sub-routine: additional processing with fetched fields */
/* Sub-routine IDs: 1 to 999999 */
RETURN;

/* --- Complete cursor pattern with error handling --- */
DECLARE C CURSOR FOR
SELECT CUSTNAME, CUST FROM CUSTOMERS WHERE CUST > 0;
OPEN C;
GOTO 9 WHERE :RETVAL = 0;  /* No records found */
LABEL 1;
FETCH C INTO :CUSTNAME, :CUST;
GOTO 8 WHERE :RETVAL = 0;  /* No more records */
/* ... database manipulations ... */
GOSUB 100 WHERE :CUST > 100;
LOOP 1;
LABEL 8;
CLOSE C;
LABEL 9;
END;

SUB 100;
/* Additional processing */
RETURN;


/*=====================================================================
 * LINK / UNLINK PATTERNS
 * Create temporary copies of database tables for safe manipulation.
 *=====================================================================*/

/* --- Basic LINK/UNLINK pattern --- */
SELECT SQL.TMPFILE INTO :TMPFILE FROM DUMMY;
LINK ORDERS TO :TMPFILE;
ERRMSG 1 WHERE :RETVAL <= 0;  /* CRITICAL: always check! */
/* All operations on ORDERS now affect the temporary copy */
INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG WHERE CURDATE = SQL.DATE8;
/* ... manipulate temporary data ... */
UNLINK ORDERS;

/* --- LINK with GOTO error handling --- */
SELECT SQL.TMPFILE INTO :TMPFILE FROM DUMMY;
LINK ORDERS TO :TMPFILE;
GOTO 99 WHERE :RETVAL <= 0;
/* ... operations on temporary ORDERS ... */
UNLINK ORDERS;
LABEL 99;

/* --- LINK ALL: Link and copy all records --- */
/* Use sparingly - copies entire table! */
SELECT SQL.TMPFILE INTO :TMPFILE FROM DUMMY;
LINK ALL ORDERS TO :TMPFILE;
GOTO 99 WHERE :RETVAL <= 0;
/* Temporary ORDERS now contains all records from the original */
UNLINK ORDERS;
LABEL 99;

/* --- Multiple links with suffixes --- */
/* Cannot link same table twice; use different suffixes */
SELECT SQL.TMPFILE INTO :T1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :T2 FROM DUMMY;
LINK ORDERS A TO :T1;
GOTO 99 WHERE :RETVAL <= 0;
LINK ORDERS B TO :T2;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO ORDERS A
SELECT * FROM ORDERS B
WHERE CURDATE > SQL.DATE8 - 30;

UNLINK ORDERS A;
UNLINK ORDERS B;
LABEL 99;

/* --- UNLINK AND REMOVE: Delete linked file when done --- */
/* Important in loops to prevent accumulation of temp files */
UNLINK AND REMOVE ORDERS;

/* --- LINK return values --- */
/* 2 = new file created */
/* 1 = linked to existing file */
/* 0 = failure */
/* -1 = duplicate link to same table name */

/* WARNING: If LINK fails and you INSERT/UPDATE the "linked" table,
   operations execute on the REAL table! ALWAYS check :RETVAL. */


/*=====================================================================
 * STRING MANIPULATION FUNCTIONS
 * Conversion, information, and manipulation functions.
 *=====================================================================*/

/* --- Type conversions --- */
SELECT ITOA(35, 4) FROM DUMMY FORMAT;    /* '0035' - INT to CHAR with leading zeros */
SELECT ITOA(35) FROM DUMMY FORMAT;       /* '35' - INT to CHAR minimum width */
SELECT ATOI('35') FROM DUMMY FORMAT;     /* 35 - CHAR to INT (max 10 chars) */
SELECT ATOR('109012.99') FROM DUMMY FORMAT;  /* 109012.990000 - CHAR to REAL */
SELECT RTOA(150654.665, 2, USECOMMA) FROM DUMMY FORMAT;  /* '150.654,67' */
SELECT RTOA(3.665432, 2) FROM DUMMY FORMAT;  /* '3.67' */

/* --- String information --- */
SELECT STRLEN('Priority') FROM DUMMY FORMAT;     /* 8 */
SELECT ISALPHA('Priority_21') FROM DUMMY FORMAT; /* 1 (starts with letter) */
SELECT ISALPHA('21Priority') FROM DUMMY FORMAT;  /* 0 */
SELECT ISPREFIX('HEEE', 'HEEE_ORDERS') FROM DUMMY FORMAT;  /* 1 */
SELECT ISNUMERIC('07666') FROM DUMMY FORMAT;     /* 1 */
SELECT ISNUMERIC('14.5') FROM DUMMY FORMAT;      /* 0 */
SELECT ISFLOAT('14.5') FROM DUMMY FORMAT;        /* 1 */

/* --- STRINDEX: Find position of substring --- */
:STR = 'hello world this is my string';
:SUBSTR = 'is';
:INDEX = 1;
SELECT STRINDEX(:STR, :SUBSTR, :INDEX) FROM DUMMY FORMAT; /* 15 */
:INDEX = -1;  /* Reverse search */
SELECT STRINDEX(:STR, :SUBSTR, :INDEX) FROM DUMMY FORMAT; /* 18 */
/* Returns 0 if not found */

/* --- Using STRINDEX in queries --- */
:FDT = BEGINOFYEAR(SQL.DATE);
SELECT CUSTNAME, CUSTDES, CREATEDDATE
FROM CUSTOMERS
WHERE CREATEDDATE > :FDT
AND STRINDEX(CUSTNAME, '073', 1) > 0
FORMAT;

/* --- String concatenation --- */
SELECT STRCAT('abc', 'ba') FROM DUMMY FORMAT;  /* 'abcba' */
/* Result limited to 127 characters */

/* --- Substring extraction --- */
SELECT SUBSTR('Priority', 3, 2) FROM DUMMY FORMAT;   /* 'io' */
SELECT RSUBSTR('Priority', 3, 2) FROM DUMMY FORMAT;  /* 'ri' (right to left) */
/* ALWAYS use SUBSTR/RSUBSTR instead of STRIND/RSTRIND with variables */

/* --- First N characters --- */
SELECT STRPREFIX('Priority', 2) FROM DUMMY FORMAT;   /* 'Pr' */

/* --- Split by delimiter --- */
SELECT STRPIECE('a/b.c.d/e.f', '.', 2, 1) FROM DUMMY FORMAT;  /* 'c' */
SELECT STRPIECE('a/b.c.d/e.f', '/', 2, 1) FROM DUMMY FORMAT;  /* 'b.c.d' */
/* STRPIECE(string, delimiter, start_part, count_parts) */

/* --- Case conversion --- */
SELECT TOUPPER('marianne') FROM DUMMY FORMAT;  /* MARIANNE */
SELECT TOLOWER('MARIANNE') FROM DUMMY FORMAT;  /* marianne */

/* --- Hex conversions --- */
SELECT ITOH(10) FROM DUMMY FORMAT;     /* 'a' - integer to hex */
SELECT HTOI('2f4') FROM DUMMY FORMAT;  /* 756 - hex to integer */


/*=====================================================================
 * DATE FUNCTIONS AND CONVERSIONS (ATOD, DTOA)
 * Date parsing, calculated dates, and format conversion.
 *=====================================================================*/

/* --- Date parsing functions --- */
SELECT DAY(03/22/06) FROM DUMMY FORMAT;         /* 4 (weekday: Sun=1) */
SELECT MDAY(03/22/06) FROM DUMMY FORMAT;        /* 22 (day in month) */
SELECT MONTH(03/22/06) FROM DUMMY FORMAT;       /* 3 */
SELECT YEAR(03/22/06) FROM DUMMY FORMAT;        /* 2006 */
SELECT WEEK(03/22/06) FROM DUMMY FORMAT;        /* 612 (YYWW) */
SELECT WEEK6(03/22/06) FROM DUMMY FORMAT;       /* 200612 (YYYYWW) */
SELECT QUARTER(09/22/06) FROM DUMMY FORMAT;     /* 3Q-2006 */
SELECT TIMELOCAL(05/04/06) FROM DUMMY FORMAT;   /* 1146693600 (epoch) */
SELECT CTIME(1146693600) FROM DUMMY FORMAT;     /* Date from epoch */

/* --- Calculated date functions --- */
SELECT BEGINOFWEEK(2220) FROM DUMMY FORMAT;       /* First day of week 20 */
SELECT BEGINOFMONTH(05/04/06) FROM DUMMY FORMAT;  /* 05/01/06 */
SELECT BEGINOFQUARTER(05/04/06) FROM DUMMY FORMAT; /* 04/01/06 */
SELECT BEGINOFHALF(10/22/06) FROM DUMMY FORMAT;   /* 07/01/06 */
SELECT BEGINOFYEAR(10/22/06) FROM DUMMY FORMAT;   /* 01/01/06 */
SELECT ENDOFMONTH(04/22/06) FROM DUMMY FORMAT;    /* 04/30/06 */
SELECT ENDOFQUARTER(03/22/06) FROM DUMMY FORMAT;  /* 03/31/06 */
SELECT ENDOFHALF(03/22/06) FROM DUMMY FORMAT;     /* 06/30/06 */
SELECT ENDOFYEAR(03/22/06) FROM DUMMY FORMAT;     /* 12/31/06 */

/* --- Extract time from DATE 14 (date+time) --- */
SELECT 17/05/09 12:25 MOD 24:00 FROM DUMMY FORMAT;  /* 12:25 */

/* --- ATOD: Convert string to date --- */
SELECT ATOD('06/21/06', 'MM/DD/YY') FROM DUMMY FORMAT;
SELECT ATOD('06/21/2006', 'MM/DD/YYYY') FROM DUMMY FORMAT;
SELECT ATOD('062106', 'MMDDYY') FROM DUMMY FORMAT;
SELECT ATOD('311006', 'DDMMYY') FROM DUMMY FORMAT;
SELECT ATOD('31102006', 'DDMMYYYY') FROM DUMMY FORMAT;

/* --- DTOA: Convert date to string --- */
:DATE = 06/01/06;
SELECT DTOA(:DATE, 'MMMM') FROM DUMMY FORMAT;      /* June */
SELECT DTOA(:DATE, 'MMM') FROM DUMMY FORMAT;        /* Jun */
SELECT DTOA(:DATE, 'MM') FROM DUMMY FORMAT;         /* 06 */
SELECT DTOA(:DATE, 'MONTH') FROM DUMMY FORMAT;      /* Jun-06 */
SELECT DTOA(:DATE, 'day') FROM DUMMY FORMAT;        /* Thu */
SELECT DTOA(:DATE, 'XX/XX/XX') FROM DUMMY FORMAT;   /* locale-dependent */
SELECT DTOA(:DATE, 'FULLDATE') FROM DUMMY FORMAT;   /* Jun 01,2006 */

:DATE = 06/01/06 12:33;
SELECT DTOA(:DATE, 'MM/DD/YY hh:mm,day') FROM DUMMY FORMAT;  /* 06/01/06 12:33,Thu */
SELECT DTOA(:DATE, 'MMM-YY') FROM DUMMY FORMAT;               /* Jun-06 */
SELECT DTOA(:DATE, 'MMMM-YYYY') FROM DUMMY FORMAT;            /* June-2006 */

/* --- DTOA with inline text --- */
SELECT DTOA(:DATE, 'The current date is MM-DD-YY, and the time is hh:mm.')
FROM DUMMY FORMAT;

/* --- Date arithmetic --- */
:TOMORROW = SQL.DATE8 + 24:00;
:NEXT_WEEK = SQL.DATE8 + (24:00 * 7);
:DAYS_AGO_30 = SQL.DATE8 - (24:00 * 30);


/*=====================================================================
 * DBI SYNTAX EXAMPLES
 * Database Interpreter for table/column/key operations.
 *=====================================================================*/

/* --- CREATE TABLE --- */
CREATE TABLE XXXX_MYTABLE 'My Custom Table' 0
XXXX_ID (INT, 13, 'ID')
XXXX_NAME (CHAR, 32, 'Name')
XXXX_AMOUNT (REAL, 13, 2, 'Amount')
XXXX_CURDATE (DATE, 8, 'Date')
XXXX_FLAG (CHAR, 1, 'Active?')
AUTOUNIQUE (XXXX_ID)
UNIQUE (XXXX_NAME);

/* --- DELETE TABLE --- */
DELETE TABLE XXXX_MYTABLE;

/* --- CHANGE TABLE NAME --- */
FOR TABLE XXXX_MYTABLE
CHANGE NAME TO XXXX_NEWTABLE;

/* --- CHANGE TABLE TITLE --- */
FOR TABLE XXXX_MYTABLE CHANGE TITLE TO 'New Table Title';

/* --- ADD COLUMN --- */
FOR TABLE XXXX_MYTABLE
INSERT XXXX_NEWCOL (INT, 13, 'New Column');

/* --- ADD COLUMN with decimal precision --- */
FOR TABLE XXXX_MYTABLE
INSERT XXXX_AMOUNT (REAL, 13, 2, 'Amount');

/* --- DELETE COLUMN --- */
FOR TABLE XXXX_MYTABLE DELETE XXXX_OLDCOL;

/* --- CHANGE COLUMN NAME --- */
FOR TABLE XXXX_MYTABLE COLUMN XXXX_OLDNAME
CHANGE NAME TO XXXX_NEWNAME;

/* --- CHANGE COLUMN WIDTH --- */
FOR TABLE XXXX_MYTABLE COLUMN XXXX_NAME CHANGE WIDTH TO 48;

/* --- CHANGE COLUMN TITLE --- */
FOR TABLE XXXX_MYTABLE COLUMN XXXX_NAME CHANGE TITLE TO 'New Title';

/* --- CHANGE DECIMAL PRECISION --- */
FOR TABLE XXXX_MYTABLE COLUMN XXXX_AMOUNT
CHANGE DECIMAL TO 4;

/* --- CHANGE NUMBER TYPE (toggle INT/REAL) --- */
FOR TABLE XXXX_MYTABLE COLUMN XXXX_COL
CHANGE NUMBER TYPE;

/* --- ADD KEY --- */
FOR TABLE XXXX_MYTABLE
INSERT NONUNIQUE (XXXX_CURDATE, XXXX_NAME)
WITH PRIORITY 3;

/* --- DELETE KEY --- */
FOR TABLE XXXX_MYTABLE
DELETE KEY 3;

/* --- ADD COLUMN TO KEY --- */
FOR TABLE XXXX_MYTABLE
KEY 2
INSERT XXXX_NEWCOL
WITH PRIORITY 2;

/* --- DBI for multi-language systems (dictionary references) --- */
/* New table with dictionary references: */
CREATE TABLE PRIV_NEWTABLE '[Ktitle : PRIV_NEWTABLE]' 1
COL1(CHAR, 3, '[Column: PRIV_NEWTABLE/COL1]')
COL2(CHAR, 32, '[Column: PRIV_NEWTABLE/COL2]')
UNIQUE(COL1);

/* New column with dictionary reference: */
FOR TABLE MYTABLE INSERT MYNEWCOL
(INT, 13, '[Column: MYTABLE/MYNEWCOL]');


/*=====================================================================
 * SELECT WITH OUTPUT FORMATS
 * Different output format commands for SELECT statements.
 *=====================================================================*/

/* --- FORMAT: Column headings and data --- */
SELECT PARTNAME, PARTDES FROM PART FORMAT;

/* --- TABS: Tab-separated with column titles --- */
SELECT PARTNAME, PARTDES FROM PART TABS;

/* --- ASCII: Data only, no headings, no spaces --- */
SELECT PARTNAME, PARTDES FROM PART ASCII;

/* --- Output to file --- */
SELECT PARTNAME, PARTDES FROM PART FORMAT 'output.txt';

/* --- Output to file using expression --- */
SELECT * FROM PART WHERE PART > 0
FORMAT STRCAT('/tmp/', 'part.sav');

/* --- UNICODE: UTF-16 output --- */
SELECT PARTNAME, PARTDES FROM PART FORMAT UNICODE 'output.txt';

/* --- ADDTO: Append to existing file --- */
SELECT PARTNAME FROM PART WHERE PART > 0
FORMAT ADDTO 'output.txt';

/* --- TABS without titles --- */
:NOTABSTITLE = 1;
SELECT PARTNAME, PARTDES FROM PART TABS 'output.txt';

/* --- Numbered list using SQL.LINE --- */
SELECT SQL.LINE, PARTNAME FROM PART FORMAT;


/*=====================================================================
 * UPSERT EXAMPLES (v25.1+)
 * Combined UPDATE with fallback INSERT.
 *=====================================================================*/

/* --- Basic UPSERT --- */
UPSERT LASTS
SET NAME = 'FOO',
VALUE = 123
WHERE NAME = 'FOO';
/* If record with NAME='FOO' exists: UPDATE VALUE to 123 */
/* If record doesn't exist: INSERT new record with NAME='FOO', VALUE=123 */

/* --- Equivalent to: --- */
UPDATE LASTS
SET VALUE = 123
WHERE NAME = 'FOO';
GOTO 1 WHERE :RETVAL > 0;
INSERT INTO LASTS(NAME, VALUE)
VALUES('FOO', 123);
LABEL 1;

/* --- IMPORTANT: SET must include all columns for both UPDATE and INSERT --- */
/* The WHERE column must also appear in SET (for the INSERT fallback) */

/* --- Best use case: Semaphore values (LASTS table) --- */
UPSERT LASTS
SET NAME = 'SDK_SEMAPHORE',
VALUE = 1
WHERE NAME = 'SDK_SEMAPHORE';

/* --- Always use the unique key in WHERE clause --- */
/* Problematic (avoid): */
/* UPSERT LASTS SET NAME = 'FOO', VALUE = 123; -- No WHERE! */


/*=====================================================================
 * OFFSET AND FETCH (PAGING RESULTS)
 * Requires ORDER BY. For paging through large result sets.
 *=====================================================================*/

/* --- OFFSET only: Skip first 100 rows --- */
:FR = 100;
SELECT ORD, ORDNAME FROM ORDERS WHERE CURDATE > 01/01/19
ORDER BY 1
OFFSET :FR
FORMAT;

/* --- OFFSET with FETCH: Get 75 rows starting from row 101 --- */
:FR = 100;
:MAX = 75;
SELECT ORD, ORDNAME FROM ORDERS WHERE CURDATE > 01/01/19
ORDER BY 1
OFFSET :FR FETCH NEXT :MAX ROWS ONLY
FORMAT;


/*=====================================================================
 * CONDITIONAL EXPRESSIONS
 * Ternary operator (C-style ? : notation).
 *=====================================================================*/

/* --- Basic ternary expression --- */
( SQL.DATE8 > ORDERITEMS.DUEDATE AND ORDERITEMS.BALANCE > 0 ? '*' : ' ' )
/* Returns '*' if overdue, ' ' otherwise */

/* --- In SELECT statement --- */
SELECT ORDNAME,
(ORDERS.ORDSTATUS > 0 ? 'Active' : 'Inactive')
FROM ORDERS FORMAT;

/* --- In calculated column expression --- */
( :$$.CURRENCY = -1 ? :$.IEXCHANGE : 1.0 )


/*=====================================================================
 * MATHEMATICAL FUNCTIONS
 *=====================================================================*/

SELECT ROUND(1.45) FROM DUMMY FORMAT;      /* 1 (INT result) */
SELECT ROUNDR(1.45) FROM DUMMY FORMAT;     /* 1.000000 (REAL result) */
SELECT EXP(2, 3) FROM DUMMY FORMAT;        /* 8 (INT^INT) */
SELECT POW(3.1, -2.4) FROM DUMMY FORMAT;   /* 0.066181 (REAL^REAL) */
SELECT SQRT(10) FROM DUMMY FORMAT;         /* 3 (INT result) */
SELECT SQRTR(10.0) FROM DUMMY FORMAT;      /* 3.162278 (REAL result) */
SELECT ABS(-5) FROM DUMMY FORMAT;          /* 5 (INT) */
SELECT ABSR(-5.3) FROM DUMMY FORMAT;       /* 5.300000 (REAL) */
SELECT 10 MOD 4 FROM DUMMY FORMAT;         /* 2 */
SELECT MINOP(1.5, 2) FROM DUMMY FORMAT;    /* 1.500000 */
SELECT MAXOP(1.5, 2) FROM DUMMY FORMAT;    /* 2.000000 */

/* --- Shifted integer conversions --- */
SELECT REALQUANT(1000) FROM DUMMY FORMAT;  /* 1.000000 (shifted INT to REAL) */
SELECT INTQUANT(1.0) FROM DUMMY FORMAT;    /* 1000 (REAL to shifted INT) */
/* Decimal shift based on DECIMAL system constant (usually 3) */


/*=====================================================================
 * OUTER JOIN AND EXTENDED LIKE
 *=====================================================================*/

/* --- Outer join (? after table ID) --- */
SELECT * FROM FNCITEMS, FNCITEMSB ?
WHERE FNCITEMSB.FNCTRANS = FNCITEMS.FNCTRANS
AND FNCITEMSB.KLINE = FNCITEMS.KLINE;
/* Outer join preserves unmatched rows (null record retrieved) */

/* --- Extended LIKE patterns --- */
/* Range match: any character A-D followed by anything */
WHERE PARTNAME LIKE '\| A-D \|%'

/* Negated range: NOT in range A-D */
WHERE PARTNAME LIKE '\| \^A-D \|%'

/* Escape special characters */
WHERE PARTNAME LIKE 'A\%'  /* Matches literal 'A%' */

/* IMPORTANT: LIKE expressions must be on a SINGLE LINE */
/* Correct: */
WHERE (PARTNAME LIKE '%' OR PART.PARTDES LIKE '%'
OR EPARTDES LIKE '%')

/* Incorrect (line break in middle of LIKE): */
/* WHERE (PARTNAME LIKE '%' OR PART.PARTDES */
/* LIKE '%') -- THIS WILL FAIL */


/*=====================================================================
 * SEMAPHORE PATTERNS
 * Prevent concurrent execution using LASTS or custom tables.
 *=====================================================================*/

/* --- Basic semaphore with LASTS table --- */
GOTO 1 FROM LASTS WHERE NAME = 'SDK_SEMAPHORE';
INSERT INTO LASTS(NAME) VALUES('SDK_SEMAPHORE');
LABEL 1;
UPDATE LASTS
SET VALUE = 1
WHERE NAME = 'SDK_SEMAPHORE'
AND VALUE = 0;
GOTO 99 WHERE :RETVAL <= 0;  /* Another process holds the lock */
/* ... protected code ... */
UPDATE LASTS
SET VALUE = 0
WHERE NAME = 'SDK_SEMAPHORE';
LABEL 99;

/* --- Time-based semaphore (allow after 24 hours) --- */
/* Requires custom table: SDK_SEMAPHORES (NAME, USER, UDATE) */
GOTO 1 FROM SDK_SEMAPHORES WHERE NAME = 'SDK_SEMAPHORE';
INSERT INTO SDK_SEMAPHORES(NAME) VALUES('SDK_SEMAPHORE');
LABEL 1;
UPDATE SDK_SEMAPHORES
SET UDATE = SQL.DATE, USER = SQL.USER
WHERE NAME = 'SDK_SEMAPHORE'
AND UDATE <= SQL.DATE - 24:00;
GOTO 99 WHERE :RETVAL <= 0;
/* ... protected code ... */
UPDATE SDK_SEMAPHORES
SET UDATE = 0, USER = 0
WHERE NAME = 'SDK_SEMAPHORE';
LABEL 99;


/*=====================================================================
 * USEFUL SYSTEM FUNCTIONS
 *=====================================================================*/

/* --- File and path functions --- */
SELECT SYSPATH('TMP', 1) FROM DUMMY FORMAT;     /* Relative temp path */
SELECT SYSPATH('TMP', 0) FROM DUMMY FORMAT;     /* Absolute temp path */
SELECT SYSPATH('MAIL', 1) FROM DUMMY FORMAT;    /* ../../system/mail */
SELECT SYSPATH('LOAD', 1) FROM DUMMY FORMAT;    /* Relative load path */
SELECT SYSPATH('SYNC', 1) FROM DUMMY FORMAT;    /* Sync folder (cloud) */
SELECT SYSPATH('IMAGE', 1) FROM DUMMY FORMAT;   /* Image folder */
/* Path types: BIN, PREP, LOAD, MAIL, SYS, TMP, SYNC, IMAGE */
/* Output type: 1 = relative, 0 = absolute */

/* --- Create file in system/mail with unique name --- */
:z = NEWATTACH('LOGFILe', '.zip');
/* Returns: ../../system/mail/202202/1t2tymq0/logfile.m */
/* Filename converted to lowercase; handles conflicts */

/* --- Get entity message text --- */
SELECT ENTMESSAGE('ORDERS', 'F', 3) FROM DUMMY FORMAT;
/* Entity types: F=form, R=report, P=procedure */
/* In procedures, use '$' for current entity: */
:MSG = ENTMESSAGE('$', 'P', 3);

/* --- ENV: Change current company --- */
ENV 'company_name';
/* Returns 1 on success, 0 on failure */
/* Web limitation: forms opened from procedure still use original company */

/* --- EXECUTE: Run a program with parameters --- */
EXECUTE BACKGROUND WINFORM 'ORDERS', '', :ORDNAME, '', '2';
/* BACKGROUND runs the program in the background */


/*=====================================================================
 * HARVESTED FORM-SHAPE IDIOMS (2026-04-22)
 * See references/forms.md for prose.
 *=====================================================================*/

-- FCLMNA.EXPR foreign-table lookup. Distilled from: LOGPART + ~40 more forms.
-- Query: FORMCLMNSA.EXPR LIKE '% WHERE % =%' AND NOT LIKE '%SELECT%' AND NOT LIKE '%FROM%'
-- These are LITERAL FCLMNA.EXPR bodies — no SELECT, no FROM, and the column
-- returned is inferred from the parent FCLMN row's CNAME.
-- Store these via WebSDK:
--   startSubForm(FCLMN) → filter(NAME, <col>) → setActiveRow → startSubForm(FCLMNA)
--   → newRow → fieldUpdate(EXPR, '<table> WHERE <fk_col> = :$.<local_col>')
--   → saveRow
--
-- Example bodies (as stored in FCLMNA.EXPR):
--   ACCOUNTS   WHERE ACCOUNT = :$.ACCOUNT
--   COUNTRIES  WHERE COUNTRY = :$.FCOUNTRY
--   TAXES      WHERE TAX     = :$.TAX


-- Shared trigger libraries via #INCLUDE func/<Name>. Distilled from: ~250 forms.
-- Query: FORMTRIGTEXT LIKE '%#INCLUDE func/%'
#INCLUDE func/Language
#INCLUDE func/DecimalPrecision
#INCLUDE func/CheckTax
#INCLUDE func/CheckRestricted
#INCLUDE func/LoadAppCond
