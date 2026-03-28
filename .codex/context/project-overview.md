# Project Overview

## Workspace Role

This workspace stores local notes and future evidence for troubleshooting a self-built OpenWrt / ImmortalWrt secondary router behind a corporate network.

Its default workflow is:

1. import prior conversation or raw evidence
2. normalize the router baseline
3. isolate the failing layer: DNS, TCP, TLS, HTTP, or policy
4. compare with known issues
5. update report and local memory

## Top-Level Layout

| Path | Purpose |
| --- | --- |
| `.codex/` | local Codex memory, context, issues, reports, sessions, and templates |

## Layer Model

### 1. Router Platform Baseline

- evidence: `ubus call system board`, `/etc/openwrt_release`, `uname -a`, `opkg list-installed`
- focus: hardware, firmware version, key packages, and feature boundary

### 2. L3 / Interface / Upstream Path

- evidence: `uci show network`, `ifstatus wan`, `ip addr`, `ip route`, `ip rule`
- focus: WAN / LAN topology, DHCP, default route, upstream DNS, and policy routing

### 3. DNS / DHCP / Resolver Layer

- evidence: `uci show dhcp`, `logread`, `nslookup`, `dig`, `cat /tmp/resolv.conf*`
- focus: `dnsmasq`, `rebind_protection`, domain-specific forwarders, and active upstream resolvers

### 4. Firewall / NAT / Policy Layer

- evidence: `uci show firewall`, `fw4 print`, `nft list ruleset`
- focus: NAT, filtering, MSS / MTU workarounds, and forward-path restrictions

### 5. URL Reachability / TLS Layer

- evidence: `curl -vkI`, `openssl s_client`, `tcpdump`
- focus: DNS vs TCP vs TLS vs HTTP separation, SNI / TLS handshake behavior, and egress-path anomalies

### 6. Client Comparison Layer

- evidence: the same test across router shell, downstream client, phone hotspot, and VPN
- focus: isolate whether the failure is router-local, client-local, or upstream-network-path dependent

## Existing Historical Material

Earlier imported troubleshooting notes have already been normalized into `.codex/` reports and issues.
No standalone root Markdown source note is retained as part of the authoritative workspace memory.
No raw router config export, packet capture, or command-output archive has been stored in this workspace yet.

## Important Boundary

Some conclusions may depend on systems outside this workspace, especially:

- company upstream DNS servers `10.187.0.7` and `10.187.0.8`
- company egress, proxy, firewall, or TLS inspection devices
- OSS region reachability outside the router

If a conclusion depends on those external components, record it as an external dependency rather than claiming it was verified locally.
