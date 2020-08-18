function RepairExtension {
    param (
        [string]$Extension = 'ALL'
    )
    Clear-Host
    Write-Host "Starting Full Repair for Extension: $Extension"
    if ($Extension -eq 'ALL') { $Extension = '' }
    $wallsAPI = New-WebServiceProxy -Uri "http://localhost/APIService/APIService.svc?wsdl" -Namespace WebServiceProxy -Class WB -UseDefaultCredential
    $wallsAPI.PerformFullSecurityRepair($Extension, $null, "IgnoreLegalHoldSecurity", $null)
    Write-Host "Successfully kicked off Full Repair for Extension: $Extension"
}
