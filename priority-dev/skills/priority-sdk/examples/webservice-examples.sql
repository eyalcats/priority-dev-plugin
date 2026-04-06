/**********************************************************************
 * PRIORITY WEB SERVICE & INTEGRATION EXAMPLES
 * WSCLIENT, XMLPARSE, JSONPARSE, SFTPCLNT, FILTER,
 * WINAPP/WINRUN, Base64 conversion.
 * Source: Priority SDK Reference Documentation
 **********************************************************************/


/*=====================================================================
 * WSCLIENT EXAMPLES (REST/SOAP CALLS)
 * Execute HTTP requests to external web services.
 *=====================================================================*/

/* --- Basic POST request --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE;
/* :ENDPOINT_URL = URL of the web service (max 127 chars) */
/* :INFILE = file sent as request body (Unicode) */
/* :OUTFILE = file where response is stored */

/* --- GET request with JSON content type --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-method', 'GET',
'-content', 'application/json';

/* --- POST with custom header --- */
:HEADER = 'Authorization: Bearer mytoken123';
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-head2', :HEADER,
'-content', 'application/json';

/* --- POST with multiple headers --- */
:H1 = 'Authorization: Bearer mytoken123';
:H2 = 'X-Custom-Header: myvalue';
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-head2', :H1,
'-head2', :H2,
'-content', 'application/json';

/* --- POST with header file --- */
/* Header file must have each header on a separate line ending with newline */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-head', :HEADERFILE,
'-content', 'application/json';

/* --- With authentication (username/password) --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-usr', :WSUSER, '-pwd', :WSUSERPWD;

/* --- With domain authentication --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-usr', :WSUSER, '-pwd', :WSUSERPWD, '-domain', :USERDOMAIN;

/* --- With client-side TLS certificate --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-tlscert', :CERTDATA, :PEMPASSWORD;

/* --- With timeout (milliseconds) --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-timeout', '30000',
'-content', 'application/json';

/* --- Extract specific XML tag from response --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-tag', 'ResponseCode';
/* -tag = full tag with XML markers */
/* -val = tag contents only */

/* --- SOAP request with action --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-action', :SOAPACTION,
'-content', 'text/xml; charset=utf-8';

/* --- Capture response headers --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-headout', :HEADERSFILE,
'-content', 'application/json';

/* --- Error messages file --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-msg', :MSGFILE,
'-content', 'application/json';
/* Errors also written to ERRMSGS with type 'w' under SQL.USER */


/*=====================================================================
 * BUILDING JSON REQUEST BODIES FOR WSCLIENT
 * Correct patterns for constructing JSON files to send via WSCLIENT.
 *=====================================================================*/

/* --- Pattern 1: Simple JSON body using NEWATTACH (preferred) --- */
/* NEWATTACH creates unique temp files, auto-cleaned by the system.
   Prefer NEWATTACH over manual STRCAT('../../system/tmp/', ...) paths. */
:BODYFILE = NEWATTACH('body.txt');
:RESPONSE = NEWATTACH('resp.txt');
:WSMSG = NEWATTACH('wsmsg.txt');
:STR1 = STRCAT('{"ordername":"', :ORDNAME, '","status":"', :STATUS, '"}');
SELECT :STR1 FROM DUMMY ASCII :BODYFILE;
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE, '-msg', :WSMSG,
'-method', 'POST', '-content', 'application/json';

/* --- Pattern 2: Larger JSON (multiple SELECTs with ASCII ADDTO) --- */
:BODYFILE = NEWATTACH('body.txt');
SELECT STRCAT('{"deviceId":"1",')
FROM DUMMY ASCII :BODYFILE;
SELECT STRCAT('"ORDERS":{"ORDNAME":"', :ORDNAME, '",')
FROM DUMMY ASCII ADDTO :BODYFILE;
SELECT STRCAT('"CUSTNAME":"', :CUSTNAME, '"}}')
FROM DUMMY ASCII ADDTO :BODYFILE;
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE, '-msg', :WSMSG,
'-method', 'POST', '-content', 'application/json';

