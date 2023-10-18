# PowerShell Script to Check Time in Hawaii Standard Time (HST)

# Function to check if the current time is between the specified start and end times in HST
function CheckTimeInHST {
    param (
        [int]$startTime,  # Start time in 24-hour format
        [int]$endTime     # End time in 24-hour format
    )

    # Get the current time in UTC with the Kind property set to Utc
    $currentUTC = [System.DateTime]::UtcNow

    # Convert UTC time to Hawaii Standard Time (HST)
    $hstZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Hawaiian Standard Time")
    $currentHST = [System.TimeZoneInfo]::ConvertTimeFromUtc($currentUTC, $hstZone)

    # Extract the hour from the HST time
    $currentHour = $currentHST.Hour

    # Check if the current hour is between the specified start and end times
    if ($startTime -le $endTime) {
        if ($currentHour -ge $startTime -and $currentHour -lt $endTime) {
            return $true
        } else {
            return $false
        }
    } else {
        if ($currentHour -ge $startTime -or $currentHour -lt $endTime) {
            return $true
        } else {
            return $false
        }
    }
}

# Example usage
$start = 0  # 12:00 AM
$end = 6   # 6:00 AM

# Call the function and store the result
$result = CheckTimeInHST -startTime $start -endTime $end

# Check if the result is True, and if so, run a command
if ($result) {
    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"

    # Replace the following line with your desired command
    Write-Host "Attempting to create a snapshot of all running virtual machines with timestamp $timestamp."
    # Create a snapshot for all running VMs with a timestamp in the snapshot name
    $runningVMs = Get-VM | Where-Object {$_.State -eq 'running'}
    if ($runningVMs.Count -eq 0) {
        Write-Host "No running VMs found."
    } else {
        $runningVMs | ForEach-Object {
            $snapshotName = "Snapshot_$timestamp"
            Checkpoint-VM -Name $_.Name -SnapshotName $snapshotName -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Created snapshot '$snapshotName' for VM: $($_.Name)"
            } else {
                Write-Host "Failed to create snapshot for VM: $($_.Name)"
            }
        }
    }

    # Forcefully stop all running VMs
    Write-Host "Attempting to stop all running virtual machines."
    $runningVMs = Get-VM | Where-Object {$_.State -eq 'running'}
    if ($runningVMs.Count -eq 0) {
        Write-Host "No running VMs found."
    } else {
        $runningVMs | ForEach-Object {
            Stop-VM -Name $_.Name -Force -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Stopped VM: $($_.Name)"
            } else {
                Write-Host "Failed to stop VM: $($_.Name)"
            }
        }
    }

    # Start all VMs that are set to automatically start
    Write-Host "Attempting to start all previously running virtual machines."
    $autoStartVMs = Get-VM | Where-Object {$_.AutomaticStartAction -eq 'Start'}
    if ($autoStartVMs.Count -eq 0) {
        Write-Host "No VMs set to automatically start were found."
    } else {
        $autoStartVMs | ForEach-Object {
            Start-VM -Name $_.Name -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Started VM: $($_.Name)"
            } else {
                Write-Host "Failed to start VM: $($_.Name)"
            }
        }
    }
} else {
    Write-Host "Restart script attempted to run outside of scheduled time."
    Exit 1
}
