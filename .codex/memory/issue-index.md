# Issue Index

| Issue | State | Confidence | Summary | Main References |
| --- | --- | --- | --- | --- |
| `OWRT-0001` | mitigated | high confidence | `dnsmasq` `rebind protection` 拦截公司域名私网结果的模式已经确认；但当前 live config 显示实际 workaround 仍是全局关闭 `rebind_protection`，不是仅白名单放行 | `.codex/issues/OWRT-0001-dns-rebind-company-domain.md`, `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md`, `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md` |
| `OWRT-0002` | resolved | high confidence | 最终修复是为 `dreame-eu.oss-eu-central-1.aliyuncs.com` 增加 host 级 `Proxy` 规则；这确认了主因是该欧盟 OSS host 被 `RuleSet/Domestic` 误分类，而不是签名过期或上游 DNS 无记录 | `.codex/issues/OWRT-0002-oss-eu-tls-handshake-failure.md`, `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md`, `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md` |
| `OWRT-0003` | resolved | confirmed | 已统一为官方源码；Hanwckf U-Boot 路线已覆盖 NX30 Pro、CMCC RAX3000M eMMC 与 Redmi AX6000。AX6000 必须配合官方 stock layout，不能使用 `ubootmod` | `.codex/issues/OWRT-0003-h3c-nx30-pro-build-support.md`, `.codex/reports/2026-08-28_h3c-nx30-pro-build-support.md`, `.codex/reports/2026-08-29_hanwckf-rax3000m-ax6000-uboot.md` |

## Notes

- 如果后续只是为同一 DNS rebind 模式补充证据，继续更新 `OWRT-0001`，不要新开 issue。
- 如果后续只是为同一 OSS TLS 握手失败模式补充证据，继续更新 `OWRT-0002`，不要新开 issue。
