# NX30 Pro OpenClash 插件更新后 LuCI 失败分析

## 摘要

高置信度判断为：OpenClash 插件内升级删除了 `luci-compat`，使 OpenClash controller 找不到 `luci.cbi.datatypes`，从而造成 LuCI 全局请求分发失败。已为后续 NX30 Pro 固件显式预装 `luci-compat`，并提供 SSH 恢复步骤。

## 现象与影响

- 初始编译固件可正常运行和上网。
- OpenClash 更新至 `v0.47.156` 后，LuCI 页面显示 `Runtime error`。
- 错误位置为 `/usr/lib/lua/luci/controller/openclash.lua:126`，错误是 `module 'luci.cbi.datatypes' not found`。
- LuCI 菜单树构建受影响，Web 管理页面不可用；尚未获得 SSH、`uptime` 或转发测试，不能据此确认系统/网络实际死机。

## 时间线

| 时间 | 证据 |
| --- | --- |
| `2026-08-31 09:40:20` | OpenClash 开始下载 `v0.47.156`。 |
| `09:40:26` | `openclash.ipk` 下载至 100%，开始更新前测试。 |
| `09:40:42` | 日志显示测试通过并开始安装。 |
| 安装后 | LuCI 载入 OpenClash controller 时缺少 `luci.cbi.datatypes`。 |

## 配置与链路

该问题不在 DNS、TCP、TLS 或 HTTP 流量路径：浏览器已经成功到达路由器的 LuCI HTTP 服务，失败发生于路由器本地 Lua 模块加载。`luci.cbi.datatypes` 由兼容层提供；其缺失导致 `ucodebridge.lua` 转发 controller 时异常。

## 判断与置信度

- `confirmed`：LuCI 本地 Lua 依赖缺失。
- `high confidence`：OpenClash 更新器清理 auto-installed `luci-compat`，与 OpenClash 仍需该模块的依赖声明不一致。上游有同版本族、同环境、同错误文本和明确 removal 日志的报告。
- `not checked`：设备 SSH 是否在线、内存/OOM、`opkg` 事务完整日志、LAN/WAN 转发。

## 恢复与验证

SSH 执行：

```sh
opkg update
opkg install luci-compat
opkg flag hold luci-compat
/etc/init.d/uhttpd restart
reboot
```

必须使用当前 ImmortalWrt 24.10 的匹配 feed 或同一次编译输出的 `.ipk`。恢复后验证：

```sh
opkg status luci-compat
test -r /usr/lib/lua/luci/cbi/datatypes.lua && echo OK
logread | tail -n 100
uptime
```

后续自编译固件已在 NX30 Pro、CMCC RAX3000M eMMC 和 Redmi AX6000 的 OpenClash defconfig 中固定 `CONFIG_PACKAGE_luci-compat=y`；重新构建前用 `.config` 检查该项，并在 image manifest 中确认 `luci-compat`。

## 参考

- https://github.com/vernesong/OpenClash/issues/4882
- https://github.com/vernesong/OpenClash/discussions/4701
