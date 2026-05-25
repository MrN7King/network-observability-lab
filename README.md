<div align="center">

# 🌐 Network Observability Lab

### A Production-Style Network Monitoring & NOC Simulation Environment

<p>
  <img src="https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/Alertmanager-FF6B6B?logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/Loki-0FAAFF?logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/Blackbox_Exporter-1E90FF?logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/Node_Exporter-4CAF50?logo=linux&logoColor=white" />
  <img src="https://img.shields.io/badge/nginx-009639?logo=nginx&logoColor=white" />
</p>

<p>
  <img src="https://img.shields.io/badge/Status-Active-success?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Platform-Docker%20Desktop%20(Windows)-blue?style=for-the-badge&logo=docker" />
  <img src="https://img.shields.io/badge/Containers-16-informational?style=for-the-badge" />
</p>

</div>

---

## Overview

A fully containerised network monitoring lab that simulates a small ISP-style topology - core router, edge nodes, and a DMZ - wired into a complete observability stack. Everything is provisioned as code: no manual Grafana clicking, no YAML hunting after startup.

Built as a portfolio project to demonstrate hands-on NOC, networking, and observability skills on a CV.

**What it shows:**
- Multi-node Docker network topology design
- ICMP reachability monitoring + HTTP application-layer probing
- Metrics collection, PromQL querying, and alerting rules
- Alertmanager routing pipeline (Slack-ready)
- Log aggregation with Loki + Promtail
- Live NOC Wallboard dashboard auto-provisioned in Grafana
- Fault injection and chaos testing scripts

---

## Architecture

