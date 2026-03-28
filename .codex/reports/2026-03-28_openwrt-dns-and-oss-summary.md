# 2026-03-28 OpenWrt DNS 与 OSS 链路排查报告

## 1. 摘要

当前已确认两条不同的问题线：

- `jira.mova-tech.com` 的问题已经定位为路由器侧 `dnsmasq` `rebind protection` 拦截，现已按 `rebind_domain` 白名单方式修正，结论为 `high confidence`
- `dreame-eu.oss-eu-central-1.aliyuncs.com` 对应的 OSS 签名 URL 问题不在 DNS，也不在签名过期；当前现象是 DNS 与 TCP 正常、TLS 握手失败，结论暂为 `medium confidence`

此外，`dreametech.feishu.cn` 已被明确排除出 DNS rebind 方向，它更像 HTTP、权限或页面有效性问题，不是当前主追踪对象。

## 2. 现象与影响

- 现象：
  - 通过该 OpenWrt / ImmortalWrt 二级路由访问公司内网时，部分域名或链接不可用
  - `jira.mova-tech.com` 曾经在子网下无法正常访问
  - 阿里云 OSS 签名 URL 目前仍无法完成访问
- 影响：
  - 公司内部资源访问不稳定
  - 当前最关键的是 OSS 下载链接仍不可用
- 期望行为：
  - 路由器应能稳定解析公司需要的域名
  - 若 DNS 与 TCP 均正常，HTTPS/TLS 访问也应可继续完成

## 3. 范围

- 输入材料：
  - 早期导入的 DNS / OSS troubleshooting 摘要，现已规范化进 `.codex`
  - 用户补充：
    - 已改回 `rebind_domain` 白名单方案
    - `10.187.0.8` 当前没有使用
    - OSS 链接问题仍未解决，继续追踪
- 时间窗口：
  - 当前为对先前对话结论的归档与规范化，不是新的抓包或命令采集轮次
- 已检查层：
  - 上游 DNS 可用性
  - `dnsmasq` rebind 逻辑
  - 域名解析结果类别
  - TCP `443` reachability
  - TLS 握手是否完成
  - OSS 签名是否过期
- 未检查层：
  - 当前完整路由器基线
  - 当前完整 `uci show dhcp` / `network` / `firewall` / `wireless`
  - 公司网络与手机热点 / VPN 的对照
  - TLS 更细粒度报文级断点

## 4. 证据

- 路由器 `wan` DHCP 已知拿到：
  - IP：`10.186.116.99/24`
  - 网关：`10.186.116.254`
  - DNS：`10.187.0.7`、`10.187.0.8`
- `10.187.0.7` 能解析至少部分公司域名，`10.187.0.8` 查询超时
- `nslookup jira.mova-tech.com 10.187.0.7` 成功，最终结果落到私网 `10.191.x.x`
- 关闭 `dnsmasq` `rebind protection` 后，`jira.mova-tech.com` 恢复正常
- 用户确认当前生效的修正是：
  - `uci add_list dhcp.@dnsmasq[0].rebind_domain='mova-tech.com'`
  - `uci add_list dhcp.@dnsmasq[0].rebind_domain='cn-shanghai.alb.aliyuncsslb.com'`
- `dreametech.feishu.cn` 通过公司 DNS 与默认 DNS 都可以解析，返回公网地址
- 实际失败链接已修正为阿里云 OSS 签名 URL，主机名是 `dreame-eu.oss-eu-central-1.aliyuncs.com`
- 该主机：
  - 能解析到 `47.254.187.24`
  - TCP `47.254.187.24:443` 连接成功
  - TLS 握手失败，报过 `SSL_ERROR_SYSCALL` 和 `unexpected eof while reading`
- 签名参数：
  - `Expires=1775441742`
  - 换算为北京时间 `2026-04-06 10:15:42 CST`
  - 在先前排查窗口内未过期

## 5. 时间线

