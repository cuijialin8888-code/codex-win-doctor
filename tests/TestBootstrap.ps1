$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(
    'src/Core/Framework.ps1',
    'src/Core/Process.ps1',
    'src/Privacy/Redaction.ps1',
    'src/Checks/Platform.ps1',
    'src/Checks/Commands.ps1',
    'src/Checks/Codex.ps1',
    'src/Checks/Filesystem.ps1',
    'src/Checks/WindowsFeatures.ps1',
    'src/Output/Renderers.ps1',
    'src/Invoke-CodexDoctor.ps1'
)

foreach ($sourceFile in $sourceFiles) {
    . (Join-Path -Path $projectRoot -ChildPath $sourceFile)
}
