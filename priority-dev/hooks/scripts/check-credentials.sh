#!/bin/bash
# Check if Priority credentials are configured in VSCode settings.
# The bridge reads from priority.environments (Priority extension) first,
# then falls back to priorityClaudeBridge.* settings.

# Determine VSCode settings path
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  VSCODE_SETTINGS="$APPDATA/Code/User/settings.json"
else
  VSCODE_SETTINGS="${HOME}/.config/Code/User/settings.json"
  [[ "$OSTYPE" == "darwin"* ]] && VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
fi

if [ ! -f "$VSCODE_SETTINGS" ]; then
  echo '{"message": "Priority credentials not configured. Install the Priority VSCode extension and add an environment, or set priorityClaudeBridge.* settings manually."}'
  exit 0
fi

# If the Priority extension has environments configured, we're good
if grep -q "priority.environments" "$VSCODE_SETTINGS" 2>/dev/null; then
  exit 0
fi

# Also accept bridge-specific settings as fallback
if grep -q "priorityClaudeBridge.serverUrl" "$VSCODE_SETTINGS" 2>/dev/null; then
  exit 0
fi

echo '{"message": "Priority credentials not configured. Either:\n  1. Install the Priority VSCode extension and add an environment (recommended), or\n  2. Add to VSCode settings: priorityClaudeBridge.serverUrl, .company, .username, .password"}'
