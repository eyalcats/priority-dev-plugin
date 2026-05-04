# Pattern-Mining Recipes

Reusable SQL recipes for finding canonical shapes in the live Priority
metadata. Populated by the form-harvest team's Curator when its
Phase 3 sideways queries prove useful, and directly usable by
`researcher` Mode 2 / Mode 3 and by developers debugging Priority.

Each recipe names: (a) what it finds, (b) the SQL, (c) the columns to
read from the result, (d) caveats.

## Recipe categories

- **Trigger shapes** — find forms exhibiting a given trigger pattern
- **Column shapes** — find column configurations (joins, hides, expressions)
- **Subform/link shapes** — find parent/child link idioms
- **Activation shapes** — find FORMEXEC patterns pointing at procedures
- **Interface shapes** — find INTERFACE call-site patterns

## Trigger shapes

### R-TRIG-01: Forms that load system/log/fnc constants in PRE-FORM

Finds forms pulling runtime constants from `SYSCONST` / `LOGCONST` /
`FNCCONST` — a canonical PRE-FORM idiom for tenant-tunable behaviour.

```sql
SELECT DISTINCT E.ENAME
FROM FORMTRIGTEXT FT, EXEC E
WHERE FT.FORM = E.EXEC
  AND FT.TEXT LIKE '%SELECT VALUE INTO %FROM SYSCONST%'
FORMAT;
```

Variants: swap `SYSCONST` for `LOGCONST` or `FNCCONST`. Read: `ENAME`.

### R-TRIG-02: Forms that pre-resolve target-form EXEC ids

Finds PRE-FORM triggers using the `SELECT EXEC INTO :VAR FROM EXEC
WHERE ENAME = '…' AND TYPE = 'F'` pattern that powers dynamic ZOOM
(see `forms.md` § "Dynamic Access (ZOOM1 pattern)").

```sql
SELECT DISTINCT E.ENAME
FROM FORMTRIGTEXT FT, EXEC E
WHERE FT.FORM = E.EXEC
  AND FT.TEXT LIKE '%SELECT EXEC INTO %FROM EXEC WHERE ENAME%'
FORMAT;
```

Read: `ENAME`. Combine with `LOGFILE`-style ternary inspection on the
`ZOOM1` column's `FCLMNA.EXPR` to confirm the target form is using the
variables as zoom resolvers, not for another purpose.

### R-TRIG-03: Forms that gate warnings via :INTERFACEIGNOREWARNINGS

Finds row triggers that wrap warning-only checks behind
`GOTO N WHERE :INTERFACEIGNOREWARNINGS = 1;` — the INTERFACE-safe
pattern.

```sql
SELECT DISTINCT E.ENAME
FROM FORMTRIGTEXT FT, EXEC E
WHERE FT.FORM = E.EXEC
  AND FT.TEXT LIKE '%:INTERFACEIGNOREWARNINGS%'
FORMAT;
```

Read: `ENAME`. Use as a reference list when adding a new warning to a
transaction form — new warnings usually belong inside the same gate so
batch loads don't trip.

### R-TRIG-04: Forms that queue procedures from a row trigger

Finds POST-INSERT / POST-UPDATE bodies that dispatch a procedure via
`EXECUTE WINACTIV '-P'` against a SQL.TMPFILE snapshot of the current
row (async fire-and-continue pattern).

```sql
SELECT DISTINCT E.ENAME
FROM FORMTRIGTEXT FT, EXEC E
WHERE FT.FORM = E.EXEC
  AND FT.TEXT LIKE '%EXECUTE WINACTIV%-P%'
FORMAT;
```

Read: `ENAME`. For server-side (web) equivalent, swap `WINACTIV` for
`ACTIVATF` in the query to find the web-safe variants.

### R-TRIG-05: Forms pulling the dynamic-ZOOM boilerplate include

```sql
SELECT DISTINCT E.ENAME
FROM FORMTRIGTEXT FT, EXEC E
WHERE FT.FORM = E.EXEC
  AND FT.TEXT LIKE '%#INCLUDE FNCTRANS/PRE-FORM%'
FORMAT;
```

Read: `ENAME`. Any form in the result set already handles dynamic zoom
via the shared `FNCTRANS/PRE-FORM` body — do not hand-roll EXEC
resolvers on these, just include the same line.

## Column shapes

### R-COL-01: Hidden join-picker columns

