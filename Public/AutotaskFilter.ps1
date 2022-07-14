class AutotaskFilter {
    hidden [string] $field
    hidden [string] $op
    hidden [object] $value
    hidden [boolean] $udf
    hidden [System.Collections.ArrayList] $items
    [hashtable] $OPs = @{
        and         = "and"
        or          = "or"
        exist       = "exist"
        notExit     = "notExist"
        eq          = "eq"
        noteq       = "noteq"
        gt          = "gt"
        gte         = "gte"
        lt          = "lt"
        lte         = "lte"
        beginsWith  = "beginsWith"
        endsWith    = "endsWith"
        contains    = "contains"
        in          = "in"
        notIn       = "notIn"
    }

    AutotaskFilter([string] $Field, [string] $Op, [object] $Value, [boolean] $UDF) {
        $this.SetField($Field)
        $this.SetOp($Op)
        $this.SetValue($Value)
        $this.SetUDF($UDF)
    }

    [void] AddGroupFilter() {
        $this.AddGroupFilter($null, $null, $null, $false)
    }

    [void] AddGroupFilter([string] $Op) {
        $this.AddGroupFilter($null, $Op, $null, $false)
    }

    [void] AddGroupFilter([string] $Field, [string] $Op) {
        $this.AddGroupFilter($Field, $Op, $null, $false)
    }

    [void] AddGroupFilter([string] $Field, [string] $Op, [object] $Value) {
        $this.AddGroupFilter($Field, $Op, $Value, $false)
    }

    [void] AddGroupFilter([string] $Field, [string] $Op, [object] $Value, [boolean] $UDF) {
        $NewFilter = New-Object -TypeName AutotaskFilter($Field, $Op, $Value, $UDF)

        if ($null -eq $this.items) {
            $this.items = New-Object -TypeName System.Collections.ArrayList
        }

        $null = $this.items.Add($NewFilter)
    }

    [void] RemoveGroupFilter([int] $Index) {
        $this.items.RemoveAt($Index)
    }

    [System.Collections.ArrayList] GetItems() {
        return $this.items
    }

    [AutotaskFilter] GetItems([int] $Index) {
        return $this.items[$Index]
    }

    [string]    GetField ()                 { return $this.field}
    [void]      SetField ([string] $Field) { $this.field = $Field }

    [string]    GetOp    ()                 { return $this.op}
    [void]      SetOp    ([string] $Op)     { $this.op = $Op }

    [object]    GetValue ()                 { return $this.value}
    [void]      SetValue ([object] $Value)  { $this.value = $Value }

    [boolean]   GetUDF   ()                 { return $this.udf}
    [void]      SetUDF   ([boolean] $UDF)   { $this.udf = $UDF }

    hidden [PSCustomObject] ToObject() {
        $PopulatedProperties = $this | Get-Member -Force | Where-Object { $_.MemberType -eq "Property" -and $_.Name -ne "OPs" }
        
        $Object = New-Object -TypeName PSCustomObject

        foreach ($Property in $PopulatedProperties) {
            if ($null -eq $this.($Property.Name) -or $this.($Property.Name).Length -eq 0) { continue }

            if ($Property.Name -eq "items") {
                $NewObject = $this.items.ToObject()
                Add-Member -InputObject $Object -NotePropertyName "items" -NotePropertyValue $NewObject
            } else {
                Add-Member -InputObject $Object -NotePropertyName $Property.Name -NotePropertyValue $this.($Property.Name)
            }
        }

        return $Object
    }

    [string] ToString() {
        return $this.ToString($false)
    }

    [string] ToString([boolean] $Expand) {
        $Properties = $this.ToObject()

        $Filter = @{
            Filter = @(
                $Properties
            )
        }

        return $Filter | ConvertTo-Json -Depth 10 -Compress:(-not $Expand)
    }
}

<#
.SYNOPSIS
    Creates a Filter object you can use to generate JSON query strings.
.DESCRIPTION
    Create a Filter object, populate it with the filters you want and use it to generate a JSON filter query for Autotasks Rest API.
.PARAMETER Field
    Create a filter with prepopulated Field.
.PARAMETER Op
    Create a filter with prepopulated Op.
.PARAMETER Value
    Create a filter with prepopulated Value.
.PARAMETER UDF
    Flags the field as being user defined
.EXAMPLE
    $Filter = New-ATRestFilter
    Create unpopulated Filter object.
#>
function New-ATRestFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$Field = $null,
        [Parameter(Mandatory = $false)][string]$Op = $null,
        [Parameter(Mandatory = $false)][object]$Value = $null,
        [Parameter(Mandatory = $false)][switch]$UDF
    )

    return New-Object -TypeName AutotaskFilter($Field, $Op, $Value, $UDF)
}