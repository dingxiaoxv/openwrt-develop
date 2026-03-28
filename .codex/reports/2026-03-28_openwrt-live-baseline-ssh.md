# 2026-03-28 OpenWrt Live Baseline SSH 报告

## 1. 摘要

这次不是复述旧对话，而是直接 SSH 到路由器抓 live config 和 live test。

当前最重要的基线结论有四条：

1. 这台路由器不是“朴素 OpenWrt 二级路由”，而是已经启用了 OpenClash，且开启了 DNS hijack、`fake-ip`、`router_self_proxy`
2. 当前 `dnsmasq` live config 不是“rebind protection 已重新开启并仅靠白名单放行”，而是仍然 `rebind_protection='0'`
3. 当前 OSS 主机 `dreame-eu.oss-eu-central-1.aliyuncs.com` 在本地默认解析链上会 `No answer`，但直查公司 DNS 和多个公网 DNS 都能解析到 `47.254.187.24`
4. 即使绕过本地 DNS，强制把域名绑到 `47.254.187.24`，`curl` 仍在 `Client hello` 后报 `SSL_ERROR_SYSCALL`；但由于 `router_self_proxy='1'`，这次 HTTPS 测试路径本身可能仍经过 OpenClash，并不能直接证明“原生 WAN 直连也失败”

## 2. 现象与影响

- 现象：
  - 当前 live router 上 `jira.mova-tech.com` 可以正常解析到 `10.191.x.x`
  - 当前 live router 上 `dreametech.feishu.cn` 可以正常解析
  - 当前 live router 上 `dreame-eu.oss-eu-central-1.aliyuncs.com` 通过默认本地解析链会 `No answer`
  - 绕过本地 DNS 后，访问该 OSS 主机仍在 TLS 握手阶段失败
- 影响：
  - 旧摘要中“DNS 正常、TLS 失败”的判断，现在需要拆成两层：
    - 当前本地 DNS 链本身有问题
    - DNS 绕过后 HTTPS 路径仍有问题
- 期望行为：
  - 路由器默认解析链应能正确返回该 OSS 主机地址
  - 在不受代理干扰的前提下，应能确认 HTTPS 失败点到底在本地代理、公司出口还是远端链路

## 3. 范围

- 输入方式：
  - 通过 `ssh root@192.168.2.1`
- 已检查层：
  - 平台型号与系统版本
  - `network` / `dhcp` / `firewall` / `wireless`
  - `ip addr` / `ip route` / `ip rule` / `ifstatus wan`
  - OpenClash `uci`
  - `nft` 中与 OpenClash 相关的规则
  - 当前 live DNS 查询对照
  - 当前 live `curl` 对照
- 未检查层：
  - OpenClash `moon.yaml` 的细粒度 DNS / rule 配置
  - 不经过 OpenClash 的原生 WAN 直连 HTTPS 对照
  - 下游客户端和手机热点 / VPN 对照
  - 报文级抓包

## 4. 证据

### 平台与版本

- 型号：`CMCC RAX3000M`
- 板级：`cmcc,rax3000m-emmc`
- 系统：`ImmortalWrt 24.10-SNAPSHOT r33409-8f9ee218f9`
- 架构：`aarch64_cortex-a53`
- 内核：`Linux 6.6.95`

### 关键包

- `dnsmasq-full - 2.90-r5`
- `firewall4 - 2024.12.18~18fc0ead-r1`
- `curl - 8.12.1-r1`
- `ip-full - 6.11.0-r1`
- `odhcp6c - 2024.09.25~b6ae9ffa-r1`
- `odhcpd-ipv6only - 2024.05.08~a2988231-r2`
- 没有可直接调用的 `openssl` CLI

### 接口与地址

- `wan` 设备：`eth1`
- `wan` 地址：`10.186.116.99/24`
- 默认网关：`10.186.116.254`
- DHCP 下发 DNS：
  - `10.187.0.7`
  - `10.187.0.8`
- `lan` 网段：`192.168.2.0/24`
- `lan` 地址：`192.168.2.1/24`
- `br-lan` 桥成员：
  - `lan1` up
  - `lan2` down
  - `lan3` down

### 无线状态

- `2.4G` 设备存在，但 `wireless.MT7981_1_1.disabled='1'`
- `2.4G` AP `ImmortalWrt-2.4G` 也是 `disabled='1'`
- `5G` AP 处于启用状态：
  - SSID：`C6H12O6-5G`
  - 加密：`sae-mixed`
