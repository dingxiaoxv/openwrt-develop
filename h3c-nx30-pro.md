# H3C Magic NX30 Pro：官方源码构建与刷机

## 适用范围

- 设备：H3C Magic NX30 Pro。
- 已完成引导前提：Hanwckf `mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin` 已写入 FIP。
- 固件：官方 `immortalwrt/immortalwrt`，分支 `openwrt-24.10`。
- 官方 profile：`mediatek/filogic` / `h3c_magic-nx30-pro-nmbm`。
- 构建配置：[h3c-magic-nx30-pro-nmbm-openclash.config](defconfig/h3c-magic-nx30-pro-nmbm-openclash.config)。

该引导链只能使用 NMBM layout。不要选择不带 `-nmbm` 的 OpenWrt U-Boot layout profile，也不要刷 `.itb`。

## 原厂免拆机与 U-Boot 路线

本节保留已验证的设备专属操作；它与统一编译 SOP 独立。

### 原厂 V100R010：启用临时 Telnet

仅适用于原厂 `V100R010`。在原厂 WebUI `http://192.168.124.1` 的“更多 → 设备管理 → 配置备份”中，先导出现有配置，再恢复 [NX30Pro免拆机Telnet.zip](NX30Pro/NX30Pro免拆机Telnet.zip) 解压出的 `decoded-NX30Pro-finished.cfg`。不要再次解码该文件。

配置包 SHA-256：

```text
adce52dd5aaae1f874d09886453ef836366c01b2148018425ee3a550fd5bcb63
```

恢复并重启后，原厂 Web/Wi-Fi 密码为 `77777777`，LAN 会出现无密码 root Telnet：

```sh
telnet 192.168.124.1 7788
```

该 Telnet 未认证，只能在可信 LAN 内短时使用。

### 联网、校时、SSH 与备份

先确认原厂系统已联网、时间不是 1970：

```sh
date
```

再在 Telnet shell 执行：

```sh
curl -o /tmp/dropbear.ipk https://downloads.openwrt.org/releases/packages-19.07/aarch64_cortex-a53/base/dropbear_2019.78-2_aarch64_cortex-a53.ipk
opkg install /tmp/dropbear.ipk
/etc/init.d/dropbear enable
/etc/init.d/dropbear start
```

SSH 凭据为 `root` / `admin`。写 FIP 前必须导出原厂分区；先导出大 `ubi`，再导出 `BL2`、`Factory`、`FIP`：

```sh
cat /proc/mtd
dd if=/dev/mtd5 of=/tmp/mtd5_ubi
# 导出 mtd5 后，再执行：
dd if=/dev/mtd1 of=/tmp/mtd1_BL2
dd if=/dev/mtd3 of=/tmp/mtd3_Factory
dd if=/dev/mtd4 of=/tmp/mtd4_FIP
```

尤其不能丢失 `mtd3_Factory`。

### 写入 Hanwckf FIP

上传 `mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin` 到 `/tmp`，两端 `sha256sum` 一致后执行：

```sh
mtd write /tmp/mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin FIP
sync
reboot
```

本步骤只写 `FIP`，不写 `BL2`、`Factory` 或 `ubi`。随后按住 Reset 通电至少 15 秒，电脑设 `192.168.1.100/24`，访问 `http://192.168.1.1` 确认 Hanwckf U-Boot WebUI。

## 构建

严格按 [官方源码编译 SOP](official-source-build-sop.md) 执行。在 SOP 的“导入机型配置”步骤使用：

```sh
cp -f /build-config/h3c-magic-nx30-pro-nmbm-openclash.config .config
make defconfig
```

构建前确认：

```sh
grep -E 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_h3c_magic-nx30-pro-nmbm|CONFIG_PACKAGE_kmod-mt7915e|CONFIG_PACKAGE_kmod-mt7981-firmware|CONFIG_PACKAGE_mt7981-wo-firmware|CONFIG_PACKAGE_luci-compat|CONFIG_PACKAGE_luci-app-openclash' .config
```

构建完成后，manifest 必须包含 `kmod-mt7915e`、`kmod-mt7981-firmware`、`mt7981-wo-firmware`、`wpad-openssl`。否则固件可能能启动但没有无线，禁止升级。

## 产物与刷机边界

- Hanwckf U-Boot WebUI 首刷：`*h3c_magic-nx30-pro-nmbm*squashfs-factory.bin`
- 已运行 NMBM ImmortalWrt 后升级：`*h3c_magic-nx30-pro-nmbm*squashfs-sysupgrade.bin`

首刷前在电脑端计算 SHA-256；U-Boot WebUI 仅上传 `factory.bin`。系统已经运行后只用同一 NMBM profile 的 `sysupgrade.bin`，无需再次刷 FIP。

## 首次启动验收

1. 访问 `http://192.168.1.1`，确认 LuCI 可用。
2. 确认 LAN、WAN 和无线 radio 均出现；无线缺失时停止，不要尝试在 LuCI 中“补开”。
3. 确认 WAN/DNS 正常后，在“服务 → OpenClash → 版本更新”下载推荐 Mihomo 内核。
4. 固件配置必须保留 `CONFIG_PACKAGE_luci-compat=y`。OpenClash 的插件内更新可能将被标记为 auto-installed 的 `luci-compat` 判为孤立依赖并删除；而 OpenClash 仍需要其 `luci.cbi.datatypes` 模块，删除后会导致整个 LuCI 请求报 `module 'luci.cbi.datatypes' not found`。

若已发生该错误，不要反复刷新 Web 页面。通过 SSH 恢复 LuCI（须使用与当前 ImmortalWrt 24.10 固件匹配的官方 feed；不要跨发行版下载 `.ipk`）：

```sh
opkg update
opkg install luci-compat
opkg flag hold luci-compat
/etc/init.d/uhttpd restart
reboot
```

`hold` 用于保护当前恢复包不被下一次插件更新清理；固件重编并显式内置 `luci-compat` 后可取消该临时保护。若 `opkg` 报 feed 中不存在或版本不匹配，应先刷回本次构建产物，或从**同一编译输出目录**安装其 `luci-compat_*.ipk`；不要强行安装其它版本固件的 LuCI 包。恢复后执行 `opkg status luci-compat`，确认它已安装，再更新 OpenClash。

## 故障定位

### `make menuconfig` 提示终端尺寸不足

在新开的独立系统终端中运行 Docker 和 `make menuconfig`，不使用 VS Code 内置终端。终端至少需要 `80` 列、`19` 行。

### 无线 radio 缺失

先检查本次固件的 manifest 是否包含上面的四个无线相关包。若没有，说明构建配置或源码不符合 SOP；重新使用官方源码和本机型配置片段构建，不在路由器上临时安装不匹配的 kmod。

### `curl: (77) CA signer not available for verification`

原厂系统显示 `1970` 时说明 WAN/NTP 未就绪，HTTPS 证书会校验失败。恢复 WAN 联网并等待校时后重试；不要使用 `curl -k` 绕过校验。
