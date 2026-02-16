# 实施提案 - 一条 curl 命令完成全自动安装

## 需求描述

用户希望通过一条 `curl` 命令完成 v2rayA 的全自动安装，包括：
- 下载安装脚本
- 自动检测系统架构
- 获取最新版本
- 下载并安装 v2rayA 和 Xray-core
- 启动服务
- 设置开机自启

目标命令格式：
```bash
curl -fsSL <public-url> | sudo bash
```

## 现状分析

### 当前 setup.sh 已实现的功能

| 功能 | 位置 | 状态 |
|------|------|------|
| Root 权限检查 | setup.sh:137-140 | ✅ 已实现 |
| 架构自动检测 | setup.sh:57-66 | ✅ 已实现 |
| 依赖检查 | setup.sh:69-91 | ⚠️ 仅检查，不安装 |
| 版本获取（GitHub API） | setup.sh:94-111 | ✅ 已实现 |
| 文件下载 | setup.sh:114-134 | ✅ 已实现 |
| 动态生成安装脚本 | setup.sh:225-341 | ✅ 已实现 |
| 服务启动 | install_v2raya_simple.sh:319 | ✅ 已实现 |
| 服务自启 | install_v2raya_simple.sh:322 | ✅ 已实现 |

### 差距分析

| 缺失项 | 影响 |
|--------|------|
| 依赖自动安装 | 用户需手动预装 jq, unzip |

## 实施方案

### 修改点 1：改造 check_dependencies() 函数

**位置**: `setup.sh:69-91`

**修改内容**:
```bash
check_dependencies() {
    print_info "检查并安装依赖工具..."

    # 确保使用 sudo 权限
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 运行此脚本"
        exit 1
    fi

    # 更新 apt 缓存
    print_info "更新 APT 缓存..."
    apt update -qq

    # 检查并安装 jq
    if ! command -v jq &> /dev/null; then
        print_info "安装 jq..."
        apt install -y jq
    fi

    # 检查并安装 unzip
    if ! command -v unzip &> /dev/null; then
        print_info "安装 unzip..."
        apt install -y unzip
    fi

    # 检查 curl 或 wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_info "安装 curl..."
        apt install -y curl
    fi

    print_info "依赖检查通过"
}
```

**说明**:
- 将依赖检查改为检查 + 自动安装
- 先执行 `apt update` 确保包列表最新
- 每个工具独立检查和安装
- 保留原有的错误提示逻辑（虽然不再需要，但向后兼容）

### 修改点 2：移除重复的 root 检查

**位置**: `setup.sh:137-140`

**修改内容**:
- 将 root 检查逻辑移至 `check_dependencies()` 函数开头
- 移除全局的 root 检查（避免重复）

### 修改点 3：将脚本上传到 GitHub

**目标 URL 格式**:
```
https://raw.githubusercontent.com/{owner}/{repo}/{branch}/setup.sh
```

**示例**:
```bash
curl -fsSL https://raw.githubusercontent.com/biaogeai002/v2rayA-for-Linux/main/setup.sh | sudo bash
```

## 实施清单

### 阶段 1：代码修改

- [ ] 修改 `check_dependencies()` 函数，添加自动安装逻辑
- [ ] 移除全局的 root 检查，合并到 `check_dependencies()`
- [ ] 测试修改后的脚本功能

### 阶段 2：部署

- [ ] 将修改后的 `setup.sh` 提交到 GitHub 仓库
- [ ] 验证 GitHub raw URL 可访问
- [ ] 更新 README.md 添加一条命令安装说明

### 阶段 3：测试

- [ ] 在全新 Ubuntu 22.04 环境测试完整安装流程
- [ ] 验证服务启动和自启状态
- [ ] 测试多架构环境（如果可用）

## 验证步骤

### 本地测试
```bash
# 1. 以 root 权限运行脚本
sudo bash setup.sh

# 2. 验证服务状态
systemctl status v2raya

# 3. 验证服务自启
systemctl is-enabled v2raya

# 4. 验证 Web 界面
curl http://localhost:2017
```

### 远程测试
```bash
# 1. 使用 curl 命令安装
curl -fsSL https://raw.githubusercontent.com/.../setup.sh | sudo bash

# 2. 执行上述验证步骤
```

## 回滚计划

如果修改导致问题：
1. 从 Git 历史恢复原始 `setup.sh`
2. 更新 README.md 移除一条命令安装说明
3. 保留原有的手动安装流程

## 影响评估

| 影响项 | 描述 |
|--------|------|
| 兼容性 | 向后兼容，已预装依赖的环境不受影响 |
| 安全性 | 新增 `apt install` 操作，需要 root 权限（已满足） |
| 性能 | 新增 `apt update` 操作，首次运行增加约 10-20 秒 |
| 可维护性 | 脚本略微复杂，但更易用 |

## 实施后文档更新

### README.md 新增内容
```markdown
## 快速安装（一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/biaogeai002/v2rayA-for-Linux/main/setup.sh | sudo bash
```

安装完成后，访问 http://localhost:2017 配置 v2rayA。
```

## 状态

- [x] 约束分析完成
- [x] 提案生成完成
- [x] 代码实施
- [ ] 部署测试
- [ ] 文档更新
