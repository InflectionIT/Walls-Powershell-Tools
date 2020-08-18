Update-FormatData -AppendPath "walls.ps1xml"

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Repair-WBWall
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int[]]$WallID
    )

    Begin
    {
    }
    Process
    {
        foreach($id in $WallID){
            Write-Host "Starting RepairWall on Wall $id..."
	        $wallsAPI = New-WebServiceProxy -Uri "http://localhost/APIService/APIService.svc?wsdl" -Namespace WebServiceProxy -Class WB -UseDefaultCredential
	        $wallsAPI.RepairWall($id, 1)
	        Write-Host "RepairWall on Wall $id API call completed."
        }
    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-WBWallType
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int[]]$WallTypeID
    )

    Begin
    {
        Write-Verbose "Length of array is $($WallTypeID.length)"
    }
    Process
    {
        foreach($id in $WallTypeID){
            Write-Verbose "Retrieving Wall Type info for wall type $id..."
	        #Write-Host "RepairWall on Wall $id API call completed."

            $Properties = @{
            ComputerName = "test"
            Manufacturer = "dell"
            Model = "viao"
            OperatingSystem = "Windows 10"
            OperatingSystemVersion = "Home"
            }
    
            # Output Information
            $out = New-Object -TypeName PSobject -Property $Properties
            $out.PSObject.TypeNames.Insert(0,'Intapp.Walls.WallType')
            #Add-ObjectDetail -InputObject $out -TypeName Intapp.Walls.WallType
            Write-Output $out
        }
    }
    End
    {
    }
}