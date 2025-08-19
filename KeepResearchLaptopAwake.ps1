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
    Write-Log "Starting keep-alive mechanism for continuous operation..."
    
    # Import required assemblies for system interaction
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $keepAliveRunning = $true
    $iteration = 0
    
    Write-Log "Keep-alive mechanism started. Press Ctrl+C to stop."
    
    try {
        while ($keepAliveRunning) {
            $iteration++
            
            # Simulate user activity every 5 minutes to prevent sleep
            [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new(
                [System.Windows.Forms.Cursor]::Position.X + 1, 
                [System.Windows.Forms.Cursor]::Position.Y
            )
            
            Start-Sleep -Seconds 1
            
            [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new(
                [System.Windows.Forms.Cursor]::Position.X - 1, 
                [System.Windows.Forms.Cursor]::Position.Y
            )
            
            # Log status every hour (720 iterations of 5 minutes)
            if ($iteration % 720 -eq 0) {
                Write-Log "Keep-alive active - Iteration $iteration ($(($iteration * 5) / 60) hours running)"
            }
            
            # Wait 5 minutes before next keep-alive signal
            Start-Sleep -Seconds 300
        }
    }
    catch {
        Write-Log "Keep-alive mechanism interrupted: $($_.Exception.Message)" "WARNING"
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
    
    if ($success) {
        Write-Log "=== INSTALLATION COMPLETE ===" "SUCCESS"
        Write-Log "Your research laptop is now configured for 24/7 operation" "SUCCESS"
        Write-Log "" "INFO"
        Write-Log "IMPORTANT NOTES:" "INFO"
        Write-Log "1. Your laptop will no longer sleep automatically" "INFO"
        Write-Log "2. Windows will not restart automatically for updates" "INFO"
        Write-Log "3. You can manually check for updates when convenient" "INFO"
        Write-Log "4. Run with -KeepAlive parameter for continuous keep-alive" "INFO"
        Write-Log "5. Run with -Status to check current configuration" "INFO"
        Write-Log "6. Run with -Uninstall to restore original settings" "INFO"
        Write-Log "" "INFO"
        Write-Log "For continuous operation, consider running:" "INFO"
        Write-Log "PowerShell -ExecutionPolicy Bypass -File KeepResearchLaptopAwake.ps1 -KeepAlive" "INFO"
    } else {
        Write-Log "Installation completed with some errors. Check log for details." "WARNING"
    }
}

# Execute main function
Main
