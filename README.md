# v2rayA-for-Linux

v2rayA + Xray 一键安装包，支持 Ubuntu 22.04 (Jammy Jellyfish)。

## 功能特性

- 动态版本加载：自动从 GitHub 获取最新版本
- 一条命令安装：支持 curl 管道直接安装
- 多架构支持：amd64, arm64, armv7, loongarch64, mips32/64, riscv64
- 自动依赖安装：自动安装 jq, unzip 等依赖工具
- 自动服务启动：安装后自动启动并设置开机自启

## 系统要求

- 操作系统：Ubuntu 22.04 (Jammy Jellyfish)
- 权限：需要 root/sudo 权限
- 网络：需访问 GitHub Releases API 和下载文件

## 快速安装（一条命令）

将脚本托管到 GitHub 后，使用以下命令：

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/setup.sh | sudo bash
```

> 注意：请将 `<owner>` 和 `<repo>` 替换为实际的 GitHub 仓库信息。

## 常规安装

下载 setup.sh 后本地执行：

```bash
sudo bash setup.sh
```

## 安装过程说明

1. 检测系统架构
2. 自动安装依赖工具（jq, unzip）
3. 从 GitHub API 获取最新版本号
4. 下载 v2rayA 和 Xray-core 安装包
5. 更新 APT 源为阿里云镜像
6. 安装软件包
7. 启动 v2rayA 服务并设置开机自启

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
| setup.sh | 主安装脚本，支持动态版本加载 |
| openspec/ | OpenSpec 约束集合和提案文档 |
| CLAUDE.md | Claude Code 项目指导文档 |

## 开源仓库

- v2rayA: https://github.com/v2rayA/v2rayA
- Xray-core: https://github.com/XTLS/Xray-core

## 许可证

本项目遵循上游项目的许可证。
