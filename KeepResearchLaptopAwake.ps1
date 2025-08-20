# KeepResearchLaptopAwake.ps1
# PowerShell script to keep Windows laptop awake for 24/7 research operations
# Designed for IV measurement data collection on quantum dot devices
# 
# IMPORTANT: Run as Administrator for full functionality
#
# Author: AI Assistant
# Purpose: Prevent sleep mode and automatic updates/restarts during research

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Status,
    [switch]$KeepAlive
)

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to log messages with timestamps
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also write to log file
    $logFile = Join-Path $PSScriptRoot "ResearchLaptop.log"
    $logMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Function to disable sleep mode and hibernation
function Disable-SleepMode {
    Write-Log "Configuring power settings to prevent sleep mode..."
    
    try {
        # Disable sleep when plugged in (AC power)
        & powercfg /X standby-timeout-ac 0
        Write-Log "Disabled sleep timeout on AC power"
        
        # Disable sleep when on battery (just in case)
        & powercfg /X standby-timeout-dc 0
        Write-Log "Disabled sleep timeout on battery power"
        
        # Disable hibernate timeout on AC
        & powercfg /X hibernate-timeout-ac 0
        Write-Log "Disabled hibernate timeout on AC power"
        
        # Disable hibernate timeout on battery
        & powercfg /X hibernate-timeout-dc 0
        Write-Log "Disabled hibernate timeout on battery power"
        
        # Disable monitor timeout on AC (keep display on)
        & powercfg /X monitor-timeout-ac 0
        Write-Log "Disabled monitor timeout on AC power"
        
        # Disable disk timeout on AC
        & powercfg /X disk-timeout-ac 0
        Write-Log "Disabled disk timeout on AC power"
        
        Write-Log "Power settings configured successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error configuring power settings: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to disable automatic updates and restarts
function Disable-AutoUpdates {
    Write-Log "Configuring Windows Update settings to prevent automatic restarts..."
    
    try {
        # Registry path for Windows Update settings
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        
        # Create registry path if it doesn't exist
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            Write-Log "Created Windows Update registry path"
        }
        
        # Prevent automatic restart when users are logged on
        Set-ItemProperty -Path $registryPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
        Write-Log "Disabled automatic restart with logged-on users"
        
        # Set to download updates but let user choose when to install
        Set-ItemProperty -Path $registryPath -Name "AUOptions" -Value 4 -Type DWord
        Write-Log "Set updates to download but manual install"
        
        # Disable wake timers that might restart the system
        $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D"
        if (Test-Path $powerPath) {
            Set-ItemProperty -Path $powerPath -Name "Attributes" -Value 2 -Type DWord
            Write-Log "Disabled wake timers"
        }
        
        Write-Log "Windows Update settings configured successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error configuring Windows Update settings: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to disable lock screen and screen saver
function Disable-LockScreen {
    Write-Log "Configuring system to disable lock screen and screen saver..."
    
    try {
        # Disable lock screen for all users
        $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (-not (Test-Path $personalizationPath)) {
            New-Item -Path $personalizationPath -Force | Out-Null
            Write-Log "Created Personalization registry path"
        }
        Set-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -Value 1 -Type DWord
        Write-Log "Disabled lock screen via Group Policy"
        
        # Disable screen saver for current user and system-wide
        $screenSaverPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -Value "0" -Type String
        Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
        Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveTimeOut" -Value "0" -Type String
        Write-Log "Disabled screen saver for current user"
        
        # Disable system screen saver policy
        $systemScreenSaverPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop"
        if (-not (Test-Path $systemScreenSaverPath)) {
            New-Item -Path $systemScreenSaverPath -Force | Out-Null
            Write-Log "Created system screen saver policy path"
        }
        Set-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaveActive" -Value "0" -Type String
        Set-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
        Write-Log "Disabled system screen saver policy"
        
        # Disable automatic lock after inactivity
        $sessionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $sessionPath -Name "InactivityTimeoutSecs" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "Disabled automatic lock after inactivity"
        
        # Disable lock screen on resume from sleep (if sleep were to occur)
        $powerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
        if (-not (Test-Path $powerPath)) {
            New-Item -Path $powerPath -Force | Out-Null
            Write-Log "Created power lock screen policy path"
        }
        Set-ItemProperty -Path $powerPath -Name "ACSettingIndex" -Value 0 -Type DWord
        Set-ItemProperty -Path $powerPath -Name "DCSettingIndex" -Value 0 -Type DWord
        Write-Log "Disabled lock screen on resume from sleep"
        
        # Additional setting to prevent Ctrl+Alt+Del screen timeout
        $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Set-ItemProperty -Path $winlogonPath -Name "ScreenSaverGracePeriod" -Value "0" -Type String -ErrorAction SilentlyContinue
        Write-Log "Disabled Winlogon screen saver grace period"
        
        Write-Log "Lock screen and screen saver disabled successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error disabling lock screen: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to disable Windows Defender scheduled scans during active hours
function Configure-DefenderSchedule {
    Write-Log "Configuring Windows Defender to minimize interruptions..."
    
    try {
        # Set scheduled scan time to a specific time (3 AM) instead of random
        Set-MpPreference -ScanScheduleTime 03:00:00
        Write-Log "Set Defender scan time to 3:00 AM"
        
        # Reduce CPU usage during scans
        Set-MpPreference -ScanAvgCPULoadFactor 25
        Write-Log "Set Defender CPU usage to 25% during scans"
        
        Write-Log "Windows Defender configured successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error configuring Windows Defender: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to create a keep-alive mechanism
function Start-KeepAlive {
    Write-Log "Starting enhanced keep-alive mechanism for continuous operation..."
    
    # Import required assemblies for system interaction
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Add Windows API functions to prevent system from going idle
    Add-Type @'
        using System;
        using System.Runtime.InteropServices;
        
        public class Win32 {
            [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern uint SetThreadExecutionState(uint esFlags);
            
            [DllImport("user32.dll")]
            public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
            
            [DllImport("user32.dll")]
            public static extern bool SetCursorPos(int X, int Y);
            
            public const uint ES_CONTINUOUS = 0x80000000;
            public const uint ES_SYSTEM_REQUIRED = 0x00000001;
            public const uint ES_DISPLAY_REQUIRED = 0x00000002;
            public const uint ES_USER_PRESENT = 0x00000004;
            
            public const byte VK_SHIFT = 0x10;
            public const uint KEYEVENTF_KEYUP = 0x0002;
        }
'@
    
    # Set execution state to prevent system sleep and keep display active
    $result = [Win32]::SetThreadExecutionState([Win32]::ES_CONTINUOUS -bor [Win32]::ES_SYSTEM_REQUIRED -bor [Win32]::ES_DISPLAY_REQUIRED -bor [Win32]::ES_USER_PRESENT)
    Write-Log "Set thread execution state to prevent sleep (Result: $result)"
    
    $keepAliveRunning = $true
    $iteration = 0
    $lastActivity = Get-Date
    
    Write-Log "Enhanced keep-alive mechanism started. Press Ctrl+C to stop."
    Write-Log "This will prevent lock screen by simulating activity every 30 seconds."
    
    try {
        while ($keepAliveRunning) {
            $iteration++
            $currentTime = Get-Date
            
            # More aggressive activity simulation every 30 seconds to prevent lock screen
            # Alternate between different types of activity
            $activityType = $iteration % 4
            
            switch ($activityType) {
                0 {
                    # Move mouse cursor slightly
                    $currentPos = [System.Windows.Forms.Cursor]::Position
                    [Win32]::SetCursorPos($currentPos.X + 1, $currentPos.Y)
                    Start-Sleep -Milliseconds 100
                    [Win32]::SetCursorPos($currentPos.X, $currentPos.Y)
                }
                1 {
                    # Send a harmless shift key press (won't interfere with typing)
                    [Win32]::keybd_event([Win32]::VK_SHIFT, 0, 0, 0)
                    Start-Sleep -Milliseconds 50
                    [Win32]::keybd_event([Win32]::VK_SHIFT, 0, [Win32]::KEYEVENTF_KEYUP, 0)
                }
                2 {
                    # Move cursor to a different position and back
                    $currentPos = [System.Windows.Forms.Cursor]::Position
                    [Win32]::SetCursorPos($currentPos.X, $currentPos.Y + 1)
                    Start-Sleep -Milliseconds 100
                    [Win32]::SetCursorPos($currentPos.X, $currentPos.Y)
                }
                3 {
                    # Refresh execution state to ensure system stays awake
                    [Win32]::SetThreadExecutionState([Win32]::ES_CONTINUOUS -bor [Win32]::ES_SYSTEM_REQUIRED -bor [Win32]::ES_DISPLAY_REQUIRED -bor [Win32]::ES_USER_PRESENT)
                }
            }
            
            $lastActivity = $currentTime
            
            # Log status every 2 hours (240 iterations of 30 seconds)
            if ($iteration % 240 -eq 0) {
                $hoursRunning = [math]::Round(($iteration * 30) / 3600, 1)
                Write-Log "Enhanced keep-alive active - Iteration $iteration ($hoursRunning hours running)"
                Write-Log "Last activity: $($lastActivity.ToString('HH:mm:ss')) - Preventing lock screen and sleep"
            }
            
            # Wait 30 seconds before next activity (much more frequent than before)
            Start-Sleep -Seconds 30
        }
    }
    catch {
        Write-Log "Keep-alive mechanism interrupted: $($_.Exception.Message)" "WARNING"
    }
    finally {
        # Restore normal execution state when stopping
        [Win32]::SetThreadExecutionState([Win32]::ES_CONTINUOUS)
        Write-Log "Restored normal thread execution state"
    }
}

# Function to show current status
function Show-Status {
    Write-Log "=== Research Laptop Status ===" "INFO"
    
    # Check power settings
    $acSleep = & powercfg /Q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current AC Power Setting Index"
    $dcSleep = & powercfg /Q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current DC Power Setting Index"
    
    Write-Log "AC Sleep Timeout: $(if ($acSleep -match '0x00000000') { 'Disabled (Good)' } else { 'Enabled (Bad)' })"
    Write-Log "DC Sleep Timeout: $(if ($dcSleep -match '0x00000000') { 'Disabled (Good)' } else { 'Enabled (Bad)' })"
    
    # Check update settings
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (Test-Path $registryPath) {
        $noAutoReboot = Get-ItemProperty -Path $registryPath -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
        Write-Log "Auto-restart disabled: $(if ($noAutoReboot.NoAutoRebootWithLoggedOnUsers -eq 1) { 'Yes (Good)' } else { 'No (Bad)' })"
    } else {
        Write-Log "Auto-restart disabled: No (Bad - Registry not configured)"
    }
    
    # Check lock screen settings
    $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (Test-Path $personalizationPath) {
        $noLockScreen = Get-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -ErrorAction SilentlyContinue
        Write-Log "Lock screen disabled: $(if ($noLockScreen.NoLockScreen -eq 1) { 'Yes (Good)' } else { 'No (Bad)' })"
    } else {
        Write-Log "Lock screen disabled: No (Bad - Registry not configured)"
    }
    
    # Check screen saver settings
    $screenSaverPath = "HKCU:\Control Panel\Desktop"
    $screenSaverActive = Get-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue
    Write-Log "Screen saver disabled: $(if ($screenSaverActive.ScreenSaveActive -eq '0') { 'Yes (Good)' } else { 'No (Bad)' })"
    
    Write-Log "=== End Status ===" "INFO"
}

# Function to restore original settings
function Restore-OriginalSettings {
    Write-Log "Restoring original Windows settings..."
    
    try {
        # Restore default power settings (30 minutes on AC, 15 on battery)
        & powercfg /X standby-timeout-ac 30
        & powercfg /X standby-timeout-dc 15
        & powercfg /X hibernate-timeout-ac 180
        & powercfg /X hibernate-timeout-dc 180
        & powercfg /X monitor-timeout-ac 20
        & powercfg /X disk-timeout-ac 20
        
        # Remove Windows Update registry modifications
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (Test-Path $registryPath) {
            Remove-ItemProperty -Path $registryPath -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $registryPath -Name "AUOptions" -ErrorAction SilentlyContinue
        }
        
        # Restore lock screen settings
        $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (Test-Path $personalizationPath) {
            Remove-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -ErrorAction SilentlyContinue
        }
        
        # Restore screen saver settings for current user
        $screenSaverPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -Value "1" -Type String -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveTimeOut" -Value "600" -Type String -ErrorAction SilentlyContinue
        
        # Remove system screen saver policy
        $systemScreenSaverPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop"
        if (Test-Path $systemScreenSaverPath) {
            Remove-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $systemScreenSaverPath -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue
        }
        
        # Remove inactivity timeout setting
        $sessionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Remove-ItemProperty -Path $sessionPath -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue
        
        # Remove power lock screen policy
        $powerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
        if (Test-Path $powerPath) {
            Remove-ItemProperty -Path $powerPath -Name "ACSettingIndex" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $powerPath -Name "DCSettingIndex" -ErrorAction SilentlyContinue
        }
        
        Write-Log "Original settings restored successfully" "SUCCESS"
    }
    catch {
        Write-Log "Error restoring settings: $($_.Exception.Message)" "ERROR"
    }
}

# Main script logic
function Main {
    Write-Log "=== Research Laptop Keep-Awake Script Started ===" "INFO"
    Write-Log "Designed for 24/7 quantum dot IV measurement operations" "INFO"
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Log "ERROR: This script must be run as Administrator!" "ERROR"
        Write-Log "Right-click PowerShell and select 'Run as Administrator'" "ERROR"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    if ($Status) {
        Show-Status
        return
    }
    
    if ($Uninstall) {
        Write-Log "Uninstalling research laptop configuration..."
        Restore-OriginalSettings
        Write-Log "Uninstallation complete. System restored to default settings."
        return
    }
    
    if ($KeepAlive) {
        Write-Log "Starting keep-alive mode only..."
        Start-KeepAlive
        return
    }
    
    # Default installation mode
    Write-Log "Installing research laptop configuration..."
    
    $success = $true
    
    # Configure power settings
    if (-not (Disable-SleepMode)) {
        $success = $false
    }
    
    # Configure Windows Update settings
    if (-not (Disable-AutoUpdates)) {
        $success = $false
    }
    
    # Configure Windows Defender
    if (-not (Configure-DefenderSchedule)) {
        $success = $false
    }
    
    # Disable lock screen and screen saver
    if (-not (Disable-LockScreen)) {
        $success = $false
    }
    
    if ($success) {
        Write-Log "=== INSTALLATION COMPLETE ===" "SUCCESS"
        Write-Log "Your research laptop is now configured for 24/7 operation" "SUCCESS"
        Write-Log "" "INFO"
        Write-Log "IMPORTANT NOTES:" "INFO"
        Write-Log "1. Your laptop will no longer sleep automatically" "INFO"
        Write-Log "2. Windows will not restart automatically for updates" "INFO"
        Write-Log "3. Lock screen and screen saver have been disabled" "INFO"
        Write-Log "4. You can manually check for updates when convenient" "INFO"
        Write-Log "5. Run with -KeepAlive parameter for continuous keep-alive" "INFO"
        Write-Log "6. Run with -Status to check current configuration" "INFO"
        Write-Log "7. Run with -Uninstall to restore original settings" "INFO"
        Write-Log "" "INFO"
        Write-Log "For continuous operation, consider running:" "INFO"
        Write-Log "PowerShell -ExecutionPolicy Bypass -File KeepResearchLaptopAwake.ps1 -KeepAlive" "INFO"
    } else {
        Write-Log "Installation completed with some errors. Check log for details." "WARNING"
    }
}

# Execute main function
Main
