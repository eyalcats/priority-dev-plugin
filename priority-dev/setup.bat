@echo off
echo === Priority Dev Plugin Setup ===
echo.

REM Step 1: Add marketplace
echo [1/3] Adding marketplace...
call claude plugin marketplace add eyalcats/priority-dev-plugin
if errorlevel 1 (
    echo WARNING: Marketplace add failed. It may already be added.
)
echo.

REM Step 2: Install plugin
echo [2/3] Installing plugin...
call claude plugin install priority-dev
if errorlevel 1 (
    echo WARNING: Plugin install failed. It may already be installed.
    echo Try: claude plugin update priority-dev
)
echo.

REM Step 3: Install VSCode bridge extension
echo [3/3] Installing VSCode bridge extension...
set "PLUGIN_DIR=%USERPROFILE%\.claude\plugins\priority-dev"
if not exist "%PLUGIN_DIR%\bridge\priority-claude-bridge-1.5.0.vsix" (
    echo ERROR: VSIX not found at %PLUGIN_DIR%\bridge\
    echo Make sure plugin install completed successfully.
    pause
    exit /b 1
)
code --install-extension "%PLUGIN_DIR%\bridge\priority-claude-bridge-1.5.0.vsix"
echo.

echo === Setup complete! ===
echo Restart VSCode to activate the bridge extension.
pause
