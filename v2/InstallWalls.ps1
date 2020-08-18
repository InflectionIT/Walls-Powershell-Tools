Using module .\WallsModule\Walls.psm1
<#
Menu options:
- Create/modify configuration
- View configuration
- Perform installation

Questions: 
- Where do installers live? Is this a configurable option in the JSON?
- For new installs, ability to install Java (for IB)?
- Past v6.4, need 2 DLLs on extension server (Sarina to send notes)

Functions:
- Read configuration from database (extension servers, API, scheduler service, etc.)
#>

$destdir = "c:\windows\temp"
function CopyFile {
    param($session, $sourcefile)

    Copy-Item -Path $sourcefile -ToSession $session -Destination "$destdir\$sourcefile"
}

function CreateSession {
    param($computername)

    $session = New-PSSession -ComputerName $computername
    return $session
}

function RunRemoteInstaller{
    param($session, $command)

    Invoke-Command -Session $session -ScriptBlock {
        "$destdir\$command"
    }
}

function InstallExe {
    param($server, $filename, $command, $featurename)
    if ($server -ne "")
    {
        Write-Host "Connecting to $($server)"
        $session = CreateSession -computername $server
        Write-Host "Copying $filename to server"
        $path = "$PSScriptRoot\Installers\$filename"
        CopyFile -session $session -sourcefile $path 
        Write-Host "Running $featurename installer"
        RunRemoteInstaller -session $session -command $command
        Write-Host -ForegroundColor Green "$featurename installed"
    }
    else {        
        & $filename $command
    }
}
function InstallWalls() {
    $params = @{
        server = $config.walls.server 
        filename = "WBApplicationSetup.exe" 
        featurename = "Walls"
        command = "/verysilent /VirtualDir='$($config.walls.virtualdir)' /DatabaseServer='$($config.database.server)' /DatabaseName='$($config.database.database)' /AuthType='$($config.database.authtype)' /UserName='$($config.database.user)' /Password='$($config.database.password)'"
        #command = /verysilent /VirtualDir="Walls" /DatabaseServer="(local)" /DatabaseName="walls" /AuthType="SQL" /UserName="sa" /Password="Tsunami9!"
    }
    InstallExe @params
}

function InstallAPI() {
    $params = @{
        server = $config.apiserver.server 
        filename = "APIServiceSetup.exe" 
        featurename = "API Service"
        command = "APIServiceSetup.exe /verysilent /VirtualDir=""$($config.apiserver.virtualdir)"" /DatabaseServer=""$($config.database.server)"" /DatabaseName=""$($config.database.database)"" /AuthType=""$($config.database.authtype)"" /UserName=""$($config.database.user)"" /Password=""$($config.database.password)"""
    }

    InstallExe @params 
}

function InstallSchedulerService() {
    $params = @{
        server = $config.schedulerservice.server 
        filename = "SchedulerServiceSetup.exe" 
        featurename = "Scheduler Service"
        command = "SchedulerServiceSetup.exe /verysilent /DatabaseServer=""$($config.database.server)"" /DatabaseName=""$($config.database.database)"" /AuthType=""$($config.database.authtype)"" /UserName=""$($config.database.user)"" /Password=""$($config.database.password)"""
    }

    InstallExe @params
}

function InstallExtensionService() {
    param($server)
    #Add logic to deal with multiple extension servers
    InstallExe -server $server -filename "ExtensionServiceSetup.exe" -featurename "Extension Service" 
}

function InstallCentralAdmin() {
    $params = @{
        server = $config.centraladmin.server 
        filename = "CentralAdministrationSetup.exe" 
        featurename = "Central Administration"
        command = "CentralAdministrationSetup.exe /verysilent /VirtualDir=""$($config.centraladmin.virtualdir)"" /DatabaseServer=""$($config.database.server)"" /DatabaseName=""$($config.database.database)"" /AuthType=""$($config.database.authtype)"" /UserName=""$($config.database.user)"" /Password=""$($config.database.password)"""
    }

    InstallExe @params
}

function InstallActivityTracker() {
    InstallExe -server $config.activitytracker.server -filename "ActivityTrackerApplicationSetup.exe" -featurename "Activity Tracker" 
}

