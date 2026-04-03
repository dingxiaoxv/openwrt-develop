# CMCC AX3000 eMMC 基于 Padavanonly 预装 OpenClash 自编译教程

更新时间：2026-04-01

## 适用范围

本文适用于：

- 设备：`CMCC AX3000 eMMC` / `RAX3000M eMMC` / 常说的“算力版”
- 固件底座：`padavanonly/immortalwrt-mt798x-6.6`
- 目标：基于 `padavanonly` 默认配置，自编译一版尽量简单、稳定的固件，只额外预装 `OpenClash`
- 引导前提：路由器已经使用兼容主线 `.itb` 的 U-Boot，通常是基于 `hanwckf/bl-mt798x` 的版本

这份教程故意不做激进精简。第一版先求稳定跑通，不主动删 MTK 默认包。

## 路线说明

综合官方仓库和恩山论坛的实际刷机路线，最稳的做法是：

1. 使用 `padavanonly/immortalwrt-mt798x-6.6` 的 `openwrt-24.10-6.6` 分支
2. 直接使用仓库自带的 `defconfig/mt7981-ax3000.config`
3. 只额外加入 `luci-app-openclash`
4. 保留 `padavanonly` 默认的 MT7981 包集
5. 编译得到 `.itb` 固件
6. 如果当前 U-Boot 已支持主线 `.itb`，先刷 `initramfs-recovery.itb`，进系统后再刷 `sysupgrade.itb`

这里有两个容易混淆的点：

- `padavanonly` 仓库 README 里还保留着旧的 clone 地址，结尾是 `immortalwrt-mt798x-24.10`；实际应以当前仓库地址 `immortalwrt-mt798x-6.6` 为准
- `defconfig/mt7981-ax3000.config` 里已经包含了 `cmcc_rax3000m` 和 `cmcc_rax3000m-emmc` 这两个目标

## 一、开始前先确认的事情

### 1. 你的 U-Boot 是否已经兼容主线 `.itb`

`CMCC AX3000 eMMC` 跑 `24.10 / 6.6`，论坛上的共识很明确：要使用支持主线 OpenWrt / ImmortalWrt `.itb` 的 U-Boot。

如果你现在已经刷的是 `hanwckf` 系或者恩山常见的兼容 WebUI U-Boot，那么这份教程里可以只编固件，不必重新编 U-Boot。

如果你现在还是旧版、原厂式或者不支持 `.itb` 的 U-Boot，不要直接刷本文编出来的固件。你需要先完成 `GPT + BL2 + FIP` 这条主线引导链迁移。

### 2. 编译环境

推荐：

- Debian 11 / 12
- Ubuntu 22.04 / 24.04
- x86_64 主机
- 至少 4 GB 内存
- 至少 25 GB 可用空间，第一次编译建议 50 GB 左右

### 3. 安全建议

刷机前建议先做到这几件事：

- 备份当前重要配置
- 确认自己当前 U-Boot 是否已经支持主线 `.itb`
- 不要混用 `NAND` 和 `eMMC` 的文件
- 不要刷其他机型的 `GPT`、`BL2`、`FIP`

## 二、安装编译依赖

依赖列表直接按 `padavanonly` README 执行：

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
  g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
  libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano \
  ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
  python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs \
  upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd
