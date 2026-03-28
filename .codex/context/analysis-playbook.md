# Analysis Playbook

## Standard Workflow

1. Define scope
   - failing domain or URL
   - affected client or clients
   - whether the router shell itself reproduces
   - expected behavior
   - exact failure stage: DNS, TCP, TLS, HTTP, or application permission
   - current network path: company LAN, hotspot, VPN, or other
2. Refresh the router baseline first
   - collect platform, package, interface, route, DNS, and firewall state
   - record whether each fact comes from direct command output or a user statement
3. Build evidence
   - inspect `uci show dhcp` and direct DNS queries for DNS cases
   - inspect `uci show network`, `ifstatus wan`, `ip route`, and `ip rule` for path cases
   - inspect `uci show firewall` when transport or MTU / policy interference is plausible
   - use `curl -vkI` and `openssl s_client` for TLS-stage isolation
   - compare router shell, downstream client, hotspot, and VPN when the failure may be upstream-path dependent
   - inspect prior local notes and reports before restating an old conclusion
4. Assess cause
   - confirmed facts
   - high-confidence inferences
   - unknowns still blocking certainty
5. Persist the result

## Config Snapshot Rule

When the baseline is missing, do not skip it.
The minimum useful snapshot is:

- `ubus call system board`
- `cat /etc/openwrt_release`
- `uname -a`
- `opkg list-installed | grep -E 'dnsmasq|firewall|odhcp|ip-full|curl|openssl'`
- `uci show network`
- `uci show dhcp`
- `uci show firewall`
- `uci show wireless`
- `ip addr`
- `ip route`
- `ip rule`
- `ip -6 route`
- `ifstatus wan`
- `logread | tail -n 100`

If the user only provides partial output, record the missing items explicitly and lower confidence where needed.

## DNS Evidence Rule

For DNS analysis:

- query the exact failing name against each specific upstream DNS
- query the same name through the router-default resolver
- check `rebind_protection`, `rebind_domain`, `server`, `noresolv`, and active resolv files
- record whether the returned address is RFC1918, `198.18.0.0/15`, or public Internet space
- if the upstream DNS set includes a bad server, record whether the router still actively uses it or only advertises it
- if disabling `rebind_protection` changes the result, treat router-side `dnsmasq` as the primary suspect

## TLS And URL Evidence Rule

For HTTPS or signed-URL analysis:

- resolve the host to an exact IP
- confirm TCP reachability to the target port
- test TLS with correct `-servername` / SNI
- confirm signed URL expiry when relevant
- compare the same host and URL across company network, hotspot, and VPN when possible
- if TCP succeeds but TLS ends with EOF / reset, bias first toward middlebox, proxy, inspection, MTU, or cross-border path effects rather than DNS
- if the router shell succeeds but a downstream client fails, split the problem again into client DNS, client proxy, client firewall, and local path differences

## Source Mutation Rule

For analysis-only tasks:

- `.codex/` and local notes may be updated
- exported router configs and captures are evidence and should stay immutable
- actual router `uci` changes require an explicit user request and a clearly identified target router

## Persistence Artifacts

For substantial analysis, keep these artifacts in sync:

1. `question-log`
   - what was asked
   - related issue id
   - output artifact
2. `issue card`
   - reusable problem memory
3. `report`
   - case-specific or task-specific deep-dive
4. `session note`
   - compact operational history

## Confidence Labels

Use one of:

- `confirmed`
- `high confidence`
- `medium confidence`
- `low confidence`

Do not upgrade an inference into a confirmed fact without direct command output or direct user confirmation.

## Language Rule

- Report narrative should default to Chinese.
- Keep technical terms in English when that is the clearer or more standard form.
- Do not translate raw log strings, command names, config keys, protocol names, paths, or exact error messages just for style consistency.

## Naming Rules

| Artifact | Naming Pattern |
| --- | --- |
| issue | `OWRT-0001-short-name.md` |
| report without a concrete log bundle | `YYYY-MM-DD_short-topic.md` |
| session | `YYYY-MM-DD_short-topic.md` |

## Default Report Shape

1. 摘要
2. 现象与影响
3. 范围
4. 证据
5. 时间线
6. 配置与链路
7. 判断
8. 未决问题
9. 后续验证建议

Within the sections above, keep prose in Chinese and mix in English only for exact technical terms or quoted artifacts.

## Update Rule

- If the issue already exists, update the existing issue card.
- If the work is only a minor clarification without new evidence, do not create a new report.
- If the question introduces a new recurring pattern, create a new issue card from the template.
