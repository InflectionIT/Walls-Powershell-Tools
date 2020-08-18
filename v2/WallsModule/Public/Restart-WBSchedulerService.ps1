function Restart-WBSchedulerService {
    [CmdletBinding()]param()
    process {
        $service = "WBSchedulerService"
        if (Get-Service $service -ErrorAction SilentlyContinue) {
            Write-Host "Restarting Walls Scheduler Service"
            Restart-Service $service
            Write-Host "Walls Scheduler Service restart completed"
        }
        else {
            Write-Host "Unable to find Scheduler Service. Please ensure that the service is installed on this machine" -ForegroundColor Red
        }
    }
}