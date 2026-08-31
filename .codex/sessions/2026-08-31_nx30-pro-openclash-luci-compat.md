# 2026-08-31 NX30 Pro OpenClash 更新 / LuCI 依赖

- 用户截图显示 OpenClash `v0.47.156` 更新后 LuCI 报 `module 'luci.cbi.datatypes' not found`。
- 与上游 ImmortalWrt 24.10 已知问题一致：更新器删除 orphaned 的 auto-installed `luci-compat`，但 OpenClash 仍依赖该 Lua 模块。
- 在 NX30 Pro、CMCC RAX3000M eMMC、Redmi AX6000 三份 OpenClash defconfig 显式加入 `CONFIG_PACKAGE_luci-compat=y`；机型指南增加只使用匹配 feed 的 SSH 恢复方法。
- 尚无 SSH / 转发证据，不能把 LuCI 崩溃写成已确认的全系统卡死。
