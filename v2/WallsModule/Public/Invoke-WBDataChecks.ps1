function Invoke-WBDataChecks {
    $data = Get-DataCheckInfo
    Write-Host $data.MatterNoKeyMap " Matters with no EntityKeyMap entry"
    Write-Host $data.MatterBadPairing " Matters with mismatched client/matter pairing in EntityKeyMap"
    Write-Host $data.DuplicateEntities " Duplicate user/group/client entities"
    Write-Host $data.DuplicateMatterEntities " Duplicate matter entities"
    Write-Host $data.MatterBadClients " Matters with bad clients"
    Write-Host $data.EntityBlankSystemID " Entities with blank entityRemoteSystemId"
    Write-Host $data.EntitySpaces " Entity IDs with spaces in the name"
}