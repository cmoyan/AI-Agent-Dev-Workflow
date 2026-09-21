param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot
)

$relativePaths = @(
    '02_SOURCE\src\Poster2PSD.MLHost\Program.cs',
    '02_SOURCE\src\Poster2PSD.MLHost\InferenceEngineRunner.cs',
    '02_SOURCE\src\Poster2PSD.MLHost\ImagePreprocessor.cs',
    '02_SOURCE\src\Poster2PSD.MLHost\ProviderAdapterRunner.cs'
)

foreach ($relative in $relativePaths) {
    $path = Join-Path $SourceRoot $relative
    if (!(Test-Path $path)) {
        throw "alpha.6 r2 fix target missing: $relative"
    }

    $text = [System.IO.File]::ReadAllText($path)
    if ($text -notmatch '(?m)^using System\.IO;\s*$') {
        $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
        [System.IO.File]::WriteAllText(
            $path,
            "using System.IO;$newline$text",
            [System.Text.UTF8Encoding]::new($false)
        )
    }

    $verify = [System.IO.File]::ReadAllText($path)
    if ($verify -notmatch '(?m)^using System\.IO;\s*$') {
        throw "alpha.6 r2 System.IO fix failed: $relative"
    }
}

Write-Host 'alpha.6 r2 System.IO overlay applied.'
