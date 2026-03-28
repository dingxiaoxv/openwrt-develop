# OpenWrt Router Analysis Workspace

This directory is primarily an OpenWrt / ImmortalWrt router troubleshooting workspace, not only a note folder.
Default task types here are:

- router baseline capture
- DNS / DHCP / `dnsmasq` behavior analysis
- URL reachability isolation by layer: DNS, TCP, TLS, HTTP
- firewall / route / policy correlation
- local memory accumulation

## First Read

For router baseline, DNS anomaly, URL access failure, firewall path, or cross-layer network analysis, read the minimum needed from:

1. `.codex/context/project-overview.md`
2. `.codex/context/code-log-map.md`
3. `.codex/context/analysis-playbook.md`
4. `.codex/memory/issue-index.md`
5. `.codex/memory/question-log.md`
6. `.codex/memory/open-questions.md`

## Default Permission Boundary

For analysis tasks, assume broad workspace access is allowed for:

- reading locally saved notes, router config exports, command outputs, and captures
- updating `.codex/` memory and reports

But treat router configs and raw captures as evidence.
Do not rewrite user-provided evidence unless explicitly asked.
Do not change the actual router configuration unless the user explicitly requests it and the target router is clear.

## Default Analysis Order

1. Confirm the exact symptom: domain / URL / host / client / time window / error text.
2. Separate the failure stage: DNS, TCP, TLS, HTTP, or application permission.
3. Capture or refresh the router baseline before making deep root-cause claims.
4. Inspect the relevant configuration and status sources.
5. Compare across network paths when the failure may depend on corporate egress.
6. Reuse an existing issue card if the pattern matches history.
7. Persist substantial findings locally.

## Config And Evidence Rules

- Treat `uci show network`, `uci show dhcp`, `uci show firewall`, and `uci show wireless` as primary configuration evidence.
- Treat `ubus call system board`, `/etc/openwrt_release`, `uname -a`, `opkg list-installed`, `ip addr`, `ip route`, `ip rule`, and `ifstatus` as baseline evidence.
- For DNS questions, always distinguish:
  - direct query to a specific upstream DNS
  - query through router-side `dnsmasq`
  - query from a downstream client
- For URL reachability, isolate in this order:
  - name resolution
  - TCP connect
  - TLS handshake
  - HTTP response
- If DNS returns RFC1918 space for a public-looking domain, check `dnsmasq` `rebind_protection` before blaming the upstream DNS.
- If DNS and TCP succeed but TLS fails, bias first toward egress path, proxy / inspection, MTU, or middlebox effects rather than a DNS cause.

## Persistence Rules

Persist only substantial analysis work. A task is substantial when it includes at least one of:

- real config inspection or baseline normalization
- real command output or an evidence chain
- a reusable conclusion, confidence level, or next-step validation advice

When the work is substantial:

- update `.codex/memory/question-log.md`
- update or create an issue card under `.codex/issues/`
- create or update a case report under `.codex/reports/`
- create a short session note under `.codex/sessions/`

## Report Style

Default to a forensic-style troubleshooting report:

- summary
- symptom and impact
- scope
- evidence
- timeline
- config / path trace
- assessment and confidence
- open questions
- next validation steps

Write reports primarily in Chinese.
Keep paths, command names, config keys, raw log strings, protocols, and exact error text in English when needed.

## Memory Discipline

- Prefer updating an existing issue card instead of duplicating a known pattern.
- Never turn an inference into a confirmed fact without command output or direct user confirmation.
- Never erase historical findings; add dated updates when the understanding changes.
- Keep the authoritative memory under `.codex/`; root-level ad-hoc notes are source material, not the long-term index.
