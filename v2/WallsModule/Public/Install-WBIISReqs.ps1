function Install-WBIISReqs {
    param([string]$servername = '')
    Write-Host "Starting IIS prerequisites install..."
    
    Install-WindowsFeature -Name Web-Server, Web-Mgmt-Service
    Write-Host "Web Server installed"

    #Check IIS Version to determine which Mmgt feature to install
    #$iisInfo = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp\
    #$version = [decimal]"$($iisInfo.MajorVersion).$($iisInfo.MinorVersion)"
    ##I believe that this service is only needed for remote management. 
    #Install-WindowsFeature -Name Web-Mgmt-Service

    Install-WindowsFeature -Name Web-Windows-Auth
    Write-Host "Windows Authentication installed"

    Install-WindowsFeature -Name MSMQ -IncludeAllSubFeature
    Write-Host "MSMQ installed"

    Install-WindowsFeature -Name NET-Framework-45-Features
    Write-Host ".NET 4.5 Features installed"

    Install-WindowsFeature -Name NET-WCF-HTTP-Activation45
    Write-Host "WCF HTTP Activation installed"
    
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\" -Name "VisualFXSetting" -Value 2
    Write-Host "Modified Visual Settings to optimize for performance"
    
    #Add Internet Explorer
    $TargetFile = "C:\Program Files\Internet Explorer\iexplore.exe"
    $ShortcutFile = "$env:Public\Desktop\Internet Explorer.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.Save()
    Write-Host "Added to Desktop: Internet Explorer"
    
    # Add Services Shortchut to desktop
    $TargetFile = "%windir%\system32\services.msc"
    $ShortcutFile = "$env:Public\Desktop\Services.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.Save()
    Write-Host "Added to Desktop: Services Shortcut"
    
    # Add IIS Shortchut to desktop
    $TargetFile = "%windir%\system32\inetsrv\InetMgr.exe"
    $ShortcutFile = "$env:Public\Desktop\IIS.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.Save()
    Write-Host "Added to Desktop: IIS Shortcut"
}