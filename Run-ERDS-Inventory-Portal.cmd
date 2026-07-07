@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-ERDS-Inventory-Portal.ps1" %*
endlocal
