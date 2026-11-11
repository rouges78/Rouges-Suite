# Rouges@Launcher - one-command install, without the browser (so no SmartScreen warning):
#
#   irm https://raw.githubusercontent.com/rouges78/Rouges-Suite/main/install.ps1 | iex
#
# Reads the latest launcher from the catalog, downloads RougesSetup.exe, checks its SHA-256 and runs it:
# the launcher installs itself in %LOCALAPPDATA%\Rouges\Launcher and opens.
# (ASCII only: "irm | iex" does not always keep the encoding.)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # PowerShell 5's progress bar slows downloads down a lot

$catalogUrl = 'https://raw.githubusercontent.com/rouges78/Rouges-Suite/main/catalog.json'
$testing = $false
if ($env:ROUGES_CATALOG) {
    # Tests only: a catalog served by this PC.
    $catalogUrl = $env:ROUGES_CATALOG
    $testing = $true
}

function Test-Address([string]$url) {
    if ($url.StartsWith('https://')) { return $true }
    return $testing -and ($url.StartsWith('http://127.0.0.1') -or $url.StartsWith('http://localhost'))
}

if (-not (Test-Address $catalogUrl)) { throw "Invalid catalog address: $catalogUrl" }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host 'Rouges@Launcher: reading the catalog...'
$catalog = Invoke-RestMethod -Uri $catalogUrl -UseBasicParsing
$launcher = $catalog.launcher
if (-not $launcher -or -not $launcher.url -or -not $launcher.sha256) { throw 'The catalog does not list the launcher.' }
if (-not (Test-Address $launcher.url)) { throw "Invalid launcher address: $($launcher.url)" }

$setup = Join-Path $env:TEMP ("RougesSetup-{0}.exe" -f $launcher.version)
Write-Host ("Downloading Rouges@Launcher {0}..." -f $launcher.version)
Invoke-WebRequest -Uri $launcher.url -OutFile $setup -UseBasicParsing

$hash = (Get-FileHash -Path $setup -Algorithm SHA256).Hash
if ($hash -ne $launcher.sha256.ToUpperInvariant()) {
    Remove-Item $setup -Force
    throw 'The SHA-256 does not match the catalog: install cancelled.'
}

Write-Host 'Installing...'
# Only the setup: "-Wait" would also wait for the launcher the setup opens at the end.
$process = Start-Process -FilePath $setup -ArgumentList '--install' -PassThru
$process.WaitForExit()
Remove-Item $setup -Force -ErrorAction SilentlyContinue
Write-Host 'Done: Rouges@Launcher is in the Start menu and on the desktop.'
