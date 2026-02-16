# 约束集合 - 修复 APT 镜像和文件匹配问题

## 需求摘要

修复 setup.sh 中的两个问题：
1. 禁止自动修改镜像源，出错直接告诉用户
2. v2rayA 下载不正确，下的校验码 txt 而不是真正的 .deb 包

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 不自动修改 /etc/apt/sources.list | 用户要求 |
| C2 | APT 更新失败时提供清晰的错误提示 | 用户要求 |
| C3 | 下载实际的 .deb 包，排除 .sha256.txt 校验文件 | 用户错误日志 |
| C4 | 支持 curl 和 wget 两种下载工具 | codex 建议 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 一次 API 调用获取版本和文件名，避免不一致 | codex 建议 |
| S2 | 检查多个匹配文件的情况 | codex 建议 |

## 问题 1：禁止自动修改镜像源

### 用户需求
> 禁止自动修改镜像源，出错直接告诉用户

### 修复方案
移除所有自动修改 /etc/apt/sources.list 的逻辑，改为：
1. 只执行 `apt update`
2. 如果失败，提示用户手动配置镜像源

### 实施细节
```bash
# 移除前（旧代码）
tee /etc/apt/sources.list <<-'EOF'
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
...
EOF

# 移除后（新代码）
if ! apt update; then
    print_error "APT 更新失败，请检查网络连接或配置正确的软件源"
    print_error "如需配置国内镜像源，请手动编辑 /etc/apt/sources.list"
    exit 1
fi
```

## 问题 2：下载错误的文件（.sha256.txt）

### 错误日志
```
[INFO] v2rayA 下载完成 (大小: 4.0K)
[ERROR] 未找到 v2rayA 安装包 (installer_debian_*.deb)
```

实际下载的是：`installer_debian_x64_2.2.7.5.deb.sha256.txt` (65 字节)

### 根本原因
jq 过滤器使用 `contains(".deb")` 会匹配 `.sha256.txt` 文件（因为文件名包含 `.deb` 字符串）

### 修复方案
1. 使用 `endswith(".deb")` 替代 `contains(".deb")`
2. 添加 `(contains("sha256") | not)` 排除校验文件
3. 添加多文件匹配检测

### 实施细节
```bash
# 修复前
filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | \
  jq -r ".assets[] | select(.name | contains(\"${V2RAYA_ARCH}\") and contains(\".deb\")) | .name")

# 修复后
filename=$(echo "$release_json" | \
  jq -r ".assets[] | select(.name | endswith(\".deb\") and (contains(\"${V2RAYA_ARCH}\")) and (contains(\"sha256\") | not)) | .name")

# 检查多文件匹配
if [[ "$filename" == *" "* ]]; then
    print_error "找到多个匹配的 .deb 文件: $filename"
    exit 1
fi
```

## 问题 3：API 多次调用可能导致版本不一致

### 问题描述
get_latest_version 函数调用了两次 GitHub API：
- 第一次获取 tag_name
- 第二次获取 assets

如果两次调用之间发布了新版本，会导致版本号和文件名不匹配。

### 修复方案
一次 API 调用获取所有信息，缓存 JSON 响应并复用。

### 实施细节
```bash
# 修复前
version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')
filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".assets[] | ...")

# 修复后
release_json=$(curl -s "https://api.github.com/repos/${repo}/releases/latest")
version=$(echo "$release_json" | jq -r '.tag_name')
filename=$(echo "$release_json" | jq -r ".assets[] | ...")
```

## 问题 4：下载工具兼容性

### 问题描述
download_file 函数只使用 wget，但系统可能只有 curl。

### 修复方案
优先使用 wget，不存在时回退到 curl，并确保错误处理一致。

### 实施细节
```bash
if command -v wget &> /dev/null; then
    wget --progress=bar:force -O "$output" "$url"
elif command -v curl &> /dev/null; then
    curl -L --fail --show-error -o "$output" "$url"
else
    print_error "找不到 wget 或 curl 下载工具"
    exit 1
fi
```

## 实施清单

- [x] 移除自动镜像源修改逻辑
- [x] 添加 apt update 错误处理和用户提示
- [x] 修复 jq 过滤器使用 endswith(".deb")
- [x] 添加 sha256 文件排除
- [x] 添加多文件匹配检测
- [x] 缓存 API 响应避免多次调用
- [x] 支持 wget 和 curl 两种下载工具
- [x] 修复 wget 选项（--progress=bar:force）
- [x] 添加 curl 错误处理（--fail --show-error）
- [x] 更新 openspec/constraints.md 文档（本文档）
- [x] 在 .gitignore 中排除旧安装包目录（不再分发预构建包）

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|------|
| R1 | downloads/ 目录中的旧安装包仍会修改镜像源 | 旧包已从 git 排除（.gitignore），用户应使用 setup.sh 最新版本 |
| R2 | 临时网络问题导致 apt update 失败 | 提示用户检查网络连接和软件源配置 |

## 成功判据

| 判据 | 验证方式 | 期望结果 |
|------|---------|---------|
| SC1 | 不修改 /etc/apt/sources.list | 文件内容保持不变 |
| SC2 | 下载 .deb 包而非 .sha256.txt | 文件大小约 13MB |
| SC3 | apt update 失败时显示错误提示 | 提示用户手动配置镜像源 |
| SC4 | 支持 curl 和 wget | 只有其中一种工具也能正常下载 |
