# AgriSmartAI :: Stop all local dev servers (backend + Flutter web)
# Fixes "Failed to bind web development server" / errno 10048 (port already in use)

$ports = @(8000, 8080, 8081)
$killed = @()

foreach ($port in $ports) {
    $lines = netstat -ano | Select-String ":$port\s" | Select-String "LISTENING"
    foreach ($line in $lines) {
        $processId = ($line -split '\s+')[-1]
        if ($processId -match '^\d+$' -and $processId -ne '0') {
            try {
                $proc = Get-Process -Id $processId -ErrorAction Stop
                Stop-Process -Id $processId -Force -ErrorAction Stop
                $killed += "Port $port -> $($proc.ProcessName) (PID $processId)"
            } catch {
                Write-Host "Could not stop PID $processId on port $port : $_"
            }
        }
    }
}

if ($killed.Count -eq 0) {
    Write-Host "No dev servers were listening on ports 8000, 8080, or 8081."
} else {
    Write-Host "Stopped:"
    $killed | ForEach-Object { Write-Host "  $_" }
}
Write-Host ""
Write-Host "Ports are free. You can now run: .\scripts\start-dev.ps1"
