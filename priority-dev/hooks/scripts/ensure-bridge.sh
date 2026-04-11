#!/bin/bash
# Ensure the Priority Claude Bridge VSCode extension is installed at the
# version shipped with this plugin.
#
# Install strategy: extract the bundled VSIX directly into VSCode's
# extensions directory. A VSIX is just a zip archive containing an
# `extension/` folder; we strip that prefix and drop the contents into
# ~/.vscode/extensions/priority-software.priority-claude-bridge-<version>/.
#
# Why not `code --install-extension`? On Windows the `code` CLI wrapper
# opens a new VSCode window (even with --force) and doesn't reliably
# install into the primary window's extension store from inside an
# integrated terminal. Direct extraction is silent and cross-platform.
#
# Requires: tar (available on Windows 10 1803+, macOS, Linux).

set -e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"

# --- 1. Find the VSIX shipped with this plugin ---
VSIX=""
for candidate in "$PLUGIN_ROOT/bridge/"priority-claude-bridge-*.vsix; do
  if [ -f "$candidate" ]; then
    if [ -z "$VSIX" ] || [ "$candidate" -nt "$VSIX" ]; then
      VSIX="$candidate"
    fi
  fi
done

if [ -z "$VSIX" ]; then
  echo '{"message": "Priority Claude Bridge VSIX not found in plugin/bridge/. Cannot auto-install."}'
  exit 0
fi

VSIX_NAME=$(basename "$VSIX")
VSIX_VERSION=$(echo "$VSIX_NAME" | sed -E 's/^priority-claude-bridge-([0-9.]+)\.vsix$/\1/')
TARGET_NAME="priority-software.priority-claude-bridge-$VSIX_VERSION"

# --- 2. Locate VSCode's extensions directory ---
EXT_DIR=""
for candidate in \
  "${HOME}/.vscode/extensions" \
  "${USERPROFILE}/.vscode/extensions"; do
  if [ -d "$candidate" ]; then
    EXT_DIR="$candidate"
    break
  fi
done

if [ -z "$EXT_DIR" ]; then
  echo '{"message": "VSCode extensions directory not found. Install Priority Claude Bridge manually via Ctrl+Shift+P -> Extensions: Install from VSIX."}'
  exit 0
fi

# --- 3. Check what's currently installed ---
EXISTING=""
for candidate in "$EXT_DIR/"priority-software.priority-claude-bridge-*; do
  if [ -d "$candidate" ]; then
    EXISTING="$candidate"
    break
  fi
done

if [ -n "$EXISTING" ]; then
  EXISTING_VERSION=$(basename "$EXISTING" | sed -E 's/^priority-software\.priority-claude-bridge-(.*)$/\1/')
  if [ "$EXISTING_VERSION" = "$VSIX_VERSION" ]; then
    # Same version, nothing to do
    exit 0
  fi
  # Different version - remove old and fall through to install new
  rm -rf "$EXISTING" 2>/dev/null || {
    echo '{"message": "Priority Claude Bridge upgrade blocked - could not remove old version at '"$EXISTING"'. Reload VSCode and retry."}'
    exit 0
  }
fi

# --- 4. Extract VSIX directly into the extensions directory ---
TARGET_DIR="$EXT_DIR/$TARGET_NAME"
mkdir -p "$TARGET_DIR"

# tar with --strip-components=1 extracts only the extension/ folder contents
# (a VSIX is a zip with [Content_Types].xml, extension.vsixmanifest, and extension/ at root)
if tar -xf "$VSIX" -C "$TARGET_DIR" --strip-components=1 extension 2>/dev/null; then
  if [ -z "$EXISTING" ]; then
    echo '{"message": "Priority Claude Bridge '"$VSIX_VERSION"' installed. Reload VSCode window (Ctrl+Shift+P -> Developer: Reload Window) to activate, then click the status bar item to set up licensing."}'
  else
    echo '{"message": "Priority Claude Bridge upgraded to '"$VSIX_VERSION"'. Reload VSCode window (Ctrl+Shift+P -> Developer: Reload Window) to activate."}'
  fi
  exit 0
fi

# --- 5. tar failed — cleanup and report ---
rm -rf "$TARGET_DIR" 2>/dev/null

# Fallback: try unzip (present in Git Bash, some Linux distros)
if command -v unzip >/dev/null 2>&1; then
  TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t pcb)
  if [ -n "$TEMP_DIR" ] && unzip -q "$VSIX" -d "$TEMP_DIR" 2>/dev/null; then
    mkdir -p "$TARGET_DIR"
    cp -r "$TEMP_DIR/extension/." "$TARGET_DIR/" 2>/dev/null && {
      rm -rf "$TEMP_DIR"
      echo '{"message": "Priority Claude Bridge '"$VSIX_VERSION"' installed via unzip fallback. Reload VSCode window to activate."}'
      exit 0
    }
    rm -rf "$TEMP_DIR"
  fi
fi

# All auto-install methods failed
echo '{"message": "Priority Claude Bridge auto-install failed (tar and unzip both unavailable or errored). Install manually via Ctrl+Shift+P -> Extensions: Install from VSIX -> '"$VSIX"'"}'
