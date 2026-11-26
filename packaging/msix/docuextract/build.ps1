<#
  Crea il pacchetto MSIX di Rouges-DocuExtract per il Microsoft Store.

  Serve il Windows SDK (makeappx, makepri, signtool):
      winget install Microsoft.WindowsSDK.10.0.26100

  I valori si trovano in Partner Center > la tua app > Gestione prodotto > Identità prodotto:
      .\build.ps1 -IdentityName "12345Rouges.Rouges-DocuExtract" `
                  -Publisher "CN=1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D" `
                  -PublisherDisplayName "Rouges"

  Risultato in .\out:
      Rouges-DocuExtract_<version>_x64.msix       non firmato: è quello da caricare nello Store
      Rouges-DocuExtract_<version>_x64.test.msix  solo con -TestSign: firmato con un certificato locale, per installarlo sul tuo PC
#>
param(
    [Parameter(Mandatory)] [string] $IdentityName,
    [Parameter(Mandatory)] [string] $Publisher,
    [Parameter(Mandatory)] [string] $PublisherDisplayName,
    [string] $DisplayName = 'Rouges-DocuExtract',
    [switch] $TestSign
)

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$catalog = Join-Path $here '..\..\..\catalog.json'
$work    = Join-Path $here 'work'
$layout  = Join-Path $work 'layout'
$out     = Join-Path $here 'out'

# --- Strumenti del Windows SDK -------------------------------------------------------
function Find-SdkTool([string] $name) {
    $root = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    $hit = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName "x64\$name" } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
    if (-not $hit) { throw "$name non trovato. Installa il Windows SDK: winget install Microsoft.WindowsSDK.10.0.26100" }
    $hit
}
$makeappx = Find-SdkTool 'makeappx.exe'
$makepri  = Find-SdkTool 'makepri.exe'

# --- Pacchetto dal catalogo (stesso zip e stesso SHA-256 del launcher) ----------
$app = (Get-Content $catalog -Raw | ConvertFrom-Json).apps | Where-Object id -eq 'docuextract'
if (-not $app) { throw 'docuextract non trovato in catalog.json' }
$parts = $app.version.Split('.')
while ($parts.Count -lt 3) { $parts += '0' }
$version = ($parts[0..2] -join '.') + '.0'     # lo Store vuole il 4° numero a 0
Write-Host "DocuExtract $($app.version) -> versione MSIX $version"

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item $layout -ItemType Directory -Force | Out-Null
New-Item $out -ItemType Directory -Force | Out-Null

$zip = Join-Path $work 'docuextract.zip'
Invoke-WebRequest $app.package.url -OutFile $zip -UseBasicParsing
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $app.package.sha256.ToLower()) { throw "SHA-256 non corrispondente: $hash" }
Expand-Archive $zip -DestinationPath $layout

# --- Manifest e loghi ------------------------------------------------------
function Escape-Xml([string] $s) { [System.Security.SecurityElement]::Escape($s) }
$manifest = Get-Content (Join-Path $here 'AppxManifest.template.xml') -Raw -Encoding UTF8
$manifest = $manifest.Replace('{{IDENTITY_NAME}}', (Escape-Xml $IdentityName))
$manifest = $manifest.Replace('{{PUBLISHER_DISPLAY_NAME}}', (Escape-Xml $PublisherDisplayName))
$manifest = $manifest.Replace('{{PUBLISHER}}', (Escape-Xml $Publisher))
$manifest = $manifest.Replace('{{DISPLAY_NAME}}', (Escape-Xml $DisplayName))
$manifest = $manifest.Replace('{{VERSION}}', $version)
[System.IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifest, (New-Object System.Text.UTF8Encoding $false))
Copy-Item (Join-Path $here 'Assets') (Join-Path $layout 'Assets') -Recurse

# resources.pri: permette a Windows di scegliere il logo giusto per ogni scala e dimensione (scale-200, targetsize-48...)
$priconfig = Join-Path $work 'priconfig.xml'
& $makepri createconfig /cf $priconfig /dq it-IT_en-US /pv 10.0.0 /o | Out-Null
& $makepri new /pr $layout /cf $priconfig /mn (Join-Path $layout 'AppxManifest.xml') /of (Join-Path $layout 'resources.pri') /o
if ($LASTEXITCODE) { throw 'makepri non riuscito' }

# --- Creazione del pacchetto --------------------------------------------------------------------
$msix = Join-Path $out "Rouges-DocuExtract_${version}_x64.msix"
& $makeappx pack /d $layout /p $msix /o
if ($LASTEXITCODE) { throw 'makeappx non riuscito' }
Write-Host "`nPacchetto per lo Store: $msix" -ForegroundColor Green

# --- Facoltativo: firma di prova locale -------------------------------------------
if ($TestSign) {
    $signtool = Find-SdkTool 'signtool.exe'
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $Publisher -and $_.HasPrivateKey } | Select-Object -First 1
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -Type Custom -Subject $Publisher -KeyUsage DigitalSignature `
            -FriendlyName 'Rouges MSIX test' -CertStoreLocation Cert:\CurrentUser\My `
            -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
    }
    $cer = Join-Path $out 'rouges-test.cer'
    Export-Certificate -Cert $cert -FilePath $cer | Out-Null

    $test = $msix -replace '\.msix$', '.test.msix'
    Copy-Item $msix $test -Force
    & $signtool sign /fd SHA256 /sha1 $cert.Thumbprint $test
    if ($LASTEXITCODE) { throw 'signtool non riuscito' }

    Write-Host "`nPacchetto di prova: $test" -ForegroundColor Green
    Write-Host 'Per installarlo, una volta sola, da PowerShell come amministratore:'
    Write-Host "    Import-Certificate -FilePath '$cer' -CertStoreLocation Cert:\LocalMachine\TrustedPeople"
    Write-Host 'poi:'
    Write-Host "    Add-AppxPackage '$test'"
}
