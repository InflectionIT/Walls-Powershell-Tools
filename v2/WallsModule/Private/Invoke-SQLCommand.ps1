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