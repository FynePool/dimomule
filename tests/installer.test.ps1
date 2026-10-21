# Test del setup in modalita silenziosa: installa, controlla manifest e registro, disinstalla.
# Uso (Windows): pwsh tests/installer.test.ps1 -Setup dist\DimomulePersonal-Setup-rXXX.exe
# Richiede un gestore ed2k:// registrato (in CI uno fittizio).
param([Parameter(Mandatory = $true)][string]$Setup)

$ErrorActionPreference = "Stop"
$App = Join-Path $env:LOCALAPPDATA "DimomulePersonal"
$RegPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\it.dimomule_personal.ed2k_opener"
$ExpectedKey = (Get-Content -Raw (Join-Path $PSScriptRoot "..\Chrome\manifest.json") | ConvertFrom-Json).key
$errors = 0

function Check([bool]$Cond, [string]$Msg) {
    if ($Cond) { Write-Host "[OK] $Msg" -ForegroundColor Green }
    else { $script:errors++; Write-Host "[ERRORE] $Msg" -ForegroundColor Red }
}

function Invoke-Setup([string[]]$Extra) {
    $argList = @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART") + $Extra
    $p = Start-Process -FilePath (Resolve-Path -LiteralPath $Setup).Path -ArgumentList $argList -PassThru
    # Un setup silenzioso bloccato non deve appendere la CI: dopo 2 minuti lo chiude e fallisce.
    if (-not $p.WaitForExit(120000)) {
        Write-Host "[ERRORE] setup bloccato con $($Extra -join ' '), terminato" -ForegroundColor Red
        Stop-Process -Id $p.Id -Force
        Get-Process | Where-Object { $_.Path -like "$env:TEMP\is-*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        return -1
    }
    return $p.ExitCode
}

function Get-Matches {
    $m = Get-Content -Raw (Join-Path $App "Chrome\manifest.json") | ConvertFrom-Json
    return ,@($m.content_scripts | ForEach-Object { $_.matches -join " " })
}

function Test-Installed([string]$Label, [string]$ExpectedMatches) {
    $m = Get-Content -Raw (Join-Path $App "Chrome\manifest.json") | ConvertFrom-Json
    Check ($m.key -eq $ExpectedKey) "$Label - chiave estensione invariata"
    $found = Get-Matches
    Check ($found.Count -eq 2 -and $found[0] -eq $ExpectedMatches -and $found[1] -eq $ExpectedMatches) "$Label - matches: $($found[0])"
    $exe = Join-Path $App "NativeHost\DimomuleNativeHost.exe"
    $jsonPath = Join-Path $App "NativeHost\native-host.json"
    Check (Test-Path -LiteralPath $exe) "$Label - Native Host presente"
    $nh = Get-Content -Raw $jsonPath | ConvertFrom-Json
    Check ($nh.name -eq "it.dimomule_personal.ed2k_opener" -and $nh.path -eq $exe -and @($nh.allowed_origins) -contains "chrome-extension://jipokengmllmldjhfjceeemnnnjeicli/") "$Label - native-host.json coerente"
    Check ((Get-Item -LiteralPath $RegPath).GetValue("") -eq $jsonPath) "$Label - registro Native Messaging"
}

$sel = "*://*.ddunlimited.net/* *://*.emulelinks.it/* *://*.ildragonero2.info/*"
$all = "http://*/* https://*/*"

Check ((Invoke-Setup @()) -eq 0) "prima installazione (predefinita)"
Test-Installed "predefinita" $sel

Check ((Invoke-Setup @("/DOMINI=tutti")) -eq 0) "installazione /DOMINI=tutti"
Test-Installed "tutti" $all

Check ((Invoke-Setup @()) -eq 0) "aggiornamento senza parametri"
Test-Installed "scelta precedente ricordata" $all

Check ((Invoke-Setup @("/DOMINI=https://www.emulelinks.it/forum/index.php,ddunlimited.net,EMULELINKS.it")) -eq 0) "installazione con URL completi"
Test-Installed "normalizzazione" "*://*.emulelinks.it/* *://*.ddunlimited.net/*"

Check ((Invoke-Setup @("/DOMINI=dominio_non_valido")) -eq 1) "dominio non valido rifiutato"
Test-Installed "dopo rifiuto" "*://*.emulelinks.it/* *://*.ddunlimited.net/*"

$uninstaller = Join-Path $App "unins000.exe"
Check (Test-Path -LiteralPath $uninstaller) "disinstallatore presente"
Start-Process -FilePath $uninstaller -ArgumentList @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART") -Wait
for ($i = 0; $i -lt 60 -and (Test-Path -LiteralPath $App); $i++) { Start-Sleep -Seconds 1 }
Check (-not (Test-Path -LiteralPath $App)) "cartella rimossa dalla disinstallazione"
Check (-not (Test-Path -LiteralPath $RegPath)) "registro Native Messaging rimosso"

if ($errors -eq 0) { Write-Host "SETUP: tutti i controlli superati" -ForegroundColor Green; exit 0 }
Write-Host "SETUP: $errors controlli falliti" -ForegroundColor Red
exit 1
