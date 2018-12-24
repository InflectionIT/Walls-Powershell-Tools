$config = Import-PowerShellDataFile .\config.psd1
$script:extensionList = $null

#-----------------------------------------------------------
#-------------------- SQL Functions ------------------------
#-----------------------------------------------------------
function Invoke-SqlCommand {
    Param (
        [Parameter(Mandatory = $false)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory = $false)][string]$Database,
        [Parameter(Mandatory = $false)][string]$Username,
        [Parameter(Mandatory = $false)][string]$Password,
        [Parameter(Mandatory = $false)][string]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory = $true)][string]$Query = $(throw "Please specify a query."),
        [Parameter(Mandatory = $false)][int]$CommandTimeout = 0
    )
    
    #BuildConnectionString    
    #build connection string
    if (!$Server) { $Server = $config.Server }
    if (!$Database) { $Database = $config.Database }
    $connstring = "Data Source=$Server;Initial Catalog=$Database;"
    If ($UseWindowsAuthentication -eq 'True') { $connstring += "Integrated Security=SSPI;" } 
    Else { $connstring += "User ID=$username; Password=$password;" }
    Write-Verbose "Connection String: $connstring"
    
    #Write-Output $connstring

    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()
    
    #build query object
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = $CommandTimeout
    
    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    [void]$adapter.Fill($dataset) #| out-null
    
    #return the first collection of results or an empty array
    If ($null -ne $dataset.Tables[0]) { $table = $dataset.Tables[0] }
    ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }
    
    $connection.Close()
    return , $table

}

#-----------------------------------------------------------
#------------------ Utility Functions ----------------------
#-----------------------------------------------------------
function Encrypt($StringToEncrypt) {
    #Taken from https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-410ef9df
    function Encrypt-String($String, $Passphrase, $salt = "SaltCrypto", $init = "IV_Password", [switch]$arrayOutput) { 
        # Create a COM Object for RijndaelManaged Cryptography 
        $r = new-Object System.Security.Cryptography.RijndaelManaged 
        # Convert the Passphrase to UTF8 Bytes 
        $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
        # Convert the Salt to UTF Bytes 
        $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
        # Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits 
        $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
        # Create the Intersecting Vector Cryptology Hash with the init 
        $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
     
        # Starts the New Encryption using the Key and IV    
        $c = $r.CreateEncryptor() 
        # Creates a MemoryStream to do the encryption in 
        $ms = new-Object IO.MemoryStream 
        # Creates the new Cryptology Stream --> Outputs to $MS or Memory Stream 
        $cs = new-Object Security.Cryptography.CryptoStream $ms, $c, "Write" 
        # Starts the new Cryptology Stream 
        $sw = new-Object IO.StreamWriter $cs 
        # Writes the string in the Cryptology Stream 
        $sw.Write($String) 
        # Stops the stream writer 
        $sw.Close() 
        # Stops the Cryptology Stream 
        $cs.Close() 
        # Stops writing to Memory 
        $ms.Close() 
        # Clears the IV and HASH from memory to prevent memory read attacks 
        $r.Clear() 
        # Takes the MemoryStream and puts it to an array 
        [byte[]]$result = $ms.ToArray() 
        # Converts the array from Base 64 to a string and returns 
        return [Convert]::ToBase64String($result) 
    }
    $encrypted = Encrypt-String $StringToEncrypt "InflectionIT" 
}

function Decrypt($StringToDecrypt) {
    function Decrypt-String($Encrypted, $Passphrase, $salt = "SaltCrypto", $init = "IV_Password") { 
        # If the value in the Encrypted is a string, convert it to Base64 
        if ($Encrypted -is [string]) { 
            $Encrypted = [Convert]::FromBase64String($Encrypted) 
        } 
 
        # Create a COM Object for RijndaelManaged Cryptography 
        $r = new-Object System.Security.Cryptography.RijndaelManaged 
        # Convert the Passphrase to UTF8 Bytes 
        $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
        # Convert the Salt to UTF Bytes 
        $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
        # Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits 
        $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
        # Create the Intersecting Vector Cryptology Hash with the init 
        $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
 
 
        # Create a new Decryptor 
        $d = $r.CreateDecryptor() 
        # Create a New memory stream with the encrypted value. 
        $ms = new-Object IO.MemoryStream @(, $Encrypted) 
        # Read the new memory stream and read it in the cryptology stream 
        $cs = new-Object Security.Cryptography.CryptoStream $ms, $d, "Read" 
        # Read the new decrypted stream 
        $sr = new-Object IO.StreamReader $cs 
        # Return from the function the stream 
        Write-Output $sr.ReadToEnd() 
        # Stops the stream     
        $sr.Close() 
        # Stops the crypology stream 
        $cs.Close() 
        # Stops the memory stream 
        $ms.Close() 
        # Clears the RijndaelManaged Cryptology IV and Key 
        $r.Clear() 
    } 
    return  Decrypt-String $StringToDecrypt "InflectionIT" 
}

