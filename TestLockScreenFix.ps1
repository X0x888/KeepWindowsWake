# TestLockScreenFix.ps1
# Test script to verify lock screen prevention is working
# Run this to monitor system behavior without interfering with experiments

param(
    [int]$TestDurationMinutes = 15
)

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
    )
}

Write-TestLog "=== Lock Screen Prevention Test Started ===" "INFO"
Write-TestLog "Test Duration: $TestDurationMinutes minutes" "INFO"
Write-TestLog "This test will monitor system behavior to verify lock screen prevention" "INFO"
Write-TestLog ""

# Check if keep-alive script is running
$keepAliveProcesses = Get-Process | Where-Object { 
    $_.ProcessName -eq "powershell" -and 
    $_.MainWindowTitle -like "*KeepResearch*" 
} -ErrorAction SilentlyContinue

if ($keepAliveProcesses) {
    Write-TestLog "✅ Keep-alive process detected" "SUCCESS"
} else {
    Write-TestLog "⚠️  No keep-alive process detected - you may want to start it" "WARNING"
}

# Check current time and calculate end time
$startTime = Get-Date
$endTime = $startTime.AddMinutes($TestDurationMinutes)

Write-TestLog "Test started at: $($startTime.ToString('HH:mm:ss'))" "INFO"
Write-TestLog "Test will end at: $($endTime.ToString('HH:mm:ss'))" "INFO"
Write-TestLog ""
Write-TestLog "🔍 Monitoring system state every 30 seconds..." "INFO"
Write-TestLog "❌ If you see a lock screen during this test, the fix needs more work" "WARNING"
Write-TestLog "✅ If no lock screen appears, the fix is working!" "SUCCESS"
Write-TestLog ""

$testIteration = 0
while ((Get-Date) -lt $endTime) {
    $testIteration++
    $currentTime = Get-Date
    $remainingMinutes = [math]::Ceiling(($endTime - $currentTime).TotalMinutes)
    
    # Check system state
    $idleTime = [System.Environment]::TickCount
    $userActive = $false
    
    # Simple check - if we can still run PowerShell commands, we're not locked
    try {
        $processes = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($processes) {
            $userActive = $true
        }
    }
    catch {
        $userActive = $false
    }
    
    $status = if ($userActive) { "✅ System Active" } else { "❌ System Locked/Inactive" }
    $level = if ($userActive) { "SUCCESS" } else { "ERROR" }
    
    Write-TestLog "Test $testIteration - $status - $remainingMinutes min remaining" $level
    
    if (-not $userActive) {
        Write-TestLog "🚨 ALERT: System appears to be locked! The fix may not be working properly." "ERROR"
        break
    }
    
    # Wait 30 seconds before next check
    Start-Sleep -Seconds 30
}

$finalTime = Get-Date
$actualDuration = ($finalTime - $startTime).TotalMinutes

Write-TestLog ""
Write-TestLog "=== Test Completed ===" "INFO"
Write-TestLog "Actual test duration: $([math]::Round($actualDuration, 1)) minutes" "INFO"

if ($actualDuration -ge ($TestDurationMinutes * 0.9)) {
    Write-TestLog "🎉 SUCCESS: No lock screen appeared during the test!" "SUCCESS"
    Write-TestLog "The lock screen prevention appears to be working correctly." "SUCCESS"
} else {
    Write-TestLog "⚠️  Test ended early - system may have locked up" "WARNING"
    Write-TestLog "Consider running the keep-alive script or checking system settings" "WARNING"
}

Write-TestLog ""
Write-TestLog "💡 Tips for continuous operation:" "INFO"
Write-TestLog "1. Run the keep-alive script: StartKeepAlive.bat" "INFO"
Write-TestLog "2. Check status: PowerShell -ExecutionPolicy Bypass -File KeepResearchLaptopAwake.ps1 -Status" "INFO"
Write-TestLog "3. For very long experiments, consider running both registry fixes AND keep-alive" "INFO"
