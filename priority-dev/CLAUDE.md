# Plugin instructions

Plugin-scoped instructions auto-loaded by Claude Code when working inside the priority-dev plugin directory. The full Priority SDK reference lives in `skills/priority-sdk/SKILL.md` and is loaded whenever `/priority-sdk` is invoked.

## Standing rules

### Tool autonomy: never delegate work the bridge can do

If a Priority operation can be performed via `websdk_form_action`, `run_inline_sqli`, `run_windbi_command`, `open_priority_file`, `write_to_editor`, or `refresh_editor` — perform it. Do **not** ask the user to "open a file in VSCode", "run a command in WINDBI", "execute this DBI", "compile this form", "save the file", "check the WINDBI panel", or "paste the code back to me". The bridge exists so you can do these autonomously.

If a tool fails: diagnose the bridge or pick an alternative tool. Do not fall back to manual delegation. See `skills/priority-sdk/references/vscode-bridge-examples.md` § "Intent → tool" for the reverse index.

**Allowed exceptions** — manual delegation IS correct here:

- VSIX install / VSCode reload — admin actions outside the bridge's scope. On Windows, do **not** invoke the `code` CLI from shell (it spawns a new VSCode instance and disrupts the running bridge). Ask the user to install via VSCode's command palette.
- Browser-only auth flows (e.g., FileSmile download on cloud Priority servers).
- `get_current_file` returns `null` — ask the user to open the target file before any work proceeds.
- The user has explicitly asked to do the step themselves.
