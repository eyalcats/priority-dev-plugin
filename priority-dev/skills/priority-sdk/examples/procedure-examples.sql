/**********************************************************************
 * PRIORITY PROCEDURE EXAMPLES
 * Step queries, user input, PRINT/PRINTERR, flow control,
 * running procedures/reports from code, document generation.
 * Source: Priority SDK Reference Documentation
 **********************************************************************/


/*=====================================================================
 * STEP QUERY EXAMPLES
 * SQL statements in the Step Query form of procedure steps.
 * Executed after parameter input.
 *=====================================================================*/

/* --- Reference parameters using :$.ParameterName --- */
/* $ is wildcard for the current procedure */
SELECT ORDNAME, ORD, ORDSTATUS, BRANCH
INTO :PAR1, :$.ORD, :STAT, :BRANCH
FROM ORDERS
WHERE ORD = ATOI(:HTMLVALUE)
AND ORD <> 0;

/* --- HTMLCURSOR step query (document procedures) --- */
/* First column must be the autounique key */
SELECT ORD, ORDNAME FROM ORDERS WHERE ORD <> 0 ORDER BY 2;

/* --- SQLI step query with linked table manipulation --- */
LINK CUSTOMERS TO :$.CST;
ERRMSG 1 WHERE :RETVAL <= 0;

:CUSTNAME = '';
SELECT CUSTNAME INTO :CUSTNAME
FROM CUSTOMERS
WHERE CUST <> 0;

UNLINK CUSTOMERS;
ERRMSG 2 WHERE :CUSTNAME = '';

/* --- Step query error messages with parameters --- */
/* Messages defined in Procedure Messages form */
/* Support <P1>, <P2>, <P3> and HTML: <P1>{=html} */
:PAR1 = 'SO1212888';
:PAR2 = DTOA(SQL.DATE8, 'MM/DD/YY');
ERRMSG 500 WHERE :RETVAL <= 0;


/*=====================================================================
 * USER INPUT EXAMPLES
 * INPUT, CHOOSE, and linked file parameters.
 *=====================================================================*/

/* --- INPUT step: basic parameter input --- */
/* Parameters defined in Procedure Parameters form:
   Name | Pos | Width | Input | Type    | Column | Table
   CST  | 0   | 0     | I     | LINE    | CUSTNAME | CUSTOMERS
   ORD  | 5   | 0     | I     | LINE    | ORDNAME  | ORDERS
*/
/* I = optional input, M = mandatory input */

/* --- Pre-set value that always appears --- */
/* In Procedure Parameter Extension, set Type = 'd' */
/* Value column: SQL.DATE8 */

/* --- Boolean checkbox input --- */
/* In Procedure Parameter Extension, set Type = 'Y' */

/* --- CHOOSE step: radio button selection --- */
/* Method 1: Parameter list with constant values */
/* First parameter stores result, additional parameters are options */
/* Each option has: unique INT value, title, position */

/* Method 2: CHOOSE query in Step Query */
/* Three CHAR arguments: Arg1 (display), Arg2 (display), Arg3 (value) */
SELECT STATDES, '', ITOA(MYDOCSTAT)
FROM XXXX_MYDOCSTATS
ORDER BY SORT;

/* --- Choose between fixed options from messages --- */
/* Parameter type: INT, Extension Type: C */
/* From Message: 10, To Message: 13 */
/* Messages in Procedure Messages form:
   10: 1, Option A
   11: 2, Option B
   12: 3, Option C
   13: 4, Cancel
*/

/* --- Linked file parameter (FILE type) --- */
/* Retrieves records from a form/table for batch processing */
/* User specifies search pattern or accesses form to select records */
/* Column Name and Table Name must be specified */

/* --- PAR parameter for Actions --- */
/* PAR must be first parameter, first step, FILE type */
/* Receives current form record when procedure runs as Action */
LINK ORDERS TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
:ORDNAME = '';
SELECT ORDNAME INTO :ORDNAME FROM ORDERS WHERE ORD <> 0;
UNLINK ORDERS;
ERRMSG 2 WHERE :ORDNAME = '';

/* --- TEXT parameter: HTML text input --- */
/* Parameter type = TEXT, user enters unlimited lines */
/* Data retrieved from PROCTABLETEXT table */
LINK PROCTABLETEXT TO :$.TXT;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO GENERALLOAD (LINE, RECORDTYPE, TEXT)
SELECT 2 + KLINE, '2', TEXT FROM PROCTABLETEXT WHERE KLINE > 0;
UNLINK PROCTABLETEXT;

