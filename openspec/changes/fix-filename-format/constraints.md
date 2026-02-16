# 约束集合 - 修复文件名格式

## 需求摘要

修复 setup.sh 中的 v2rayA 文件名构造错误：使用 `_v` 分隔符导致文件名不匹配，下载失败。

## 问题分析

### 错误日志

```
[ERROR] URL: https://github.com/v2rayA/v2rayA/releases/download/v2.2.7.5/installer_debian_x64_v2.2.7.5.deb
```

### 实际文件名

GitHub API 返回的文件名：
```
installer_debian_x64_2.2.7.5.deb
```

### 脚本构造的文件名

当前脚本构造：
```bash
V2RAYA_DEB="installer_debian_${V2RAYA_ARCH}_${V2RAYA_VERSION}.deb"
# 结果: installer_debian_x64_v2.2.7.5.deb
```

### 根本原因

v2rayA 从 v2.2.x 版本开始，文件名格式改为使用下划线 `_` 而不是 `_v`：

| 版本 | 文件名格式 |
|------|------------|
| v2.2.6 | installer_debian_x64_2.2.6.deb |
| v2.2.5 | installer_debian_x64_2.2.5.deb |
| v2.2.4 | installer_debian_x64_2.2.4.deb |

但我们的脚本使用 `${V2RAYA_VERSION}` 时，如果版本号是 `v2.2.7.5`，会被解释为：
- `installer_debian_x64_v2.2.7.5.deb`（因为 shell 会把 `v2` 作为变量名的第一个字符）

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 修复文件名构造逻辑 | 用户明确要求 |
| C2 | 使用下划线 `_` 而不是 `_v` | GitHub 实际格式 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 从 API 获取实际文件名 | 准确性 |

## 修复方案

### 方案：从 API 获取实际文件名

修改脚本，从 GitHub API 获取实际的下载文件名，而不是自己构造：

```bash
get_latest_version() {
    local repo=$1
    local name=$2
    local version
    local filename

    print_info "正在获取 $name 最新版本..."

    version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        print_error "无法获取 $name 的最新版本号"
        print_error "请检查网络连接或稍后重试"
        exit 1
    fi

    print_info "$name 最新版本: $version"
    echo "$version"

    # 获取对应架构的文件名
    if [ "$name" = "v2rayA" ]; then
        filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".assets[] | select(.name | contains(\"${V2RAYA_ARCH}\") and contains(\".deb\")) | .name")
        if [ -z "$filename" ]; then
            print_error "无法找到 $name 的 ${V2RAYA_ARCH} .deb 文件"
            exit 1
        fi
    else
        filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".assets[] | select(.name == \"Xray-linux-${XRAY_ARCH}.zip\") | .name")
        if [ -z "$filename" ]; then
            print_error "无法找到 $name 的 ${XRAY_ARCH} .zip 文件"
            exit 1
        fi
    fi

    echo "$filename"
}
```

然后修改主流程：

```bash
# 获取最新版本和文件名
V2RAYA_INFO=$(get_latest_version_file "$V2RAYA_REPO" "v2rayA")
V2RAYA_VERSION=$(echo "$V2RAYA_INFO" | head -1)
V2RAYA_DEB=$(echo "$V2RAYA_INFO" | tail -1)

XRAY_INFO=$(get_latest_version_file "$XRAY_REPO" "Xray-core")
XRAY_VERSION=$(echo "$XRAY_INFO" | head -1)
XRAY_ZIP=$(echo "$XRAY_INFO" | tail -1)

# 构造下载 URL
V2RAYA_URL="https://github.com/${V2RAYA_REPO}/releases/download/${V2RAYA_VERSION}/${V2RAYA_DEB}"
XRAY_URL="https://github.com/${XRAY_REPO}/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
```

## 依赖关系

```
setup.sh 修改:
├── 修改 get_latest_version 返回版本号和文件名
└── 修改主流程使用 API 返回的文件名
```

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|---------|
| R1 | API 调用次数增加 | 每个项目增加 1 次调用 |

## 成功判据

| 判据 | 验证方式 | 期望结果 |
|------|---------|---------|
| SC1 | 使用 API 返回的文件名 | 匹配 GitHub 实际文件名 |
| SC2 | 下载成功 | wget 无错误 |

## 禁止事项

| ID | 禁止行为 | 原因 |
|----|---------|------|
| P1 | 自己构造文件名 | 可能导致 404 错误 |
