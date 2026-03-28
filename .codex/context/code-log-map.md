# Config And Evidence Map

## Default Source Mapping

| Layer | Evidence | When To Enter |
| --- | --- | --- |
| Platform baseline | `ubus call system board`, `cat /etc/openwrt_release`, `uname -a`, `opkg list-installed` | enter before deep troubleshooting, or when feature support and version compatibility matter |
| Network topology and routes | `uci show network`, `ifstatus wan`, `ip addr`, `ip route`, `ip rule`, `ip -6 route` | enter when WAN / LAN path, DHCP, gateway, or policy routing may affect behavior |
| DNS and DHCP | `uci show dhcp`, `logread`, `cat /tmp/resolv.conf*`, `nslookup`, `dig` | default first stop for domain resolution, rebind, or stale upstream DNS questions |
| Firewall and NAT | `uci show firewall`, `fw4 print`, `nft list ruleset` | enter when traffic leaves the router but downstream behavior still differs, or when MTU / MSS / policy interference is suspected |
| Wireless and client access | `uci show wireless`, `iwinfo`, `ubus call network.wireless status` | enter when the symptom may start before DNS, or when client-specific WLAN behavior matters |
| URL / TLS path | `curl -vkI`, `openssl s_client`, `tcpdump` | enter when DNS success does not produce usable HTTPS access |

## Key Entry Points

| File Or Command | Main Responsibility | Typical Symptoms |
| --- | --- | --- |
| `/etc/config/network` and `uci show network` | interface roles, DHCP client, gateway, static routes, policy hooks | wrong upstream path, no default route, wrong DNS advertisement, asymmetric routing |
| `/etc/config/dhcp` and `uci show dhcp` | `dnsmasq`, DHCP options, upstream DNS policy, rebind handling | domain fails only behind router, mixed upstream DNS behavior, RFC1918 result blocked |
| `/etc/config/firewall` and `uci show firewall` | forward policy, NAT, MSS / MTU workarounds, zone handling | HTTPS path differs by client, NAT edge cases, unexpected drops |
| `/etc/config/wireless` and `uci show wireless` | AP / STA setup, radio and client access policy | WLAN join failure, client-specific access problems |
| `curl -vkI` | DNS to TCP to TLS to HTTP stage split | URL opens nowhere, TLS EOF, signed URL troubleshooting |
| `openssl s_client -connect ... -servername ...` | SNI-aware TLS handshake inspection | EOF during TLS, certificate path uncertainty, protocol negotiation problems |

## Cross-Layer Rules

### Start With Failure-Stage Separation

Unless the evidence already proves otherwise, split every URL access problem into:

1. DNS resolution
2. TCP connect
3. TLS handshake
4. HTTP response or redirect
5. application-layer authorization or expiry

Do not collapse these into one generic "network failure".

### Move Into `dnsmasq` Early For Router-Only DNS Symptoms

When direct queries to an upstream DNS succeed but downstream clients behind the router fail, move into:

- `/etc/config/dhcp`
- `dnsmasq` options such as `rebind_protection`, `rebind_domain`, `server`, and `noresolv`
- router-local resolver behavior

### Move Into Firewall And Path Policy Only After The Layer Isolated

If DNS and TCP are good but TLS or HTTP still fails, move into:

- `/etc/config/firewall`
- MSS / MTU handling
- proxy, transparent proxy, or policy-routing side effects
- external network-path comparison

### Go Sideways To External Network Comparison When Needed

When router-local config alone cannot explain the symptom, compare the same test across:

- router shell
- downstream LAN client
- phone hotspot
- VPN

This is often the fastest way to separate router-local policy from company-egress policy.

## Reporting Requirement

Every substantial report should explicitly state:

- which layers were checked
- which layers were not checked
- whether the conclusion is router-local, client-local, or an external dependency
