# OWRT-0004 OpenClash 更新删除 `luci-compat` 导致 LuCI 不可用

## 摘要

NX30 Pro 的自编译 ImmortalWrt 固件首次启动、联网及 OpenClash 初始运行正常；从 OpenClash 页面更新插件到 `v0.47.156` 后，LuCI 请求失败。直接错误为 `module 'luci.cbi.datatypes' not found`。这是插件更新路径删除 `luci-compat` 后的依赖不一致，而非已确认的系统网络栈死机。

## 状态

- State: mitigated
- Confidence: high confidence
- Last normalized: 2026-08-31

## 证据

- 用户截图的更新日志显示 `OpenClash - v0.47.156` 已下载并通过更新前测试，随后开始安装。
- 同次截图中 LuCI 报错来自 `/usr/lib/lua/luci/controller/openclash.lua:126`，缺失模块为 `luci.cbi.datatypes`。
- OpenClash 上游 Issue #4882 记录了同一错误、ImmortalWrt 24.10 环境和更新时 `luci-compat was autoinstalled and is now orphaned, removing` 的日志；临时恢复方法为安装 `luci-compat`。另有上游 Discussion #4701 将相同错误归因为“安装依赖，被卸载了”。

## 判断

- confirmed: LuCI 不能构建菜单，因为 OpenClash controller `require` 的 `luci.cbi.datatypes` 不存在。
- high confidence: 该缺失由插件内更新移除 auto-installed 的 `luci-compat` 引起；截图版本、路径和错误文本与上游已知回归一致。
- not confirmed: “整个系统卡死”。当前证据仅证明 LuCI 控制面失败，不能证明内核、交换转发或 WAN 已崩溃。应通过 SSH / ping / `uptime` 单独验证。

## 缓解与预防

- 已在 NX30 Pro、CMCC RAX3000M eMMC 和 Redmi AX6000 三份 OpenClash defconfig 增加 `CONFIG_PACKAGE_luci-compat=y`，使它成为固件显式包，不依赖 OpenClash 的自动依赖状态。
- 已在机型指南加入同 feed 的 `opkg install luci-compat` 恢复流程；不得混装跨 OpenWrt/ImmortalWrt 版本的 LuCI `.ipk`。

## 参考

- https://github.com/vernesong/OpenClash/issues/4882
- https://github.com/vernesong/OpenClash/discussions/4701
