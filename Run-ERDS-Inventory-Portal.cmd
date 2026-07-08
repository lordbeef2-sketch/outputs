@echo off
setlocal
if /I "%~1"=="publish" (
  shift
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Publish-ERDS-Inventory-Portal.ps1" %*
) else (
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-ERDS-Inventory-Portal.ps1" %*
)
endlocal
