# Import the required module
Import-Module ActiveDirectory

# Initialize an empty array to hold the IP addresses of domain controllers
$dcIPAddresses = @()

# Get all domain controllers in the environment
$domainControllers = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue

# Check if there are any domain controllers
if ($null -eq $domainControllers) {
    Write-Host "No domain controllers found. Exiting."
    exit 0
}

# Loop through each domain controller to get its IP address
foreach ($dc in $domainControllers) {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($dc.HostName)
    foreach ($ip in $ipAddress) {
        if ($ip.AddressFamily -eq "InterNetwork") { # Filter out IPv6 addresses
            $dcIPAddresses += $ip.IPAddressToString
        }
    }
}

# Output the IP addresses of domain controllers using Write-Host
Write-Host "IP Addresses of Domain Controllers: $($dcIPAddresses -join ', ')"

# Get the network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}

# Set the DNS servers
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dcIPAddresses

# Get the newly set DNS server addresses
$newDNSServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses

# Output the new DNS servers for verification
Write-Host "DNS Servers have been set to: $($newDNSServers -join ', ')"

# Check if all domain controllers are now listed as DNS servers
$missingDnsServers = $dcIPAddresses | Where-Object { $_ -notin $newDNSServers }

if ($missingDnsServers.Count -gt 0) {
    Write-Host "Warning: The following domain controller(s) are not listed as DNS servers: $($missingDnsServers -join ', ')"
} else {
    Write-Host "All domain controllers are now listed as DNS servers."
}