```

注意：

- 整个编译过程尽量用普通用户，不要在源码目录里 `sudo make`
- 源码路径里不要带空格，也不要放在包含中文的路径下
- 如果你不是很熟悉 WSL，优先用原生 Linux

## 三、拉取 Padavanonly 源码

建议直接按当前仓库地址拉：

```bash
git clone -b openwrt-24.10-6.6 --single-branch https://github.com/padavanonly/immortalwrt-mt798x-6.6.git
cd immortalwrt-mt798x-6.6
```

然后更新并安装 feeds：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

## 四、导入官方 MT7981 基础配置

直接使用仓库自带的 AX3000 基线配置：

```bash
cp -f defconfig/mt7981-ax3000.config .config
```

这个配置已经把 `CMCC RAX3000M eMMC` 放进来了。你可以确认一下：

```bash
grep -n "cmcc_rax3000m" .config
```

关键项应包含：

- `CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_cmcc_rax3000m-emmc=y`
- `CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_cmcc_rax3000m=y`

这也是为什么本文推荐“按 padavanonly 默认走”。第一版尽量不要删 MTK 相关默认包，避免把无线、交换、加速依赖删坏。

## 五、把 OpenClash 加进源码树

OpenClash 官方 README 给出的方式很明确：可以把 `luci-app-openclash` 放进自己的 OpenWrt / ImmortalWrt 源码树里，再随固件一起编译。

最直接的做法：

```bash
git clone --depth 1 https://github.com/vernesong/OpenClash.git package/openclash
```

拉完以后，目录应该是：

```bash
package/openclash/luci-app-openclash/Makefile
```

如果你本地源码里已经存在这个路径，这一步可以跳过。

## 六、在 menuconfig 里启用 OpenClash

打开菜单：

```bash
make menuconfig
```

这里只做最少改动：

1. 保持 `MediaTek` 和 `MT7981` 目标不变
2. 进入 `LuCI -> Applications`
3. 选中 `luci-app-openclash`
4. 保存退出

然后执行：

```bash
make defconfig
```

可以再确认一下：

```bash
grep -n "CONFIG_PACKAGE_luci-app-openclash=y" .config
```

## 七、OpenClash 依赖说明

OpenClash 当前 `Makefile` 里声明的直接依赖包括：

- `dnsmasq-full`
- `bash`
- `curl`
- `ca-bundle`
- `ip-full`
- `ruby`
- `ruby-yaml`
- `kmod-tun`
- `unzip`

另外它还会根据防火墙框架自动带一些默认项：

- 在 `firewall4` 下：`kmod-nft-tproxy`、`dnsmasq_full_nftset`、`kmod-inet-diag`
- 在旧 `iptables` 路线下：`kmod-ipt-nat`、`iptables-mod-tproxy`、`iptables-mod-extra`、`dnsmasq_full_ipset`、`ipset`

`padavanonly` 这条 `24.10 / 6.6` 路线本身就是 `firewall4`，所以你应当看到的是 `nft` 这一套。

正常情况下，只要 `luci-app-openclash` 选中正确，不需要你手工一个个再去勾这些依赖。

## 八、开始编译

先下载源码包：

```bash
make download -j8
```

正式编译：

```bash
make -j"$(nproc)" V=s
```

如果机器内存不大，改成更保守的并行数：

```bash
make -j4 V=s
```

编译产物目录：

```bash
bin/targets/mediatek/filogic/
```

## 九、怎么看编译出来的文件

对这台机器来说，你主要关心四类文件。

### 1. 固件文件

最常用的是这两个：

- `immortalwrt-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb`
- `immortalwrt-mediatek-filogic-cmcc_rax3000m-squashfs-sysupgrade.itb`

### 2. eMMC 引导辅助文件

这些只在迁移主线引导链时需要：

- `immortalwrt-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin`
- `immortalwrt-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin`

文件名容易看花，记住这个规律就行：

- 真正运行的固件文件通常是 `cmcc_rax3000m`
- eMMC 引导辅助文件通常是 `cmcc_rax3000m-emmc`

所以 `.itb` 没带 `-emmc` 并不代表它不是给 eMMC 版用的。

你可以用下面的命令列出最终产物：

```bash
find bin/targets/mediatek/filogic -maxdepth 1 -type f | sort
```

## 十、刷机策略

### 情况 A：你已经有兼容主线的 U-Boot

这是本文默认、也最推荐的情况。

刷机顺序：

1. 进入 U-Boot WebUI
2. 先刷 `initramfs-recovery.itb`
3. 成功启动进入 ImmortalWrt
4. 打开 LuCI：`http://192.168.6.1`
5. 再从运行中的系统里升级 `squashfs-sysupgrade.itb`

这是第一次切换到新系统时最稳的路线。

### 情况 B：你还没有兼容主线的 U-Boot

这种情况不要直接刷本文编出来的 `.itb`。

根据恩山现有的 `RAX3000M eMMC + 24.10 / 6.6` 实操路线，顺序通常是：

1. 刷 `...cmcc_rax3000m-emmc-gpt.bin`
2. 刷 `...cmcc_rax3000m-emmc-preloader.bin`
3. 刷 `mt7981-cmcc_rax3000m-emmc-fip-fit.bin`
4. 再刷 `initramfs-recovery.itb`
5. 启动系统后再升级 `squashfs-sysupgrade.itb`

这里的 `fip-fit.bin` 不是 `padavanonly` 固件仓库编出来的，而是 U-Boot 项目生成的。

如果你需要自己编这个引导文件，`hanwckf/bl-mt798x` 里的命令是：

```bash
SOC=mt7981 BOARD=cmcc_rax3000m-emmc ./build.sh
```

