
function PerformSelfMaintaining {
	$wallsAPI = New-WebServiceProxy -Uri "http://localhost/APIService/APIService.svc?wsdl" -Namespace WebServiceProxy -Class WB -UseDefaultCredential
    Write-Host "Starting Self-Maintaining..."
    $wallsAPI.PerformSelfMaintaining($null)
    Write-Host "Successfully kicked off Self-Maintaining process"
}
function Restart-WinService($serviceName, $computerName)
{
	#remote logic determines whether the server to be restarted is the local server. If so, a different command is needed (for some reason....)
	Write-Host "Restarting $serviceName on $computerName...`n"
	$remote = [System.Net.Dns]::GetHostAddresses($x).IPAddressToString -notmatch [System.Net.Dns]::GetHostAddresses($local)[1].IPAddressToString
	if ($remote -eq $true)
	{
		Get-Service -Name $serviceName -ComputerName $computerName | Restart-Service
	}
	else
	{
		Restart-Service $serviceName
	}
}

Export-ModuleMember -Function PerformSelfMaintaining
