# Get text lines from file that contain 'function' 
$functionList = Select-String -Path "Powershell Studio Code.txt" -Pattern "function"

# Iterate through all of the returned lines
foreach ($functionDef in $functionList)
{
    # Get index into string where function definition is and skip the space
    $funcIndex = ([string]$functionDef).LastIndexOf(" ") + 1

    # Get the function name from the end of the string
    $FunctionExport = ([string]$functionDef).Substring($funcIndex)

    Write-Output $FunctionExport
}