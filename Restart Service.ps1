# PowerShell Script to Restart a Windows Service with Error Checking

# Define the service name you want to restart
$serviceName = $env:service_name

# Check if the service exists
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Service '$serviceName' exists. Attempting to restart..."

    try {
        # Stop the service
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        Write-Host "Successfully stopped the service '$serviceName'."

        # Start the service
        Start-Service -Name $serviceName -ErrorAction Stop
        Write-Host "Successfully started the service '$serviceName'."
		exit 0
    }
    catch {
        Write-Host "An error occurred while restarting the service '$serviceName': $_"
		exit 1
    }
}
else {
    Write-Host "Service '$serviceName' does not exist."
	exit 1
}
