<#
.SYNOPSIS
    Performs a 'PATCH' API call to the Autotask API.
.DESCRIPTION
    Updates an object in Autotask based on given resource type and object body. Refer to the official Autotask documentation to determine which fields are writeable.
    Use "Select-Object -Properties <List of properties you want to update>" to only update the fields you want changed.
.PARAMETER Resource
    The Autotask resource type you want to update.
.PARAMETER ParentID
    ID of the resource you want to update.
.PARAMETER Body
    Object Body of the object you want to update. An empty body with all fields can be created with New-ATRestObjectModel.
.PARAMETER PreviewURL
    Prints the finished request URL and exits without performing an API call.
.EXAMPLE
    Set-ATRestResource -Resource Tickets -Body $TicketBody
    Updates the Ticket based on the ID given in $TicketBody.id.
.EXAMPLE
    Set-ATRestResource -Resource TicketNotesChild -ParentID 12345 -ChildID 56789 -Body $NoteBody
    Updates the TicketNote with ID 56789 within the Ticket with ID 12345.
.LINK
    Rest API Entities overview: https://ww2.autotask.net/help/DeveloperHelp/Content/APIs/REST/Entities/_EntitiesOverview.htm
#>
function Set-ATRestResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)][String]$ParentID,
        [Parameter(Mandatory = $true)]$Body,
        [Parameter(Mandatory = $false)][switch]$PreviewURL
    )
    DynamicParam {
        $Script:DynParameters["Patch"]
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        if ((-not (Test-Path Variable:Script:ATHeader)) -or (-not (Test-Path Variable:Script:ATBaseURL))) {
            Write-Warning "You need to execute Initialize-ATRestApi first:"
            Initialize-ATRestApi
        }
        
        $Method = "Patch"

        $ResourceURL = (($Script:Queries | Where-Object { $_."$Method" -eq $Resource }).Name | Select-Object -First 1) -Replace "/query", ""
        
        $URL = "$($Script:ATBaseURL)$($ResourceURL)"

        if (($ParentID.Length -eq 0) -and ($URL.Contains("{parentId}"))) {
            Write-Warning -Message "The ID of the parent object is required."
            return
        }

        $URL = "$(($URL -Replace "{parentId}|{id}", $ParentID))"

        Format-ATRestDates -InputObject $Body
        
        if ($Body.GetType() -eq [hashtable]) {
            $SendingBody = $Body | ConvertTo-Json -Depth 10
        } else {
            $BodyNoNull = $Body | ForEach-Object { $Properties = $_.PSObject.Properties.Name | Where-Object { $null -ne $Body.$_ } ; $Body | Select-Object $Properties }
            $SendingBody = ConvertTo-Json -Depth 10 -InputObject $BodyNoNull
        }

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