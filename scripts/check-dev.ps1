# AgriSmartAI :: Check if dev servers are running

$services = @(
    @{ Port = 8000; Name = "Backend API";      Url = "http://localhost:8000/docs" },
    @{ Port = 8080; Name = "Admin dashboard"; Url = "http://localhost:8080" },
    @{ Port = 8081; Name = "Farmer app";      Url = "http://localhost:8081" }
)

Write-Host ""
Write-Host "AgriSmartAI - service status" -ForegroundColor Cyan
Write-Host ""

$anyUp = $false
foreach ($s in $services) {
    $listening = $null -ne (netstat -ano | Select-String ":$($s.Port)\s" | Select-String "LISTENING")
    $ready = $false
    if ($listening -and $s.Port -in 8080, 8081) {
        try {
            $js = Invoke-WebRequest -Uri "http://127.0.0.1:$($s.Port)/main.dart.js" -UseBasicParsing -TimeoutSec 3
            $ready = ($js.StatusCode -eq 200 -and $js.Content.Length -gt 1000)
        } catch {}
    } elseif ($listening -and $s.Port -eq 8000) {
        try {
            $h = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -UseBasicParsing -TimeoutSec 3
            $ready = ($h.StatusCode -eq 200)
        } catch {}
    }
    if ($listening -and $ready) {
        Write-Host "  [READY]   $($s.Name) -> $($s.Url)" -ForegroundColor Green
        $anyUp = $true
    } elseif ($listening) {
        Write-Host "  [STARTING] $($s.Name) -> $($s.Url)" -ForegroundColor Yellow
        $anyUp = $true
    } else {
        Write-Host "  [DOWN]    $($s.Name) -> $($s.Url)" -ForegroundColor Red
    }
}

Write-Host ""
if (-not $anyUp) {
    Write-Host "Nothing is running. Start with:" -ForegroundColor Yellow
    Write-Host "  .\scripts\start-dev.ps1"
    Write-Host ""
    Write-Host "First start builds release web apps (3-5 min). Wait for 'AgriSmartAI IS READY'."
} else {
    Write-Host "Admin:  admin@agrismartai.ph / admin123"
    Write-Host "Farmer: any email + password (6+ chars)"
}
Write-Host ""