- 这意味着当前无线侧主要是 `5G AP` 在工作

### 当前 `dnsmasq` 实际配置

- `dhcp.@dnsmasq[0].rebind_protection='0'`
- `dhcp.@dnsmasq[0].noresolv='1'`
- `dhcp.@dnsmasq[0].server='127.0.0.1#7874'`
- `dhcp.@dnsmasq[0].dns_redirect='1'`
- 当前 `uci show dhcp` 里没有看到 `rebind_domain`

### 当前 OpenClash 实际配置

- `openclash.config.enable='1'`
- `openclash.config.en_mode='fake-ip'`
- `openclash.config.operation_mode='fake-ip'`
- `openclash.config.dns_port='7874'`
- `openclash.config.proxy_port='7892'`
- `openclash.config.tproxy_port='7895'`
- `openclash.config.mixed_port='7893'`
- `openclash.config.http_port='7890'`
- `openclash.config.router_self_proxy='1'`
- `openclash.config.redirect_dns='1'`
- `openclash.config.enable_redirect_dns='1'`
- `openclash.config.config_path='/etc/openclash/config/moon.yaml'`

### 当前 OpenClash DNS 与规则关键点

- `dns.fallback-filter.geoip: true`
- `dns.fallback` 包含：
  - `https://dns.cloudflare.com/dns-query`
  - 多个 `https://*.madns-*.site:2443/dns-query`
- `dns.nameserver` 也混入多个 `madns-*` DoH 服务器
- 首轮 live inspection 时，runtime config 中存在：
  - `DOMAIN-SUFFIX,aliyuncs.com,DIRECT`

### 防火墙与策略路由痕迹

- `firewall.openclash` include 存在，路径是 `/var/etc/openclash.include`
- `ip rule` 中存在：
  - `32765: from all fwmark 0x162 lookup 354`
- `ip route show table 354` 为：
  - `local default dev lo scope host`
- `nft` 里可见：
  - DNS hijack 到本地 `:53`
  - TCP redirect 到 `:7892`
  - UDP TProxy 到 `127.0.0.1:7895`

### live DNS 对照

- `nslookup jira.mova-tech.com 127.0.0.1`
  - 成功
  - 返回私网 `10.191.23.237` / `10.191.16.7`
- `nslookup jira.mova-tech.com 10.187.0.7`
  - 成功
- `nslookup jira.mova-tech.com 10.187.0.8`
  - 超时
- `nslookup dreametech.feishu.cn 127.0.0.1`
  - 成功
  - 返回 `122.193.131.58` 到 `122.193.131.65` 等公网地址
- `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1`
  - `No answer`
- `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 10.187.0.7`
  - 成功，返回 `47.254.187.24`
- `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 223.5.5.5`
  - 成功，返回 `47.254.187.24`
- `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 114.114.114.114`
  - 成功，返回 `47.254.187.24`
- `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 119.29.29.29`
  - 成功，返回 `47.254.187.24`

### live HTTPS 对照

- `curl -vkI --connect-timeout 10 https://dreame-eu.oss-eu-central-1.aliyuncs.com/`
  - 当前直接失败于解析阶段：
  - `Could not resolve host: dreame-eu.oss-eu-central-1.aliyuncs.com`
- `curl -vkI --connect-timeout 10 --resolve dreame-eu.oss-eu-central-1.aliyuncs.com:443:47.254.187.24 https://dreame-eu.oss-eu-central-1.aliyuncs.com/`
  - 能发出 `TLS handshake, Client hello`
  - 之后报：
    - `OpenSSL SSL_connect: SSL_ERROR_SYSCALL`

### OpenClash 日志直接证据

- 首轮 live inspection 时，`/tmp/openclash.log` 多次出现：
  - `dial DIRECT (match DomainSuffix/aliyuncs.com) ... dreame-eu.oss-eu-central-1.aliyuncs.com:443 error: dns resolve failed`
- 其中首个报错包括：
  - 请求 `https://koala.madns-lemon.site:2443/dns-query` 超时
  - 请求 `https://otter.madns-pear.site:2443/dns-query` 被 `read: connection reset by peer`

这说明对该 OSS 主机的 DNS 失败不是上游权威或普通公共 DNS 无答案，而是 OpenClash 当前选中的 fallback DoH 链本身在现网里不可用。

## 5. 时间线

