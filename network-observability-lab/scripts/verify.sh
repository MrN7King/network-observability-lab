#!/usr/bin/env bash
# ============================================================
#  verify.sh
#  Runs a suite of checks to prove the lab is working.
#  Output is clean and interview-friendly.
# ============================================================

PASS=0
FAIL=0

check() {
  local label="$1"
  local cmd="$2"
  local expected="$3"

  result=$(eval "$cmd" 2>&1 || true)
  if echo "$result" | grep -q "$expected"; then
    echo "  ✅  $label"
    PASS=$((PASS+1))
  else
    echo "  ❌  $label"
    echo "      Expected: $expected"
    echo "      Got     : $result"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "══════════════════════════════════════════"
echo "  Network Observability Lab — Verify"
echo "══════════════════════════════════════════"
echo ""

echo "[ Docker Containers ]"
for c in core-router edge-a edge-b dmz-host blackbox prometheus grafana \
          exporter-core exporter-edge-a exporter-edge-b exporter-dmz; do
  check "Container $c is running" \
    "docker inspect -f '{{.State.Status}}' $c" "running"
done

echo ""
echo "[ Network Connectivity ]"
check "edge-a can ping core-router (172.21.0.1)" \
  "docker exec edge-a ping -c 2 -W 1 172.21.0.1" "2 packets transmitted"
check "edge-b can ping core-router (172.22.0.1)" \
  "docker exec edge-b ping -c 2 -W 1 172.22.0.1" "2 packets transmitted"
check "dmz-host can ping core-router (172.23.0.1)" \
  "docker exec dmz-host ping -c 2 -W 1 172.23.0.1" "2 packets transmitted"

echo ""
echo "[ Exporter Health ]"
check "exporter-core responds on :9100" \
  "docker exec exporter-core wget -qO- http://localhost:9100/metrics | head -5" "node_"
check "exporter-edge-a responds on :9100" \
  "docker exec exporter-edge-a wget -qO- http://localhost:9100/metrics | head -5" "node_"

echo ""
echo "[ Blackbox Probes ]"
check "Blackbox can probe core-router via ICMP" \
  "curl -s 'http://localhost:9115/probe?target=172.20.0.10&module=icmp' | grep probe_success" \
  "probe_success 1"
check "Blackbox can probe edge-a via ICMP" \
  "curl -s 'http://localhost:9115/probe?target=172.21.0.10&module=icmp' | grep probe_success" \
  "probe_success 1"

echo ""
echo "[ Prometheus ]"
check "Prometheus is up" \
  "curl -s http://localhost:9090/-/healthy" "Prometheus"
check "Prometheus has ICMP probe metrics" \
  "curl -s 'http://localhost:9090/api/v1/query?query=probe_success' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d[\"data\"][\"result\"]))'" \
  "4"

echo ""
echo "[ Grafana ]"
check "Grafana is up" \
  "curl -s http://localhost:3000/api/health" "ok"
check "Grafana datasource is configured" \
  "curl -s -u admin:netlab123 http://localhost:3000/api/datasources | python3 -c 'import sys,json; ds=json.load(sys.stdin); print(ds[0][\"type\"])'" \
  "prometheus"

echo ""
echo "══════════════════════════════════════════"
printf "  Results: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "══════════════════════════════════════════"
echo ""
