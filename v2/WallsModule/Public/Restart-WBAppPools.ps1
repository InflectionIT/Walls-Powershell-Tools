function Restart-WBAppPools {
    [CmdletBinding()]param()
    process {
        Write-Host = "Starting App pool restart..."
        C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 WallsAppPool"
        C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 APIServiceAppPool"
        C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 ActivityTrackerAppPool"
        C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 CentralAdminAppPool"
        C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 MatterTeamManagerAppPool"
        Write-Host "App pool restart completed"
    }
}