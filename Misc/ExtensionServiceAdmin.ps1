Import-Module .\WallsSQL.psm1
Import-Module .\Utility.psm1

function RestartAllExtensionServices {
    Write-Host "Restarting ALL Extension services..."
    $extServers = Get-ExtensionServices
    foreach ($extServer in $extServers) {
        Restart-WinService "WBExtensionService" $extServer
    }
    Write-Host "All Extension services restarted"
}

function Get-ExtensionServices {
	$extServers = @()
	$SQLQuery = "select ConfigValue1 from Config where ConfigVariable = 'MessageBus::ReceiverXML'"
	$configs = Invoke-SqlCommand -Query $SQLQuery
	$messageBusXML = [xml]$configs.ConfigValue1
	$receivers = $messageBusXML.receivers.receiver
	foreach ($r in $receivers)
	{
		$pos = $r.IndexOf("@")
		$extServer = $r.Substring($pos + 1)
		$extServers += $extServer
	}
	return $extServers
}

function RestartAppPools {
    Write-Host = "Starting App pool restart..."
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 WallsAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 APIServiceAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 ActivityTrackerAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 CentralAdminAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 MatterTeamManagerAppPool"
    Write-Host "App pool restart completed"
}

function RestartSchedulerService {
    Write-Host "Restarting Walls Scheduler Service"
    Restart-Service "WBSchedulerService"
    Write-Host "Walls Scheduler Service restart completed"
}

function Show-Menu {
    param (
        [string]$Title = 'Options'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "Please select Extension Service operation to perform"
    Write-Host "1: Press '1' to restart ALL Extension services"
    Write-Host "2: Press '2' to list Extension services"
    Write-Host "3: Press '3' to get executing Extension jobs"
    Write-Host "4: Press '4' to export Extension services"
    Write-Host "Q: Press 'Q' to quit."
}

do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            Clear-Host
            RestartAllExtensionServices
        } '2' {
            Clear-Host
            RestartAppPools
        } '3' {
            Clear-Host
            RestartSchedulerService
        } 'q' {
            return
        }
    }
    pause
}
until ($input -eq 'q')