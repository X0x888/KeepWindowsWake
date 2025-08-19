# MonitorSystemImpact.ps1
# Script to monitor system performance impact of the keep-alive mechanism
# For research laptop performance verification

param(
    [int]$DurationMinutes = 10
)

function Get-SystemMetrics {
    $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
    $memory = Get-Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1
    $processes = Get-Process | Where-Object { $_.ProcessName -like "*powershell*" -or $_.ProcessName -like "*KeepResearch*" }
    
    return @{
        CPUUsage = [math]::Round($cpu.CounterSamples[0].CookedValue, 2)
        AvailableMemoryMB = [math]::Round($memory.CounterSamples[0].CookedValue, 0)
        PowerShellProcesses = $processes
        Timestamp = Get-Date
    }
}

Write-Host "=== System Impact Monitor ===" -ForegroundColor Green
Write-Host "Monitoring system performance for $DurationMinutes minutes..." -ForegroundColor Yellow
Write-Host "This will help verify minimal impact of keep-alive mechanism" -ForegroundColor Yellow
Write-Host ""

$samples = @()
$sampleCount = $DurationMinutes * 2  # Sample every 30 seconds

for ($i = 1; $i -le $sampleCount; $i++) {
    $metrics = Get-SystemMetrics
    $samples += $metrics
    
    Write-Host "Sample $i/$sampleCount - CPU: $($metrics.CPUUsage)% - Available RAM: $($metrics.AvailableMemoryMB)MB - Time: $($metrics.Timestamp.ToString('HH:mm:ss'))"
    
    if ($i -lt $sampleCount) {
        Start-Sleep -Seconds 30
    }
}

Write-Host ""
Write-Host "=== Performance Summary ===" -ForegroundColor Green

$avgCPU = ($samples | Measure-Object -Property CPUUsage -Average).Average
$minRAM = ($samples | Measure-Object -Property AvailableMemoryMB -Minimum).Minimum
$maxRAM = ($samples | Measure-Object -Property AvailableMemoryMB -Maximum).Maximum

Write-Host "Average CPU Usage: $([math]::Round($avgCPU, 2))%" -ForegroundColor Cyan
Write-Host "RAM Usage Range: $([math]::Round($maxRAM - $minRAM, 0))MB variation" -ForegroundColor Cyan

# Check for PowerShell processes
$psProcesses = $samples[0].PowerShellProcesses
if ($psProcesses) {
    Write-Host ""
    Write-Host "PowerShell Processes Found:" -ForegroundColor Yellow
    foreach ($proc in $psProcesses) {
        $memUsageMB = [math]::Round($proc.WorkingSet / 1MB, 1)
        Write-Host "  - $($proc.ProcessName): $memUsageMB MB RAM, CPU Time: $($proc.TotalProcessorTime)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== Impact Assessment ===" -ForegroundColor Green
if ($avgCPU -lt 5) {
    Write-Host "✅ CPU Impact: MINIMAL (< 5%)" -ForegroundColor Green
} elseif ($avgCPU -lt 15) {
    Write-Host "⚠️  CPU Impact: LOW ($([math]::Round($avgCPU, 1))%)" -ForegroundColor Yellow
} else {
    Write-Host "❌ CPU Impact: HIGH ($([math]::Round($avgCPU, 1))%)" -ForegroundColor Red
}

if (($maxRAM - $minRAM) -lt 100) {
    Write-Host "✅ Memory Impact: MINIMAL (< 100MB variation)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Memory Impact: MODERATE ($([math]::Round($maxRAM - $minRAM, 0))MB variation)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Note: This monitoring script itself uses more resources than the keep-alive mechanism!" -ForegroundColor Gray
