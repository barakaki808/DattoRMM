# Initialize a flag to 0 (not found)
$foundFlag = 0

# Get the list of all user profiles
$userProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }

# Loop through each user profile to check for the OneLaunch folder
foreach ($profile in $userProfiles) {
    $appDataPath = Join-Path $profile.LocalPath "AppData\Local"
    $oneLaunchPath = Join-Path $appDataPath "OneLaunch"

    # Check if the OneLaunch folder exists
    if (Test-Path $oneLaunchPath) {
        $foundFlag = 1
        break
    }
}

# Return 1 if found, 0 otherwise
return $foundFlag