Find columns that pair `JOIN > 0` with `HIDE = 'Y'` — the canonical
"hidden FK picker" shape.

```sql
SELECT FORM, NAME, IDCOLUMN, IDJOIN, JOIN
FROM   FORMCLMNS
WHERE  JOIN > 0 AND HIDE = 'Y'
ORDER BY FORM
FORMAT;
```

Read: `FORM` (citing form), `NAME` (column name). Use with `researcher`
Mode 2 when the builder needs the canonical picker shape.

### R-COL-02: FCLMNA.EXPR foreign-table lookup bodies

Find expression columns that drive foreign-table lookups via the
`<TABLE> WHERE <key> = :$.<fk>` shape (no `SELECT`, no `FROM`).

```sql
SELECT DISTINCT E.ENAME, C.NAME, A.EXPR
FROM FORMCLMNSA A, FORMCLMNS C, EXEC E
WHERE A.FORM = C.FORM AND A.NAME = C.NAME
  AND A.FORM = E.EXEC
  AND C.EXPRESSION = 'Y'
  AND A.EXPR LIKE '% WHERE % =%'
  AND A.EXPR NOT LIKE '%SELECT%'
  AND A.EXPR NOT LIKE '%FROM%'
FORMAT;
```

Read: `ENAME` (form), `NAME` (column), `EXPR` (body). The EXPR bodies
are the canonical one-liner lookup shape — copy one and swap the table
name / FK column names to match the target form.

### R-COL-03: Forms with expression+readonly-M display columns

```sql
SELECT DISTINCT E.ENAME
FROM FORMCLMNS C, EXEC E
WHERE C.FORM = E.EXEC
  AND C.EXPRESSION = 'Y'
  AND C.READONLY = 'M'
FORMAT;
```

Read: `ENAME`. Use as a list of forms that follow the computed-display
convention (modify-only, computed at save).

## Subform/link shapes

*(none yet — populated by harvest runs)*

## Activation shapes

*(none yet — populated by harvest runs)*

## Interface shapes

*(none yet — populated by harvest runs)*

## Tooling note — always append `FORMAT`

`run_inline_sqli` returns row data only when the SELECT ends with
`FORMAT`, `TABS`, or `DATA`. Without an output clause, Priority executes
the SELECT and discards rows, leaving the bridge envelope showing only
"Execution ok". This is covered in `common-mistakes.md` § "SELECT via
run_inline_sqli prints no rows" — and is the #1 cause of Scout
under-harvest runs.

## Discovery Tools

### Table Generator Built-in Dictionaries

The Tables Generator (System Management > Generators > Tables) provides read-only dictionaries and reports for inspecting existing tables without running DBI or WINDBI queries:

| Name | Description |
|------|-------------|
| **Table Dictionary** | Lists all tables in the database; sub-levels show columns, keys, and key columns |
| **Column Dictionary** | Displays attributes of all table columns across the database |
| **Columns per Table** | Report listing all columns for each table |
| **Keys per Table** | Report listing all keys for each table |

*(seen in: handbook:Tables@page-36)*

### SQL Interpreter Analysis Flags

In the SQL Development (WINDBI) program (System Management > Generators > Procedures), run the SQL Interpreter (Execute > SQL interpreter). Prefix a query with these flags to get execution plans:

| Flag | Output |
|------|--------|
| `+ optimizer` | Displays the steps of data retrieval |
| `+ execution` | Displays retrieval steps AND number of records retrieved at each step |

These are equivalent to query-plan / explain-analyze in standard SQL databases and are useful for diagnosing slow queries.

**Permission required:** The `Authorized for SQL` column in the Personnel File (Human Resources menu) must be enabled for the user. `INSERT`/`UPDATE`/`DELETE` additionally require the **tabula** superuser group.

*(seen in: handbook:Tables@page-43)*

## Tooling note — `:$` tokens inside LIKE patterns

SQLI parses `:$` as a form-column variable reference, so `LIKE '%:$.FOO%'`
fires "Value missing for parameter" errors at bind time. Workarounds:
keep the `:$` token out of the pattern (use `LIKE '%WHERE % =%'` to
find the general shape, then filter manually), or build the literal via
a cursor variable assigned from a `SELECT` that does not appear in
`WHERE`. `STRCAT` does not work as a top-level expression in SELECT
either — it produces `parse error at or near symbol STRCAT`.
