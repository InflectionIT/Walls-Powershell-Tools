@{
    # If authoring a script module, the RootModule is the name of your .psm1 file
    RootModule = 'Walls.psm1'

    Author = 'Alan Westley <alan.westley@inflectionit.com>'

    CompanyName = 'InflectionIT'

    ModuleVersion = '1.0'

    # Use the New-Guid command to generate a GUID, and copy/paste into the next line
    GUID = '8e0e10c2-b6e4-40bd-bb4d-54f6dc80ed38'

    Copyright = '(c) 2019 InflectionIT'

    Description = 'PowerShell module to interact with Intapp Walls application'

    # Minimum PowerShell version supported by this module (optional, recommended)
    PowerShellVersion = '5.1'

    # Which PowerShell Editions does this module work with? (Core, Desktop)
    CompatiblePSEditions = @('Desktop', 'Core')

    # Which PowerShell functions are exported from your module? (eg. Get-CoolObject)
    FunctionsToExport = @('Invoke-WBIISReqs','Invoke-WBDataChecks','Invoke-WBEscalation')

    # Which PowerShell aliases are exported from your module? (eg. gco)
    AliasesToExport = @('')

    # Which PowerShell variables are exported from your module? (eg. Fruits, Vegetables)
    VariablesToExport = @('')

    # PowerShell Gallery: Define your module's metadata
    PrivateData = @{
        PSData = @{
            # What keywords represent your PowerShell module? (eg. cloud, tools, framework, vendor)
            # Tags = @('')

            # What software license is your code being released under? (see https://opensource.org/licenses)
            # LicenseUri = ''

            # What is the URL to your project's website?
            # ProjectUri = ''

            # What is the URI to a custom icon file for your project? (optional)
            # IconUri = ''

            # What new features, bug fixes, or deprecated features, are part of this release?
            #ReleaseNotes = @'
#'@
        }
    }

    # If your module supports updateable help, what is the URI to the help archive? (optional)
    # HelpInfoURI = ''
}