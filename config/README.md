# GL-MT3600BE Mihomo 配置模板

`mihomo.yaml` 是面向 OpenClash 的 Mihomo 配置模板。将 `proxy-providers.subscription.url` 替换为支持 Mihomo 的订阅 URL；保留双引号，包含引号或反斜杠时需按 YAML 转义。订阅地址通常是访问凭据，请勿提交 Git 或公开分享。可以将填写后的配置保存为本地的 `mt3600be-cord.yaml`，该文件已被 Git 忽略。

在 OpenClash「配置管理」上传配置，切换前保留可用配置，再启动并检查日志。OpenClash 可能覆写 DNS、端口及运行模式。订阅需返回 Mihomo 可解析的节点格式，首次下载时路由器需要能访问订阅服务。`private`、`openai`、`anthropic`、`cn` 使用 GeoSite 数据，`GEOIP,CN` 需要相应数据库。

## 策略组

- `Proxy` 可选择 `Smart`、`Auto` 或订阅中的单个节点，未匹配流量默认使用此组。
- `AI` 和 `Streaming` 可选择 `Proxy`、地区自动分组或 `DIRECT`。Streaming 规则覆盖部分 Netflix、HBO、Disney+ 和 YouTube 域名，可能需要按实际访问日志补充。
- `Auto` 使用 `url-test` 按健康检查延迟选择节点；香港、台湾、日本、韩国、新加坡、美国及 Other 分组采用同样方式。`tolerance: 50` 的单位为毫秒。
- 地区分组根据节点名称筛选，需要按订阅的实际命名调整；Other 包含未匹配上述地区的节点，名称不能保证实际出口位置。
- `Smart` 已启用，必须使用支持 `type: smart` 的内核；`uselightgbm: false`、`collectdata: false` 关闭对应可选功能。

延迟不保证所有网站、流媒体服务和地区的使用效果最优。地区匹配、流媒体规则、Smart 内核兼容性和内存占用需要在目标路由器上结合实际订阅验证。模板没有大型广告规则；企业内网和特殊站点可能需要额外规则。可选 OSS 例外规则在模板中注释，按需启用。
