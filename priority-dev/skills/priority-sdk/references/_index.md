# Reference index — full-text search patterns

For specific topics in the priority-sdk reference files, search using these patterns. This file is the relocated "Search Patterns" table that used to live at the bottom of SKILL.md — it's loaded only when needed, not on every `/priority-sdk` invocation.

| Topic | Search Pattern | File |
|-------|---------------|------|
| System variables | `SQL.` or `:$` | `references/sql-core.md` |
| Date functions | `ATOD\|DTOA\|DAYS\|ADDDATE` | `references/sql-core.md` |
| String functions | `STRCAT\|SUBSTR\|STRIND\|ITOA` | `references/sql-core.md` |
| Trigger types | `CHECK-FIELD\|POST-FIELD\|PRE-INSERT` | `references/triggers.md` |
| ERRMSG/WRNMSG | `ERRMSG\|WRNMSG` | `references/triggers.md` |
| MAILMSG | `MAILMSG` | `references/triggers.md` |
| WINHTML | `WINHTML\|-d\|-dQ` | `references/documents.md` |
| Interface params | `EXECUTE INTERFACE` | `references/interfaces.md` |
| GENERALLOAD | `GENERALLOAD` | `references/interfaces.md` |
| WSCLIENT | `WSCLIENT` | `references/integrations.md` |
| JSON body for WSCLIENT | `JSON.*body\|ASCII.*BODYFILE\|STRCAT.*JSON` | `references/integrations.md`, `examples/webservice-examples.sql` |
| XMLPARSE | `XMLPARSE\|JSONPARSE` | `references/integrations.md` |
| SFTPCLNT | `SFTPCLNT` | `references/integrations.md` |
| WINAPP / WINRUN / SHELLEX | `WINAPP\|WINRUN\|SHELLEX` | `references/integrations.md` |
| COPYFILE / MOVEFILE / FILELIST / FILTER | `COPYFILE\|MOVEFILE\|FILELIST\|EXECUTE FILTER` | `references/file-operations.md` |
| CRPTUTIL (encryption) | `CRPTUTIL` | `references/file-operations.md` |
| PREXFILE (print attachments) | `PREXFILE` | `references/file-operations.md` |
| Dynamic SQL / Semaphores | `EXECUTE SQLI\|LASTS` | `references/advanced-sqli.md` |
| Run proc/report from SQLI | `ACTIVATF\|WINACTIV\|ACTIVATE` | `references/advanced-sqli.md` |
| Debug | `-trc\|DEBUGSQL\|HEAVYQUERY` | `references/debugging.md` |
| Compile errors (FORMPREPERRS triage) | `parse error at or near symbol ;\|FORM/COL/EXPR\|orphan-expression\|missing-column-ref\|compile-doctor` | `references/compile-debugging.md` |
| Dashboard | `WINHTMLH\|HTMLCURSOR` | `references/web-cloud-dashboards.md` |
| Web SDK | `CORS\|Connection\|PAT\|reportOptions\|getRows\|displayURL` | `references/web-cloud-dashboards.md` |
| HEBCONV | `HEBCONV\|CLR\|hebutils` | `references/sql-core.md` |
| ODBC | `ODBC\|priodbc` | `references/interfaces.md` |
| VSCode bridge | `get_current_file\|write_to_editor\|run_windbi_command` | `references/vscode-bridge-examples.md` |
| WebSDK operations | `websdk_form_action\|startSubForm\|getRows\|fieldUpdate\|EFORM` | `references/websdk-cookbook.md` |
| WebSDK search/filter | `LIKE\|operator\|choose\|setSearchFilter\|clearFilter\|search` | `references/websdk-cookbook.md` |
| Form metadata tables | `FORMCLMNS\|FORMTRIG\|FORMCLTRIGTEXT\|HIDEBOOL\|HIDE` | `references/websdk-cookbook.md` |
| Text subform recipe (6-call) | `Text Subform Creation\|TEXTFORM\|EDES.*LOG\|FCLMNA.*EXPR` | `references/websdk-cookbook.md` |
| Find form internal ID | `Find a form's internal ID\|EXEC FROM EXEC` | `references/websdk-cookbook.md` |
| Copy entity (proc/report/form/interface) | `COPYPROG\|COPYREP\|COPYFORM\|COPYINTER\|WINPROC -P` | `references/procedures.md` |
| Generator-form ENAMEs | `EPROG\|EREP\|EFORM\|EINTER\|Canonical generator-form names` | `references/websdk-cookbook.md` |
| SELECT prints nothing | `Output Formats for SELECT\|FORMAT;\|Execution ok` | `references/sql-core.md`, `references/common-mistakes.md` |
| Unfiltered getRows empty / bridge sees nothing | `Unfiltered .getRows. returns empty\|session or tenant\|Logging in to url` | `references/common-mistakes.md` |
| Subagent hallucinated a result | `Done .0 tool uses\|subagent summary\|unverified` | `references/common-mistakes.md` |
| Upgrade shells / UPGCODE | `UPGCODE\|TAKESINGLEENT\|TAKETRIG\|TAKEFORMCOL\|UPGNOTES\|TAKEUPGRADE\|DOWNLOADUPG\|generate_shell` | `references/deployment.md` |
| Direct activations | `FORMEXEC\|:\$\.PAR\|direct activation\|LINK.*TO.*:\$\.PAR` | `references/procedures.md`, `references/deployment.md` |
| EDI internals | `INTERFORMS\|INTERCLMNSFILE\|EINTER\|INTERFACE.*-form` | `references/interfaces.md` |
| Known bridge behaviors | `QueryValues\|setSearchFilter\|runSqliFile\|FORMCLTRIGTEXT.*append\|FCLMNA.*scalar` | `references/websdk-cookbook.md` |
| Anti-patterns / why doesn't X work | `Wrong:\|Right:\|See:\|common mistake` | `references/common-mistakes.md` |
| MCP tools | `priority-dev\|priority-gateway\|bridge` | `references/debugging.md`, `references/vscode-bridge-examples.md` |
| Scaffold | `createFormTrigger\|createProcedureStep` | `references/vscode-bridge-examples.md` |
