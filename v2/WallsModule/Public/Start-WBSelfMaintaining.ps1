function Start-WBSelfMaintaining {
    [CmdletBinding()]param()
    process {
        Write-Host "Starting Self-Maintaining..."
        $wallsAPI = New-WebServiceProxy -Uri "http://localhost/APIService/APIService.svc?wsdl" -Namespace WebServiceProxy -Class WB -UseDefaultCredential
        $wallsAPI.PerformSelfMaintaining($null)
        Write-Host "Successfully kicked off Self-Maintaining process"
    }
}
