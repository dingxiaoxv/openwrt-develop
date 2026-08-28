# OpenWrt / ImmortalWrt Firmware Build Workspace

面向多种路由器的 OpenWrt / ImmortalWrt 刷机与自编译工作区。仓库保存通用 Docker 构建环境、不同机型的刷机 workflow 与构建说明；固件源码、下载缓存和编译产物不提交到 Git。

## 交付与使用方式

| 内容 | 保存位置 | 用途 |
| --- | --- | --- |
| 构建环境定义 | 本仓库 [`Dockerfile`](Dockerfile) | 可审计、可复现地构建 Docker image |
| 构建环境镜像 | Docker Hub：`docker.io/dingyanxu/openwrt-buildenv:padavanonly-24.10-6.6-debian12` | 在其它电脑直接 `docker pull` 后开始编译 |
| ImmortalWrt 源码 | `immortalwrt-mt798x-6.6/`（本地） | 通过 bind mount 交给容器编译 |
| 构建缓存 | `./.cache/ccache/`（本地） | 加快重复构建，不提交 |
| 编译产物 | `immortalwrt-mt798x-6.6/bin/`（本地） | 生成的固件文件 |

个人 Docker Hub 仓库已创建并发布首个镜像：

```text
docker.io/dingyanxu/openwrt-buildenv:padavanonly-24.10-6.6-debian12
```

## 首次构建并发布构建环境

在本仓库根目录执行：

```sh
export IMAGE_NAME='dingyanxu/openwrt-buildenv:padavanonly-24.10-6.6-debian12'

docker build -t "$IMAGE_NAME" .
docker login
docker push "$IMAGE_NAME"
```

Dockerfile 安装的依赖遵循 Padavanonly README 的 Debian/Ubuntu APT 清单，并且以非 root 用户执行编译。Debian 12 已不提供 README 中列出的可选 `upx-ucl` 包，因此镜像未安装该工具；基础 OpenWrt 编译不受影响。

## 在任意电脑使用构建环境

```sh
git clone git@github.com:dingxiaoxv/openwrt-develop.git
cd openwrt-develop

export IMAGE_NAME='dingyanxu/openwrt-buildenv:padavanonly-24.10-6.6-debian12'
docker pull "$IMAGE_NAME"

mkdir -p .cache/ccache
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$PWD/immortalwrt-mt798x-6.6:/workspace" \
  -v "$PWD/.cache/ccache:/ccache" \
  "$IMAGE_NAME"
```

容器内进入 `/workspace` 后，再执行 feeds、目标配置和 `make`。后续会把 NX30 Pro 的最终 `.config` 与完整构建命令固化到本仓库。

## 已收录机型 Workflow

- [H3C Magic NX30 Pro：免拆机 Telnet、SSH、Hanwckf U-Boot 与 NMBM 固件](h3c-nx30-pro.md)
- [CMCC AX3000 eMMC：Padavanonly 固件编译与刷机](cmcc-ax3000-emmc.md)
- [Redmi AX6000：ImmortalWrt 编译与 Hanwckf U-Boot 刷机](redmi-ax6000.md)

新增机型时，优先创建独立 Markdown workflow；通用构建容器、缓存策略和上游链接保留在本 README。

## 常用地址

- [Hanwckf MT798x U-Boot 使用说明](https://cmi.hanwckf.top/p/mt798x-uboot-usage/)
- [Hanwckf `bl-mt798x` 最新下载](https://github.com/hanwckf/bl-mt798x/releases/latest)
- [Padavanonly ImmortalWrt MT798x 6.6 源码](https://github.com/padavanonly/immortalwrt-mt798x-6.6)
- [Padavanonly 分支：`openwrt-24.10-6.6`](https://github.com/padavanonly/immortalwrt-mt798x-6.6/tree/openwrt-24.10-6.6)
- [Docker Hub](https://hub.docker.com/)
- [已发布的构建环境镜像](https://hub.docker.com/r/dingyanxu/openwrt-buildenv)
- [Docker Hub 创建仓库说明](https://docs.docker.com/docker-hub/repos/create/)
- [新版 NX30 Pro 原厂固件免拆机参考](https://chariri.moe/archives/2383/h3c-nx30-pro-openwrt-new-stock-firmware-no-ttl/)
