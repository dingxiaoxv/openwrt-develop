# Hanwckf U-Boot：CMCC RAX3000M eMMC 与 Redmi AX6000 路线核验

日期：2026-08-29  
置信度：high confidence（公开上游/官方项目资料；未进行实机写入）

## 摘要

Hanwckf `bl-mt798x` 的 latest release 是 `20241115`。已将 CMCC RAX3000M eMMC 与 Redmi AX6000 的 U-Boot 迁移步骤补齐为“前置确认、完整备份、校验、写入、回读/verify、WebUI 恢复”的流程。

最重要的修正是：Hanwckf 的 Redmi AX6000 U-Boot 不兼容官方 `ubootmod` layout；应构建并刷入官方 `xiaomi_redmi-router-ax6000-stock` 镜像。

## 范围

- CMCC RAX3000M **eMMC**：`mt7981_cmcc_rax3000m-emmc-fip.bin`。
- Redmi AX6000：`mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin`。
- 不涉及实际路由器配置或 flash 写入。

## 证据

1. Hanwckf [机型与 WebUI 文档](https://cmi.hanwckf.top/p/mt798x-uboot-usage/) 列出两机型的 BOARD、默认恢复 IP、Reset 进入方法和构建参数。
2. Hanwckf [release 页面](https://github.com/hanwckf/bl-mt798x/releases/tag/20241115) 显示 `20241115` 为 latest。
3. `bl-mt798x` 当前 `build.sh` 对 eMMC 禁用 multi-layout/fixed-mtdparts，并按 `SOC=mt7981 BOARD=cmcc_rax3000m-emmc` 输出 eMMC FIP；AX6000 的 SPI-NAND 可用 `MULTI_LAYOUT=1`。
4. Hanwckf 的 AX6000 layout 兼容表将 `OpenWrt ubootmod`、`ImmortalWrt ubootmod`、`X-Wrt ubootmod` 全部标为不兼容，而 stock firmware 在 `default` layout 下兼容。
5. 官方 ImmortalWrt `openwrt-24.10` 的 `filogic.mk` 同时定义 AX6000 `stock` 和 `ubootmod` devices，前者产出 `sysupgrade.bin`，后者产出 `sysupgrade.itb`；故文档/defconfig 已选 stock。

## 判断

- confirmed：此前 AX6000 的“Hanwckf U-Boot + 官方 ubootmod 镜像”组合错误，必须停止使用。
- high confidence：RAX3000M eMMC 的迁移需使用匹配的 GPT、preloader/BL2 与 Hanwckf eMMC FIP，且必须对 eMMC block device 与回读进行验证。
- high confidence：两机型的 failsafe WebUI 均要求电脑可设静态 IP；RAX3000M eMMC 为 `192.168.1.1`，AX6000 为 `192.168.31.1`。

## 未决问题

1. 待刷的 RAX3000M 是否已确认是 eMMC 而非 NAND，且可安全进入 root shell？
2. 待刷 AX6000 的当前系统/分区标签是否仍有 `BL2`、`Nvram`、`Bdata`、`Factory`、`FIP`？
3. Hanwckf 未对 release 内单个 FIP 提供独立签名/哈希；实际执行应保留自行构建的 tag、commit 与 SHA-256。

## 后续验证

1. 在实际设备上先执行文档的只读硬件/分区检查与备份，存储到两处。
2. 写入后先验证 FIP read-back（RAX3000M eMMC）或 `mtd verify`（AX6000），再首次重启。
3. 通过 WebUI 仅上传对应 stock/`.itb` 镜像，启动后再检查 LAN/WAN/Wi-Fi 与 manifest。
