# ============================================================
#  chaos.ps1 — Chaos mode for Network Observability Lab v2
#  Randomly stops and restarts containers so your monitoring
#  catches failures automatically. Great for screen recording.
#
#  Usage:
#    .\scripts\chaos.ps1              # runs forever
#    .\scripts\chaos.ps1 -Rounds 5   # runs 5 rounds then stops
# ============================================================
param([int]$Rounds = 0)

$nodes = @("edge-a", "edge-b", "dmz-host", "web-dmz")
$round = 0

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CHAOS MODE — Network Observability Lab  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Grafana: http://localhost:3001" -ForegroundColor Yellow
Write-Host "  Watch the dashboard while chaos runs." -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $round++
    $target = $nodes | Get-Random
    $downTime = Get-Random -Minimum 20 -Maximum 45

    Write-Host "[Round $round] $(Get-Date -Format 'HH:mm:ss') — Stopping $target for ${downTime}s..." -ForegroundColor Red
    docker stop $target | Out-Null

    Start-Sleep -Seconds $downTime

    Write-Host "[Round $round] $(Get-Date -Format 'HH:mm:ss') — Restarting $target" -ForegroundColor Green
    docker start $target | Out-Null

    # Cooldown between rounds
    $cooldown = Get-Random -Minimum 15 -Maximum 30
    Write-Host "[Round $round] Cooldown ${cooldown}s before next fault..." -ForegroundColor Gray
    Start-Sleep -Seconds $cooldown

    if ($Rounds -gt 0 -and $round -ge $Rounds) {
        Write-Host ""
        Write-Host "Completed $Rounds rounds. All nodes restored." -ForegroundColor Green
        break
    }
}
