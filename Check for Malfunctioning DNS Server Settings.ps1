# Initialize an empty array to store DNS server IP addresses
$dnsServerIPs = @()

# Array to store IPs of failing DNS servers
$failingDnsServers = @()

# Number of queries to perform for each DNS server
$numQueries = 5

# Get all network interfaces
$networkInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Loop through each network interface to get DNS server information
foreach ($interface in $networkInterfaces) {
    $dnsInfo = Get-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($dnsInfo -ne $null -and $dnsInfo.ServerAddresses -ne $null) {
        foreach ($entry in $dnsInfo) {
            # Add the DNS server IP addresses to the array
            $dnsServerIPs += $entry.ServerAddresses
        }
    } else {
        Write-Host "No DNS server addresses found for interface $($interface.Name) with index $($interface.ifIndex)."
    }
}

# Remove duplicate entries
$uniqueDnsServerIPs = $dnsServerIPs | Sort-Object | Get-Unique

# Display the unique DNS server IP addresses
Write-Host "Unique IPv4 DNS Server IP Addresses:"
$uniqueDnsServerIPs

# Perform NSLookup for google.com using each DNS server IP
Write-Host "Performing NSLookup for google.com using each DNS server IP:"
foreach ($dnsIP in $uniqueDnsServerIPs) {
    Write-Host "Using DNS Server: $dnsIP"
    $failedCount = 0
    for ($i = 1; $i -le $numQueries; $i++) {
        $nslookupResult = nslookup "google.com" $dnsIP 2>&1
        if ($nslookupResult -like '*Non-existent domain*' -or $nslookupResult -like '*Request timed out*') {
            $failedCount++
        }
    }
    if ($failedCount -eq $numQueries) {
        Write-Host "Failed to resolve DNS for google.com using server $dnsIP after $numQueries queries."
        $failingDnsServers += $dnsIP
    } else {
        Write-Host "NSLookup successful after $numQueries queries."
    }
}

# Exit with status code 1 if any DNS lookups failed
if ($failingDnsServers.Count -gt 0) {
	Write-Host "<-Start Result->"
    Write-Host "Result=Failing DNS Server IPs: $($failingDnsServers -join ', ')"
	Write-Host "<-End Result->"
    exit 1
}
else {
	Write-Host "<-Start Result->"
    Write-Host "Result=All DNS servers returned a valid result"
	Write-Host "<-End Result->"
	exit 0
}