如果你当前已经在用恩山常见的、基于 `hanwckf` 改出来的兼容版本，一般没必要再重复刷一次 `BL2 / FIP`。

## 十一、首次开机

`padavanonly` 默认信息：

- 地址：`http://192.168.6.1`
- 域名：`http://immortalwrt.lan`
- 用户名：`root`
- 密码：默认空

第一次开机后建议按这个顺序：

1. 先设置 root 密码
2. 确认 LAN、WAN、无线都正常
3. 确认系统稳定后再去配置 OpenClash

## 十二、首次使用 OpenClash

要特别注意：

“固件里已经预装 `luci-app-openclash`” 不等于 “OpenClash 内核已经自带好了”。

OpenClash 包本身会创建：

- `/etc/openclash/core`

第一版最简单的做法是开机后再下载内核：

1. 打开 `服务 -> OpenClash`
2. 在版本更新页面下载推荐内核
3. 导入你的订阅或者配置文件
4. 保存并启动

如果你以后想做“完全离线、第一次开机就带内核”的版本，可以再单独把 Mihomo 核心塞进固件，但这不属于本文这版最简单方案。

## 十三、第一版不建议做的事

- 不要第一版就大幅删 MTK 默认包
- 不要混刷 `NAND` 和 `eMMC` 文件
- 不要在不确定 U-Boot 是否支持主线 `.itb` 时直接刷 `sysupgrade.itb`
- 不要把“OpenClash 插件已安装”和“OpenClash 内核已下载”混为一谈
- 不要为了追求整洁去替换一个已经工作正常的兼容 U-Boot

## 十四、快速检查清单

刷机前：

- `make` 已经成功结束
- `.config` 里已经有 `CONFIG_PACKAGE_luci-app-openclash=y`
- `bin/targets/mediatek/filogic/` 里有 `cmcc_rax3000m` 对应的 `.itb`
- 如果要迁移 U-Boot，引导辅助文件也已经准备好
- 你已经确认自己当前 U-Boot 是否支持主线 `.itb`

刷机后：

- 路由器能正常启动
- 能访问 `192.168.6.1`
- 无线工作正常
- 菜单里能看到 `服务 -> OpenClash`
- OpenClash 能正常下载内核

## 十五、常见问题

### 1. `menuconfig` 里看不到 `luci-app-openclash`

先检查目录是不是这个结构：

```bash
package/openclash/luci-app-openclash/Makefile
```

如果不是，通常是仓库放错位置了。

### 2. 编译太慢或者爆内存

把并行数调低：

```bash
make -j2 V=s
```

### 3. 刷机后不能启动

这时首先不要怀疑 OpenClash，也不要先怀疑无线包。先检查引导链：

- 当前是不是主线兼容 U-Boot
- 用的到底是不是 `RAX3000M eMMC` 对应文件
- 有没有误用 `NAND` 文件
- 有没有在旧引导链上直接刷主线 `.itb`

### 4. OpenClash 页面存在但启动不了

最常见的原因就是：插件装了，但核心还没下载。先去 OpenClash 的版本更新页面把内核下好。

## 参考来源

官方项目来源：

- `padavanonly` 仓库：https://github.com/padavanonly/immortalwrt-mt798x-6.6
- `padavanonly` README：https://github.com/padavanonly/immortalwrt-mt798x-6.6/blob/openwrt-24.10-6.6/README.md
- MT7981 默认配置：https://github.com/padavanonly/immortalwrt-mt798x-6.6/blob/openwrt-24.10-6.6/defconfig/mt7981-ax3000.config
- OpenClash 仓库：https://github.com/vernesong/OpenClash
- OpenClash README：https://github.com/vernesong/OpenClash/blob/master/README.md
- OpenClash Makefile：https://github.com/vernesong/OpenClash/blob/master/luci-app-openclash/Makefile
- `hanwckf` 引导仓库：https://github.com/hanwckf/bl-mt798x

论坛参考：

- `RAX3000M EMMC算力版 更换U-Boot 安装ImmortalWrt24.10.0 itb 格式固件`：https://www.right.com.cn/forum/thread-8418450-1-1.html
- `MT7981系列... CMCC RAX3000M EMMC nand 23.05/24.10`：https://www.right.com.cn/forum/thread-8420900-1-1.html
- `RAX3000M Emmc ImmortalWrt 24.10闭源固件`：https://www.right.com.cn/forum/thread-8445676-1-1.html
- `MT798x 支持主线 OpenWrt 的 U-Boot`：https://www.right.com.cn/forum/thread-8400306-1-1.html
