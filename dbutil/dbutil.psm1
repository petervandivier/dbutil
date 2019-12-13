Push-Location $PSScriptRoot

Get-ChildItem -Recurse -Path "./functions/*.ps1" | ForEach-Object {
    . $PSItem.FullName 
}

Pop-Location
