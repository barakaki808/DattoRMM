# Kill the specified processes
$processesToKill = @("OneLaunch", "OneLaunchTray", "Chromium")

foreach ($process in $processesToKill) {
    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue
    Write-Host "Killed process: $process"
}

# Get the path to the Users folder, usually "C:\Users"
$usersPath = "C:\Users"

# Define the folder name to search for
$folderName = "OneLaunch"

# Loop through each user profile
Get-ChildItem -Path $usersPath | ForEach-Object {
    $userProfile = $_.FullName

    # Construct the path to the AppData\Local folder for this user
    $appDataLocalPath = Join-Path -Path $userProfile -ChildPath "AppData\Local"

    # Construct the full path to the folder to search for
    $fullFolderPath = Join-Path -Path $appDataLocalPath -ChildPath $folderName

    # Check if the folder exists
    if (Test-Path $fullFolderPath) {
        # Remove the folder forcibly
        Remove-Item -Path $fullFolderPath -Recurse -Force
        Write-Host "Removed folder: $fullFolderPath"
    } else {
        Write-Host "Folder does not exist: $fullFolderPath"
    }
}
