
function Remove-PgDatabase {
<#
.DESCRIPTION
    Some days you just can't get rid of a database
    Shamelessly plagiarised from https://github.com/sqlcollaborative/dbatools/blob/development/functions/Remove-DbaDatabase.ps1
    Currently only supports execution against a localhost, cause that's all I need it for atm 

.EXAMPLE
    createdb foo;createdb bar;
    @('foo','bar') | Remove-PgDatabase -Confirm:$false
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = "Default")]
    param (
        [Parameter(ValueFromPipeline, Mandatory, ParameterSetName = "databases",Position=0)]
        [Alias('Database')]
        [string[]]$InputObject
    )

    process{
        $server = hostname

        # Excludes system databases as these cannot be deleted
        $system_dbs = @( "postgres", "template0", "template1" )
        $InputObject = $InputObject | Where-Object { $_.Name -notin $system_dbs }

            foreach($Database in $InputObject){
            try {
                $KillCmd = @(
                    "select pg_terminate_backend(pid) " 
                    "from   pg_stat_activity " 
                    "where  datname = '$Database'; " 
                ) -join "`n"

                if ($Pscmdlet.ShouldProcess("$Database", "KillDatabase")) {
                    $res = Invoke-PgQuery -Query $KillCmd
                    Write-Verbose "$($res.Count) connection(s) terminated again $Database"
                    dropdb "$Database"

                    [pscustomobject]@{
                        ComputerName = $server
                        InstanceName = $server
                        SqlInstance  = $server
                        Database     = $Database
                        Status       = "Dropped"
                    }
                }
            } catch {
                Write-Verbose -Message "Could not drop database $Database on $server"

                [pscustomobject]@{
                    ComputerName = $server
                    InstanceName = $server
                    SqlInstance  = $server
                    Database     = $Database
                    Status       = (Get-ErrorMessage -Record $_)
                }
            }
        }
    }
}