/* --- Browse Button for file selection --- */
/* In Procedure Parameter Extension: Browse Button = 'Y' */
/* Opens Windows Explorer for file selection (CHAR parameter) */
/* Browse Button = 'S' allows saving a new file */

/* --- CHOOSE-FIELD trigger for procedure parameter --- */
/* Defined in Field Triggers sub-level of Procedure Parameters */
/* Can reference other params via :PROGPAR.ParameterName */


/*=====================================================================
 * PRINT / PRINTCONT / PRINTERR EXAMPLES
 * Display messages during procedure execution.
 *=====================================================================*/

/* --- PRINT: Display message, procedure continues --- */
/* If the file is empty or does not exist, procedure continues silently */

/* --- Printing a fixed message --- */
/* Parameter: CHAR type, message text in Title column */
/* Example Title: "Processing complete. Click OK to continue." */

/* --- PRINT from a file (step query populates the file) --- */
/* In SQLI step: */
SELECT SQL.TMPFILE INTO :$.MSG FROM DUMMY;
SELECT MESSAGE FROM ERRMSGS
WHERE TYPE = 'i' AND USER = SQL.USER
ASCII :$.MSG;
/* Then PRINT step uses the MSG parameter */

/* --- PRINTCONT: Display message with Continue/Stop options --- */
/* User can choose to continue or halt the procedure */
/* Same file handling as PRINT */

/* --- PRINTERR: Display error and cause procedure failure --- */
/* If file is empty, procedure continues (no error) */
/* Useful for conditional error display */
SELECT SQL.TMPFILE INTO :$.ERR FROM DUMMY;
SELECT 'Error: Order could not be created'
FROM DUMMY
WHERE :ORD = 0
ASCII UNICODE :$.ERR;
/* PRINTERR step uses the ERR parameter */
/* If :ORD <> 0, file is empty, so no error is displayed */

/* --- MESSAGE step: display from Procedure Messages --- */
/* Parameter: INT type, value = message number */
/* Message defined in Procedure Messages form */

/* --- WRNMSG step: message with Cancel option --- */
/* Same as MESSAGE but includes Cancel button */


/*=====================================================================
 * FLOW CONTROL EXAMPLES
 * GOTO, CONTINUE, END for procedure step navigation.
 *=====================================================================*/

/* --- GOTO: Jump to a step --- */
/* Parameter: INT type, Value = step number to jump to */

/* --- GOTO with CHOOSE (user-driven flow) --- */
/* 1. CHOOSE step: user selects option (e.g., value = 60) */
/* 2. GOTO step: uses same parameter (value left blank, INT type) */
/* 3. Procedure jumps to step matching chosen value */
/* 4. Execution continues until END */

/* --- CONTINUE: OK/Cancel dialog --- */
/* No parameters needed */
/* Useful before heavy data manipulation */

/* --- END: Stop procedure execution --- */
/* Used with GOTO to create conditional branches */

/* --- Combined CHOOSE + GOTO + END pattern --- */
/* Step 10: CHOOSE - "Select action" */
/*   Option 1: "Create Order" (value 30) */
/*   Option 2: "Create Invoice" (value 50) */
/*   Option 3: "Cancel" (value 90) */
/* Step 20: GOTO (uses CHOOSE result) */
/* Step 30: SQLI - Create Order logic */
/* Step 40: END */
/* Step 50: SQLI - Create Invoice logic */
/* Step 60: END */
/* Step 90: END (cancel) */


/*=====================================================================
 * RUNNING PROCEDURES FROM CODE
 * WINACTIV, ACTIVATE, ACTIVATF commands.
 *=====================================================================*/

/* --- ACTIVATF: Run procedure in same process (no UI) --- */
/* Best for server-side execution (web interface) */
GOTO 10099 WHERE :$.CPROFSTAT <> :SPECIALSTATUS;
SELECT SQL.TMPFILE INTO :FILE FROM DUMMY;
LINK CPROF TO :FILE;
GOTO 10099 WHERE :RETVAL <= 0;
INSERT INTO CPROF
SELECT * FROM CPROF O WHERE PROF = :$.PROF;
UNLINK CPROF;
EXECUTE ACTIVATF '-P', 'OPENORDBYCPROF', 'CPROF', :FILE;
LABEL 10099;

