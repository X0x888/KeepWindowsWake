# DiagnoseLockScreenIssue.ps1
# Diagnostic script to identify why lock screen is still appearing
# Run this to get detailed information about current system state

# Function to log messages with timestamps
function Write-DiagLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "CRITICAL" { "Magenta" }
            default { "White" }
        }
    )
}

Write-DiagLog "=== Lock Screen Issue Diagnosis ===" "INFO"
Write-DiagLog "This will check all settings that could cause lock screen to appear" "INFO"
Write-DiagLog ""

# Check if running as Administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-DiagLog "Running as Administrator: $(if ($isAdmin) { 'Yes' } else { 'No - This may cause issues!' })" $(if ($isAdmin) { "SUCCESS" } else { "WARNING" })
Write-DiagLog ""

# 1. Check Power Settings
Write-DiagLog "=== POWER SETTINGS ===" "INFO"
try {
    $acSleep = & powercfg /Q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current AC Power Setting Index"
    $dcSleep = & powercfg /Q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current DC Power Setting Index"
    
    Write-DiagLog "AC Sleep Timeout: $(if ($acSleep -match '0x00000000') { 'Disabled ✅' } else { 'Enabled ❌' })"
    Write-DiagLog "DC Sleep Timeout: $(if ($dcSleep -match '0x00000000') { 'Disabled ✅' } else { 'Enabled ❌' })"
} catch {
    Write-DiagLog "Error checking power settings: $($_.Exception.Message)" "ERROR"
}

# 2. Check Lock Screen Registry Settings
Write-DiagLog ""
Write-DiagLog "=== LOCK SCREEN REGISTRY SETTINGS ===" "INFO"

# Check Group Policy lock screen disable
$personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (Test-Path $personalizationPath) {
    try {
        $noLockScreen = Get-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -ErrorAction SilentlyContinue
        if ($noLockScreen -and $noLockScreen.NoLockScreen -eq 1) {
            Write-DiagLog "Group Policy NoLockScreen: Enabled ✅" "SUCCESS"
        } else {
            Write-DiagLog "Group Policy NoLockScreen: Not set or disabled ❌" "ERROR"
        }
    } catch {
        Write-DiagLog "Error reading NoLockScreen setting: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-DiagLog "Personalization registry path does not exist ❌" "ERROR"
    Write-DiagLog "This means the lock screen disable was not applied!" "CRITICAL"
}

# Check additional lock screen settings
$additionalPaths = @(
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "InactivityTimeoutSecs"; Expected = 0},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"; Name = "ACSettingIndex"; Expected = 0},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"; Name = "DCSettingIndex"; Expected = 0}
)

foreach ($setting in $additionalPaths) {
    if (Test-Path $setting.Path) {
        try {
            $value = Get-ItemProperty -Path $setting.Path -Name $setting.Name -ErrorAction SilentlyContinue
            if ($value -and $value.$($setting.Name) -eq $setting.Expected) {
                Write-DiagLog "$($setting.Name): Correctly set ✅"
            } else {
                Write-DiagLog "$($setting.Name): Not set or incorrect value ❌" "WARNING"
            }
        } catch {
            Write-DiagLog "Error reading $($setting.Name): $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-DiagLog "$($setting.Path): Path does not exist ❌" "WARNING"
    }
}

# 3. Check Screen Saver Settings
Write-DiagLog ""
Write-DiagLog "=== SCREEN SAVER SETTINGS ===" "INFO"

$screenSaverPath = "HKCU:\Control Panel\Desktop"
try {
    $screenSaverActive = Get-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue
    $screenSaverSecure = Get-ItemProperty -Path $screenSaverPath -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue
    $screenSaverTimeout = Get-ItemProperty -Path $screenSaverPath -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue
    
    Write-DiagLog "Screen Saver Active: $(if ($screenSaverActive.ScreenSaveActive -eq '0') { 'Disabled ✅' } else { 'Enabled ❌' })"
    Write-DiagLog "Screen Saver Secure: $(if ($screenSaverSecure.ScreenSaverIsSecure -eq '0') { 'Disabled ✅' } else { 'Enabled ❌' })"
    Write-DiagLog "Screen Saver Timeout: $($screenSaverTimeout.ScreenSaveTimeOut) seconds"
} catch {
    Write-DiagLog "Error checking screen saver settings: $($_.Exception.Message)" "ERROR"
}

# 4. Check if Keep-Alive Process is Running
Write-DiagLog ""
Write-DiagLog "=== KEEP-ALIVE PROCESS CHECK ===" "INFO"

$keepAliveProcesses = Get-Process | Where-Object { 
    $_.ProcessName -eq "powershell" -and 
    ($_.CommandLine -like "*KeepResearch*" -or $_.MainWindowTitle -like "*KeepAlive*")
} -ErrorAction SilentlyContinue

if ($keepAliveProcesses) {
    Write-DiagLog "Keep-alive processes found: $($keepAliveProcesses.Count) ✅" "SUCCESS"
    foreach ($proc in $keepAliveProcesses) {
        $runtime = (Get-Date) - $proc.StartTime
        Write-DiagLog "  Process ID $($proc.Id): Running for $([math]::Round($runtime.TotalHours, 1)) hours"
    }
} else {
    Write-DiagLog "No keep-alive processes detected ❌" "WARNING"
    Write-DiagLog "The keep-alive mechanism may not be running!"
}

# 5. Check Windows Version and Lock Screen Capabilities
Write-DiagLog ""
Write-DiagLog "=== SYSTEM INFORMATION ===" "INFO"

$osVersion = Get-CimInstance -ClassName Win32_OperatingSystem
Write-DiagLog "OS Version: $($osVersion.Caption) Build $($osVersion.BuildNumber)"

# Check if this is Windows 10/11 which has different lock screen behavior
$buildNumber = [int]$osVersion.BuildNumber
if ($buildNumber -ge 22000) {
    Write-DiagLog "Windows 11 detected - May need additional settings" "WARNING"
} elseif ($buildNumber -ge 10240) {
    Write-DiagLog "Windows 10 detected - Standard lock screen prevention should work" "INFO"
} else {
    Write-DiagLog "Older Windows version detected" "INFO"
}

# 6. Recommendations
Write-DiagLog ""
Write-DiagLog "=== RECOMMENDATIONS ===" "INFO"

$criticalIssues = 0
$warnings = 0

if (-not $isAdmin) {
    Write-DiagLog "🔧 CRITICAL: Re-run the main script as Administrator!" "CRITICAL"
    $criticalIssues++
}

if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) {
    Write-DiagLog "🔧 CRITICAL: Lock screen registry settings not applied!" "CRITICAL"
    Write-DiagLog "   Run: PowerShell -ExecutionPolicy Bypass -File KeepResearchLaptopAwake.ps1" "INFO"
    $criticalIssues++
}

if (-not $keepAliveProcesses) {
    Write-DiagLog "🔧 WARNING: Start the keep-alive process!" "WARNING"
    Write-DiagLog "   Run: StartKeepAlive.bat" "INFO"
    $warnings++
}

if ($criticalIssues -eq 0 -and $warnings -eq 0) {
    Write-DiagLog "🎉 All settings appear correct - lock screen should be prevented!" "SUCCESS"
} else {
    Write-DiagLog "❌ Found $criticalIssues critical issues and $warnings warnings" "ERROR"
}

Write-DiagLog ""
Write-DiagLog "=== DIAGNOSIS COMPLETE ===" "INFO"
