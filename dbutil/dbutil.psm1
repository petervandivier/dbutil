Push-Location $PSScriptRoot

Get-ChildItem -Recurse -Path "./functions/*.ps1" | ForEach-Object {
    . $PSItem.FullName 
}

Pop-Location

New-Alias -Name 'ipgq' -Value 'Invoke-PgQuery'
New-Alias -Name 'rmpgdb' -Value 'Remove-PgDatabase'