/* --- Pattern 3: Complete POST with error handling --- */
/* Uses system/tmp for debugging (inspect files) */
:URL =
'https://example.com/api/webhook';
:RESPONSE =
STRCAT('../../system/tmp/',
ITOA(SQL.USER), '-resp.txt');
:WSMSG =
STRCAT('../../system/tmp/',
ITOA(SQL.USER), '-msg.txt');
:BODYFILE =
STRCAT('../../system/tmp/',
ITOA(SQL.USER), '-body.txt');
/* Build JSON with ASCII ADDTO for long payloads */
SELECT STRCAT('{"orderNum":"',
:ORDNAME, '",')
FROM DUMMY ASCII :BODYFILE;
SELECT STRCAT('"customer":"',
:CUSTNAME, '"}')
FROM DUMMY ASCII ADDTO :BODYFILE;
/* Send POST — break long lines at params */
EXECUTE WSCLIENT :URL,
:BODYFILE, :RESPONSE,
'-msg', :WSMSG,
'-method', 'POST',
'-content', 'application/json',
'-trc';
/* Check for errors */
:PAR1 = '';
SELECT MESSAGE INTO :PAR1
FROM ERRMSGS
WHERE USER = SQL.USER
AND TYPE = 'w';


/*=====================================================================
 * WSCLIENT - URL LONGER THAN 127 CHARACTERS
 * Use -urlfile for long URLs.
 *=====================================================================*/

/* Write the long URL to a file */
SELECT SQL.TMPFILE INTO :URLFILE FROM DUMMY;
SELECT :LONGURL FROM DUMMY ASCII UNICODE :URLFILE;

/* Pass empty string as endpoint, use -urlfile */
EXECUTE WSCLIENT '', :INFILE, :OUTFILE,
'-urlfile', :URLFILE,
'-method', 'GET',
'-content', 'application/json';


/*=====================================================================
 * WSCLIENT - OAUTH2 AUTHENTICATION
 * Use token code from OAuth2 Definitions form.
 *=====================================================================*/

/* --- Using -authname with OAuth2 token code --- */
EXECUTE WSCLIENT :ENDPOINT_URL, :INFILE, :OUTFILE,
'-authname', 'DEMO_TOKEN',
'-content', 'application/json',
'-method', 'GET';

/* Setup steps in Priority:
   1. Open OAuth2 Definitions form
   2. Record Token Code (e.g., DEMO_TOKEN) and Token Description
   3. Register with web service provider to get:
      ClientID, Client Secret, Token URL, OAuth2 URL
   4. Fill in Redirect URL (run "Update Redirect URL" action)
   5. Fill in Scope (end with offline_access)
   6. In OAuth2 Data subform, record Entity ID
   7. Run "Get New Token" action
   8. Refresh tokens via "Refresh Token" action
*/


/*=====================================================================
 * XMLPARSE EXAMPLES
 * Parse XML files into INTERFXMLTAGS table.
 *=====================================================================*/

/* --- Parse first instance only --- */
SELECT SQL.TMPFILE INTO :OUTXMLTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTXMLTAB1;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD', 1), 'example.xml');

EXECUTE XMLPARSE :FILE, :OUTXMLTAB1, 0, :MSG;

SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I1 WHERE LINE <> 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;

/* --- Parse ALL instances (-all flag) --- */
SELECT SQL.TMPFILE INTO :OUTXMLTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I2 TO :OUTXMLTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD', 1), 'example.xml');

EXECUTE XMLPARSE :FILE, :OUTXMLTAB2, 0, :MSG, '-all';

SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I2 WHERE LINE <> 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I2;

/* --- Complete XMLPARSE pattern with two linked copies --- */
SELECT SQL.TMPFILE INTO :OUTXMLTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :OUTXMLTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTXMLTAB1;
GOTO 500 WHERE :RETVAL <= 0;
LINK INTERFXMLTAGS I2 TO :OUTXMLTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD', 1), 'example.xml');

EXECUTE XMLPARSE :FILE, :OUTXMLTAB1, 0, :MSG;
EXECUTE XMLPARSE :FILE, :OUTXMLTAB2, 0, :MSG, '-all';

SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I1 WHERE LINE <> 0 FORMAT;
SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I2 WHERE LINE <> 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
UNLINK INTERFXMLTAGS I2;


/*=====================================================================
 * INSTAG - INSERT DATA INTO AN XML TAG
 * Insert file contents into a specific XML tag.
 *=====================================================================*/

/* --- Basic INSTAG --- */
:XMLFILE = 'path_to_xml_file';
:DATAFILE = 'path_to_data_file';
:XMLTAG = 'tag_name';
EXECUTE INSTAG :XMLFILE, :DATAFILE, :XMLTAG;
/* If multiple tags share the same name, contents go into first found */