/* --- ACTIVATF with linked table (simulates form Action) --- */
/* The linked table goes to the PAR variable of the procedure */
SELECT SQL.TMPFILE INTO :FILE FROM DUMMY;
LINK ORDERS TO :FILE;
GOTO 10099 WHERE :RETVAL <= 0;
INSERT INTO ORDERS
SELECT * FROM ORDERS O WHERE ORD = :$.ORD;
UNLINK ORDERS;
EXECUTE ACTIVATF '-P', 'OPENINVFORORDER', 'ORDERS', :FILE;
LABEL 10099;

/* --- ACTIVATF with external variables --- */
/* All variables received as CHAR type */
EXECUTE ACTIVATF '-P', 'DEMO_MYPROC', '-var:MODE', 'UPDATE', '-var:QUANT', '500';
/* In the called procedure, access with EXTERNAL prefix: */
:DEMO_QUANT = ATOI(:EXTERNAL.QUANT);
GOSUB 100 WHERE :EXTERNAL.MODE = 'UPDATE';

/* --- WINACTIV: Run procedure with UI (Windows only) --- */
/* Has progress bar and messages */
/* NOT for web interface */
EXECUTE WINACTIV '-P', 'BACKFLUSH_ONNEW';


/*=====================================================================
 * RUNNING REPORTS FROM CODE
 * WINACTIV with -R flag (Windows only).
 *=====================================================================*/

/* --- Run a report with linked table --- */
:F = '../../output.txt';
SELECT SQL.TMPFILE INTO :CST FROM DUMMY;
LINK CUSTOMERS TO :CST;
GOTO 299 WHERE :RETVAL <= 0;
INSERT INTO CUSTOMERS
SELECT * FROM CUSTOMERS O
WHERE CUSTNAME = '250';
UNLINK CUSTOMERS;
EXECUTE WINACTIV '-R', 'OPENORDIBYDOER', 'CUSTOMERS', :CST;
LABEL 299;

/* --- Run report and send by email --- */
SELECT SQL.TMPFILE INTO :TMP FROM DUMMY;
LINK ERRMSGS TO :TMP;
GOTO 99 WHERE :RETVAL <= 0;
INSERT INTO ERRMSGS
SELECT * FROM ERRMSGS O
WHERE USER = SQL.USER AND TYPE = 'i';
GOTO 90 WHERE :RETVAL <= 0;

/* Send to a Priority mail recipient */
:MAILER = SQL.USER;
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-u', :MAILER;

/* Send to a Priority group */
:GROUPNAME = 'mailGroup';
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-g', :GROUPNAME;

/* Send to an external recipient */
:EMAIL = 'example@example.com';
EXECUTE WINACTIV '-R', 'INTERFACEERR', 'ERRMSGS', :TMP, '-e', :EMAIL;

LABEL 90;
UNLINK ERRMSGS;
LABEL 99;

/* --- Redirect report to tab-delimited file --- */
:F = '../../output.txt';
SELECT SQL.TMPFILE INTO :CST FROM DUMMY;
LINK CUSTOMERS TO :CST;
GOTO 299 WHERE :RETVAL <= 0;
INSERT INTO CUSTOMERS
SELECT * FROM CUSTOMERS O WHERE CUSTNAME = '250';
UNLINK CUSTOMERS;
EXECUTE ACTIVATF '-x', :F, '-R', 'OPENORDIBYDOER', 'CUSTOMERS', :CST;
LABEL 299;
MAILMSG 5 TO EMAIL 'demo@demo.com' DATA :F;

/* --- Redirect report to Excel --- */
EXECUTE WINACTIV '-P', 'ORGUNITS', '-X', '..\temp\cur';
/* Provide Excel filename without a suffix */


/*=====================================================================
 * DOCUMENT GENERATION (WINHTML) EXAMPLES
 * Generate documents as HTML, PDF, Word, or for printing.
 *=====================================================================*/

/* --- Output as HTML System Document (-o) --- */
/* Single document */
:ORD = 100;
:HTMLFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.html');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-o', :HTMLFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS, '-o',
STRCAT(SYSPATH('TMP', 1), 'O.html');

/* --- Output as PDF Based on System Document (-pdf) --- */
/* Single document */
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-pdf', :PDFFILE;

/* Multiple documents */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS,
'-pdf', STRCAT(SYSPATH('TMP', 1), 'O.pdf');

/* --- Output as Word File (-wo) --- */
:ORD = 100;
:WORDFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.docx');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-wo', :WORDFILE;

/* --- Output as PDF Based on Word Template (-wpdf) --- */
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-wpdf', :PDFFILE;

/* --- HTML with specific print format --- */
:ORD = 100;
:HTMLFORMAT = -1;
:HTMLFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.html');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-format', :HTMLFORMAT, '-o', :HTMLFILE;

