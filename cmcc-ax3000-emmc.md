# CMCC RAX3000M eMMC：Hanwckf U-Boot、官方源码构建与刷机

## 适用范围与边界

- 仅适用于 **CMCC RAX3000M eMMC（算力版）**，不是 NAND 版，也不是 RAX3000Me。
- U-Boot 使用 Hanwckf [`bl-mt798x`](https://github.com/hanwckf/bl-mt798x)；截至 2026-08-29 latest GitHub release 为 `20241115`。必须使用 `mt7981_cmcc_rax3000m-emmc`，不能使用无 `-emmc` 的 NAND 文件。
- 固件使用官方 `immortalwrt/immortalwrt` `openwrt-24.10` 分支，profile 是 `mediatek/filogic` / `cmcc_rax3000m`；配置为 [cmcc-rax3000m-openclash.config](defconfig/cmcc-rax3000m-openclash.config)。

`BL2`、GPT 和 FIP 分别写入 eMMC boot area 与 user area；写错设备、文件或 offset 需要串口/编程器恢复。以下步骤要求已有 root shell 与稳定供电。

## 1. 准备三个匹配文件

从 [Hanwckf latest release](https://github.com/hanwckf/bl-mt798x/releases/latest) 下载发布包并解压，或自行构建。正确 FIP 的可复现构建方式：

```sh
git clone --depth 1 https://github.com/hanwckf/bl-mt798x.git
cd bl-mt798x && git checkout 20241115
SOC=mt7981 BOARD=cmcc_rax3000m-emmc ./build.sh
# output/mt7981_cmcc_rax3000m-emmc-fip.bin
sha256sum output/mt7981_cmcc_rax3000m-emmc-fip.bin
```

按 [官方源码编译 SOP](official-source-build-sop.md) 构建官方固件，同时保留：

- `*cmcc_rax3000m-emmc-gpt.bin`
- `*cmcc_rax3000m-emmc-preloader.bin`
- `mt7981_cmcc_rax3000m-emmc-fip.bin`（Hanwckf）

上传三者到 `/tmp/`，在路由器重算 `sha256sum` 并与电脑一致。Hanwckf release 只发布压缩包、没有逐 FIP 签名校验值，故不使用来源不明的网盘文件。

## 2. 确认硬件并完整备份

以下任一项不符合即停止：

```sh
cat /proc/partitions | grep -E 'mmcblk0|mmcblk0boot0'
test -b /dev/mmcblk0 && test -b /dev/mmcblk0boot0 && echo 'eMMC block devices present'
ls -l /tmp/*rax3000m-emmc* /tmp/mt7981_cmcc_rax3000m-emmc-fip.bin
```

把 boot area 和 user area 前 16 MiB 备份到电脑以外的位置，再核验 SHA-256：

```sh
dd if=/dev/mmcblk0boot0 of=/tmp/rax3000m-emmc-boot0-before.bin bs=1M conv=fsync
dd if=/dev/mmcblk0 of=/tmp/rax3000m-emmc-first16m-before.bin bs=1M count=16 conv=fsync
sha256sum /tmp/rax3000m-emmc-*-before.bin
```

确认备份可读、待写文件与哈希完全一致之前，**不要**继续。

## 3. 首次迁移：GPT + BL2 + Hanwckf FIP

`seek=13312` 是 `0x680000 / 512`，仅适用于本页限定的 RAX3000M eMMC GPT 布局。每条成功后再执行下一条；期间不得断电、重启或拔盘：

```sh
dd if=/tmp/immortalwrt-*-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync
echo 0 > /sys/block/mmcblk0boot0/force_ro
dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync
dd if=/tmp/immortalwrt-*-cmcc_rax3000m-emmc-preloader.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync
dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync
dd if=/tmp/mt7981_cmcc_rax3000m-emmc-fip.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync
sync
```

必须回读验证 FIP：

```sh
FIP_BYTES=$(wc -c < /tmp/mt7981_cmcc_rax3000m-emmc-fip.bin)
FIP_BLOCKS=$(( (FIP_BYTES + 511) / 512 ))
dd if=/dev/mmcblk0 of=/tmp/rax3000m-emmc-fip-readback.bin bs=512 skip=13312 count="$FIP_BLOCKS" status=none
cmp -n "$FIP_BYTES" /tmp/mt7981_cmcc_rax3000m-emmc-fip.bin /tmp/rax3000m-emmc-fip-readback.bin && echo 'FIP read-back verified'
```

仅在显示 `FIP read-back verified` 后重启。电脑接 LAN，设静态 `192.168.1.100/24`，按住 Reset 通电至少 15 秒后访问 `http://192.168.1.1`。WebUI 不保证提供 DHCP。

## 4. 固件与后续升级

首次在 Hanwckf WebUI 上传 `*cmcc_rax3000m*initramfs-recovery.itb`，启动后进入 LuCI，再从运行中的系统升级 `*cmcc_rax3000m*squashfs-sysupgrade.itb`。今后只刷同 layout 的 `sysupgrade.itb`，不重复写 GPT、BL2 或 FIP。更新 Hanwckf 本身时访问 `http://192.168.1.1/uboot.html`，只上传本机型 eMMC FIP。

构建时：

```sh
cp -f /build-config/cmcc-rax3000m-openclash.config .config
make defconfig
```

manifest 必须包含 `kmod-mt7915e`、`kmod-mt7981-firmware`、`mt7981-wo-firmware` 与 `wpad-openssl`。首次启动后确认 LAN、WAN、两个无线 radio 和 LuCI，再配置 OpenClash。

## 来源与版本依据

- Hanwckf 的 [机型表、构建参数和 failsafe WebUI 说明](https://cmi.hanwckf.top/p/mt798x-uboot-usage/) 列出 `cmcc_rax3000m-emmc`、`192.168.1.1`、`SOC=mt7981 BOARD=cmcc_rax3000m-emmc` 以及静态 IP/Reset 进入方式。
- [Hanwckf release 20241115](https://github.com/hanwckf/bl-mt798x/releases/tag/20241115) 是本次查询时的 latest release。
- GPT/BL2/FIP 写入位置与官方 `cmcc_rax3000m` profile 的 eMMC 辅助产物相对应；实际操作以本机备份和回读验证为准。
