# Fixes incomplete Flutter install by downloading the Dart SDK (~204 MB)
# Run in PowerShell:  .\scripts\fix_flutter.ps1

$ErrorActionPreference = "Stop"
$flutterRoot = "C:\Users\PC\flutter"
if (-not (Test-Path "$flutterRoot\bin\flutter.bat")) {
  Write-Host "Flutter not found at $flutterRoot" -ForegroundColor Red
  Write-Host "Install from https://docs.flutter.dev/get-started/install/windows first."
  exit 1
}

$engine = Get-Content "$flutterRoot\bin\internal\engine.version" -Raw
$engine = $engine.Trim()
$url = "https://storage.googleapis.com/flutter_infra_release/flutter/$engine/dart-sdk-windows-x64.zip"
$zip = "$env:TEMP\dart-sdk.zip"
$dest = "$flutterRoot\bin\cache\dart-sdk"

Write-Host "Engine: $engine"
Write-Host "Downloading Dart SDK..."
curl.exe -L --retry 5 -o $zip $url
if ($LASTEXITCODE -ne 0) { throw "Dart SDK download failed" }

$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Downloaded ${mb} MB"

if ($mb -lt 190) { throw "Download too small ($mb MB). Check disk space and retry." }

New-Item -ItemType Directory -Force -Path "$flutterRoot\bin\cache" | Out-Null
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }

Write-Host "Extracting..."
Expand-Archive -Path $zip -DestinationPath "$flutterRoot\bin\cache" -Force
$inner = Get-ChildItem "$flutterRoot\bin\cache" -Directory | Where-Object { $_.Name -like "dart-sdk*" } | Select-Object -First 1
if ($inner -and $inner.FullName -ne $dest) {
  Move-Item $inner.FullName $dest -Force
}
Remove-Item $zip -Force -ErrorAction SilentlyContinue

$env:Path = "$flutterRoot\bin;" + $env:Path
flutter --version
flutter doctor
Write-Host ""
Write-Host "Flutter fixed. Now run: .\scripts\run_system.ps1" -ForegroundColor Green
