# Rouges-Launcher - one-command install, without the browser (so no SmartScreen warning):
#
#   irm https://raw.githubusercontent.com/rouges78/Rouges-Suite/main/install.ps1 | iex
#
# Reads the latest launcher from the catalog, downloads RougesSetup.exe, checks its size and SHA-256 and runs it:
# the launcher installs itself in %LOCALAPPDATA%\Rouges\Launcher and opens.
# The catalog comes from the same repository as this script, so it is trusted as much as the script itself;
# its signature is checked by the launcher, which refuses a catalog that is not signed.
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
    $uri = $null
    if (-not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$uri)) { return $false }
    if ($uri.Scheme -eq 'https') { return $true }
    # Plain http only for tests, and only from this PC.
    return $testing -and $uri.Scheme -eq 'http' -and ($uri.Host -eq '127.0.0.1' -or $uri.Host -eq 'localhost')
}

if (-not (Test-Address $catalogUrl)) { throw "Invalid catalog address: $catalogUrl" }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host 'Rouges-Launcher: reading the catalog...'
$catalog = Invoke-RestMethod -Uri $catalogUrl -UseBasicParsing
$launcher = $catalog.launcher
if (-not $launcher -or -not $launcher.url -or -not $launcher.sha256 -or -not $launcher.size) { throw 'The catalog does not list the launcher.' }
if (-not (Test-Address $launcher.url)) { throw "Invalid launcher address: $($launcher.url)" }
$version = [string]$launcher.version
if ($version -notmatch '^\d+(\.\d+){1,3}$') { throw "Invalid launcher version: $version" }
$size = [long]$launcher.size

$setup = Join-Path $env:TEMP "RougesSetup-$version.exe"
try {
    Write-Host "Downloading Rouges-Launcher $version..."
    Invoke-WebRequest -Uri $launcher.url -OutFile $setup -UseBasicParsing

    if ((Get-Item $setup).Length -ne $size) { throw 'The size does not match the catalog: install cancelled.' }
    $hash = (Get-FileHash -Path $setup -Algorithm SHA256).Hash
    if ($hash -ne $launcher.sha256.ToUpperInvariant()) { throw 'The SHA-256 does not match the catalog: install cancelled.' }

    Write-Host 'Installing...'
    $installed = Join-Path $env:LOCALAPPDATA 'Rouges\Launcher\RougesLauncher.exe'
    # Only the setup: "-Wait" would also wait for the launcher the setup opens at the end.
    $process = Start-Process -FilePath $setup -ArgumentList '--install' -PassThru
    $process.WaitForExit()
    # The setup reports its own errors in a window and always exits with 0: the installed launcher
    # must be this very file.
    $ok = $process.ExitCode -eq 0 -and (Test-Path $installed) -and (Get-FileHash -Path $installed -Algorithm SHA256).Hash -eq $hash
    if (-not $ok) { throw 'Rouges-Launcher was not installed.' }
} finally {
    Remove-Item $setup -Force -ErrorAction SilentlyContinue
}
Write-Host 'Done: Rouges-Launcher is in the Start menu and on the desktop.'
