# 2026-03-28 OpenWrt Memory Framework Session

## Request

Review the imported OpenWrt troubleshooting context, normalize the current router baseline, and replace the single-file note approach with a harness-style local memory framework.

## What Was Checked

- imported troubleshooting summary later normalized into `.codex/`
- user clarifications:
  - active `rebind_domain` whitelist is in use
  - `10.187.0.8` is currently not used
  - OSS URL problem remains unresolved and is still the main next issue
- existing Codex memory framework examples under:
  - `/home/dyx/workspace/system/Wi-Fi/.codex`
  - `/home/dyx/workspace/system/bluenet/.codex`

## What Changed In Memory

- created root `AGENTS.md`
- created `.codex/context/*`
- created `.codex/templates/*`
- created `.codex/memory/*`
- created `.codex/issues/OWRT-0001-dns-rebind-company-domain.md`
- created `.codex/issues/OWRT-0002-oss-eu-tls-handshake-failure.md`
- created `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md`
- created this session note

## Notes

The imported root Markdown notes were transitional source material and have since been removed.
`.codex/` is the authoritative local memory framework for this workspace.

The current active unresolved issue is `OWRT-0002`.
The router hardware / version / interface baseline is still incomplete and should be captured before deeper OSS / TLS diagnosis.
