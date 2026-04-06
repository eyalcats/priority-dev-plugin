#!/bin/bash
# Check if the Priority Claude Bridge VSCode extension is installed.
# If not, install from the bundled VSIX.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
VSIX="$PLUGIN_ROOT/bridge/priority-claude-bridge-1.4.0.vsix"

# Check if extension is already installed
if code --list-extensions 2>/dev/null | grep -qi "priority-claude-bridge"; then
  exit 0
fi

# Extension not found — install if VSIX exists
if [ -f "$VSIX" ]; then
  echo '{"message": "Installing Priority Claude Bridge VSCode extension..."}'
  code --install-extension "$VSIX" --force 2>/dev/null
  if [ $? -eq 0 ]; then
    echo '{"message": "Priority Claude Bridge extension installed. Reload VSCode to activate."}'
  else
    echo '{"message": "Could not auto-install bridge extension. Run: code --install-extension '"$VSIX"'"}'
  fi
else
  echo '{"message": "Priority Claude Bridge extension not found. Install the VSIX from the bridge/ folder manually."}'
fi