/* --- Word with specific print format --- */
:ORD = 100;
:WORDFORMAT = -3;
:WORDFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.docx');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-format', :WORDFORMAT, '-wo', :WORDFILE;

/* --- Quick Mode: Print to default printer --- */
:ORD = 100;
EXECUTE WINHTML '-dQ', 'WWWSHOWORDER', :ORD;
/* Quick mode: default printer, single copy, silent */
/* Only mode that supports printing via browser */

/* --- Digitally Signed PDF --- */
:ORD = 100;
:PDFFILE = STRCAT(SYSPATH('TMP', 1), 'SOMEFILENAME.pdf');
EXECUTE WINHTML '-d', 'WWWSHOWORDER', '', '', '-v', :ORD, '-s',
'-signpdf', '-pdf', :PDFFILE;

/* --- E-Document (Digitally Signed) --- */
EXECUTE WINHTML '-d', 'WWWSHOWCIV', '', '', '-v', :IV, '-s',
'-edoc', '-pdf', :FILE2;

/* --- E-Document with auto-mail to customer --- */
EXECUTE WINHTML '-d', 'WWWSHOWCIV', '', '', '-v', :IV, '-g',
'-edoc', '-AMAIL', '-s';
/* When using -AMAIL, do not specify path/filename */

/* --- Setting print format via PRINTFORMAT table --- */
:EXEC = 0;
SELECT EXEC INTO :EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER';
:PRINTFORMAT = -5;
UPDATE PRINTFORMAT SET VALUE = :PRINTFORMAT
WHERE EXEC = :EXEC AND USER = SQL.USER;

/* For Word templates, multiply by -1 */
:WORDFORMAT = -3;
UPDATE PRINTFORMAT SET VALUE = (:WORDFORMAT * -1)
WHERE EXEC = :EXEC AND USER = SQL.USER;

/* --- Determine available print formats --- */
/* System document print formats */
SELECT * FROM EXTMSG WHERE EXEC = (
SELECT EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER')
AND NUM < 0 FORMAT;

/* Word templates */
SELECT * FROM TRIGMSG WHERE EXEC = (
SELECT EXEC FROM EXEC WHERE TYPE = 'P'
AND ENAME = 'WWWSHOWORDER') FORMAT;

/* --- Display document in browser (v22.0+) --- */
/* Combine WINHTML with a URL step */
:DOC = 100;
:FILENAME = 'document.pdf';
:PATH = '';
SELECT NEWATTACH(:FILENAME) INTO :PATH FROM DUMMY;
EXECUTE WINHTML '-d', 'WWWSHOWORD', '', '', '-v', :DOC, '-pdf',
:PATH;
SELECT SQL.TMPFILE INTO :$.ADD FROM DUMMY;
SELECT :PATH FROM DUMMY
ASCII :$.ADD;
/* Then add a URL step with the ADD parameter */

/* --- Saving a certified copy when printing --- */
/* Include HTMLEXTFILES step for attached files */
/* In first INPUT step: */
:HTMLPRINTORIG = 1;
/* In SQLI step after HTMLCURSOR: */
:SAVECOPY = 1;


/*=====================================================================
 * PROCESSED REPORT EXAMPLES
 * Reports embedded in procedures with data manipulation.
 *=====================================================================*/

/* --- Change report title at runtime --- */
/* In SQLI step preceding the report: */
:HTMLFNCTITLE = 'New Title';

/* --- Define dynamic column titles --- */
:COLTITLES = 1;
SELECT ENTMESSAGE('$', 'P', 10)
INTO :title1 FROM DUMMY;
:REPCOLTITLE.30 = :title1;
/* 30 = column number in the report */

/* --- Define dynamic report conditions --- */
/* Add REPCONDITION as FILE type local variable */
SELECT SQL.TMPFILE INTO :REPCONDITION FROM DUMMY;
/* Write conditions to the file in ASCII format */


/*=====================================================================
 * OPEN FORM RECORD FROM PROCEDURE
 * Create a record via interface and open the form.
 *=====================================================================*/

/* --- Example: Open Customer Shipment from Sales Orders --- */
LINK ORDERS TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
:ORDNAME = '';
SELECT ORDNAME INTO :ORDNAME FROM ORDERS WHERE ORD <> 0;
UNLINK ORDERS;
ERRMSG 2 WHERE :ORDNAME = '';

LINK GENERALLOAD TO :$.GEN;
ERRMSG 1 WHERE :RETVAL <= 0;
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT1) VALUES(1, '1', :ORDNAME);
EXECUTE INTERFACE 'YUVV_OPENDOC_D', SQL.TMPFILE, '-L', :$.GEN;

