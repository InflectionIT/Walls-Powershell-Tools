function Set-ConnectionString($config)
{
    if ([string]::IsNullOrWhiteSpace($config.Connectionstring))
    {
        $global:connectionString = "Data Source=$($config.Server);Initial Catalog=$($config.Database);"
        If ($config.UseSSP -eq 'True') { $global:connectionString += "Integrated Security=SSPI;" } 
        Else { $global:connectionString += "User ID=$($config.User); Password=$($config.Password);" }        
    }
    else {
        $global:connectionString = $config.Connectionstring
    }
}