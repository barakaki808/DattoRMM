$threshold = 30
$vms = Get-VM
$longRunningVms = @()

foreach ($vm in $vms) {
    $uptime = (Get-VM -Name $vm.Name).Uptime.Days
    if ($uptime -gt $threshold) {
        $longRunningVms += $vm.Name
    }
}

if ($longRunningVms.Count -gt 0) {
    write-host '<-Start Result->'
    write-host "STATUS=Long-running VMs: $($longRunningVms -join ', ')"
    write-host '<-End Result->'
    write-host '<-Start Diagnostic->'
    write-host "Diagnostic Info: VM Names running more than 30 days: $($longRunningVms -join ', ')"
    write-host '<-End Diagnostic->'
    exit 1
} else {
    write-host '<-Start Result->'
    write-host "STATUS=No VMs running more than 30 days"
    write-host '<-End Result->'
    exit 0
}
