function Invoke-PgQuery {
<#
.DESCRIPTION
    Sends a text string to a postgres database and tries to return a dataset

.EXAMPLE
    # return version() from a docker instance port forwarded to 54320:5432
    $splat = @{
        Port = 54320 
        User = 'postgres' 
        Password = (ConvertTo-SecureString -AsPlainText 'example' -Force)
    }
    Invoke-PgQuery @splat

#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]
        $Query = 'select version();',

        [Alias('Connection', 'Conn')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SQLConnection = '127.0.0.1',

        [int]
        [ValidateRange(1024,65535)]
        $Port = 5432,

        [string]
        $Database = 'postgres',

        [string]
        $User = $env:USER,

        [SecureString]
        $Password
    )

    $iniFile = Invoke-Expression "odbcinst -j | grep DRIVERS | awk '{print `$2}'"

    if([System.IO.File]::ReadAllText($iniFile) -notmatch $Driver){
        Write-Error "Cannot find Driver configuration for '$Driver' in '$iniFile'."
        return
    }

    # Pwd is stripped from the connection string at .conn() but is still sent in the clear
    # over the network unless via SSL. 
    $BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)

    $conn = New-Object System.Data.Odbc.OdbcConnection
    $conn.ConnectionString = @(
        "Driver={$Driver};"
        "Server=$SQLConnection;"
        "Port=$Port;"
        "Database=$Database;"
        "Uid=$User;"
        "Pwd=$([system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR));"
    ) -join ''
    $conn.Open()

    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) 
    Remove-Variable Password,BSTR

    $cmd = New-Object System.Data.Odbc.OdbcCommand($Query,$conn)
    $ds = New-Object System.Data.DataSet
    $da = New-Object System.Data.Odbc.OdbcDataAdapter($cmd)

    $da.Fill($ds) | Out-Null

    $conn.close()
    $conn.Dispose()

    try{
        $ds.Tables[0].Rows[0].Table[0]
    }
    catch{
        Write-Warning "No resultset returned for command string."
        Write-Warning $Query
    }
    $da.Dispose()
    $ds.Dispose()
}
