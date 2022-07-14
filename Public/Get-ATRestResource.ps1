<#
.SYNOPSIS
    Performs a 'GET' API call to the Autotask API.
.DESCRIPTION
    Retrieves an Autotask resource by ID or a JSON search query, which can be generated using the AutotaskFilter object.
.PARAMETER Resource
    The Autotask resource type you want to retrieve.
.PARAMETER ID
    Retrieves specific resource based on ID.
.PARAMETER ParentID
    Alias for the ID parameter.
.PARAMETER ChildID
    Retrieves specific child-item of a resource.
.PARAMETER Query
    JSON filter string, can be generated using the AutotaskFilter object.
.PARAMETER PreviewURL
    Prints the finished request URL and exits without performing an API call.
.EXAMPLE
    Get-ATRestResource -Resource Tickets -ID 12345
    Retrieves the Autotask Ticket with ID 12345.
.EXAMPLE
    Get-ATRestResource -Resource TicketNotesChild -ParentID 12345 -ChildID 56789
    Retrieves the Autotask TicketNote with ID 56789 from Ticket with ID 12345.
.EXAMPLE
    Get-ATRestResource -Resource TicketNotesChild -ParentID 12345
    Retries all Notes from Ticket with ID 12345
#>
function Get-ATRestResource {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'ID', Mandatory = $true)][Alias("ParentID")][String]$ID,
        [Parameter(ParameterSetName = 'ID', Mandatory = $false)][String]$ChildID,
        [Parameter(ParameterSetName = 'Query', Mandatory = $false)][String]$Query,
        [Parameter(Mandatory = $false)][switch]$PreviewURL
    )
    DynamicParam {
        $Script:DynParameters["Get"]
    }
    begin {
        $Resource = $PSBoundParameters.Resource
    }
    process {
        if ((-not (Test-Path Variable:Script:ATHeader)) -or (-not (Test-Path Variable:Script:ATBaseURL))) {
            Write-Warning "You need to execute Initialize-ATRestApi first:"
            Initialize-ATRestApi
        }

        $Method = "Get"

        $ResourceURL = (($Script:Queries | Where-Object { $_."$Method" -eq $Resource }).Name | Select-Object -First 1) -Replace "/query", ""

        $URL = "$($Script:ATBaseURL)$($ResourceURL)"

        if (($ID.Length -eq 0) -and ($URL.Contains("{parentId}"))) {
            Write-Warning -Message "ParentID parameter is required. Aborting."
            return
        } elseif (-not ($URL.Contains("{parentId}")) -and ($ID.Length -gt 0)) {
            $URL += "/{id}"
        } elseif (($URL.Contains("{parentId}")) -and ($ChildID.Length -gt 0)) {
            $URL += "/$($ChildID)"
        } elseif ($Query.Length -gt 0) {
            $URL += "/query?search=$($Query)"
        }

        $URL = "$(($URL -Replace "{parentId}|{id}", $ID))"

        if ($PreviewURL) {
            Write-Host "Request URL: $($URL)"
            return
        }

        try {
            do {
                $RawResponse = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Script:ATHeader
                $URL = $RawResponse.PageDetails.NextPageUrl

                if ($RawResponse.items) {
                    foreach ($item in $RawResponse.items) {
                        $item
                    }
                }
                if ($RawResponse.item) {
                    foreach ($item in $RawResponse.item) {
                        $item
                    }
                }
            } while ($null -ne $URL)
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