# ============================================================
#  traffic.ps1 — Generate continuous ICMP traffic
#  Makes Grafana dashboard panels show real data
#  Usage: .\scripts\traffic.ps1
# ============================================================
Write-Host "Generating traffic... Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Host "Grafana: http://localhost:3001" -ForegroundColor Yellow

$round = 0
while ($true) {
    $round++
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Round $round" -ForegroundColor Gray

    # Ping from each node to core-router
    docker exec edge-a   ping -c 3 172.20.0.10 | Out-Null
    docker exec edge-b   ping -c 3 172.20.0.10 | Out-Null
    docker exec dmz-host ping -c 3 172.20.0.10 | Out-Null

    # Hit the web server
    docker exec edge-a curl -s http://172.20.0.30/health | Out-Null
    docker exec edge-b curl -s http://172.20.0.30/ | Out-Null

    Start-Sleep -Seconds 10
}
