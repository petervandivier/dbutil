
function Export-PgTableData {
<#
.DESCRIPTION
    Plaintext CSV & Format-SqlValues dump of $DumpTables in ur $Database.
    Default usage dumps all tables in $Database.public on your localhost to ./data 

.EXAMPLE dump two tables
    psql postgres -c 'select 1 as a into foo; select 2 as b into bar;'
    $splat = @{
        Table = @('foo','bar')
        Database = 'postgres'
    }
    Export-PgTableData @splat

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Database,

        [Parameter()]
        [string[]]
        $Table,

        [Parameter()]
        [string]
        $User = $env:USER,

        [Parameter()]
        [securestring]
        $Password,

        [Parameter()]
        [string]
        $Port = 5432,

        [Parameter()]
        [string]
        $SqlConnection = '127.0.0.1',

        [Parameter()]
        [string]
        $CsvPath = "./data/csv",

        [Parameter()]
        [string]
        $SqlPath = "./data"
    )

    $ConnSplat = @{
        Port = $Port 
        User = $User 
        Password = $Password
        Database = $Database
    }

    if(-not $Table){
        $DumpTables = (Invoke-PgQuery @ConnSplat -Query "select * from pg_tables where schemaname = 'public';").tablename
    } else {
        $DumpTables = $Table
    }

    $SqlPath = (New-Item -ItemType Directory -Path $SqlPath -Force).FullName
    $CsvPath = (New-Item -ItemType Directory -Path $CsvPath -Force).FullName

    # Invoke-PgQuery borks hard atm on meta-commands, back to env var hackery
    $CopyCmdTmp = "\COPY {0} to $CsvPath/{0}.csv CSV HEADER"

    $env:PGPASSWORD = $Password

    foreach($tbl in $DumpTables) {
        $CopyCmd = $CopyCmdTmp -f $tbl
        Invoke-Command {psql -d $Database -h $SqlConnection -p $Port -U $User -c $CopyCmd}
        $data = Import-Csv "$CsvPath/$tbl.csv"
        Format-SqlValues -InputObject $data -Expanded -TableName $tbl | Set-Content "$SqlPath/$tbl.sql" -Force
    }
}
