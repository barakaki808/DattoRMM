# Create a snapshot for all running VMs
$runningVMs = Get-VM | Where-Object {$_.State -eq 'running'}
if ($runningVMs.Count -eq 0) {
    Write-Host "No running VMs found."
} else {
    $runningVMs | ForEach-Object {
        Checkpoint-VM -Name $_.Name -SnapshotName "BeforeReboot" -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "Created snapshot for VM: $($_.Name)"
        } else {
            Write-Host "Failed to create snapshot for VM: $($_.Name)"
        }
    }
}

# Forcefully stop all running VMs
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
