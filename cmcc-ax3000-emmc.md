# CMCC RAX3000M eMMC：官方源码构建与刷机

## 适用范围

- 设备：CMCC RAX3000M eMMC（“算力版”）。
- 固件：官方 `immortalwrt/immortalwrt`，分支 `openwrt-24.10`。
- 官方 profile：`mediatek/filogic` / `cmcc_rax3000m`。
- 构建配置：[cmcc-rax3000m-openclash.config](defconfig/cmcc-rax3000m-openclash.config)。
- 唯一额外应用：`luci-app-openclash`；无线驱动、firmware 和 `wpad-openssl` 是设备基础包。

## 构建

严格按 [官方源码编译 SOP](official-source-build-sop.md) 执行。在 SOP 的“导入机型配置”步骤使用：

```sh
cp -f /build-config/cmcc-rax3000m-openclash.config .config
make defconfig
```

构建前确认：

```sh
grep -E 'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_cmcc_rax3000m|CONFIG_PACKAGE_kmod-mt7915e|CONFIG_PACKAGE_kmod-mt7981-firmware|CONFIG_PACKAGE_mt7981-wo-firmware|CONFIG_PACKAGE_luci-app-openclash' .config
```

构建完成后，manifest 必须包含 `kmod-mt7915e`、`kmod-mt7981-firmware`、`mt7981-wo-firmware` 与 `wpad-openssl`。缺少任一项时禁止刷机。

## 产物与刷机边界

官方 profile 同时生成 eMMC 引导辅助文件和通用运行镜像：

- 运行镜像：`*cmcc_rax3000m*initramfs-recovery.itb`、`*cmcc_rax3000m*squashfs-sysupgrade.itb`
- eMMC 辅助文件：`*cmcc_rax3000m-emmc-gpt.bin`、`*cmcc_rax3000m-emmc-preloader.bin`

若已使用兼容主线 `.itb` 的 U-Boot：

1. 在 U-Boot WebUI 上传 `initramfs-recovery.itb`。
2. 启动后进入 LuCI。
3. 从运行中的系统升级对应 `squashfs-sysupgrade.itb`。

若尚未确认 U-Boot / eMMC 引导链兼容性，不要上传任何固件或辅助文件；先备份分区并按该 U-Boot 的专用文档完成迁移。不得混用 NAND、eMMC 或其他机型的 GPT、BL2、FIP。

### 尚未迁移兼容 U-Boot 时

先完成原厂备份；常见 eMMC 迁移顺序为：

1. `*cmcc_rax3000m-emmc-gpt.bin`
2. `*cmcc_rax3000m-emmc-preloader.bin`
3. 与 eMMC 对应的 Hanwckf FIP
4. `initramfs-recovery.itb`
5. 运行中的系统升级 `squashfs-sysupgrade.itb`

FIP 由 U-Boot 项目生成；如需自行构建，Hanwckf 项目使用：

```sh
SOC=mt7981 BOARD=cmcc_rax3000m-emmc ./build.sh
```

已运行兼容 U-Boot 时，不要为了更新固件重复写 GPT、BL2 或 FIP。

## 首次启动验收

1. LAN、WAN 和无线 radio 均出现。
2. `网络 → 无线` 中可以创建 2.4 GHz / 5 GHz SSID。
3. LuCI 中能看到“服务 → OpenClash”。
4. 确认 WAN/DNS 正常后，再通过 OpenClash 的“版本更新”下载 Mihomo 内核。

## 机型专属排查

- 首刷不能启动时，先核对引导链与镜像 layout，不要先删无线包或怀疑 OpenClash。
- `.itb` 运行镜像文件名不带 `-emmc` 是正常的；eMMC 信息体现在 GPT/preloader/FIP 辅助文件中。
- OpenClash 页面存在但无法启动时，优先检查 Mihomo 内核是否已下载到 `/etc/openclash/core`。
