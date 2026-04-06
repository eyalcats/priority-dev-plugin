/**********************************************************************
 * PRIORITY WEB SDK (JavaScript) EXAMPLES
 * Connection, form operations, procedure execution,
 * report generation, search/filter, and error handling.
 * Source: Priority SDK Documentation + Service Call Analysis
 **********************************************************************/


/*=====================================================================
 * CONNECTION AND INITIALIZATION
 * Configure and connect to Priority via the Web SDK.
 * Ref: SCI2391106, SCI25021422, SCI25057856
 *=====================================================================*/

/* --- Basic connection with username/password --- */
const configuration = {
  url: 'https://your-priority-server.com',     // Web UI URL
  tabulaini: 'tabula.ini',                      // Environment ini file
  language: 3,                                   // 1=Hebrew, 3=English
  profile: {
    company: 'your_company'                      // From Companies form
  }
};

const priority = new Priority(configuration);
await priority.login('username', 'password');


/* --- Connection with Personal Access Token (PAT) --- */
/* Use the token as username and literal "PAT" as password */
/* Ref: SCI25021422 - Token authentication */
const patConfig = {
  url: 'https://your-priority-server.com',
  tabulaini: 'tabMOB.ini',                      // Use tabMOB.ini for PAT
  language: 3,
  profile: {
    company: 'your_company'
  }
};

const priority = new Priority(patConfig);
await priority.login('F35C2690A07E46618272CBBDC6855ADF', 'PAT');


/* --- Private cloud connection --- */
/* For private cloud, use base WCF service path, not AWS URL */
/* Ref: SCI24014560, SCI24016973 */
const privateCloudConfig = {
  url: 'https://server/alias',                   // Base WCF path
  tabulaini: 'tabula.ini',
  language: 3,
  profile: {
    company: 'demo'
  }
};


/*=====================================================================
 * FORM OPERATIONS
 * Open forms, read rows, update fields.
 *=====================================================================*/

/* --- Open a form --- */
const form = await priority.formStart(
  'ORDERS',                // Form name
  onError,                 // Error callback
  onSuccess,               // Success callback
  '',                      // Company (empty = current)
  1                        // Auto-retrieve rows
);

function onError(err) {
  console.error('Form error:', err);
}

function onSuccess(data) {
  console.log('Form success:', data);
}


/* --- Get rows from a form --- */
const rows = await form.getRows(1);  // Start from row 1
console.log(rows);
/* Returns array of form records with all visible columns */


/* --- Update a field value --- */
/* Ref: SCI23133711 - fieldUpdate pattern */
await form.setActiveRow(0);          // Select first row
const result = await form.fieldUpdate('QUANT', '10');
/* After fieldUpdate, the field's POST-FIELD triggers execute */


/* --- Save changes --- */
await form.saveRow(0);


/* --- Open a sub-level form --- */
await form.setActiveRow(0);
const subform = await form.startSubForm(
  'ORDERITEMS',            // Sub-level form name
  onError,
  onSuccess
);


/* --- Close a sub-level form --- */
/* endCurrentForm() on subforms may hang indefinitely in some forms
   (e.g., UPGNOTES). Data IS saved even if close hangs.
   Use Promise.race with a timeout, then close the parent form
   and reopen if needed. */
function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise(resolve => setTimeout(() => resolve({ timedOut: true }), ms)),
  ]);
}

const closeResult = await withTimeout(subform.endCurrentForm(), 8000);
if (closeResult && closeResult.timedOut) {
  // Subform close hung — parent form is stuck in subform mode.
  // Close entire parent form and reopen fresh.
  await withTimeout(form.endCurrentForm(), 5000);
  // Reopen form for further operations (e.g., activateStart)
}


/*=====================================================================
 * SEARCH AND FILTERING
 * Apply filters and search for records.
 * Ref: SCI24025282, SC22097049, SC22026586
 *=====================================================================*/

/* --- Apply a search filter --- */
/* Ref: SC22097049 - getRows after filter */
const filter = {
  or: 0,                   // 0=AND, 1=OR
  ignorecase: 1,           // 1=case insensitive (Ref: SCI24025282)
  QueryValues: [
    {
      field: 'CUSTNAME',
      fromval: '1000',
      toval: '2000',
      op: '0',             // 0=between, 1=equals
      sort: 0,
      isdesc: 0
    }
  ]
};

await form.setSearchFilter(filter);
const filteredRows = await form.getRows(1);
/* If getRows returns undefined, verify filter object structure */


/* --- Clear a filter --- */
await form.clearSearchFilter();


