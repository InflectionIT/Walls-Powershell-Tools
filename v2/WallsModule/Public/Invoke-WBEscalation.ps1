function Invoke-WBEscalation {
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
        $errorLogHTML = $errorLog | Select-Object ServiceType, ServiceId, LogLevel, LogMessage, LogException, Created | ConvertTo-Html -Fragment | Out-String
    
        $configs = Invoke-SqlCommand -Query "select ConfigVariable, ConfigValue1, ConfigValue2, Category from config where ConfigVariable not like '%password%' 
            AND (Category in (SELECT Category from dbo.Config where (ConfigVariable like '%IsActive' and ConfigValue1=1))
            OR Category in (SELECT ConfigValue2 from dbo.Config where (Category='Modules' and ConfigValue1=1))
            ) order by Category, ConfigVariable asc"
        $configsHTML = $configs | Select-Object ConfigVariable, ConfigValue1, ConfigValue2, Category | ConvertTo-Html -Fragment | Out-String

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