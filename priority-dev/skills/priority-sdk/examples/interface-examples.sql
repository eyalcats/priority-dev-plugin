/**********************************************************************
 * PRIORITY INTERFACE & LOADING EXAMPLES
 * GENERALLOAD, EXECUTE INTERFACE, dynamic interfaces,
 * DBLOAD, XML/JSON load, document duplication.
 * Source: Priority SDK Reference Documentation
 **********************************************************************/


/*=====================================================================
 * GENERALLOAD TABLE POPULATION
 * Populate the linked GENERALLOAD table before running INTERFACE.
 *=====================================================================*/

/* --- Step 1: Create a linked, empty copy of GENERALLOAD --- */
SELECT SQL.TMPFILE INTO :DEMO_GEN FROM DUMMY;
LINK GENERALLOAD TO :DEMO_GEN;
GENMSG 1 WHERE :RETVAL <= 0;

/* --- Step 2: Insert parent record (Record Type 1 = Sales Orders) --- */
/* Only customer code is needed; mapped to TEXT2 in the interface */
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT2)
SELECT 1, '1', CUSTOMERS.CUSTNAME
FROM CUSTOMERS
WHERE CUSTDES = 'Demo Customer';

/* --- Step 3: Insert child records (Record Type 2 = Order Items) --- */
/* 4 mandatory fields: PARTNAME, TQUANT, PRICE, DUEDATE */
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, TEXT2,
INT1, REAL1, DATE1)
SELECT SQL.LINE + 1, '2', PART.PARTNAME,
INTQUANT(1.0), PART.LASTPRICE, SQL.DATE + (24:00 * 10)
FROM PART
WHERE PARTNAME LIKE 'DEMO%';
/* TQUANT is a shifted integer: use INTQUANT(real_number)
   to convert based on system decimal precision.
   SQL.LINE auto-increments LINE values for multiple rows. */

/* --- Resulting GENERALLOAD table:
   LINE | RECORDTYPE | TEXT2      | INT1 | REAL1 | DATE1
   1    | '1'        | 'DEMOCUST' |      |       |
   2    | '2'        | 'DEMO01'   | 1000 | 25.00 | 03/15/23
   3    | '2'        | 'DEMO02'   | 1000 | 35.00 | 03/15/23
*/

/* --- Step 4: Execute the interface --- */
EXECUTE INTERFACE 'DEMO_NEWORDER',
SQL.TMPFILE, '-L', :DEMO_GEN;

/* --- Step 5: Check results --- */
/* LOADED = 'Y' for successfully loaded lines */
/* KEY1 filled with autounique key of created record */
SELECT ORDERS.ORDNAME FROM ORDERS, GENERALLOAD
WHERE ORDERS.ORD = ATOI(GENERALLOAD.KEY1)
AND GENERALLOAD.RECORDTYPE = '1'
AND GENERALLOAD.LOADED = 'Y';

/* --- Step 6: Clean up --- */
UNLINK GENERALLOAD;


/*=====================================================================
 * EXECUTE INTERFACE EXAMPLES (ALL VARIATIONS)
 * Different ways to call EXECUTE INTERFACE.
 *=====================================================================*/

/* --- Basic: Execute from file defined in Form Load Designer --- */
EXECUTE INTERFACE 'interface', '';

/* --- Execute from file specified in code --- */
/* Run on a file imported in a procedure step to parameter FIL */
EXECUTE INTERFACE 'interface', '-i', :$.FIL, '';

/* --- Execute from linked load table --- */
SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
LINK GENERALLOAD ORD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO GENERALLOAD ORD(LINE, RECORDTYPE, TEXT2)
SELECT SQL.LINE, '1', CPROFNUM
FROM CPROF
WHERE PDATE = SQL.DATE8;

EXECUTE INTERFACE 'OPENORDBYCPROF', '', '-L', :G1;

LABEL 99;
UNLINK GENERALLOAD ORD;

/* --- Execute with all common flags --- */
EXECUTE INTERFACE 'MYINTERFACE', SQL.TMPFILE,
'-L', :DEMO_GEN,      /* Use linked load table */
'-w',                   /* Ignore warnings */
'-noskip',              /* Continue loading after errors */
'-ns',                  /* No progress bar */
'-nv',                  /* Hide column names in errors */
'-enforcebpm',          /* Apply BPM rules */
'-debug', :DEBUGFILE;   /* Debug output */

/* --- Execute with -stackerr for better error handling --- */
SELECT SQL.TMPFILE INTO :S1 FROM DUMMY;
EXECUTE INTERFACE 'OPENORDBYCPROF', SQL.TMPFILE,
'-L', :G1, '-stackerr', :S1;