1. 原始症状是“部分域名或链接无法访问 / 疑似无法解析”
2. 对 `jira.mova-tech.com` 直接查询公司 DNS，发现 `10.187.0.7` 可解析，`10.187.0.8` 超时
3. 进一步发现 `jira.mova-tech.com` 最终返回 `10.191.x.x` 私网地址
4. 关闭 OpenWrt `dnsmasq` 的 `rebind protection` 后，`jira.mova-tech.com` 恢复正常，说明阻断点在路由器本地 resolver
5. 后续修正为 `rebind_domain` 白名单方式，而不是长期全局关闭保护
6. `dreametech.feishu.cn` 被验证为 DNS 正常，因此从 DNS / rebind 方向排除
7. 实际失败链接被修正为阿里云 OSS 签名 URL
8. 对 OSS 主机验证后确认：DNS 正常、TCP 正常、TLS 握手失败、签名未过期
9. 用户确认当前仍未解决 OSS/TLS 问题，并要求先把路由器记忆框架与基线建好

## 6. 配置与链路

### `jira.mova-tech.com` 链路

1. 下游客户端向路由器侧 `dnsmasq` 发起解析
2. `dnsmasq` 向公司 DNS 查询，`10.187.0.7` 可以返回结果
3. 返回链最终落到 RFC1918 私网 `10.191.x.x`
4. `dnsmasq` `rebind protection` 将其拦截
5. 加入 `rebind_domain` 白名单后，该域名不再被本地 resolver 拦截

### OSS URL 链路

1. 客户端解析 `dreame-eu.oss-eu-central-1.aliyuncs.com`
2. DNS 能得到 `47.254.187.24`
3. TCP 到 `47.254.187.24:443` 可达
4. TLS 握手阶段终止，尚未进入稳定的 HTTP 对象读取阶段
5. 这意味着当前阻断点位于 DNS 之后、HTTP 之前

## 7. 判断

- 已确认：
  - `jira.mova-tech.com` 的根因是 `dnsmasq` `rebind protection`
  - 当前已按白名单方式修正，而非全局关闭保护
  - `dreametech.feishu.cn` 不是 DNS rebind 问题
  - OSS 主机的 DNS 正常
  - OSS 主机的 TCP `443` 正常
  - OSS 签名在先前排查窗口内未过期
- 高置信推断：
  - `jira.mova-tech.com` 的问题不是公司 DNS 完全不会解析，而是路由器本地 `dnsmasq` 的策略阻断
  - OSS 问题更像公司出口、代理、TLS inspection、跨境链路或其他中间网络因素
- 尚未排除的备选解释：
  - 路由器本地是否存在 MTU / MSS、策略路由、透明代理、IPv6 或 firewall 影响 TLS 路径
  - `10.187.0.8` 是否仍在某些路径上被间接使用

## 8. 未决问题

1. 当前完整的路由器基线仍未采集，包括硬件、版本、接口、路由、DNS 与 firewall 状态
2. 当前完整的 `uci show dhcp` 尚未拿到，因此还不能精确确认 `dnsmasq` 的最终生效配置
3. 还没有在手机热点和 VPN 下对同一 OSS URL 做严格对照
4. 还没有通过 `openssl s_client -msg -state` 或 `tcpdump` 确认 TLS 到底在哪个报文阶段被中断

## 9. 后续验证建议

1. 先补全路由器基线：
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
2. 对 OSS 主机分别在路由器 shell、下游客户端、手机热点、VPN 下执行同一组验证命令
3. 使用以下方式继续细化 TLS 断点：
   - `curl -vkI 'https://...'`
   - `openssl s_client -connect dreame-eu.oss-eu-central-1.aliyuncs.com:443 -servername dreame-eu.oss-eu-central-1.aliyuncs.com -msg -state`
4. 如果公司网络下持续失败、而手机热点或 VPN 下成功，则优先把问题归入外部网络路径而不是 OpenWrt DNS 本地配置
