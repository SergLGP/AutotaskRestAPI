<#
.SYNOPSIS
    Initialize the Autotask API connection with your credentials.
.DESCRIPTION
    An actual connection is not yet made, but the headers, base URL and dynamic Parameters are prepared.
.PARAMETER IntegrationCode
    Your Autotask Integration Code
.PARAMETER Credentials
    A PSCredential object with your Autotask Username and Password, created with the Cmdlet Get-Credentials or with the New-Object Cmdlet.
.PARAMETER Server
    The subdomain of the Autotask Server your instance is running on. If your URL is something like this: "https://webservices18.autotask.net....", input "webservices18" here.
.PARAMETER ImpersonationResourceID
    Impersonation resource ID. Refer to the offical Autotask Rest API documentation.
.EXAMPLE
    Initialize-ATRestApi -IntegrationCode <IntCode> -Credentials (Get-Credentials) -Server webservices18
.EXAMPLE
    Initialize-ATRestApi -IntegrationCode <IntCode> -Credentials $CredentialObject -Server webservices18
#>
function Initialize-ATRestApi {
    [CmdletBinding(DefaultParameterSetName = "Credential")]
    param (
        [Parameter(ParameterSetName = "CredentialItem", Mandatory = $true)]
        [Parameter(Position = 0, ParameterSetName = "Credential", Mandatory = $true)][String]$IntegrationCode,
        [Parameter(Position = 1, ParameterSetName = "Credential", Mandatory = $true)][string]$Username,
        [Parameter(Position = 2, ParameterSetName = "Credential", Mandatory = $true)][string]$Secret,
        [Parameter(ParameterSetName = "CredentialItem", Mandatory = $true)][pscredential]$Credentials,
        [Parameter(ParameterSetName = "CredentialItem", Mandatory = $true)]
        [Parameter(Position = 3, ParameterSetName = "Credential", Mandatory = $true)][string]$Zone,
        [Parameter(Mandatory = $false)][string]$ImpersonationResourceID
    )

    $Script:ATBaseURL = "https://$($Zone).autotask.net/atservicesrest"

    if ($Username.Length -gt 0 -and $Secret.Length -gt 0) {
        $SecretPW = $Secret | ConvertTo-SecureString -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential($UserName, $SecretPW)
    }

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credentials.Password)
    $Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

    $Script:ATHeader = @{
        'ApiIntegrationcode' = $IntegrationCode
        'UserName'           = $Credentials.UserName
        'Secret'             = $Secret
        'Content-Type'       = 'application/json'
    }

    if ($ImpersonationResourceID.Length -gt 0) {
        $ATHeader["ImpersonationResourceId"] = $ImpersonationResourceID
    }
}