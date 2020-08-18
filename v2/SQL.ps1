$connectionString = ""

function Set-ConnectionString($config)
{
    $connectionString = "Data Source=$($config.Server);Initial Catalog=$($config.Database);"
    If ($config.UseSSP -eq 'True') { $connectionString += "Integrated Security=SSPI;" } 
    Else { $connectionString += "User ID=$($config.User); Password=$($config.Password);" }
}

function Test-SQLConnection
{    
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();

        return $true;
    }
    catch
    {
        return $false;
    }
}

function Invoke-SQL {
    Param (
        [Parameter(Mandatory = $true)][string]$Query = $(throw "Please specify a query."),
        [Parameter(Mandatory = $false)][int]$CommandTimeout = 0
    )
    
    Write-Verbose "Connection String: $connectionString"
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
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
