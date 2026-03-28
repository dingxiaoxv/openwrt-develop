# 2026-03-28 OpenWrt Live Baseline SSH Session

## Request

Connect to the live router over SSH, understand the real baseline before further troubleshooting, and persist the findings in the harness-style local memory framework.

## What Was Checked

- live router access over `ssh root@192.168.2.1`
- platform, release, packages, `network`, `dhcp`, `firewall`, `wireless`
- interface, route, policy-route, and `ifstatus wan`
- OpenClash `uci`, processes, and `nft` rules
- live DNS checks for:
  - `jira.mova-tech.com`
  - `dreametech.feishu.cn`
  - `dreame-eu.oss-eu-central-1.aliyuncs.com`
- live HTTPS checks for the OSS host

## What Changed In Memory

- created `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md`
- updated `.codex/issues/OWRT-0001-dns-rebind-company-domain.md`
- updated `.codex/issues/OWRT-0002-oss-eu-tls-handshake-failure.md`
- updated `.codex/memory/issue-index.md`
- updated `.codex/memory/open-questions.md`
- updated `.codex/memory/question-log.md`

## Notes

The live router baseline differs materially from the earlier imported summary:

- `rebind_protection` is still disabled
- DNS is currently routed through OpenClash
- the OSS hostname now fails on the current default local resolver path

Any next-step OSS conclusion must distinguish:

1. local resolver failure
2. HTTPS failure after DNS bypass
3. whether the HTTPS test path is still going through OpenClash
