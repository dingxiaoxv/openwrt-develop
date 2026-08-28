# H3C Magic NX30 Pro 免拆机刷机流程

本流程只保留已实际验证的路线：原厂 `V100R010` → 导入本地 Telnet 配置 → SSH → 备份 → Hanwckf U-Boot → NMBM 固件。

## 文件与前提

- 路由器：H3C Magic NX30 Pro。
- 原厂版本：**仅 `V100R010`**。
- 已验证的配置包：[NX30Pro免拆机Telnet.zip](NX30Pro/NX30Pro免拆机Telnet.zip)。解压后得到 `decoded-NX30Pro-finished.cfg`；虽然文件名带 `decoded`，它实际是可由原厂 WebUI 直接恢复的 XOR 封装配置，不要再次解码。
- 配置包 SHA-256：`adce52dd5aaae1f874d09886453ef836366c01b2148018425ee3a550fd5bcb63`
- Hanwckf U-Boot：`mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin`。
- 后续固件 profile：`h3c_magic-nx30-pro-nmbm`，首次刷 `factory.bin`，后续升级使用 `sysupgrade.bin`。

刷写 FIP 时不能断电。不要刷其它机型的 U-Boot，也不要把 OpenWrt U-Boot-layout 镜像混入本流程。

## SHA-256 核对

在电脑或路由器上均可执行：

```sh
sha256sum 文件名
```

输出的前 64 位字符是 SHA-256。传文件后，电脑与路由器对同一文件执行该命令，两个 64 位结果必须完全一致。

例如核对本地 Telnet 配置包：

```sh
sha256sum NX30Pro免拆机Telnet/decoded-NX30Pro-finished.cfg
```

它应为：

```text
adce52dd5aaae1f874d09886453ef836366c01b2148018425ee3a550fd5bcb63
```

## 1. 导入 Telnet 配置

1. 登录原厂 WebUI：`http://192.168.124.1`。
2. 进入“更多 → 设备管理 → 配置备份”。
3. 先导出并保存当前原厂配置。
4. 解压 [NX30Pro免拆机Telnet.zip](NX30Pro/NX30Pro免拆机Telnet.zip)，选择恢复其中的 `decoded-NX30Pro-finished.cfg`。
5. 完成恢复后，将路由器断电再上电，等待完全启动。

恢复该配置后，Wi-Fi 密码和原厂 Web 管理密码均为：

```text
77777777
```

该配置会在 LAN 上启动一个无密码 root Telnet：

```sh
telnet 192.168.124.1 7788
```

进入后应直接看到 root shell，例如：

```text
/ #
```

此 Telnet 未认证，只能在可信的本地有线网络短时间使用，不能暴露到 WAN。

## 2. 联网、校时并开启 SSH

先让原厂系统正常联网。确认时间不是 `1970`：

```sh
date
```

时间正确后，在 Telnet shell 中执行：

```sh
curl -o /tmp/dropbear.ipk https://downloads.openwrt.org/releases/packages-19.07/aarch64_cortex-a53/base/dropbear_2019.78-2_aarch64_cortex-a53.ipk
opkg install /tmp/dropbear.ipk
/etc/init.d/dropbear enable
/etc/init.d/dropbear start
```

从电脑验证 SSH：

```sh
ssh root@192.168.124.1
```

用户名和密码为：

```text
username: root
password: admin
```

## 3. 备份原厂分区

通过 SSH 先检查分区，再依次导出备份。先备份最大的 `ubi`，传到电脑后再备份小分区，避免 `/tmp` 空间不足：

```sh
cat /proc/mtd
dd if=/dev/mtd5 of=/tmp/mtd5_ubi
```

从电脑导出 `mtd5_ubi` 后，回到路由器执行：

```sh
rm /tmp/mtd5_ubi
dd if=/dev/mtd1 of=/tmp/mtd1_BL2
dd if=/dev/mtd3 of=/tmp/mtd3_Factory
dd if=/dev/mtd4 of=/tmp/mtd4_FIP
```

把这三个文件也导出到电脑并长期保存。尤其不要丢失 `mtd3_Factory`。

## 4. 刷入 Hanwckf U-Boot

将 `mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin` 上传到路由器 `/tmp`，核对 SHA-256 后执行：

```sh
# 电脑端
sha256sum mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin

# 路由器端
sha256sum /tmp/mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin
```

两端结果完全一致后再执行：

```sh
mtd write /tmp/mt7981_h3c_magic-nx30-pro-fip-fixed-parts.bin FIP
sync
reboot
```

本步骤只写 `FIP`，不写 `BL2`、`Factory` 或 `ubi`。

## 5. 确认 U-Boot 并刷入固件

1. 路由器断电。
2. 按住 Reset 后通电，保持至少 15 秒。
3. 电脑连接 LAN，设为静态 IP `192.168.1.100/24`。
4. 打开 `http://192.168.1.1`，确认 Hanwckf U-Boot WebUI。
5. 上传自编译的 `*h3c_magic-nx30-pro-nmbm*factory.bin`。

系统首次启动后，后续升级使用同一 NMBM profile 的 `sysupgrade.bin`。

## Troubleshooting

### `curl: (77) CA signer not available for verification`

首先检查时间：

```sh
date
```

如果显示 `Thu Jan 1 ... 1970`，说明路由器尚未联网，NTP 无法同步时间。TLS 会把 HTTPS 证书判断为尚未生效，因此 `curl` 无法下载 `dropbear`。

恢复 WAN 联网，等待时间自动同步为当前日期后再重试 `curl`。不要用 `curl -k` 绕过证书校验。

## 参考

- [新版 V100R009/R010 免拆机思路](https://chariri.moe/archives/2383/h3c-nx30-pro-openwrt-new-stock-firmware-no-ttl/)
- [用户实际参考的恩山帖子](https://www.right.com.cn/forum/thread-8460938-1-1.html)
- [Hanwckf bl-mt798x](https://github.com/hanwckf/bl-mt798x)
