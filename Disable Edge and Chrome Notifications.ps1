# Define registry paths and keys
$chromeRegistryPath = "HKLM:\Software\Policies\Google\Chrome"
$edgeRegistryPath = "HKLM:\Software\Policies\Microsoft\Edge"
$registryKey = "DefaultNotificationsSetting"

# Function to check and update the registry value
function CheckAndUpdateRegistryValue {
    param (
        [string]$path,
        [string]$key
    )

    # Check if the registry path exists
    if (Test-Path $path) {
        # Get the registry key value
        $value = Get-ItemPropertyValue -Path $path -Name $key -ErrorAction SilentlyContinue

        # Check if the value is not equal to 2
        if ($value -ne 2) {
            Write-Host "Registry key value at $path is incorrect: $value. Updating to 2." -ForegroundColor Yellow
            Set-ItemProperty -Path $path -Name $key -Value 2
            return 1
        } else {
            Write-Host "Registry key value at $path is correct: $value" -ForegroundColor Green
            return 0
        }
    } else {
        Write-Host "Registry path $path not found. Creating registry key and setting value to 2." -ForegroundColor Yellow
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -Path $path -Name $key -Value 2 -PropertyType DWord -Force
        return 1
    }
}

# Check and update Chrome settings
$chromeResult = CheckAndUpdateRegistryValue -path $chromeRegistryPath -key $registryKey

# Check and update Edge settings
$edgeResult = CheckAndUpdateRegistryValue -path $edgeRegistryPath -key $registryKey

# Determine overall result
if ($chromeResult -eq 1 -or $edgeResult -eq 1) {
    exit 1
} else {
    exit 0
}
