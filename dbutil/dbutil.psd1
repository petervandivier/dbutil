@{
    RootModule = 'dbutil.psm1'
    ModuleVersion = '0.0.0'
    GUID = '2ab7a49e-7cc4-413c-853b-10811eb2bbfe'
    Author = 'Peter Vandivier'
    FunctionsToExport = @(
        'Format-SqlIdentifier',
        'Format-SqlValues',
        'Invoke-PgQuery'
    )
}
