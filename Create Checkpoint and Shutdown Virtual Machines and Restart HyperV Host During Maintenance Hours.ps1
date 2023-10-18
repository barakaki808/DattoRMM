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
    # Generate a timestamp for the checkpoint name
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"

    # Create a snapshot of all running VMs
    $runningVMs = Get-VM | Where-Object {$_.State -eq 'running'}
    if ($runningVMs.Count -eq 0) {
        Write-Host "No running VMs found."
    } else {
        $runningVMs | ForEach-Object {
            Checkpoint-VM -Name $_.Name -SnapshotName "BeforeReboot_$timestamp" -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Created snapshot for VM: $($_.Name) with name BeforeReboot_$timestamp"
            } else {
                Write-Host "Failed to create snapshot for VM: $($_.Name)"
            }
        }
    }

    # Forcefully stop all running VMs
    $runningVMs | ForEach-Object {
        Stop-VM -Name $_.Name -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "Stopped VM: $($_.Name)"
        } else {
            Write-Host "Failed to stop VM: $($_.Name)"
        }
    }

    # Restart the Hyper-V host
    Restart-Computer -Force
} else {
    Write-Host "Restart script attempted to run outside of scheduled time."
    Exit 1
}