/*=====================================================================
 * PROCEDURE EXECUTION
 * Run procedures and handle step-by-step flow.
 * Ref: SC22127007, SC22039416, SC22027623
 *=====================================================================*/

/* --- Start a procedure --- */
const proc = await priority.procStart(
  'WWWSHOWORDER',          // Procedure name
  'P',                     // Type: P=procedure
  onError,
  onSuccess
);


/* --- Execute procedure with input fields --- */
/* Ref: SCI23123295 - All mandatory fields must be provided */
const inputData = {
  EditFields: [
    { field: 1, op: 0, value: 'PO23000462' },
    { field: 2, op: 0, value: 'לפי מספר ההזמנה' }
    /* Values must match DISPLAY STRING in login language, */
    /* not the internal integer value */
  ]
};

const step = await proc.proc.inputFields(1, inputData);


/*=====================================================================
 * REPORT EXECUTION AND DOCUMENT OUTPUT
 * Generate reports and retrieve output URLs.
 * Ref: SCI25082487, SCI25065817, SCI25059135, SCI2357159
 *=====================================================================*/

/* --- Execute a document procedure and get output URL --- */
/* Ref: SCI2357159 - Get document URL via direct activation */
const form = await priority.formStart(
  'ORDERS', onError, onSuccess, '', 1
);
await form.setActiveRow(0);

/* Start direct activation (document procedure) */
const activation = await form.activateStart(
  'WWWSHOWORDER',          // Direct activation name
  'P',                     // Type
  onError,
  onSuccess
);


/* --- Select report format --- */
/* Ref: SCI25082487 - Report format selection */
/* First, check available formats */
const formats = await proc.proc.reportOptions(0);
/* formats may contain: { id: -101, name: 'Basic' } */

/* Select format by index and ID */
const nextStep = await proc.proc.reportOptions(1, -101);


/* --- Get the display URL --- */
/* Ref: SCI23123295 - displayURL may be undefined if inputs missing */
const docResult = await proc.proc.documentOptions(1);
if (docResult && docResult.displayURL) {
  console.log('Document URL:', docResult.displayURL);
  /* Open or download the document at this URL */
} else {
  console.error('displayURL is undefined - check mandatory input fields');
}


/*=====================================================================
 * ERROR HANDLING
 * Common patterns for handling Web SDK errors.
 *=====================================================================*/

/* --- HTTP 500 from activateStart --- */
/* Ref: SC22027623 - Often fixed by updating bin95 and app server */
try {
  const proc = await form.activateStart('MY_PROC', 'P', onError, onSuccess);
} catch (err) {
  if (err.status === 500) {
    console.error('HTTP 500 - Check bin95 version and app server config');
  }
}


/* --- Connection errors with PAT --- */
/* Ref: SCI25056774 - Avoid special characters in passwords */
/* If login fails, check:
   1. Correct tabulaini (tabula.ini vs tabMOB.ini)
   2. No special characters in password
   3. API module is licensed
   4. If Identity Management is installed, different handling needed
*/


/*=====================================================================
 * FULL WORKFLOW EXAMPLE
 * Open a form, create a record, run a procedure, get PDF output.
 *=====================================================================*/

async function createOrderAndPrint(customerName, partName, quantity) {
  // 1. Open the orders form
  const ordersForm = await priority.formStart(
    'ORDERS', onError, onSuccess, '', 0
  );

  // 2. Create a new row
  await ordersForm.newRow();
  await ordersForm.fieldUpdate('CUSTNAME', customerName);
  await ordersForm.saveRow(0);

  // 3. Open order items sub-form
  const itemsForm = await ordersForm.startSubForm(
    'ORDERITEMS', onError, onSuccess
  );

  // 4. Add an item
  await itemsForm.newRow();
  await itemsForm.fieldUpdate('PARTNAME', partName);
  await itemsForm.fieldUpdate('TQUANT', quantity);
  await itemsForm.saveRow(0);
  await itemsForm.endCurrentForm();

  // 5. Get the order number for printing
  const rows = await ordersForm.getRows(1);
  const ordName = rows[0].ORDNAME;

  // 6. Run the print document procedure
  const printProc = await ordersForm.activateStart(
    'WWWSHOWORDER', 'P', onError, onSuccess
  );

  // 7. Get the PDF output URL
  const doc = await printProc.proc.documentOptions(1);
  if (doc && doc.displayURL) {
    console.log('Order PDF:', doc.displayURL);
  }

  // 8. Clean up
  await ordersForm.endCurrentForm();

  return ordName;
}
