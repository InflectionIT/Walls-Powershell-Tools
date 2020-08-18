$config = Import-PowerShellDataFile .\config.psd1
$script:connectionString

function BuildConnectionString
{
    $connServer = $config.Server
    $connDB = $config.Database
    if ($config.UseSSP) {
        $script:connectionString = "Data Source=$connServer;Initial Catalog=$connDB;Integrated Security=SSPI;"
    }
}

function Invoke-SqlCommand {
    Param (
        [Parameter(Mandatory=$false)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory=$false)][string]$Database,
        [Parameter(Mandatory=$false)][string]$Username,
        [Parameter(Mandatory=$false)][string]$Password,
        [Parameter(Mandatory=$false)][string]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory=$true)][string]$Query = $(throw "Please specify a query."),
        [Parameter(Mandatory=$false)][int]$CommandTimeout=0
    )
    
    #build connection string
    if (!$Server) { $Server = $config.Server }
    if (!$Database) { $Database = $config.Database }
    $connstring = "Data Source=$Server;Initial Catalog=$Database;"
    If ($UseWindowsAuthentication -eq 'True') { $connstring += "Trusted_Connection=Yes;Integrated Security=SSPI;" } 
    Else { $connstring += "User ID=$username; Password=$password;" }
    
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
    $adapter.Fill($dataset) | out-null
    
    #return the first collection of results or an empty array
    If ($dataset.Tables[0] -ne $null) { $table = $dataset.Tables[0] }
    ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }
    
    $connection.Close()
    return ,$table
}

$response = Invoke-SqlCommand -Query "select TOP 10 ServiceType, ServiceId, LogLevel, LogMessage, LogException, Created from ErrorLog order by created desc"
$response

Write-Host "**************************************************"

$response = $response | where {$_.LogMessage -like 'Started*' }
$response