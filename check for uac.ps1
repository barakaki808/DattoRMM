function write-DRRMAlert ($message) {
	write-host '<-Start Result->'
	write-host "Alert=$message"
	write-host '<-End Result->'
}

function write-DRMMDiag ($messages) {
	write-host '<-Start Diagnostic->'
	foreach ($Message in $Messages){ $Message }
	write-host '<-End  Diagnostic->'
}

$PSDenabled = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).PromptOnSecureDesktop
$CPAenabled = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).ConsentPromptBehaviorAdmin

if ($PSDenabled -Eq 1 -And $CPAenabled -Eq 5) {
	$message = "UAC is Enabled"
	write-DRRMAlert ($message)
    exit 0
}
else
{
	$message = "UAC is Disabled"
	write-DRRMAlert ($message)
	exit 1
}