/* --- Reload failed records (-repeat) --- */
EXECUTE INTERFACE 'DEMO_NEWORDER',
SQL.TMPFILE, '-L', :DEMO_GEN, '-repeat';
/* Only processes records where LOADED <> 'Y' */


/*=====================================================================
 * ERROR HANDLING PATTERNS
 * ERRMSGS table, STACK_ERR, and error display.
 *=====================================================================*/

/* --- Method 1: Display errors via ASCII parameter --- */
SELECT MESSAGE FROM ERRMSGS
WHERE TYPE = 'i' AND USER = SQL.USER
ASCII :$.MSG;
/* Then pass MSG to a PRINT procedure step */

/* --- Method 2: Get single error message --- */
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE TYPE = 'i' AND USER = SQL.USER AND LINE = 1;
/* Then use ERRMSG to display */

/* --- Method 3: STACK_ERR for multiple interfaces --- */
SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :G2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :S1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :S2 FROM DUMMY;

LINK GENERALLOAD ORD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;
LINK GENERALLOAD DOC TO :G2;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO GENERALLOAD ORD(LINE, RECORDTYPE, TEXT2)
SELECT SQL.LINE, '1', CPROFNUM
FROM CPROF
WHERE PDATE = SQL.DATE8;

EXECUTE INTERFACE 'OPENORDBYCPROF', SQL.TMPFILE,
'-L', :G1, '-stackerr', :S1;

INSERT INTO GENERALLOAD DOC(LINE, RECORDTYPE, TEXT1)
SELECT SQL.LINE, '1', ORDNAME
FROM ORDERS, GENERALLOAD ORD
WHERE ORD.LOADED = 'Y'
AND ORDERS.ORD = ATOI(ORD.KEY1);

UNLINK GENERALLOAD ORD;

EXECUTE INTERFACE 'OPENDOC', SQL.TMPFILE,
'-L', :G2, '-stackerr', :S2;

UNLINK GENERALLOAD DOC;

/* Read errors from first interface */
LINK STACK_ERR S1 TO :S1;
GOTO 99 WHERE :RETVAL <= 0;
SELECT * FROM STACK_ERR S1 FORMAT;
UNLINK STACK_ERR S1;

/* Read errors from second interface */
LINK STACK_ERR S2 TO :S2;
GOTO 99 WHERE :RETVAL <= 0;
SELECT * FROM STACK_ERR S2 FORMAT;
UNLINK STACK_ERR S2;

LABEL 99;

/* --- Quick error check during development (WINDBI) --- */
SELECT * FROM ERRMSGS WHERE USER = SQL.USER AND TYPE = 'i' FORMAT;


/*=====================================================================
 * EXPORT DATA TO LOAD TABLE
 * Export form data to a GENERALLOAD linked table.
 *=====================================================================*/

SELECT SQL.TMPFILE INTO :G1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :O1 FROM DUMMY;

LINK ORDERS TO :O1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG
WHERE CURDATE = '03/22/23';

/* -o = export, -l = export to linked load table */
EXECUTE INTERFACE 'DUMPORD', '', '-o', '-L', :O1,
'-l', 'GENERALLOAD', :G1;

LINK GENERALLOAD TO :G1;
GOTO 99 WHERE :RETVAL <= 0;
/* GENERALLOAD now contains exported data */

LABEL 99;
UNLINK ORDERS;
UNLINK GENERALLOAD;


/*=====================================================================
 * EXPORT DATA TO XML FILE
 * Export form data to an XML file with UTF-8 encoding.
 *=====================================================================*/

SELECT SQL.TMPFILE INTO :O1 FROM DUMMY;
:OUTFILE = STRCAT(SYSPATH('TMP', 0), 'Orders.xml');

LINK ORDERS TO :O1;
GOTO 99 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG
WHERE CURDATE = '03/22/23';

/* -ou8 = UTF-8 encoding, -f = output file */
EXECUTE INTERFACE 'DUMPORDXML', '', '-ou8',
'-L', :O1, '-f', :OUTFILE;

LABEL 99;
UNLINK ORDERS;


/*=====================================================================
 * DYNAMIC INTERFACE EXAMPLES (v21.0+)
 * Create interfaces from code without predefining in the generator.
 * Uses -form flag. File structure in XML/JSON determines load order.
 *=====================================================================*/

/* --- Dynamic Export to JSON --- */
SELECT SQL.TMPFILE INTO :TMPFILE FROM DUMMY;
LINK ORDERS TO :TMPFILE;
GOTO 1 WHERE :RETVAL <= 0;

INSERT INTO ORDERS
SELECT * FROM ORDERS ORIG WHERE ORDNAME IN ('SO2000001364','SO2000001365');

EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form',                                     /* Dynamic interface */
'-select', 'ORDNAME', 'CUSTNAME',            /* Select specific fields */
'-ou',                                        /* Unicode output */
'-L', :TMPFILE,                               /* Linked table */
'-f', STRCAT(SYSPATH('TMP', 1), 'O2.txt'),   /* Output file */
'-J',                                         /* JSON format */
'-expand', 'ORDERITEMS',                      /* Include sub-level */
'-select', 'PRICE', 'PARTNAME',              /* Sub-level fields */
'-expand', 'ORDERITEMSTEXT';                  /* Another sub-level */

UNLINK ORDERS;
LABEL 1;

/* --- Dynamic Export ALL fields as XML --- */
/* If -select is omitted, all form fields are exported */
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-ou', '-L', :TMPFILE,
'-f', STRCAT(SYSPATH('TMP', 1), 'testxml.xml'),
'-expand', 'ORDERITEMS';

/* --- Dynamic Import from XML file --- */
/* XML file must follow Priority hierarchy: form > sub-level */
/*
   <?xml version="1.0" encoding="utf-8"?>
   <FORM>
       <ORDERS>
           <CUSTNAME>84841</CUSTNAME>
           <ORDERITEMS>
               <PARTNAME>000</PARTNAME>
               <DUEDATE>07/11/20</DUEDATE>
           </ORDERITEMS>
       </ORDERS>
   </FORM>
*/
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-i', '-f', STRCAT(SYSPATH('TMP', 1), 'in1.txt'),
'-ignorewrn', '-noskip';

/* --- Dynamic Import from JSON file --- */
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-J', '-i', '-f', STRCAT(SYSPATH('TMP', 1), 'in1.json'),
'-ignorewrn', '-noskip';

/* --- Dynamic Delete --- */
/* JSON file specifies keys of records to delete:
   {
       "ORDERS": [
           {
               "ORDNAME": "SO0000001",
               "ORDERITEMS": [
                   { "KLINE": 1 },
                   { "KLINE": 3 }
               ]
           }
       ]
   }
*/
EXECUTE INTERFACE 'ORDERS', STRCAT(SYSPATH('TMP', 1), 'msg.txt'),
'-form', '-J', '-delete',
'-i', '-f', STRCAT(SYSPATH('TMP', 1), 'delete.json');


/*=====================================================================
 * DELETING RECORDS VIA INTERFACE
 * Same interface definition, but record type prefixed with @.
 *=====================================================================*/

/* Record type '@2' deletes records of type 2 */
INSERT INTO GENERALLOAD(LINE, RECORDTYPE, INT1)
VALUES(1, '@2', :ORDI);
/* Important: Do NOT flag "Replace Form Data" when using delete */


/*=====================================================================
 * DBLOAD EXAMPLES
 * Import data from tab-delimited files into interim tables.
 *=====================================================================*/

/* --- Basic DBLOAD from file defined in Characteristics for Download --- */
EXECUTE DBLOAD '-L', 'loadname';

/* --- DBLOAD with specific input file --- */
EXECUTE DBLOAD '-L', 'loadname', '-i', :FILEPATH;

/* --- DBLOAD to a linked table copy --- */
EXECUTE DBLOAD '-L', 'loadname', '-T', 'TABLENAME', :LINKFILE;

/* --- DBLOAD with debug output --- */
EXECUTE DBLOAD '-L', 'loadname', '-g', '../../tmp/dbg.txt';

/* --- DBLOAD with error handling options --- */
EXECUTE DBLOAD '-L', 'loadname',
'-i', :FILEPATH,          /* Input file */
'-N',                      /* Append to ERRMSGS (don't clear) */
'-E', '../../unloaded.txt', /* Save failed lines */
'-u',                      /* Record user in ERRMSGS */
'-v',                      /* Validate input types */
'-C',                      /* Remove commas from numbers */
SQL.TMPFILE;               /* Message file */

/* --- Convert Excel to tab-delimited, then DBLOAD --- */
EXECUTE WINAPP 'p:\bin.95', '-w', 'EXL2TXT.exe', :EXCELFILE, :TSVFILE;
EXECUTE DBLOAD '-L', 'loadname', '-i', :TSVFILE;

/* --- Browse folder and DBLOAD each file (FILELIST pattern) --- */
:DIR = STRCAT(SYSPATH('SYNC', 1), 'tmpDir');
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
EXECUTE FILELIST :DIR, :ST6, :MSG;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
DECLARE NEWFILES CURSOR FOR
SELECT TOLOWER(NAME)
FROM STACK6
WHERE TOLOWER(NAME) LIKE 'loadorder*';
OPEN NEWFILES;
GOTO 90 WHERE :RETVAL <= 0;
:FILENAME = '';
LABEL 10;
FETCH NEWFILES INTO :FILENAME;
GOTO 85 WHERE :RETVAL <= 0;
:PATH = STRCAT(:DIR, '/', :FILENAME);
EXECUTE DBLOAD '-L', 'Example.load', '-i', :PATH;
LOOP 10;
LABEL 85;
CLOSE NEWFILES;
LABEL 90;
UNLINK STACK6;
LABEL 99;