/* --- Insert base64-encoded image into XML tag --- */
:IN_JPG = STRCAT(SYSPATH('TMP', 0), 'my_jpg.jpg');
:IN_JPGBASE = STRCAT(SYSPATH('TMP', 0), 'my_jpg.base');
EXECUTE FILTER '-base64', :IN_JPG, :IN_JPGBASE;
:IN_XML = STRCAT(SYSPATH('TMP', 0), 'file.xml');
:IN_TAG = 'attach';
EXECUTE INSTAG :IN_XML, :IN_JPGBASE, :IN_TAG;


/*=====================================================================
 * JSONPARSE EXAMPLES
 * Parse JSON files using XMLPARSE with 'Y' flag.
 *=====================================================================*/

/* --- Parse first instance only --- */
SELECT SQL.TMPFILE INTO :OUTJSONTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTJSONTAB1;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD', 1), 'example.json');

/* Add '' (empty string) and 'Y' at the end for JSON */
EXECUTE XMLPARSE :FILE, :OUTJSONTAB1, 0, :MSG, '', 'Y';

SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I1 WHERE LINE > 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;

/* --- Parse ALL instances from JSON --- */
SELECT SQL.TMPFILE INTO :OUTJSONTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I2 TO :OUTJSONTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD', 1), 'example.json');

EXECUTE XMLPARSE :FILE, :OUTJSONTAB2, 0, :MSG, '-all', 'Y';

SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I2 WHERE LINE > 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I2;

/* --- Convert base64-encoded PDF from JSON response --- */
SELECT SQL.TMPFILE INTO :JSON1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :JSON1;
GOTO 500 WHERE :RETVAL <= 0;

/* Parse JSON response */
EXECUTE XMLPARSE :RESPONSE, :JSON1, 0, :MSG, '', 'Y';

SELECT SQL.TMPFILE INTO :PDFBASE64TMP FROM DUMMY;
SELECT SQL.TMPFILE INTO :PDFFILETMP FROM DUMMY;
SELECT SQL.TMPFILE INTO :FILTERTMP FROM DUMMY;

/* Dump base64 contents to file */
SELECT VALUE
FROM INTERFXMLTAGS I1
WHERE LINE > 0
AND TAG = 'pdf'
ASCII UNICODE :PDFBASE64TMP;
UNLINK INTERFXMLTAGS I1;

/* Prepare for base64 conversion (clean up newlines) */
SELECT '#' FROM DUMMY ASCII UNICODE ADDTO :PDFBASE64TMP;
EXECUTE FILTER '-delnl', :PDFBASE64TMP, :FILTERTMP;
EXECUTE FILTER '-filter', '#', '#', '010', :FILTERTMP, :PDFBASE64TMP;

/* Convert from base64 to binary PDF */
EXECUTE FILTER '-unbase64', :PDFBASE64TMP, :PDFFILETMP, SQL.TMPFILE;
LABEL 500;
UNLINK INTERFXMLTAGS I1;


/*=====================================================================
 * SFTPCLNT EXAMPLES
 * SFTP upload, download, and directory listing.
 * Available v23.1+ (backports for v22.1, v23.0).
 *=====================================================================*/

/* --- Upload a file to SFTP --- */
SELECT SQL.TMPFILE INTO :SOURCE FROM DUMMY;
SELECT 'THIS IS A TEST' FROM DUMMY ASCII :SOURCE;
:DEST = 'destinationTest.txt';
EXECUTE SFTPCLNT 'ch1', '-u', :SOURCE, :DEST;
/* 'ch1' = Code from Definitions for SFTP form */
/* Cannot create folders on SFTP during upload */

/* --- Download a file from SFTP --- */
:SRC = 'TestFolder/GrabTest.txt';
:TRGT = STRCAT(SYSPATH('LOAD', 1), 'GrabTarget.txt');
EXECUTE SFTPCLNT 'ch1', '-d', :SRC, :TRGT;

/* --- Upload with timeout and error messages --- */
EXECUTE SFTPCLNT 'ch1', '-u', :SOURCE, :DEST,
'-msg', :MSGFILE, '-timeout', '30000';

