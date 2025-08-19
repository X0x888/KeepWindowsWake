# KeepWindowsWake 🔬

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.svg)](https://www.microsoft.com/windows)

An energy-efficient PowerShell solution to keep Windows laptops awake for 24/7 research operations, specifically designed for scientific data collection environments.

## 🎯 Purpose
This PowerShell script is designed for research environments where laptops need to operate 24/7 without interruption, specifically for:
- **Quantum dot IV measurement data collection**
- **Long-running scientific experiments** 
- **Remote laboratory control**
- **Overnight data acquisition**
- **Unattended research instrumentation**

## ⚠️ IMPORTANT SAFETY NOTES

**FOR RESEARCH USE ONLY** - This script disables important Windows power management and update features. Only use on dedicated research laptops that:
- Are always plugged into AC power
- Are used exclusively for data collection
- Have adequate cooling and ventilation
- Are monitored regularly for temperature

**NEVER use this on**:
- Personal laptops
- Battery-powered devices
- Laptops without adequate cooling
- Systems with critical security requirements

## What This Script Does

### Power Management
- ✅ Disables sleep mode when plugged in
- ✅ Disables hibernation
- ✅ Keeps display on (prevents monitor timeout)
- ✅ Prevents disk timeout
- ✅ Disables wake timers

### Windows Updates
- ✅ Prevents automatic restarts after updates
- ✅ Downloads updates but requires manual installation
- ✅ Keeps system control in your hands during measurements

### System Optimization
- ✅ Configures Windows Defender to scan at 3 AM
- ✅ Reduces Defender CPU usage during scans
- ✅ Provides continuous keep-alive mechanism
- ✅ Comprehensive logging for monitoring

## Quick Start

### Option 1: Easy Installation (Recommended)
1. **Right-click** on `RunAsAdmin.bat`
2. **Select** "Run as administrator"
3. **Follow** the prompts

### Option 2: Manual PowerShell
1. **Open PowerShell as Administrator**
2. **Navigate** to the script directory
3. **Run**: `Set-ExecutionPolicy Bypass -Scope Process`
4. **Run**: `.\KeepResearchLaptopAwake.ps1`

## Usage Options

### Install Configuration (One-time setup)
```batch
# Double-click RunAsAdmin.bat
# OR in PowerShell as Admin:
.\KeepResearchLaptopAwake.ps1
```

### Start Continuous Keep-Alive Mode
```batch
# Double-click StartKeepAlive.bat
# OR in PowerShell as Admin:
.\KeepResearchLaptopAwake.ps1 -KeepAlive
```

### Check Current Status
```powershell
.\KeepResearchLaptopAwake.ps1 -Status
```

### Uninstall (Restore Original Settings)
```powershell
.\KeepResearchLaptopAwake.ps1 -Uninstall
```

## For IV Measurement Workflows

### Before Starting Long Measurements:
1. **Install** the configuration: `RunAsAdmin.bat`
2. **Start** keep-alive mode: `StartKeepAlive.bat`
3. **Begin** your IV sweep measurements
4. **Monitor** the log file: `ResearchLaptop.log`

### During Measurements:
- The script logs activity every hour
- Keep-alive simulates minimal user activity every 5 minutes
- No interruptions from sleep or automatic restarts
- Full remote control capability maintained

### After Measurements:
- Press `Ctrl+C` to stop keep-alive mode
- Optionally run uninstall to restore normal operation
- Review logs for any issues

## Files Included

| File | Purpose |
|------|---------|
| `KeepResearchLaptopAwake.ps1` | Main PowerShell script |
| `RunAsAdmin.bat` | Easy installer with admin privileges |
| `StartKeepAlive.bat` | Continuous keep-alive mode launcher |
| `README.md` | This documentation |
| `ResearchLaptop.log` | Generated log file (created when script runs) |

## Monitoring

The script creates a log file `ResearchLaptop.log` that tracks:
- Configuration changes
- Keep-alive activity (hourly updates)
- Any errors or warnings
- Timestamps for all activities

## Troubleshooting

### Script Won't Run
- **Ensure** you're running as Administrator
- **Check** execution policy: `Get-ExecutionPolicy`
- **Set** bypass if needed: `Set-ExecutionPolicy Bypass -Scope Process`

### Laptop Still Goes to Sleep
- **Run** status check: `.\KeepResearchLaptopAwake.ps1 -Status`
- **Verify** AC power is connected
- **Check** manufacturer power management software
- **Consider** using keep-alive mode during measurements

### Updates Still Force Restart
- **Check** Windows Update settings in Settings app
- **Verify** Group Policy isn't overriding registry settings
- **Consider** pausing updates during critical measurement periods

### High CPU Usage
- Windows Defender is configured for low CPU usage (25%)
- Keep-alive mode uses minimal resources
- Check Task Manager for other processes

## Technical Details

### Power Configuration Commands Used
```powershell
powercfg /X standby-timeout-ac 0      # Disable AC sleep
powercfg /X hibernate-timeout-ac 0    # Disable AC hibernate  
powercfg /X monitor-timeout-ac 0      # Keep display on
powercfg /X disk-timeout-ac 0         # Prevent disk timeout
```

### Registry Modifications
```
HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
- NoAutoRebootWithLoggedOnUsers = 1
- AUOptions = 4
```

### Keep-Alive Mechanism
- Moves mouse cursor 1 pixel every 5 minutes
- Minimal system impact
- Prevents sleep without interfering with measurements
- Logs status every hour

## Restoring Normal Operation

When your research is complete, you can restore normal Windows behavior:

```powershell
.\KeepResearchLaptopAwake.ps1 -Uninstall
```

This will:
- Restore default sleep timeouts (30 min AC, 15 min battery)
- Re-enable automatic updates and restarts
- Remove registry modifications
- Restore default Defender settings

## Support

This script was designed specifically for quantum dot IV measurement research. If you encounter issues:

1. **Check** the log file `ResearchLaptop.log`
2. **Run** status check to verify configuration
3. **Ensure** Administrator privileges
4. **Verify** your laptop meets the safety requirements

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Designed for quantum dot research and scientific data collection
- Optimized for energy efficiency and minimal system impact
- Built with research laboratory requirements in mind

## 📞 Support

If you encounter issues specific to research environments or have suggestions for improvements, please open an issue on GitHub.

---

## ⚖️ Disclaimer

This script is provided as-is for research purposes. Users are responsible for:
- Ensuring adequate laptop cooling and monitoring
- Regular system maintenance and security updates
- Understanding the implications of disabling power management
- Backing up important data before use

**Use at your own risk. Not suitable for production environments or personal laptops.**

---
**⭐ If this script helps your research, please consider giving it a star!**
