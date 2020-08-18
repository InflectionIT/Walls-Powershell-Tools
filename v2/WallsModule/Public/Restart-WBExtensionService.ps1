function Restart-WBExtensionService {
    [CmdletBinding()]param([string]$ExtServerName)
    process {
        Write-Host "Restarting Extension Service"
        Invoke-Command -ComputerName $ExtServerName -ScriptBlock {
            Get-Service -Name "WBExtensionService" -ErrorAction SilentlyContinue | Restart-Service
        }
        Write-Host "Extension Service restart completed"
    }
}