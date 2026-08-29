# Redmi AX6000：Hanwckf U-Boot、官方源码构建与刷机

## 适用范围与兼容性结论

- 设备：Xiaomi Redmi Router AX6000（MT7986，SPI-NAND）。
- U-Boot：Hanwckf [`bl-mt798x`](https://github.com/hanwckf/bl-mt798x)；截至 2026-08-29 latest release 为 `20241115`。
- 固件：官方 `immortalwrt/immortalwrt` `openwrt-24.10`，使用 `mediatek/filogic` / `xiaomi_redmi-router-ax6000-stock`。
- 构建配置：[xiaomi-redmi-router-ax6000-stock-openclash.config](defconfig/xiaomi-redmi-router-ax6000-stock-openclash.config)。

**不要把任何 `ubootmod` 镜像刷给 Hanwckf U-Boot。** Hanwckf 的兼容性表明确列出 OpenWrt、ImmortalWrt 与 X-Wrt 的 `ubootmod` 均不兼容；其 AX6000 `default` layout 对应 stock firmware。旧文档中的 `xiaomi_redmi-router-ax6000-ubootmod` 已废弃。

下文从已经取得 root shell 的原厂/兼容系统开始。小米原厂 SSH 解锁方式取决于地区和版本；没有 root shell 时，先选择与当前版本精确匹配且可回退的解锁方案。

## 1. 准备正确的 Hanwckf FIP

从 [latest release](https://github.com/hanwckf/bl-mt798x/releases/latest) 下载发布包并解压，或自行构建。标准选择是保留 stock firmware 兼容性的 multi-layout FIP：

```sh
git clone --depth 1 https://github.com/hanwckf/bl-mt798x.git
cd bl-mt798x && git checkout 20241115
SOC=mt7986 BOARD=redmi_ax6000 MULTI_LAYOUT=1 ./build.sh
# output/mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin
sha256sum output/mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin
```

上传该 FIP 到 `/tmp/`，在路由器上再次计算 SHA-256 并与电脑一致。release 是压缩包而非逐 FIP 签名发布，因此不接受来源不明的同名文件。

## 2. 确认分区名并备份原厂校准与引导数据

FIP 的 `/dev/mtdN` 编号可能随 layout 改变，操作只能使用分区**名称**。先确认五个分区都存在：

```sh
cat /proc/mtd
for part in BL2 Nvram Bdata Factory FIP; do
  grep -q "\"$part\"" /proc/mtd || { echo "missing: $part"; exit 1; }
done
```

备份 `BL2`、`Nvram`、`Bdata`、`Factory` 和 FIP；其中 `Bdata`/`Factory` 包含设备校准、MAC 等唯一数据，绝不能用其他设备的备份替代：

```sh
mkdir -p /tmp/ax6000-before-hanwckf
for part in BL2 Nvram Bdata Factory FIP; do
  mtd read "/tmp/ax6000-before-hanwckf/$part.bin" "$part" || exit 1
done
sha256sum /tmp/ax6000-before-hanwckf/*.bin
```

将整个目录下载到两处电脑存储，并在电脑再次核对 SHA-256。未确认备份可读前，不得写 FIP。

## 3. 刷入 Hanwckf FIP 并验证

稳定供电下，确认文件名、哈希和 `/proc/mtd` 的 `FIP` 标签无误后执行：

```sh
sha256sum /tmp/mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin
mtd write /tmp/mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin FIP
mtd verify /tmp/mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin FIP
```

`mtd write` 已处理目标分区擦写，避免额外执行 `mtd erase FIP`。仅在 `mtd verify` 成功时继续；FIP 写入期间断电将需要串口或编程器恢复。

断电后按住 Reset 通电至少 15 秒。电脑连任一 LAN 口并设静态 `192.168.31.100/24`，用隐身窗口访问 `http://192.168.31.1`。Hanwckf WebUI 默认不提供 DHCP；进不了页面时先检查静态地址和 Reset 时序，不要盲刷其他 FIP。

## 4. 首次固件与后续升级

在 Hanwckf WebUI 选择 **stock layout**，上传官方构建产物：

- 首次：`*xiaomi_redmi-router-ax6000-stock*initramfs-factory.ubi`
- 后续：从运行中的系统通过 LuCI/`sysupgrade` 刷 `*xiaomi_redmi-router-ax6000-stock*squashfs-sysupgrade.bin`

切换 layout 必须在 Hanwckf WebUI 中完成，再上传该 layout 对应的固件；不能在运行中的系统内跨 layout 刷写。更新 U-Boot 时访问 `http://192.168.31.1/uboot.html`，且只上传 AX6000 FIP。

## 构建与首次启动验收

严格按 [官方源码编译 SOP](official-source-build-sop.md)，并导入：

```sh
cp -f /build-config/xiaomi-redmi-router-ax6000-stock-openclash.config .config
make defconfig
```

manifest 必须包含 `kmod-mt7915e`、`kmod-mt7986-firmware`、`mt7986-wo-firmware` 和 `wpad-openssl`。确认 LAN、WAN、两个无线 radio 和 LuCI 正常后，再配置 OpenClash；插件预装不等于 Mihomo 内核已安装。

网络受限时，可在电脑下载 `mihomo-linux-arm64-*.gz`，解压后上传：

```sh
scp mihomo-linux-arm64-* root@192.168.1.1:/etc/openclash/core/clash_meta
ssh root@192.168.1.1 'chmod +x /etc/openclash/core/clash_meta'
```

## 来源与版本依据

- Hanwckf 的 [机型表、构建参数、WebUI 进入步骤及 layout 兼容表](https://cmi.hanwckf.top/p/mt798x-uboot-usage/) 指定 AX6000 的 `redmi_ax6000`、`192.168.31.1`、`MULTI_LAYOUT=1`，并明确 `ubootmod` 不兼容。
- [Hanwckf release 20241115](https://github.com/hanwckf/bl-mt798x/releases/tag/20241115) 是本次查询时的 latest release。
