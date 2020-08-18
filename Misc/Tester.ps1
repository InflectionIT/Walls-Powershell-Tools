Remove-Module "WallsSQL"
Remove-Module "Utility"
Import-Module .\WallsSQL.psm1
Import-Module .\Utility.psm1

$dataTable = Invoke-SqlCommand -Query 'Select top 5 * from config' -UseWindowsAuthentication "True"

# foreach($row in $dataTable.Rows) 
# {
#     write-output " $($row.ConfigId) -  $($row.ConfigVariable) - $($row.ConfigValue1)"
# }

$dataTable | Out-GridView
WriteTable($dataTable)

## Writing objects to table using Format-Table -AutoSize
$a = @()
$a += [pscustomobject]@{a = "Alan"; b = "Westley"; c=3}
$a += [pscustomobject]@{a = 3; b = 4; c=5}
$a += [pscustomobject]@{a = 5; b = 6; c=7}

$a | Format-Table -AutoSize

"P@ssword1" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "c:\Password.txt"

$pass = Get-Content "C:\Password.txt" | ConvertTo-SecureString
Write-Host $pass

$File = "\\Machine1\SharedPath\Password.txt"
[Byte[]] $key = (1..16)
$Password = "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $key | Out-File $File

