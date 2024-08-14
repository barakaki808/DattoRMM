# Function to check if a machine needs to be restarted
function Test-PendingReboot {
    # Check for pending file rename operations
    $PendingFileRenameOperations = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue).PendingFileRenameOperations

    # Check for pending computer rename
    $PendingComputerRename = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName' -ErrorAction SilentlyContinue) -ne (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name 'ComputerName' -ErrorAction SilentlyContinue)

    # Check for RebootRequired key
    $RebootRequired = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

    # Check for PendingReboot flag
    $RebootPending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'

    if ($PendingFileRenameOperations -or $PendingComputerRename -or $RebootRequired -or $RebootPending) {
        return $true
    } else {
        return $false
    }
}

# Function to randomly decide if an action should be performed (1 in 30 chance)
function Roll-Dice {
    $roll = Get-Random -Minimum 1 -Maximum 31  # Generates a number between 1 and 30
    return $roll -eq 1  # Returns true if the number is 1
}

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

# Execute the function to check if a reboot is required
if (Test-PendingReboot) {
    Write-Output "A reboot is required."
    
    # Roll the dice to decide if an action should be performed
    if (Roll-Dice) {
        Write-Output "The action will be performed. You rolled a 1!"
        
        # Example usage
        $start = 0  # 12:00 AM
        $end = 6    # 6:00 AM

        # Call the function and store the result
        $result = CheckTimeInHST -startTime $start -endTime $end

        # Check if the result is True, and if so, run the desired operations
        if ($result) {
            # Generate a timestamp for the checkpoint name
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            # Create a snapshot of all running VMs
            $runningVMs = Get-VM | Where-Object {$_.State -eq 'Running'}
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
    } else {
        Write-Output "No action performed this time. Better luck next roll!"
    }
} else {
    Write-Output "No reboot is required."
}
