# External Integrations

Reference for invoking external programs and integrating with external systems: WINAPP/WINRUN for external apps, WSCLIENT for HTTP/REST/SOAP, XMLPARSE/JSONPARSE for response parsing, SFTPCLNT for SFTP file transfer, and URL-based Priority activation from external callers.

## Table of Contents

- [External Program Invocation](#external-program-invocation)
- [WSCLIENT - Webservice Interaction](#wsclient---webservice-interaction)
- [XML and JSON Parsing](#xml-and-json-parsing)
- [SFTP with SFTPCLNT](#sftp-with-sftpclnt)
- [Activate Priority from External Application](#activate-priority-from-external-application)

---

## External Program Invocation

### WINAPP - Run External Applications

```sql
EXECUTE WINAPP 'path', ['-w'], 'program', [parameters];
```

- Path: full path to the external program (web interface: must be in BIN.95 folder)
- `-w`: wait for the program to complete before returning
- Program name with or without .exe suffix

**Examples:**
```sql
/* Run MS-Word */
EXECUTE WINAPP 'C:\Program Files\Microsoft Office\Office', 'WINWORD.EXE';

/* Open tabula.ini in Notepad and wait */
EXECUTE WINAPP 'C:\Windows', '-w', 'notepad', 'tabula.ini';
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Web Interface Execution Environment
In the Web interface, `WINAPP` executes on the **server side** (IIS server), not on the local client machine. 
*   **Location:** Executables must be stored in the `bin.95` directory on the server.
*   **Path Parameter:** To avoid hardcoding paths or issues with UNC paths (where `SYSPATH` might return a network address), leave the first parameter empty (`''`). This defaults to the local `bin.95` folder on the server.
*   **Permissions:** The OS user running the "Priority App Service" or IIS App Pool must have sufficient permissions to access the executable and any network paths the program interacts with.

```sql
/* Recommended syntax for Web Interface (executable in bin.95) */
EXECUTE WINAPP '', '-w', 'CheckApp.exe';
```

#### File Access in Web Environment
Because the application runs on the server, any file parameters (input/output files) must refer to paths accessible by the server's file system, not the user's local `C:\` drive. If you need to process a local file, it must first be uploaded to the server.

#### Running Local Client Applications from Web
`WINAPP` cannot trigger local applications (like a `.bat` file or `ftp.exe`) on a user's computer when using the Web interface. 
*   **Solution:** For client-side interaction, develop a local Web Service on the client machine and communicate with it using the `WSCLIENT` command instead of `WINAPP`.

#### Limitations of WINACTIV and ACTIVATE in Web
Commands like `WINACTIV` or `ACTIVATE` (often used to trigger reports or other procedures with UI) are generally not supported within form triggers in the Web interface. If a procedure calls an external executable that requires user interaction, it will fail in the Web environment as there is no desktop session to display the interface.

#### Using EXL2TXT Utility
When using the `EXL2TXT.exe` utility via `WINAPP` to convert files for `DBLOAD`:
*   Ensure the utility is in the server's `bin.95` folder.
*   Ensure the source Excel file and target Text file paths are server-accessible paths.

```sql
/* Example: Converting Excel to Text on the server */
EXECUTE WINAPP '', '-w', 'EXL2TXT.exe', 'C:\temp\data.xls', 'C:\temp\data.txt';
```
<!-- ADDED END -->
### WINRUN - Execute Priority from External Application (Windows Only)

```
x:\priority\bin.95\winrun "" username password
x:\priority\system\prep company -nbg -err errfile command arguments
```

**Parameters:**
- `-nbg`: run in foreground
- `-err errfile`: send preliminary error messages to file

**Examples:**
```
/* Open Sales Orders form */
p:\priority\bin.95\winrun "" tabula XYZabc1 p:\priority\system\prep demo
WINFORM ORDERS

/* Run a procedure */
d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
WINACTIV -P BACKFLUSH_ONNEW

/* Run an interface */
d:\priority\bin.95\winrun "" tabula XYZabc1 d:\priority\system\prep demo
INTERFACE LOADORDERS d:\priority\tmp\messages.txt
```

<!-- ADDED START -->
### Common Issues and Solutions

**Web Interface Compatibility**
*   **Problem:** Attempting to execute `WINRUN` or `WINACTIV` from a client machine that only uses the Priority Web interface.
*   **Solution:** `WINRUN` is a legacy Windows-only utility and is not compatible with the Web interface environment. For web-based environments, use the Web SDK (REST API), the Task Scheduler (TTS), or execute logic via server-side procedures.
*   **Example:**
    ```cmd
    C:\priority\bin.95\winrun "" username password C:\priority\system\prep demo WINACTIV -P PROCEDURE_NAME
    ```

**Priority Zoom Limitations**
*   **Problem:** External applications or websites failing to trigger interfaces via `winrun.exe` after version updates in Priority Zoom.
*   **Solution:** Priority Zoom has specific development limitations regarding direct command-line execution from web services. It is recommended to use standard API modules or file-based interfaces (Excel/Load tables) rather than calling `winrun.exe` directly from an external web process.
*   **Example:**
    ```cmd
    c:\zoom\bin.95\winrun.exe "" username password c:\zoom\system\prep company c:\zoom\bin.95\INTERFAC.EXE INTERFACE_NAME C:\path\to\file.TXT -stackerr ERR_LOG -W -enforcebpm
    ```

**Inconsistent Data in HTML Generation**
*   **Problem:** Missing fields (e.g., "To" address) when generating documents via `WINHTML` through a `WINRUN` command line.
*   **Solution:** Ensure the `-nbg` (no background) flag is used to ensure the process has sufficient resources and focus to render the HTML. If data is still missing inconsistently, verify that the environment paths and permissions for the output directory are correctly mapped for the user executing the command.
*   **Example:**
    ```cmd
    "C:\Priority\bin.95\winrun" "" "username" "password" "\\server\priority\system\prep" company -nbg WINHTML -d WWWSHOWDOC_D "" "" -v 1234567 -s "" -o C:\output\path\doc.html
    ```
<!-- ADDED END -->
### Miscellaneous Utilities

**SHELLEX** (Windows client only):
```sql
:file = 'c:\test.doc';
EXECUTE SHELLEX :file;       /* Opens with default application */

:file = 'www.google.com';
EXECUTE SHELLEX :file;       /* Opens default browser */

:file = 'c:\temp';
EXECUTE SHELLEX :file;       /* Opens folder in Explorer */
```

**PRANDOM** (random value):
```sql
EXECUTE PRANDOM :file, :outtype;
/* 'Y' = hexadecimal, anything else = decimal */
```

---

<!-- ADDED START -->
### Common Issues and Solutions

**COPYFILE Parameter Requirements**
Starting from Priority 24.0, the `msgfile` parameter in the `COPYFILE` command is mandatory. If omitted, the command will fail to execute.
```sql
/* Correct syntax for version 24.0+ */
EXECUTE COPYFILE '-i', :url, :tofile, timeout, :msgfile;
```

**Client-Side vs. Server-Side Execution (EXL2TXT)**
The `EXL2TXT.exe` utility is a Windows-only client-side tool. It cannot be executed via the Web interface or directly on the server via `WINAPP` in a web environment. For web-based Excel processing, use built-in Form Load Excel import capabilities.
```sql
/* Works in Windows Client ONLY */
EXECUTE WINAPP 'C:\priority\bin.95', '-w', 'EXL2TXT.exe', :input_xls, :output_txt;
```

**Verifying DELWINDOW Success**
The `DELWINDOW` command does not return a success or failure status. To verify if a file was successfully deleted, use the `FileSizeDate` function from the `FUNC` table immediately after execution to check if the file still exists.

**PDF Manipulation Limitations**
Priority does not have built-in SDK methods for programmatically editing, merging, or overlaying text (such as Part IDs) onto existing external PDF files. Such operations require third-party tools or external scripts.

**Encoding and Hebrew Text (Hebconvert)**
The `Hebconvert` component is deprecated and not supported on SQL Server 2017 and above. To avoid "gibberish" or reversed Hebrew text when extracting data for external BI tools (like Qlik), it is recommended to use the REST API, which handles modern encoding standards correctly.

**Automating HTML Attachments**
To programmatically attach an HTML report to a form (e.g., `MAILBOX`):
1. Generate the report using `WINHTML` or `ACTIVATE` and save it to a file.
2. Use a Form Load (interface) to load that file path into the `EXTFILENAME` sub-level of the target form.

**Troubleshooting PRNTORIG**
If `PRNTORIG` sends a blank page, verify the file pathing. Ensure the path is accessible to the service user (especially when running via Task Scheduler) and consider using UNC paths for network accessibility.
<!-- ADDED END -->

---

## WSCLIENT - Webservice Interaction

### Syntax

```sql
EXECUTE WSCLIENT :endpoint_url, :inFile, :outFile
  [, '-msg', :msgFile]
  [[, '-head2', :oneHeader] | [, '-head', :headerFile]]
  [, '-usr', :wsUser [, '-pwd', :wsUserPwd] [, '-domain', :userDomain]]
  [, '-tlscert', "certData", "pem password"]
  [, '-tag'|'-val', :tagName]
  [, '-action', :soapAction]
  [, '-timeout', :msec]
  [, '-content', :contentType]
  [, '-method', :method]
  [, '-headout', headers_response_outfile]
  [, '-authname', :tokenCode]
  [, '-urlfile', urlfile];
```

<!-- ADDED START -->
### Common Issues and Solutions

*   **GET Requests and Input Files:**
    When performing a `GET` request, the command may fail if a file path is passed as the second parameter (`:inFile`). Since `GET` requests typically do not have a request body, pass an empty string (`''`) as the input file parameter.
    ```sql
    :URL = 'https://api.example.com/odata/Customers';
    EXECUTE WSCLIENT :URL, '', :OUTJSON, '-method', 'GET';
    ```

*   **Binary/PDF File Corruption:**
    In older versions of Priority, binary files (such as PDFs) downloaded via `WSCLIENT` might arrive corrupted even if the same request works in external tools like Postman. This was a known issue in the executable (bin) and was resolved in version 22.1.85. If you encounter file corruption, ensure your environment is updated to at least this version.

*   **Cloud Environment Connectivity:**
    In Priority Cloud environments, outgoing requests via `WSCLIENT` are generally restricted to port 443. If you receive network or port blockage errors, verify that the destination service is listening on port 443 and that the specific destination URL has been whitelisted in the cloud firewall.

*   **Silent Failures or Environment Issues:**
    If `WSCLIENT` fails to send data without generating entries in the `ERRMSGS` table, it often indicates an outdated `bin` folder or a server-side environment issue. Testing the request against a third-party request inspector (like Pipedream or Webhook.site) can help determine if the issue lies within the Priority utility or the destination server.

*   **Missing Response Files in Older Versions:**
    In specific older versions (e.g., 18.5), the command might fail to generate the response file (`.RSP`) despite the same code working in newer versions. This typically requires a technical investigation into version-specific bugs or an upgrade to a more stable release.
<!-- ADDED END -->
### Parameter Reference

| Parameter | Description |
|---|---|
| `:endpoint_url` | URL of the web service (max 127 chars) |
| `:inFile` | File sent to the web service (Unicode; converted if different encoding specified) |
| `:outFile` | File where response is stored |
| `-msg`, `:msgFile` | File for error messages |
| `-head2`, `:oneHeader` | Single header (can specify multiple instances) |
| `-head`, `:headerFile` | Header file (each header must end with newline) |
| `-usr`, `:wsUser` | Username for authentication |
| `-pwd`, `:wsUserPwd` | Password for authentication |
| `-domain`, `:userDomain` | Domain for authentication |
| `-tlscert`, `certData`, `pem password` | Client-side certificate (PEM format) |
| `-tag` / `-val`, `:tagName` | Extract XML tag from response (`-val` = contents only) |
| `-action`, `:soapAction` | SOAP action |
| `-timeout`, `:msec` | Timeout in milliseconds |
| `-content`, `:contentType` | Content type (e.g., `application/json`) |
| `-method`, `:method` | HTTP method (default POST; can be GET, PATCH, etc.) |
| `-headout`, `outfile` | Store response headers in a file |
| `-authname`, `:tokenCode` | OAuth2 token code |
| `-urlfile`, `urlfile` | URL file for URLs > 127 chars (set endpoint_url to '') |

**Notes:**
- Error messages are also written to ERRMSGS with type `w` under SQL.USER.
- Use XMLPARSE to read XML/JSON responses.
- Requests/responses are written to server log at DEBUG level.
- Content-type for XML must match encoding in XML header.

<!-- ADDED START -->
### Common Issues and Solutions

**Handling Long Headers (e.g., API Tokens > 1000 characters)**
Priority `CHAR` variables have length restrictions that may prevent passing long Bearer tokens directly via `-head2`.
*   **Solution:** Save the long token/header string into an ASCII file using a table and the `SELECT TO ASCII` command. Then, use the `-head` parameter to reference this file.

**Extracting Data from Response Headers**
Sometimes required data (like a session token) is returned in the HTTP response header rather than the body.
*   **Solution:** Use the `-headout` parameter followed by a filename. This saves the response headers to a file which can then be parsed using standard Priority file-reading commands.

**HTTP 415 or Communication Errors after Upgrades**
Upgrading Priority versions may change default header behaviors. If a web service suddenly returns "Unsupported Media Type," it may require an explicit content type.
*   **Solution:** Explicitly define the `Content-Type` using the `-content` parameter.
*   **Example:**
    ```sql
    EXECUTE WSCLIENT :URL, :INFILE, :OUTFILE, '-content', 'text/xml';
    ```

**"Premature end of file" Errors with XML**
When `-content` is set to `text/xml`, the system performs stricter validation on the XML structure.
*   **Solution:** Ensure the input file includes a proper XML declaration (e.g., `<?xml version="1.0" encoding="UTF-8" ?>`). If the receiving server allows it, you may also try omitting the `-content` parameter to bypass strict local validation.
*   **Example:**
    ```sql
    EXECUTE WSCLIENT :URL, :INFILE, :OUTFILE, '-msg', :MSGS, '-content', 'text/xml; charset=utf-8';
    ```

**Timeout Limitations**
While the `-timeout` parameter accepts large values (in milliseconds), the connection may still drop if external factors (load balancers, firewalls, or the destination server's own timeout settings) are set to a lower threshold than the `WSCLIENT` parameter.
<!-- ADDED END -->

### SOAP / XML Responses (25.1+)

Starting with SDK 25.1, `WSCLIENT` accepts responses with `Content-Type: application/soap+xml` in addition to JSON and plain XML. Pair `-content` with `-action` to set the SOAPAction header required by most SOAP services:

```sql
EXECUTE WSCLIENT :URL, :INFILE, :OUTFILE,
  '-msg',     :MSGFILE,
  '-content', 'application/soap+xml; charset=utf-8',
  '-action',  'http://tempuri.org/MyOperation';
```

Parse the response with `XMLPARSE` (see the XML/JSON Parsing section):

```sql
EXECUTE XMLPARSE :OUTFILE, :LINKFILE, 0, :MSG;
```

Notes:
- When `-content` is `text/xml` or `application/soap+xml`, the server validates that the XML header's encoding matches (e.g., `text/xml; charset="utf-8"` must match `<?xml version="1.0" encoding="UTF-8"?>` in the input file).
- To read SOAP envelopes larger than 1023 characters per tag, ensure the server BIN is 23.1+ so `XMLPARSE` can read up to 45,000 chars per tag.
- If the SOAP response only carries data in headers, combine with `-headout` to capture the header file separately.

### URL Longer Than 127 Characters

```sql
EXECUTE WSCLIENT '', :INFILE, :OUTFILE,
  '-urlfile', :urlfile;
```

### Authenticate with OAuth2

1. Open the **OAuth2 Definitions** form in Priority.
2. Record Token Code and Token Description (use custom prefix, e.g., `DEMO_TOKEN`).
3. Register with the web service provider to obtain: ClientID, Client Secret (+ Client Secret 2 if needed), Token URL, OAuth2 URL.
4. Fill in Redirect URL:
   - **Automatic Redirect:** Run "Update Redirect URL" action. Requires Priority Application Server.
   - **OOB Redirect:** Use provider-supplied parameters (e.g., `urn:ietf:wg:oauth:2.0:oob`).
5. Fill in Scope (end with `offline_access`).

**Version 22.1+ options:**
- Additional Parameters for URL
- Encrypted Tokens (auto-encrypt received tokens)
- By User (users see only their own tokens)
- Multi-company (token persists between companies)

**Getting the Token:**
1. In OAuth2 Data subform, record Entity ID and Description.
2. Run "Get New Token" action.
3. Login in browser when prompted.
4. For Automatic Redirect, tokens are obtained automatically.
5. For OOB Redirect, copy the string from the browser and paste into Priority.
6. Refresh tokens via "Refresh Token" action.

Use `-authname` with the token code in WSCLIENT calls.

### Building JSON Request Bodies

When constructing JSON files to send as WSCLIENT request bodies, follow these rules:

#### Use `ASCII` format (not `TABS UNICODE`)

- `ASCII` = data only, no headings — correct for JSON files
- `TABS UNICODE` adds column titles to each record, polluting the JSON. Even with `:NOTABSTITLE = 1`, headers may still appear for STRCAT expressions
- `SQLSERVER` is documented as "TABS without titles" but may still produce headers in some contexts

```sql
/* CORRECT - plain ASCII, no headers */
SELECT STRCAT('{"key":"', :VALUE, '"}')
FROM DUMMY ASCII :BODYFILE;

/* WRONG - TABS UNICODE adds column headers */
SELECT STRCAT('{"key":"', :VALUE, '"}')
FROM DUMMY TABS UNICODE :BODYFILE;
```

#### Use `"` directly — no placeholder replacement needed

Double quotes `"` are valid inside single-quoted strings in Priority SQL. Write JSON with `"` directly instead of using `!` placeholders with FILTER replacement:

```sql
/* CORRECT - direct double quotes */
SELECT STRCAT('{"name":"', :NAME, '"}')
FROM DUMMY ASCII :BODYFILE;

/* UNNECESSARY - placeholder replacement */
SELECT STRCAT('{!name!:!', :NAME, '!}')
FROM DUMMY ASCII :BODYFILE;
EXECUTE FILTER '-replace', '!', '"', :BODYFILE, :BODYFILE2;
```

#### Respect the 127-character STRCAT limit

STRCAT results are limited to 127 characters. For longer JSON:
- Split into multiple variables: `:STR1`, `:STR2`, then `STRCAT(:STR1, :STR2)`
- Or use multiple `SELECT ... ASCII ADDTO` statements

```sql
/* Chain variables for longer JSON */
:STR1 = STRCAT('{"field1":"', :VAL1, '","field2":"', :VAL2, '",');
:JSON = STRCAT(:STR1, '"field3":"', :VAL3, '"}');
SELECT :JSON FROM DUMMY ASCII :BODYFILE;
```

#### Never mix `ASCII` and `ASCII UNICODE` in the same file

Mixing encodings in a single file (one SELECT with `ASCII`, another with `ASCII UNICODE ADDTO`) produces garbled output. Use the same format for all writes to a file.

#### `:HEBREWFILTER` breaks JSON structure

Setting `:HEBREWFILTER = 1` reorders the entire output line using the bidirectional text algorithm, including JSON syntax characters (`{`, `"`, `:`). This produces invalid JSON. Do not use `:HEBREWFILTER` when building JSON files.

Hebrew text in Priority is stored in visual (reversed) order. Handle the reversal on the receiving side, not in the Priority output.

#### `ASCII ADDTO` inserts newlines between SELECTs

Each `SELECT ... ASCII ADDTO` writes on a new line. The resulting file will have newlines between JSON fragments. Most APIs accept multiline JSON, but if the API is strict about single-line JSON, build the entire body in one SELECT or use FILTER to strip newlines.

#### File path recommendations

Use `system/tmp/` with user-specific filenames for debuggable temp files:

```sql
:BODYFILE =
STRCAT('../../system/tmp/',
ITOA(SQL.USER), '-body.txt');
```

Use `NEWATTACH` for production files that don't need manual inspection (files are auto-cleaned but **not** visible in `system/tmp/`):

```sql
:BODYFILE = NEWATTACH('body.txt');
```

**Important:** `NEWATTACH` files are stored in Priority's internal attachment directory, not in `system/tmp/`. During development, use explicit `system/tmp/` paths so you can inspect the files. Switch to `NEWATTACH` for production.

#### 68-character line length limit

The Priority VSCode extension enforces a 68-character maximum line length for SQLI code. Break long lines at commas or operators:

```sql
/* WRONG — line too long, VSCode will warn */
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE, '-msg', :WSMSG, '-method', 'POST', '-content', 'application/json';

/* CORRECT — break at parameter boundaries */
EXECUTE WSCLIENT :URL,
:BODYFILE, :RESPONSE,
'-msg', :WSMSG,
'-method', 'POST',
'-content', 'application/json';
```

String literals containing URLs may exceed 68 chars — this is acceptable and the extension will allow it.

#### No string concatenation operator

Priority SQLI has no `||` or `+` operator for string concatenation. Use `STRCAT()` function only:

```sql
/* WRONG — || does not exist in SQLI */
:FULLNAME = :FIRST || ' ' || :LAST;

/* CORRECT */
:FULLNAME = STRCAT(:FIRST, ' ', :LAST);
```

<!-- ADDED START -->
### Common Issues and Solutions

#### Downloading Files from External URLs
In Priority Cloud environments, using `COPYFILE` to download files from external URLs often fails due to security restrictions or firewall blocks (especially for non-HTTPS links). 
**Solution:** Use `WSCLIENT` with the `GET` method to download the file to a temporary location first.
```sql
/* Example: Downloading a PDF via WSCLIENT */
:URL = 'https://external-service.com/file.pdf';
:TMP_FILE = NEWATTACH('download.pdf');
:EMPTY_IN = NEWATTACH('empty.txt'); /* WSCLIENT requires an input file */

EXECUTE WSCLIENT :URL, :EMPTY_IN, :TMP_FILE, '-method', 'GET';
```

#### Cloud Security and Whitelisting
When calling third-party APIs (e.g., Payment Gateways, SharePoint, or Cloud Storage) from a Priority Cloud environment, outbound requests may be blocked by default.
**Solution:** You must provide the Fully Qualified Domain Names (FQDN) or specific IP ranges of the external service to Priority Support to have them whitelisted in the cloud firewall.

#### Interacting with Cloud Storage (SharePoint, etc.)
Priority does not have a native "out-of-the-box" configuration for syncing with cloud storage providers like SharePoint.
**Solution:** Use `WSCLIENT` to interact with the provider's REST API. This typically requires setting up OAuth2 authentication (as described in the Authenticate with OAuth2 section) and using the `-authname` parameter to pass the token.
#### EXECUTE WRITE is NOT a Valid Command

`EXECUTE WRITE` does not exist in Priority SQLI. Do not use it for logging.
For debugging WSCLIENT calls, use the `-trc` flag which creates a trace file,
or log to a custom table (like the PIKY_APIFILES pattern below).

#### Recommended WSCLIENT POST Pattern (Clean)

```sql
/* Use NEWATTACH for all temp files */
:URL = 'https://api.example.com/endpoint';
:BODYFILE = NEWATTACH('body.txt');
:RESPONSE = NEWATTACH('resp.txt');
:WSMSG = NEWATTACH('wsmsg.txt');

/* Build JSON into a variable, then write with ASCII */
:PAR1 = STRCAT('{',
'"field1":"', :VAL1, '",',
'"field2":"', :VAL2, '"',
'}');
SELECT :PAR1 FROM DUMMY ASCII :BODYFILE;

/* Send POST with trace for debugging */
EXECUTE WSCLIENT :URL, :BODYFILE, :RESPONSE,
'-msg', :WSMSG, '-method', 'POST',
'-content', 'application/json', '-trc';

/* Check for errors */
:PAR1 = '';
SELECT MESSAGE INTO :PAR1 FROM ERRMSGS
WHERE USER = SQL.USER AND TYPE = 'w';
```

**Key points:**
- Use `NEWATTACH` instead of `STRCAT('../../system/tmp/', ITOA(SQL.USER), ...)` for temp files
- Use `ASCII` output (not `TABS UNICODE` + `FILTER` to replace quote placeholders)
- Double quotes `"` work directly inside single-quoted SQLI strings: `'"field":"value"'`
- Build complex JSON into a variable first with `STRCAT`, then `SELECT :VAR FROM DUMMY ASCII :FILE`
- Use `-trc` flag for debugging — creates a trace file with full request/response details
- Check `ERRMSGS` after WSCLIENT for error messages
- For batch API calls, log requests/responses to a custom table (see PIKY_APIFILES pattern in examples)

<!-- ADDED END -->

---

## XML and JSON Parsing

### XMLPARSE - Parse XML Files

```sql
EXECUTE XMLPARSE :XMLFILE, :LINKFILE, 0, :MSGFILE, ['-all'];
```

| Parameter | Description |
|---|---|
| `:XMLFILE` | XML file to parse |
| `:LINKFILE` | Linked INTERFXMLTAGS file for parsed data |
| `0` | Required syntax |
| `:MSGFILE` | Linked file for errors |
| `'-all'` | Parse all instances (omit for first instance only) |

**Note:** Starting with v23.1, XMLPARSE reads up to 45,000 characters per XML tag.

**Example:**
```sql
SELECT SQL.TMPFILE INTO :OUTXMLTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :OUTXMLTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTXMLTAB1;
GOTO 500 WHERE :RETVAL <= 0;
LINK INTERFXMLTAGS I2 TO :OUTXMLTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD',1), 'example.xml');

EXECUTE XMLPARSE :FILE, :OUTXMLTAB1, 0, :MSG;
EXECUTE XMLPARSE :FILE, :OUTXMLTAB2, 0, :MSG, '-all';

SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I1 WHERE LINE <> 0 FORMAT;
SELECT LINE, TAG, VALUE, ATTR
FROM INTERFXMLTAGS I2 WHERE LINE <> 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
UNLINK INTERFXMLTAGS I2;
```

### INSTAG - Insert Data into an XML Tag

```sql
EXECUTE INSTAG 'path_to_xml_file', 'path_to_data_file', 'tag_name';
```

**Variables version:**
```sql
:XMLFILE = 'path_to_xml_file';
:DATAFILE = 'path_to_data_file';
:XMLTAG = 'tag_name';
EXECUTE INSTAG :XMLFILE, :DATAFILE, :XMLTAG;
```

**Common use case -- inserting base64 image into XML:**
```sql
:IN_JPG = STRCAT(SYSPATH('TMP', 0), 'my_jpg.jpg');
:IN_JPGBASE = STRCAT(SYSPATH('TMP', 0), 'my_jpg.base');
EXECUTE FILTER '-base64', :IN_JPG, :IN_JPGBASE;
:IN_XML = STRCAT(SYSPATH('TMP', 0), 'file.xml');
:IN_TAG = 'attach';
EXECUTE INSTAG :IN_XML, :IN_JPGBASE, :IN_TAG;
```

**Note:** If multiple tags share the same name, contents are inserted into the first tag found.

### JSONPARSE - Parse JSON

Add `'Y'` to the end of the XMLPARSE command:

```sql
SELECT SQL.TMPFILE INTO :OUTJSONTAB1 FROM DUMMY;
SELECT SQL.TMPFILE INTO :OUTJSONTAB2 FROM DUMMY;
SELECT SQL.TMPFILE INTO :MSG FROM DUMMY;
LINK INTERFXMLTAGS I1 TO :OUTJSONTAB1;
GOTO 500 WHERE :RETVAL <= 0;
LINK INTERFXMLTAGS I2 TO :OUTJSONTAB2;
GOTO 500 WHERE :RETVAL <= 0;
:FILE = STRCAT(SYSPATH('LOAD',1), 'example.json');

EXECUTE XMLPARSE :FILE, :OUTJSONTAB1, 0, :MSG, '', 'Y';
EXECUTE XMLPARSE :FILE, :OUTJSONTAB2, 0, :MSG, '-all', 'Y';

SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I1 WHERE LINE > 0 FORMAT;
SELECT LINE, TAG, VALUE, ATTR FROM INTERFXMLTAGS I2 WHERE LINE > 0 FORMAT;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
UNLINK INTERFXMLTAGS I2;
```

### Convert Files from Base64

Complete example for converting a base64-encoded PDF from a JSON response:

```sql
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

/* Prepare for base64 conversion */
SELECT '#' FROM DUMMY ASCII UNICODE ADDTO :PDFBASE64TMP;
EXECUTE FILTER '-delnl', :PDFBASE64TMP, :FILTERTMP;
EXECUTE FILTER '-filter', '#', '#', '010', :FILTERTMP, :PDFBASE64TMP;

/* Convert from base64 */
EXECUTE FILTER '-unbase64', :PDFBASE64TMP, :PDFFILETMP, SQL.TMPFILE;
LABEL 500;
UNLINK INTERFXMLTAGS I1;
```

---

## SFTP with SFTPCLNT

Available starting with v23.1 (BIN95 version 9). Backports for v22.1 and v23.0.

### Definitions for SFTP

Set up in **Definitions for SFTP** form (System Management > System Maintenance > Internet Definitions > Definitions for SFTP):

| Field | Description |
|---|---|
| Code | Identifying code (used as CONFIGID) |
| SFTP Folder Desc | Short description |
| Path | Server URL starting with `sftp://` and ending with port (e.g., `sftp://20.0.0.195:22`) |
| User | Username |
| Password | Password |

**Note:** Only username/password authentication is supported.

### Upload/Download

```sql
EXECUTE SFTPCLNT 'CONFIGID', '-u' | '-d', 'SOURCEFILE',
  'DESTINATIONFILE', ['-msg', MSGFILE], ['-timeout', milliseconds];
```

| Parameter | Description |
|---|---|
| CONFIGID | Code from Definitions for SFTP |
| `-u` / `-d` | Upload or download |
| SOURCEFILE | File to upload from Priority, or download from SFTP |
| DESTINATIONFILE | Target file name (cannot create folders on SFTP during upload) |
| `-msg` | Error messages file |
| `-timeout` | Connection timeout in milliseconds |

**Upload example:**
```sql
SELECT SQL.TMPFILE INTO :SOURCE FROM DUMMY;
SELECT 'THIS IS A TEST' FROM DUMMY ASCII :SOURCE;
:DEST = 'destinationTest.txt';
EXECUTE SFTPCLNT 'ch1', '-u', :SOURCE, :DEST;
```

**Download example:**
```sql
:SRC = 'TestFolder/GrabTest.txt';
:TRGT = STRCAT(SYSPATH('LOAD', 1), 'GrabTarget.txt');
EXECUTE SFTPCLNT 'ch1', '-d', :SRC, :TRGT;
```

### List Folder Contents

```sql
EXECUTE SFTPCLNT 'CONFIGID', '-l', 'DIR', 'TABLEFILE',
  ['-msg', MSGFILE], ['-timeout', milliseconds];
```

**Example:**
```sql
SELECT SQL.TMPFILE INTO :ST6 FROM DUMMY;
EXECUTE SFTPCLNT 'vg1', '-l', 'pub/example', :ST6;
LINK STACK6 TO :ST6;
GOTO 99 WHERE :RETVAL <= 0;
SELECT NAME, TYPE, 01/01/88 + NUM FROM STACK6 WHERE NAME <> '' FORMAT;
UNLINK STACK6;
LABEL 99;
```

**Sample output:**
```
NAME                                T NUM
----------------------------------- - -------------
KeyGenerator.png                    F  02/10/23 12:45
KeyGeneratorSmall.png               F  12/10/23 08:15
ResumableTransfer.png               F  02/10/23 10:13
```

---

## Activate Priority from External Application

### Open a Record from Hyperlink

```
priority:priform\@FORMNAME:DOCUMENTNUM:COMPANY:TABINIFILE:LANG
```

| Parameter | Description |
|---|---|
| FORMNAME | Entity name (for non-forms, add type suffix: `.P` for procedure, `.R` for report) |
| DOCUMENTNUM | Value of key column (leave blank to just open form) |
| COMPANY | Priority company name |
| TABINIFILE | Name of tabula.ini file |
| LANG | Language ID |

<!-- ADDED START -->
### Common Issues and Solutions

**Authentication Limitations**
The system does not support passing credentials (username and password) directly via URL parameters for the web client. If a user clicks a hyperlink and is not already authenticated in an active session, they will be prompted to log in manually before the record or entity is displayed.

**Opening Specific Records via Web SDK**
When using the Web SDK to open a form filtered to a specific record (similar to the `WINRUN` functionality in the Windows interface), use the `formStartEx` method with the `zoomValue` parameter.
```javascript
// Example: Opening a specific project in the DOCUMENTS_P form
await PrioritySdk.formStartEx(
    'DOCUMENTS_p', 
    this.onShowMessge, 
    null, 
    PRIORITY_LOGIN_CONFIG.profile.company, 
    1,
    { zoomValue: projectNumber, hiddenFields: [] }
);
```

**Hyperlinks in Scheduled Tasks (TTS)**
Hyperlinks generated within reports (e.g., using `WINACTIV`) are currently only active when the report is run manually by a user. If the report is generated and sent via the Task Scheduler (TTS), the hyperlinks will be rendered as plain text and will not be clickable.
<!-- ADDED END -->
### Open from Command Prompt (Windows Only)

```
x:\priority\priform.exe priform\@FORMNAME:DOCUMENTNUM:COMPANY:TABINIFILE:LANG
```
