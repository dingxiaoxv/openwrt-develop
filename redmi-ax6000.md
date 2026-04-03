# Redmi AX6000 ImmortalWrt 编译指南

- **仓库**：immortalwrt-mt798x-6.6（padavanonly fork）
- **设备**：Redmi AX6000，hanwckf 110MB 大分区 uboot
- **目标 profile**：`xiaomi_redmi-router-ax6000-ubootmod`
- **附加包**：OpenClash（Clash Meta 内核）
- **编译环境**：Ubuntu 24.04

---

## 刷机文件说明

| 文件 | 用途 |
|------|------|
| `*-initramfs-factory.ubi` | 首次从 hanwckf uboot Web 界面刷入 |
| `*-sysupgrade.bin` | 后续在系统内升级 |

---

## Step 1：安装编译依赖

使用官方脚本（推荐，自动适配发行版版本）：

```bash
sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'
```

或手动安装（Ubuntu 24.04）：

```bash
sudo apt update && sudo apt install -y \
  build-essential clang flex bison g++ gawk gcc-multilib \
  g++-multilib gettext git libncurses-dev libssl-dev \
  python3-dev python3-setuptools \
  rsync unzip zlib1g-dev file wget \
  qemu-utils libelf-dev curl
```

> Ubuntu 24.04 的 Python 3.12 移除了 distutils，用 `python3-dev` + `python3-setuptools` 替代，不要装 `python3-distutils`。

---

## Step 2：进入仓库目录

```bash
cd /home/mova/playground/router/immortalwrt-mt798x-6.6
```

---

## Step 3：拉取 OpenClash 源码

```bash
git clone --depth 1 https://github.com/vernesong/OpenClash.git package/openclash
```

验证包结构：

```bash
ls package/openclash/luci-app-openclash/
# 应能看到 Makefile
```

---

## Step 4：更新 feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

---

## Step 5：加载 AX6000 基础配置

```bash
cp defconfig/mt7986-ax6000.config .config
```

---

## Step 6：menuconfig 调整

```bash
make menuconfig
```

### 6.1 确认目标设备

`cp defconfig/mt7986-ax6000.config .config` 已自动设置好目标，进入 menuconfig 后只需确认显示正确：

```
Target System  → MediaTek ARM
Subtarget      → Filogic 8xx
Target Profile → Xiaomi Redmi Router AX6000 (OpenWrt U-Boot layout)
```

### 6.2 启用 OpenClash

```
LuCI → Applications → luci-app-openclash  →  [*]
```

### 6.3 关闭不需要的代理插件

```
LuCI → Applications:
  luci-app-ssr-plus   → [ ]
  luci-app-passwall   → [ ]  （如存在）
  luci-app-vssr       → [ ]  （如存在）
```

### 6.4 确认 OpenClash 运行依赖

```
Kernel modules → Network Support:
  kmod-tun                      → [*]

Network → Firewall:
  iptables-mod-tproxy           → [*]
  iptables-mod-extra            → [*]
```

> 这些在原 defconfig 中已存在，确认未被误删即可。

保存退出（Save → `.config`）。

---

## Step 7：编译

```bash
# 预下载所有源码包
make download -j8 V=s

# 开始编译（根据 CPU 核心数自动并发）
make -j$(nproc) V=s 2>&1 | tee build.log
```

首次编译约 2~4 小时。

如果编译中途报错，用单线程重跑获取完整错误信息：

```bash
make -j1 V=sc 2>&1 | tee build_error.log
```

---

## Step 8：找到编译产物

```bash
ls bin/targets/mediatek/filogic/ | grep ax6000
```

需要的文件（前缀为 `immortalwrt-mediatek-filogic-`）：

- `...-xiaomi_redmi-router-ax6000-ubootmod-initramfs-factory.ubi`
- `...-xiaomi_redmi-router-ax6000-ubootmod-sysupgrade.bin`

---

## Step 9：刷机

在 hanwckf uboot Web 界面（路由器按住 reset 上电，访问 `192.168.31.1`）：

1. 上传 `initramfs-factory.ubi` 刷入
2. 等待重启，首次启动约 2 分钟
3. 访问 `192.168.1.1` 进入 LuCI

---

## Step 10：首次启动后配置 Clash Meta 内核

OpenClash 的 mihomo 内核二进制不内嵌进固件，需要联网后下载。

### 方式一：在路由器上自动下载

LuCI → OpenClash → 版本更新：

1. 内核类型选 **Clash Meta (mihomo)**
2. 点「检查并更新」

### 方式二：手动传输（网络受限时）

在电脑上从 [mihomo releases](https://github.com/MetaCubeX/mihomo/releases) 下载：
- 文件名格式：`mihomo-linux-arm64-*.gz`

```bash
# 解压并传到路由器
gunzip mihomo-linux-arm64-*.gz
scp mihomo-linux-arm64-* root@192.168.1.1:/etc/openclash/core/clash_meta

# 在路由器上赋权
ssh root@192.168.1.1 'chmod +x /etc/openclash/core/clash_meta'
```

---

## 注意事项

- 必须用非 root 用户编译，OpenWrt 构建系统禁止 root 运行
- 磁盘空间至少预留 25GB
- `make download` 阶段需要能访问 GitHub