function InstallTeamManager() {
    $params = @{
        server = $config.teammanager.server 
        filename = "TeamManagerApplicationSetup.exe" 
        featurename = "Team Manager"
        command = "TeamManagerApplicationSetup.exe /verysilent /VirtualDir=""$($config.teammanager.virtualdir)"" /DatabaseServer=""$($config.database.server)"" /DatabaseName=""$($config.database.database)"" /AuthType=""$($config.database.authtype)"" /UserName=""$($config.database.user)"" /Password=""$($config.database.password)"""
    }

    InstallExe @params
}

function InstallApps() {
    if (!(Test-Path "$PSScriptRoot\InstallWalls.json")) {
        Write-Warning "Config file does not exist. Please run option 1 to create config file"
    } else {
        $configFile = "$PSScriptRoot\InstallWalls.json"  
        $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

        if ($config.walls.installwalls -eq $true) {
            InstallWalls
        }
        if ($config.apiservice.installAPIService -eq $true) {
            InstallAPI
        }
        if ($config.schedulerservice.installSchedulerService -eq $true) {
            InstallSchedulerService
        }
        if ($config.extensionservice.installExtensionService -eq $true) {
            $servers = $config.extensionservice.servers
            foreach($server in $servers) {
                InstallExtensionService -server $server
            }
        }
        if ($config.centraladmin.installcentraladmin -eq $true) {
            InstallCentralAdmin
        }
        if ($config.teammanager.installTeamManager -eq $true) {
            InstallTeamManager
        }
        if ($config.activitytracker.installActivityTracker -eq $true) {
            InstallActivityTracker
        }
    }
}

function CreateConfigFromExistingInstall() {
    $configFile = "$PSScriptRoot\InstallWalls.json"  
    $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    Clear-Host
    Write-Host "================= Generate Walls installation configuration ================="
    Write-Host "This script helps you prepare a Walls installation/upgrade based on an existing database"
    Write-Host "============================================================================="
    Write-Host ""    

    Set-ConnectionString($config.database)

    ### Walls ###
    Write-Host "Reading Walls configuration"
    $wallsqueue = Get-ConfigValue -ConfigVariable "WallsMessageQueue"
    $wallsqueueconfig = $wallsqueue.ConfigValue1
    $results = $wallsqueueconfig | Select-String -Pattern '<receiver>[a-zA-Z0-9_-]+@([a-zA-Z0-9_-]+)' -AllMatches
    foreach($result in $results.Matches)
    {
        $config.walls.server = $result.Groups[1].Value
    }

    ### Extension Service ###
    Write-Host "Reading Extension Service configuration"
    $config.extensionservice.servers = @()
    $messagebusrow = Get-ConfigValue -ConfigVariable "MessageBus::ReceiverXML"
    $messagebusconfig = $messagebusrow.ConfigValue1
    $results = $messagebusconfig | Select-String -Pattern '<receiver>[a-zA-Z0-9_-]+@([a-zA-Z0-9_-]+)' -AllMatches
    foreach($result in $results.Matches)
    {
        $config.extensionservice.servers += $result.Groups[1].Value
    }

    ### API Service ###
    Write-Host "Reading API Service configuration"
    $APIqueuerow = Get-ConfigValue -ConfigVariable "APIServiceMessageQueue"
    $APIqueueconfig = $APIqueuerow.ConfigValue1
    $results = $APIqueueconfig | Select-String -Pattern '<receiver>[a-zA-Z0-9_-]+@([a-zA-Z0-9_-]+)' -AllMatches
    foreach($result in $results.Matches)
    {
        $config.apiservice.server = $result.Groups[1].Value
    }

    ### Activity Tracker ###
    Write-Host "Reading Activity Tracker configuration"
    $ATqueuerow = Get-ConfigValue -ConfigVariable "ActivityTrackerMessageQueue"
    $ATqueueconfig = $ATqueuerow.ConfigValue1
    $results = $ATqueueconfig | Select-String -Pattern '<receiver>[a-zA-Z0-9_-]+@([a-zA-Z0-9_-]+)' -AllMatches
    if ($results.Matches.Count -gt 0) {
        $config.activitytracker.installActivityTracker = $true
        foreach($result in $results.Matches)
        {
            $config.activitytracker.server = $result.Groups[1].Value
        }
    }

    ### Team Manager ###
    Write-Host "Reading Team Manager configuration"
    $ATqueuerow = Get-ConfigValue -ConfigVariable "TeamManagerMessageQueue"
    $TMqueueconfig = $TMqueuerow.ConfigValue1
    $results = $TMqueueconfig | Select-String -Pattern '<receiver>[a-zA-Z0-9_-]+@([a-zA-Z0-9_-]+)' -AllMatches
    if ($results.Matches.Count -gt 0) {
        $config.teammanager.installTeamManager = $true
        foreach($result in $results.Matches)
        {
            $config.teammanager.server = $result.Groups[1].Value
        }    
    }

    $config | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\InstallWalls.json"
    Write-Host "Installation config file created - InstallWalls.json"
}

