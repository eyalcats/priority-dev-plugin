#!/bin/bash
# Check if the Priority Claude Bridge VSCode extension is installed.
# If not, install from the bundled VSIX — without launching VSCode windows.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
VSIX="$PLUGIN_ROOT/bridge/priority-claude-bridge-1.5.0.vsix"

# Check multiple possible extension directories (avoid `code` CLI which opens windows)
for EXT_DIR in \
  "${HOME}/.vscode/extensions" \
  "${USERPROFILE}/.vscode/extensions" \
  "${APPDATA}/Code/User/extensions" \
  "${LOCALAPPDATA}/Programs/Microsoft VS Code/extensions"; do
  if [ -d "$EXT_DIR" ] && ls "$EXT_DIR" 2>/dev/null | grep -qi "priority-claude-bridge"; then
    exit 0
  fi
done

# Extension not found — notify but do NOT run `code` CLI (it opens windows)
if [ -f "$VSIX" ]; then
  echo '{"message": "Priority Claude Bridge extension not detected. Install manually: code --install-extension '"$VSIX"'"}'
else
  echo '{"message": "Priority Claude Bridge extension not found. Install the VSIX from the bridge/ folder manually."}'
fi
