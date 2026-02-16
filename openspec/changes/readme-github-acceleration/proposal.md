# 实施提案 - 添加 GitHub 加速说明

## 需求描述

更新 README.md，添加 GitHub 加速访问说明，帮助用户在 GitHub 访问受限或速度较慢的环境中使用本项目。

## 现状分析

### 当前 README.md 结构

| 章节 | 位置 | 状态 |
|------|------|------|
| 项目概述 | 第 1-3 行 | 保留 |
| 功能特性 | 第 5-11 行 | 保留 |
| 系统要求 | 第 13-17 行 | 保留 |
| 快速安装 | 第 19-27 行 | **需修改** |
| 常规安装 | 第 29-35 行 | 保留 |
| 安装过程说明 | 第 37-45 行 | 保留 |
| 安装后访问 | 第 47-55 行 | 保留 |
| 服务管理 | 第 57-66 行 | 保留 |
| 架构支持 | 第 68-77 行 | 保留 |
| 文件说明 | 第 79-85 行 | 保留 |
| 开源仓库 | 第 87-90 行 | **需修改** |

### 需要修改的内容

1. **快速安装章节** - 添加加速版本的 curl 命令
2. **开源仓库章节** - 添加加速访问链接

## 实施方案

### 修改点 1：扩展快速安装章节

**原内容** (第 19-27 行):
```markdown
## 快速安装（一条命令）

将脚本托管到 GitHub 后，使用以下命令：

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/setup.sh | sudo bash
```

> 注意：请将 `<owner>` 和 `<repo>` 替换为实际的 GitHub 仓库信息。
```

**修改为**:
```markdown
## 快速安装（一条命令）

### 标准安装

将脚本托管到 GitHub 后，使用以下命令：

```bash
curl -fsSL https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo bash
```

### GitHub 加速访问

如果 GitHub 访问速度较慢或无法访问，可以使用以下加速方案：

#### 方案 1：使用 ghproxy 代理

```bash
curl -fsSL https://mirror.ghproxy.com/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo bash
```

#### 方案 2：使用 fastgit 加速

```bash
curl -fsSL https://raw.fastgit.org/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo bash
```

#### 方案 3：手动下载后安装

如果上述方案都无法访问，可以手动下载 setup.sh 后执行：

1. 从以下地址下载 setup.sh：
   - 标准：https://github.com/AsisYu/v2rayA-xray-Linux/raw/main/setup.sh
   - 加速：https://mirror.ghproxy.com/https://github.com/AsisYu/v2rayA-xray-Linux/raw/main/setup.sh

2. 下载后执行：
```bash
sudo bash setup.sh
```
```

### 修改点 2：扩展开源仓库章节

**原内容** (第 87-90 行):
```markdown
## 开源仓库

- v2rayA: https://github.com/v2rayA/v2rayA
- Xray-core: https://github.com/XTLS/Xray-core
```

**修改为**:
```markdown
## 开源仓库

### 本项目

- 主仓库：https://github.com/AsisYu/v2rayA-xray-Linux
- 加速访问：https://mirror.ghproxy.com/https://github.com/AsisYu/v2rayA-xray-Linux

### 依赖项目

- v2rayA: https://github.com/v2rayA/v2rayA
- Xray-core: https://github.com/XTLS/Xray-core
```

### 修改点 3：新增网络加速说明章节（可选）

**位置**：在文件末尾、许可证章节之前

**内容**:
```markdown
## 网络加速

如果在使用过程中遇到 GitHub 访问问题：

### 克隆加速

```bash
# 使用 fastgit
git clone https://hub.fastgit.xyz/AsisYu/v2rayA-xray-Linux.git

# 使用 ghproxy
git clone https://mirror.ghproxy.com/https://github.com/AsisYu/v2rayA-xray-Linux.git
```

### 文件下载加速

使用 ghproxy 在原始 URL 前添加前缀：
```
原 URL: https://github.com/...
加速 URL: https://mirror.ghproxy.com/https://github.com/...
```

### 恢复官方源

加速镜像可能存在同步延迟，如需获取最新内容，请使用官方 GitHub 地址。
```

## 实施清单

- [ ] 修改快速安装章节，添加加速命令
- [ ] 修改开源仓库章节，添加加速链接
- [ ] 新增网络加速说明章节
- [ ] 验证无 emoji
- [ ] 验证 Markdown 格式正确

## 回滚计划

如需回滚，使用 git 恢复：
```bash
git checkout main -- README.md
```

## 影响评估

| 影响项 | 描述 |
|--------|------|
| 兼容性 | 向后兼容，原有功能不变 |
| 用户体验 | 提升，解决 GitHub 访问问题 |
| 文档可读性 | 增加，提供多种选择 |

## 状态

- [x] 约束分析完成
- [x] 提案生成完成
- [x] 实施 README.md 更新
