@echo off
REM RunAsAdmin.bat - Batch file to run the PowerShell script as Administrator
REM For 24/7 research laptop operation (Quantum Dot IV Measurements)

echo ============================================
echo Research Laptop Keep-Awake Script Launcher
echo ============================================
echo.
echo This script will configure your laptop for 24/7 research operations.
echo It will prevent sleep mode and automatic updates/restarts.
echo.
echo IMPORTANT: This batch file will request Administrator privileges.
echo.

REM Check if already running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Already running as Administrator.
    goto :run_script
)

echo Requesting Administrator privileges...
echo.

REM Request administrator privileges and run PowerShell script
powershell -Command "Start-Process cmd -ArgumentList '/c cd /d \"%~dp0\" && powershell -ExecutionPolicy Bypass -File \"KeepResearchLaptopAwake.ps1\"' -Verb RunAs"

goto :end

:run_script
echo Running PowerShell script...
powershell -ExecutionPolicy Bypass -File "%~dp0KeepResearchLaptopAwake.ps1"

:end
echo.
echo Script execution completed.
pause
