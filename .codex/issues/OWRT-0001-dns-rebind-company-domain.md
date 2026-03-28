# OWRT-0001 DNS Rebind Blocking Company Domain

## Summary

在当前 OpenWrt / ImmortalWrt 二级路由环境里，`jira.mova-tech.com` 的问题已经定位清楚：
公司 DNS `10.187.0.7` 能返回结果，但结果链最终落到 `10.191.x.x` 私网地址。
路由器侧 `dnsmasq` 的 `rebind protection` 把这类结果当作 DNS rebind 风险拦截，因此导致子网客户端表现为“无法解析 / 无法访问”。

此前认为当前修正方式是“重新开启保护并通过 `rebind_domain` 放行相关域名”，但 live SSH baseline 证实当前运行中的实际状态仍是全局关闭 `rebind_protection`，并通过 OpenClash 接管 DNS 路径。

## Status

- State: mitigated
- Confidence: high confidence
- Last normalized: 2026-03-28

## Symptoms

- 子网客户端下 `jira.mova-tech.com` 无法正常访问
- 路由器直查 `10.187.0.7` 可以解析该域名
- `10.187.0.8` 查询超时
- 关闭 `dnsmasq` `rebind protection` 后该域名恢复正常

## Known Evidence

- source notes:
  - `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md`
  - `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md`
- relevant config areas:
  - `/etc/config/dhcp`
  - `dnsmasq` `rebind_protection`
  - `dnsmasq` `rebind_domain`
  - `dnsmasq` `server`
- user-confirmed active commands:
  - `uci add_list dhcp.@dnsmasq[0].rebind_domain='mova-tech.com'`
  - `uci add_list dhcp.@dnsmasq[0].rebind_domain='cn-shanghai.alb.aliyuncsslb.com'`

## Current Assessment

- confirmed facts:
  - `nslookup jira.mova-tech.com 10.187.0.7` 成功
  - 返回链最终是私网地址 `10.191.x.x`
  - `nslookup jira.mova-tech.com 10.187.0.8` 超时
  - 在 LuCI 中关闭 `rebind protection` 后问题消失
  - 当前 live config 显示 `dhcp.@dnsmasq[0].rebind_protection='0'`
  - 当前 live config 中没有看到 `rebind_domain` 条目
  - 当前 live config 显示 `dhcp.@dnsmasq[0].noresolv='1'`
  - 当前 live config 显示 `dhcp.@dnsmasq[0].server='127.0.0.1#7874'`
  - 当前 live test 中 `nslookup jira.mova-tech.com 127.0.0.1` 可以直接返回 `10.191.23.237` 和 `10.191.16.7`
- high-confidence inferences:
  - 首要阻断点在路由器侧 `dnsmasq`，不是公司 DNS 完全不会解析该域名
  - 当前 live router 上该域名之所以可用，更直接的原因是全局关闭了 `rebind protection`，而不是仅靠白名单精确放行
  - 如果路由器仍保留混合上游 DNS，继续固定或定向到 `10.187.0.7` 会比依赖异常的 `10.187.0.8` 更稳妥
- remaining unknowns:
  - 用户先前描述的“已改回白名单方案”与当前 live config 不一致，尚不清楚中间发生了什么配置变更
  - 还没有确认是否已经配置 `server=/mova-tech.com/10.187.0.7` 之类的定向转发
  - `10.187.0.8` 仍在 `wan` DHCP 下发结果里出现，但当前客户端默认解析并不直接走它

## Open Questions

1. 当前 `dnsmasq` 的 `rebind_protection`、`rebind_domain`、`server`、`noresolv` 实际配置是什么？
2. `10.187.0.8` 现在是如何被停用的？
3. 是否已经为 `mova-tech.com` 或相关 ALB 域名配置定向转发到 `10.187.0.7`？

## Update 2026-03-28

Imported from the prior troubleshooting summary and normalized into local issue memory.

User confirmed that the active fix is no longer "global disable rebind protection", but the following whitelist entries:

- `uci add_list dhcp.@dnsmasq[0].rebind_domain='mova-tech.com'`
- `uci add_list dhcp.@dnsmasq[0].rebind_domain='cn-shanghai.alb.aliyuncsslb.com'`

## Update 2026-03-28 Live SSH Baseline

Direct SSH inspection of the router showed that the current running configuration is not the previously described whitelist-only state.

What was directly confirmed:

1. `dhcp.@dnsmasq[0].rebind_protection='0'`
2. no visible `rebind_domain` entries in current `uci show dhcp`
3. `dhcp.@dnsmasq[0].noresolv='1'`
4. `dhcp.@dnsmasq[0].server='127.0.0.1#7874'`
5. `nslookup jira.mova-tech.com 127.0.0.1` currently returns the private ALB addresses successfully

So the current live router is using a broader workaround than the earlier memory suggested: global rebind protection is disabled, and client DNS is funneled through the local OpenClash DNS path.
