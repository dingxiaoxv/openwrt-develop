# Open Questions

## OWRT-0001 Related

1. 用户先前记忆中的 `rebind_domain` 白名单配置，为什么没有反映在当前 live config 里？
2. `10.187.0.8` 现在是被配置层面移除了，还是只是现实客户端解析不直接走它？
3. 是否已经存在 `/mova-tech.com/10.187.0.7` 或相关 ALB 域名的定向 DNS 转发规则？

## OWRT-0002 Related

1. 是否还有其他海外 `aliyuncs.com` / OSS 区域节点也会被 `RuleSet/Domestic` 误分类，需要一起补规则？
2. 对当前已恢复的这个 host，是否还需要额外加 `nameserver-policy` 作为稳定性优化？

## Baseline Related

1. 路由器硬件型号、SoC、OpenWrt / ImmortalWrt 版本分别是什么？
2. 当前 `wan`、`lan`、无线接口和桥接关系已拿到，但 OpenClash 如何接管 DNS 与流量路径还需要进一步固定成基线描述
3. 当前没有看到有效的 WAN IPv6 默认路由，`odhcpd` 日志多次提示 `No default route present`；是否需要把 IPv6 视为关闭或半配置状态？
4. `openssl` CLI 当前不在 PATH，后续若要继续 TLS 报文级诊断，是否需要补安装相关工具？
