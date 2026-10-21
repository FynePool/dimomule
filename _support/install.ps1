$ErrorActionPreference = "Stop"

$Version = "1.0"
$ManifestVersion = "1.0.0"
$HostName = "it.dimomule_personal.ed2k_opener"
$ExtensionId = "jipokengmllmldjhfjceeemnnnjeicli"
$ExpectedKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw+scjkhdTQxg/IQfBYQ9Y2l0YafYTHPJOaSE2VPC6sxUDyPMwYVjka/WED17i8l10TC8zYcSfLKTgGVmGCPAYaDoitoPOvgFXV6hvn+1oOHMJwxYjz/rqxW9croor9dgj5HxkT6gGOZQbJtRqZ3hnVBIpO4/ECsNpJpWanJH9GkxH/z1EbfjUf8wNJV46C78CwH7KeeMBRGdH5hk6uYTc8oIsxxNjXCMR/4XPe0HpL1Cy3l6B0PuAPWDIBiOHcGuG4ZGCOcerLNs7EikBpQ2g7edQXelrEEEvu655U/50wAPtaiK11ETTi6HUMt6u/JXh6bHP8Ar4CW/cNSwvCGIOwIDAQAB"

$PackageRoot = Split-Path -Parent $PSScriptRoot
$SourceCs = Join-Path $PSScriptRoot "NativeHost.cs"
$SourceChrome = Join-Path $PackageRoot "Chrome"
$RevisionFile = Join-Path $PackageRoot "REVISION.txt"
$Revision = if (Test-Path -LiteralPath $RevisionFile) { (Get-Content -LiteralPath $RevisionFile -TotalCount 1).Trim() } else { "r000" }
if ($Revision -notmatch '^r\d{3,}(-p\d+)?$') { throw "REVISION.txt non valido: $Revision" }

$Root = Join-Path $env:LOCALAPPDATA "DimomulePersonal"
$InstallDir = Join-Path $Root "NativeHost"
$ChromeInstallDir = Join-Path $Root "Chrome"
$Exe = Join-Path $InstallDir "DimomuleNativeHost.exe"
$Manifest = Join-Path $InstallDir "native-host.json"
$StatePath = Join-Path $Root "install-state.json"
$VersionPath = Join-Path $Root "VERSION.txt"
$RevisionPath = Join-Path $Root "REVISION.txt"
$RegPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"

