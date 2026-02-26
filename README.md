# v2rayA-for-Linux

v2rayA + Xray 一键安装包，支持 Debian/Ubuntu 和 CentOS/RHEL 系列。

## 功能特性

- 动态版本加载：自动从 GitHub 获取最新版本
- 一条命令安装：支持 curl 管道直接安装
- 多系统支持：Debian/Ubuntu, CentOS/RHEL, Rocky Linux, AlmaLinux
- 多架构支持：amd64, arm64, armv7, loongarch64, mips32/64, riscv64
- 自动依赖安装：自动安装 jq, unzip 等依赖工具
- 自动服务启动：安装后自动启动并设置开机自启
- GitHub 代理支持：支持配置代理解决国内网络问题

## 系统要求

### 支持的操作系统

| 系统 | 版本 |
|------|------|
| Debian | 10/11/12 |
| Ubuntu | 20.04/22.04/24.04 |
| CentOS | 7/8/9 (Stream) |
| RHEL | 7/8/9 |
| Rocky Linux | 8/9 |
| AlmaLinux | 8/9 |
| Fedora | 最新版 |

### 其他要求

- 权限：需要 root/sudo 权限
- 网络：需访问 GitHub Releases API 和下载文件

## 快速安装（一条命令）

### 标准安装

```bash
curl -fsSL https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo bash
```

### 国内服务器（使用 GitHub 加速）

```bash
# 方式一：先 export 再运行（推荐）
export GITHUB_API_PROXY=https://v6.gh-proxy.org/https://api.github.com
export GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org
curl -fsSL https://v6.gh-proxy.org/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo -E bash

# 方式二：使用 env 前缀传递环境变量
curl -fsSL https://v6.gh-proxy.org/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | env GITHUB_API_PROXY=https://v6.gh-proxy.org/https://api.github.com GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org sudo -E bash
```

### 一行命令（国内服务器推荐）

```bash
# 注意：管道 (|) 后的 bash 无法获取前面的环境变量，需使用 env 前缀
curl -fsSL https://v6.gh-proxy.org/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | env GITHUB_API_PROXY=https://v6.gh-proxy.org/https://api.github.com GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org sudo -E bash
```

## 环境变量配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `GITHUB_API_PROXY` | GitHub API 代理地址 | `https://v6.gh-proxy.org/https://api.github.com` |
| `GITHUB_DOWNLOAD_PROXY` | GitHub 文件下载代理 | `https://v6.gh-proxy.org` |

## 安装过程说明

1. 检测系统架构和操作系统类型
2. 自动安装依赖工具（jq, unzip, curl）
3. 从 GitHub API 获取最新版本号
4. 下载 v2rayA 和 Xray-core 安装包
5. 安装软件包（Debian 使用 dpkg，CentOS 使用 yum/dnf）
6. 预下载 geoip.dat 和 geosite.dat 数据文件（支持代理）
7. 配置并启动 v2rayA 服务

## 安装后访问

安装完成后，通过浏览器访问：

```
http://localhost:2017
```

首次访问需要设置管理员账户和密码。

## 服务管理

```bash
sudo systemctl start v2raya      # 启动服务
sudo systemctl stop v2raya       # 停止服务
sudo systemctl restart v2raya   # 重启服务
sudo systemctl status v2raya     # 查看状态
sudo systemctl enable v2raya     # 设置开机自启
sudo systemctl disable v2raya    # 取消开机自启
```

## 卸载

```bash
# 标准卸载
sudo ./uninstall.sh

# 强制卸载
sudo ./uninstall.sh --force

# 完全清理（含配置、缓存、日志）
sudo ./uninstall.sh --purge
```

卸载脚本功能：
- 自动检测安装方式（dpkg/rpm/本地二进制）
- 停止并禁用 v2raya 服务
- 卸载 v2rayA 软件包或二进制
- 删除 Xray 二进制文件
- 清理 geoip.dat 和 geosite.dat 数据文件
- 可选清理配置、缓存、日志（--purge）

## 架构支持

| 系统架构 | 支持状态 |
|---------|---------|
| amd64/x86_64 | 支持 |
| arm64/aarch64 | 支持 |
| armv7/armhf | 支持 |
| loongarch64 | 支持 |
| mips32/64/64le | 支持 |
| riscv64 | 支持 |

## 文件说明

| 文件 | 说明 |
|------|------|
| setup.sh | 主安装脚本，支持动态版本加载和多系统 |

## AI 辅助开发

本项目使用 Claude AI (Claude Code) 进行代码开发和文档编写辅助。

### 主要功能

Claude AI 参与了以下开发工作：

- 动态版本加载功能设计与实现
- 一条命令安装功能开发
- CentOS/RHEL 系统支持实现
- GitHub 代理支持功能
- 多架构支持实现
- 文档编写和优化

### 开发方法

项目采用 OpenSpec 方法论进行开发规划：
- 约束集合定义
- 实施提案文档
- 结构化需求分析

## 开源仓库

### 本项目

- 主仓库：https://github.com/AsisYu/v2rayA-xray-Linux
- 加速访问：https://v6.gh-proxy.org/https://github.com/AsisYu/v2rayA-xray-Linux

### 依赖项目

- v2rayA: https://github.com/v2rayA/v2rayA
- Xray-core: https://github.com/XTLS/Xray-core

## 网络加速

如果在使用过程中遇到 GitHub 访问问题：

### 常用代理地址

- `https://v6.gh-proxy.org`
- `https://ghproxy.net`

### 使用方式

在原始 URL 前添加代理前缀：
```
原 URL: https://github.com/...
加速 URL: https://v6.gh-proxy.org/https://github.com/...
```

## 许可证

本项目遵循上游项目的许可证。
