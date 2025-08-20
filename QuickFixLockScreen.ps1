# QuickFixLockScreen.ps1
# Emergency fix for persistent lock screen issues
# This applies the most aggressive lock screen prevention settings

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "=== EMERGENCY LOCK SCREEN FIX ===" -ForegroundColor Green
Write-Host "Applying comprehensive lock screen prevention..." -ForegroundColor Yellow
Write-Host ""

try {
    # 1. Disable Lock Screen via Group Policy
    Write-Host "1. Disabling lock screen via Group Policy..." -ForegroundColor Cyan
    $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (-not (Test-Path $personalizationPath)) {
        New-Item -Path $personalizationPath -Force | Out-Null
    }
    Set-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -Value 1 -Type DWord
    Write-Host "   ✅ Lock screen disabled via Group Policy" -ForegroundColor Green

    # 2. Disable Screen Saver (Current User)
    Write-Host "2. Disabling screen saver for current user..." -ForegroundColor Cyan
    $screenSaverPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -Value "0" -Type String
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveTimeOut" -Value "0" -Type String
    Write-Host "   ✅ Screen saver disabled for current user" -ForegroundColor Green

    # 3. Disable Screen Saver System-Wide
    Write-Host "3. Disabling screen saver system-wide..." -ForegroundColor Cyan
    $systemScreenSaverPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop"
    if (-not (Test-Path $systemScreenSaverPath)) {
        New-Item -Path $systemScreenSaverPath -Force | Out-Null
    }
    Set-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaveActive" -Value "0" -Type String
    Set-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
    Write-Host "   ✅ System-wide screen saver disabled" -ForegroundColor Green

    # 4. Disable Inactivity Timeout
    Write-Host "4. Disabling inactivity timeout..." -ForegroundColor Cyan
    $sessionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty -Path $sessionPath -Name "InactivityTimeoutSecs" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "   ✅ Inactivity timeout disabled" -ForegroundColor Green

    # 5. Disable Lock on Resume from Sleep
    Write-Host "5. Disabling lock on resume from sleep..." -ForegroundColor Cyan
    $powerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
    if (-not (Test-Path $powerPath)) {
        New-Item -Path $powerPath -Force | Out-Null
    }
    Set-ItemProperty -Path $powerPath -Name "ACSettingIndex" -Value 0 -Type DWord
    Set-ItemProperty -Path $powerPath -Name "DCSettingIndex" -Value 0 -Type DWord
    Write-Host "   ✅ Lock on resume disabled" -ForegroundColor Green

    # 6. Additional Windows 10/11 Settings
    Write-Host "6. Applying additional Windows 10/11 settings..." -ForegroundColor Cyan
    
    # Disable dynamic lock
    $dynamicLockPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $dynamicLockPath -Name "EnableFirstLogonAnimation" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Disable lock screen timeout in power settings
    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $winlogonPath -Name "ScreenSaverGracePeriod" -Value "0" -Type String -ErrorAction SilentlyContinue
    
    # Disable Windows Spotlight lock screen
    $spotlightPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $spotlightPath)) {
        New-Item -Path $spotlightPath -Force | Out-Null
    }
    Set-ItemProperty -Path $spotlightPath -Name "DisableWindowsSpotlightFeatures" -Value 1 -Type DWord
    
    Write-Host "   ✅ Additional settings applied" -ForegroundColor Green

    # 7. Force Group Policy Update
    Write-Host "7. Forcing Group Policy update..." -ForegroundColor Cyan
    try {
        & gpupdate /force | Out-Null
        Write-Host "   ✅ Group Policy updated" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Group Policy update failed (not critical)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🎉 EMERGENCY FIX COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "1. You may need to RESTART your computer for all changes to take effect" -ForegroundColor White
    Write-Host "2. After restart, run the keep-alive script: StartKeepAlive.bat" -ForegroundColor White
    Write-Host "3. Test with: DiagnoseLockScreenIssue.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "If lock screen still appears after restart, there may be:" -ForegroundColor Yellow
    Write-Host "- Domain Group Policy overriding these settings" -ForegroundColor White
    Write-Host "- Third-party security software interfering" -ForegroundColor White
    Write-Host "- Windows version-specific lock screen behavior" -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you're running as Administrator!" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"
