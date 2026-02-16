# 约束集合 - 一条 curl 命令完成全自动安装

## 需求摘要

使当前 `setup.sh` 能够通过一条 `curl` 命令完成 v2rayA 的全自动安装、启动和自启。

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 脚本必须以 root 权限执行（通过 sudo） | setup.sh:137-140 |
| C2 | 脚本必须自动安装依赖工具：jq, unzip, curl/wget | 用户确认 |
| C3 | 需要访问 GitHub API 获取最新版本号 | setup.sh:101 |
| C4 | 需要访问 GitHub Releases 下载安装包 | setup.sh:166,169 |
| C5 | 需要 systemd 支持（systemctl 命令） | install_v2raya_simple.sh:316-322 |
| C6 | 脚本必须托管到公共 URL（如 GitHub raw） | 用户确认 |
| C7 | 保持现有的安装流程：备份源、更新阿里云镜像、修复依赖 | install_v2raya_simple.sh:257-310 |
| C8 | 支持多架构自动检测 | setup.sh:57-66 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 使用临时目录下载文件，安装后自动清理 | setup.sh:146-155 |
| S2 | 保留彩色输出和进度提示 | setup.sh:39-54 |
| S3 | 保持 heredoc 方式生成 install_v2raya_simple.sh | setup.sh:225-341 |

## 依赖关系

```
curl 命令执行 → 下载/执行脚本 → 自动安装依赖 → 获取版本 → 下载包 → 安装 → 启动/自启
     ↓               ↓               ↓           ↓         ↓        ↓
   root权限       公共URL         apt命令    GitHub API GitHub  systemd
```

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|---------|
| R1 | GitHub API 限流（60次/小时未认证） | 添加 API 限流检测和错误处理 |
| R2 | 网络环境受限（防火墙/代理） | 添加超时和重试机制 |
| R3 | apt update 失败（镜像源问题） | 使用默认 Ubuntu 源作为备选 |
| R4 | 依赖工具安装失败 | 提供明确的错误提示和手动安装说明 |

## 成功判据

### 可验证的行为

| 判据 | 验证命令/行为 | 期望结果 |
|------|-------------|---------|
| SC1 | `curl -fsSL <url> \| sudo bash` | 命令执行无错误，安装完成 |
| SC2 | `systemctl is-active v2raya` | 返回 `active` |
| SC3 | `systemctl is-enabled v2raya` | 返回 `enabled` |
| SC4 | `curl http://localhost:2017` | 返回 HTML 响应 |
| SC5 | `command -v jq` | 返回路径（jq 已安装） |
| SC6 | `command -v unzip` | 返回路径（unzip 已安装） |

## 实施约束

| ID | 约束描述 |
|----|---------|
| EC1 | 修改 `check_dependencies()` 函数，实现自动安装依赖 |
| EC2 | 将修改后的 `setup.sh` 上传到 GitHub 仓库 |
| EC3 | 公共 URL 格式：`https://raw.githubusercontent.com/{owner}/{repo}/{branch}/setup.sh` |
| EC4 | 保持向后兼容，已预装依赖的环境也能正常工作 |

## 禁止事项

| ID | 禁止行为 | 原因 |
|----|---------|------|
| P1 | 移除架构自动检测功能 | 破坏多架构支持 |
| P2 | 修改 install_v2raya_simple.sh 的核心安装流程 | 可能影响现有安装 |
| P3 | 使用不可靠的第三方镜像源 | 安全风险 |
