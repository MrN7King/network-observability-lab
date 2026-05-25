# ============================================================
#  fault-inject.ps1 — Simulate a single node failure
#  Usage: .\scripts\fault-inject.ps1 -Node edge-a -DownSeconds 30
# ============================================================
param(
    [string]$Node = "edge-a",
    [int]$DownSeconds = 30
)

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  FAULT INJECTION" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Target : $Node" -ForegroundColor Yellow
Write-Host "  Down   : ${DownSeconds}s" -ForegroundColor Yellow
Write-Host "  Watch  : http://localhost:3001" -ForegroundColor Yellow
Write-Host ""

Write-Host "Stopping $Node..." -ForegroundColor Red
docker stop $Node

Write-Host "$Node is DOWN. Alert fires in ~20s in Grafana." -ForegroundColor Red
Write-Host "Waiting ${DownSeconds}s..."
Start-Sleep -Seconds $DownSeconds

Write-Host "Restarting $Node..." -ForegroundColor Green
docker start $Node
Write-Host "$Node is back UP. Alert resolves in ~30s." -ForegroundColor Green