/*=====================================================================
 * DOCUMENT DUPLICATION EXAMPLE
 * Copy a Sales Order for another customer using export/import pattern.
 *=====================================================================*/

/* --- Step 1: Get customer and order from input --- */
LINK CUSTOMERS TO :$.CST;
ERRMSG 1 WHERE :RETVAL <= 0;

:CUSTNAME = '';
SELECT CUSTNAME INTO :CUSTNAME
FROM CUSTOMERS
WHERE CUST <> 0;

UNLINK CUSTOMERS;
ERRMSG 2 WHERE :CUSTNAME = '';

/* --- Step 2: Export the source order to GENERALLOAD --- */
EXECUTE INTERFACE 'TEST_OPENSALESORD', SQL.TMPFILE,
'-o', '-L', :$.ORD, '-l', 'GENERALLOAD', :$.GEN;

/* --- Step 3: Modify data (replace customer) --- */
LINK GENERALLOAD TO :$.GEN;
ERRMSG 1 WHERE :RETVAL <= 0;

UPDATE GENERALLOAD
SET TEXT1 = :CUSTNAME
WHERE LINE = 1;

UNLINK GENERALLOAD;

/* --- Step 4: Import modified data as new order --- */
EXECUTE INTERFACE 'TEST_OPENSALESORD', :$.MSG, '-L', :$.GEN;

/* --- Step 5: Retrieve the new order key --- */
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

/* --- Step 6: Open the new order form --- */
/* Windows client */
EXECUTE BACKGROUND WINFORM 'ORDERS', '', :ORDNAME, '', '2';
/* Web interface: add ORDERS as form step (Type F) in procedure */


/*=====================================================================
 * PRIORITY LITE / WEB INPUT PATTERN
 * Load data via interface from an HTML input procedure.
 *=====================================================================*/

LINK GENERALLOAD TO :$.LNK;
INSERT INTO GENERALLOAD (LINE, RECORDTYPE, ...) VALUES (...);
EXECUTE INTERFACE 'MYINTERFACE', SQL.TMPFILE, '-L', :$.LNK;
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE USER = ATOI(RSTRIND(SQL.CLIENTID, 1, 9))
AND TYPE = 'i' AND LINE = 1;
ERRMSG 1 WHERE EXISTS (SELECT 'X' FROM GENERALLOAD
WHERE LOADED <> 'Y' AND LINE > 0);
UNLINK GENERALLOAD;


/*=====================================================================
 * FINANCIAL DOCUMENTS FOLLOW-UP PROCEDURE
 * Runs after invoice finalization via IVTYPES.CONTENAME.
 *=====================================================================*/

LINK INVOICES TO :$.PAR;
ERRMSG 1 WHERE :RETVAL <= 0;
SELECT IV, IVNUM, TYPE, DEBIT FROM INVOICES FORMAT '../../iv.txt';
SELECT IV, IVNUM, TYPE, DEBIT FROM INVOICES ORIG
WHERE IV = (SELECT IV FROM INVOICES) FORMAT ADDTO '../../iv.txt';
UNLINK INVOICES;


/*=====================================================================
 * REAL-WORLD PATTERNS FROM SERVICE CALLS
 * Patterns discovered from Priority SDK service call analysis.
 *=====================================================================*/

/* --- Interface export with sub-level expansion (Ref: SCI24080696) --- */
/* Export form data including sub-levels to XML/file */
EXECUTE INTERFACE 'DOCUMENTS_p', :$.MSG,
  '-form',                   /* Form-based export mode */
  '-ou',                     /* Output (export) mode */
  '-L', :$.PRJ,              /* Linked table file */
  '-f', :$.FIL,              /* Output file path */
  '-expand', 'PROJACTS',     /* Include PROJACTS sub-level */
  '-expand', 'PROJACTSTEXT'; /* Include PROJACTSTEXT sub-level */
/* -expand can be specified multiple times for multiple sub-levels */

/* --- Interface with UTF-8 output encoding (Ref: service calls) --- */
EXECUTE INTERFACE 'MY_INTERFACE', SQL.TMPFILE,
  'ou8',                     /* Output in UTF-8 encoding */
  '-f', :OUTFILE;

/* --- Populating extension tables after upgrade (Ref: SCI25077950) --- */
/* When a new sub-table is added, populate it from existing data */
INSERT INTO ORDERITEMSB(ORDI)
SELECT ORDI FROM ORDERITEMS;
/* Run this after adding a new extension table to ensure all existing
   records have corresponding rows in the extension table */
