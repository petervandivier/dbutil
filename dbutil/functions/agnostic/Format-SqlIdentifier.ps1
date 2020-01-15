function Format-SqlIdentifier {
<#
.DESCRIPTION
    Add quoted identifiers iff the input string is not a valid identifier
    ¿Warn if the input srting appears already quoted?
    Error if the input string is not quoteable (null or empty)

    Note, emoji are valid unquoted identifiers in postgres & mysql.
    The intent of this function is not eliminate _all_ extraneous quoting,
    rather to unquote most common identifiers. False positives are okay.

.PARAMETER QuoteStyle
    Accepts single-char or double-char input or "friendly wording" by 
    description of syntax style or platform name. If platform name is 
    used, then the function will choose a compatible style.

.EXAMPLE
    @('foo bar','foo') | Format-SqlIdentifier

#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateScript({-not [string]::IsNullOrWhiteSpace($_)})]
        [Alias('text')]
        [string]
        $Word,

        [ValidateSet('"',               "'",            '`',        '[',']',
                     '""',              "''",           '``',       '[]',
                     'DoubleQuote',     'SingleQuote',  'BackTick', 'SquareBracket',
                     'PostgreSQL','pg',                 'MySql',    'SqlServer','ms',
                     1,                  2,              3,          4)]
        [Alias('qs')]
        [string]
        $QuoteStyle = '"'
    )

    begin{
        $syntaxCode = switch($QuoteStyle) {
            {$_ -in ( '"',     '""', 'DoubleQuote',   'PostgreSQL','pg' ) } { 1 }
            {$_ -in ( "'",     "''", 'SingleQuote'                      ) } { 2 }
            {$_ -in ( '`',     '``', 'BackTick',      'MySql' )           } { 3 }
            {$_ -in ( '[',']', '[]', 'SquareBracket', 'SqlServer','ms' )  } { 4 }
            Default { $QuoteStyle }
        }

        # TODO: Get-SqlKeywords for styles 2,3,4
        # MSSQL (4) see - https://gist.github.com/petervandivier/1b6d87de4af6b4cd5150e107d22d4eb2#gistcomment-3110666
        $keywords = switch($syntaxCode) {
                1 {Get-PgKeyword}
                # 2 {}
                # 3 {}
                # 4 {}
                default {$null}
        }

        function Add-Quote {
            param ($Word,$syntaxCode)
            switch ($syntaxCode) {
                0 { "$Word";     break; }
                1 { "`"$Word`""; break; }
                2 { "'$Word'";   break; }
                3 { "``$Word``"; break; }
                4 { "[$Word]";   break; }
                Default { throw "Unknown syntaxCode '$syntaxCode'. Valid values are (0,1,2,3,4)." }
            }
        }
    }
    
    process{
        $addQuote = $false

        if($Word -in $keywords){$addQuote = $true}
        if($Word -match '[^a-zA-Z0-9_]'){$addQuote = $true}
        if($Word.Substring(0,1) -match '[0-9]'){$addQuote = $true}

        if($addQuote){
            if(($syntaxCode -in (1,3)) -and ($Word -cmatch '[A-Z]')){
                Write-Warning "Upper casing is preserved in quoted identifiers for PostgreSQL & MySQL. Inspect the output after execution."
            }
            return Add-Quote $Word $syntaxCode
        } else {
            return $Word
        }
    }

    end{}
}
