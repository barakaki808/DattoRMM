# Initialize a flag to 0 (not found)
$foundFlag = 0
$foundPath = ""

# Get the list of all user profiles
$userProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }

# Loop through each user profile to check for the OneLaunch folder
foreach ($profile in $userProfiles) {
    $appDataPath = Join-Path $profile.LocalPath "AppData\Local"
    $oneLaunchPath = Join-Path $appDataPath "OneLaunch"

    # Check if the OneLaunch folder exists
    if (Test-Path $oneLaunchPath) {
        $foundFlag = 1
        $foundPath = $oneLaunchPath
        break
    }
}

# Check if the OneLaunch folder was found and print the results
if ($foundFlag) {
    Write-Host "<-Start Result->"
    Write-Host "Result=OneLaunch folder found: $foundPath"
    Write-Host "<-End Result->"
    exit 1
} else {
    Write-Host "<-Start Result->"
    Write-Host "Result=OneLaunch folder does not exist"
    Write-Host "<-End Result->"
    exit 0
}
