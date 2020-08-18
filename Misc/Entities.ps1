Remove-Module "WallsSQL"
Remove-Module "Utility"
Import-Module .\WallsSQL.psm1
Import-Module .\Utility.psm1

function GetEntityUDFs {
    $SQLQuery = "select * from EntityCustomFieldConfig ORDER BY EntityTypeId ASC, Field ASC"
    $UDFs = Invoke-SqlCommand -Query $SQLQuery	
    WriteTable($UDFs)
    $UDFs | Out-File "data.csv"

    $UDFs | %{new-object psobject -property @{text=$_}} | Export-Csv test.csv  -NoTypeInformation                                              

    #$UDFs | Export-Csv -Path "data.csv"
	#$rowCount = Output-Data $UDFs "EntityCustomFieldConfig"
}

GetEntityUDFs