/* --- List folder contents --- */
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
EXECUTE SFTPCLNT 'vg1', '-l', 'pub/example', :ST6;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
/* STACK6 columns: NAME (filename), TYPE (F/D/L), NUM (timestamp) */
SELECT NAME, TYPE, 01/01/88 + NUM FROM STACK6 WHERE NAME <> '' FORMAT;
UNLINK STACK6;
LABEL 99;

/* SFTP setup in Priority:
   Open: System Management > System Maintenance > Internet Definitions > Definitions for SFTP
   Fields: Code (CONFIGID), Path (sftp://host:port), User, Password
   Only username/password authentication is supported */


/*=====================================================================
 * FILTER EXAMPLES
 * Text file manipulation: encoding, replacement, base64.
 *=====================================================================*/

/* --- Convert uppercase to lowercase --- */
EXECUTE FILTER 'A', 'Z', 'a', :INPUT, :OUTPUT;
/* Formula: new char = original + (target - from) */

/* --- Convert tabs to commas (for CSV) --- */
EXECUTE FILTER '09', '09', ',', :INPUT, :OUTPUT;

/* --- String replacement --- */
EXECUTE FILTER '-replace', 'OldString', 'NewString', :INPUT, :OUTPUT;

/* --- Multiple replacements --- */
EXECUTE FILTER '-replace', 'Old1', 'New1', 'Old2', 'New2', :INPUT, :OUTPUT;

/* --- Replace with file contents (for strings > 127 chars) --- */
EXECUTE FILTER '-replacef', '[placeholder]', :FILESTR, :INPUT, :OUTPUT;

/* --- Encoding conversions --- */
EXECUTE FILTER '-unicode2ascii', :INPUT, :OUTPUT;
EXECUTE FILTER '-ascii2unicode', :INPUT, :OUTPUT;
EXECUTE FILTER '-unicode2utf8', :INPUT, :OUTPUT;
EXECUTE FILTER '-utf82unicode', :INPUT, :OUTPUT;
EXECUTE FILTER '-ofx2xml', :INPUT, :OUTPUT;   /* OFX to XML */

/* --- File formatting --- */
EXECUTE FILTER '-addcr', :INPUT, :OUTPUT;     /* Add carriage returns */
EXECUTE FILTER '-trim', :INPUT, :OUTPUT;      /* Trim whitespace */
EXECUTE FILTER '-delnl', :INPUT, :OUTPUT;     /* Delete last empty line */

/* --- Reverse character order --- */
EXECUTE FILTER '-r', :INPUT, :OUTPUT;

/* --- Convert comma-separated to tab-separated (CSV to TSV) --- */
EXECUTE FILTER ',', ',', '09', :INPUT, :OUTPUT;


/*=====================================================================
 * BASE64 CONVERSION EXAMPLES
 * Encode/decode files to/from base64.
 *=====================================================================*/

/* --- Encode file to base64 --- */
:_PDF = STRCAT(SYSPATH('TMP', 1), 'f.pdf');
:_PDF_B = STRCAT(SYSPATH('TMP', 1), 'f_base64.pdf');
EXECUTE FILTER '-base64', :_PDF, :_PDF_B, SQL.TMPFILE;

/* --- Decode base64 to file --- */
/* Input file must be in Unicode format */
:_PDF2 = STRCAT(SYSPATH('TMP', 1), 'f_new.pdf');
EXECUTE FILTER '-unbase64', :_PDF_B, :_PDF2, SQL.TMPFILE;

/* --- Replace string in file with base64 of another file --- */
/* Useful for inserting base64 data into JSON requests */
EXECUTE FILTER '-replacestrbase64', :INPUT, :OUTPUT,
'[stringToReplace]', :FILETOCONVERT, SQL.TMPFILE;

/* --- Insert base64 image into XML tag --- */
:IN_JPG = STRCAT(SYSPATH('TMP', 0), 'my_jpg.jpg');
:IN_JPGBASE = STRCAT(SYSPATH('TMP', 0), 'my_jpg.base');
EXECUTE FILTER '-base64', :IN_JPG, :IN_JPGBASE;
:IN_XML = STRCAT(SYSPATH('TMP', 0), 'file.xml');
EXECUTE INSTAG :IN_XML, :IN_JPGBASE, 'attach';


/*=====================================================================
 * WINAPP - RUNNING EXTERNAL APPLICATIONS
 * Execute external programs from Priority.
 *=====================================================================*/

/* --- Run an external program --- */
EXECUTE WINAPP 'C:\Program Files\Microsoft Office\Office', 'WINWORD.EXE';