#-----------------------------------------------------------
#-------------------- Walls Functions ----------------------
#-----------------------------------------------------------
function Get-WallsIISPaths {
    $apps = @()
    #Walls APP Pools
    $apps += (Get-WebApplication | Where-Object { $_.applicationPool -like "*WallsAppPool*" })
    #API App Pools
    $apps += (Get-WebApplication | Where-Object { $_.applicationPool -like "*APIServiceAppPool*" })
    #Module App Pools
    $apps += (Get-WebApplication | Where-Object { $_.applicationPool -like "*ActivityTrackerAppPool*" })
    $apps += (Get-WebApplication | Where-Object { $_.applicationPool -like "*MatterTeamManagerAppPool*" })
    $apps += (Get-WebApplication | Where-Object { $_.applicationPool -like "*MatterTeamManagerAppPoolERRORTEST*" })
    return $apps
}

function InstallIISServerPrereqs {
    Write-Host "Starting IIS prerequisites install..."
    
    Install-WindowsFeature -Name Web-Server, Web-Mgmt-Service
    Write-Host "Web Server installed"

    #Check IIS Version to determine which Mmgt feature to install
    $iisInfo = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp\
    $version = [decimal]"$($iisInfo.MajorVersion).$($iisInfo.MinorVersion)"
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

function InstallExtensionServicePrereqs {
    Write-Host "Starting Extension Server prerequistes install..."
    Install-WindowsFeature -Name MSMQ -IncludeAllSubFeature
    Write-Host "MSMQ installed`n"
    Install-WindowsFeature -Name NET-Framework-45-Features
    Write-Host ".NET 4.5 installed"
	
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\" -Name "VisualFXSetting" -Value 2
    Write-Host "Modified Visual Settings to optimize for performance"
	
    # Add Internet Explorer Shortchut to desktop
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
}

function RestartAppPools {
    Write-Host = "Starting App pool restart..."
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 WallsAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 APIServiceAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 ActivityTrackerAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 CentralAdminAppPool"
    C:\WINDOWS\system32\inetsrv\appcmd recycle apppool "ASP.NET v4.0 MatterTeamManagerAppPool"
    Write-Host "App pool restart completed"
}

function RestartSchedulerService {
    Write-Host "Restarting Walls Scheduler Service"
    Restart-Service "WBSchedulerService"
    Write-Host "Walls Scheduler Service restart completed"
}

function StartSelfMaintaining {
    Write-Host "Starting Self-Maintaining..."
    $wallsAPI = New-WebServiceProxy -Uri "http://localhost/APIService/APIService.svc?wsdl" -Namespace WebServiceProxy -Class WB -UseDefaultCredential
    $wallsAPI.PerformSelfMaintaining($null)
    Write-Host "Successfully kicked off Self-Maintaining process"
}

function GetExtensionList {
    $sql = 'SELECT * from (
            SELECT 0 as [ID], ''ALL'' as Extension from config
            UNION
            SELECT ROW_NUMBER() over (ORDER BY ConfigVariable) as [ID], left(ConfigVariable, charindex('':'', ConfigVariable, 0) -1) as Extension from config where configvariable like ''%isactive'' and ConfigValue1 = 1
            ) t
            order by t.[ID]'

    #Write-Host $sql
    $script:extensionList = Invoke-SqlCommand -Query $sql 
    #$script:extensionList | Format-Table
}

