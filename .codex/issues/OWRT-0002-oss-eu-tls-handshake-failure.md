# OWRT-0002 OSS EU TLS Handshake Failure

## Summary

当前已收敛并解决的主问题是：
访问阿里云 OSS 签名 URL 时，历史排查显示目标主机 `dreame-eu.oss-eu-central-1.aliyuncs.com` 可以正常解析，目标 `443` 端口的 TCP 连接也能建立，但 TLS 握手阶段失败，报过 `SSL_ERROR_SYSCALL` 和 `unexpected eof while reading`。

live SSH baseline 进一步确认：当前路由器的默认本地解析链已经变成 `dnsmasq -> OpenClash DNS`，而该链路对这个 OSS 主机返回 `No answer`。用户移除显式 `aliyuncs.com -> DIRECT` 之后，问题仍未消失；最新 runtime log 显示该主机现在命中 `RuleSet/Domestic`，且 DNS 失败首错仍指向 OpenClash 选中的 DoH 端点。

现有证据最终收敛到“规则分类错误导致路径错误”这一主因：该欧盟 OSS host 被更宽的 `RuleSet/Domestic` 误分类；在加入 host 级 `Proxy` 覆盖规则后，访问恢复。

## Status

- State: resolved
- Confidence: high confidence
- Last normalized: 2026-03-28

## Symptoms

- 阿里云 OSS 签名 URL 无法正常访问
- `curl` / `openssl s_client` 在 TLS 握手阶段失败
- 典型报错：
  - `SSL_ERROR_SYSCALL`
  - `unexpected eof while reading`
- 同时：
  - 历史排查里 DNS 可以解析
  - 当前 live router 的默认本地解析链对该主机返回 `No answer`
  - 绕过本地 DNS 后，HTTPS 仍在 TLS 阶段失败

## Known Evidence

- source notes:
  - `.codex/reports/2026-03-28_openwrt-dns-and-oss-summary.md`
  - `.codex/reports/2026-03-28_openwrt-live-baseline-ssh.md`
- target host:
  - `dreame-eu.oss-eu-central-1.aliyuncs.com`
- verified facts already captured:
  - DNS 解析到 `47.254.187.24`
  - TCP 到 `47.254.187.24:443` 连接成功
  - 新一轮复测的签名参数 `Expires=1775535783`
  - 换算北京时间为 `2026-04-07 12:23:03 CST`
- comparison gaps:
  - 还没有完成手机热点或 VPN 对照验证
  - 还没有拿到明确绕过 OpenClash 的原生 WAN 直连对照

## Current Assessment

- confirmed facts:
  - 历史排查里，该 OSS 主机可以解析到 `47.254.187.24`
  - 历史排查里，目标 `443` 端口的 TCP 连接成功
  - 历史排查里，TLS 握手失败早于任何 HTTP 对象下载
  - 签名在先前排查时间内未过期
  - 当前 live SSH baseline 中，`nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1` 返回 `No answer`
  - 当前 live SSH baseline 中，直查 `10.187.0.7`、`223.5.5.5`、`114.114.114.114`、`119.29.29.29` 都能解析到 `47.254.187.24`
  - 当前 live router 上 `dnsmasq` 使用 `noresolv='1'` 且上游指向 `127.0.0.1#7874`
  - 当前 live router 上 OpenClash 已启用，`fake-ip` 模式开启，`dns_port='7874'`，`router_self_proxy='1'`
  - 当前 OpenClash DNS 配置里：
    - `fallback-filter.geoip: true`
    - `fallback` 包含 `dns.cloudflare.com` 和多个 `madns-*` DoH 服务器
    - `nameserver` 也混入了多个 `madns-*` DoH 服务器
  - 历史 live runtime config 中曾存在 `DOMAIN-SUFFIX,aliyuncs.com,DIRECT`
  - 用户已移除显式 `aliyuncs.com -> DIRECT` 后，`/etc/openclash/moon.yaml` 与 `/etc/openclash/config/moon.yaml` 里已不再看到 `aliyuncs.com` 或 `oss-eu-central-1`
  - 移除显式规则后，`/tmp/openclash.log` 明确出现：
    - `dial Domestic (match RuleSet/Domestic) ... dreame-eu.oss-eu-central-1.aliyuncs.com:443 error: dns resolve failed`
    - 首个错误多次指向 `https://whale.madns-peach.site:2443/dns-query`、`https://cobra.madns-cherry.site:2443/dns-query` 或 `https://dns.twnic.tw/dns-query`
  - 当前 live SSH baseline 中，对完整签名 URL 直接执行 `curl -vkI` 仍失败于解析阶段：`Could not resolve host: dreame-eu.oss-eu-central-1.aliyuncs.com`