/* --- Run and wait for completion (-w) --- */
EXECUTE WINAPP 'C:\Windows', '-w', 'notepad', 'tabula.ini';

/* --- Convert Excel to tab-delimited --- */
EXECUTE WINAPP 'p:\bin.95', '-w', 'EXL2TXT.exe', :EXCELFILE, :TSVFILE;
/* Only first sheet is converted; output is UTF-16 */

/* --- Web interface: program must be in BIN.95 folder --- */
EXECUTE WINAPP SYSPATH('BIN', 0), '-w', 'MYPROGRAM.exe', :PARAM1;


/*=====================================================================
 * WINRUN - EXECUTING PRIORITY FROM EXTERNAL APPLICATION
 * Windows only. For automation and external integrations.
 *=====================================================================*/

/* --- Open a form --- */
/* p:\priority\bin.95\winrun "" tabula XYZabc1 p:\priority\system\prep demo
   WINFORM ORDERS */

/* --- Run a procedure --- */
/* d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
   WINACTIV -P BACKFLUSH_ONNEW */

/* --- Run an interface --- */
/* d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
   INTERFACE LOADORDERS d:\priority\tmp\messages.txt */


/*=====================================================================
 * FILE MANAGEMENT UTILITIES
 * Copy, move, delete files; get file info.
 *=====================================================================*/

/* --- Copy a file --- */
EXECUTE COPYFILE :SOURCE, :DESTINATION;

/* --- Download from Internet --- */
EXECUTE COPYFILE '-i', :URL, :TOFILE, 30000;
/* Last parameter = timeout in milliseconds */
/* Optional: add :MSGFILE for error messages */

/* --- Move a file --- */
EXECUTE MOVEFILE :F1, :F2;

/* --- Delete a file --- */
EXECUTE DELWINDOW 'f', :F1;

/* --- Create a folder --- */
EXECUTE MAKEDIR :DIR;

/* --- Get file date --- */
LINK STACK TO :$.STK;
ERRMSG 1 WHERE :RETVAL <= 0;
EXECUTE GETDATE 'path/file_name', :$.STK;
:FILEDATE = 0;
SELECT ELEMENT INTO :FILEDATE FROM STACK WHERE ELEMENT > 0;
UNLINK STACK;

/* --- Get file size --- */
LINK STACK TO :$.STK;
ERRMSG 500 WHERE :RETVAL <= 0;
EXECUTE GETSIZE 'path/file_name', :$.STK;
:FILESIZE = 0;
SELECT ELEMENT INTO :FILESIZE FROM STACK WHERE ELEMENT > 0;
UNLINK STACK;


/*=====================================================================
 * FILELIST - BROWSE FOLDER CONTENTS
 * List files in a directory.
 *=====================================================================*/

/* --- Basic FILELIST (results in STACK6) --- */
:DIR = STRCAT(SYSPATH('SYNC', 1), 'tmpDir');
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
EXECUTE FILELIST :DIR, :ST6, :MSG;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
/* STACK6: NAME (filename), TYPE (F=file, D=dir, L=pagination), NUM (timestamp) */
SELECT NAME, TYPE, NUM FROM STACK6 WHERE NAME <> '' FORMAT;
UNLINK STACK6;
LABEL 99;

/* --- FILELIST with file size (-f flag, results in STACK_ERR) --- */
EXECUTE FILELIST :DIR, :ST6, :MSG, '-f';
/* STACK_ERR: MESSAGE (filename), CHARDATA (type), INTDATA1 (timestamp), INTDATA2 (size) */

/* --- Recursive FILELIST (-R flag) --- */
EXECUTE FILELIST :DIR, :ST6, :MSG, '-R';
/* Lists files including sub-folder paths */

/* --- AWS Cloud pagination (max 1000 files per call) --- */
/* A record with TYPE = 'L' and value '0' means more results available */
/* UNLINK AND REMOVE, then rerun FILELIST to get next page */


/*=====================================================================
 * ENCRYPTING DATA WITH CRPTUTIL
 * AES-256 encryption using Priority's installation-specific key.
 *=====================================================================*/

SELECT SQL.TMPFILE INTO :TST_STK FROM DUMMY;
LINK STACK_ERR TST_CRPSTK TO :TST_STK;
GOTO 9 WHERE :RETVAL <= 0;

