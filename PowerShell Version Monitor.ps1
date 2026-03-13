# DattoRMM Monitor Component - PowerShell Version Check
# Monitors that PowerShell 7.4 LTS is installed and reports version details
# Alerts if PowerShell 7.4.x is not found on the device

$requiredMajor = 7
$requiredMinor = 4

try {
    # Check if pwsh (PowerShell 7+) is available
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: PowerShell 7 is not installed. Only Windows PowerShell $($PSVersionTable.PSVersion) was found. Please install PowerShell 7.4 LTS."
        Write-Host "<-End Result->"
        exit 1
    }

    # Get the version from pwsh
    $versionOutput = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>&1
    $installedVersion = [Version]$versionOutput

    if ($installedVersion.Major -eq $requiredMajor -and $installedVersion.Minor -eq $requiredMinor) {
        Write-Host "<-Start Result->"
        Write-Host "Result=PowerShell $installedVersion (7.4 LTS) is installed. Path: $($pwshPath.Source)"
        Write-Host "<-End Result->"
        exit 0
    } elseif ($installedVersion.Major -gt $requiredMajor -or ($installedVersion.Major -eq $requiredMajor -and $installedVersion.Minor -gt $requiredMinor)) {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: PowerShell $installedVersion is installed but 7.4 LTS is required. Current version may not be the LTS release. Path: $($pwshPath.Source)"
        Write-Host "<-End Result->"
        exit 1
    } else {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: PowerShell $installedVersion is installed but 7.4 LTS is required. Please upgrade. Path: $($pwshPath.Source)"
        Write-Host "<-End Result->"
        exit 1
    }
} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
}