function StartFullRepair {
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

function RunDataChecks {
    $data = GetDataCheckInfo
    Write-Host $data.MatterNoKeyMap " Matters with no EntityKeyMap entry"
    Write-Host $data.MatterBadPairing " Matters with mismatched client/matter pairing in EntityKeyMap"
    Write-Host $data.DuplicateEntities " Duplicate user/group/client entities"
    Write-Host $data.DuplicateMatterEntities " Duplicate matter entities"
    Write-Host $data.MatterBadClients " Matters with bad clients"
    Write-Host $data.EntityBlankSystemID " Entities with blank entityRemoteSystemId"
    Write-Host $data.EntitySpaces " Entity IDs with spaces in the name"
}

function GetDataCheckInfo {
    # Get Matters with no EntityKeyMap
    $MatterNoKeyMap = Invoke-SqlCommand -Query "select count(*) as count from Entities e left join EntityKeyMap ekm on e.EntityId = ekm.EntityId 
        where ekm.EntityId is null and e.EntityTypeId = 4"

    # Get Matters with mismatched client/matter pairing in EntityKeyMap
    $MatterBadPairing = Invoke-SqlCommand -Query "select count(*) as count from Entities e 
        inner join entities e2 on e.entitytypeid=4 and e2.entitytypeid=3 and e.parentremotesystemid=e2.entityremotesystemid 
        left join entitykeymap ekm on ekm.entityid=e.entityid and ekm.parententityid=e2.entityid 
        where ekm.entityid is null"

    # Get Duplicate user/group/client entities
    $DuplicateEntities = Invoke-SqlCommand -Query "SELECT COUNT(*) as count from Entities e
        join Entities e2 on e.EntityTypeId=e2.EntityTypeId and e.EntityId<>e2.EntityId
        and 
        (
        e.EntityRemoteSystemId=e2.EntityRemoteSystemId
        --or ISNULL(NULLIF(e.FinancialSystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.FinancialSystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.TimeEntrySystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.TimeEntrySystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.RecordsSystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.RecordsSystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.WindowsNetworkLogon, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.WindowsNetworkLogon, e2.EntityRemoteSystemId), '')
        )
        WHERE e.EntityTypeId<>4"

    # Duplicate matter entities
    $DuplicateMatterEntities = Invoke-SqlCommand -Query "select count(*) as count from
    (
    select EntityRemoteSystemId, entitytypeid, parentRemoteSystemId, count(entityRemotesystemid) as count from dbo.entities group by EntityRemoteSystemId, entitytypeid, parentRemoteSystemId 
    having entitytypeid=4 and count(entityRemotesystemid)>1
    ) t"

    # Matters with bad clients
    $MatterBadClients = Invoke-SqlCommand -Query "select count(*) as count
    from dbo.entities where entitytypeid=4 and (ParentRemoteSystemId is null or ParentRemoteSystemId='' or ParentTypeId<>3)"

    # Entities with blank entityRemoteSystemID
    $EntityBlankSystemID = Invoke-SqlCommand -Query "select count(*) as count
        from dbo.entities where entityremotesystemid=''"

    # Entity IDs with spaces in the name
    $EntitySpaces = Invoke-SqlCommand -Query "select count(*) as count
        from Entities 
        where ((EntityRemoteSystemId like '% ' OR EntityRemoteSystemId like ' %') 
        OR (EntityDisplayId like '% ' OR EntityDisplayId like ' %') 
        OR (TimeEntrySystemId like '% ' OR TimeEntrySystemId like ' %') 
        OR (RecordsSystemId like '% ' OR RecordsSystemId like ' %') 
        OR (FinancialSystemId like '% ' OR FinancialSystemId like ' %'))"

    [PSCustomObject]@{
        MatterNoKeyMap          = $MatterNoKeyMap.rows[0].count;
        MatterBadPairing        = $MatterBadPairing.rows[0].count;
        DuplicateEntities       = $DuplicateEntities.rows[0].count;
        DuplicateMatterEntities = $DuplicateMatterEntities.rows[0].count;
        MatterBadClients        = $MatterBadClients.rows[0].count;
        EntityBlankSystemID     = $EntityBlankSystemID.rows[0].count;
        EntitySpaces            = $EntitySpaces.rows[0].count;
    }
}

function GenerateHandoverGuide {
    Import-Module WebAdministration

    function Get-ApplicationVersion {
        $response = Invoke-SqlCommand -Query "select ConfigValue1 from config where configvariable = 'AppVersion'"
        #Write-Host "Application Version: " $response.rows[0].ConfigValue1
        return $response.rows[0].ConfigValue1
    }

    function Get-Modules {
        $response = Invoke-SqlCommand -Query "SELECT ConfigValue2 as Category from dbo.Config where (Category='Modules' and ConfigValue1=1) and ConfigValue2 not in ('Intapp Walls', 'Walls and Security') ORDER BY ConfigValue2"
        $modules = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Active Modules: $modules"
        return $modules
    }

    function Get-AppUsers {
        $response = Invoke-SqlCommand -Query "select Name, Email, ar.RoleName from ApplicationUsers au join ApplicationRolesWB ar on ar.RoleId=au.WBRoleId where userId<>-1 and IsDeleted=0 and IsEnabled=1"
        $appusers = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "App Users: $appusers"
        return $appusers
    }

    function Get-Libraries {
        $response = Invoke-SqlCommand -Query  "select '<libraries>
		<library>
			<name>' + Category + '</name>
			<connectString>' + ConfigValue1 + '</connectString>
		</library>
	    </libraries>' as ConfigValue1, Category from Config where ConfigVariable like '%ConnectionString' and REPLACE(Category, 'Webview', 'Elite') in
        (
        SELECT REPLACE(Category, 'Webview', 'Elite') from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1)
        )
        UNION ALL
        select ConfigValue1, Category from Config where ConfigVariable like '%LibraryXML' and Category in
        (
        SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1)
        )"
        
        $colName = New-Object system.Data.DataColumn 'name', ([string])
        $colServer = New-Object system.Data.DataColumn 'server', ([string])
        $colDB = New-Object system.Data.DataColumn 'db', ([string])
        $response.columns.add($colName)
        $response.columns.add($colServer)
        $response.columns.add($colDB)

        $sb = New-Object System.Data.Common.DbConnectionStringBuilder
        $rows = $response.rows
        ForEach ($r in $rows) {
            #parse XML
            $xml = [xml]$r.ConfigValue1
            $libraries = $xml.SelectNodes("//libraries/library")
            foreach ($library in $libraries) {
                $sb.set_ConnectionString($library.connectString.Trim())
                $r.name = $library.name.Trim()
                #Enter data in the row
                if ($sb.Contains("server")) {
                    $r.server = $sb.server
                }
                else {
                    $r.server = $sb.'data source'
                }
			
			
                if ($sb.Contains("database")) {
                    $r.db = $sb.database
                }
                else {
                    $r.db = $sb.'initial catalog'
                }		
            }
        }
        $response.columns.remove('ConfigValue1')
        $libraries = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Libraries: $libraries"
        return $libraries
    }

    function Get-Schedules {
        $response = Invoke-SqlCommand -Query "select ConfigVariable, ConfigValue1 from Config where ConfigVariable like '%CronExpression' and Category in
            (
            SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1)
            )"
        $schedules = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Schedules: $schedules"
        return $schedules
    }

    function Get-SQLVersion {
        $response = Invoke-SqlCommand -Query "select @@VERSION as version"
        $SQLVersion = $response.rows[0].version | ConvertTo-Json
        #Write-Host "SQL Version: $SQLVersion"
        return $SQLVersion
    }

    function Get-Extensions {
        $response = Invoke-SqlCommand -Query "SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1) ORDER BY Category"
        $extensions = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Extension List: $extensions"
        return $extensions
    }

    function Get-EXTServers {
        $response = Invoke-SqlCommand -Query "select ConfigValue1 from Config where configvariable = 'MessageBus::ReceiverXML'"
        
        $colServer = New-Object system.Data.DataColumn 'Server', ([string])
        $colIP = New-Object system.Data.DataColumn 'IP', ([string])
        $response.columns.add($colServer)
        $response.columns.add($colIP)

        $rows = $response.rows
        ForEach ($r in $rows) {
            #parse XML
            $xml = [xml]$r.ConfigValue1
            $extServers = $xml.SelectNodes("//receivers/receiver")
            foreach ($extServer in $extServers) {
                #Create a row
                $EXT_Server = $extServer.'#text'.Replace("IntAppExtensionServiceQueue@", "").Trim()
                try {
                    $EXT_IP = Resolve-DnsName $EXT_Server -Type A -erroraction 'silentlycontinue'
                    $EXT_IP = $EXT_IP[0].IPAddress
                }
                catch {
                    $EXT_IP = "Unable to obtain IP address for server"
                    "Unable to obtain IP address for server: " + $EXT_Server
                }
			
                #Enter data in the row
                $r.Server = $EXT_Server
                $r.IP = $EXT_IP
            }
        }
        $response.columns.remove('ConfigValue1')
        $EXTServers = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Extension List: $EXTServers"
        return $EXTServers
    }
    
    function Get-Configs {
        $response = Invoke-SqlCommand -Query "select ConfigVariable, ConfigValue1, ConfigValue2, Category from config where ConfigVariable not like '%password%' 
            AND 
            (
            Category in (SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1))
            OR
            Category in (SELECT ConfigValue2 from dbo.Config where (Category='Modules' and ConfigValue1=1))
            )
            order by Category, ConfigVariable asc"
        $rows = $response.rows
        ForEach ($r in $rows) {
            if ($null -eq $r.ConfigValue1) {
                $r.ConfigValue1.Replace("<", "&lt;").Replace(">", "&gt;") 
            }
        }
        $configs = ConvertTo-Json @($response | Select-Object $response.Columns.ColumnName)
        #Write-Host "Configs: $configs"
        return $configs
    }

    function Get-ServiceAccount {
        $response = Invoke-SqlCommand -Query "select ConfigValue1 from Config where configvariable = 'ExtensionServiceUsername'"
        $ServiceAccount = $response.rows[0].ConfigValue1 | ConvertTo-Json
        #Write-Host "Service Account: $ServiceAccount"
        return $ServiceAccount
    }

    function Get-SQLIP {
        $SQLServer = $config.Server
        try {
            ##If SQL Named instance, take everything before the \
            #$SQLServerVar = [regex]::Match($SQLServer, "^[^\\]*").Value
            #$SQL_IP = Resolve-DnsName $SQLServerVar -Type A -erroraction 'silentlycontinue'
            $SQL_IP = Resolve-DnsName $SQLServer -Type A -erroraction 'silentlycontinue'
            return $SQL_IP[0].IPAddress
        }
        catch {
            return "Unable to obtain IP address for SQL server: $SQLServer"
        }
    }

    function Get-IISAppPools {
        $IIS_AppPools = Get-ChildItem -Path IIS:\AppPools\ | Out-String
        $IIS_AppPools = $IIS_AppPools.Split("`n")
        $table = New-Object system.Data.DataTable ""
        $col1 = New-Object system.Data.DataColumn 'line', ([string])
        $table.columns.add($col1)
        ForEach ($r in $IIS_AppPools) {
            #Create a row
            $row = $table.NewRow()
            #Enter data in the row
            $row.'line' = '>' + $r
		
            #Add the row to the table
            $table.Rows.Add($row)
        }
        $IIS_AppPools = ConvertTo-Json @($table | Select-Object $table.Columns.ColumnName)
        return $IIS_AppPools
    }

    function Get-IISSites {
        #Get Walls IIS Paths
        $apps = Get-WallsIISPaths
    
        #Build Table
        $table = New-Object system.Data.DataTable ""
        $col1 = New-Object system.Data.DataColumn 'line', ([string])
        $table.columns.add($col1)
        ForEach ($app in $apps) {
            $row = $table.NewRow()
            $row.'line' = $app.applicationPool + " - $IIS_hostname" + $app.path + ": " + $app.PhysicalPath
            $table.Rows.Add($row)
        }
        $IIS_Sites = ConvertTo-Json @($table | Select-Object $table.Columns.ColumnName) 
        return $IIS_Sites       
    }

    function Read-MultiLineInputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText) {
        <#
    .SYNOPSIS
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .DESCRIPTION
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .PARAMETER Message
    The message to display to the user explaining what text we are asking them to enter.
     
    .PARAMETER WindowTitle
    The text to display on the prompt window's title.
     
    .PARAMETER DefaultText
    The default text to show in the input box.
     
    .EXAMPLE
    $userText = Read-MultiLineInputDialog "Input some text please:" "Get User's Input"
     
    Shows how to create a simple prompt to get mutli-line input from a user.
     
    .EXAMPLE
    # Setup the default multi-line address to fill the input box with.
    $defaultAddress = @'
    John Doe
    123 St.
    Some Town, SK, Canada
    A1B 2C3
    '@
     
    $address = Read-MultiLineInputDialog "Please enter your full address, including name, street, city, and postal code:" "Get User's Address" $defaultAddress
    if ($address -eq $null)
    {
        Write-Error "You pressed the Cancel button on the multi-line input box."
    }
     
    Prompts the user for their address and stores it in a variable, pre-filling the input box with a default multi-line address.
    If the user pressed the Cancel button an error is written to the console.
     
    .EXAMPLE
    $inputText = Read-MultiLineInputDialog -Message "If you have a really long message you can break it apart`nover two lines with the powershell newline character:" -WindowTitle "Window Title" -DefaultText "Default text for the input box."
     
    Shows how to break the second parameter (Message) up onto two lines using the powershell newline character (`n).
    If you break the message up into more than two lines the extra lines will be hidden behind or show ontop of the TextBox.
     
    .NOTES
    Name: Show-MultiLineInputDialog
    Author: Daniel Schroeder (originally based on the code shown at http://technet.microsoft.com/en-us/library/ff730941.aspx)
    Version: 1.0
    #>
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
     
        # Create the Label.
        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Size(10, 10) 
        $label.Size = New-Object System.Drawing.Size(280, 20)
        $label.AutoSize = $true
        $label.Text = $Message
     
        # Create the TextBox used to capture the user's text.
        $textBox = New-Object System.Windows.Forms.TextBox 
        $textBox.Location = New-Object System.Drawing.Size(10, 40) 
        $textBox.Size = New-Object System.Drawing.Size(575, 200)
        $textBox.AcceptsReturn = $true
        $textBox.AcceptsTab = $false
        $textBox.Multiline = $true
        $textBox.ScrollBars = 'Both'
        $textBox.Text = $DefaultText
     
        # Create the OK button.
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Size(415, 250)
        $okButton.Size = New-Object System.Drawing.Size(75, 25)
        $okButton.Text = "OK"
        $okButton.Add_Click( { $form.Tag = $textBox.Text; $form.Close() })
     
        # Create the Cancel button.
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Size(510, 250)
        $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
        $cancelButton.Text = "Cancel"
        $cancelButton.Add_Click( { $form.Tag = $null; $form.Close() })
     
        # Create the form.
        $form = New-Object System.Windows.Forms.Form 
        $form.Text = $WindowTitle
        $form.Size = New-Object System.Drawing.Size(610, 320)
        $form.FormBorderStyle = 'FixedSingle'
        $form.StartPosition = "CenterScreen"
        $form.AutoSizeMode = 'GrowAndShrink'
        $form.Topmost = $True
        $form.AcceptButton = $okButton
        $form.CancelButton = $cancelButton
        $form.ShowInTaskbar = $true
     
        # Add all of the controls to the form.
        $form.Controls.Add($label)
        $form.Controls.Add($textBox)
        $form.Controls.Add($okButton)
        $form.Controls.Add($cancelButton)
     
        # Initialize and show the form.
        $form.Add_Shown( {$form.Activate()})
        $form.ShowDialog() > $null   # Trash the text of the button that was clicked.
     
        # Return the text that the user entered.
        return $form.Tag
    }

    Write-Host "#############################################################"
    Write-Host "Please answer the following ten questions before continuting"
    Write-Host "#############################################################"
    
    #Parse input values
    $email = Read-Host "1/10 Please enter email address to send report"
    $TextInfo = (Get-Culture).TextInfo
    $SE = $TextInfo.ToTitleCase([regex]::Match($email, "^[^@]*").Value.Replace(".", " "))
    $client_name = Read-Host "2/10 Please enter client name"
    $ibversion = Read-Host "3/10 Please enter Integrate version"
    $user_source = Read-Host "4/10 Please enter User source application"
    $user_server = Read-Host "5/10 Please enter User source server name"
    $user_db = Read-Host "6/10 Please enter User source DB name"
    $cm_source = Read-Host "7/10 Please enter Client/Matter source application"
    $cm_server = Read-Host "8/10 Please enter Client/Matter source server name"
    $cm_db = Read-Host "9/10 Please enter Client/Matter source DB name"

    $customizations = Read-MultiLineInputBoxDialog -Message "10/10 Please enter all customizations you made to the system" -WindowTitle "Customizations" -DefaultText "Enter some text here..."
    if ($null -eq $customizations) { Write-Host "You clicked Cancel on the Customizations input box" }

    Write-Host ""
    Write-Host "Starting data gathering for handover guide"

    #Run SQL Queries
    $version = Get-ApplicationVersion
    $modules = Get-Modules
    $appusers = Get-AppUsers
    $libraries = Get-Libraries
    $schedules = Get-Schedules
    $SQLVersion = Get-SQLVersion
    $extensions = Get-Extensions
    $EXTServers = Get-EXTServers
    $configs = Get-Configs
    $ServiceAccount = Get-ServiceAccount

    #Run additional information
    $SQL_IP = Get-SQLIP
    $WindowsVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
    $IIS_hostname = Hostname
    $IIS_IP = Resolve-DnsName $IIS_hostname -Type A
    $IIS_Sites = Get-IISSites
    $IIS_AppPools = Get-IISAppPools

    #Put data in JSON format
    $body = "
    { 
        ""email"": ""$email"",
        ""client_name"": ""$client_name"", 
        ""version"": ""$version"", 
        ""SE"": ""$SE"", 
        ""extensions"": $extensions,
        ""modules"": $modules, 
        ""cm_source"": ""$cm_source"",  
        ""user_source"": ""$user_source"", 
        ""appusers"": $appusers,  
        ""IBversion"": ""$ibversion"", 
        ""cm_db"": ""$cm_db"", 	
        ""cm_server"": ""$cm_server"", 
        ""user_db"": ""$user_db"",
        ""user_server"": ""$user_server"",  
        ""connections"": $libraries, 
        ""schedules"": $schedules, 
        ""SQLVersion"": $SQLVersion,
        ""SQLDB"": ""$SQLDB"",
        ""SQLServer"": ""$SQLServer"",
        ""SQL_IP"": ""$SQL_IP"",
        ""ServiceAccount"": $ServiceAccount,
        ""WindowsVersion"": ""$WindowsVersion"",
        ""IIS_hostname"": ""$IIS_hostname"",
        ""IIS_IP"": ""$IIS_IP"",
        ""IIS_Sites"": $IIS_Sites,
        ""IIS_AppPools"": $IIS_AppPools,
        ""EXTServers"": $EXTServers,
        ""SRTtext"": ""$SRTtext"",
        ""customizations"": ""$customizations"",
        ""configs"": $configs
    }"

    #Save $body to text file
    $body > 'HandoverGuideBody.txt'
    Write-Host "Check HandoverGuideBody.txt file for results"

    #Prepare web merge
    Write-Host "Creating and sending email..."
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $mergeUrl = 'https://www.webmerge.me/merge/87189/2wpdmn'
    #$response = Invoke-RestMethod $mergeUrl -Method Post -Headers $headers -Body $body
    Write-Host "Finished handover guide - sent to $email"
}

function GenerateAutoEscalation {
    param (
        [string]$Email = "steve.surrette@inflectionIT.com",
        [string]$htmlRows = 100,
        [string]$csvRows = 1000,
        [bool]$SendEmail = 1, 
        [bool]$takeScreenshot = 0,
        [string]$issue
    )
    function takeScreenshot($File) {
        Add-Type -AssemblyName System.Windows.Forms
        Add-type -AssemblyName System.Drawing
		
        # Gather Screen resolution information
        $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $Width = $Screen.Width
        $Height = $Screen.Height
        $Left = $Screen.Left
        $Top = $Screen.Top
		
        # Create bitmap using the top-left and bottom-right bounds
        $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
		
        # Create Graphics object
        $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
		
        # Capture screen
        $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
		
        # Save to file
        $bitmap.Save($File)
    }

    function GenerateConfigsCSV {
        $response = Invoke-SqlCommand -Query  "select ConfigVariable, ConfigValue1, ConfigValue2, Category from Config where ConfigVariable not like '%password%' order by ConfigVariable asc"
        $response | export-csv ".\Output\configs.csv" -noTypeInformation
        return $response
    }

    function GenerateErrorLogCSV {
        $response = Invoke-SqlCommand -Query "select TOP $csvRows ServiceType, ServiceId, LogLevel, LogMessage, LogException, Created from ErrorLog order by created desc"
        $response | export-csv ".\Output\errorlog.csv" -noTypeInformation
        return $response
    }

    function GenerateExtensionServiceJobs {
        $response = Invoke-SqlCommand -Query "SELECT TOP $csvRows [ExtensionServiceName],[ExtensionType],[LibraryName],[JobType],[JobXML],[JobState],[FinalStatus]
            ,[Retries],[QueueTime],[StateLastChangedTime],[StartTime],[EndTime],[Messages],[OperationId]
            FROM [dbo].[ExtensionServiceJobs] ORDER BY [QueueTime] desc"
        $response | export-csv ".\Output\extensionservicejobs.csv" -noTypeInformation
        return $response
    }

    function PullLogFiles {
        #Clear out old log files
        $folderName = $PSScriptRoot + "\Output\Logs"
        if (Test-Path $folderName) {
            Remove-Item $folderName -Force -Recurse
        }

        #Get IIS Log files
        $apps = Get-WallsIISPaths
        foreach ($app in $apps) {
            $searchPath = $app.PhysicalPath + "\Logs"
            if (Test-Path $searchPath) {
                $destinationPath = $folderName + "\" + $app.path + "\"
                Copy-Item $searchPath $destinationPath -Recurse -force
            }
        }

        #Get Extension Service log files    
        $response = Invoke-SqlCommand -Query "select ConfigValue1 from Config where configvariable = 'MessageBus::ReceiverXML'"
        $messageBusXML = [xml]$response.ConfigValue1
        $receivers = $messageBusXML.receivers.receiver
        foreach ($r in $receivers) {
            $pos = $r.IndexOf("@")
            $extServer = $r.Substring($pos + 1)
            $source = "\\$extServer\C$\Program Files (x86)\Intapp\WBExtensionService\Logs\"
            $destinationPath = $folderName + "\EXT\" + $extServer + "\"
            Copy-Item -Path $source -Destination $destinationPath -Recurse -force
        }

        #Create Zip file
        $fileName = $folderName + "\logs.zip"
        if (Test-Path $fileName) {
            #delete if exists
            Remove-Item $fileName
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        $Zip = [System.IO.Compression.ZipFile]::Open($fileName, 'Create')
        $i = 0
        Do {
            #$regex = "(debug\.log\.[1-1]$|extensions\.log\.[1-$logFileCount]$|\.log$)"
            if ($i -eq 0) {
                $regex = "\.log$"
            }
            else {
                $regex = "\.log\.$i$"
            }
		
            $SourceFiles = Get-Childitem $folderName -Recurse | Where-Object { $_.Name -match $regex }
            ForEach ($SourceFile in $SourceFiles) {
                $SourcePath = $SourceFile.Fullname
                #$SourceName = $SourceFile.Name
                $SourceName = $SourcePath.Replace($folderName + "\", "")
                $null = [System.IO.Compression.ZipFileExtensions]::
                CreateEntryFromFile($Zip, $SourcePath, $SourceName, $CompressionLevel)
            }
            $zipSize = (Get-Item $fileName).Length / 1024
            $predictNextSize = $zipSize + ($zipSize - $lastSize)
            $lastSize = $zipSize
            $i++
        }
        while ($predictNextSize -lt 7000 -and $i -lt 10)
	
        $Zip.Dispose()
        return $fileName
    }

    function PrepareEmailHTML {
        $data = GetDataCheckInfo
        $dataHTML = "
            {0} Matters with no EntityKeyMap entry<br/>
            {1} Matters with mismatched client/matter pairing in EntityKeyMap<br/>
            {2} Duplicate user/group/client entities<br/>
            {3} Duplicate matter entities<br/>
            {4} Matters with bad clients<br/>
            {5} Entities with blank entityRemoteSystemId<br/>
            {6} Entity IDs with spaces in the name<br/>" -f $data.MatterNoKeyMap, $data.MatterBadPairing, $data.DuplicateEntities, $data.DuplicateMatterEntities, $data.MatterBadClients, $data.EntityBlankSystemID, $data.EntitySpaces 

        $extservicejobs = $extservicejobs | Where-Object {$null -ne $_.Messages} 
        if ($extservicejobs.Rows.Count -gt $htmlRows) {$extservicejobs = $extservicejobs[0..$htmlRows - 1]}
        $extservicejobsHTML = $extservicejobs | ConvertTo-Html -Fragment | Out-String
        
        $errorLog = $errorLog | Where-Object {$_.LogLevel -ne "Info"}  #Another Example: {$_.LogMessage -like 'Started*' }
        if ($errorLog.Rows.Count -gt $htmlRows) { $errorLog = $errorLog[0..$htmlRows - 1] }
        $errorLogHTML = $errorLog | Select ServiceType, ServiceId, LogLevel, LogMessage, LogException, Created | ConvertTo-Html -Fragment | Out-String
    
        $configs = Invoke-SqlCommand -Query "select ConfigVariable, ConfigValue1, ConfigValue2, Category from config where ConfigVariable not like '%password%' 
            AND (Category in (SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1))
            OR Category in (SELECT ConfigValue2 from dbo.Config where (Category='Modules' and ConfigValue1=1))
            ) order by Category, ConfigVariable asc"
        $configsHTML = $configs | Select ConfigVariable, ConfigValue1, ConfigValue2, Category | ConvertTo-Html -Fragment | Out-String

        $body = "<html>
            <style>
                TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
                TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
                TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
            </style>
            <body>
            <h2>Inflection IT Auto Escalation</h2>
            <h3>Question / Issue</h3>$issue<br/><hr/>
            <h3>Reproduction Steps:</h3><p>(Solution Engineer fill out)<br>1. <br>2. <br>3. <br>4. <br>* Actual: <br>* Expected: <br></p><br/><hr/>
            <h3>Data Quality Checks</h3>$dataHTML<br/><hr/>
            <h3>dbo.extensionservicejobs (non-empty Messages only, see CSV for full)</h3>$extservicejobsHTML<br/><hr/> 
            <h3>dbo.error (INFO type filtered out, see CSV for for full info)</h3>$errorLogHTML<br/><hr/>
            <h3>dbo.config (filtered for only enabled modules/extensions, see CSV for full info [minus passwords])</h3>$configsHTML<br/><hr/>
            </body></html>" #-f $issue, $dataHTML, $extservicejobsHTML, $errorLogHTML, $configsHTML

        
        return $body
    }

    Write-Host "*******************************************************"
    #Delete existing output path
    $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    Get-ChildItem -Directory $ScriptDir | Remove-Item -Recurse
    #Remove-Item –path $outputPath –recurse
    $outputPath = $ScriptDir + "\Output"
    mkdir $outputPath -Force | Out-Null

    #Generate configs (CSV & HTML) <-- There may be two different queries here
    Write-Host "Getting config data..."
    $configs = GenerateConfigsCSV

    #Get Error Logs (CSV & HTML)
    Write-Host "Getting error logs (this may take ~30 seconds)..."
    $errorLog = GenerateErrorLogCSV

    #Get ExtensionServiceJobs (CSV & HTML)
    Write-Host "Getting Extension Service Jobs..."
    $extservicejobs = GenerateExtensionServiceJobs

    #Get Log Files
    Write-Host "Getting log files (this may take ~30 seconds)..."
    $logFiles = PullLogFiles

    #Take Screenshot
    if ($takeScreenshot -eq 1) {
        Write-Host "Taking screenshot..."
        $Screenshot = $PSScriptRoot + "\Output\screenshot.bmp"
        takeScreenshot($Screenshot)
    }
    
    #Prepare Email Body
    Write-Host "Constructing email and attachments..."
    $body = PrepareEmailHTML
    $file = $PSScriptRoot + "\Output\configs.csv"
    $att = new-object Net.Mail.Attachment($file)
    $file = $PSScriptRoot + "\Output\errorlog.csv"
    $att2 = new-object Net.Mail.Attachment($file)
    $file = $PSScriptRoot + "\Output\extensionservicejobs.csv"
    $att3 = new-object Net.Mail.Attachment($file)
    $attLogs = new-object Net.Mail.Attachment($logFiles)
    
    #Send Email
    Write-Host "Sending email..."
    $smtpServer = "email-smtp.us-west-2.amazonaws.com"
    $smtpPort = 587
    $username = Decrypt "0kopTjk1NeL3AOXD4pQBKksMRn/JIH3P6ZCXoJ6j6yw=" 
    $password = Decrypt "fZ7PPC5I7pJVcHANu3zhq7M/usc6ctP2tzDEU8a6nmuZVLmXzlC+caYqymBwWjXq" 
    $from = "steve.surrette@inflectionIT.com"
    $subject = "Inflection IT Walls Auto-escalation"
    $smtp = new-object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.Credentials = new-object Net.NetworkCredential($username, $password)
    $msg = new-object Net.Mail.MailMessage
    $msg.From = $from
    $msg.To.Add($Email)
    $msg.Subject = $subject
    $msg.Body = $body
    $msg.IsBodyHtml = 1
    $msg.Attachments.Add($att)
    $msg.Attachments.Add($att2)
    $msg.Attachments.Add($att3)
    $msg.Attachments.Add($attLogs)
    if ($takeScreenshot -eq 1) { $msg.Attachments.Add($Screenshot) }
    if ($sendEmail -eq 1) {
        $smtp.Send($msg)        
    }
    
    Write-Host "*******************************************************"
    Write-Host "Finished auto-escalation process - email sent to $Email"
}

function Show-Menu {
    param (
        [string]$Title = 'Options'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "Please select System Administration operation to perform"
    Write-Host "1: Press '1' to install IIS Server Prerequisites"
    Write-Host "2: Press '2' to install Extension Server Prerequisites"
    Write-Host "3: Press '3' to restart IIS App Pools"
    Write-Host "4: Press '4' to restart Scheduler service"
    Write-Host "5: Press '5' to kick off Self-Maintaining"
    Write-Host "6: Press '6' to kick off Full Repair"
    Write-Host "7: Press '7' to run data quality checks"
    Write-Host "8: Press '8' to generate Handover Guide"
    Write-Host "9: Press '9' to initiate Auto-Escalation"
    Write-Host "Q: Press 'Q' to quit."
}
 
do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            Clear-Host
            InstallIISServerPrereqs
        } '2' {
            Clear-Host
            InstallExtensionServicePrereqs
        } '3' {
            Clear-Host
            RestartAppPools
        } '4' {
            Clear-Host
            RestartSchedulerService
        } '5' {
            Clear-Host
            StartSelfMaintaining
        } '6' {
            Clear-Host
            GetExtensionList 
            $script:extensionList | Format-Table
            $input = Read-Host "Please make a selection"
            $extension = $script:extensionList.where( {$_.ID -eq $input})
            StartFullRepair $extension[0].Extension
        } '7' {
            Clear-Host
            RunDataChecks
        } '8' {
            Clear-Host
            GenerateHandoverGuide
        } '9' {
            Clear-Host
            $input = Read-Host "Please enter an email address to send escalation to"
            $issue = Read-Host "Please enter short description of the question or issue"
            $takeScreenshot = Read-Host "Would you like to include a screenshot? [y/n]"
            $takeScreenshot = if ($takeScreenshot -eq 'y') { 1 } else { 0 }
            GenerateAutoEscalation -Email $input -SendEmail 1 -takeScreenshot $takeScreenshot -issue $issue
        } 'q' {
            return
        }
    }
    pause
}
until ($input -eq 'q')