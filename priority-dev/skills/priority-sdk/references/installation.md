# Installation Guide

## Prerequisites

- **VSCode** with the [Priority Dev Tools extension](https://marketplace.visualstudio.com/items?itemName=PrioritySoftware.priority-vscode) installed and at least one environment configured
- **Claude Code** CLI installed

## Install the Plugin

```bash
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
```

That's it. On first session start, the plugin will:
1. Auto-install the Priority Claude Bridge VSCode extension (if not already installed)
2. Configure the MCP connection to the bridge
3. Check for credentials — if the Priority Dev Tools extension has an environment configured, no additional setup is needed

## Verify

1. Reload VSCode (`Ctrl+Shift+P` > `Developer: Reload Window`)
2. Open a Priority file from the Environments Explorer
3. Start Claude Code and ask: `List the Priority bridge tools available`

## Manual Credential Setup (only if Priority Dev Tools extension is not installed)

Add to VSCode settings (`Ctrl+,`):
```json
{
  "priorityClaudeBridge.serverUrl": "https://your-server",
  "priorityClaudeBridge.company": "your-company",
  "priorityClaudeBridge.username": "your-user",
  "priorityClaudeBridge.password": "your-password",
  "priorityClaudeBridge.tabulaini": "tabula.ini"
}
```
