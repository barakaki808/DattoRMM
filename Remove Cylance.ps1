# Stop the CylanceSvc service
$serviceName = "CylanceSvc"

# Check if the service exists
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    # Stop the service
    Stop-Service -Name $serviceName
    Write-Host "Successfully stopped $serviceName service."
} else {
    Write-Host "Service $serviceName not found."
}

# Define the registry path and key names
$registryPath = "HKLM:\Software\Cylance\Desktop"
$keyToSet = "SelfProtectionLevel"
$keyToDelete = "LastStateRestorePoint"

# Check if the registry path exists
if (Test-Path $registryPath) {
    # Set the SelfProtectionLevel registry key value
    Set-ItemProperty -Path $registryPath -Name $keyToSet -Value 1
    Write-Host "Successfully set $keyToSet to 1 at $registryPath"

    # Delete the LastStateRestorePoint registry key
    Remove-ItemProperty -Path $registryPath -Name $keyToDelete -ErrorAction SilentlyContinue
    Write-Host "Successfully deleted $keyToDelete from $registryPath"
} else {
    Write-Host "The registry path $registryPath does not exist."
}

# Run the msiexec command with /qn option for silent uninstall
$msiexecCommand = "msiexec /x {2E64FC5C-9286-4A31-916B-0D8AE4B22954} /qn"
Invoke-Expression $msiexecCommand
Write-Host "Successfully executed the msiexec command."
