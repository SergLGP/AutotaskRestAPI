<#
.SYNOPSIS
    Returns a custom Powershell object with field names based on a given Autotask resource. For Filters.
.DESCRIPTION
    The object contains all possible fields of a given resource, every field contains it's own name as it's value, so it can be used
    as a variable to create a filter.
.PARAMETER Resource
    Retrieves Object based on given Autotask Resource.
.OUTPUTS
    [PSCustomObject]
.EXAMPLE
    Get-ATRestObjectFields -Resource Tickets
    Gives an object with all possible fields an Autotask Ticket can have.
#>
function Get-ATRestObjectFields {
    [CmdletBinding()]
    param ()
    DynamicParam {
        $Script:DynParameters['Patch']
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        $Object = Get-ATRestObjectModel -Resource $Resource

        $ReturnObject = New-Object -TypeName hashtable
        
        foreach ($Name in $Object.PSObject.Properties.Name) {
            $ReturnObject.$Name = $Name
        }

        return New-Object -TypeName PSObject -Property $ReturnObject
    }
}