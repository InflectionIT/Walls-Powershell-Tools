#INCOMPLETE - NEED TO MOVE GETEXTENSIONLIST TO PRIVATE FUNCTION
function Start-WBFullRepair {
    GetExtensionList 
    $script:extensionList | Format-Table
    $input = Read-Host "Please make a selection"
    $extension = $script:extensionList.where( {$_.ID -eq $input})
    RepairExtension $extension[0].Extension
}