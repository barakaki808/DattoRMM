# Get the OS drive letter (usually C:)
$osDrive = (Get-Volume | Where-Object {$_.DriveType -eq 'Fixed' -and $_.DriveLetter -eq 'C'}).DriveLetter

# Get the disk number for the OS drive
$diskNumber = (Get-Partition -DriveLetter $osDrive).DiskNumber

# Get the physical disk information for the OS drive
$osDisk = Get-PhysicalDisk | Where-Object {$_.DeviceID -eq $diskNumber}

# Check if the OS drive is an SSD
if ($osDisk.MediaType -eq 'SSD') {
    Write-Host "<-Start Result->"
    Write-Host "Result=OS Drive is SSD"
    Write-Host "<-End Result->"
    New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name "Custom30" -Value "OS-SSD" -PropertyType "String"
    Exit 0
} else {
    Write-Host "<-Start Result->"
    Write-Host "Result=OS Drive is HDD"
    Write-Host "<-End Result->"
    New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name "Custom30" -Value "OS-HDD" -PropertyType "String"
    Exit 1
}
