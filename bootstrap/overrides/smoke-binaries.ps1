param([string]$BuildRoot = '', [string]$Version = '0.1.0-alpha.2')
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
if ([string]::IsNullOrWhiteSpace($BuildRoot)) { $BuildRoot = Join-Path $Root '03_BUILD' }
$tests = @('Poster2PSD.exe','Poster2PSD.Core.exe','Poster2PSD.MLHost.exe','Poster2PSD.MCP.exe','Poster2PSD.MCP.Launcher.exe','Poster2PSD.Diagnostic.exe','Poster2PSD.Updater.exe','Poster2PSD.Launcher.exe','Poster2PSD_Setup.exe')

function Invoke-CheckedProcess([string]$FilePath, [string[]]$Arguments = @(), [string]$Label = '') {
  $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    $name = if ([string]::IsNullOrWhiteSpace($Label)) { [System.IO.Path]::GetFileName($FilePath) } else { $Label }
    throw "$name failed with exit code $($process.ExitCode)"
  }
  return $process.ExitCode
}

foreach ($exe in $tests) {
  $path = Join-Path $BuildRoot $exe
  if (!(Test-Path $path)) { throw "Missing $path" }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  if ($bytes.Length -lt 2 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw "$exe is not a Windows PE executable" }
  $productVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path).ProductVersion
  if ([string]::IsNullOrWhiteSpace($productVersion) -or !$productVersion.StartsWith($Version, [StringComparison]::OrdinalIgnoreCase)) { throw "$exe ProductVersion mismatch: $productVersion" }
  Invoke-CheckedProcess -FilePath $path -Arguments @('--self-test') -Label "$exe self-test" | Out-Null
}

$payload = Join-Path $BuildRoot 'payload'
foreach ($exe in $tests | Where-Object { $_ -ne 'Poster2PSD_Setup.exe' }) {
  $rootExe = Join-Path $BuildRoot $exe
  $payloadExe = Join-Path $payload $exe
  if (!(Test-Path $payloadExe)) { throw "Payload missing $exe" }
  $a = (Get-FileHash $rootExe -Algorithm SHA256).Hash
  $b = (Get-FileHash $payloadExe -Algorithm SHA256).Hash
  if ($a -ne $b) { throw "Root/payload binary mismatch for $exe" }
}

# Isolated real installer lifecycle regression. No runner registry/desktop pollution.
$testRoot = Join-Path $env:TEMP ("poster2psd-exe-regression-" + [guid]::NewGuid().ToString('N'))
$appRoot = Join-Path $testRoot 'app'
$desktopRoot = Join-Path $testRoot 'desktop'
New-Item (Join-Path $appRoot 'data') -ItemType Directory -Force | Out-Null
'sentinel-preserve-user-data' | Set-Content (Join-Path $appRoot 'data\sentinel.txt') -Encoding utf8
$env:POSTER2PSD_APP_ROOT = $appRoot
$env:POSTER2PSD_DESKTOP_ROOT = $desktopRoot
$env:POSTER2PSD_SKIP_REGISTRY = '1'
$env:POSTER2PSD_SKIP_SHORTCUT = '1'
try {
  $setup = Join-Path $BuildRoot 'Poster2PSD_Setup.exe'
  Invoke-CheckedProcess -FilePath $setup -Label 'Fresh install' | Out-Null
  if ((Get-Content (Join-Path $appRoot 'current.txt') -Raw).Trim() -ne $Version) { throw 'current.txt version mismatch' }
  $versionRoot = Join-Path $appRoot ("versions\" + $Version)
  foreach ($exe in @('Poster2PSD.exe','Poster2PSD.Core.exe','Poster2PSD.MCP.exe','Poster2PSD.Launcher.exe','Poster2PSD.MCP.Launcher.exe')) {
    if (!(Test-Path (Join-Path $versionRoot $exe))) { throw "Installed version missing $exe" }
  }
  foreach ($stable in @('Poster2PSD.Launcher.exe','Poster2PSD.MCP.Launcher.exe')) {
    if (!(Test-Path (Join-Path $appRoot $stable))) { throw "Stable launcher missing $stable" }
  }
  Invoke-CheckedProcess -FilePath (Join-Path $appRoot 'Poster2PSD.Launcher.exe') -Arguments @('--probe') -Label 'Stable Launcher probe' | Out-Null

  Invoke-CheckedProcess -FilePath $setup -Arguments @('--repair') -Label 'Repair' | Out-Null

  $lifecycleSetup = Join-Path $appRoot 'lifecycle\Poster2PSD_Setup.exe'
  if (!(Test-Path $lifecycleSetup)) { throw 'Cached lifecycle Setup missing' }
  Invoke-CheckedProcess -FilePath $lifecycleSetup -Arguments @('--uninstall') -Label 'Uninstall' | Out-Null
  if (Test-Path (Join-Path $appRoot 'versions')) { throw 'Uninstall left versions directory' }
  if (Test-Path (Join-Path $appRoot 'current.txt')) { throw 'Uninstall left current.txt' }
  if (Test-Path (Join-Path $appRoot 'Poster2PSD.Launcher.exe')) { throw 'Uninstall left stable launcher' }
  if (!(Test-Path (Join-Path $appRoot 'data\sentinel.txt'))) { throw 'Uninstall deleted user data sentinel' }
}
finally {
  Remove-Item Env:POSTER2PSD_APP_ROOT -ErrorAction SilentlyContinue
  Remove-Item Env:POSTER2PSD_DESKTOP_ROOT -ErrorAction SilentlyContinue
  Remove-Item Env:POSTER2PSD_SKIP_REGISTRY -ErrorAction SilentlyContinue
  Remove-Item Env:POSTER2PSD_SKIP_SHORTCUT -ErrorAction SilentlyContinue
  Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# Release hash list must resolve to the exact built artifacts.
$hashFile = Join-Path $Root '05_RELEASE\FILE-HASHES.sha256'
if (!(Test-Path $hashFile)) { throw 'FILE-HASHES.sha256 missing' }
foreach ($line in Get-Content $hashFile) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split '\s+', 2
  if ($parts.Count -ne 2) { throw "Malformed hash line: $line" }
  $expected = $parts[0].ToLowerInvariant()
  $rel = $parts[1].Trim().Replace('/', [System.IO.Path]::DirectorySeparatorChar)
  $path = Join-Path $BuildRoot $rel
  if (!(Test-Path $path)) { throw "Hash target missing: $rel" }
  $actual = (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw "Hash mismatch: $rel" }
}

Write-Host 'EXE artifact regression PASS: 9 PE executables, self-tests, payload parity, install/repair/uninstall, hash verification.'