- 用户已明确说明：该问题目前仍未解决，后续要继续追踪
- high-confidence inferences:
  - 当前 live router 至少存在一个新的本地问题：`dnsmasq -> OpenClash DNS (127.0.0.1:7874)` 这条默认解析链对该 OSS 主机不给答案，而上游 DNS 本身是有答案的
  - 这不是“上游 DNS 根本不会解析该 OSS 主机”的问题
  - 这也不是“签名 URL 早已过期”的问题
  - `dreame-eu.oss-eu-central-1.aliyuncs.com` 解析到 `47.254.187.24` 这类非 CN 地址后，很可能被 OpenClash `fallback-filter.geoip: true` 送去 `fallback` DoH 解析链
  - 当前真正失败的不是“任何 DNS 都查不到”，而是 OpenClash 选中的 fallback DoH 服务器在现网里超时或被 reset
  - 去掉显式 `aliyuncs.com -> DIRECT` 后，问题并没有消失，说明显式规则只是问题的一部分，不是全部
  - 当前这条 OSS 访问路径与“国内直连、国外代理”的目标仍不匹配，因为这个欧盟 OSS 主机仍被 `RuleSet/Domestic` 误分类，同时 DNS 解析继续走到不稳定的 OpenClash DoH 链
- remaining unknowns:
  - OpenClash 为什么对 `aliyuncs.com` 选择了当前这组易超时的 fallback DoH，而不是直接采用可用的 `223.5.5.5` / `dns.alidns.com`
  - 在把该主机从 `RuleSet/Domestic` 精确覆盖出去之前，是否还会继续落到错误的路径
  - 故障是否在下游客户端与路由器 shell 上完全一致
  - 公司网络、手机热点、VPN 三种网络下是否稳定呈现不同结果
  - 是否存在 MTU / MSS、透明代理或其他中间件差异

## Open Questions

1. 是否还有其他海外 `aliyuncs.com` / OSS 区域节点存在相同的 `RuleSet/Domestic` 误分类，需要一起补规则？
2. 当前是否还需要为这个 host 单独增加 `nameserver-policy`，还是保留仅规则覆盖的最小修复即可？

## Update 2026-03-28

Imported from the prior troubleshooting summary and kept open as the active unresolved issue.

User confirmed:

- the OSS URL problem is still unresolved
- this is the next line of investigation after the router baseline is normalized

## Update 2026-03-28 Live SSH Baseline

Direct SSH inspection materially changed the understanding of the current live environment.

What was directly confirmed:

1. the router is not using upstream WAN DNS directly for clients; `dnsmasq` currently uses `127.0.0.1#7874`
2. OpenClash is enabled in `fake-ip` mode with DNS hijack and `router_self_proxy='1'`
3. the OSS hostname fails on the current default local resolver path: `nslookup ... 127.0.0.1` returns `No answer`
4. direct queries to `10.187.0.7`, `223.5.5.5`, `114.114.114.114`, and `119.29.29.29` all return `47.254.187.24`
5. bypassing local DNS with `curl --resolve ...:47.254.187.24` still ends in `SSL_ERROR_SYSCALL` after `Client hello`

This means the active unresolved issue is now clearly layered:

- current local resolver path is wrong for the OSS hostname
- even after bypassing resolver failure, the HTTPS path still breaks
- but the HTTPS test path may still be contaminated by OpenClash transparent proxying, so external-network conclusions remain unproven

## Update 2026-03-28 OpenClash Rule And DNS Diagnosis

Read-only inspection of the active OpenClash YAML and runtime log narrowed the failure further.

What was directly confirmed:

1. `/etc/openclash/moon.yaml` contains `DOMAIN-SUFFIX,aliyuncs.com,DIRECT`
2. the active DNS section enables `fallback-filter.geoip: true`
3. the active `fallback` and `nameserver` lists include multiple third-party `madns-*` DoH endpoints
4. `/tmp/openclash.log` repeatedly shows:
   - `dial DIRECT (match DomainSuffix/aliyuncs.com) ... dreame-eu.oss-eu-central-1.aliyuncs.com:443 error: dns resolve failed`
   - the first DNS error points to `koala.madns-lemon.site` / `otter.madns-pear.site` timing out or being reset

Current best assessment:

- DNS failure root cause is no longer vague; it is strongly tied to OpenClash's fallback DNS path for this domain
- traffic policy root cause is also clear: `aliyuncs.com` is currently forced to `DIRECT`, not proxy
- therefore the current behavior conflicts with the user's actual target of "domestic direct, foreign proxy", because this hostname points to an EU OSS endpoint under an Alibaba domain

## Update 2026-03-28 After Removing Explicit aliyuncs DIRECT

User then removed the explicit `aliyuncs.com -> DIRECT` rule and the problem still reproduced.

What was directly reconfirmed:

1. the signed URL is still valid; `Expires=1775535783` converts to `2026-04-07 12:23:03 CST`
2. the active OpenClash source config and runtime config no longer contain explicit `aliyuncs.com` or `oss-eu-central-1` rules
3. `nslookup dreame-eu.oss-eu-central-1.aliyuncs.com 127.0.0.1` still returns `No answer`
4. direct queries to `223.5.5.5` and `10.187.0.7` still return `47.254.187.24`
5. `/tmp/openclash.log` now shows `dial Domestic (match RuleSet/Domestic) ... error: dns resolve failed`
6. the first DNS errors now point to `whale.madns-peach.site`, `cobra.madns-cherry.site`, and `dns.twnic.tw`
7. `curl -vkI` against the full signed URL still fails at DNS resolution on the router itself

Current best assessment after this change:

- removing the explicit `DIRECT` rule was necessary, but it was not sufficient
- the hostname is still being misclassified by a broader `RuleSet/Domestic`
- the immediate blocker is still OpenClash DNS resolution for this host, not URL expiry
- the next minimal fix should be host-specific:
  - add a stable `nameserver-policy` for `dreame-eu.oss-eu-central-1.aliyuncs.com` or `+.oss-eu-central-1.aliyuncs.com`
  - add a higher-priority proxy rule for the same host or narrow suffix so it overrides `RuleSet/Domestic`

## Update 2026-03-28 Persistent Override Entry Points

Direct inspection confirmed that `moon.yaml` is generated output and should not be treated as the durable edit target.

What was directly confirmed:

1. persistent custom rule file:
   - `/etc/openclash/custom/openclash_custom_rules.list`
2. current durable user rules already present there:
   - `- DOMAIN-SUFFIX,kutting.tech,DIRECT`
   - `- DOMAIN-SUFFIX,mova-tech.com,DIRECT`
3. in generated runtime config, those custom rules land before the built-in Domestic ruleset:
   - `- DOMAIN-SUFFIX,kutting.tech,DIRECT`
   - `- DOMAIN-SUFFIX,mova-tech.com,DIRECT`
   - later `- RULE-SET, Domestic, Domestic`
4. persistent custom DNS policy file:
   - `/etc/openclash/custom/openclash_custom_domain_dns_policy.list`
5. persistent overwrite script also exists:
   - `/etc/openclash/custom/openclash_custom_overwrite.sh`
   - but it is still template/demo content and is not the current source of the user's domain overrides

Current best edit targets:

- host-specific traffic override should be added to `/etc/openclash/custom/openclash_custom_rules.list`
- host-specific DNS policy should be added to `/etc/openclash/custom/openclash_custom_domain_dns_policy.list`

## Update 2026-03-28 User Confirmed Resolution

User then added the following persistent custom rule and reported that the problem was resolved immediately:

- `- DOMAIN,dreame-eu.oss-eu-central-1.aliyuncs.com,Proxy`

Current best assessment after this confirmation:

- the decisive fix was the host-specific proxy override
- this strongly confirms that the main root cause was rule misclassification under `RuleSet/Domestic`
- a custom `nameserver-policy` may still be optional optimization, but it is no longer required to explain or reproduce the recovery