function GenerateNewConfig() {
    $configFile = "$PSScriptRoot\InstallWalls.json"  
    $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    Clear-Host
    Write-Host "================= Generate Walls installation configuration ================="
    Write-Host "This script helps you prepare a Walls installation/upgrade"
    Write-Host "Please answer the following questions to generate the necessary configuration"
    Write-Host "============================================================================="
    Write-Host ""
    
    #Database information
    Write-Host "[Database information]" -ForegroundColor Green
    $config.database.Server = Read-Host "Enter the server name where the Walls Database will be located" 
    $config.database.Database = Read-Host "Enter the Walls database name"
    $config.database.UseSSP = Read-Host "Would you like to use integrated authentication (Windows login) to access the database [Y/N]"
    if ($config.database.UseSSP -eq "Y") {
        $config.database.UseSSP = "true"
        $config.database.User  = ""
        $config.database.Password = ""
    } 
    else {
        $config.database.UseSSP = "false"
        $config.database.User = Read-Host "Enter the database username"
        $config.database.Password = Read-Host "Enter the database password"
    }

    #Walls installation
    Write-Host "============================================================================="
    Write-Host "[Walls web application information]" -ForegroundColor Green
    $config.walls.server = Read-Host "Enter the IIS server for Walls"
    $config.walls.virtualdir = Read-Host "Enter the virtual directory for Walls (usually 'walls')"
    
    #Extension Service
    Write-Host "============================================================================="
    Write-Host "[Extension Service information]" -ForegroundColor Green
    $config.extensionservice.installExtensionService = Read-Host "Do you want to install the Extension Service [Y/N]"
    if ($config.extensionservice.installExtensionService -eq "Y") { $config.extensionservice.installExtensionService = "true" }

    #Scheduler Service
    Write-Host "============================================================================="
    Write-Host "[Scheduler Service information]" -ForegroundColor Green
    $config.schedulerservice.installSchedulerService = Read-Host "Do you want to install the Scheduler Service [Y/N]"
    if ($config.schedulerservice.installSchedulerService -eq "Y") { $config.schedulerservice.installSchedulerService = "true" }

    #API Service
    Write-Host "============================================================================="
    Write-Host "[API Service information]" -ForegroundColor Green
    $config.apiservice.installAPIService = Read-Host "Do you want to install the API Service [Y/N]"
    if ($config.apiservice.installAPIService -eq "Y") { $config.apiservice.installAPIService = "true" }

    #Team Manager 
    Write-Host "============================================================================="
    Write-Host "[Team Manager information]" -ForegroundColor Green
    $config.teammanager.installTeamManager = Read-Host "Do you want to install Team Manager [Y/N]"
    if ($config.teammanager.installTeamManager -eq "Y") { 
        $config.teammanager.installTeamManager = "true"    
        $config.teammanager.server = Read-Host "Enter the server name for Team Manager"
        $config.teammanager.virtualdir = Read-Host "Enter the virtual directory for Team Manager (usually 'MTM')"
    }

    #Activity Tracker
    Write-Host "============================================================================="
    Write-Host "[Activity Tracker information]" -ForegroundColor Green
    $config.activitytracker.installActivityTracker = Read-Host "Do you want to install Activity Tracker [Y/N]"
    if ($config.activitytracker.installActivityTracker -eq "Y") { 
        $config.activitytracker.installActivityTracker = "true"     
        $config.activitytracker.server = Read-Host "Enter the server name for Activity Tracker"   
        $config.activitytracker.virtualdir = Read-Host "Enter the virtual directory for Activity Tracker (usually 'ActivityTracker')"
        $config.activitytracker.IntDBHost = Read-Host "Enter the server name where the Intermediate DB will be located"    
        $config.activitytracker.IntDBName = Read-Host "Enter the Intermediate database name"
        $config.activitytracker.IntDBUser = Read-Host "Enter the Intermediate database username"
        $config.activitytracker.IntDBPassword = Read-Host "Enter the Intermediate database username"
    }

    #Central Admin
    Write-Host "============================================================================="
    Write-Host "[Central Administration information]" -ForegroundColor Green
    $config.centraladmin.installcentraladmin = Read-Host "Do you want to install Central Administration [Y/N]"
    if ($config.centraladmin.installcentraladmin -eq "Y") { 
        $config.centraladmin.installcentraladmin = "true"    
        $config.centraladmin.server = Read-Host "Enter the server name for Central Admin"  
        $config.centraladmin.virtualdir = Read-Host "Enter the virtual directory for Central Administration"
    }

    #Wrap-up
    Write-Host "============================================================================="
    Write-Host "[Finishing up]" -ForegroundColor Green
    $config | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\InstallWalls.json"   
    Write-Host "Configuration has been saved to installWalls.json file" -ForegroundColor Green     
}

