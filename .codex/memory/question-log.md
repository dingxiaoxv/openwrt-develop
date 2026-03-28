# Question Log

| Date | Request | Related Issue | Output |
| --- | --- | --- | --- |
| `2026-03-28` | review the prior OpenWrt DNS / URL troubleshooting summary, extract only confirmed facts, and normalize the current router baseline | `OWRT-0001 / OWRT-0002` | initially created a scratch baseline note, then normalized the imported summary into `.codex` issue/report memory and removed the transient root notes |
| `2026-03-28` | build a harness-style local memory framework for this OpenWrt router workspace instead of relying on a single baseline markdown file | `n/a` | created `AGENTS.md`, `.codex/context/*`, `.codex/memory/*`, `.codex/issues/*`, `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md`, and `.codex/sessions/2026-03-28_openwrt-memory-framework.md` |
| `2026-03-28` | SSH into the live router, capture the real baseline, and reconcile it with the imported DNS / OSS summary | `OWRT-0001 / OWRT-0002` | created `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md`, updated both issue cards, and normalized the current OpenClash / DNS / policy-routing state |

## Update Rule

Append only when the task is substantial and created reusable analysis value.