function Ensure-Parent([string]$Path) {
    $p = Split-Path -Parent $Path
    if ($p -and !(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Get-RelativeChromeFiles {
    $base = $SourceChrome.TrimEnd('\') + '\'
    @(Get-ChildItem -LiteralPath $SourceChrome -File -Recurse | ForEach-Object {
        $_.FullName.Substring($base.Length)
    })
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "          DIMOMULE PERSONAL" -ForegroundColor Cyan
Write-Host "          build $Revision" -ForegroundColor DarkCyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

try {
    $handler = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\ed2k\shell\open\command")."(default)"
    if ([string]::IsNullOrWhiteSpace($handler)) { throw "Associazione vuota" }
    Write-Host "[OK] Protocollo ed2k:// associato a:" -ForegroundColor Green
    Write-Host "     $handler"
} catch {
    Write-Host "[ERRORE] Windows non ha un gestore ed2k:// registrato." -ForegroundColor Red
    Write-Host "Apri eMule e registra prima i link ED2K, poi rilancia Dimomule."
    exit 20
}

if (!(Test-Path -LiteralPath $SourceChrome -PathType Container)) { throw "Cartella Chrome non trovata: $SourceChrome" }
if (!(Test-Path -LiteralPath $SourceCs -PathType Leaf)) { throw "NativeHost.cs non trovato: $SourceCs" }

# Controlli che impediscono di cambiare accidentalmente l'identita dell'estensione.
$sourceManifestPath = Join-Path $SourceChrome "manifest.json"
$sourceManifest = Get-Content -Raw -LiteralPath $sourceManifestPath | ConvertFrom-Json
if ($sourceManifest.name -ne "Dimomule Personal") { throw "Nome estensione inatteso nel manifest." }
if ($sourceManifest.version -ne $ManifestVersion) { throw "Versione manifest inattesa: $($sourceManifest.version)" }
if ($sourceManifest.key -ne $ExpectedKey) { throw "CHIAVE ESTENSIONE MODIFICATA: installazione bloccata per non cambiare ID Chrome." }
if ($sourceManifest.action.default_popup -ne "popup.html") { throw "Popup informativo mancante nel manifest." }

$nativeSourceText = Get-Content -Raw -LiteralPath $SourceCs
if ($nativeSourceText -notlike "*$ExtensionId*") { throw "NativeHost.cs non contiene l'ID estensione atteso." }

$chromeRel = Get-RelativeChromeFiles
$required = @("manifest.json","content.js","page-bridge.js","service-worker.js","popup.html","popup.css","info.html","info.css","icons\icon16.png","icons\icon32.png","icons\icon48.png","icons\icon128.png")
foreach ($r in $required) {
    if ($chromeRel -notcontains $r) { throw "File obbligatorio mancante nel pacchetto: Chrome\$r" }
}

# Elenco dei file che questa build possiede. Serve per aggiornamenti e disinstallazione sicuri.
$newOwned = @()
$newOwned += $chromeRel | ForEach-Object { "Chrome\$_" }
$newOwned += @("NativeHost\NativeHost.cs","NativeHost\DimomuleNativeHost.exe","NativeHost\native-host.json","NativeHost\Dimomule.log","VERSION.txt","REVISION.txt")
$newOwned = @($newOwned | Sort-Object -Unique)

# Compatibilita con le installazioni precedenti, prive di install-state.json.
$fallbackOldOwned = @(
  "Chrome\manifest.json","Chrome\content.js","Chrome\page-bridge.js","Chrome\service-worker.js",
  "Chrome\popup.html","Chrome\popup.css","Chrome\info.html","Chrome\info.css",
  "Chrome\icons\icon16.png","Chrome\icons\icon32.png","Chrome\icons\icon48.png","Chrome\icons\icon128.png",
  "NativeHost\NativeHost.cs","NativeHost\DimomuleNativeHost.exe","NativeHost\native-host.json","NativeHost\Dimomule.log",
  "VERSION.txt","REVISION.txt"
)
$previousOwned = @()
if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
    try {
        $oldState = Get-Content -Raw -LiteralPath $StatePath | ConvertFrom-Json
        $previousOwned = @($oldState.owned_files | ForEach-Object { [string]$_ })
    } catch {
        Write-Host "[ATTENZIONE] install-state.json non leggibile; uso elenco compatibile." -ForegroundColor Yellow
        $previousOwned = $fallbackOldOwned
    }
} else {
    $previousOwned = $fallbackOldOwned
}

$allTouched = @($previousOwned + $newOwned + @("install-state.json") | Sort-Object -Unique)
$stage = Join-Path $env:TEMP ("DimomuleStage_" + [Guid]::NewGuid().ToString("N"))
$backup = Join-Path $env:TEMP ("DimomuleBackup_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $backup -Force | Out-Null

$existed = @{}
$regExisted = Test-Path -LiteralPath $RegPath
$oldRegValue = $null
if ($regExisted) {
    try { $oldRegValue = (Get-Item -LiteralPath $RegPath).GetValue("") } catch { $oldRegValue = $null }
}

try {
    # Backup esclusivamente dei file Dimomule noti o registrati nello stato precedente.
    foreach ($rel in $allTouched) {
        $src = Join-Path $Root $rel
        $existed[$rel] = (Test-Path -LiteralPath $src -PathType Leaf)
        if ($existed[$rel]) {
            $dst = Join-Path $backup $rel
            Ensure-Parent $dst
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
    }

    # Prepara una build completa in staging prima di toccare i file installati.
    $stageChrome = Join-Path $stage "Chrome"
    $stageNative = Join-Path $stage "NativeHost"
    New-Item -ItemType Directory -Path $stageChrome -Force | Out-Null
    New-Item -ItemType Directory -Path $stageNative -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceChrome "*") -Destination $stageChrome -Recurse -Force
    Copy-Item -LiteralPath $SourceCs -Destination (Join-Path $stageNative "NativeHost.cs") -Force

    $stageExe = Join-Path $stageNative "DimomuleNativeHost.exe"
    $source = Get-Content -Raw -LiteralPath (Join-Path $stageNative "NativeHost.cs")
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $stageExe -OutputType ConsoleApplication -ReferencedAssemblies @("System.dll","System.Web.Extensions.dll")
    if (!(Test-Path -LiteralPath $stageExe -PathType Leaf)) { throw "Impossibile creare il Native Host." }

    $stageNativeManifest = Join-Path $stageNative "native-host.json"
    $finalExe = Join-Path $InstallDir "DimomuleNativeHost.exe"
    $nativeHostManifestData = @{
      name = $HostName
      description = "Dimomule Personal Native Messaging Host"
      path = $finalExe
      type = "stdio"
      allowed_origins = @("chrome-extension://$ExtensionId/")
    }
    $json = $nativeHostManifestData | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($stageNativeManifest, $json, (New-Object System.Text.UTF8Encoding($false)))

    # Solo ora aggiorna le directory stabili.
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ChromeInstallDir -Force | Out-Null
    Copy-Item -Path (Join-Path $stageChrome "*") -Destination $ChromeInstallDir -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $stageNative "NativeHost.cs") -Destination (Join-Path $InstallDir "NativeHost.cs") -Force
    Copy-Item -LiteralPath $stageExe -Destination $Exe -Force
    Copy-Item -LiteralPath $stageNativeManifest -Destination $Manifest -Force

    # Rimuove soltanto file appartenenti alla vecchia Dimomule che non esistono piu nella nuova build.
    $stale = @($previousOwned | Where-Object { $newOwned -notcontains $_ })
    foreach ($rel in $stale) {
        $f = Join-Path $Root $rel
        if (Test-Path -LiteralPath $f -PathType Leaf) { Remove-Item -LiteralPath $f -Force }
    }

    $versionText = "Dimomule Personal`r`nBuild: $Revision`r`nExtension ID: $ExtensionId`r`nChrome: $ChromeInstallDir`r`nNativeHost: $InstallDir`r`n"
    [System.IO.File]::WriteAllText($VersionPath, $versionText, (New-Object System.Text.UTF8Encoding($false)))
    [System.IO.File]::WriteAllText($RevisionPath, ($Revision + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))

    New-Item -Path $RegPath -Force | Out-Null
    Set-Item -Path $RegPath -Value $Manifest

    $state = [ordered]@{
      product = "Dimomule"
      visible_version = $Version
      build = $Revision
      extension_id = $ExtensionId
      native_host = $HostName
      chrome_dir = $ChromeInstallDir
      native_dir = $InstallDir
      installed_utc = [DateTime]::UtcNow.ToString("o")
      owned_files = $newOwned
    }
    $stateJson = $state | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($StatePath, $stateJson, (New-Object System.Text.UTF8Encoding($false)))

} catch {
    Write-Host "[ERRORE] Aggiornamento non completato. Ripristino della situazione precedente..." -ForegroundColor Red
    foreach ($rel in $allTouched) {
        $dest = Join-Path $Root $rel
        $bak = Join-Path $backup $rel
        if ($existed.ContainsKey($rel) -and $existed[$rel] -and (Test-Path -LiteralPath $bak -PathType Leaf)) {
            Ensure-Parent $dest
            Copy-Item -LiteralPath $bak -Destination $dest -Force
        } elseif ($existed.ContainsKey($rel) -and -not $existed[$rel] -and (Test-Path -LiteralPath $dest -PathType Leaf)) {
            Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        }
    }
    if ($regExisted) {
        New-Item -Path $RegPath -Force | Out-Null
        if ($null -ne $oldRegValue) { Set-Item -Path $RegPath -Value $oldRegValue }
    } else {
        if (Test-Path -LiteralPath $RegPath) { Remove-Item -LiteralPath $RegPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
    throw
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "[OK] Native Host installato/aggiornato in:" -ForegroundColor Green
Write-Host "     $InstallDir"
Write-Host "[OK] Estensione Chrome installata/aggiornata in:" -ForegroundColor Green
Write-Host "     $ChromeInstallDir"
Write-Host "[OK] ID estensione bloccato: $ExtensionId" -ForegroundColor Green
Write-Host "[OK] Build installata: $Revision" -ForegroundColor Green
Write-Host ""
Write-Host "PRIMA INSTALLAZIONE:" -ForegroundColor Yellow
Write-Host "  1. apri chrome://extensions"
Write-Host "  2. attiva Modalita sviluppatore"
Write-Host "  3. scegli Carica estensione non pacchettizzata"
Write-Host "  4. seleziona: $ChromeInstallDir"
Write-Host ""
Write-Host "AGGIORNAMENTI SUCCESSIVI:" -ForegroundColor Yellow
Write-Host "  Non ricaricare la cartella. Chrome resta collegato allo stesso percorso."
Write-Host "  Dopo l'installer, premi soltanto Ricarica sulla scheda Dimomule se necessario."
Write-Host ""
try {
    Set-Clipboard -Value $ChromeInstallDir
    Write-Host "[OK] Percorso Chrome copiato negli appunti." -ForegroundColor Green
} catch {
    Write-Host "[INFO] Percorso Chrome: $ChromeInstallDir" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "INSTALLAZIONE/AGGIORNAMENTO DIMOMULE PERSONAL COMPLETATO." -ForegroundColor Green
Write-Host "Nessuna finestra aggiuntiva e stata aperta." -ForegroundColor Green
