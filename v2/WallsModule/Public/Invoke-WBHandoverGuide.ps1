function Invoke-WBHandoverGuide {
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