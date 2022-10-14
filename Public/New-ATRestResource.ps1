<#
.SYNOPSIS
    Performs a 'POST' API call to the Autotask API.
.DESCRIPTION
    Creates an object in Autotask based on given resource type and object body. Refer to the official Autotask documentation to determine which fields are required.
.PARAMETER Resource
    The Autotask resource type you want to create.
.PARAMETER ParentID
    To create a childitem within a resource based on ParentID.
.PARAMETER Body
    Object Body of the object you want to create. An empty body with all fields can be created with New-ATRestObjectModel.
.PARAMETER PreviewURL
    Prints the finished request URL and exits without performing an API call.
.EXAMPLE
    New-ATRestResource -Resource Tickets -Body $TicketBody
    Creates a new Ticket with the populated fields defined in $TicketBody.
.EXAMPLE
    New-ATRestResource -Resource TicketNotesChild -ParentID 12345 -Body $NoteBody
    Creates a new Ticketnote within the Ticket with ID 12345.
.LINK
    Rest API Entities overview: https://ww2.autotask.net/help/DeveloperHelp/Content/APIs/REST/Entities/_EntitiesOverview.htm
#>
function New-ATRestResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)][String]$ParentID,
        [Parameter(Mandatory = $true)]$Body,
        [Parameter(Mandatory = $false)][switch]$PreviewURL
    )
    DynamicParam {
        $Script:DynParameters["Post"]
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        if ((-not (Test-Path Variable:Script:ATHeader)) -or (-not (Test-Path Variable:Script:ATBaseURL))) {
            Write-Warning "You need to execute Initialize-ATRestApi first:"
            Initialize-ATRestApi
        }
        
        $Method = "Post"
        
        $ResourceURL = (($Script:Queries | Where-Object { $_."$Method" -eq $Resource }).Name | Select-Object -First 1) -Replace "/query", ""

        $URL = "$($Script:ATBaseURL)$($ResourceURL)"

        if (($ParentID.Length -eq 0) -and ($URL.Contains("{parentId}"))) {
            Write-Warning -Message "The ID of the parent object is required."
            return
        }
        
        $URL = "$(($URL -Replace "{parentId}|{id}", $ParentID))"

        if ($PreviewURL) {
            Write-Host "Request URL: $($URL)"
            return
        }
        
        Format-ATRestDates -InputObject $Body
        
        if ($Body.GetType() -eq [hashtable]) {
            $SendingBody = $Body | ConvertTo-Json -Depth 10
        } else {
            $BodyNoNull = $Body | ForEach-Object { $Properties = $_.PSObject.Properties.Name | Where-Object { $null -ne $Body.$_ } ; $Body | Select-Object $Properties }
            $SendingBody = ConvertTo-Json -Depth 10 -InputObject $BodyNoNull
        }

        try {
            $Bytes = [System.Text.Encoding]::UTF8.GetByteCount("ä")

            if ($Bytes -eq 4) {
                $RawResponse = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Script:ATHeader -Body $SendingBody -ErrorAction Stop
            } else {
                $BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($SendingBody)
                $RawResponse = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Script:ATHeader -Body $BodyBytes -ErrorAction Stop
            }
            
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