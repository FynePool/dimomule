$HostName = "it.dimomule_personal.ed2k_opener"
$ExtensionId = "jipokengmllmldjhfjceeemnnnjeicli"
$ExpectedKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw+scjkhdTQxg/IQfBYQ9Y2l0YafYTHPJOaSE2VPC6sxUDyPMwYVjka/WED17i8l10TC8zYcSfLKTgGVmGCPAYaDoitoPOvgFXV6hvn+1oOHMJwxYjz/rqxW9croor9dgj5HxkT6gGOZQbJtRqZ3hnVBIpO4/ECsNpJpWanJH9GkxH/z1EbfjUf8wNJV46C78CwH7KeeMBRGdH5hk6uYTc8oIsxxNjXCMR/4XPe0HpL1Cy3l6B0PuAPWDIBiOHcGuG4ZGCOcerLNs7EikBpQ2g7edQXelrEEEvu655U/50wAPtaiK11ETTi6HUMt6u/JXh6bHP8Ar4CW/cNSwvCGIOwIDAQAB"
$Root = Join-Path $env:LOCALAPPDATA "DimomulePersonal"
$NativeDir = Join-Path $Root "NativeHost"
$ChromeDir = Join-Path $Root "Chrome"
$RegPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
$errors = 0

function Ok([string]$s) { Write-Host "[OK] $s" -ForegroundColor Green }
function Err([string]$s) { $script:errors++; Write-Host "[ERRORE] $s" -ForegroundColor Red }
function Info([string]$s) { Write-Host "[INFO] $s" -ForegroundColor Yellow }

Write-Host "=== DIMOMULE PERSONAL - VERIFICA ===" -ForegroundColor Cyan
try {
  $handler=(Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\ed2k\shell\open\command")."(default)"
  if ([string]::IsNullOrWhiteSpace($handler)) { Err "Associazione ed2k:// vuota" } else { Ok "ED2K: $handler" }
} catch { Err "Associazione ed2k:// assente" }

$nativeManifestPath = Join-Path $NativeDir "native-host.json"
$nativeExe = Join-Path $NativeDir "DimomuleNativeHost.exe"
if (Test-Path -LiteralPath $nativeExe -PathType Leaf) { Ok "Native Host presente" } else { Err "Native Host mancante" }
if (Test-Path -LiteralPath $RegPath) {
    try {
        $regValue = (Get-Item -LiteralPath $RegPath).GetValue("")
        if ($regValue -eq $nativeManifestPath) { Ok "Native Messaging registrato correttamente" } else { Err "Registro Native Messaging punta a: $regValue" }
    } catch { Err "Impossibile leggere la registrazione Native Messaging" }
} else { Err "Native Messaging non registrato" }

if (Test-Path -LiteralPath $nativeManifestPath -PathType Leaf) {
    try {
        $nm = Get-Content -Raw -LiteralPath $nativeManifestPath | ConvertFrom-Json
        if ($nm.name -eq $HostName -and $nm.path -eq $nativeExe -and @($nm.allowed_origins) -contains "chrome-extension://$ExtensionId/") {
            Ok "Manifest Native Host coerente"
        } else { Err "Manifest Native Host incoerente" }
    } catch { Err "Manifest Native Host non leggibile" }
} else { Err "native-host.json mancante" }

$chromeManifestPath = Join-Path $ChromeDir "manifest.json"
if (Test-Path -LiteralPath $chromeManifestPath -PathType Leaf) {
    try {
        $cm = Get-Content -Raw -LiteralPath $chromeManifestPath | ConvertFrom-Json
        if ($cm.key -eq $ExpectedKey -and $cm.version -eq "1.0.0" -and $cm.name -eq "Dimomule Personal") {
            Ok "Manifest Chrome: identita e versione corrette"
        } else { Err "Manifest Chrome non corrisponde alla Dimomule attesa" }
        if ($cm.action.default_popup -eq "popup.html" -and (Test-Path -LiteralPath (Join-Path $ChromeDir "popup.html"))) { Ok "Popup informazioni presente" } else { Err "Popup informazioni mancante" }
    } catch { Err "Manifest Chrome non leggibile" }
} else { Err "Estensione stabile mancante: $ChromeDir" }

$rev = Join-Path $Root "REVISION.txt"
if (Test-Path -LiteralPath $rev) { Info ("Build installata: " + ((Get-Content -LiteralPath $rev -TotalCount 1).Trim())) }
Info "ID atteso: $ExtensionId"
Info "Chrome deve restare caricato da: $ChromeDir"

if ($errors -eq 0) {
    Write-Host ""; Write-Host "VERIFICA COMPLETATA: componenti locali Dimomule coerenti." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""; Write-Host "VERIFICA COMPLETATA CON $errors ERRORE/I." -ForegroundColor Red
    exit 1
}
