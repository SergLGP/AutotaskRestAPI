<#
.SYNOPSIS
    Changes all datetime fields in a given object into a UTC String for Autotask.
.DESCRIPTION
    The datetime String will be in the Autotask Rest API Format "yyyy-MM-ddThh:mm:ss.fffZ". Every field of type "System.DateTime" will turn into a string.
.PARAMETER InputObject
    PSCustomObject intended to post or patch an Autotask Resource.
.EXAMPLE
    Format-ATRestDates -InputObject $Object
    Does not return anything, it changes the datetime values within the given Object itself.
#>
function Format-ATRestDates {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]$InputObject
    )

    $DateFormat = "yyyy-MM-ddTHH:mm:ss.fffZ"

    if ($InputObject.GetType() -eq [hashtable]) {
        $Dates = $InputObject.GetEnumerator() | Where-Object { $_.Value.GetType() -eq [System.DateTime] }
    } else {
        $Dates = $InputObject.PSObject.Properties | Where-Object -Property TypeNameOfValue -eq "System.DateTime"
    }

    foreach ($Date in $Dates) {
        $ConvertedDate = $InputObject."$($Date.Name)".ToUniversalTime().ToString($DateFormat)
        $InputObject."$($Date.Name)" = $ConvertedDate
    }
}