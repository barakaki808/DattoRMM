# PowerShell Script to Update Windows 11 to the Latest Feature Update
# Uses the Windows 11 Installation Assistant for in-place upgrade
# DattoRMM Component Script

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: Script must be run as Administrator"
    Write-Host "<-End Result->"
    exit 1
}

# Verify this is Windows 11
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$buildNumber = [int]$osInfo.BuildNumber

if ($buildNumber -lt 22000) {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: This script is intended for Windows 11 only. Current OS: $($osInfo.Caption) (Build $buildNumber)"
    Write-Host "<-End Result->"
    exit 1
}

Write-Host "Current OS: $($osInfo.Caption)"
Write-Host "Current Build: $($osInfo.Version)"

# Check available disk space (minimum 20 GB required)
$systemDrive = $env:SystemDrive
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

if ($freeSpaceGB -lt 20) {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: Insufficient disk space. Available: ${freeSpaceGB}GB, Required: 20GB minimum"
    Write-Host "<-End Result->"
    exit 1
}

Write-Host "Available disk space on ${systemDrive}: ${freeSpaceGB}GB"

# Set up working directory
$workingDir = Join-Path $env:TEMP "Win11FeatureUpdate"
if (-not (Test-Path $workingDir)) {
    New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
}

# Download the Windows 11 Installation Assistant
$assistantUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"
$assistantPath = Join-Path $workingDir "Windows11InstallationAssistant.exe"

Write-Host "Downloading Windows 11 Installation Assistant..."

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($assistantUrl, $assistantPath)
    $webClient.Dispose()
} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: Failed to download Windows 11 Installation Assistant - $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
}

if (-not (Test-Path $assistantPath)) {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: Download completed but file not found at $assistantPath"
    Write-Host "<-End Result->"
    exit 1
}

Write-Host "Download complete. Starting Windows 11 Installation Assistant..."

# Run the Installation Assistant silently
# /quiet - quiet mode, no user interaction
# /skipeula - skip EULA prompt
# /auto upgrade - perform automatic upgrade
try {
    $process = Start-Process -FilePath $assistantPath `
        -ArgumentList "/quietinstall /skipeula /auto upgrade" `
        -Wait -PassThru -NoNewWindow

    $exitCode = $process.ExitCode

    switch ($exitCode) {
        0 {
            Write-Host "<-Start Result->"
            Write-Host "Result=Windows 11 feature update installed successfully. A reboot may be required."
            Write-Host "<-End Result->"
            exit 0
        }
        3010 {
            Write-Host "<-Start Result->"
            Write-Host "Result=Windows 11 feature update installed successfully. A reboot is required to complete the installation."
            Write-Host "<-End Result->"
            exit 0
        }
        0x800F0923 {
            Write-Host "<-Start Result->"
            Write-Host "Result=ERROR: Incompatible driver or application detected. Review compatibility before retrying."
            Write-Host "<-End Result->"
            exit 1
        }
        default {
            Write-Host "<-Start Result->"
            Write-Host "Result=ERROR: Installation Assistant exited with code $exitCode"
            Write-Host "<-End Result->"
            exit 1
        }
    }
} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: Failed to run Installation Assistant - $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
} finally {
    # Clean up downloaded file
    if (Test-Path $assistantPath) {
        Remove-Item -Path $assistantPath -Force -ErrorAction SilentlyContinue
    }
}
