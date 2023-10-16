# Initialize a flag to indicate if any adapter is using static DNS
$hasStaticDNS = $false

# Get all network adapters that are online
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Loop through each online adapter
foreach ($adapter in $adapters) {
    # Get the adapter's GUID
    $guid = $adapter.InterfaceGuid

    # Construct the Registry path
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"

    # Check if the Registry path exists
    if (Test-Path $regPath) {
        # Get the NameServer value
        $nameServer = Get-ItemProperty -Path $regPath -Name "NameServer" -ErrorAction SilentlyContinue

        # Check if the adapter is using static or dynamic DNS
        if ($nameServer.NameServer -ne $null -and $nameServer.NameServer -ne "") {
            Write-Host ("Adapter " + $adapter.Name + " is using static DNS: " + $nameServer.NameServer)
            $hasStaticDNS = $true
            break
        } else {
            Write-Host ("Adapter " + $adapter.Name + " is using dynamic DNS.")
        }
    } else {
        Write-Host ("Adapter " + $adapter.Name + " DNS configuration is unknown.")
    }
}

# Fail if any adapter is using static DNS
if ($hasStaticDNS) {
	Write-Host "<-Start Result->"
    Write-Host ("Result=Failing because at least one adapter is using static DNS.")
	Write-Host "<-End Result->"
    exit 1
} else {
	Write-Host "<-Start Result->"
    Write-Host ("Result=All online adapters are using dynamic DNS.")
	Write-Host "<-End Result->"
	exit 0
}
