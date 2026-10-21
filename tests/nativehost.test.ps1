# Test del Native Host compilato con gli stessi casi di tests/validate.test.mjs.
# Uso (Windows): pwsh tests/nativehost.test.ps1 -Exe build\DimomuleNativeHost.exe
# I link validi vengono aperti davvero: serve un gestore ed2k:// registrato (in CI uno fittizio).
param([Parameter(Mandatory = $true)][string]$Exe)

$ErrorActionPreference = "Stop"
$Origin = "chrome-extension://jipokengmllmldjhfjceeemnnnjeicli/"
$errors = 0

function Read-Exact($Stream, [int]$Count) {
    $buf = New-Object byte[] $Count
    $off = 0
    while ($off -lt $Count) {
        $n = $Stream.Read($buf, $off, $Count - $off)
        if ($n -le 0) { return $null }
        $off += $n
    }
    return ,$buf
}

function Invoke-NativeHost([string]$CallerOrigin, [string]$Url) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Resolve-Path -LiteralPath $Exe).Path
    $psi.Arguments = $CallerOrigin
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $payload = [System.Text.Encoding]::UTF8.GetBytes((@{ url = $Url } | ConvertTo-Json -Compress))
    try {
        $stdin = $p.StandardInput.BaseStream
        $stdin.Write([BitConverter]::GetBytes([int]$payload.Length), 0, 4)
        $stdin.Write($payload, 0, $payload.Length)
        $stdin.Close()
    } catch {
        # Il Native Host puo chiudere prima di leggere (origine rifiutata).
    }
    $stdout = $p.StandardOutput.BaseStream
    $len = Read-Exact $stdout 4
    if ($null -eq $len) { throw "Nessuna risposta dal Native Host" }
    $body = Read-Exact $stdout ([BitConverter]::ToInt32($len, 0))
    if (-not $p.WaitForExit(15000)) { $p.Kill(); throw "Timeout del Native Host" }
    return ([System.Text.Encoding]::UTF8.GetString($body) | ConvertFrom-Json)
}

$cases = (& node (Join-Path $PSScriptRoot "validate.test.mjs") --dump) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $cases.Count -eq 0) { throw "Impossibile leggere i casi da validate.test.mjs" }

foreach ($c in $cases) {
    $r = Invoke-NativeHost $Origin $c.url
    if ($c.expected) { $good = ($r.ok -eq $true) } else { $good = ($r.ok -ne $true -and $r.error -eq "invalid_ed2k_url") }
    if (-not $good) {
        $errors++
        Write-Host ("[ERRORE] " + $c.label + ": risposta " + ($r | ConvertTo-Json -Compress)) -ForegroundColor Red
    }
}

$r = Invoke-NativeHost "chrome-extension://mihhpbnljinclnfipcadonlnnnnngkbk/" $cases[0].url
if ($r.error -ne "unauthorized_origin") { $errors++; Write-Host "[ERRORE] origine non autorizzata accettata" -ForegroundColor Red }

if ($errors -eq 0) {
    Write-Host ("[OK] Native Host: " + ($cases.Count + 1) + " casi superati") -ForegroundColor Green
    exit 0
}
Write-Host "Native Host: $errors casi falliti" -ForegroundColor Red
exit 1