/* Insert data to encrypt */
:TST_STRING1 = 'First very long confidential string';
:TST_STRING2 = 'Second very long confidential string';

DELETE FROM STACK_ERR TST_CRPSTK;
INSERT INTO STACK_ERR TST_CRPSTK (LINE, MESSAGE) VALUES(1, :TST_STRING1);
INSERT INTO STACK_ERR TST_CRPSTK (LINE, MESSAGE) VALUES(2, :TST_STRING2);

/* Encrypt (mode 2) */
:TST_CRPTMODE = 2;
EXECUTE CRPTUTIL :TST_CRPTMODE, -1, :TST_STK;
SELECT LINE, MESSAGE, INTDATA1
FROM STACK_ERR TST_CRPSTK WHERE LINE > 0 FORMAT;

/* Decrypt (mode 3) */
:TST_CRPTMODE = 3;
EXECUTE CRPTUTIL :TST_CRPTMODE, -1, :TST_STK;
SELECT INTDATA1, LINE, MESSAGE
FROM STACK_ERR TST_CRPSTK WHERE LINE > 0 FORMAT;

LABEL 9;
UNLINK STACK_ERR TST_CRPSTK;
/* Note: encryption key is unique per Priority installation.
   Encrypted data CANNOT be transferred to another installation.
   Running "Reset Priority Connect Data" regenerates the key. */


/*=====================================================================
 * MISCELLANEOUS UTILITIES
 *=====================================================================*/

/* --- SHELLEX: Open file with default application (Windows only) --- */
:FILE = 'c:\test.doc';
EXECUTE SHELLEX :FILE;       /* Opens with default application */

:FILE = 'www.google.com';
EXECUTE SHELLEX :FILE;       /* Opens default browser */

:FILE = 'c:\temp';
EXECUTE SHELLEX :FILE;       /* Opens folder in Explorer */

/* --- PRANDOM: Generate random value --- */
EXECUTE PRANDOM :FILE, 'Y';     /* Hexadecimal output */
EXECUTE PRANDOM :FILE, 'N';     /* Decimal output */

/* --- TABINI: Read client INI file (Windows only) --- */
SELECT SQL.TMPFILE INTO :A FROM DUMMY;
EXECUTE TABINI 'Environment', 'Tabula Host', :A;
LINK GENERALLOAD TO :A;
SELECT TEXT FROM GENERALLOAD WHERE LINE = 1 FORMAT;
UNLINK GENERALLOAD;

/* --- Dynamic SQL from file (EXECUTE SQLI) --- */
:FILENAME = '..\..\tmp\sqlfile.txt';
EXECUTE SQLI :FILENAME;
/* INSERT/UPDATE/DELETE only work for tabula group users */


/*=====================================================================
 * PRIORITY CLOUD FILE HANDLING
 * Special considerations for cloud-hosted environments.
 *=====================================================================*/

/* --- Cannot save directly to system/mail or system/sync --- */
/* Create in temp first, then COPYFILE */
SELECT NEWATTACH('aaa1', 'txt') INTO :FOUT FROM DUMMY;
SELECT SQL.TMPFILE INTO :F FROM DUMMY;
SELECT * FROM DAYS WHERE DAYNUM BETWEEN 1 AND 4 TABS :F;
EXECUTE COPYFILE :F, :FOUT;

/* --- Copy from system/sync to temp before processing --- */
:RAWFILE = STRCAT(SYSPATH('SYNC', 1), 'csv_240915.txt');
:RAWTMPFILE = STRCAT(SYSPATH('TMP', 1), 'csv_240915.txt');
:FILTEREDFILE = STRCAT(SYSPATH('TMP', 1), 'tsv_240915.txt');
EXECUTE COPYFILE :RAWFILE, :RAWTMPFILE;
EXECUTE FILTER ',', ',', '09', :RAWTMPFILE, :FILTEREDFILE;
EXECUTE DBLOAD '-L', 'EXAMPLE', '-i', :FILTEREDFILE;

/* --- Saving debug files on web --- */
:DEBUGFILE = NEWATTACH('MyDebug', '.txt');
:FILEPATH = STRCAT(SYSPATH('TMP', 1), 'MyDebug.txt');
SELECT DAYNUM, DAYNAME FROM DAYS TABS :FILEPATH;
EXECUTE COPYFILE :FILEPATH, :DEBUGFILE;
/* Access via a form with Attachments subform */