![Network Architecture](https://raw.githubusercontent.com/MrN7King/network-observability-lab/main/Topology.png)

---

## Stack

| Container | Image | Role |
|-----------|-------|------|
| `core-router` | alpine:3.19 | Hub node - multi-homed across all segments |
| `edge-a` | alpine:3.19 | Branch office simulation |
| `edge-b` | alpine:3.19 | Datacenter edge simulation |
| `dmz-host` | alpine:3.19 | DMZ node (ICMP monitored) |
| `web-dmz` | nginx:alpine | DMZ web server (HTTP + ICMP monitored) |
| `exporter-*` ×4 | prom/node-exporter | CPU, memory, interface metrics per node |
| `blackbox` | prom/blackbox-exporter | ICMP reachability + HTTP health probes |
| `prometheus` | prom/prometheus | Metrics collection and alerting rules |
| `alertmanager` | prom/alertmanager | Alert routing (Slack-ready) |
| `loki` | grafana/loki | Log aggregation backend |
| `promtail` | grafana/promtail | Collects and ships all container logs |
| `grafana` | grafana/grafana | NOC Wallboard + dashboards (auto-provisioned) |

---

## Prerequisites

- **Docker Desktop for Windows** (WSL2 or Hyper-V backend)
- **PowerShell** (built into Windows - no install needed)
- **Git** (optional, for cloning)

> No static IP conflicts. No FRR/OSPF config. Works on Windows Docker Desktop out of the box.

---

## Quick Start

```powershell
# Clone
git clone https://github.com/YOUR_USERNAME/network-observability-lab.git
cd network-observability-lab

# Wipe any old data (important for a clean first run)
docker compose down -v

# Launch all 16 containers
docker compose up -d

# Confirm everything is running
docker compose ps
```

Once all containers show `Up`:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana NOC Wallboard** | http://localhost:3001 | admin / netlab123 |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| DMZ Web Server | http://localhost:8080 | - |
| Loki | http://localhost:3100 | - |

> If panels show "No data", wait 30 seconds for the first Prometheus scrape cycle.

---

## Usage

### Generate traffic

Makes the Grafana dashboard panels show live graphs instead of flatlines:

```powershell
.\scripts\traffic.ps1
```

### Fault injection - single node

Simulate a node failure and watch the alert fire in Grafana:

```powershell
.\scripts\fault-inject.ps1 -Node edge-a -DownSeconds 30
```

Open the NOC Wallboard at http://localhost:3001. The `edge-a` tile turns **red** within ~20 seconds, the alert fires, then everything recovers automatically.

### Chaos mode

Random continuous faults - great for a screen recording or live demo:

```powershell
.\scripts\chaos.ps1            # runs forever
.\scripts\chaos.ps1 -Rounds 5  # 5 random faults then stops
```

---

## Alerting

Alerts defined in `prometheus/alerts.yml`:

| Alert | Condition | Severity |
|-------|-----------|----------|
| `NodeUnreachable` | ICMP probe fails for > 20s | critical |
| `WebServerDown` | HTTP probe fails for > 15s | critical |
| `HighLatency` | ICMP RTT > 100ms for > 30s | warning |
| `ExporterDown` | Node exporter stops responding | warning |
| `HighCPU` | CPU > 85% for > 1 minute | warning |
| `HighRxTraffic` | Interface RX > 50 MB/s | warning |

### Enable Slack notifications

1. Create an Incoming Webhook at https://api.slack.com/messaging/webhooks
2. Open `alertmanager/alertmanager.yml`
3. Uncomment the `slack_configs` block and paste your webhook URL
4. Reload Alertmanager:

```powershell
docker exec alertmanager wget -qO- --post-data='' http://localhost:9093/-/reload
```

---

## Grafana Dashboards

The **NOC Wallboard** loads automatically as the home dashboard and includes:

- Node reachability tiles (green = UP, red = DOWN) for all 5 nodes
- HTTP response time for the DMZ web server
- ICMP round-trip time history for all nodes
- Interface RX / TX traffic per node
- Active alerts panel (live from Prometheus)
- Container log stream (live from Loki)

---

## Project Structure

```
network-observability-lab/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml          # Scrape configs, relabelling, alertmanager integration
│   └── alerts.yml              # Alert rules (ICMP, HTTP, CPU, traffic)
├── alertmanager/
│   └── alertmanager.yml        # Routing tree + Slack config (commented out)
├── blackbox/
│   └── blackbox.yml            # ICMP + HTTP + TCP probe modules
├── loki/
│   └── loki.yml                # Log storage backend config
├── promtail/
│   └── promtail.yml            # Docker log scraping via Docker socket
├── nginx/
│   ├── conf/default.conf       # nginx with /health endpoint + stub_status
│   └── html/index.html         # DMZ landing page
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/        # Auto-configures Prometheus + Loki
│   │   └── dashboards/         # Auto-loads dashboard JSON
│   └── dashboards/
│       └── noc-wallboard.json  # Main NOC dashboard
└── scripts/
    ├── traffic.ps1             # Continuous ICMP + HTTP traffic generator
    ├── fault-inject.ps1        # Single node failure simulation
    └── chaos.ps1               # Random continuous fault injection
```

---

## Stopping the Lab

```powershell
docker compose down      # stop containers, keep Prometheus/Grafana data
docker compose down -v   # stop containers and wipe all stored data
```

---

## Skills Demonstrated

- **Docker networking** - multi-bridge topology, static IP allocation, subnet planning
- **Prometheus** - scrape configuration, metric relabelling, PromQL, alerting rules
- **Alertmanager** - routing trees, group configuration, receiver setup, Slack integration
- **Grafana** - datasource provisioning, dashboard-as-code (JSON model), stat/timeseries/logs panels
- **Blackbox Exporter** - ICMP reachability and HTTP endpoint monitoring
- **Node Exporter** - interface-level telemetry (RX/TX bytes, CPU, memory)
- **Loki + Promtail** - log aggregation pipeline with Docker service discovery
- **nginx** - server configuration, health endpoints, access log formatting
- **Observability methodology** - metrics, logs, alerting as a unified pipeline

---

<div align="center">
<sub>A project made during my free time · BSc (Hons) Computer Networking · CCNA in progress</sub>
</div>