function ShowConfig() {
    $configFile = "$PSScriptRoot\InstallWalls.json"  
    $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    Clear-Host
    Write-Host "==================  Walls installation configuration ========================"
    Write-Host "The script will install the following components:"
    if ($config.walls.installWalls -eq "true") {
        Write-Host "Walls" -ForegroundColor Green -NoNewline
        Write-Host " (Virtual dir: $($config.walls.virtualdir))"
    }
    if ($config.extensionservice.installExtensionService -eq "true") {
        Write-Host "Extension Service" -ForegroundColor Green -NoNewline
        Write-Host " (server: $($config.extensionservice.servers))"
    }
    if ($config.apiservice.installAPIService -eq "true") {
        Write-Host "API Service" -ForegroundColor Green -NoNewline
        Write-Host " (Virtual dir: $($config.apiservice.virtualdir))"
    }       
    if ($config.schedulerservice.installSchedulerService -eq "true") {
        Write-Host "Scheduler Service" -ForegroundColor Green -NoNewline
        Write-Host " (server: $($config.schedulerservice.server))"
    }    
    if ($config.activitytracker.installActivityTracker -eq "true") {
        Write-Host "Activity Tracker" -ForegroundColor Green -NoNewline
        Write-Host " (server: $($config.activitytracker.server), virtualdir: $($config.activitytracker.virtualdir))"
    }    
    if ($config.teammanager.installTeamManager -eq "true") {
        Write-Host "Team Manager" -ForegroundColor Green -NoNewline
        Write-Host " (server: $($config.teammanager.server), virtualdir: $($config.teammanager.virtualdir))"
    }  
}

function Show-Menu {
    Clear-Host
    Write-Host "================ Walls Installation ================"
    Write-Host "Please select an option"
    Write-Host "1: Press '1' to create configuration for brand new installation"
    Write-Host "1: Press '2' to create configuration for an upgrade"
    Write-Host "2: Press '3' to view configuration file"
    Write-Host "3: Press '4' to kick off Walls installation"
    Write-Host "Q: Press 'Q' to quit."
}
 
do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            Clear-Host
            GenerateNewConfig
        } '2' {
            Clear-Host
            CreateConfigFromExistingInstall
        } '3' {
            Clear-Host
            ShowConfig        
        } '4' {
            Clear-Host
            InstallApps
        } 'q' {
            return
        }
    }
    pause
}
until ($input -eq 'q')

