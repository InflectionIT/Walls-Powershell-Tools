function Install-WBExtensionServicePrereqs {
    param([string]$ExtServerName)
    Write-Host "Starting Extension Server prerequistes install..."
    Invoke-Command -ComputerName $ExtServerName -ScriptBlock {   
        Install-WindowsFeature -Name MSMQ -IncludeAllSubFeature
        Write-Host "MSMQ installed`n"
        Install-WindowsFeature -Name NET-Framework-45-Features
        Write-Host ".NET 4.5 installed"
        
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\" -Name "VisualFXSetting" -Value 2
        Write-Host "Modified Visual Settings to optimize for performance"
    }
}