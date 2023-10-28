# PowerShell Script to Monitor Print Queues and Exit with Code Based on Job Age

# Initialize a flag for old jobs
$oldJobDetected = $false

# Get the list of print jobs
$printJobs = Get-Printer -Full | Get-PrintJob

# Loop through each print job to check its age
foreach ($job in $printJobs) {
    $timeSubmitted = $job.TimeSubmitted
    $currentTime = Get-Date

    # Calculate the age of the print job in minutes
    $jobAge = ($currentTime - $timeSubmitted).TotalMinutes

    # Check if the job age is greater than 5 minutes
    if ($jobAge -gt 5) {
        $oldJobDetected = $true
        break
    }
}

# Exit with the appropriate code
if ($oldJobDetected) {
	Write-Host "<-Start Result->"
    Write-Host "Result=Print job older than 5 minutes detected"
	Write-Host "<-End Result->"
    exit 1
} else {
	Write-Host "<-Start Result->"
    Write-Host "Result=No problems found in print Queue"
	Write-Host "<-End Result->"
    exit 0
}
