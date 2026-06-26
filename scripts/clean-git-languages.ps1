# AgriSmartAI — Remove auto-generated files from Git tracking (keeps local copies)
# Run from repo root:  .\scripts\clean-git-languages.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host "=== AgriSmartAI: Clean Git language stats ===" -ForegroundColor Cyan
Write-Host "Repo: $root`n"

# 1) Remove entire old/duplicate folders from Git index
$folders = @(
    "standalone_app",
    "node_modules",
    "mobile_app/windows",
    "mobile_app",
    "web_dashboard",
    "demo",
    "dist",
    "evaluation",
    "public",
    "frontend/farmer_mobile_app",
    "frontend/admin_web_dashboard"
)

foreach ($dir in $folders) {
    if (git ls-files -- "$dir" 2>$null) {
        Write-Host "Removing from Git: $dir/" -ForegroundColor Yellow
        git rm -r --cached --ignore-unmatch -- "$dir" 2>$null
    }
}

# 2) Remove any remaining platform / native files still tracked anywhere
$patterns = @(
    '/ios/',
    '/macos/',
    '/linux/',
    '/windows/',
    '/.cxx/',
    '/.dart_tool/',
    '/build/',
    '\.cpp$',
    '\.cc$',
    '\.cmake$',
    'CMakeLists\.txt$',
    '\.swift$',
    '\.tflite$'
)

$all = git ls-files
$toRemove = @()
foreach ($f in $all) {
    foreach ($p in $patterns) {
        if ($f -match $p) {
            $toRemove += $f
            break
        }
    }
}

$toRemove = $toRemove | Sort-Object -Unique
if ($toRemove.Count -gt 0) {
    Write-Host "`nRemoving $($toRemove.Count) auto-generated files from Git index..." -ForegroundColor Yellow
    foreach ($f in $toRemove) {
        git rm --cached --ignore-unmatch -- "$f" 2>$null
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  git add .gitignore .gitattributes"
Write-Host "  git status"
Write-Host "  git commit -m `"chore: stop tracking auto-generated platform and build files`""
Write-Host "  git push origin main"
Write-Host ""
Write-Host "GitHub language stats refresh within a few minutes after push."
