<#
.SYNOPSIS
    Plays the DeepSeek Harness boot animation, then starts the desktop client.

.DESCRIPTION
    The splash is a single HTML page rendered fullscreen (kiosk) by the Edge/Chrome
    already installed on Windows. Nothing inside the client is modified, so removing
    the shortcut (or this folder) fully reverts the change.

    Timeline (milliseconds from the moment the browser is launched):
        0     browser starts, page fades in
        1400  the client is started behind the splash
        2900  the splash may go away, but it waits (up to 7000) for the client window

.PARAMETER NoApp
    Play the animation only; do not start the client.

.PARAMETER KeepOpen
    Leave the splash on screen (debugging); kill it manually.
#>
[CmdletBinding()]
param(
    [string]$AppPath,
    [switch]$NoApp,
    [switch]$KeepOpen
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$page = Join-Path $root 'index.html'
if (-not (Test-Path $page)) { throw "splash page not found: $page" }

$AppStartMs   = 1400
$EarliestEnd  = 2900
$LatestEnd    = 7000
$ProfileDir   = Join-Path $env:LOCALAPPDATA 'DSH-Splash\browser-profile'

function Find-Browser {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Find-Client {
    if ($AppPath -and (Test-Path -LiteralPath $AppPath)) { return $AppPath }
    $guesses = @(
        'F:\deepseek\DeepSeek Harness.exe',
        (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\DeepSeek Harness.exe'),
        (Join-Path $env:LOCALAPPDATA 'DeepSeek Harness\DeepSeek Harness.exe'),
        (Join-Path $env:ProgramFiles 'DeepSeek Harness\DeepSeek Harness.exe')
    )
    foreach ($g in $guesses) {
        if ($g -and (Test-Path -LiteralPath $g)) { return $g }
    }
    return $null
}

function Start-Splash([string]$browser, [string]$url) {
    New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
    $arguments = @(
        '--kiosk'
        $url
        "--user-data-dir=$ProfileDir"
        '--no-first-run'
        '--no-default-browser-check'
        '--disable-session-crashed-bubble'
        '--disable-features=Translate,msEdgeSidebarV2,msImplicitSignin,msEdgeIdentityScope'
        '--noerrdialogs'
        '--autoplay-policy=no-user-gesture-required'
        '--window-size=1920,1080'
    )
    Start-Process -FilePath $browser -ArgumentList $arguments -WindowStyle Normal | Out-Null
}

function Stop-Splash {
    Get-CimInstance Win32_Process -Filter "Name='msedge.exe' OR Name='chrome.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.Contains($ProfileDir) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

$browser = Find-Browser
if (-not $browser) { throw 'no Edge/Chrome found to render the splash' }

$client = if ($NoApp) { $null } else { Find-Client }
if (-not $NoApp -and -not $client) { throw 'DeepSeek Harness.exe not found; pass -AppPath' }

$baseline = @()
if ($client) {
    $baseline = @(Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -ExpandProperty Id)
}

$clock = [System.Diagnostics.Stopwatch]::StartNew()
$url = ([uri]$page).AbsoluteUri
Start-Splash -browser $browser -url $url

# If the client is already open there is no new window to wait for, so end on schedule.
if ($baseline.Count -gt 0) { $LatestEnd = [Math]::Min($LatestEnd, $EarliestEnd) }

if (-not $NoApp) {
    while ($clock.ElapsedMilliseconds -lt $AppStartMs) { Start-Sleep -Milliseconds 25 }
    Start-Process -FilePath $client | Out-Null
}

if ($KeepOpen) {
    Write-Host "splash running; kill msedge processes using $ProfileDir when done"
    return
}

# Hold the splash at least until the intro finishes, then until the client window shows.
$clientSeen = $false
while ($clock.ElapsedMilliseconds -lt $LatestEnd) {
    if ($clock.ElapsedMilliseconds -ge $EarliestEnd) {
        if ($NoApp) { break }
        $now = @(Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne 0 -and $baseline -notcontains $_.Id })
        if ($now.Count -gt 0) {
            $clientSeen = $true
            Start-Sleep -Milliseconds 260
            break
        }
    }
    Start-Sleep -Milliseconds 40
}

Stop-Splash
$clock.Stop()

if ($client -and -not $clientSeen -and -not $NoApp) {
    # The window did not paint in time; make sure the client is at least running.
    Start-Process -FilePath $client | Out-Null
}
