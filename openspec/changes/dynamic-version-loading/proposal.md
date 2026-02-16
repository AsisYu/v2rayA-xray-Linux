# 提案：动态版本加载功能

## 概述

修改 `/home/biaogeai002/desktop/v2rayA-for-Linux/setup.sh` 安装脚本，使其能够从 GitHub Releases 动态获取 v2rayA 和 Xray-core 的最新版本，替代现有的硬编码下载链接。这解决了当前脚本依赖固定版本 URL 的问题，使安装脚本能够自动获取最新发布版本。

**实施状态：✅ 已完成**

## 背景

当前 `setup.sh` 脚本存在以下问题：

1. **硬编码版本依赖**：脚本中 `DOWNLOAD_URL="https://v2raya.os.tn/v2raya-xray-installer-2.2.7.4.tar.gz"` 使用了固定的版本号
2. **文件名固定**：脚本检查 `installer_debian_x64_2.2.7.4.deb` 和 `xray_25.8.3_amd64.deb` 固定文件名
3. **非官方源**：当前下载地址为第三方镜像站点，不是官方 GitHub Releases

这些问题导致：
- 新版本发布时需要手动更新脚本
- 无法自动获取最新功能和安全修复
- 依赖非官方源可能带来安全风险

## 约束集合

### 硬约束

#### 1. 版本发现机制
- 必须使用 GitHub Releases API `/releases/latest` 端点
- API 端点必须无认证访问（公开端点）
- 仓库地址固定：
  - v2rayA: `https://api.github.com/repos/v2rayA/v2rayA/releases/latest`
  - Xray-core: `https://api.github.com/repos/XTLS/Xray-core/releases/latest`

#### 2. 资源命名模式
- v2rayA debian x64: `installer_debian_x64_{VERSION}.deb`
- Xray-core linux x64: `Xray-linux-64.zip`
- 版本号格式：`v{major}.{minor}.{patch}`（如 v2.2.7.5, v26.2.6）

#### 3. 下载 URL 构造
- v2rayA: `https://github.com/v2rayA/v2rayA/releases/download/{version}/installer_debian_x64_{version}.deb`
- Xray-core: `https://github.com/XTLS/Xray-core/releases/download/{version}/Xray-linux-64.zip`

#### 4. 失败处理
- API 调用失败时必须报错并退出
- 资源下载失败时必须报错并退出
- 版本号解析失败时必须报错并退出
- 不得静默失败或使用默认值

#### 5. 兼容性约束
- 必须保持 `install_v2raya_simple.sh` 的调用接口不变
- 当前 setup.sh 的文件结构检查逻辑需要适配新格式
- 需要处理 `.deb` 和 `.zip` 两种不同的包格式

### 软约束

#### 1. 用户体验
- 显示正在获取的版本号
- 显示下载进度
- 提供清晰的错误信息

#### 2. 代码可读性
- 使用清晰的变量名
- 添加必要的注释
- 遵循现有的脚本风格

#### 3. 架构扩展性
- 支持检测系统架构（amd64, arm64, armv7 等）
- 根据架构选择对应的包

## 实施方案

### 依赖工具
- `curl` 或 `wget`：用于下载文件和 API 调用
- `jq`：用于解析 JSON（GitHub API 响应）
- `dpkg`：用于安装 .deb 包
- `unzip`：用于解压 .zip 文件（Xray-core）

### 实施步骤

#### 步骤 1: 添加版本获取函数
```bash
get_latest_version() {
    local repo=$1
    local version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        print_error "无法获取 ${repo} 的最新版本号"
        exit 1
    fi
    echo "$version"
}
```

#### 步骤 2: 获取最新版本
```bash
print_info "获取最新版本信息..."

V2RAYA_VERSION=$(get_latest_version "v2rayA/v2rayA")
print_info "v2rayA 最新版本: $V2RAYA_VERSION"

XRAY_VERSION=$(get_latest_version "XTLS/Xray-core")
print_info "Xray-core 最新版本: $XRAY_VERSION"
```

#### 步骤 3: 构造下载 URL
```bash
V2RAYA_DEB="installer_debian_x64_${V2RAYA_VERSION}.deb"
V2RAYA_URL="https://github.com/v2rayA/v2rayA/releases/download/${V2RAYA_VERSION}/${V2RAYA_DEB}"

XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
```

#### 步骤 4: 下载 v2rayA 包
```bash
print_info "正在下载 v2rayA ${V2RAYA_VERSION}..."
if ! wget -q --show-progress -O "$TEMP_DIR/$V2RAYA_DEB" "$V2RAYA_URL"; then
    print_error "下载 v2rayA 失败"
    exit 1
fi
```

#### 步骤 5: 下载并解压 Xray 包
```bash
print_info "正在下载 Xray-core ${XRAY_VERSION}..."
if ! wget -q --show-progress -O "$TEMP_DIR/$XRAY_ZIP" "$XRAY_URL"; then
    print_error "下载 Xray-core 失败"
    exit 1
fi

print_info "正在解压 Xray-core..."
if ! unzip -q "$TEMP_DIR/$XRAY_ZIP" -d "$TEMP_DIR/xray"; then
    print_error "解压 Xray-core 失败"
    exit 1
fi
```

#### 步骤 6: 修改文件检查逻辑
将原有的固定文件名检查：
```bash
if [ ! -f "installer_debian_x64_2.2.7.4.deb" ]; then
    print_error "找不到 v2rayA 安装包"
    exit 1
fi
```

改为动态文件名检查：
```bash
if [ ! -f "$TEMP_DIR/$V2RAYA_DEB" ]; then
    print_error "找不到 v2rayA 安装包 ($V2RAYA_DEB)"
    exit 1
fi
```

#### 步骤 7: 更新 install_v2raya_simple.sh 调用
确保安装脚本能够正确使用新格式的文件名。

## 成功判据

1. 脚本能够成功获取最新的 v2rayA 和 Xray-core 版本号
2. 能够正确下载对应版本的安装包（.deb 和 .zip 格式）
3. 安装过程能够正常完成
4. 安装的软件版本与 GitHub 最新版本一致
5. 错误情况下能够提供清晰的错误信息并退出

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| GitHub API 速率限制 | 脚本无法获取版本 | 无认证端点通常足够，可添加重试逻辑 |
| 网络连接问题 | 下载失败 | wget 已有超时和重试机制 |
| 版本不兼容 | 安装后功能异常 | GitHub 发布版本通常经过测试 |
| jq 依赖缺失 | 脚本无法执行 | 在脚本中检查 jq 是否安装 |

## 后续扩展

1. 支持多架构：检测系统架构并下载对应的包
2. 版本锁定：添加 `--version` 参数允许指定特定版本
3. 离线模式：支持从本地缓存安装
4. 镜像源：添加国内镜像源支持以加快下载速度
