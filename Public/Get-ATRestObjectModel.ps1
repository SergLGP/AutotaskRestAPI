<#
.SYNOPSIS
    Returns an object with empty fields based on given Autotask resource.
.DESCRIPTION
    Gives you an Autotask object intended for creating or updating an existing resource.
.PARAMETER Resource
    Generates Object based on given Autotask Resource.
.PARAMETER Example
    Get variable types and picklist values from your Autotask instance.
.OUTPUTS
    [PSCustomObject]
.EXAMPLE
    Get-ATRestObjectModel -Resource Tickets
    Returns an empty Ticket object for you to populate and post or patch.
.EXAMPLE
    Get-ATRestObjectModel -Resource Tickets -Example
    Returns a populated Ticket object with variable types for values, intended to see available fields and expected variable types. Do not use to post or patch.
#>
function Get-ATRestObjectModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][switch]$Example
    )
    DynamicParam {
        $Script:DynParameters['Model']
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        $ModelName = ($Swagger.paths.PSObject.Properties.Value.post | Where-Object { $_.tags -eq $Resource }).parameters.schema.'$ref'.Split('/')[-1]

        $Object = New-Object -TypeName PSCustomObject
        $ResourceURL = (($Script:Queries | Where-Object { $_.Get -eq $Resource }).Name | Select-Object -First 1) -Replace "/query", ""

        $ObjectTemplate = (Invoke-RestMethod -Uri "$($Script:ATBaseURL)$($ResourceURL)/entityInformation/fields" -Headers $Script:ATHeader -Method Get).fields

        $UDFs = (Invoke-RestMethod -Uri "$($Script:ATBaseURL)$($ResourceURL)/entityInformation/userdefinedfields" -Headers $Script:ATHeader -Method Get).fields | Select-Object -Property Name, Value
        Add-Member -InputObject $Object -NotePropertyName 'UserdefinedFields' -NotePropertyValue $UDFs -Force

        if ($Example) {
            foreach ($Item in $ObjectTemplate) { 
                $ExpectedValue = if ($Item.picklistValues) { $Item.picklistValues | Select-Object -Property label, value, isActive } else { $($Item.datatype) }
                Add-Member -InputObject $Object -NotePropertyName $Item.Name -NotePropertyValue $ExpectedValue -Force
            }
        } else {
            foreach ($Item in $Swagger.definitions.$ModelName.properties.PSObject.Properties) {
                Add-Member -InputObject $Object -NotePropertyName $Item.Name -NotePropertyValue $null -Force
            }
        }

        $Names = if ($UDFs) { $ObjectTemplate.name + "UserDefinedFields" } else { $ObjectTemplate.name }

        return $Object | Select-Object $Names
    }
}