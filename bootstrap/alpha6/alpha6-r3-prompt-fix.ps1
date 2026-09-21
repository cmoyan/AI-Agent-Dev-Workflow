param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot
)

$path = Join-Path $SourceRoot '02_SOURCE\src\Poster2PSD.MLHost\PromptCompiler.cs'
if (!(Test-Path $path)) {
    throw 'alpha.6 r3 PromptCompiler target missing'
}

$text = [System.IO.File]::ReadAllText($path)
$old = '[GeneratedRegex(@"\((?<text>[^():]+):(?<weight>[0-9]+(?:\.[0-9]+)?)\)|(?<plain>[^,]+)", RegexOptions.Compiled)]'
$new = '[GeneratedRegex(@"\s*(?:\((?<text>[^():]+):(?<weight>[0-9]+(?:\.[0-9]+)?)\)|(?<plain>[^,]+))", RegexOptions.Compiled)]'

if ($text.Contains($old)) {
    $text = $text.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}
elseif (!$text.Contains($new)) {
    throw 'alpha.6 r3 PromptCompiler regex signature not found'
}

$verify = [System.IO.File]::ReadAllText($path)
if (!$verify.Contains($new)) {
    throw 'alpha.6 r3 PromptCompiler regex fix failed'
}

Write-Host 'alpha.6 r3 PromptCompiler weighted-segment fix applied.'
