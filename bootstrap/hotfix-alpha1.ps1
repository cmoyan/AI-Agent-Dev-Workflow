$ErrorActionPreference = 'Stop'
$root = Join-Path $env:GITHUB_WORKSPACE 'projects\Poster2PSD-V2'

function Replace-Exact([string]$path, [string]$old, [string]$new) {
  $content = Get-Content $path -Raw
  if (-not $content.Contains($old)) { throw "Expected source fragment not found in $path :: $old" }
  Set-Content -Path $path -Value ($content.Replace($old, $new)) -Encoding utf8
}

$coreProgram = Join-Path $root '02_SOURCE\src\Poster2PSD.Core\Program.cs'
Replace-Exact $coreProgram 'var paths = new AppPaths(temp);' 'var selfTestPaths = new AppPaths(temp);'
Replace-Exact $coreProgram 'var storage = new CoreStorage(paths);' 'var selfTestStorage = new CoreStorage(selfTestPaths);'
Replace-Exact $coreProgram 'await storage.InitializeAsync();' 'await selfTestStorage.InitializeAsync();'
Replace-Exact $coreProgram 'await storage.CreateProjectAsync("Self Test", "system")' 'await selfTestStorage.CreateProjectAsync("Self Test", "system")'
Replace-Exact $coreProgram 'await storage.CreateSessionAsync(project.Id)' 'await selfTestStorage.CreateSessionAsync(project.Id)'
Replace-Exact $coreProgram 'await storage.GetSchemaVersionAsync()' 'await selfTestStorage.GetSchemaVersionAsync()'

$coreProject = Join-Path $root '02_SOURCE\src\Poster2PSD.Core\Poster2PSD.Core.csproj'
Replace-Exact $coreProject '<PackageReference Include="Microsoft.Data.Sqlite" Version="10.0.0" />' '<PackageReference Include="Microsoft.Data.Sqlite" Version="10.0.12" />'

$pipeClient = Join-Path $root '02_SOURCE\src\Poster2PSD.Workbench\CorePipeClient.cs'
Replace-Exact $pipeClient 'using System.IO.Pipes;' "using System.IO;$([Environment]::NewLine)using System.IO.Pipes;"

$mainWindow = Join-Path $root '02_SOURCE\src\Poster2PSD.Workbench\MainWindow.xaml.cs'
Replace-Exact $mainWindow 'using Microsoft.Win32;' "using System.IO;$([Environment]::NewLine)using Microsoft.Win32;"
Replace-Exact $mainWindow 'Path.GetFileNameWithoutExtension(dialog.FileName)' 'System.IO.Path.GetFileNameWithoutExtension(dialog.FileName)'
Replace-Exact $mainWindow 'Path.GetExtension(path)' 'System.IO.Path.GetExtension(path)'

Write-Host 'Tracked source hotfixes applied.'