:DOCNO = '';
SELECT DOCNO INTO :DOCNO FROM DOCUMENTS
WHERE TYPE = 'D'
AND DOC = (SELECT ATOI(KEY1) FROM GENERALLOAD
WHERE LINE = 1 AND LOADED = 'Y');
UNLINK GENERALLOAD;
ERRMSG 3 WHERE :DOCNO = '';
:$.DNO = :DOCNO;

GOTO 9 WHERE :SQL.NET = 1;
/* Windows client: open form directly */
EXECUTE WINFORM 'DOCUMENTS_D', '', :DOCNO, '', '2';
LABEL 9;
/* Web interface: add DOCUMENTS_D as form step (Type F) in procedure */


/*=====================================================================
 * LOGGING EXAMPLES
 * JOURNALP for structured logging to system logs.
 *=====================================================================*/

/* --- Log a warning message --- */
:MSG = 'Statement failed to execute. Please help.';
:SEV = 4;  /* JOURNAL_WARNING */
/* Severity levels: 1=DEBUG, 2=TRACE, 3=INFO, 4=WARNING, 5=ERROR, 6=FATAL */
EXECUTE JOURNALP :SEV, :MSG;


/*=====================================================================
 * REAL-WORLD PATTERNS FROM SERVICE CALLS
 * Patterns discovered from Priority SDK service call analysis.
 *=====================================================================*/

/* --- Full WINHTML call with all parameters (Ref: SCI24072650) --- */
/* Generate PDF from Word template with format, language, and silent mode */
EXECUTE WINHTML '-d', 'ISOT_SHOWORDER', '', '', '-v', :TTS_ORD,
  '-format', :TTS_VALUE,
  '-lang', :TTS_LANG,
  '-wpdf', :TTS_TMPOUT,
  '-s';
/* -d       = direct mode
   '' ''    = empty table/linked file (single record with -v)
   -v       = single record mode (skips HTMLCURSOR)
   -format  = print format number
   -lang    = language (1=Hebrew, 3=English)
   -wpdf    = output as PDF from Word template
   -s       = silent (no notification window) */

/* --- WINHTML with HTML output for Cloud (Ref: SCI24081025) --- */
EXECUTE WINHTML '-d', 'WWWSHOWORDER', 'ORDERS', :TMPORDERS,
  '-o', '../../TMP/O.html';

/* --- SENDMAIL for automated report email via TTS (Ref: SCI25089305) --- */
/* Send report by email: report_number + offset, tmpfile, format */
EXECUTE SENDMAIL 0 + 10875, SQL.TMPFILE, 4;
/* First param: 0 + report_exec_number (from EXEC table)
   Second param: temp file for errors/messages
   Third param: format (4 = PDF) */

/* --- ACTIVATE for web-compatible procedure execution (Ref: SCI24062508) --- */
/* Replace WINACTIV with ACTIVATE for Web interface compatibility */
EXECUTE ACTIVATE '-P', 'MY_PROC';
/* ACTIVATE has no UI (no progress bar), runs in a new process */

/* --- ACTIVATEF with procedure chaining (Ref: SCI25093656) --- */
/* Run a procedure from within another procedure (same process) */
EXECUTE ACTIVATF '-P', 'FOLLOWUP_PROC', 'INVOICES', :FILE;
/* ACTIVATF runs in same process (.dll), shares memory context */

/* --- Run report from SQLI with output to file (Ref: SCI25093263) --- */
EXECUTE ACTIVATE '-R', 'LIL_STACK_ERR', 'STACK_ERR', :$.ERR;

/* --- WINAPP for Web (executable in bin.95) (Ref: SCI25081221) --- */
/* In Web: leave path empty to default to server's bin.95 folder */
EXECUTE WINAPP '', '-w', 'CheckApp.exe';
/* -w = wait for program to complete before returning */

/* --- WINAPP with multiple parameters (Ref: SCI25011107) --- */
EXECUTE WINAPP '', '-w', '-n', 'lmailto', :P154;
/* -n = no window (run hidden) */

/* --- LABELS command for printing (Ref: SCI2397296) --- */
EXECUTE LABELS;
/* Used in label/sticker printing procedures */

/* --- SCHEMA commands for table maintenance (Ref: SCI24102279) --- */
EXECUTE SCHEMA '-linkall';
/* Rebuilds all table links. Run after DBI changes. */
EXECUTE SCHEMA '-linkdelete';
/* Removes orphaned links */
