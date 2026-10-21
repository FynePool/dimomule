$ErrorActionPreference = "Stop"
$HostName = "it.dimomule_personal.ed2k_opener"
$RegPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
$Root = Join-Path $env:LOCALAPPDATA "DimomulePersonal"
$StatePath = Join-Path $Root "install-state.json"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "       DIMOMULE PERSONAL - DISINSTALLA" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "REGOLA: nessun file di Windows viene cancellato o modificato." -ForegroundColor Yellow
Write-Host "Il file C:\Windows\System32\drivers\etc\hosts NON viene toccato." -ForegroundColor Yellow
Write-Host ""

if (Test-Path -LiteralPath $RegPath) {
    Remove-Item -LiteralPath $RegPath -Recurse -Force
    Write-Host "[OK] Registrazione Native Messaging Dimomule rimossa." -ForegroundColor Green
}

$fallback = @(
  "Chrome\manifest.json","Chrome\content.js","Chrome\page-bridge.js","Chrome\service-worker.js",
  "Chrome\popup.html","Chrome\popup.css","Chrome\info.html","Chrome\info.css",
  "Chrome\icons\icon16.png","Chrome\icons\icon32.png","Chrome\icons\icon48.png","Chrome\icons\icon128.png",
  "NativeHost\NativeHost.cs","NativeHost\DimomuleNativeHost.exe","NativeHost\native-host.json","NativeHost\Dimomule.log",
  "VERSION.txt","REVISION.txt"
)
$owned = $fallback
if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
    try {
        $state = Get-Content -Raw -LiteralPath $StatePath | ConvertFrom-Json
        $owned = @($state.owned_files | ForEach-Object { [string]$_ })
    } catch {
        Write-Host "[ATTENZIONE] Stato installazione non leggibile; uso elenco sicuro incorporato." -ForegroundColor Yellow
    }
}

$parents = New-Object System.Collections.Generic.List[string]
foreach ($rel in @($owned | Sort-Object -Unique)) {
    $f = Join-Path $Root $rel
    if (Test-Path -LiteralPath $f -PathType Leaf) {
        Remove-Item -LiteralPath $f -Force
        Write-Host "[OK] Rimosso file Dimomule: $f"
    }
    $p = Split-Path -Parent $f
    while ($p -and $p.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase) -and $p -ne $Root) {
        if (-not $parents.Contains($p)) { $parents.Add($p) }
        $p = Split-Path -Parent $p
    }
}
if (Test-Path -LiteralPath $StatePath -PathType Leaf) { Remove-Item -LiteralPath $StatePath -Force }

foreach ($d in @($parents | Sort-Object Length -Descending)) {
    if (Test-Path -LiteralPath $d -PathType Container) {
        $remaining = @(Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue)
        if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $d -Force }
    }
}
if (Test-Path -LiteralPath $Root -PathType Container) {
    $remaining = @(Get-ChildItem -LiteralPath $Root -Force -ErrorAction SilentlyContinue)
    if ($remaining.Count -eq 0) {
        Remove-Item -LiteralPath $Root -Force
    } else {
        Write-Host "[ATTENZIONE] %LOCALAPPDATA%\DimomulePersonal contiene elementi non appartenenti all'elenco Dimomule: lasciati intatti." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "DISINSTALLAZIONE COMPONENTI DIMOMULE COMPLETATA." -ForegroundColor Green
Write-Host "Nessun file Windows, associazione ed2k:// o file hosts e stato modificato." -ForegroundColor Green
Write-Host "Rimuovi anche l'estensione da chrome://extensions se e ancora presente."
