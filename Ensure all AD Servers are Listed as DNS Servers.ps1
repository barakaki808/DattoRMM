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

# Get the DNS server addresses configured on the server
$dnsServerAddresses = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses

# Output the configured DNS server addresses using Write-Host
Write-Host "Configured DNS Server Addresses: $($dnsServerAddresses -join ', ')"

# Check if all domain controllers are listed as DNS servers
$missingDnsServers = $dcIPAddresses | Where-Object { $_ -notin $dnsServerAddresses }

if ($missingDnsServers.Count -gt 0) {
    Write-Host "<-Start Result->"
    Write-Host "Result=Error: The following domain controller(s) are not listed as DNS servers: $($missingDnsServers -join ', ')"
    Write-Host "<-End Result->"
    exit 1
} else {
    Write-Host "<-Start Result->"
    Write-Host "Result=All domain controllers are listed as DNS servers."
    Write-Host "<-End Result->"
    exit 0
}
