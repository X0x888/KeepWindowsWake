@echo off
REM StartKeepAlive.bat - Batch file to run continuous keep-alive mode
REM For maintaining 24/7 research laptop operation during measurements

echo ============================================
echo Research Laptop Continuous Keep-Alive Mode
echo ============================================
echo.
echo This will start continuous keep-alive mode to prevent sleep
echo during long-running IV measurements.
echo.
echo The script will:
echo - Simulate minimal user activity every 5 minutes
echo - Log status every hour
echo - Run until you press Ctrl+C
echo.
echo Press any key to start keep-alive mode...
pause >nul

REM Check if already running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running keep-alive mode as Administrator...
    goto :run_keepalive
)

echo Requesting Administrator privileges for keep-alive mode...
powershell -Command "Start-Process cmd -ArgumentList '/c cd /d \"%~dp0\" && powershell -ExecutionPolicy Bypass -File \"KeepResearchLaptopAwake.ps1\" -KeepAlive' -Verb RunAs"
goto :end

:run_keepalive
powershell -ExecutionPolicy Bypass -File "%~dp0KeepResearchLaptopAwake.ps1" -KeepAlive

:end
echo.
echo Keep-alive mode ended.
pause
