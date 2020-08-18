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