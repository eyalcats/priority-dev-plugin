# Priority Dev Plugin — Installation

## Prerequisites

- [Claude Code CLI](https://claude.ai/code)
- [VSCode](https://code.visualstudio.com/)
- Recommended: [Priority Dev Tools](https://marketplace.visualstudio.com/items?itemName=PrioritySoftware.priority-vscode) with one Priority environment configured. The bridge reads those credentials directly.

## Quick install

```
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

Open the project in VSCode and start Claude Code in the integrated terminal:

```
claude
```

The `ensure-bridge.sh` hook runs on session start and installs the bridge VSIX via `code --install-extension`. When it finishes, reload VSCode:

1. `Ctrl+Shift+P` → `Developer: Reload Window`
2. The status bar shows **⚠ Priority Bridge** — the bridge is installed but unlicensed
3. A toast prompts you to click the status bar item
4. Click it (or run `Priority Bridge: Setup` from the command palette)

## License activation

The Setup quick-pick offers:

- **Copy Machine ID** — copies the machine ID to the clipboard
- **Request License…** — opens your email client with machine ID and requested expiry pre-filled
- **Paste License JSON** — paste the one-line license your admin sent
- **Load License File…** — pick a `license.json` from disk
- **Install Priority Dev Claude Code Plugin** — appears when the plugin is missing

### Typical flow

1. Click **Request License…** and send the pre-filled email to your admin
2. Admin runs `node tools/generate-license.js --machine-id YOUR_ID --expires 2027-MM-DD` and replies with the one-line JSON
3. Click **Paste License JSON**, paste the line, and the bridge activates
4. Status bar shows **✓ Priority Bridge — expires YYYY-MM-DD**

To pre-fill the admin address, set `priorityClaudeBridge.licenseAdminEmail` in VSCode settings.

## Updating

```
claude plugin update priority-dev@priority-dev-marketplace
```

On the next Claude Code session, `ensure-bridge.sh` detects the newer VSIX and upgrades the extension. Reload the window once to activate.

> **Use `claude plugin update` for upgrades.** `claude plugin marketplace add` is a no-op once the marketplace is registered — it prints *"already declared in user settings"* and keeps the stale local clone, so `claude plugin install` then reinstalls the old version. If `update` still won't pull the latest, reset the marketplace (below).

### Full marketplace reset

If `claude plugin update` stays on an old version, the local clone is pinned. Wipe it and re-add:

```powershell
# PowerShell
claude plugin marketplace remove priority-dev-marketplace
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\marketplaces\priority-dev-marketplace" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\plugins\cache\priority-dev-marketplace" -ErrorAction SilentlyContinue
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

```bash
# macOS / Linux
claude plugin marketplace remove priority-dev-marketplace
rm -rf ~/.claude/plugins/marketplaces/priority-dev-marketplace
rm -rf ~/.claude/plugins/cache/priority-dev-marketplace
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

Start a fresh `claude` session in VSCode and reload the window once the bridge auto-install finishes.

## Manual install (fallback)

If the auto-install hook fails — missing extraction tools, a locked directory, and so on — install the VSIX by hand:

1. `Ctrl+Shift+P` → `Extensions: Install from VSIX…`
2. Open `%USERPROFILE%\.claude\plugins\cache\priority-dev-marketplace\priority-dev\<version>\bridge\` and pick the `.vsix` file (for example, `1.6.4`)
3. Reload VSCode

## Verify

1. Status bar shows **✓ Priority Bridge — expires YYYY-MM-DD**
2. Open a Priority entity from the Priority Dev Tools Environments Explorer
3. In the Claude Code session, ask: `list the Priority bridge tools available`

Expected tools: `get_current_file`, `write_to_editor`, `refresh_editor`, `run_windbi_command`, `websdk_form_action`, `run_inline_sqli`.
