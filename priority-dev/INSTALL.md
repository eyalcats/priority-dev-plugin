# Priority Dev Plugin — Installation

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed
- [VSCode](https://code.visualstudio.com/) installed
- (Recommended) [Priority Dev Tools](https://marketplace.visualstudio.com/items?itemName=PrioritySoftware.priority-vscode) VSCode extension with at least one Priority environment configured — the bridge reads its credentials from there automatically

## Quick install

```
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

Then **open the project in VSCode and start a Claude Code session inside the integrated terminal**:

```
claude
```

On session start, the plugin's `ensure-bridge.sh` hook auto-installs the Priority Claude Bridge VSCode extension from the bundled VSIX via `code --install-extension`. You'll see a message telling you to reload the VSCode window.

1. `Ctrl+Shift+P` → `Developer: Reload Window`
2. After reload, the status bar shows **⚠ Priority Bridge** (not yet licensed)
3. A one-time info toast appears: *"Click the Priority Bridge item in the status bar to set up."*
4. Click the status bar item (or run `Priority Bridge: Setup` from the command palette)

## License activation

The Setup quick-pick shows these options:

- **Copy Machine ID** — copies your per-machine ID to clipboard
- **Request License…** — opens your default email client with a pre-filled request (machine ID + requested expiry already in the body)
- **Paste License JSON** — paste the one-line license blob your admin sent you
- **Load License File…** — pick a `license.json` file from disk
- **Install Priority Dev Claude Code Plugin** — only shown if the Claude Code plugin is not already installed

### Typical flow

1. Click **Request License…** → your email client opens with everything ready → send to your admin
2. Admin runs `node tools/generate-license.js --machine-id YOUR_ID --expires 2027-MM-DD` in the plugin repo. The generator prints a one-line JSON blob that fits in a chat message or email body
3. Admin replies with the one-line JSON
4. You click **Paste License JSON** → paste the line → bridge activates
5. Status bar now shows **✓ Priority Bridge — expires YYYY-MM-DD**

You can also set `priorityClaudeBridge.licenseAdminEmail` in VSCode settings so the mailto pre-fills the recipient too.

## Updating

```
claude plugin update priority-dev@priority-dev-marketplace
```

On the next Claude Code session, `ensure-bridge.sh` detects the newer VSIX shipped with the plugin and auto-upgrades the installed extension. Reload the window once to activate. No manual file dialog needed.

> **Important: `claude plugin marketplace add` does NOT refresh an existing marketplace.** If you already added `eyalcats/priority-dev-plugin` before, running `marketplace add` again is a no-op — Claude Code says *"already declared in user settings"* and keeps the stale local clone. `claude plugin install` will then pull the old version from that stale clone. **Always use `claude plugin update`** for upgrades, or do a full marketplace reset (see below).

### Full marketplace reset (when updates don't pull the latest)

If `claude plugin update` doesn't bring you to the latest version — usually because the local marketplace clone is pinned and the update mechanism isn't re-fetching — wipe the local clone and re-add:

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

Then start a fresh `claude` session in VSCode and reload the window when the bridge auto-install finishes.

## Manual install (fallback)

If the auto-install hook doesn't run (extraction tools missing, locked directory, etc.), install the VSIX manually:

1. `Ctrl+Shift+P` → `Extensions: Install from VSIX…`
2. Navigate to `%USERPROFILE%\.claude\plugins\cache\priority-dev-marketplace\priority-dev\<version>\bridge\` and pick the only `.vsix` file in there (replace `<version>` with the latest installed — e.g., `1.6.4`)
3. Reload VSCode

## Verify

1. Status bar shows **✓ Priority Bridge — expires YYYY-MM-DD**
2. Open any Priority entity file from the Priority Dev Tools extension's Environments Explorer
3. In the Claude Code session, ask: `list the Priority bridge tools available`

You should see: `get_current_file`, `write_to_editor`, `refresh_editor`, `run_windbi_command`, `websdk_form_action`, `run_inline_sqli`.
