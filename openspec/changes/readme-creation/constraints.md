# 约束集合 - 创建 README.md

## 需求摘要

为 v2rayA-for-Linux 项目创建 README.md 文档，用于说明项目功能、安装方法和使用指南。

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 不使用 emoji | 用户要求 |
| C2 | README.md 必须位于项目根目录 | 项目规范 |
| C3 | 文档必须反映当前代码实际状态 | setup.sh 分析结果 |
| C4 | 必须包含动态版本加载功能说明 | setup.sh:94-111 |
| C5 | 必须包含一条 curl 命令安装说明 | openspec/changes/one-curl-install |
| C6 | 目标系统：Ubuntu 22.04 (Jammy Jellyfish) | CLAUDE.md:73 |
| C7 | 需要 root/sudo 权限 | setup.sh:73-76 |
| C8 | 安装后访问地址：http://localhost:2017 | CLAUDE.md:36 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 使用 Markdown 格式 | GitHub 标准规范 |
| S2 | 包含代码示例 | 提高可读性 |
| S3 | 结构清晰，分节组织 | 便于阅读 |
| S4 | 包含服务管理命令 | 实用性考虑 |

## 依赖关系

```
README.md 内容来源:
├── setup.sh (当前代码)
├── CLAUDE.md (现有项目说明)
├── openspec/changes/one-curl-install/proposal.md (一条命令安装)
└── openspec/changes/dynamic-version-loading/proposal.md (动态版本加载)
```

## 文档结构要求

| 章节 | 必需 | 内容 |
|------|------|------|
| 项目概述 | 是 | 项目简介、功能说明 |
| 系统要求 | 是 | 目标系统、权限要求 |
| 快速安装 | 是 | 一条 curl 命令安装 |
| 常规安装 | 是 | sudo bash setup.sh |
| 安装后配置 | 是 | 访问地址、首次设置 |
| 服务管理 | 是 | start/stop/restart/status 命令 |
| 功能特性 | 是 | 动态版本、多架构支持 |
| 故障排查 | 否 | 可选，根据需要 |

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|---------|
| R1 | 代码变更导致文档过时 | 定期更新文档与代码同步 |
| R2 | 用户未检查权限直接安装 | 明确标注 sudo 要求 |
| R3 | GitHub URL 变更导致 curl 命令失效 | 使用稳定 URL 或说明如何获取 |

## 成功判据

| 判据 | 验证方式 | 期望结果 |
|------|---------|---------|
| SC1 | README.md 文件存在 | 文件位于项目根目录 |
| SC2 | 无 emoji | grep -E "[:alnum:]:|:\w:" README.md 无匹配 |
| SC3 | 包含一条 curl 命令 | 文档中包含 curl 命令示例 |
| SC4 | 包含动态版本说明 | 提及 GitHub API 获取版本 |
| SC5 | 包含服务管理命令 | systemctl 命令列完整 |
| SC6 | 目标系统明确 | Ubuntu 22.04 明确标注 |

## 禁止事项

| ID | 禁止行为 | 原因 |
|----|---------|------|
| P1 | 使用 emoji | 用户明确要求 |
| P2 | 引用不存在或过时的功能 | 保持文档准确性 |
| P3 | 包含硬编码版本号 | 版本动态获取，避免误导 |
