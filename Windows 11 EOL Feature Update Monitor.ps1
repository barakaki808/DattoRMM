# DattoRMM Monitor Component - Windows 11 EOL Feature Update Check
# Checks if the device is running an End-of-Life feature update of Windows 11
# Alerts if the installed Windows 11 version is no longer receiving security updates

# Windows 11 EOL dates by version and edition
# Sources: https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information
#          https://learn.microsoft.com/en-us/lifecycle/products/windows-11-home-and-pro
#          https://learn.microsoft.com/en-us/lifecycle/products/windows-11-enterprise-and-education

$eolDates = @{
    # Version = @{ HomePro = "EOL Date"; Enterprise = "EOL Date" }
    "21H2" = @{ HomePro = "2023-10-10"; Enterprise = "2024-10-08" }
    "22H2" = @{ HomePro = "2024-10-08"; Enterprise = "2025-10-14" }
    "23H2" = @{ HomePro = "2025-11-11"; Enterprise = "2026-11-10" }
    "24H2" = @{ HomePro = "2026-10-13"; Enterprise = "2027-10-12" }
    "25H2" = @{ HomePro = "2027-10-12"; Enterprise = "2028-10-10" }
}

# Build number to version mapping
$buildToVersion = @{
    "22000" = "21H2"
    "22621" = "22H2"
    "22631" = "23H2"
    "26100" = "24H2"
    "26200" = "25H2"
}

try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $buildNumber = $osInfo.BuildNumber

    # Verify this is Windows 11 (build 22000+)
    if ([int]$buildNumber -lt 22000) {
        Write-Host "<-Start Result->"
        Write-Host "Result=Not Windows 11 (Build $buildNumber). This monitor is for Windows 11 only."
        Write-Host "<-End Result->"
        exit 0
    }

    # Determine the feature update version from the build number
    $version = $null
    if ($buildToVersion.ContainsKey($buildNumber)) {
        $version = $buildToVersion[$buildNumber]
    } else {
        # Try to get DisplayVersion from the registry
        $version = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
    }

    if (-not $version) {
        Write-Host "<-Start Result->"
        Write-Host "Result=Unable to determine Windows 11 feature update version. Build: $buildNumber"
        Write-Host "<-End Result->"
        exit 1
    }

    # Determine edition type (Home/Pro vs Enterprise/Education)
    $edition = $osInfo.Caption
    $isEnterprise = $edition -match "Enterprise|Education"
    $editionType = if ($isEnterprise) { "Enterprise" } else { "HomePro" }
    $editionLabel = if ($isEnterprise) { "Enterprise/Education" } else { "Home/Pro" }

    # Look up the EOL date for this version
    if (-not $eolDates.ContainsKey($version)) {
        Write-Host "<-Start Result->"
        Write-Host "Result=Windows 11 $version is not in the known EOL database. Build: $buildNumber. The script may need updating."
        Write-Host "<-End Result->"
        exit 0
    }

    $eolDateString = $eolDates[$version][$editionType]
    $eolDate = [DateTime]::ParseExact($eolDateString, "yyyy-MM-dd", $null)
    $today = Get-Date

    if ($today -gt $eolDate) {
        $daysPastEol = ($today - $eolDate).Days
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: Windows 11 $version ($editionLabel) reached End-of-Life on $eolDateString ($daysPastEol days ago). OS: $edition (Build $buildNumber). This system is no longer receiving security updates."
        Write-Host "<-End Result->"
        exit 1
    } else {
        $daysUntilEol = ($eolDate - $today).Days
        Write-Host "<-Start Result->"
        Write-Host "Result=Windows 11 $version ($editionLabel) is supported until $eolDateString ($daysUntilEol days remaining). OS: $edition (Build $buildNumber)"
        Write-Host "<-End Result->"
        exit 0
    }
} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
}
