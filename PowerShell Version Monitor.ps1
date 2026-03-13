# DattoRMM Monitor Component - PowerShell 7.4 LTS Version Check (Self-Healing)
# Monitors that PowerShell 7.4 LTS is installed and automatically installs it if missing or wrong version
# Uses the official Microsoft MSI installer for a silent install

$requiredMajor = 7
$requiredMinor = 4
$msiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.7/PowerShell-7.4.7-win-x64.msi"
$installerPath = "$env:TEMP\PowerShell-7.4.7-win-x64.msi"

function Install-PowerShell74 {
    param (
        [string]$Reason
    )

    Write-Host "PowerShell 7.4 LTS not satisfied ($Reason). Beginning installation..."

    # Download the MSI installer
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msiUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: Failed to download PowerShell 7.4 LTS installer. Error: $($_.Exception.Message)"
        Write-Host "<-End Result->"
        exit 1
    }

    # Run the MSI installer silently
    # ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 - Adds "Open here" context menu
    # ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 - Adds "Run with PowerShell 7" context menu
    # ENABLE_PSREMOTING=1 - Enables PS Remoting
    # REGISTER_MANIFEST=1 - Registers Windows Event Logging manifest
    # USE_MU=1 / ENABLE_MU=1 - Enables updating via Microsoft Update
    $msiArgs = @(
        "/i"
        "`"$installerPath`""
        "/qn"
        "/norestart"
        "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1"
        "ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1"
        "ENABLE_PSREMOTING=1"
        "REGISTER_MANIFEST=1"
        "USE_MU=1"
        "ENABLE_MU=1"
    )

    $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

    # Clean up the installer
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

    if ($installProcess.ExitCode -ne 0) {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: PowerShell 7.4 LTS installation failed with exit code $($installProcess.ExitCode). $Reason"
        Write-Host "<-End Result->"
        exit 1
    }

    # Refresh PATH so we can verify the install
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"

    # Verify the installation
    $pwshVerify = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshVerify) {
        $newVersion = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>&1
        Write-Host "<-Start Result->"
        Write-Host "Result=PowerShell 7.4 LTS ($newVersion) was successfully installed. Previous state: $Reason. Path: $($pwshVerify.Source)"
        Write-Host "<-End Result->"
        exit 0
    } else {
        Write-Host "<-Start Result->"
        Write-Host "Result=ALERT: PowerShell 7.4 LTS installer completed but pwsh was not found in PATH. A reboot may be required."
        Write-Host "<-End Result->"
        exit 1
    }
}

try {
    # Check if pwsh (PowerShell 7+) is available
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

    if (-not $pwshPath) {
        Install-PowerShell74 -Reason "PowerShell 7 is not installed, only Windows PowerShell $($PSVersionTable.PSVersion) found"
        return
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
        Install-PowerShell74 -Reason "PowerShell $installedVersion is installed but is not the 7.4 LTS release"
    } else {
        Install-PowerShell74 -Reason "PowerShell $installedVersion is installed but is older than 7.4 LTS"
    }
} catch {
    Write-Host "<-Start Result->"
    Write-Host "Result=ERROR: $($_.Exception.Message)"
    Write-Host "<-End Result->"
    exit 1
}
