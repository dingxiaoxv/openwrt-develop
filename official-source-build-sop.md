# 路由器官方源码编译 SOP

更新时间：2026-08-29

## 0. 强制规则

所有新固件一律从官方源码构建：

- ImmortalWrt：`https://github.com/immortalwrt/immortalwrt.git`，分支 `openwrt-24.10`
- OpenWrt：`https://github.com/openwrt/openwrt.git`，使用与目标机型已验证的官方稳定分支

第三方 fork、个人 fork、恩山下载包和厂商 SDK 仅可作为 U-Boot、分区布局或故障参考；不得作为默认固件源码。每次构建都使用独立源码目录，禁止将 fork 的 `feeds`、`.config`、`build_dir` 或 `staging_dir` 复用到官方源码。

## 1. 已收录机型的官方 profile

| 设备 | 官方 target/profile | 无线必需包 | 首刷镜像 | 后续升级镜像 |
| --- | --- | --- | --- | --- |
| H3C Magic NX30 Pro（Hanwckf FIP） | `mediatek/filogic` / `h3c_magic-nx30-pro-nmbm` | `kmod-mt7915e`、`kmod-mt7981-firmware`、`mt7981-wo-firmware` | `*nmbm*factory.bin` | `*nmbm*sysupgrade.bin` |
| CMCC RAX3000M eMMC | `mediatek/filogic` / `cmcc_rax3000m` | `kmod-mt7915e`、`kmod-mt7981-firmware`、`mt7981-wo-firmware` | `*cmcc_rax3000m*initramfs-recovery.itb` | `*cmcc_rax3000m*squashfs-sysupgrade.itb` |
| Xiaomi Redmi Router AX6000（Hanwckf U-Boot） | `mediatek/filogic` / `xiaomi_redmi-router-ax6000-stock` | `kmod-mt7915e`、`kmod-mt7986-firmware`、`mt7986-wo-firmware` | `*ax6000-stock*initramfs-factory.ubi` | `*ax6000-stock*squashfs-sysupgrade.bin` |

配置片段位于 `defconfig/`。其中的无线包和 `wpad-openssl` 是硬件/无线基础能力；OpenClash 及其为插件内升级保护而显式保留的 `luci-compat` 是额外应用。其余 OpenClash 直接依赖由 `make defconfig` 解析。

## 2. 建立隔离源码目录

在工作区根目录执行：

```sh
export IMAGE_NAME='dingyanxu/openwrt-buildenv:immortalwrt-official-24.10-debian11'
export SOURCE_DIR="$PWD/immortalwrt-official-24.10"

git clone --branch openwrt-24.10 --single-branch \
  https://github.com/immortalwrt/immortalwrt.git "$SOURCE_DIR"
mkdir -p .cache/ccache
docker pull "$IMAGE_NAME"
```

记录来源，构建后也将此提交保存到产物目录：

```sh
git -C "$SOURCE_DIR" remote -v
git -C "$SOURCE_DIR" rev-parse HEAD
```

`origin` 必须指向 `github.com/immortalwrt/immortalwrt.git`；不是时停止，不要编译。

## 3. 进入 Docker 编译环境

只在新开的独立系统终端中执行，不使用 VS Code 内置终端：

```sh
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$SOURCE_DIR:/workspace" \
  -v "$PWD/.cache/ccache:/ccache" \
  -v "$PWD/defconfig:/build-config:ro" \
  "$IMAGE_NAME"
```

容器内 `/workspace`：

```sh
./scripts/feeds update -a
./scripts/feeds install -a
```

手动检查 `package/openclash/luci-app-openclash/Makefile`；不存在时执行：

```sh
git clone --depth 1 https://github.com/vernesong/OpenClash.git package/openclash
```

## 4. 导入机型配置并复核

任选**一份**对应配置导入：

```sh
# NX30 Pro NMBM
cp -f /build-config/h3c-magic-nx30-pro-nmbm-openclash.config .config

# CMCC RAX3000M eMMC
# cp -f /build-config/cmcc-rax3000m-openclash.config .config

# Redmi AX6000 Hanwckf U-Boot（stock layout；不要使用 ubootmod）
# cp -f /build-config/xiaomi-redmi-router-ax6000-stock-openclash.config .config

make defconfig
make menuconfig
```

在 `menuconfig` 中只复核目标 profile、对应 `kmod-mt7915e`、`wpad-openssl`、`luci-compat` 和 `luci-app-openclash`；不要用其他机型的 defconfig 覆盖 `.config`，也不要删减设备无线驱动/固件。保存退出后：

```sh
make defconfig
```

## 5. 构建前门槛

先确认目标、OpenClash 和无线包都在 `.config`：

```sh
grep -E 'CONFIG_TARGET_DEVICE_|CONFIG_PACKAGE_luci-app-openclash|CONFIG_PACKAGE_luci-compat|CONFIG_PACKAGE_kmod-mt7915e|CONFIG_PACKAGE_kmod-mt798[16]-firmware|CONFIG_PACKAGE_mt798[16]-wo-firmware|CONFIG_PACKAGE_wpad-openssl' .config
```

若目标 profile 或对应无线包缺失，停止并修正配置；不要依赖“设备 profile 应该会自动带入”。

## 6. 编译、产物门槛与归档

```sh
make download -j"$(nproc)"
make -j"$(nproc)" V=s
```

内存不足时使用 `make -j4 V=s`。成功后：

```sh
find bin/targets/mediatek/filogic -maxdepth 1 -type f | sort
sha256sum bin/targets/mediatek/filogic/*{factory,sysupgrade,recovery}.bin \
  bin/targets/mediatek/filogic/*.itb 2>/dev/null
cp .config bin/targets/mediatek/filogic/build.config
git rev-parse HEAD > bin/targets/mediatek/filogic/source.commit
```

对 NX30 Pro 和 CMCC，检查 manifest 含 MT7981 无线包；对 Redmi AX6000，检查 MT7986 无线包：

```sh
rg -n 'kmod-mt7915e|kmod-mt7981-firmware|mt7981-wo-firmware|kmod-mt7986-firmware|mt7986-wo-firmware|wpad-openssl' \
  bin/targets/mediatek/filogic/*.manifest
```

manifest 未出现目标机型的三项无线包时，禁止刷机。

## 7. 刷机边界

- 编译 profile 和刷机 layout 必须匹配；不得跨机型、跨 NMBM/ITB/UBI layout 使用镜像。
- 仅首次迁移使用各机型教程定义的 factory/recovery 镜像和 U-Boot WebUI。
- 已运行同一 layout 系统时，只用对应 `sysupgrade` 镜像升级；无需重复刷 U-Boot。
- 刷机前核对 SHA-256；刷机后先确认无线 radio、LAN、WAN 与 LuCI，再配置 OpenClash。
