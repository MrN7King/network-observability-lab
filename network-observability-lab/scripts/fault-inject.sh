#!/usr/bin/env bash
# ============================================================
#  fault-inject.sh
#  Simulates a node failure and automatic recovery.
#  Great for a live demo or a screen-recording for your CV.
#
#  Usage:
#    bash scripts/fault-inject.sh [node] [down-seconds]
#    bash scripts/fault-inject.sh edge-a 30
# ============================================================

NODE=${1:-edge-a}
DOWN=${2:-30}

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   FAULT INJECTION — Network Lab      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Target node : $NODE"
echo "Down period : ${DOWN}s"
echo "Watch Grafana → http://localhost:3000"
echo ""

echo "▼  Stopping $NODE..."
docker stop "$NODE"
echo "   $NODE is DOWN. Prometheus will fire NodeUnreachable alert in ~30s."
echo "   Sleeping ${DOWN}s..."
sleep "$DOWN"

echo "▲  Restarting $NODE..."
docker start "$NODE"
echo "   $NODE is UP. Alert should resolve within 30s."
echo ""
echo "Done. Check the Alerts panel in Grafana."