1. 先抓取系统、`uci`、接口、路由和日志，建立 live baseline
2. 从 `dhcp` 和 `firewall` 里发现明显的 OpenClash 痕迹
3. 继续抓 OpenClash `uci`、运行进程和 `nft` 规则，确认 DNS hijack、TCP redirect、UDP TProxy、`router_self_proxy`
4. 对历史提到的域名做 live DNS 对照
5. 发现 `jira` 和 `feishu` 在当前本地解析链里都能工作，但 OSS 主机在本地解析链里 `No answer`
6. 再直查多个上游 DNS，确认不是上游不会解析该 OSS 主机
7. 继续读取 OpenClash YAML 和 runtime log，发现 `aliyuncs.com` 被 runtime rule 强制为 `DIRECT`
8. 同时从 OpenClash log 里确认该域名的 DNS 失败首错指向 `madns-*` fallback DoH 超时 / reset
9. 最后用 `curl --resolve` 绕过本地 DNS，确认 HTTPS 路径仍在 `Client hello` 后失败

## 6. 配置与链路

### 当前客户端默认 DNS 链

1. 下游客户端向路由器 `dnsmasq` 发起 DNS 请求
2. `dnsmasq` 并不直接使用 `wan` DHCP 下发的 `10.187.0.7` / `10.187.0.8`
3. 当前 `dnsmasq` 使用 `noresolv='1'` 和 `server='127.0.0.1#7874'`
4. `127.0.0.1:7874` 由 OpenClash DNS 接管
5. OpenClash 当前处于 `fake-ip` 模式，并启用了 DNS hijack

这意味着当前路由器上的“客户端真实 DNS 路径”是：

`client -> dnsmasq(127.0.0.1:53) -> OpenClash DNS(127.0.0.1:7874)`

而不是：

`client -> dnsmasq -> 10.187.0.7 / 10.187.0.8`

对这个 OSS 主机而言，当前更细的实际行为是：

1. OpenClash 先根据自己的 DNS 逻辑决定解析路径
2. 该主机解析到的 `47.254.187.24` 属于非 CN 地址
3. 在 `fallback-filter.geoip: true` 条件下，它更容易被送入 fallback DoH 链
4. 当前 fallback DoH 链里的 `madns-*` 端点在现网里超时 / reset
5. 结果就是本地默认解析链返回 `No answer`

### 当前路由器自身 HTTPS 路径

1. 路由器自己发起 TCP 请求
2. `firewall` / `nft` 中有 OpenClash output redirect 规则
3. `openclash.config.router_self_proxy='1'`
4. 因此路由器自身 `curl` 也可能被透明导入代理路径

这意味着当前用路由器自身做 HTTPS 测试时，默认不能把结果直接解释成“原生 WAN 直连结果”。

另一个关键点是：

- 首轮 live inspection 时，runtime rule 已明确把 `aliyuncs.com` 送到 `DIRECT`

所以如果你的策略目标是“国内直连、国外代理”，那这条规则仍然过于粗糙，因为它会把欧盟 OSS 这类海外节点也误送到直连路径。

## 7. 判断

- 已确认：
  - 当前 live router 启用了 OpenClash
  - 当前 live `dnsmasq` 不是简单上游 DNS 转发，而是接 OpenClash DNS
  - 当前 live `rebind_protection` 仍是关闭状态
  - 当前 live router 对 OSS 主机的默认本地解析链返回 `No answer`
  - 该 OSS 主机对多个上游 DNS 都可解析到 `47.254.187.24`
  - 首轮 live inspection 中，runtime rule 明确包含 `DOMAIN-SUFFIX,aliyuncs.com,DIRECT`
  - 首轮 live inspection 中，OpenClash log 已直接记录该域名命中 `DIRECT`，并且 DNS 失败首错指向 `madns-*` fallback DoH
  - 绕过 DNS 后，HTTPS 仍在 `Client hello` 后失败
- 高置信推断：
  - 当前 live 环境和最初“纯 OpenWrt + 公司 DNS”的心智模型已经不一致
  - 旧摘要里与 DNS 相关的部分需要按“历史结论”和“当前 live 状态”分开看
  - 当前 OSS 问题至少分成两层：
    - 当前默认解析链错误，且错误已可归因到 OpenClash fallback DoH 路径
    - DNS 绕过后 HTTPS 仍失败，而该路径当前被 runtime rule 强制 `DIRECT`
  - 这条 `aliyuncs.com -> DIRECT` 规则与用户“国内直连、国外代理”的目标不匹配，因为这里命中的是欧盟 OSS
