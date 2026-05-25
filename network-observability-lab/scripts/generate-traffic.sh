#!/usr/bin/env bash
# ============================================================
#  generate-traffic.sh
#  Pumps ICMP and TCP traffic between containers so that
#  Grafana dashboards show real data rather than flatlines.
#
#  Usage:
#    bash scripts/generate-traffic.sh          # runs forever
#    bash scripts/generate-traffic.sh 60       # runs for 60s
# ============================================================

set -euo pipefail

DURATION=${1:-0}   # 0 = run forever
START=$(date +%s)

declare -a NODES=("core-router" "edge-a" "edge-b" "dmz-host")
declare -A PING_TARGETS=(
  ["core-router"]="172.21.0.10 172.22.0.10 172.23.0.10"
  ["edge-a"]="172.20.0.10 172.22.0.10"
  ["edge-b"]="172.20.0.10 172.21.0.10"
  ["dmz-host"]="172.20.0.10"
)

echo "▶  Traffic generator started. Press Ctrl-C to stop."
echo "   Nodes: ${NODES[*]}"
echo ""

round=0
while true; do
  round=$((round + 1))
  echo "[round $round] $(date '+%H:%M:%S')"

  for node in "${NODES[@]}"; do
    targets="${PING_TARGETS[$node]}"
    for target in $targets; do
      docker exec "$node" ping -c 3 -W 1 "$target" > /dev/null 2>&1 &
    done
  done

  # Generate some small file transfer traffic (dd over /dev/null)
  docker exec edge-a   sh -c "dd if=/dev/urandom bs=64k count=8 2>/dev/null | cat > /dev/null" &
  docker exec edge-b   sh -c "dd if=/dev/urandom bs=64k count=8 2>/dev/null | cat > /dev/null" &
  docker exec dmz-host sh -c "dd if=/dev/urandom bs=64k count=4 2>/dev/null | cat > /dev/null" &

  wait

  if [ "$DURATION" -gt 0 ]; then
    elapsed=$(( $(date +%s) - START ))
    if [ "$elapsed" -ge "$DURATION" ]; then
      echo "✅  Duration ${DURATION}s reached. Stopping."
      break
    fi
  fi

  sleep 10
done
