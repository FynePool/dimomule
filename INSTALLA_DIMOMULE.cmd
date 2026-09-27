@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Avvio installazione Dimomule 1.0...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_support\install.ps1"
echo.
pause
