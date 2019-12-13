function Format-SqlIdentifier {
<#
.DESCRIPTION
    Add quoted identifiers iff the input string is not a valid identifier
    ¿Warn if the input srting appears already quoted?
    Error if the input string is not quoteable (null or empty)

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
        $syntaxCode = switch ($QuoteStyle) {
            {$_ -in ( '"',     '""', 'DoubleQuote',   'PostgreSQL','pg' ) } { 1 }
            {$_ -in ( "'",     "''", 'SingleQuote'                      ) } { 2 }
            {$_ -in ( '`',     '``', 'BackTick',      'MySql' )           } { 3 }
            {$_ -in ( '[',']', '[]', 'SquareBracket', 'SqlServer','ms' )  } { 4 }
            Default { $QuoteStyle }
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
        # $keywords = Get-SqlKeyword $syntaxCode
        $addQuote = $false

        if($Word -in $keywords){$addQuote = $true}
        if($Word -match '[^a-zA-Z0-9_]'){$addQuote = $true}
        if($Word.Substring(0,1) -match '[0-9]'){$addQuote = $true}

        if($addQuote){
            return Add-Quote $Word $syntaxCode
        } else {
            return $Word
        }
    }

    end{}
}
