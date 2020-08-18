function get-myDiskInfo {
    param (
        [string]$ComputerName
        )
 
    $Dev = get-CimInstance -class Win32_OperatingSystem -ComputerName $ComputerName | Select-Object -expandproperty SystemDevice
    $Disk = Get-CimInstance -Class Win32_LogicalDisk -ComputerName $ComputerName -filter "drivetype='3'" | Select-Object -Property DeviceID,Size,FreeSpace
 
    $props = @{
           "HardDisk"= $dev
           "DeviceID" = $Disk.DeviceID
           "DiskSize" = $Disk.Size
           "FreeSpace" = $Disk.FreeSpace
           }
 
    $obj = New-Object -TypeName PSObject -Property $props
    $obj | Format-Table -AutoSize
}