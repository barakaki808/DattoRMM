# PowerShell Script to Check Time in Hawaii Standard Time (HST)

# Function to check if the current time is between the specified start and end times in HST
function CheckTimeInHST {
    param (
        [int]$startTime,  # Start time in 24-hour format
        [int]$endTime     # End time in 24-hour format
    )

    # Get the current time in UTC
    $currentUTC = [System.DateTime]::UtcNow

    # Convert UTC time to Hawaii Standard Time (HST)
    $hstZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Hawaiian Standard Time")
    $currentHST = [System.TimeZoneInfo]::ConvertTimeFromUtc($currentUTC, $hstZone)

    # Extract the hour from the HST time
    $currentHour = $currentHST.Hour

    # Check if the current hour is between the specified start and end times
    if ($currentHour -ge $startTime -and $currentHour -lt $endTime) {
        return $true
    } else {
        return $false
    }
}

# Example usage
$start = 0  # 12:00 AM
$end = 6   # 6:00 AM

# Call the function and store the result
$result = CheckTimeInHST -startTime $start -endTime $end

# Check if the result is True, and if so, run the desired operations
if ($result) {
    # Restart the host
    Restart-Computer -Force
} else {
    Write-Host "Restart script attempted to run outside of scheduled time."
    Exit 1
}
