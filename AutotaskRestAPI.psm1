$Path = @{ base = $PSScriptRoot }

$Functions = Get-ChildItem -Path $Path['base'] -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($Function in $Functions) {
    . $Function.FullName
}

New-ATRestDynamicParameters