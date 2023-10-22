# PowerShell Script to Find All Administrators on a Windows 10/11 Machine

# Function to find all administrators
function Find-Administrators {
    # Run the 'net localgroup Administrators' command and capture its output
    $output = net localgroup Administrators

    # Initialize an array to hold the names of administrators
    $adminNames = @()

    # Parse the output line-by-line to find usernames
    $capture = $false
    foreach ($line in $output) {
        # Start capturing lines after the line that contains '---'
        if ($line -like "---*") {
            $capture = $true
            continue
        }

        # Stop capturing lines after the last username
        if ($line -eq "") {
            $capture = $false
        }

        # Capture the usernames
        if ($capture) {
            $adminNames += $line.Trim()
        }
    }

    # Return the list of administrator names
    return $adminNames
}

# Call the function and store its result
$administrators = Find-Administrators

# Display the administrators
Write-Host "List of Administrators on this machine:"
foreach ($admin in $administrators) {
    Write-Host "- $admin"
}
