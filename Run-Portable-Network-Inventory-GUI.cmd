@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER_PATH=%SCRIPT_DIR%scripts\ERDS-Toolbox-Launcher.ps1"

if not exist "%LAUNCHER_PATH%" (
    echo Script not found:
    echo %LAUNCHER_PATH%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%LAUNCHER_PATH%"
endlocal
