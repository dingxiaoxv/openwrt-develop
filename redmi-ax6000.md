# Redmi AX6000：官方源码构建与刷机

## 适用范围

- 设备：Xiaomi Redmi Router AX6000。
- 前提：已使用 Hanwckf U-Boot 的 OpenWrt U-Boot layout。
- 固件：官方 `immortalwrt/immortalwrt`，分支 `openwrt-24.10`。
- 官方 profile：`mediatek/filogic` / `xiaomi_redmi-router-ax6000-ubootmod`。
- 构建配置：[xiaomi-redmi-router-ax6000-ubootmod-openclash.config](defconfig/xiaomi-redmi-router-ax6000-ubootmod-openclash.config)。

## 构建

严格按 [官方源码编译 SOP](official-source-build-sop.md) 执行。在 SOP 的“导入机型配置”步骤使用：

```sh
cp -f /build-config/xiaomi-redmi-router-ax6000-ubootmod-openclash.config .config
make defconfig
```

构建前确认：

```sh
grep -E 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_xiaomi_redmi-router-ax6000-ubootmod|CONFIG_PACKAGE_kmod-mt7915e|CONFIG_PACKAGE_kmod-mt7986-firmware|CONFIG_PACKAGE_mt7986-wo-firmware|CONFIG_PACKAGE_luci-app-openclash' .config
```

构建完成后，manifest 必须包含 `kmod-mt7915e`、`kmod-mt7986-firmware`、`mt7986-wo-firmware` 和 `wpad-openssl`。

## 产物与刷机边界

- 首次从 Hanwckf U-Boot WebUI 刷入：`*xiaomi_redmi-router-ax6000-ubootmod*initramfs-factory.ubi`
- 已运行同一 U-Boot layout 系统后升级：`*xiaomi_redmi-router-ax6000-ubootmod*squashfs-sysupgrade.itb`

U-Boot WebUI 地址、复位进入方式和静态 IP 以已安装的 Hanwckf U-Boot 版本为准。不要将 `sysupgrade.itb` 上传到 U-Boot WebUI，也不要使用 stock layout 或其他机型镜像。

已验证的 Hanwckf 路线通常为：按住 Reset 通电进入 U-Boot WebUI（常见地址 `192.168.31.1`），上传 `initramfs-factory.ubi`，等待首次启动约两分钟，再访问 LuCI `http://192.168.1.1`。地址以实际 U-Boot 页面为准。

## 首次启动验收

确认 LAN、WAN、两个无线 radio 和 LuCI 正常后，再配置 OpenClash。OpenClash 插件预装不等于 Mihomo 内核预装；联网后在“服务 → OpenClash → 版本更新”下载推荐内核。

网络受限时，可在电脑下载 `mihomo-linux-arm64-*.gz`，解压后上传：

```sh
scp mihomo-linux-arm64-* root@192.168.1.1:/etc/openclash/core/clash_meta
ssh root@192.168.1.1 'chmod +x /etc/openclash/core/clash_meta'
```
