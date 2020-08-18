function Invoke-SQL {
    Param (
        [Parameter(Mandatory = $true)][string]$Query = $(throw "Please specify a query."),
        [Parameter(Mandatory = $false)][int]$CommandTimeout = 0
    )
    
    Write-host "Connection String: $global:connectionString"
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
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
