function crt.sh {
    param (
        [Parameter(Position=0)]
        [string]$Domain,

        [Parameter(Position=1)]
        [string]$OutputFile,

        [switch]$Help
    )

    if ($Help -or -not $Domain) {
        Write-Host "Usage: crt.sh <domain or pattern> [outputfile]"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  crt.sh example.com"
        Write-Host "  crt.sh *.example.com          (all subdomains)"
        Write-Host "  crt.sh api*.example.com       (prefix match)"
        Write-Host "  crt.sh example.com subs.txt"
        return
    }

    # Detect dangerous patterns like *word*
    if ($Domain -match '^\*.+\*') {
        Write-Warning "Substring searches (*word*) are not supported by crt.sh and will likely fail."
        Write-Warning "Try using prefix (word*.example.com) or suffix (*.example.com) patterns instead."
        return
    }

    # Convert PowerShell-style wildcards (*) into crt.sh wildcards (%)
    $Query = $Domain -replace '\*','%'

    $url = "https://crt.sh/?q=$Query&output=json"

    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing

        $subdomains = $response.name_value `
            | ForEach-Object { $_ -replace '^\*\.', '' } `
            | ForEach-Object { $_ -split "`n" } `
            | Sort-Object -Unique

        if ($OutputFile) {
            $subdomains | Out-File -FilePath $OutputFile -Encoding utf8
            Write-Host "Saved $($subdomains.Count) subdomains to $OutputFile"
        } else {
            $subdomains
        }
    }
    catch {
        Write-Error "Failed to fetch or parse results for $Domain : $_"
    }
}
