<#
.SYNOPSIS
    Add (or remove) the DeepSeek Harness boot-animation shortcut.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1
    powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$AppPath = 'F:\deepseek\DeepSeek Harness.exe',
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath

$targets = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'DeepSeek Harness.lnk'),
    (Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\DeepSeek Harness.lnk')
)

if ($Uninstall) {
    foreach ($t in $targets) {
        if (Test-Path -LiteralPath $t) {
            Remove-Item -LiteralPath $t -Force
            Write-Host "removed $t"
        }
    }
    return
}

if (-not (Test-Path -LiteralPath $AppPath)) {
    Write-Warning "client not found at $AppPath — the shortcut will still work if it can be auto-detected"
}

$icon = if (Test-Path -LiteralPath $AppPath) { "$AppPath,0" } else { "$env:SystemRoot\System32\shell32.dll,137" }

$shell = New-Object -ComObject WScript.Shell
foreach ($t in $targets) {
    $parent = Split-Path -Parent $t
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

    $lnk = $shell.CreateShortcut($t)
    $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
    $lnk.Arguments = '"' + (Join-Path $root 'start-silent.vbs') + '"'
    $lnk.WorkingDirectory = $root
    $lnk.IconLocation = $icon
    $lnk.Description = 'DeepSeek Harness (with boot animation)'
    $lnk.Save()
    Write-Host "created $t"
}

Write-Host ''
Write-Host 'Done. Double-click the "DeepSeek Harness" shortcut on your Desktop.'
Write-Host 'The animation plays fullscreen, then the client window takes over.'
