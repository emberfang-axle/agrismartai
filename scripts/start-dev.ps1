# AgriSmartAI :: Start backend + admin dashboard + farmer app (RELEASE builds)
# Release web builds load in seconds instead of 3+ minutes of debug scripts.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $root ".env"
$logDir = Join-Path $root "scripts\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Read-DotEnv($path) {
    $map = @{}
    if (-not (Test-Path $path)) { return $map }
    Get-Content $path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $idx = $line.IndexOf("=")
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        $map[$key] = $val
    }
    return $map
}

function Test-PortListening($port) {
    return $null -ne (netstat -ano | Select-String ":$port\s" | Select-String "LISTENING")
}

function Wait-ForHttp($url, $timeoutSec = 60) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
            if ($r.StatusCode -eq 200) { return $true }
        } catch {}
        Start-Sleep -Seconds 2
    }
    return $false
}

function Wait-ForFlutterApp($port, $label, $timeoutSec = 600) {
    Write-Host "  Waiting for $label (port $port, up to ${timeoutSec}s)..."
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        $indexOk = $false
        $jsOk = $false
        try {
            $idx = Invoke-WebRequest -Uri "http://127.0.0.1:${port}/" -UseBasicParsing -TimeoutSec 5
            $indexOk = ($idx.StatusCode -eq 200)
        } catch {}
        try {
            $js = Invoke-WebRequest -Uri "http://127.0.0.1:${port}/main.dart.js" -UseBasicParsing -TimeoutSec 5
            $jsOk = ($js.StatusCode -eq 200 -and $js.Content.Length -gt 1000)
        } catch {}
        if ($indexOk -and $jsOk) {
            Write-Host "  OK: $label is ready at http://localhost:$port" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 3
    }
    Write-Host "  TIMEOUT: $label not ready on port $port" -ForegroundColor Red
    return $false
}

function Build-FlutterWeb($appDir, $label, $logFile, $dartArg) {
    Write-Host "  Building $label (release, first time may take 3-5 min)..."
    $mainJs = Join-Path $appDir "build\web\main.dart.js"
    if (Test-Path $mainJs) { Remove-Item $mainJs -Force -ErrorAction SilentlyContinue }
    $buildCmd = @"
Set-Location '$appDir'
flutter pub get 2>&1 | Tee-Object -FilePath '$logFile' -Append
flutter build web --release $dartArg 2>&1 | Tee-Object -FilePath '$logFile' -Append
exit `$LASTEXITCODE
"@
    $proc = Start-Process powershell -Wait -PassThru -WindowStyle Minimized -ArgumentList @(
        "-Command", $buildCmd
    )
    if ($proc.ExitCode -ne 0) {
        Write-Host "  BUILD FAILED: $label - see $logFile" -ForegroundColor Red
        return $false
    }
    $mainJs = Join-Path $appDir "build\web\main.dart.js"
    if (-not (Test-Path $mainJs)) {
        Write-Host "  BUILD FAILED: main.dart.js missing for $label" -ForegroundColor Red
        return $false
    }
    Write-Host "  OK: $label built" -ForegroundColor Green
    return $true
}

function Start-StaticWeb($buildDir, $port, $logFile) {
    $serveCmd = "Set-Location '$buildDir'; python -m http.server $port --bind 127.0.0.1 2>&1 | Tee-Object -FilePath '$logFile' -Append"
    Start-Process powershell -WindowStyle Minimized -ArgumentList @("-NoExit", "-Command", $serveCmd)
}

# Free ports if something stale is running
foreach ($p in 8000, 8080, 8081) {
    if (Test-PortListening $p) {
        Write-Host "Port $p in use - stopping old servers..."
        & "$root\scripts\stop-dev.ps1"
        Start-Sleep -Seconds 2
        break
    }
}

$cfg = Read-DotEnv $envFile
$dartDefines = @()
foreach ($key in @("SUPABASE_URL", "SUPABASE_ANON_KEY", "API_BASE_URL")) {
    if ($cfg.ContainsKey($key) -and $cfg[$key]) {
        $dartDefines += "--dart-define=${key}=$($cfg[$key])"
    }
}
$dartArg = if ($dartDefines.Count -gt 0) { $dartDefines -join " " } else { "" }

$backendEnv = @{}
foreach ($key in @("SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "API_BASE_URL", "PORT")) {
    if ($cfg.ContainsKey($key) -and $cfg[$key]) { $backendEnv[$key] = $cfg[$key] }
}

$adminDir = Join-Path $root "frontend\admin_dashboard"
$farmerDir = Join-Path $root "frontend\mobile_app"
$adminLog = Join-Path $logDir "admin.log"
$farmerLog = Join-Path $logDir "farmer.log"
$adminServeLog = Join-Path $logDir "admin-serve.log"
$farmerServeLog = Join-Path $logDir "farmer-serve.log"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AgriSmartAI - Starting all services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# [1] Backend
Write-Host "[1/5] Backend API..."
$backendLog = Join-Path $logDir "backend.log"
$backendCmd = "Set-Location '$root\backend'"
foreach ($k in $backendEnv.Keys) {
    $backendCmd += "; `$env:$k='$($backendEnv[$k])'"
}
$backendCmd += "; python -m uvicorn main:app --host 127.0.0.1 --port 8000 2>&1 | Tee-Object -FilePath '$backendLog'"
Start-Process powershell -WindowStyle Minimized -ArgumentList @("-NoExit", "-Command", $backendCmd)
if (-not (Wait-ForHttp "http://127.0.0.1:8000/api/health" 30)) {
    Write-Host "Backend failed. Check: $backendLog" -ForegroundColor Red
    exit 1
}
Write-Host "  OK: Backend at http://localhost:8000" -ForegroundColor Green

# [2] Build admin
Write-Host "[2/5] Admin dashboard..."
if (-not (Build-FlutterWeb $adminDir "Admin dashboard" $adminLog $dartArg)) { exit 1 }

# [3] Build farmer
Write-Host "[3/5] Farmer app..."
if (-not (Build-FlutterWeb $farmerDir "Farmer app" $farmerLog $dartArg)) { exit 1 }

# [4] Serve admin
Write-Host "[4/5] Serving admin on port 8080..."
Start-StaticWeb (Join-Path $adminDir "build\web") 8080 $adminServeLog
$adminOk = Wait-ForFlutterApp 8080 "Admin dashboard" 120

# [5] Serve farmer
Write-Host "[5/5] Serving farmer on port 8081..."
Start-StaticWeb (Join-Path $farmerDir "build\web") 8081 $farmerServeLog
$farmerOk = Wait-ForFlutterApp 8081 "Farmer app" 120

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  AgriSmartAI IS READY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Admin dashboard:  http://localhost:8080" -ForegroundColor Yellow
Write-Host "  Farmer app:       http://localhost:8081" -ForegroundColor Yellow
Write-Host "  Backend API docs: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Admin login:  admin@agrismartai.ph / admin123"
Write-Host "  Farmer login: any email + password (6+ chars)"
Write-Host ""
if (-not $adminOk) { Write-Host "  Admin not ready - check $adminLog" -ForegroundColor Red }
if (-not $farmerOk) { Write-Host "  Farmer not ready - check $farmerLog" -ForegroundColor Red }
Write-Host "  Logs: $logDir"
Write-Host "  Stop: .\scripts\stop-dev.ps1"
Write-Host ""

if ($adminOk) { Start-Process "http://localhost:8080" }
if ($farmerOk) { Start-Sleep -Seconds 1; Start-Process "http://localhost:8081" }
