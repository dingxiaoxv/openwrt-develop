# OpenWrt / ImmortalWrt Firmware Build Workspace

所有新的路由器固件构建统一使用官方源码和官方推荐 Docker 环境。先阅读 [官方源码编译 SOP](official-source-build-sop.md)。

## 当前构建环境

- Docker Hub：`docker.io/dingyanxu/openwrt-buildenv:immortalwrt-official-24.10-debian11`
- Dockerfile：[Dockerfile](Dockerfile)，基于官方推荐的 Debian 11 与完整依赖清单
- 官方源码：`https://github.com/immortalwrt/immortalwrt.git`，分支 `openwrt-24.10`

```sh
export IMAGE_NAME='dingyanxu/openwrt-buildenv:immortalwrt-official-24.10-debian11'
docker pull "$IMAGE_NAME"
```

旧 Debian 12 / Padavanonly 环境仅作追溯，见 [历史构建环境](legacy-build-environment.md)。

## 已收录机型

- [通用：官方源码编译 SOP](official-source-build-sop.md)
- [H3C Magic NX30 Pro：免拆机 Telnet、SSH、Hanwckf U-Boot 与 NMBM 固件](h3c-nx30-pro.md)
- [CMCC AX3000 eMMC：刷机与官方源码编译](cmcc-ax3000-emmc.md)
- [Redmi AX6000：刷机与官方源码编译](redmi-ax6000.md)

## 常用地址

- [ImmortalWrt 官方源码：`openwrt-24.10`](https://github.com/immortalwrt/immortalwrt/tree/openwrt-24.10)
- [官方构建产物：MediaTek Filogic](https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/mediatek/filogic/)
- [Hanwckf MT798x U-Boot](https://github.com/hanwckf/bl-mt798x)
