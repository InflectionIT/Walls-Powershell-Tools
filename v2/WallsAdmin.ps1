Using module .\WallsModule\Walls.psm1

function Show-Menu {
    param (
        [string]$Title = 'Options'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "Please select System Administration operation to perform"
    Write-Host "1: Press '1' to restart IIS App Pools"
    Write-Host "2: Press '2' to restart Scheduler service"
    Write-Host "3: Press '3' to kick off Self-Maintaining"
    Write-Host "4: Press '4' to kick off Full Repair"
    Write-Host "5: Press '5' to run data quality checks"
    Write-Host "6: Press '6' to generate Handover Guide"
    Write-Host "7: Press '7' to initiate Auto-Escalation"
    Write-Host "8: Press '8' to restart Extension Service"
    Write-Host "Q: Press 'Q' to quit."
}
 
do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            Clear-Host
            Restart-WBAppPools
        } '2' {
            Clear-Host
            Restart-WBSchedulerService
        } '3' {
            Clear-Host
            StartSelfMaintaining
        } '4' {
            Clear-Host
            GetExtensionList 
            $script:extensionList | Format-Table
            $input = Read-Host "Please make a selection"
            $extension = $script:extensionList.where( {$_.ID -eq $input})
            StartFullRepair $extension[0].Extension
        } '5' {
            Clear-Host
            RunDataChecks
        } '6' {
            Clear-Host
            GenerateHandoverGuide
        } '7' {
            Clear-Host
            $input = Read-Host "Please enter an email address to send escalation to"
            $issue = Read-Host "Please enter short description of the question or issue"
            $takeScreenshot = Read-Host "Would you like to include a screenshot? [y/n]"
            $takeScreenshot = if ($takeScreenshot -eq 'y') { 1 } else { 0 }
            GenerateAutoEscalation -Email $input -SendEmail 1 -takeScreenshot $takeScreenshot -issue $issue
        } '8' {
            Clear-Host
            Restart-WBExtensionService -ExtServerName "ADD EXTENSIONSERVERNAME"  
        } 'q' {
            return
        }
    }
    pause
}
until ($input -eq 'q')
