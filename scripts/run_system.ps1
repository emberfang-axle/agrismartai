# AgriSmartAI — start backend + Flutter mobile (Android) + admin web
# Requires: Flutter SDK in PATH (https://docs.flutter.dev/get-started/install/windows)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Test-Backend {
  try {
    $r = Invoke-RestMethod "http://127.0.0.1:8000/health" -TimeoutSec 2
    return $r.status -eq "healthy"
  } catch { return $false }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  if (Test-Path "C:\Users\PC\flutter\bin\flutter.bat") {
    $env:Path = "C:\Users\PC\flutter\bin;" + $env:Path
  } else {
    Write-Host "Flutter not found. Install from https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Red
    Write-Host "Then reopen PowerShell and run this script again."
    exit 1
  }
}

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
if (Test-Path $sdk) { $env:ANDROID_HOME = $sdk }

if (-not (Test-Backend)) {
  Write-Host "Starting FastAPI backend..."
  Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root\backend'; python -m uvicorn main:app --host 127.0.0.1 --port 8000"
  Start-Sleep -Seconds 4
}

Write-Host "Backend: http://127.0.0.1:8000/health"

Write-Host "Starting Admin Web (Chrome) on http://localhost:5050 ..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
cd '$root\frontend\admin_web_dashboard'
flutter pub get
flutter run -d chrome --web-port=5050
"@

Start-Sleep -Seconds 3

$devices = flutter devices 2>&1 | Out-String
if ($devices -match "android|emulator") {
  Write-Host "Starting Farmer Mobile App on Android..."
  Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
cd '$root\frontend\farmer_mobile_app'
flutter pub get
flutter run
"@
} else {
  Write-Host "No Android device/emulator — starting mobile UI in Chrome on http://localhost:5051 ..."
  Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
cd '$root\frontend\farmer_mobile_app'
flutter pub get
flutter run -d chrome --web-port=5051
"@
}

Write-Host "Done. Admin: http://localhost:5050 | Mobile preview: http://localhost:5051 (if no Android device)"
