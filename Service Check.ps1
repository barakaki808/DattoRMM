$serviceName = $env:service_name
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service -ne $null) {
	Write-Host "<-Start Result->"
    Write-Host "Result=The $serviceName exists"
	Write-Host "<-End Result->"
    exit 0
} else {
    Write-Host "<-Start Result->"
	Write-Host "Result=The $serviceName does not exist"
    Write-Host "<-End Result->"
	exit 1
}