# Priority Dev Plugin — Installation

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed
- [VSCode](https://code.visualstudio.com/) installed

## Quick Install (Windows)

Download and run `setup.bat`, or paste these commands into a terminal:

```
claude plugin marketplace add eyalcats/priority-dev-plugin
claude plugin install priority-dev
code --install-extension "%USERPROFILE%\.claude\plugins\priority-dev\bridge\priority-claude-bridge-1.5.0.vsix"
```

Restart VSCode after installation.

## Manual Install

1. Add the plugin marketplace:
   ```
   claude plugin marketplace add eyalcats/priority-dev-plugin
   ```

2. Install the plugin:
   ```
   claude plugin install priority-dev
   ```

3. Install the VSCode bridge extension:
   ```
   code --install-extension "%USERPROFILE%\.claude\plugins\priority-dev\bridge\priority-claude-bridge-1.5.0.vsix"
   ```

4. Restart VSCode.

## Updating

```
claude plugin update priority-dev
code --install-extension "%USERPROFILE%\.claude\plugins\priority-dev\bridge\priority-claude-bridge-1.5.0.vsix"
```

## Verify

1. Open VSCode — you should see "Priority Claude Bridge" in the status bar
2. Start a Claude Code session — the plugin skill and agents should be available
