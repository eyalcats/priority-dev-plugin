# Priority Dev Plugin — Installation

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed
- [VSCode](https://code.visualstudio.com/) installed

## Quick Install (Windows)

Run these commands in PowerShell or Command Prompt:

```
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

Then install the VSCode bridge extension. In VSCode:

1. Press `Ctrl+Shift+P` → type "Extensions: Install from VSIX..."
2. Browse to `%USERPROFILE%\.claude\plugins\priority-dev\bridge\priority-claude-bridge-1.5.0.vsix`
3. Reload VSCode

## Licensing

The bridge requires a license to run. On first launch after installing the VSIX:

1. VSCode shows an error popup with two buttons: **"Load License"** and **"Copy Machine ID"**
2. Click **"Copy Machine ID"** — sends the ID to your clipboard
3. Send the machine ID + your email to the plugin admin
4. Admin generates a `license.json` file and sends it to you
5. Click **"Load License"** (or run `Ctrl+Shift+P` → "Extensions: Install from VSIX..." and reinstall to see the popup again) → select the `license.json` file
6. The bridge activates immediately — status bar shows "Priority Bridge"

No manual folder creation needed. The license persists across extension updates.

## Updating

```
claude plugin update priority-dev@priority-dev-marketplace
```

Then reinstall the VSIX in VSCode:

1. `Ctrl+Shift+P` → "Extensions: Install from VSIX..."
2. Browse to `%USERPROFILE%\.claude\plugins\priority-dev\bridge\priority-claude-bridge-1.5.0.vsix`
3. Reload VSCode

## Verify

1. Open VSCode — status bar shows "Priority Bridge" (licensed) or machine ID (unlicensed)
2. Start a Claude Code session — the plugin skill and agents should be available
