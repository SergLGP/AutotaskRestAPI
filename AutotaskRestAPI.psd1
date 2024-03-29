@{
    RootModule = 'AutotaskRestAPI.psm1'
    ModuleVersion = '0.4'
    #CompatiblePSEditions = @('Desktop')
    GUID = '1abff155-5810-4fa0-800d-5765ac8e9a09'
    Author = 'Sergius Schweizer'
    CompanyName = 'Logiphys Datensysteme GmbH'
    Copyright = '(c) Logiphys Datensysteme GmbH. All rights reserved.'
    Description = 'Allows command line interaction with Autotask using the Rest API.'
    PowerShellVersion = '5.1'
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    # RequiredModules = @()
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        'Get-ATRestObjectFields',
        'Get-ATRestObjectModel',
        'Get-ATRestResource',
        'Initialize-ATRestApi',
        'New-ATRestResource',
        'Remove-ATRestResource',
        'Set-ATRestResource',
        'New-ATRestFilter'
    )
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    PrivateData = @{

        PSData = @{
            Tags = @("Autotask", "API", "REST", "Datto", "AutotaskAPI", "AutotaskPSA", "PSA", "Logiphys")
            LicenseUri = 'https://github.com/SergLGP/AutotaskRestAPI/blob/main/LICENSE'
            ProjectUri = 'https://github.com/SergLGP/AutotaskRestAPI'
            # IconUri = ''
            # ReleaseNotes = ''

        }
    }
    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''
}