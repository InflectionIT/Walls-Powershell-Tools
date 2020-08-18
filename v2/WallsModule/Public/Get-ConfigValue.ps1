function Get-ConfigValue {
    param([string]$ConfigVariable)

    return Invoke-SQL -Query "SELECT * FROM Config WHERE ConfigVariable like '%$ConfigVariable%'"
}