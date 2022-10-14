<#
.SYNOPSIS
    Performs a 'DELETE' API call to the Autotask API.
.DESCRIPTION
    Deletes a resource from Autotask based on given ID.
.PARAMETER Resource
    The Autotask resource type you want to delete.
.PARAMETER ID
    To update a childitem within a resource based on ParentID.
.PARAMETER ParentID
    Alias for the ID Parameter.
.PARAMETER ChildID
    ID of the childitem you want to remove.
.PARAMETER PreviewURL
    Prints the finished request URL and exits without performing an API call.
.EXAMPLE
    Remove-ATRestResource -Resource TimeEntries -ID 12345
    Removes the time entry with ID 12345.
.EXAMPLE
    Remove-ATRestResource -Resource TicketChecklistItemsChild -ParentID 12345 -ChildID 56789
    Removes the Checklist item with ID 56789 from Ticket with ID 12345.
#>
function Remove-ATRestResource {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'ID', Mandatory = $true)][Alias("ParentID")][String]$ID,
        [Parameter(ParameterSetName = 'ID', Mandatory = $false)][String]$ChildID,
        [Parameter(Mandatory = $false)][switch]$PreviewURL
    )
    DynamicParam {
        $Script:DynParameters["Delete"]
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        if ((-not (Test-Path Variable:Script:ATHeader)) -or (-not (Test-Path Variable:Script:ATBaseURL))) {
            Write-Warning "You need to execute Initialize-ATRestApi first:"
            Initialize-ATRestApi
        }
        
        $Method = "Delete"
        
        $ResourceURL = (($Script:Queries | Where-Object { $_."$Method" -eq $Resource }).Name | Select-Object -First 1)
        
        $URL = "$($Script:ATBaseURL)$($ResourceURL)"

        if (($ID.Length -eq 0) -and ($URL.Contains("{parentId}"))) {
            Write-Warning -Message "The ID of the parent object is required."
            return
        } elseif ($null -ne $ChildID) {
            $URL += "/$($ChildID)"
        }

        $URL = "$(($URL -Replace "{parentId}|{id}", $ID))"

        if ($PreviewURL) {
            Write-Host "Request URL: $($URL)"
            return
        }

        try {
            $RawResponse = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Script:ATHeader -Body $SendingBody -ErrorAction Stop
            
            $RawResponse.itemId
        } catch {
            $ErrorMessage = "`n"
            $ErrorMessage += $_.Exception.Message
            $ErrorMessage += "`n`nErrors:`n"
            
            foreach ($Item in ($_.ErrorDetails.Message | ConvertFrom-Json).PSObject.Properties) {
                $ErrorMessage += " ! $($Item.Value)`n"
            }

            $ErrorMessage += "`n`n"

            Write-Error $ErrorMessage
        }
    }
}