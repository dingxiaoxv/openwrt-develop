# 2026-08-29 Hanwckf RAX3000M eMMC / AX6000 U-Boot

- 查询 Hanwckf `bl-mt798x` 上游 release、构建脚本、功能说明和官方 ImmortalWrt `openwrt-24.10` device definitions。
- 结论：latest release 为 `20241115`；RAX3000M eMMC 用 `mt7981_cmcc_rax3000m-emmc-fip.bin`，AX6000 用 multi-layout `mt7986_redmi_ax6000-fip-fixed-parts-multi-layout.bin`。
- 纠正 AX6000 固件路线：Hanwckf 不支持 `ubootmod`，改用官方 stock profile/`sysupgrade.bin`。
- 已更新两份机型指南、SOP、AX6000 defconfig、issue card 与报告；未执行路由器写入。