- 尚未排除的备选解释：
  - `aliyuncs.com` 的 DNS 问题只需要调整 OpenClash DNS policy 就能解决
  - `aliyuncs.com` 的 TLS 问题只要取消 `DIRECT` 并改走代理就能解决
  - 公司网络或远端链路也可能同时参与了当前 `DIRECT` 路径下的 TLS 失败

## 8. 未决问题

1. 是否直接为 `+.aliyuncs.com` 固定一个稳定的 `nameserver-policy`？
2. 是否直接覆盖该欧盟 OSS 主机或更窄域后缀的 `DIRECT` 规则，让它走代理？
3. 历史记忆中的 `rebind_domain` 白名单为什么没有出现在当前 live config 里？
4. 下游客户端是否与路由器自身呈现同样的 DNS 与 HTTPS 行为？

## 9. 后续验证建议

1. 在 OpenClash DNS 中为 `+.aliyuncs.com` 增加稳定 DNS policy，例如 `223.5.5.5` 与 `119.29.29.29`
2. 在规则层把 `aliyuncs.com` 或更精确的 OSS 主机从 `DIRECT` 改成代理组
3. 修改后重新验证：
   - `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1`
   - `curl -vkI https://dreame-eu.oss-eu-central-1.aliyuncs.com/`
4. 如果修改后仍失败，再去判断公司出口或远端链路问题

## 10. 追加更新：移除显式 aliyuncs DIRECT 后

用户随后明确说明其真实策略目标是“国内网站直连，国外代理”，并已手动去掉显式 `aliyuncs.com -> DIRECT`。

对最新 live 状态的直接复测结果：

1. 完整签名 URL 的 `Expires=1775535783`，换算为 `2026-04-07 12:23:03 CST`，所以当前不是签名过期
2. `/etc/openclash/moon.yaml` 与 `/etc/openclash/config/moon.yaml` 中都已不再看到 `aliyuncs.com` 或 `oss-eu-central-1` 的显式规则
3. `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1` 仍返回 `No answer`
4. `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 223.5.5.5` 与 `nslookup ... 10.187.0.7` 仍都返回 `47.254.187.24`
5. `/tmp/openclash.log` 最新记录已变为：
   - `dial Domestic (match RuleSet/Domestic) ... dreame-eu.oss-eu-central-1.aliyuncs.com:443 error: dns resolve failed`
6. 最新 DNS 首错指向：
   - `https://whale.madns-peach.site:2443/dns-query`
   - `https://cobra.madns-cherry.site:2443/dns-query`
   - `https://dns.twnic.tw/dns-query`
7. 直接对完整签名 URL 执行 `curl -vkI`，仍失败于解析阶段：
   - `Could not resolve host: dreame-eu.oss-eu-central-1.aliyuncs.com`

这说明最新状态下的问题已经进一步收敛：

- 去掉显式 `aliyuncs.com -> DIRECT` 是必要动作，但不是充分条件
- 该欧盟 OSS 主机目前仍被更宽泛的 `RuleSet/Domestic` 误分类
- 当前最直接的失败点仍是 OpenClash DNS 对这个 host 不给答案
- 下一步最小修复应是精确覆盖，而不是继续粗放修改整段 `aliyuncs.com`

建议的最小改动：

1. 为 `dreame-eu.oss-eu-central-1.aliyuncs.com` 或 `+.oss-eu-central-1.aliyuncs.com` 增加稳定的 `nameserver-policy`
2. 为同一 host 或窄后缀增加高优先级代理规则，覆盖 `RuleSet/Domestic`
3. 修改后立即复测：
   - `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1`
   - `curl -vkI "完整签名 URL"`

## 11. 最终结论：用户确认 host 级 Proxy 规则后恢复

用户随后直接在持久化自定义规则中加入：

- `- DOMAIN,dreame-eu.oss-eu-central-1.aliyuncs.com,Proxy`

并确认问题立即解决。

这使得本次 OSS 问题的主因可以高置信收敛为：

- 该欧盟 OSS host 被更宽的 `RuleSet/Domestic` 误分类
- host 级 `Proxy` 覆盖规则能够直接修复访问失败

因此：

- 先前关于“签名过期”与“上游 DNS 无记录”的解释可以排除
- `nameserver-policy` 仍可作为后续稳定性优化项，但已经不是解释这次恢复所必需的条件
