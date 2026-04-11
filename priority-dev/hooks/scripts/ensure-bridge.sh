#!/bin/bash
# Check if the Priority Claude Bridge VSCode extension is installed.
# If not, auto-install the bundled VSIX via `code --install-extension --force`.
# With --force, the CLI does NOT open a new VSCode window.

set -e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"

# Pick the most recently modified VSIX in bridge/ (version-agnostic)
VSIX=""
for candidate in "$PLUGIN_ROOT/bridge/"priority-claude-bridge-*.vsix; do
  if [ -f "$candidate" ]; then
    if [ -z "$VSIX" ] || [ "$candidate" -nt "$VSIX" ]; then
      VSIX="$candidate"
    fi
  fi
done

# Already installed? (check common extension directories)
for EXT_DIR in \
  "${HOME}/.vscode/extensions" \
  "${USERPROFILE}/.vscode/extensions" \
  "${APPDATA}/Code/User/extensions" \
  "${LOCALAPPDATA}/Programs/Microsoft VS Code/extensions"; do
  if [ -d "$EXT_DIR" ] && ls "$EXT_DIR" 2>/dev/null | grep -qi "priority-claude-bridge"; then
    # Extension is installed. Check if the shipped VSIX is newer than any installed version.
    if [ -n "$VSIX" ]; then
      VSIX_NAME=$(basename "$VSIX")
      VSIX_VERSION=$(echo "$VSIX_NAME" | sed -E 's/^priority-claude-bridge-([0-9.]+)\.vsix$/\1/')
      INSTALLED_VERSION=$(ls "$EXT_DIR" 2>/dev/null | grep -i "priority-claude-bridge" | sed -E 's/.*priority-claude-bridge-([0-9.]+).*/\1/' | sort -V | tail -1)
      if [ -n "$VSIX_VERSION" ] && [ -n "$INSTALLED_VERSION" ] && [ "$VSIX_VERSION" != "$INSTALLED_VERSION" ]; then
        # Newer VSIX shipped — upgrade in place
        if command -v code >/dev/null 2>&1; then
          code --install-extension "$VSIX" --force >/dev/null 2>&1 || true
          echo '{"message": "Priority Claude Bridge updated to '"$VSIX_VERSION"'. Reload VSCode window to activate."}'
        fi
      fi
    fi
    exit 0
  fi
done

# Not installed — auto-install
if [ -z "$VSIX" ]; then
  echo '{"message": "Priority Claude Bridge VSIX not found in plugin/bridge/. Cannot auto-install."}'
  exit 0
fi

if command -v code >/dev/null 2>&1; then
  code --install-extension "$VSIX" --force >/dev/null 2>&1 && \
    echo '{"message": "Priority Claude Bridge installed. Reload VSCode window (Ctrl+Shift+P → Developer: Reload Window) to activate, then click the status bar item to set up licensing."}' || \
    echo '{"message": "Priority Claude Bridge auto-install failed. Install manually: code --install-extension '"$VSIX"'"}'
else
  echo '{"message": "Priority Claude Bridge not installed and `code` CLI not found on PATH. Install manually via VSCode: Ctrl+Shift+P → Extensions: Install from VSIX → '"$VSIX"'"}'
fi
