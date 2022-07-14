<#
.SYNOPSIS
    Populates global variables for dynamic Parameters, for auto-completion.
.DESCRIPTION
    Parameter auto-completion will be available for all functions with the -Resource parameter.
.EXAMPLE
    New-ResourceDynamicParameters
    Not intended to be used on it's own, is called within the Initialize-ATRestApi function.
#>
function New-ATRestDynamicParameters {
    $json_file = "$($MyInvocation.MyCommand.Module.ModuleBase)\v1.json"

    $ParameterName = "Resource"

    $Methods = @("Get", "Post", "Patch", "Delete")

    if (-Not $Script:Swagger) { $Script:Swagger = Get-Content $json_file -Raw | ConvertFrom-Json }
    $Script:Queries = foreach ($Path in $Script:Swagger.paths.PSObject.Properties) {
        [PSCustomObject]@{
            Name   = $path.Name
            Get    = $Path.Value.Get.tags
            Post   = $Path.Value.Post.tags
            Patch  = $Path.Value.Patch.tags
            Delete = $Path.Value.Delete.tags
        }
    }

    $Script:DynParameters = @{}

    foreach ($Method in $Methods) {
        $DynParameters[$Method] = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $AttributeCollection.Add($ParameterAttribute)

        $ResourceList = foreach ($Query in  $Queries | Where-Object { $null -ne $_.$Method }) {
            $Query.$Method | Select-Object -Last 1
        }

        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ResourceList | Select-Object -Unique)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $DynParameters[$Method].Add($ParameterName, $RuntimeParameter)
    }

    $DynParameters["Model"] = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $AttributeCollection.Add($ParameterAttribute)

    $ResourceList = foreach ($Query in  $Queries | Where-Object { $null -ne $_."Get" }) {
        if (-not ($Query.Name.ToLower().Contains("{parentid}")) -and ($Query.Name.ToLower().Contains("entityinformation"))) {
            $Query."Get" | Select-Object -Last 1
        }
    }

    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ResourceList | Select-Object -Unique)
    $AttributeCollection.Add($ValidateSetAttribute)
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
    $DynParameters["Model"].Add($ParameterName, $RuntimeParameter)
}